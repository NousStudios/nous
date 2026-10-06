import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';

class ContasNousService {
  ContasNousService._();

  static Future<List<UsuarioNous>> carregarTodas() async {
    final db = await BancoDadosService.db;
    final rows = await db.query('contas_usuarios');
    return rows
        .map((r) =>
            UsuarioNous.fromJson(jsonDecode(r['dados_json'] as String)))
        .toList();
  }

  static Future<UsuarioNous?> buscarPorCpf(String cpf) async {
    final db = await BancoDadosService.db;
    final rows = await db.query(
      'contas_usuarios',
      where: 'cpf = ?',
      whereArgs: [cpf],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UsuarioNous.fromJson(
        jsonDecode(rows.first['dados_json'] as String));
  }

  static Future<String?> buscarCpfDoEmail(String email) async {
    final contas = await carregarTodas();
    for (final conta in contas) {
      if (conta.emails.contains(email)) return conta.cpf;
    }
    return null;
  }

  static Future<void> salvar(UsuarioNous conta) async {
    final db = await BancoDadosService.db;
    await db.insert(
      'contas_usuarios',
      {
        'cpf': conta.cpf,
        'nome': conta.nome,
        'dados_json': jsonEncode(conta.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> excluir(String cpf) async {
    final db = await BancoDadosService.db;
    await db.delete(
      'contas_usuarios',
      where: 'cpf = ?',
      whereArgs: [cpf],
    );
  }
}