import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:nous/src/core/services/som_service.dart';
import 'package:nous/src/core/utils/json_isolate_utils.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/contas_excluidas_service.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/chat/controllers/helpers/mensageria_solicitacoes_helper.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/notificacoes/models/convite_loja.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/notificacoes/services/convites_service.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/terminal_conectado_info.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';

/// Contexto de execução para processamento de mensagens WebSocket no Servidor de Rede Local.
class ServidorWsContext {
  final Map<WebSocket, TerminalConectadoInfo> terminaisWs;
  final List<WebSocket> clientesWs;
  final PdvProvider? pdvProvider;
  final AuthProvider? authProvider;
  final Loja? Function() obterLojaAtiva;
  final VoidCallback atualizarListasTerminais;
  final VoidCallback notificarPresencas;
  final void Function(TerminalConectadoInfo) consolidarContaTerminal;
  final void Function(Map<String, dynamic>) processarSinalChamadaLocal;

  const ServidorWsContext({
    required this.terminaisWs,
    required this.clientesWs,
    required this.pdvProvider,
    required this.authProvider,
    required this.obterLojaAtiva,
    required this.atualizarListasTerminais,
    required this.notificarPresencas,
    required this.consolidarContaTerminal,
    required this.processarSinalChamadaLocal,
  });

  /// Envia payload serializado para todos os clientes conectados, exceto o emissor original se fornecido.
  /// Aplica filtragem de privacidade soberana: clientes externos recebem apenas eventos pertinentes
  /// a eles e visões públicas/cardápios, bloqueando o vazamento de dados internos de gestão.
  void retransmitirParaOutros(String payload, {WebSocket? exceto}) {
    Map<String, dynamic>? dados;
    try {
      final dec = jsonDecode(payload);
      if (dec is Map<String, dynamic>) {
        dados = dec;
      }
    } catch (_) {}

    final tipo = dados?['tipo'] as String?;

    for (final cliente in List<WebSocket>.from(clientesWs)) {
      if (cliente == exceto) continue;

      final terminal = terminaisWs[cliente];
      final ehCliente = terminal?.tipoConexao == 'cliente';

      if (ehCliente && dados != null) {
        // Clientes externos não devem receber dados de clientes, estoque interno ou caixa
        if (tipo == 'cliente_atualizado' ||
            tipo == 'movimento_estoque' ||
            tipo == 'caixa_atualizado') {
          continue;
        }

        // Se for atualização de loja, cliente recebe apenas a visão pública do cardápio
        if (tipo == 'loja_atualizada') {
          try {
            final lojaMap = dados['loja'] as Map<String, dynamic>?;
            if (lojaMap != null) {
              final lojaObj = Loja.fromJson(lojaMap);
              final payloadSanitizado = jsonEncode({
                ...dados,
                'loja': lojaObj.toVisaoPublica().toJson(),
              });
              cliente.add(payloadSanitizado);
              continue;
            }
          } catch (_) {}
        }

        // Se for pedido adicionado ou atualizado, cliente só recebe se o pedido pertencer a ele
        if (tipo == 'pedido_atualizado' || tipo == 'pedido_adicionado') {
          try {
            final pedMap = dados['pedido'] as Map<String, dynamic>?;
            if (pedMap != null) {
              final pedCpf = pedMap['cpfCliente']?.toString().replaceAll(RegExp(r'\D'), '');
              final pedClienteId = pedMap['clienteId']?.toString();
              final termCpf = terminal?.cpf?.replaceAll(RegExp(r'\D'), '');
              final termId = terminal?.id;

              final ehMeuPedido = (termCpf != null && termCpf.isNotEmpty && termCpf == pedCpf) ||
                  (termId != null && termId.isNotEmpty && termId == pedClienteId);

              if (!ehMeuPedido) {
                continue;
              }
            }
          } catch (_) {}
        }
      }

      try {
        cliente.add(payload);
      } catch (_) {}
    }
  }
}

/// Manipulador desacoplado de eventos e mensagens WebSocket recebidas pelos clientes conectados.
class ServidorWsMessageHandler {
  static Future<void> processarMensagem(
    WebSocket ws,
    dynamic msg,
    ServidorWsContext ctx,
  ) async {
    try {
      final dados = await decodificarJsonMapaSeguro(msg as String);
      final tipo = dados['tipo'] as String?;

      if (tipo == 'ping') {
        ws.add(jsonEncode({
          'tipo': 'pong',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }));
        return;
      }

      if (tipo == 'logout' || tipo == 'desidentificacao') {
        _processarDesidentificacao(ws, ctx);
        return;
      }

      if (tipo == 'identificacao') {
        await _processarIdentificacao(ws, dados, ctx);
        return;
      }

      if (tipo == 'mensagem_chat') {
        await _processarMensagemChat(ws, dados, ctx);
        return;
      }

      if (tipo == 'mensagem_entregue') {
        final msgId = dados['id'] as String? ?? dados['mensagemId'] as String? ?? '';
        final convId = dados['conversaId'] as String?;
        await ChatService.processarMensagemEntregueDaRede(msgId, conversaId: convId);
        ctx.retransmitirParaOutros(jsonEncode(dados), exceto: ws);
        return;
      }

      if (tipo == 'mensagens_lidas') {
        final convId = dados['conversaId'] as String? ?? '';
        final idLeitor = dados['idLeitor'] as String? ?? '';
        await ChatService.processarMensagensLidasDaRede(convId, idLeitor);
        ctx.retransmitirParaOutros(jsonEncode(dados), exceto: ws);
        return;
      }

      if (tipo == 'mensagens_lidas_loja') {
        final lojaId = dados['lojaId'] as String? ?? '';
        final idLeitor = dados['idLeitor'] as String? ?? '';
        await ChatService.processarMensagensLidasDaLojaDaRede(lojaId, idLeitor);
        ctx.retransmitirParaOutros(jsonEncode(dados), exceto: ws);
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
        ctx.retransmitirParaOutros(jsonEncode(dados), exceto: ws);
        return;
      }

      if (tipo == 'conversa_atualizada') {
        if (dados['conversa'] != null) {
          final cMap = dados['conversa'] as Map<String, dynamic>;
          await ChatService.salvarConversaLocal(cMap);
          ctx.retransmitirParaOutros(jsonEncode(dados), exceto: ws);
        }
        return;
      }

      if (tipo == 'conversa_renomeada') {
        final convId = dados['conversaId'] as String?;
        final novoTit = dados['novoTitulo'] as String?;
        if (convId != null && novoTit != null) {
          await ChatService.renomearConversa(convId, novoTit, originadoDaRede: true);
          ctx.retransmitirParaOutros(jsonEncode(dados), exceto: ws);
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
          ctx.retransmitirParaOutros(jsonEncode(dados), exceto: ws);
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
        ctx.retransmitirParaOutros(jsonEncode(dados), exceto: ws);
        return;
      }

      if (tipo == 'usuario_atualizado') {
        await _processarUsuarioAtualizado(ws, dados, ctx);
        return;
      }

      if (tipo == 'usuario_nous_excluido') {
        await _processarUsuarioNousExcluido(ws, dados, ctx);
        return;
      }

      if (tipo == 'solicitacao_aceita') {
        final conversaId = dados['conversaId'] as String? ?? '';
        final cpf = dados['cpf'] as String? ?? '';
        await MensageriaSolicitacoesHelper.processarAceiteRemoto(
          conversaId: conversaId,
          meuCpf: cpf,
        );
        ctx.retransmitirParaOutros(jsonEncode(dados), exceto: ws);
        return;
      }

      if (tipo == 'pedido_atualizado' || tipo == 'pedido_adicionado') {
        _processarPedidoAtualizado(ws, dados, ctx);
        return;
      }

      if (tipo == 'cliente_atualizado') {
        _processarClienteAtualizado(ws, dados, ctx);
        return;
      }

      if (tipo == 'loja_excluida') {
        await _processarLojaExcluida(ws, dados, ctx);
        return;
      }

      if (tipo == 'novo_convite_loja') {
        await _processarNovoConviteLoja(ws, dados, ctx);
        return;
      }

      if (tipo == 'convite_loja_removido') {
        await _processarConviteLojaRemovido(ws, dados, ctx);
        return;
      }

      if (tipo != null && tipo.startsWith('chamada_')) {
        ctx.processarSinalChamadaLocal(dados);
        ctx.retransmitirParaOutros(jsonEncode(dados), exceto: ws);
        return;
      }
    } catch (_) {}
  }

  static void _processarDesidentificacao(WebSocket ws, ServidorWsContext ctx) {
    final terminal = ctx.terminaisWs[ws];
    if (terminal != null) {
      terminal.cpf = null;
      terminal.nomeUsuario = null;
      terminal.apelido = null;
      terminal.tipoConexao = 'desconhecido';
      ctx.atualizarListasTerminais();
      ctx.notificarPresencas();
      debugPrint(
        '[ServidorRedeLocal] Terminal deslogado/desidentificado: ${terminal.nome} (${terminal.ip})',
      );
    }
  }

  static Future<void> _processarIdentificacao(
    WebSocket ws,
    Map<String, dynamic> dados,
    ServidorWsContext ctx,
  ) async {
    final nome = dados['nomeDispositivo'] as String?;
    final cpf = dados['cpf'] as String?;
    final nomeUsuario = dados['nomeUsuario'] as String?;
    final apelido = dados['apelido'] as String?;
    final foto = dados['foto'] as String?;
    final terminal = ctx.terminaisWs[ws];
    if (terminal != null) {
      if (nome != null && nome.trim().isNotEmpty) {
        terminal.nome = nome.trim();
      }
      if (cpf != null && cpf.trim().isNotEmpty) {
        terminal.cpf = cpf.trim();
      }
      if (nomeUsuario != null && nomeUsuario.trim().isNotEmpty) {
        terminal.nomeUsuario = nomeUsuario.trim();
      }
      if (apelido != null && apelido.trim().isNotEmpty) {
        terminal.apelido = apelido.trim();
      }

      // Fecha e limpa conexões antigas duplicadas do mesmo CPF ou IP
      final cpfLimpoTerm = (cpf != null) ? ChatService.normalizarCpf(cpf) : '';
      final socketsParaRemover = <WebSocket>[];
      for (final entry in ctx.terminaisWs.entries) {
        if (entry.key != ws) {
          final outroTerm = entry.value;
          final outroCpfLimpo = outroTerm.cpf != null
              ? ChatService.normalizarCpf(outroTerm.cpf!)
              : '';
          final mesmoCpf =
              cpfLimpoTerm.isNotEmpty && outroCpfLimpo == cpfLimpoTerm;
          final mesmoIp = terminal.ip.isNotEmpty && outroTerm.ip == terminal.ip;
          final ehDuplicada = mesmoCpf ||
              (cpfLimpoTerm.isEmpty && outroCpfLimpo.isEmpty && mesmoIp);
          if (ehDuplicada) {
            socketsParaRemover.add(entry.key);
          }
        }
      }
      for (final velhoWs in socketsParaRemover) {
        ctx.clientesWs.remove(velhoWs);
        ctx.terminaisWs.remove(velhoWs);
        try {
          debugPrint(
            '[ServidorRedeLocal] Encerrando conexão duplicada anterior para CPF: $cpfLimpoTerm / IP: ${terminal.ip}',
          );
          velhoWs.close();
        } catch (_) {}
      }

      ctx.atualizarListasTerminais();
      debugPrint(
        '[ServidorRedeLocal] Terminal identificado: "${terminal.nome}" (CPF: ${terminal.cpf}, Nome: ${terminal.nomeUsuario}, Apelido: ${terminal.apelido}, IP: ${terminal.ip})',
      );

      ctx.consolidarContaTerminal(terminal);

      if (cpf != null && cpf.trim().isNotEmpty && foto != null && foto.trim().isNotEmpty) {
        final fotoResolvida = ImagemService.resolverCaminhoExistente(foto);
        if (fotoResolvida != null) {
          final c = await ContasNousService.buscarPorCpf(cpf.trim());
          if (c != null && (c.foto.isEmpty || !ImagemService.existe(c.foto) || c.foto != fotoResolvida)) {
            final atualizado = c.copyWith(foto: fotoResolvida);
            await ContasNousService.salvar(atualizado);
            ctx.authProvider?.atualizarContaNoCache(atualizado);
          }
        }
      }

      ctx.notificarPresencas();

      if (cpfLimpoTerm.isNotEmpty) {
        try {
          final convitesPendentes = await ConvitesService.carregar(cpfLimpoTerm);
          if (convitesPendentes.isNotEmpty) {
            ws.add(jsonEncode({
              'tipo': 'sincronizacao_convites',
              'convites': convitesPendentes.map((c) => c.toJson()).toList(),
            }));
            debugPrint(
              '[ServidorRedeLocal] Sincronizados ${convitesPendentes.length} convite(s) pendente(s) com terminal $cpfLimpoTerm',
            );
          }
        } catch (e) {
          debugPrint('[ServidorRedeLocal] Erro ao sincronizar convites com terminal: $e');
        }
      }

      // Drena quaisquer mensagens que estavam retidas na fila aguardando a conexão deste terminal
      ChatService.drenarFilaDeSaida();
    }
  }

  static Future<void> _processarMensagemChat(
    WebSocket ws,
    Map<String, dynamic> dados,
    ServidorWsContext ctx,
  ) async {
    if (dados['mensagem'] != null) {
      final msgJson = dados['mensagem'] as Map<String, dynamic>;
      final msg = MensagemChat.fromJson(msgJson);

      // 1. RETRANSMISSÃO IMEDIATA EM 0ms: entrega sem bloqueio de banco aos demais clientes
      final payload = jsonEncode({'tipo': 'mensagem_chat', 'mensagem': msgJson});
      ctx.retransmitirParaOutros(payload, exceto: ws);

      // 2. Persistência local e autocura de perfil em background sem atrasar o WebSocket
      // (A confirmação 'mensagem_entregue' será emitida por processarMensagemRecebidaDaRede
      // exclusivamente se este nó for o verdadeiro destinatário da mensagem)
      unawaited(() async {
        try {
          await ChatService.processarMensagemRecebidaDaRede(
            msgJson,
            emitirAlertaSonoro: true,
          );

          final cpfRemetente = ChatService.normalizarCpf(msg.remetenteId);
          if (cpfRemetente.length == 11 && msg.remetenteFoto.isNotEmpty) {
            final fotoResolvida = ImagemService.resolverCaminhoExistente(msg.remetenteFoto);
            if (fotoResolvida != null) {
              final c = await ContasNousService.buscarPorCpf(cpfRemetente);
              if (c != null && (c.foto.isEmpty || !ImagemService.existe(c.foto) || c.foto != fotoResolvida)) {
                final atualizado = c.copyWith(foto: fotoResolvida);
                await ContasNousService.salvar(atualizado);
                ctx.authProvider?.atualizarContaNoCache(atualizado);
              }
            }
          }
        } catch (e) {
          debugPrint('[ServidorRedeLocal] Erro em background ao persistir mensagem recebida: $e');
        }
      }());
    }
  }

  static Future<void> _processarUsuarioAtualizado(
    WebSocket ws,
    Map<String, dynamic> dados,
    ServidorWsContext ctx,
  ) async {
    if (dados['usuario'] != null) {
      try {
        final usuario = UsuarioNous.fromJson(dados['usuario'] as Map<String, dynamic>);
        await ContasNousService.salvar(usuario);
        ctx.authProvider?.atualizarContaNoCache(usuario);
        await ctx.authProvider?.carregarCacheContas();
        ctx.pdvProvider?.notificarMudanca();

        final payload = jsonEncode({
          'tipo': 'usuario_atualizado',
          'usuario': usuario.toJson(),
        });
        ctx.retransmitirParaOutros(payload, exceto: ws);
      } catch (e) {
        debugPrint('[ServidorRedeLocal] Erro ao processar usuario_atualizado via WS: $e');
      }
    }
  }

  static Future<void> _processarUsuarioNousExcluido(
    WebSocket ws,
    Map<String, dynamic> dados,
    ServidorWsContext ctx,
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
      ctx.retransmitirParaOutros(jsonEncode(dados), exceto: ws);
    } catch (e) {
      debugPrint('[ServidorRedeLocal] Erro ao processar usuario_nous_excluido: $e');
    }
  }

  static void _processarPedidoAtualizado(
    WebSocket ws,
    Map<String, dynamic> dados,
    ServidorWsContext ctx,
  ) {
    if (dados['pedido'] != null && ctx.pdvProvider != null) {
      final pedido = PedidoLoja.fromJson(dados['pedido'] as Map<String, dynamic>);
      final lojaAtiva = ctx.obterLojaAtiva();
      final lojaIdAlvo = pedido.lojaId.isNotEmpty
          ? pedido.lojaId
          : (dados['lojaId'] as String? ?? lojaAtiva?.id ?? '');
      if (lojaIdAlvo.isEmpty) return;

      final lojaAtual = ctx.pdvProvider!.buscarPorId(lojaIdAlvo);
      if (lojaAtual != null) {
        final pedidos = List<PedidoLoja>.from(lojaAtual.pedidosLoja);
        final idx = pedidos.indexWhere((p) => p.id == pedido.id);
        final ehNovo = idx == -1;
        if (idx != -1) {
          pedidos[idx] = pedido;
        } else {
          pedidos.insert(0, pedido);
        }
        ctx.pdvProvider!.atualizarListasLoja(lojaAtual.id, pedidos: pedidos);

        if (ehNovo) {
          SomService.tocarEvento(
            SomService.eventoNovoPedido,
            loja: lojaAtual,
          );
        }

        final payload = jsonEncode({
          'tipo': ehNovo ? 'pedido_adicionado' : 'pedido_atualizado',
          'lojaId': lojaAtual.id,
          'pedido': pedido.toJson(),
        });
        ctx.retransmitirParaOutros(payload, exceto: ws);
      }
    }
  }

  static void _processarClienteAtualizado(
    WebSocket ws,
    Map<String, dynamic> dados,
    ServidorWsContext ctx,
  ) {
    if (dados['cliente'] != null && ctx.pdvProvider != null) {
      final cliente = Cliente.fromJson(dados['cliente'] as Map<String, dynamic>);
      final lojaAtiva = ctx.obterLojaAtiva();
      final lojaIdAlvo = (dados['lojaId'] as String?)?.trim().isNotEmpty == true
          ? (dados['lojaId'] as String).trim()
          : (lojaAtiva?.id ?? '');
      if (lojaIdAlvo.isEmpty) return;

      final lojaAtual = ctx.pdvProvider!.buscarPorId(lojaIdAlvo);
      if (lojaAtual != null) {
        final clientes = List<Cliente>.from(lojaAtual.clientesLoja);
        final idx = clientes.indexWhere((c) => c.id == cliente.id);
        if (idx != -1) {
          clientes[idx] = cliente.copyWith(fretePadrao: clientes[idx].fretePadrao);
        } else {
          clientes.add(cliente);
        }
        ctx.pdvProvider!.atualizarListasLoja(lojaAtual.id, clientes: clientes);

        final payload = jsonEncode({
          'tipo': 'cliente_atualizado',
          'lojaId': lojaAtual.id,
          'cliente': cliente.toJson(),
        });
        ctx.retransmitirParaOutros(payload, exceto: ws);
      }
    }
  }

  static Future<void> _processarLojaExcluida(
    WebSocket ws,
    Map<String, dynamic> dados,
    ServidorWsContext ctx,
  ) async {
    final lojaId = dados['lojaId'] as String?;
    if (lojaId != null && ctx.pdvProvider != null) {
      await ctx.pdvProvider!.excluirLoja(lojaId, originadaDaRede: true);
      final payload = jsonEncode({'tipo': 'loja_excluida', 'lojaId': lojaId});
      ctx.retransmitirParaOutros(payload, exceto: ws);
    }
  }

  static Future<void> _processarNovoConviteLoja(
    WebSocket ws,
    Map<String, dynamic> dados,
    ServidorWsContext ctx,
  ) async {
    if (dados['convite'] != null) {
      try {
        final convite = ConviteLoja.fromJson(dados['convite'] as Map<String, dynamic>);
        Loja? lojaAnexa;
        if (dados['loja'] != null) {
          lojaAnexa = Loja.fromJson(dados['loja'] as Map<String, dynamic>);
          await LojasService.salvarLojaIndividual(lojaAnexa);
        }
        await ConvitesService.adicionar(
          convite.cpfConvidado,
          convite,
          originadoDaRede: true,
        );
        NotificacoesProvider.instanciaAtiva?.recarregarSeuCpf();

        final payload = jsonEncode({
          'tipo': 'novo_convite_loja',
          'convite': convite.toJson(),
          if (lojaAnexa != null) 'loja': lojaAnexa.toJson(),
        });
        ctx.retransmitirParaOutros(payload, exceto: ws);
        debugPrint(
          '[ServidorRedeLocal] Convite da loja "${convite.nomeLoja}" para ${convite.cpfConvidado} retransmitido na rede local.',
        );
      } catch (e) {
        debugPrint('[ServidorRedeLocal] Erro ao processar novo_convite_loja via WS: $e');
      }
    }
  }

  static Future<void> _processarConviteLojaRemovido(
    WebSocket ws,
    Map<String, dynamic> dados,
    ServidorWsContext ctx,
  ) async {
    final cpf = dados['cpf'] as String?;
    final conviteId = dados['conviteId'] as String?;
    if (cpf != null && conviteId != null) {
      await ConvitesService.remover(cpf, conviteId, originadoDaRede: true);
      NotificacoesProvider.instanciaAtiva?.recarregarSeuCpf();
      final payload = jsonEncode({
        'tipo': 'convite_loja_removido',
        'cpf': cpf,
        'conviteId': conviteId,
      });
      ctx.retransmitirParaOutros(payload, exceto: ws);
    }
  }
}
