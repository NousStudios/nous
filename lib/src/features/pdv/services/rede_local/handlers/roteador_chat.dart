import 'dart:convert';
import 'dart:io';

import 'package:nous/src/core/utils/json_isolate_utils.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

/// Roteador responsável pelos endpoints REST de Mensageria e Chat no Servidor Local.
class RoteadorChat {
  RoteadorChat._();

  static Future<bool> atender(
    HttpRequest request, {
    required ServidorRedeLocal servidor,
  }) async {
    final path = request.uri.path;

    // 1. Envio de mensagem de chat via REST (fallback e redundância)
    if (path == '/api/chat/mensagem' && request.method == 'POST') {
      try {
        final body = await utf8.decodeStream(request);
        final dados = await decodificarJsonMapaSeguro(body);
        final msgJson = dados['mensagem'] as Map<String, dynamic>? ?? dados;
        await ChatService.processarMensagemRecebidaDaRede(
          msgJson,
          emitirAlertaSonoro: false,
        );
        servidor.notificarTodos({'tipo': 'mensagem_chat', 'mensagem': msgJson});
        ServidorRedeLocal.responderJson(request, {'sucesso': true, 'entregue': true});
        return true;
      } catch (e) {
        ServidorRedeLocal.responderJson(
          request,
          {'sucesso': false, 'erro': e.toString()},
          statusCode: HttpStatus.internalServerError,
        );
        return true;
      }
    }

    // 2. Sincronização de mensagens de chat pela rede Wi-Fi
    if (path == '/api/chat/mensagens' && request.method == 'GET') {
      try {
        final cpf = request.uri.queryParameters['cpf'];
        final lojaId = request.uri.queryParameters['lojaId'];
        final mensagens = await ChatService.obterMensagensParaSincronizacao(
          cpf: cpf,
          lojaId: lojaId,
        );
        ServidorRedeLocal.responderJson(
          request,
          {'sucesso': true, 'mensagens': mensagens},
        );
        return true;
      } catch (e) {
        ServidorRedeLocal.responderJson(
          request,
          {'sucesso': false, 'erro': e.toString()},
          statusCode: HttpStatus.internalServerError,
        );
        return true;
      }
    }

    // 3. Sincronização de conversas e grupos pela rede Wi-Fi (GET)
    if (path == '/api/chat/conversas' && request.method == 'GET') {
      try {
        final cpf = request.uri.queryParameters['cpf'];
        final lojaId = request.uri.queryParameters['lojaId'];
        final conversas = await ChatService.obterConversasParaSincronizacao(
          cpf: cpf,
          lojaId: lojaId,
        );
        final excluidas = await ChatService.obterIdsConversasExcluidas();
        ServidorRedeLocal.responderJson(request, {
          'sucesso': true,
          'conversas': conversas,
          'excluidas': excluidas,
        });
        return true;
      } catch (e) {
        ServidorRedeLocal.responderJson(
          request,
          {'sucesso': false, 'erro': e.toString()},
          statusCode: HttpStatus.internalServerError,
        );
        return true;
      }
    }

    // 4. Sincronização bidirecional enviada pelo cliente terminal móvel (POST)
    if (path == '/api/chat/conversas/sync' && request.method == 'POST') {
      try {
        final body = await utf8.decodeStream(request);
        final dados = await decodificarJsonMapaSeguro(body);

        // Processa exclusões vindas do terminal móvel
        if (dados['excluidas'] is List) {
          for (final id in dados['excluidas'] as List<dynamic>) {
            if (id is String && id.isNotEmpty) {
              await ChatService.excluirConversaLocal(id);
            }
          }
        }

        int alteracoes = 0;
        if (dados['conversas'] is List) {
          final excluidasLocais = await ChatService.obterIdsConversasExcluidas();
          for (final c in dados['conversas'] as List<dynamic>) {
            if (c is Map<String, dynamic>) {
              final id = c['id'] as String? ?? '';
              if (!excluidasLocais.contains(id)) {
                final alterou = await ChatService.salvarConversaLocal(c, notificar: false);
                if (alterou) alteracoes++;
              }
            }
          }
        }
        if (dados['mensagens'] is List) {
          for (final m in dados['mensagens'] as List<dynamic>) {
            if (m is Map<String, dynamic>) {
              final msg = MensagemChat.fromJson(m);
              final alterou = await ChatService.salvarMensagem(
                msg,
                originadaDaRede: true,
                notificar: false,
              );
              if (alterou) alteracoes++;
            }
          }
        }
        if (alteracoes > 0) {
          ChatService.notificarAlteracao();
        }
        ServidorRedeLocal.responderJson(request, {'sucesso': true});
        return true;
      } catch (e) {
        ServidorRedeLocal.responderJson(
          request,
          {'sucesso': false, 'erro': e.toString()},
          statusCode: HttpStatus.internalServerError,
        );
        return true;
      }
    }

    return false;
  }
}
