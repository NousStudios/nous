import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/services/helpers/timeline_sqlite_utils.dart';

/// Helper SQLite para reações e comentários sociais.
class TimelineInteracoesSqliteHelper {
  TimelineInteracoesSqliteHelper._();

  static Future<void> salvarReacao(Database db, ReacaoSocial reacao) async {
    await db.insert(
      'reacoes_sociais',
      {
        'id': reacao.id,
        'publicacao_id': reacao.publicacaoId,
        'usuario_cpf': TimelineSqliteUtils.normalizarCpf(reacao.usuarioCpf),
        'tipo': reacao.tipo.name,
        'criada_em': reacao.criadaEm.toIso8601String(),
        'atualizada_em': reacao.atualizadaEfetiva.toIso8601String(),
        'dados_json': jsonEncode(reacao.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> removerReacao(
    Database db, {
    required String publicacaoId,
    required String usuarioCpf,
  }) async {
    final cpfNorm = TimelineSqliteUtils.normalizarCpf(usuarioCpf);
    final rows = await db.query(
      'reacoes_sociais',
      where: 'publicacao_id = ? AND usuario_cpf = ?',
      whereArgs: [publicacaoId, cpfNorm],
    );
    final agora = DateTime.now();
    for (final r in rows) {
      try {
        final reacao = ReacaoSocial.fromJson(
          TimelineSqliteUtils.decodificarDadosJson(r),
        );
        final tombstone = reacao.copyWith(
          excluida: true,
          atualizadaEm: agora,
        );
        await salvarReacao(db, tombstone);
      } catch (_) {}
    }
  }

  static Future<List<ReacaoSocial>> listarReacoesDaPublicacao(
    Database db,
    String publicacaoId,
  ) async {
    final rows = await db.query(
      'reacoes_sociais',
      where: 'publicacao_id = ?',
      whereArgs: [publicacaoId],
      orderBy: 'criada_em DESC',
    );
    return rows
        .map(
          (r) => ReacaoSocial.fromJson(
            TimelineSqliteUtils.decodificarDadosJson(r),
          ),
        )
        .where((r) => !r.excluida)
        .toList();
  }

  static Future<List<ReacaoSocial>> listarReacoesDoUsuario(
    Database db,
    String cpf,
  ) async {
    final cpfNorm = TimelineSqliteUtils.normalizarCpf(cpf);
    final rows = await db.query(
      'reacoes_sociais',
      where: 'usuario_cpf = ?',
      whereArgs: [cpfNorm],
      orderBy: 'criada_em DESC',
      limit: 100,
    );
    return rows
        .map(
          (r) => ReacaoSocial.fromJson(
            TimelineSqliteUtils.decodificarDadosJson(r),
          ),
        )
        .where((r) => !r.excluida)
        .toList();
  }

  static Future<void> salvarComentario(
    Database db,
    ComentarioSocial comentario,
  ) async {
    await db.insert(
      'comentarios_sociais',
      {
        'id': comentario.id,
        'publicacao_id': comentario.publicacaoId,
        'autor_cpf': TimelineSqliteUtils.normalizarCpf(comentario.autorCpf),
        'criada_em': comentario.criadaEm.toIso8601String(),
        'atualizada_em': comentario.atualizadaEfetiva.toIso8601String(),
        'excluido': comentario.excluido ? 1 : 0,
        'dados_json': jsonEncode(comentario.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<ComentarioSocial>> listarComentariosDaPublicacao(
    Database db,
    String publicacaoId,
  ) async {
    final rows = await db.query(
      'comentarios_sociais',
      where: 'publicacao_id = ? AND excluido = 0',
      whereArgs: [publicacaoId],
      orderBy: 'criada_em ASC',
    );
    return rows
        .map(
          (r) => ComentarioSocial.fromJson(
            TimelineSqliteUtils.decodificarDadosJson(r),
          ),
        )
        .toList();
  }

  static Future<List<ComentarioSocial>> listarComentariosDoUsuario(
    Database db,
    String cpf,
  ) async {
    final cpfNorm = TimelineSqliteUtils.normalizarCpf(cpf);
    final rows = await db.query(
      'comentarios_sociais',
      where: 'autor_cpf = ?',
      whereArgs: [cpfNorm],
      orderBy: 'criada_em DESC',
      limit: 100,
    );
    return rows
        .map(
          (r) => ComentarioSocial.fromJson(
            TimelineSqliteUtils.decodificarDadosJson(r),
          ),
        )
        .toList();
  }
}
