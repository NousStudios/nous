import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_excluidas_service.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/terminal_conectado_info.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/loja/consolidador_loja_local.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/handlers/cliente_ws_message_handler.dart';

/// Processa eventos WebSocket de sincronização de loja e entidades operacionais do PDV.
class ClienteWsLojaSyncHelper {
  /// Tenta processar a mensagem caso pertença à sincronização da loja ou PDV.
  /// Retorna `true` se o tipo de evento foi tratado por este helper.
  static Future<bool> tentarProcessar(
    String? tipo,
    Map<String, dynamic> dados,
    ClienteWsContext ctx,
  ) async {
    if (tipo == 'dados_iniciais' || tipo == 'loja_atualizada') {
      await _processarDadosIniciaisOuLojaAtualizada(dados, ctx);
      return true;
    }

    if (tipo == 'pedido_adicionado' || tipo == 'pedido_atualizado') {
      _processarPedido(dados, ctx);
      return true;
    }

    if (tipo == 'cliente_atualizado') {
      _processarCliente(dados, ctx);
      return true;
    }

    if (tipo == 'estoque_atualizado') {
      _processarEstoque(dados, ctx);
      return true;
    }

    if (tipo == 'mesa_atualizada') {
      _processarMesa(dados, ctx);
      return true;
    }

    return false;
  }

  static Future<void> _processarDadosIniciaisOuLojaAtualizada(
    Map<String, dynamic> dados,
    ClienteWsContext ctx,
  ) async {
    if (dados['loja'] != null && ctx.pdvProvider != null) {
      ctx.definirAplicandoAtualizacaoRemota(true);
      try {
        final lojaBruta = Loja.fromJson(dados['loja'] as Map<String, dynamic>);
        final lojaRemotaComImagens = await ctx.sincronizarImagensRemotas(lojaBruta);

        final lojaLocalExistente = ctx.pdvProvider!.buscarPorId(lojaBruta.id) ??
            await LojasService.carregarLojaPorId(lojaBruta.id);

        final lojaConsolidada = LojasService.consolidarLojaComImagensLocais(
          lojaRemotaComImagens,
          lojaLocalExistente,
          manterItensAusentes: true,
        );

        final lojaSincAtual = ctx.obterLojaSincronizada();
        final ehLojaAtivaServidor = dados['ehLojaAtivaServidor'] == true;
        if (dados['tipo'] == 'dados_iniciais' ||
            ehLojaAtivaServidor ||
            (lojaSincAtual != null &&
                lojaSincAtual.id == lojaConsolidada.id)) {
          ctx.definirLojaSincronizada(lojaConsolidada);
        }
        await ctx.pdvProvider!.adicionarOuAtualizarLoja(lojaConsolidada);
        await ctx.vincularLojaSeNecessario(lojaConsolidada);

        final notificacoesDispensadas =
            (dados['notificacoesDispensadasLoja'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList();
        if (notificacoesDispensadas != null && notificacoesDispensadas.isNotEmpty) {
          NotificacoesProvider.instanciaAtiva?.dispensarNotificacoesLoja(
            lojaConsolidada.id,
            notificacoesDispensadas,
            originadoDaRede: true,
          );
        }

        if (lojaLocalExistente != null && dados['tipo'] == 'dados_iniciais') {
          final pedidosAtivosAusentesNoSnapshot = lojaLocalExistente.pedidosLoja
              .where(
                (pLoc) =>
                    pLoc.status != StatusPedido.concluido &&
                    pLoc.status != StatusPedido.cancelado &&
                    !lojaBruta.pedidosLoja.any((pRem) => pRem.id == pLoc.id),
              )
              .toList();

          var enviarParaCura = false;
          if (pedidosAtivosAusentesNoSnapshot.isNotEmpty) {
            final idsAusentes =
                pedidosAtivosAusentesNoSnapshot.map((p) => p.id).toList();
            final reconciliados = await ctx.reconciliarPedidosNoServidor(
              lojaConsolidada.id,
              idsAusentes,
            );

            if (reconciliados.isNotEmpty && ctx.pdvProvider != null) {
              final lojaAtualizada =
                  ctx.pdvProvider!.buscarPorId(lojaConsolidada.id) ??
                      lojaConsolidada;
              final mapaReconciliados = {
                for (final p in reconciliados) p.id: p,
              };
              final novaLista = lojaAtualizada.pedidosLoja
                  .map((p) => mapaReconciliados[p.id] ?? p)
                  .toList();
              ctx.pdvProvider!.atualizarListasLoja(
                lojaAtualizada.id,
                pedidos: novaLista,
              );
            }

            final idsEncontrados = reconciliados.map((p) => p.id).toSet();
            enviarParaCura = idsAusentes.any((id) => !idsEncontrados.contains(id));
          }

          final servidorTinhaMenosTurnos = lojaLocalExistente.turnosCaixa.any(
            (tLoc) =>
                tLoc.status.name == 'aberto' &&
                !lojaBruta.turnosCaixa.any((tRem) => tRem.id == tLoc.id),
          );

          if (enviarParaCura || servidorTinhaMenosTurnos) {
            debugPrint(
              '[ClienteRedeLocal] Novidades operacionais ativas detectadas neste aparelho. Transmitindo ao balcão para cura mútua...',
            );
            final lojaFinal =
                ctx.pdvProvider?.buscarPorId(lojaConsolidada.id) ??
                    lojaConsolidada;
            unawaited(ctx.enviarLojaCuradaParaServidor(lojaFinal));
          }
        }
      } finally {
        ctx.definirAplicandoAtualizacaoRemota(false);
      }
    }

    if (dados['lojaNousColetiva'] != null && ctx.pdvProvider != null) {
      try {
        final lojaNousBruta =
            Loja.fromJson(dados['lojaNousColetiva'] as Map<String, dynamic>);
        final lojaNousAtual =
            ctx.pdvProvider!.buscarPorId(PdvProvider.idLojaColetivaNous);
        if (lojaNousAtual != null) {
          final membrosCombinados = <String, MembroLoja>{};
          for (final m in lojaNousAtual.membros) {
            membrosCombinados[m.cpf.replaceAll(RegExp(r'\D'), '')] = m;
          }
          for (final m in lojaNousBruta.membros) {
            final cpfNorm = m.cpf.replaceAll(RegExp(r'\D'), '');
            membrosCombinados[cpfNorm] = m;
          }
          final mesclada = lojaNousAtual.copyWith(
            membros: membrosCombinados.values.toList(),
          );
          await ctx.pdvProvider!.adicionarOuAtualizarLoja(mesclada);
        } else {
          await ctx.pdvProvider!.adicionarOuAtualizarLoja(lojaNousBruta);
        }
      } catch (e) {
        debugPrint('[ClienteRedeLocal] Erro ao sincronizar lojaNousColetiva: $e');
      }
    }

    if (dados['presencas'] != null) {
      final lista = dados['presencas'] as List<dynamic>? ?? [];
      ctx.presencasAtivas.value = lista
          .map((e) => TerminalConectadoInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    if (dados['fotosUsuariosAusentes'] != null) {
      final ausentes = (dados['fotosUsuariosAusentes'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();
      ctx.curarFotosUsuariosAusentesNoServidor(ausentes);
    }

    if (dados['contasSincronizadas'] is List) {
      await _mesclarContasSincronizadas(
        dados['contasSincronizadas'] as List<dynamic>,
        ctx,
      );
    }
  }

  static Future<void> _mesclarContasSincronizadas(
    List<dynamic> contasJson,
    ClienteWsContext ctx,
  ) async {
    var houveMudanca = false;
    for (final item in contasJson) {
      if (item is! Map<String, dynamic>) continue;
      try {
        var remota = UsuarioNous.fromJson(item);
        if (remota.cpf.trim().isEmpty) continue;
        if (await ContasExcluidasService.estaExcluido(remota.cpf)) continue;

        final local = await ContasNousService.buscarPorCpf(remota.cpf);
        if (local == null) {
          if (remota.foto.isNotEmpty) {
            final novaFoto = await ctx.baixarImagemRemota(remota.foto);
            remota = remota.copyWith(foto: novaFoto);
          }
          await ContasNousService.salvar(remota);
          ctx.authProvider?.atualizarContaNoCache(remota);
          houveMudanca = true;
          continue;
        }

        final fotoFinal = (local.foto.isNotEmpty && ImagemService.existe(local.foto))
            ? local.foto
            : (remota.foto.isNotEmpty
                ? await ctx.baixarImagemRemota(remota.foto)
                : '');

        final mesclada = local
            .mesclarCom(remota, priorizarOutro: true)
            .copyWith(foto: fotoFinal);

        await ContasNousService.salvar(mesclada);
        ctx.authProvider?.atualizarContaNoCache(mesclada);
        houveMudanca = true;
      } catch (e) {
        debugPrint('[ClienteRedeLocal] Erro ao mesclar conta sincronizada: $e');
      }
    }
    if (houveMudanca) {
      await ctx.authProvider?.carregarCacheContas();
      ctx.pdvProvider?.notificarMudanca();
    }
  }

  static void _processarPedido(Map<String, dynamic> dados, ClienteWsContext ctx) {
    if (dados['pedido'] != null && ctx.pdvProvider != null) {
      final pedido = PedidoLoja.fromJson(dados['pedido'] as Map<String, dynamic>);
      final lojaSinc = ctx.obterLojaSincronizada();
      final lojaIdAlvo = pedido.lojaId.isNotEmpty
          ? pedido.lojaId
          : (dados['lojaId'] as String? ?? lojaSinc?.id ?? '');
      if (lojaIdAlvo.isEmpty) return;

      final lojaAtual = ctx.pdvProvider!.buscarPorId(lojaIdAlvo);
      if (lojaAtual != null) {
        ctx.definirAplicandoAtualizacaoRemota(true);
        try {
          final pedidos = List<PedidoLoja>.from(lojaAtual.pedidosLoja);
          final idx = pedidos.indexWhere((p) => p.id == pedido.id);
          if (idx != -1) {
            pedidos[idx] =
                ConsolidadorLojaLocal.mesclarDoisPedidos(pedidos[idx], pedido);
          } else {
            pedidos.insert(0, pedido);
          }
          ctx.pdvProvider!.atualizarListasLoja(lojaAtual.id, pedidos: pedidos);
        } finally {
          ctx.definirAplicandoAtualizacaoRemota(false);
        }
      }
    }
  }

  static void _processarCliente(Map<String, dynamic> dados, ClienteWsContext ctx) {
    if (dados['cliente'] != null && ctx.pdvProvider != null) {
      final cliente = Cliente.fromJson(dados['cliente'] as Map<String, dynamic>);
      final lojaSinc = ctx.obterLojaSincronizada();
      final lojaIdAlvo = (dados['lojaId'] as String?)?.trim().isNotEmpty == true
          ? (dados['lojaId'] as String).trim()
          : (lojaSinc?.id ?? '');
      if (lojaIdAlvo.isEmpty) return;

      final lojaAtual = ctx.pdvProvider!.buscarPorId(lojaIdAlvo);
      if (lojaAtual != null) {
        ctx.definirAplicandoAtualizacaoRemota(true);
        try {
          final clientes = List<Cliente>.from(lojaAtual.clientesLoja);
          final idx = clientes.indexWhere((c) => c.id == cliente.id);
          if (idx != -1) {
            clientes[idx] = cliente;
          } else {
            clientes.add(cliente);
          }
          ctx.pdvProvider!.atualizarListasLoja(lojaAtual.id, clientes: clientes);
        } finally {
          ctx.definirAplicandoAtualizacaoRemota(false);
        }
      }
    }
  }

  static void _processarEstoque(Map<String, dynamic> dados, ClienteWsContext ctx) {
    if (dados['movimento'] != null && ctx.pdvProvider != null) {
      final movMap = dados['movimento'] as Map<String, dynamic>;
      final mov = MovimentoEstoque.fromJson(movMap);
      final lojaSinc = ctx.obterLojaSincronizada();
      final lojaIdDireto = (dados['lojaId'] as String?)?.trim() ?? '';
      final lojaIdMov = (movMap['lojaId'] as String?)?.trim() ?? '';
      final lojaIdAlvo = lojaIdDireto.isNotEmpty
          ? lojaIdDireto
          : (lojaIdMov.isNotEmpty ? lojaIdMov : (lojaSinc?.id ?? ''));
      if (lojaIdAlvo.isEmpty) return;

      final lojaAtual = ctx.pdvProvider!.buscarPorId(lojaIdAlvo);
      if (lojaAtual != null) {
        final movs = List<MovimentoEstoque>.from(lojaAtual.movimentosEstoque);
        if (!movs.any((m) => m.id == mov.id)) {
          movs.insert(0, mov);
          ctx.definirAplicandoAtualizacaoRemota(true);
          try {
            ctx.pdvProvider!.atualizarListasLoja(lojaAtual.id, movimentosEstoque: movs);
          } finally {
            ctx.definirAplicandoAtualizacaoRemota(false);
          }
        }
      }
    }
  }

  static void _processarMesa(Map<String, dynamic> dados, ClienteWsContext ctx) {
    if (dados['mesa'] != null && ctx.pdvProvider != null) {
      final mesaMap = dados['mesa'] as Map<String, dynamic>;
      final mesa = MesaLoja.fromJson(mesaMap);
      final lojaSinc = ctx.obterLojaSincronizada();
      final lojaIdDireto = (dados['lojaId'] as String?)?.trim() ?? '';
      final lojaIdMesa = (mesaMap['lojaId'] as String?)?.trim() ?? '';
      final lojaIdAlvo = lojaIdDireto.isNotEmpty
          ? lojaIdDireto
          : (lojaIdMesa.isNotEmpty ? lojaIdMesa : (lojaSinc?.id ?? ''));
      if (lojaIdAlvo.isEmpty) return;

      final lojaAtual = ctx.pdvProvider!.buscarPorId(lojaIdAlvo);
      if (lojaAtual != null) {
        final mesas = List<MesaLoja>.from(lojaAtual.mesas);
        final idx = mesas.indexWhere((m) => m.id == mesa.id);
        if (idx != -1) {
          mesas[idx] = mesa;
        } else {
          mesas.add(mesa);
        }
        ctx.definirAplicandoAtualizacaoRemota(true);
        try {
          ctx.pdvProvider!.atualizarListasLoja(lojaAtual.id, mesas: mesas);
        } finally {
          ctx.definirAplicandoAtualizacaoRemota(false);
        }
      }
    }
  }
}
