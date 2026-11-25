import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/features/pdv/models/referencia_loja.dart';

/// Repositório SQLite para persistência e consulta de [ReferenciaLoja] por CPF.
class ReferenciasRepositorioLoja {
  ReferenciasRepositorioLoja._();

  static Future<List<ReferenciaLoja>> carregar(
    String cpf, {
    bool Function(String? lojaId)? ehHostFalsa,
  }) async {
    final db = await BancoDadosService.db;
    final rows = await db.query(
      'referencias_loja',
      where: 'cpf = ?',
      whereArgs: [cpf],
    );
    return rows
        .map(
          (r) => ReferenciaLoja.fromJson(
            jsonDecode(r['dados_json'] as String) as Map<String, dynamic>,
          ),
        )
        .where((ref) => !(ehHostFalsa?.call(ref.lojaId) ?? false))
        .toList();
  }

  static Future<void> salvar(
    String cpf,
    List<ReferenciaLoja> referencias,
  ) async {
    final db = await BancoDadosService.db;
    await db.transaction((txn) async {
      await txn.delete(
        'referencias_loja',
        where: 'cpf = ?',
        whereArgs: [cpf],
      );
      for (final ref in referencias) {
        final refId = '$cpf-${ref.lojaId}';
        await txn.insert(
          'referencias_loja',
          {
            'id': refId,
            'cpf': cpf,
            'loja_id': ref.lojaId,
            'dados_json': jsonEncode(ref.toJson()),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  static Future<void> adicionar(
    String cpf,
    ReferenciaLoja referencia, {
    bool Function(String? lojaId)? ehHostFalsa,
  }) async {
    if (ehHostFalsa?.call(referencia.lojaId) ?? false) return;
    final atuais = await carregar(cpf, ehHostFalsa: ehHostFalsa);
    final jaTem = atuais.any((r) => r.lojaId == referencia.lojaId);
    if (jaTem) return;
    await salvar(cpf, [...atuais, referencia]);
  }

  static Future<void> remover(String cpf, String lojaId) async {
    final db = await BancoDadosService.db;
    await db.delete(
      'referencias_loja',
      where: 'cpf = ? AND loja_id = ?',
      whereArgs: [cpf, lojaId],
    );
  }
}
