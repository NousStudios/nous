import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/helpers/timeline_sqlite_utils.dart';

/// Helper SQLite para stories sociais.
class TimelineStoriesSqliteHelper {
  TimelineStoriesSqliteHelper._();

  static Future<void> salvarStory(Database db, StorySocial story) async {
    await db.insert(
      'stories_sociais',
      {
        'id': story.id,
        'autor_cpf': TimelineSqliteUtils.normalizarCpf(story.autorCpf),
        'criado_em': story.criadoEm.toIso8601String(),
        'atualizada_em': story.atualizadoEfetivo.toIso8601String(),
        'expira_em': story.expiraEm?.toIso8601String(),
        'excluido': story.excluido ? 1 : 0,
        'arquivado': story.arquivado ? 1 : 0,
        'dados_json': jsonEncode(story.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<StorySocial>> listarStoriesDoUsuario(
    Database db,
    String cpf,
  ) async {
    final todos = await listarTodosStoriesDoUsuario(db, cpf);
    return todos.where((s) => s.estaAtivo).toList();
  }

  /// Lista todos os stories ativos (24h) da rede para a barra superior do Feed.
  static Future<List<StorySocial>> listarStoriesAtivosDaRede(
    Database db,
  ) async {
    final rows = await db.query(
      'stories_sociais',
      where: 'excluido = 0',
      orderBy: 'criado_em DESC',
      limit: 150,
    );
    final agora = DateTime.now();
    return rows
        .map(
          (r) => StorySocial.fromJson(
            TimelineSqliteUtils.decodificarDadosJson(r),
          ),
        )
        .where(
          (s) =>
              !s.excluido &&
              !s.arquivado &&
              s.estaAtivo &&
              agora.difference(s.criadoEm).inHours < 24,
        )
        .toList();
  }

  /// Lista todo o histórico de stories do usuário (inclusive expirados >24h)
  /// para o Arquivo e Calendário de Stories na página Conta.
  static Future<List<StorySocial>> listarTodosStoriesDoUsuario(
    Database db,
    String cpf,
  ) async {
    final cpfNorm = TimelineSqliteUtils.normalizarCpf(cpf);
    if (cpfNorm.isEmpty) return const [];
    final rows = await db.query(
      'stories_sociais',
      where: 'autor_cpf = ? AND excluido = 0',
      whereArgs: [cpfNorm],
      orderBy: 'criado_em DESC',
    );
    return rows
        .map(
          (r) => StorySocial.fromJson(
            TimelineSqliteUtils.decodificarDadosJson(r),
          ),
        )
        .toList();
  }

  /// Busca um story diretamente pelo ID (independente de expiração ou arquivamento).
  static Future<StorySocial?> buscarStoryPorId(
    Database db,
    String storyId,
  ) async {
    if (storyId.trim().isEmpty) return null;
    final rows = await db.query(
      'stories_sociais',
      where: 'id = ?',
      whereArgs: [storyId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return StorySocial.fromJson(
      TimelineSqliteUtils.decodificarDadosJson(rows.first),
    );
  }
}
