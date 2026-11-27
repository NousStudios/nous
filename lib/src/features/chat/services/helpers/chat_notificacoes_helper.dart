import 'package:flutter/foundation.dart';
import 'package:nous/src/core/services/preferencias_soberanas_service.dart';
import 'package:nous/src/features/chat/services/chat_repositorio_sqlite.dart';
import 'package:nous/src/features/chat/services/chat_sincronizacao_service.dart';

/// Helper para gerenciamento de silenciamento e notificações de conversas.
class ChatNotificacoesHelper {
  ChatNotificacoesHelper._();

  static const String _chaveConversasSilenciadas =
      'nous_conversas_silenciadas';

  static Future<bool> alternarSilenciarConversa(
    String conversaId, {
    required void Function({bool imediato}) aoNotificar,
  }) async {
    final res = await ChatRepositorioSqlite.alternarSilenciarConversa(
      conversaId,
    );
    final db = await ChatRepositorioSqlite.obterDb();
    final atualizada = await db.query(
      'conversas_chat',
      where: 'id = ?',
      whereArgs: [conversaId],
      limit: 1,
    );
    if (atualizada.isNotEmpty) {
      ChatSincronizacaoService.despacharEventoRede({
        'tipo': 'conversa_atualizada',
        'conversa': Map<String, dynamic>.from(atualizada.first),
      });
    }
    aoNotificar(imediato: true);
    return res;
  }

  static Future<bool> deveNotificarConversa(String conversaId) async {
    try {
      final db = await ChatRepositorioSqlite.obterDb();
      final rows = await db.query(
        'conversas_chat',
        columns: ['silenciada'],
        where: 'id = ?',
        whereArgs: [conversaId],
        limit: 1,
      );
      if (rows.isNotEmpty && (rows.first['silenciada'] as int? ?? 0) == 1) {
        return false;
      }
      final silenciadas = await PreferenciasSoberanasService.obterLista(
        _chaveConversasSilenciadas,
      );
      return !silenciadas.contains(conversaId);
    } catch (_) {
      return true;
    }
  }

  static Future<void> alternarNotificacaoConversa(
    String conversaId,
    bool notificar, {
    required VoidCallback aoNotificar,
  }) async {
    try {
      final silenciadas = (await PreferenciasSoberanasService.obterLista(
        _chaveConversasSilenciadas,
      ))
          .toSet();
      if (notificar) {
        silenciadas.remove(conversaId);
      } else {
        silenciadas.add(conversaId);
      }
      await PreferenciasSoberanasService.salvarLista(
        _chaveConversasSilenciadas,
        silenciadas.toList(),
      );
      aoNotificar();
    } catch (e) {
      debugPrint(
        '[ChatService] Erro ao alternar notificação de conversa: $e',
      );
    }
  }
}
