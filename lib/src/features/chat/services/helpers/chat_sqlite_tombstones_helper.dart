import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Helper para operações SQLite de tombstones (`conversas_excluidas`) e estado de conversas.
class ChatSqliteTombstonesHelper {
  ChatSqliteTombstonesHelper._();

  static Future<List<String>> obterIdsConversasExcluidas(Database db) async {
    try {
      final rows = await db.query('conversas_excluidas');
      final idsExcluidos = <String>[];
      for (final r in rows) {
        final id = r['id'] as String? ?? '';
        final excluidaEmStr = r['excluida_em'] as String?;
        if (id.isEmpty) continue;
        if (excluidaEmStr != null) {
          final resNovas = await db.rawQuery(
            'SELECT COUNT(*) as qtd FROM mensagens_chat WHERE conversa_id = ? AND data_hora > ?',
            [id, excluidaEmStr],
          );
          final countNovas =
              (resNovas.isNotEmpty && resNovas.first['qtd'] != null)
                  ? (resNovas.first['qtd'] as num).toInt()
                  : 0;
          if (countNovas > 0) {
            await db.delete(
              'conversas_excluidas',
              where: 'id = ?',
              whereArgs: [id],
            );
            continue;
          }
        }
        idsExcluidos.add(id);
      }
      return idsExcluidos;
    } catch (_) {
      return [];
    }
  }

  static Future<bool> isConversaExcluida(
    Database db,
    String conversaId,
  ) async {
    try {
      final rows = await db.query(
        'conversas_excluidas',
        where: 'id = ?',
        whereArgs: [conversaId],
        limit: 1,
      );
      return rows.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<void> desmarcarConversaExcluida(
    Database db,
    String conversaId,
  ) async {
    try {
      await db.delete(
        'conversas_excluidas',
        where: 'id = ?',
        whereArgs: [conversaId],
      );
    } catch (_) {}
  }

  static Future<void> excluirConversaLocal(
    Database db,
    String conversaId,
  ) async {
    await db.insert('conversas_excluidas', {
      'id': conversaId,
      'excluida_em': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await db.delete(
      'mensagens_chat',
      where: 'conversa_id = ?',
      whereArgs: [conversaId],
    );
    await db.delete('conversas_chat', where: 'id = ?', whereArgs: [conversaId]);
  }

  static Future<bool> alternarSilenciarConversa(
    Database db,
    String conversaId,
  ) async {
    try {
      final rows = await db.query(
        'conversas_chat',
        columns: ['silenciada'],
        where: 'id = ?',
        whereArgs: [conversaId],
        limit: 1,
      );
      if (rows.isEmpty) return false;
      final atual = (rows.first['silenciada'] as int? ?? 0) == 1;
      final novoValor = atual ? 0 : 1;
      await db.update(
        'conversas_chat',
        {'silenciada': novoValor},
        where: 'id = ?',
        whereArgs: [conversaId],
      );
      return novoValor == 1;
    } catch (_) {
      return false;
    }
  }
}
