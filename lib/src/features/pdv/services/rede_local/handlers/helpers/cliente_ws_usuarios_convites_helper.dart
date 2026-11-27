import 'package:flutter/foundation.dart';
import 'package:nous/src/core/services/preferencias_soberanas_service.dart';
import 'package:nous/src/core/services/relogio_rede_service.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_excluidas_service.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/notificacoes/models/convite_loja.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/notificacoes/services/convites_service.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/handlers/cliente_ws_message_handler.dart';

/// Processa eventos WebSocket de usuários, perfis e convites de loja no cliente.
class ClienteWsUsuariosConvitesHelper {
  /// Tenta processar a mensagem caso pertença ao domínio de usuários ou convites.
  /// Retorna `true` se o tipo de evento foi tratado por este helper.
  static Future<bool> tentarProcessar(
    String? tipo,
    Map<String, dynamic> dados,
    ClienteWsContext ctx,
  ) async {
    if (tipo == 'usuario_atualizado') {
      await _processarUsuarioAtualizado(dados, ctx);
      return true;
    }

    if (tipo == 'usuario_nous_excluido') {
      await _processarUsuarioNousExcluido(dados, ctx);
      return true;
    }

    if (tipo == 'perfis_usuario_atualizados') {
      await _processarPerfisUsuarioAtualizados(dados, ctx);
      return true;
    }

    if (tipo == 'novo_convite_loja') {
      await _processarNovoConviteLoja(dados);
      return true;
    }

    if (tipo == 'sincronizacao_convites') {
      await _processarSincronizacaoConvites(dados);
      return true;
    }

    if (tipo == 'convite_loja_removido') {
      final cpf = dados['cpf'] as String?;
      final conviteId = dados['conviteId'] as String?;
      if (cpf != null && conviteId != null) {
        await ConvitesService.remover(cpf, conviteId, originadoDaRede: true);
        NotificacoesProvider.instanciaAtiva?.recarregarSeuCpf();
      }
      return true;
    }

    if (tipo == 'usuario_seguir_atualizado') {
      final autorCpf = (dados['autorCpf'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
      final alvoCpf = (dados['alvoCpf'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
      final seguindo = dados['seguindo'] == true;
      if (autorCpf.isNotEmpty && alvoCpf.isNotEmpty) {
        final alvo = await ContasNousService.buscarPorCpf(alvoCpf);
        if (alvo != null) {
          final seguidores = List<String>.from(alvo.seguidores);
          if (seguindo) {
            if (!seguidores.any((s) => s.replaceAll(RegExp(r'\D'), '') == autorCpf)) {
              seguidores.add(autorCpf);
            }
          } else {
            seguidores.removeWhere((s) => s.replaceAll(RegExp(r'\D'), '') == autorCpf);
          }
          final atualizado = alvo.copyWith(
            seguidores: seguidores,
            atualizadoEm: RelogioRedeService.agora().toIso8601String(),
          );
          await ContasNousService.salvar(atualizado);
          ctx.authProvider?.atualizarContaNoCache(atualizado);
        }
      }
      return true;
    }

    if (tipo == 'preferencias_cpf_sync') {
      final itens = dados['itens'] as List<dynamic>? ?? const [];
      await PreferenciasSoberanasService.mesclarRemotas(itens);
      return true;
    }

    return false;
  }

  static Future<void> _processarUsuarioAtualizado(
    Map<String, dynamic> dados,
    ClienteWsContext ctx,
  ) async {
    if (dados['usuario'] != null) {
      try {
        var usuarioRemoto =
            UsuarioNous.fromJson(dados['usuario'] as Map<String, dynamic>);
        if (usuarioRemoto.foto.isNotEmpty) {
          final novaFotoLocal = await ctx.baixarImagemRemota(usuarioRemoto.foto);
          usuarioRemoto = usuarioRemoto.copyWith(foto: novaFotoLocal);
        }
        if (usuarioRemoto.fotoPublica.isNotEmpty) {
          final novaFotoPubLocal =
              await ctx.baixarImagemRemota(usuarioRemoto.fotoPublica);
          if (novaFotoPubLocal.isNotEmpty) {
            usuarioRemoto = usuarioRemoto.copyWith(fotoPublica: novaFotoPubLocal);
          }
        }

        final local = await ContasNousService.buscarPorCpf(usuarioRemoto.cpf);
        if (local != null) {
          final fotoLocalValida =
              local.foto.isNotEmpty && ImagemService.existe(local.foto);
          final fotoRemotaValida = usuarioRemoto.foto.isNotEmpty &&
              ImagemService.existe(usuarioRemoto.foto);
          final fotoPubLocalValida = local.fotoPublica.isNotEmpty &&
              ImagemService.existe(local.fotoPublica);
          final fotoPubRemotaValida = usuarioRemoto.fotoPublica.isNotEmpty &&
              ImagemService.existe(usuarioRemoto.fotoPublica);
          usuarioRemoto = local.mesclarCom(usuarioRemoto, priorizarOutro: true);
          if (!fotoRemotaValida && fotoLocalValida) {
            usuarioRemoto = usuarioRemoto.copyWith(foto: local.foto);
          }
          if (!fotoPubRemotaValida && fotoPubLocalValida) {
            usuarioRemoto = usuarioRemoto.copyWith(fotoPublica: local.fotoPublica);
          }
        }

        if (await ContasExcluidasService.estaExcluido(usuarioRemoto.cpf)) {
          return;
        }
        await ContasNousService.salvar(usuarioRemoto);
        ctx.authProvider?.atualizarContaNoCache(usuarioRemoto);
        ctx.pdvProvider?.notificarMudanca();
        ctx.pdvProvider?.sincronizarFotoUsuarioEmClientes(
          usuarioRemoto.cpf,
          usuarioRemoto.foto,
        );
        ctx.pdvProvider?.sincronizarDadosUsuarioEmLojas(usuarioRemoto);

        final cpfAtivo = ctx.pdvProvider?.cpfAtual ??
            ctx.authProvider?.contaAtual?.cpf ??
            ctx.authProvider?.cpf;
        if (cpfAtivo != null &&
            cpfAtivo.replaceAll(RegExp(r'\D'), '') ==
                usuarioRemoto.cpf.replaceAll(RegExp(r'\D'), '')) {
          await ctx.authProvider?.recarregarConta();
        } else {
          await ctx.authProvider?.carregarCacheContas();
        }
        debugPrint(
          '[ClienteRedeLocal] Identidade do usuário ${usuarioRemoto.cpf} (${usuarioRemoto.nome}) atualizada via WebSocket (Foto: ${usuarioRemoto.foto})',
        );
      } catch (e) {
        debugPrint(
          '[ClienteRedeLocal] Erro ao processar usuario_atualizado via WebSocket: $e',
        );
      }
    }
  }

  static Future<void> _processarUsuarioNousExcluido(
    Map<String, dynamic> dados,
    ClienteWsContext ctx,
  ) async {
    final cpf = (dados['cpf'] as String? ?? '').replaceAll(RegExp(r'\D'), '');
    if (cpf.isEmpty) return;
    try {
      final regJson = dados['registro'] as Map<String, dynamic>?;
      if (regJson != null) {
        await ContasExcluidasService.salvarRegistro(
          ContaExcluidaNous.fromMap(regJson),
        );
      } else {
        final local = await ContasNousService.buscarPorCpf(cpf);
        if (local != null) {
          await ContasExcluidasService.registrarExclusao(local);
        }
      }
      await ContasNousService.excluir(cpf);
      final coletiva = ctx.pdvProvider?.buscarPorId('loja_nous_coletiva');
      if (coletiva != null) {
        final membrosAtualizados = coletiva.membros
            .where((m) => m.cpf.replaceAll(RegExp(r'\D'), '') != cpf)
            .toList();
        if (membrosAtualizados.length != coletiva.membros.length) {
          final atualizada = coletiva.copyWith(membros: membrosAtualizados);
          await LojasService.salvarLojaIndividual(atualizada);
          await ctx.pdvProvider?.adicionarOuAtualizarLoja(atualizada);
        }
      }
      await ctx.authProvider?.carregarCacheContas();
      ctx.pdvProvider?.notificarMudanca();
    } catch (e) {
      debugPrint(
        '[ClienteRedeLocal] Erro ao processar usuario_nous_excluido via WebSocket: $e',
      );
    }
  }

  static Future<void> _processarPerfisUsuarioAtualizados(
    Map<String, dynamic> dados,
    ClienteWsContext ctx,
  ) async {
    final cpfAtualizado =
        (dados['cpf'] as String? ?? '').replaceAll(RegExp(r'\D'), '');
    final cpfAtivo = (ctx.pdvProvider?.cpfAtual ??
            ctx.authProvider?.contaAtual?.cpf ??
            ctx.authProvider?.cpf ??
            '')
        .replaceAll(RegExp(r'\D'), '');
    if (cpfAtualizado.isNotEmpty && cpfAtualizado == cpfAtivo) {
      debugPrint(
        '[ClienteRedeLocal] Perfis do usuário $cpfAtualizado atualizados via WebSocket. Sincronizando perfis...',
      );
      await ctx.sincronizarPerfisLojasComServidor();
    }
  }

  static Future<void> _processarNovoConviteLoja(Map<String, dynamic> dados) async {
    if (dados['convite'] != null) {
      try {
        final convite =
            ConviteLoja.fromJson(dados['convite'] as Map<String, dynamic>);
        if (dados['loja'] != null) {
          try {
            final lojaAnexa =
                Loja.fromJson(dados['loja'] as Map<String, dynamic>);
            await LojasService.salvarLojaIndividual(lojaAnexa);
          } catch (_) {}
        }
        await ConvitesService.adicionar(
          convite.cpfConvidado,
          convite,
          originadoDaRede: true,
        );
        NotificacoesProvider.instanciaAtiva?.recarregarSeuCpf();
        debugPrint(
          '[ClienteRedeLocal] Novo convite recebido da rede para "${convite.nomeLoja}"!',
        );
      } catch (e) {
        debugPrint('[ClienteRedeLocal] Erro ao processar novo_convite_loja via WS: $e');
      }
    }
  }

  static Future<void> _processarSincronizacaoConvites(
    Map<String, dynamic> dados,
  ) async {
    final lojasAnexas = dados['lojas'];
    if (lojasAnexas is Map) {
      for (final entry in lojasAnexas.entries) {
        if (entry.value is Map<String, dynamic>) {
          try {
            final lojaAnexa = Loja.fromJson(entry.value as Map<String, dynamic>);
            await LojasService.salvarLojaIndividual(lojaAnexa);
          } catch (_) {}
        }
      }
    }
    final listaConvites = dados['convites'] as List<dynamic>? ?? [];
    for (final cJson in listaConvites) {
      if (cJson is Map<String, dynamic>) {
        try {
          final c = ConviteLoja.fromJson(cJson);
          await ConvitesService.adicionar(
            c.cpfConvidado,
            c,
            originadoDaRede: true,
          );
        } catch (_) {}
      }
    }
    if (listaConvites.isNotEmpty) {
      NotificacoesProvider.instanciaAtiva?.recarregarSeuCpf();
      debugPrint(
        '[ClienteRedeLocal] Sincronizados ${listaConvites.length} convite(s) via balcão.',
      );
    }
  }
}
