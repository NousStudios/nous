import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/features/notificacoes/models/convite_loja.dart';

class ConvitesService {
  ConvitesService._();

  static Future<List<ConviteLoja>> carregar(String cpf) async {
    final db = await BancoDadosService.db;
    final rows = await db.query(
      'convites',
      where: 'cpf_destinatario = ?',
      whereArgs: [cpf],
    );
    return rows
        .map((r) =>
            ConviteLoja.fromJson(jsonDecode(r['dados_json'] as String)))
        .toList();
  }

  static Future<void> salvar(String cpf, List<ConviteLoja> convites) async {
    final db = await BancoDadosService.db;
    await db.transaction((txn) async {
      await txn.delete(
        'convites',
        where: 'cpf_destinatario = ?',
        whereArgs: [cpf],
      );
      for (final c in convites) {
        await txn.insert(
          'convites',
          {
            'id': c.id,
            'cpf_destinatario': cpf,
            'dados_json': jsonEncode(c.toJson()),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  static Future<void> adicionar(String cpf, ConviteLoja convite) async {
    final db = await BancoDadosService.db;
    await db.insert(
      'convites',
      {
        'id': convite.id,
        'cpf_destinatario': cpf,
        'dados_json': jsonEncode(convite.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> remover(String cpf, String conviteId) async {
    final db = await BancoDadosService.db;
    await db.delete(
      'convites',
      where: 'cpf_destinatario = ? AND id = ?',
      whereArgs: [cpf, conviteId],
    );
  }
}