import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nous/src/core/utils/json_isolate_utils.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/chat/controllers/helpers/mensageria_solicitacoes_helper.dart';
import 'package:nous/src/features/chat/services/chamada_webrtc_service.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/notificacoes/models/convite_loja.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/notificacoes/services/convites_service.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/terminal_conectado_info.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';

/// Contexto de execução para processamento de mensagens WebSocket no Cliente de Rede Local.
class ClienteWsContext {
  final PdvProvider? pdvProvider;
  final AuthProvider? authProvider;
  final ValueNotifier<List<TerminalConectadoInfo>> presencasAtivas;
  final Loja? Function() obterLojaSincronizada;
  final void Function(Loja) definirLojaSincronizada;
  final void Function(bool) definirAplicandoAtualizacaoRemota;
  final Future<Loja> Function(Loja) sincronizarImagensRemotas;
  final Future<void> Function(Loja) vincularLojaSeNecessario;
  final Future<void> Function(Loja) enviarLojaCuradaParaServidor;
  final void Function(List<String>) curarFotosUsuariosAusentesNoServidor;
  final Future<void> Function() sincronizarPerfisLojasComServidor;
  final void Function(Map<String, dynamic>) processarSinalChamada;
  final Future<String> Function(String) baixarImagemRemota;

  const ClienteWsContext({
    required this.pdvProvider,
    required this.authProvider,
    required this.presencasAtivas,
    required this.obterLojaSincronizada,
    required this.definirLojaSincronizada,
    required this.definirAplicandoAtualizacaoRemota,
    required this.sincronizarImagensRemotas,
    required this.vincularLojaSeNecessario,
    required this.enviarLojaCuradaParaServidor,
    required this.curarFotosUsuariosAusentesNoServidor,
    required this.sincronizarPerfisLojasComServidor,
    required this.processarSinalChamada,
    required this.baixarImagemRemota,
  });
}

/// Manipulador desacoplado de eventos e mensagens WebSocket recebidas pelo servidor balcão.
class ClienteWsMessageHandler {
  static Future<void> processarMensagem(dynamic msg, ClienteWsContext ctx) async {
    try {
      final dados = await decodificarJsonMapaSeguro(msg as String);
      final tipo = dados['tipo'] as String?;

      if (tipo == 'pong') {
        return;
      }

      if (tipo == 'dados_iniciais' || tipo == 'loja_atualizada') {
        await _processarDadosIniciaisOuLojaAtualizada(dados, ctx);
        return;
      }

      if (tipo == 'presencas_atualizadas') {
        final lista = dados['presencas'] as List<dynamic>? ?? [];
        ctx.presencasAtivas.value = lista
            .map((e) => TerminalConectadoInfo.fromJson(e as Map<String, dynamic>))
            .toList();
        return;
      }

      if (tipo == 'loja_excluida') {
        final lojaId = dados['lojaId'] as String?;
        if (lojaId != null && ctx.pdvProvider != null) {
          await ctx.pdvProvider!.excluirLoja(lojaId, originadaDaRede: true);
        }
        return;
      }

      if (tipo == 'pedido_adicionado' || tipo == 'pedido_atualizado') {
        _processarPedido(dados, ctx);
        return;
      }

      if (tipo == 'cliente_atualizado') {
        _processarCliente(dados, ctx);
        return;
      }

      if (tipo == 'estoque_atualizado') {
        _processarEstoque(dados, ctx);
        return;
      }

      if (tipo == 'mesa_atualizada') {
        _processarMesa(dados, ctx);
        return;
      }

      if (tipo == 'usuario_atualizado') {
        await _processarUsuarioAtualizado(dados, ctx);
        return;
      }

      if (tipo == 'usuario_nous_excluido') {
        await _processarUsuarioNousExcluido(dados, ctx);
        return;
      }

      if (tipo == 'solicitacao_aceita') {
        final conversaId = dados['conversaId'] as String? ?? '';
        final cpf = dados['cpf'] as String? ?? '';
        await MensageriaSolicitacoesHelper.processarAceiteRemoto(
          conversaId: conversaId,
          meuCpf: cpf,
        );
        return;
      }

      if (tipo == 'perfis_usuario_atualizados') {
        await _processarPerfisUsuarioAtualizados(dados, ctx);
        return;
      }

      if (tipo == 'mensagem_chat') {
        if (dados['mensagem'] != null) {
          final msgJson = dados['mensagem'] as Map<String, dynamic>;
          await ChatService.processarMensagemRecebidaDaRede(msgJson);
        }
        return;
      }

      if (tipo == 'mensagem_entregue') {
        final msgId = dados['id'] as String? ?? dados['mensagemId'] as String? ?? '';
        final convId = dados['conversaId'] as String?;
        await ChatService.processarMensagemEntregueDaRede(msgId, conversaId: convId);
        return;
      }

      if (tipo == 'mensagens_lidas') {
        final convId = dados['conversaId'] as String? ?? '';
        final idLeitor = dados['idLeitor'] as String? ?? '';
        await ChatService.processarMensagensLidasDaRede(convId, idLeitor);
        return;
      }

      if (tipo == 'mensagens_lidas_loja') {
        final lojaId = dados['lojaId'] as String? ?? '';
        final idLeitor = dados['idLeitor'] as String? ?? '';
        await ChatService.processarMensagensLidasDaLojaDaRede(lojaId, idLeitor);
        return;
      }

      if (tipo == 'notificacoes_loja_limpas') {
        final lojaId = dados['lojaId'] as String? ?? '';
        final ids = (dados['ids'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList();
        if (lojaId.isNotEmpty && ids.isNotEmpty) {
          NotificacoesProvider.instanciaAtiva?.dispensarNotificacoesLoja(
            lojaId,
            ids,
            originadoDaRede: true,
          );
          await ChatService.processarMensagensLidasDaLojaDaRede(lojaId, '');
        }
        return;
      }

      if (tipo == 'conversa_atualizada') {
        if (dados['conversa'] != null) {
          final cMap = dados['conversa'] as Map<String, dynamic>;
          await ChatService.salvarConversaLocal(cMap);
        }
        return;
      }

      if (tipo == 'conversa_renomeada') {
        final convId = dados['conversaId'] as String?;
        final novoTit = dados['novoTitulo'] as String?;
        if (convId != null && novoTit != null) {
          await ChatService.renomearConversa(convId, novoTit, originadoDaRede: true);
        }
        return;
      }

      if (tipo == 'conversa_excluida') {
        final convId = dados['conversaId'] as String?;
        if (convId != null) {
          await ChatService.excluirConversaLocal(
            convId,
            originadoDaRede: true,
          );
        }
        return;
      }

      if (tipo == 'grupo_criado' ||
          tipo == 'grupo_atualizado' ||
          tipo == 'mensagem_editada' ||
          tipo == 'mensagem_excluida' ||
          tipo == 'mensagem_reacao' ||
          tipo == 'mensagem_fixada' ||
          tipo == 'comanda_atualizada') {
        await ChatService.processarMensagemRecebidaDaRede(
          dados,
          emitirAlertaSonoro: false,
        );
        return;
      }

      if (tipo == 'novo_convite_loja') {
        await _processarNovoConviteLoja(dados, ctx);
        return;
      }

      if (tipo == 'sincronizacao_convites') {
        await _processarSincronizacaoConvites(dados, ctx);
        return;
      }

      if (tipo == 'convite_loja_removido') {
        final cpf = dados['cpf'] as String?;
        final conviteId = dados['conviteId'] as String?;
        if (cpf != null && conviteId != null) {
          await ConvitesService.remover(cpf, conviteId, originadoDaRede: true);
          NotificacoesProvider.instanciaAtiva?.recarregarSeuCpf();
        }
        return;
      }

      if (tipo != null && tipo.startsWith('chamada_')) {
        ctx.processarSinalChamada(dados);
        return;
      }
    } catch (e) {
      debugPrint('[ClienteRedeLocal] Erro ao processar mensagem WebSocket: $e');
    }
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
        if (dados['tipo'] == 'dados_iniciais' ||
            lojaSincAtual == null ||
            lojaSincAtual.id == lojaConsolidada.id) {
          ctx.definirLojaSincronizada(lojaConsolidada);
        }
        await ctx.pdvProvider!.adicionarOuAtualizarLoja(lojaConsolidada);
        await ctx.vincularLojaSeNecessario(lojaConsolidada);

        final notificacoesDispensadas = (dados['notificacoesDispensadasLoja'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList();
        if (notificacoesDispensadas != null && notificacoesDispensadas.isNotEmpty) {
          NotificacoesProvider.instanciaAtiva?.dispensarNotificacoesLoja(
            lojaConsolidada.id,
            notificacoesDispensadas,
            originadoDaRede: true,
          );
        }

        if (lojaLocalExistente != null) {
          final servidorTinhaMenosPedidos = lojaLocalExistente.pedidosLoja.any(
            (pLoc) => !lojaBruta.pedidosLoja.any((pRem) => pRem.id == pLoc.id),
          );
          final servidorTinhaMenosTurnos = lojaLocalExistente.turnosCaixa.any(
            (tLoc) => !lojaBruta.turnosCaixa.any((tRem) => tRem.id == tLoc.id),
          );
          final servidorTinhaMenosEstoque = lojaLocalExistente.movimentosEstoque.any(
            (mLoc) => !lojaBruta.movimentosEstoque.any((mRem) => mRem.id == mLoc.id),
          );

          if (servidorTinhaMenosPedidos ||
              servidorTinhaMenosTurnos ||
              servidorTinhaMenosEstoque) {
            debugPrint(
              '[ClienteRedeLocal] Novidades financeiras detectadas neste aparelho. Transmitindo ao balcão para cura mútua...',
            );
            unawaited(ctx.enviarLojaCuradaParaServidor(lojaConsolidada));
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
            pedidos[idx] = pedido;
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
            clientes[idx] = cliente.copyWith(fretePadrao: clientes[idx].fretePadrao);
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
          ctx.pdvProvider!.atualizarListasLoja(lojaAtual.id, movimentosEstoque: movs);
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
        ctx.pdvProvider!.atualizarListasLoja(lojaAtual.id, mesas: mesas);
      }
    }
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

        final local = await ContasNousService.buscarPorCpf(usuarioRemoto.cpf);
        if (local != null &&
            local.foto.isNotEmpty &&
            ImagemService.existe(local.foto) &&
            (usuarioRemoto.foto.isEmpty || !ImagemService.existe(usuarioRemoto.foto))) {
          usuarioRemoto = usuarioRemoto.copyWith(foto: local.foto);
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

  static Future<void> _processarNovoConviteLoja(
    Map<String, dynamic> dados,
    ClienteWsContext ctx,
  ) async {
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
    ClienteWsContext ctx,
  ) async {
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

  /// Processa e roteia pacotes WebRTC de áudio e vídeo recebidos via WebSocket
  static void processarSinalChamada({
    required Map<String, dynamic> dados,
    required String meuCpf,
    required List<Loja>? lojasLocal,
  }) {
    try {
      final tipo = dados['tipo'] as String?;

      if (tipo == 'chamada_iniciar') {
        final chamadaJson = dados['chamada'] as Map<String, dynamic>?;
        final sdp = dados['sdp'] as Map<String, dynamic>?;
        if (chamadaJson != null && sdp != null) {
          final destId = (chamadaJson['destinatarioId'] as String? ?? '').replaceAll(RegExp(r'\D'), '');
          final participantes = (chamadaJson['participantesIds'] as List<dynamic>?)
                  ?.map((e) => e.toString().replaceAll(RegExp(r'\D'), ''))
                  .toList() ??
              [];
          final destEhLojaLocal = destId.isNotEmpty &&
              (lojasLocal?.any(
                    (l) =>
                        PdvProvider.normalizarIdLoja(l.id) == destId &&
                        (ChatService.normalizarCpf(l.cpfDonoOriginal) ==
                                meuCpf ||
                            l.membros.any(
                              (m) =>
                                  ChatService.normalizarCpf(m.cpf) == meuCpf,
                            )),
                  ) ??
                  false);

          if (destId == meuCpf ||
              destEhLojaLocal ||
              participantes.contains(meuCpf) ||
              destId.isEmpty) {
            ChamadaWebRtcService.instancia.receberConvite(chamadaJson, sdp);
          }
        }
      } else if (tipo == 'chamada_aceita') {
        final sdp = dados['sdp'] as Map<String, dynamic>?;
        if (sdp != null) {
          ChamadaWebRtcService.instancia.receberRespostaAceita(sdp);
        }
      } else if (tipo == 'chamada_candidato_ice') {
        final candidate = dados['candidate'] as Map<String, dynamic>?;
        if (candidate != null) {
          ChamadaWebRtcService.instancia.receberCandidatoIce(candidate);
        }
      } else if (tipo == 'chamada_rejeitada' || tipo == 'chamada_encerrada') {
        ChamadaWebRtcService.instancia.encerrarChamada(notificarRede: false);
      }
    } catch (e) {
      debugPrint('[ClienteWsMessageHandler] Erro ao processar sinal de chamada: $e');
    }
  }
}
