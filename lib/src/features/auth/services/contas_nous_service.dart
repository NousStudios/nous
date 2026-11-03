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
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
    final rows = await db.query(
      'contas_usuarios',
      where:
          "cpf = ? OR cpf = ? OR REPLACE(REPLACE(REPLACE(cpf, '.', ''), '-', ''), ' ', '') = ?",
      whereArgs: [cpf, cpfLimpo, cpfLimpo],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UsuarioNous.fromJson(
        jsonDecode(rows.first['dados_json'] as String));
  }

  static Future<List<UsuarioNous>> buscarPorTermo(String termo) async {
    final contas = await carregarTodas();
    if (termo.isEmpty) return contas;
    final t = termo.trim().toLowerCase();
    final tSemArroba = t.startsWith('@') ? t.substring(1) : t;
    final digitos = t.replaceAll(RegExp(r'\D'), '');

    return contas.where((c) {
      if (c.nome.toLowerCase().contains(t) ||
          c.nomeExibicao.toLowerCase().contains(t)) {
        return true;
      }
      if (c.nomeDeUsuario.toLowerCase().contains(tSemArroba) ||
          c.usernameExibicao.toLowerCase().contains(tSemArroba)) {
        return true;
      }
      if (c.apelido.toLowerCase().contains(t) ||
          c.apelidoExibicao.toLowerCase().contains(t)) {
        return true;
      }
      if (digitos.isNotEmpty &&
          c.cpf.replaceAll(RegExp(r'\D'), '').contains(digitos)) {
        return true;
      }
      return false;
    }).toList();
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
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
    final db = await BancoDadosService.db;
    await db.delete(
      'contas_usuarios',
      where:
          "cpf = ? OR cpf = ? OR REPLACE(REPLACE(REPLACE(cpf, '.', ''), '-', ''), ' ', '') = ?",
      whereArgs: [cpf, cpfLimpo, cpfLimpo],
    );
  }
}