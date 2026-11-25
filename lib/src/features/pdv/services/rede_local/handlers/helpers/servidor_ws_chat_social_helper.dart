import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:nous/src/core/services/assinatura_rede_service.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/busca/services/mapa_espelhamento_service.dart';
import 'package:nous/src/features/chat/controllers/helpers/mensageria_solicitacoes_helper.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/handlers/servidor_ws_message_handler.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';

/// Helper para processamento de eventos de chat, social, timeline, mapa e chamadas no servidor WS.
class ServidorWsChatSocialHelper {
  /// Tenta processar eventos de chat, timeline, mapa e chamadas. Retorna `true` se tratado.
  static Future<bool> tentarProcessar(
    String? tipo,
    WebSocket ws,
    Map<String, dynamic> dados,
    ServidorWsContext ctx,
  ) async {
    if (tipo == 'mensagem_chat') {
      await processarMensagemChat(ws, dados, ctx);
      return true;
    }

    if (tipo == 'mensagem_entregue') {
      final msgId =
          dados['id'] as String? ?? dados['mensagemId'] as String? ?? '';
      final convId = dados['conversaId'] as String?;
      await ChatService.processarMensagemEntregueDaRede(
        msgId,
        conversaId: convId,
      );
      ctx.retransmitirParaOutros(jsonEncode(dados), exceto: ws);
      return true;
    }

    if (tipo == 'mensagens_lidas') {
      final convId = dados['conversaId'] as String? ?? '';
      final idLeitor = dados['idLeitor'] as String? ?? '';
      await ChatService.processarMensagensLidasDaRede(convId, idLeitor);
      ctx.retransmitirParaOutros(jsonEncode(dados), exceto: ws);
      return true;
    }

    if (tipo == 'mensagens_lidas_loja') {
      final lojaId = dados['lojaId'] as String? ?? '';
      final idLeitor = dados['idLeitor'] as String? ?? '';
      await ChatService.processarMensagensLidasDaLojaDaRede(lojaId, idLeitor);
      ctx.retransmitirParaOutros(jsonEncode(dados), exceto: ws);
      return true;
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
      return true;
    }

    if (tipo == 'conversa_atualizada') {
      if (dados['conversa'] != null) {
        final cMap = dados['conversa'] as Map<String, dynamic>;
        await ChatService.salvarConversaLocal(cMap);
        ctx.retransmitirParaOutros(jsonEncode(dados), exceto: ws);
      }
      return true;
    }

    if (tipo == 'conversa_renomeada') {
      final convId = dados['conversaId'] as String?;
      final novoTit = dados['novoTitulo'] as String?;
      if (convId != null && novoTit != null) {
        await ChatService.renomearConversa(
          convId,
          novoTit,
          originadoDaRede: true,
        );
        ctx.retransmitirParaOutros(jsonEncode(dados), exceto: ws);
      }
      return true;
    }

    if (tipo == 'conversa_excluida') {
      final convId = dados['conversaId'] as String?;
      if (convId != null) {
        await ChatService.excluirConversaLocal(convId, originadoDaRede: true);
        ctx.retransmitirParaOutros(jsonEncode(dados), exceto: ws);
      }
      return true;
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
      return true;
    }

    if (tipo == 'solicitacao_aceita') {
      final conversaId = dados['conversaId'] as String? ?? '';
      final cpf = dados['cpf'] as String? ?? '';
      await MensageriaSolicitacoesHelper.processarAceiteRemoto(
        conversaId: conversaId,
        meuCpf: cpf,
      );
      ctx.retransmitirParaOutros(jsonEncode(dados), exceto: ws);
      return true;
    }

    if (tipo == 'mapa_navegacao_sync') {
      MapaEspelhamentoService.instancia.receberEventoRede(
        dados,
        ctx.authProvider?.cpf,
      );
      ctx.retransmitirParaOutros(jsonEncode(dados), exceto: ws);
      return true;
    }

    if (tipo != null && tipo.startsWith('chamada_')) {
      ctx.processarSinalChamadaLocal(dados);
      ctx.retransmitirParaOutros(jsonEncode(dados), exceto: ws);
      return true;
    }

    if (tipo != null && tipo.startsWith('timeline_')) {
      final assinaturaValida = await AssinaturaRedeService.verificarPayload(
        dados,
      );
      if (!assinaturaValida) {
        return true;
      }
      await TimelineService.processarEventoRemoto(dados);
      ctx.retransmitirParaOutros(jsonEncode(dados), exceto: ws);
      return true;
    }

    return false;
  }

  static Future<void> processarMensagemChat(
    WebSocket ws,
    Map<String, dynamic> dados,
    ServidorWsContext ctx,
  ) async {
    if (dados['mensagem'] == null) return;
    final msgJson = dados['mensagem'] as Map<String, dynamic>;
    final msg = MensagemChat.fromJson(msgJson);

    // 1. Retransmissão imediata em 0ms: entrega sem bloqueio de banco aos demais clientes
    final payload = jsonEncode({'tipo': 'mensagem_chat', 'mensagem': msgJson});
    ctx.retransmitirParaOutros(payload, exceto: ws);

    // 2. Persistência local e autocura de perfil em background sem atrasar o WebSocket
    unawaited(() async {
      try {
        await ChatService.processarMensagemRecebidaDaRede(
          msgJson,
          emitirAlertaSonoro: true,
        );

        final cpfRemetente = ChatService.normalizarCpf(msg.remetenteId);
        if (cpfRemetente.length == 11 && msg.remetenteFoto.isNotEmpty) {
          final fotoResolvida = ImagemService.resolverCaminhoExistente(
            msg.remetenteFoto,
          );
          if (fotoResolvida != null) {
            final c = await ContasNousService.buscarPorCpf(cpfRemetente);
            if (c != null &&
                (c.foto.isEmpty ||
                    !ImagemService.existe(c.foto) ||
                    c.foto != fotoResolvida)) {
              final atualizado = c.copyWith(foto: fotoResolvida);
              await ContasNousService.salvar(atualizado);
              ctx.authProvider?.atualizarContaNoCache(atualizado);
            }
          }
        }
      } catch (e) {
        debugPrint(
          '[ServidorRedeLocal] Erro em background ao persistir mensagem recebida: $e',
        );
      }
    }());
  }
}
