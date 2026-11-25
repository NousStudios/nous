import 'package:flutter/foundation.dart';
import 'package:nous/src/features/chat/services/chat_outbox_e_recibos_service.dart';
import 'package:nous/src/features/chat/services/chat_repositorio_sqlite.dart';
import 'package:nous/src/features/chat/services/chat_sincronizacao_service.dart';

/// Helper para processamento e despacho de recibos de entrega e leitura em rede local.
class ChatRecibosRedeHelper {
  ChatRecibosRedeHelper._();

  /// Identifica se uma conversa é coletiva (grupos, tópicos da Ágora Digital, comunidade ou chat de equipe)
  static bool ehConversaColetivaOuGrupo(String conversaId) {
    if (conversaId.isEmpty) return false;
    if (conversaId.startsWith('grupo_') ||
        conversaId.startsWith('topico_') ||
        conversaId.startsWith('comunidade_') ||
        conversaId.startsWith('loja_nous_coletiva_')) {
      return true;
    }
    return false;
  }

  /// Processa evento de entrega de mensagem recebido da rede local (2 checks cinzas)
  static Future<void> processarMensagemEntregueDaRede(
    String msgId, {
    String? conversaId,
    required VoidCallback aoNotificar,
  }) async {
    if (msgId.isEmpty) return;
    try {
      final db = await ChatRepositorioSqlite.obterDb();
      final alterou = await db.update(
        'mensagens_chat',
        {'status_envio': 'entregue', 'entregue': 1},
        where: 'id = ? AND status_envio != "lida"',
        whereArgs: [msgId],
      );
      if (alterou > 0) {
        await ChatOutboxERecibosService.registrarEntrega(
          msgId,
          conversaId ?? 'rede',
        );
        aoNotificar();
      }
    } catch (e) {
      debugPrint(
        '[ChatService] Erro ao processar mensagem entregue da rede: $e',
      );
    }
  }

  /// Processa confirmação de mensagens lidas recebida da rede local (2 checks azuis)
  static Future<void> processarMensagensLidasDaRede(
    String conversaId,
    String idLeitor, {
    required void Function({bool imediato}) aoNotificar,
  }) async {
    if (conversaId.isEmpty || idLeitor.isEmpty) return;
    try {
      final db = await ChatRepositorioSqlite.obterDb();

      // Em grupos e tópicos coletivos (Ágora Digital, equipe, etc.), uma leitura individual
      // NÃO passa a mensagem para azul (lida). Mantém em 'entregue' (2 checks cinzas).
      if (ehConversaColetivaOuGrupo(conversaId)) {
        await ChatOutboxERecibosService.registrarLeituraConversa(
          conversaId,
          idLeitor,
        );
        final alterou = await db.update(
          'mensagens_chat',
          {'status_envio': 'entregue', 'entregue': 1},
          where: 'conversa_id = ? AND status_envio = "enviada"',
          whereArgs: [conversaId],
        );
        if (alterou > 0) {
          aoNotificar();
        }
        return;
      }

      int alterou = 0;
      if (conversaId.startsWith('loja_')) {
        final leitorDigits = idLeitor.replaceAll(RegExp(r'\D'), '');
        final ehLeituraDaLoja =
            idLeitor.startsWith('loja_') || leitorDigits.length != 11;
        if (ehLeituraDaLoja) {
          // A loja leu a conversa: mensagens do cliente viram lidas
          alterou = await db.update(
            'mensagens_chat',
            {'status_envio': 'lida', 'lida': 1},
            where:
                'conversa_id = ? AND status_envio != "lida" AND remetente_id NOT LIKE "loja_%"',
            whereArgs: [conversaId],
          );
        } else {
          // O cliente leu a conversa: mensagens da loja viram lidas
          alterou = await db.update(
            'mensagens_chat',
            {'status_envio': 'lida', 'lida': 1},
            where:
                'conversa_id = ? AND status_envio != "lida" AND remetente_id LIKE "loja_%"',
            whereArgs: [conversaId],
          );
          if (alterou == 0) {
            final leitorNorm = ChatRepositorioSqlite.normalizarCpf(idLeitor);
            alterou = await db.update(
              'mensagens_chat',
              {'status_envio': 'lida', 'lida': 1},
              where:
                  'conversa_id = ? AND status_envio != "lida" AND remetente_id NOT IN (?, ?, ?)',
              whereArgs: [conversaId, idLeitor, leitorNorm, 'user_$leitorNorm'],
            );
          }
        }
      } else {
        // Em conversas 1:1 normais entre usuários
        final leitorNorm = ChatRepositorioSqlite.normalizarCpf(idLeitor);
        alterou = await db.update(
          'mensagens_chat',
          {'status_envio': 'lida', 'lida': 1},
          where:
              'conversa_id = ? AND status_envio != "lida" AND remetente_id NOT IN (?, ?, ?)',
          whereArgs: [conversaId, idLeitor, leitorNorm, 'user_$leitorNorm'],
        );
      }
      if (alterou > 0) {
        await ChatOutboxERecibosService.registrarLeituraConversa(
          conversaId,
          idLeitor,
        );
        aoNotificar(imediato: true);
      }
    } catch (e) {
      debugPrint(
        '[ChatService] Erro ao processar mensagens lidas da rede: $e',
      );
    }
  }

  static Future<void> marcarComoLidas(
    String conversaId,
    String idLeitor, {
    bool notificar = true,
    required VoidCallback aoNotificar,
  }) async {
    final alterou = await ChatRepositorioSqlite.marcarComoLidas(
      conversaId,
      idLeitor,
    );
    if (notificar && alterou) {
      aoNotificar();
    }
    ChatSincronizacaoService.despacharConfirmacaoLida(conversaId, idLeitor);
  }

  static Future<void> marcarMensagensDaLojaComoLidas(
    String lojaId,
    String idLeitor, {
    required VoidCallback aoNotificar,
  }) async {
    final alterou =
        await ChatRepositorioSqlite.marcarMensagensDaLojaComoLidas(
      lojaId,
      idLeitor,
    );
    if (alterou) {
      aoNotificar();
    }
    ChatSincronizacaoService.despacharEventoRede({
      'tipo': 'mensagens_lidas_loja',
      'lojaId': lojaId,
      'idLeitor': idLeitor,
    });
  }

  static Future<void> processarMensagensLidasDaLojaDaRede(
    String lojaId,
    String idLeitor, {
    required VoidCallback aoNotificar,
  }) async {
    if (lojaId.isEmpty) return;
    try {
      final alterou =
          await ChatRepositorioSqlite.marcarMensagensDaLojaComoLidas(
        lojaId,
        idLeitor,
      );
      if (alterou) {
        aoNotificar();
      }
    } catch (e) {
      debugPrint(
        '[ChatService] Erro ao processar mensagens_lidas_loja da rede: $e',
      );
    }
  }

  static Future<void> marcarMensagensDoUsuarioComoLidas(
    String cpf,
    List<String> conversaIds, {
    required void Function({bool imediato}) aoNotificar,
  }) async {
    final cpfNorm = ChatRepositorioSqlite.normalizarCpf(cpf);
    if (cpfNorm.isEmpty) return;
    for (final convId in conversaIds.toSet()) {
      await ChatRepositorioSqlite.marcarComoLidas(convId, cpfNorm);
      ChatSincronizacaoService.despacharConfirmacaoLida(convId, cpfNorm);
    }
    aoNotificar(imediato: true);
  }
}
