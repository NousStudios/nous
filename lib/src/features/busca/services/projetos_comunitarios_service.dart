import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/features/busca/models/projeto_comunitario.dart';

/// Persistência soberana local dos Projetos Comunitários no Mapa (Autogestão Social).
class ProjetosComunitariosService {
  ProjetosComunitariosService._();

  static bool _tabelaGarantida = false;

  static Future<Database> _db() async {
    final db = await BancoDadosService.db;
    if (!_tabelaGarantida) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS projetos_comunitarios (
          id TEXT PRIMARY KEY,
          dados_json TEXT NOT NULL,
          atualizado_em TEXT NOT NULL
        );
      ''');
      _tabelaGarantida = true;
    }
    return db;
  }

  static Future<List<ProjetoComunitario>> listarTodos() async {
    final db = await _db();
    final rows = await db.query(
      'projetos_comunitarios',
      orderBy: 'atualizado_em DESC',
    );
    final lista = <ProjetoComunitario>[];
    for (final row in rows) {
      try {
        final map =
            jsonDecode(row['dados_json'] as String) as Map<String, dynamic>;
        lista.add(ProjetoComunitario.fromJson(map));
      } catch (_) {}
    }
    return lista;
  }

  static Future<void> salvar(ProjetoComunitario projeto) async {
    final db = await _db();
    await db.insert(
      'projetos_comunitarios',
      {
        'id': projeto.id,
        'dados_json': jsonEncode(projeto.toJson()),
        'atualizado_em': projeto.atualizadoEm.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<ProjetoComunitario> alternarApoio({
    required ProjetoComunitario projeto,
    required String cpfUsuario,
  }) async {
    final cpfNorm = cpfUsuario.replaceAll(RegExp(r'\D'), '');
    if (cpfNorm.isEmpty) return projeto;
    final apoiadores = List<String>.from(projeto.apoiadoresCpfs);
    if (apoiadores.contains(cpfNorm)) {
      apoiadores.remove(cpfNorm);
    } else {
      apoiadores.add(cpfNorm);
    }
    final atualizado = projeto.copyWith(
      apoiadoresCpfs: apoiadores,
      atualizadoEm: DateTime.now(),
    );
    await salvar(atualizado);
    return atualizado;
  }

  static Future<ProjetoComunitario> assumirResponsabilidade({
    required ProjetoComunitario projeto,
    required String cpfUsuario,
    required String nomeUsuario,
  }) async {
    final atualizado = projeto.copyWith(
      responsavelCpf: cpfUsuario.replaceAll(RegExp(r'\D'), ''),
      responsavelNome: nomeUsuario,
      status: StatusProjetoComunitario.emAndamento,
      atualizadoEm: DateTime.now(),
    );
    await salvar(atualizado);
    return atualizado;
  }

  static Future<ProjetoComunitario> atualizarStatus({
    required ProjetoComunitario projeto,
    required StatusProjetoComunitario status,
  }) async {
    final atualizado = projeto.copyWith(
      status: status,
      atualizadoEm: DateTime.now(),
    );
    await salvar(atualizado);
    return atualizado;
  }
}
