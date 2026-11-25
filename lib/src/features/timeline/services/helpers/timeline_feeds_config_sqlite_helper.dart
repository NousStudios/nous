import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/helpers/timeline_sqlite_utils.dart';

/// Helper SQLite para feeds personalizados, timelines visíveis e abas de descoberta.
class TimelineFeedsConfigSqliteHelper {
  TimelineFeedsConfigSqliteHelper._();

  static Future<void> salvarFeedPersonalizado(
    Database db,
    FeedPersonalizado feed,
  ) async {
    await db.insert(
      'feeds_personalizados',
      {
        'id': feed.id,
        'dono_cpf': TimelineSqliteUtils.normalizarCpf(feed.donoCpf),
        'criado_em': feed.criadoEm.toIso8601String(),
        'dados_json': jsonEncode(feed.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> removerFeedPersonalizado(Database db, String id) async {
    await db.delete('feeds_personalizados', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<FeedPersonalizado>> listarFeedsPersonalizados(
    Database db,
    String cpf,
  ) async {
    final cpfNorm = TimelineSqliteUtils.normalizarCpf(cpf);
    final rows = await db.query(
      'feeds_personalizados',
      where: 'dono_cpf = ?',
      whereArgs: [cpfNorm],
      orderBy: 'criado_em ASC',
    );
    return rows
        .map(
          (r) => FeedPersonalizado.fromJson(
            TimelineSqliteUtils.decodificarDadosJson(r),
          ),
        )
        .toList();
  }

  static Future<List<String>?> carregarTimelinesVisiveis(
    Database db,
    String cpf,
  ) async {
    final cpfNorm = TimelineSqliteUtils.normalizarCpf(cpf);
    final rows = await db.query(
      'timelines_visiveis_perfil',
      where: 'cpf = ?',
      whereArgs: [cpfNorm],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final lista = jsonDecode(rows.first['tipos_json'] as String? ?? '[]');
    if (lista is List) return lista.map((e) => e.toString()).toList();
    return null;
  }

  static Future<void> salvarTimelinesVisiveis(
    Database db,
    String cpf,
    List<String> tipos,
  ) async {
    final cpfNorm = TimelineSqliteUtils.normalizarCpf(cpf);
    await db.insert(
      'timelines_visiveis_perfil',
      {
        'cpf': cpfNorm,
        'tipos_json': jsonEncode(tipos.toSet().toList()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>?> carregarAbasDescoberta(
    Database db,
    String cpf,
  ) async {
    final cpfNorm = TimelineSqliteUtils.normalizarCpf(cpf);
    final rows = await db.query(
      'descoberta_tags_config',
      where: 'cpf = ?',
      whereArgs: [cpfNorm],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final decoded = jsonDecode(rows.first['abas_json'] as String? ?? '[]');
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return null;
  }

  static Future<void> salvarAbasDescoberta(
    Database db,
    String cpf,
    List<Map<String, dynamic>> abas,
  ) async {
    final cpfNorm = TimelineSqliteUtils.normalizarCpf(cpf);
    await db.insert(
      'descoberta_tags_config',
      {
        'cpf': cpfNorm,
        'abas_json': jsonEncode(abas),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
