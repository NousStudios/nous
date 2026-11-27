import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/notificacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/models/salvos_denuncia_social.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/helpers/timeline_feeds_config_sqlite_helper.dart';
import 'package:nous/src/features/timeline/services/helpers/timeline_interacoes_sqlite_helper.dart';
import 'package:nous/src/features/timeline/services/helpers/timeline_salvos_denuncias_sqlite_helper.dart';
import 'package:nous/src/features/timeline/services/helpers/timeline_sqlite_utils.dart';
import 'package:nous/src/features/timeline/services/helpers/timeline_stories_sqlite_helper.dart';
import 'package:nous/src/features/timeline/services/timeline_schema_sqlite.dart';
import 'package:nous/src/features/timeline/services/timeline_sync_service.dart';

/// Repositório SQLite indexado para publicações, coautorias ilimitadas,
/// reações (Like/Deslike), comentários, stories e feeds personalizados.
class TimelineRepositorioSqlite {
  TimelineRepositorioSqlite._();

  static bool _tabelasGarantidas = false;
  static Future<void>? _garantindoEmVoo;
  static Database? _dbParaTeste;

  @visibleForTesting
  static void definirDbParaTestes(Database db) {
    _dbParaTeste = db;
    _tabelasGarantidas = false;
    _garantindoEmVoo = null;
  }

  static Future<Database> obterDb() async {
    final db = _dbParaTeste ?? await BancoDadosService.db;
    if (!_tabelasGarantidas) {
      _garantindoEmVoo ??= TimelineSchemaSqlite.garantirTabelas(db).then((_) {
        _tabelasGarantidas = true;
      }).whenComplete(() {
        _garantindoEmVoo = null;
      });
      await _garantindoEmVoo;
    }
    return db;
  }

  static void resetarCacheSchemaParaTeste() {
    _tabelasGarantidas = false;
    _garantindoEmVoo = null;
  }

  static Future<void> garantirTabelas(Database db) =>
      TimelineSchemaSqlite.garantirTabelas(db);

  static Future<void> salvarNotificacaoSocial(NotificacaoSocial notif) async {
    final db = await obterDb();
    await db.insert(
      'notificacoes_sociais',
      {
        'id': notif.id,
        'destinatario_cpf': normalizarCpf(notif.destinatarioCpf),
        'criada_em': notif.criadaEm.toIso8601String(),
        'lida': notif.lida ? 1 : 0,
        'dados_json': jsonEncode(notif.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<NotificacaoSocial>> listarNotificacoesSociaisDoUsuario(
    String cpf, {
    int limit = 40,
  }) async {
    final db = await obterDb();
    final cpfNorm = normalizarCpf(cpf);
    if (cpfNorm.isEmpty) return const [];
    final rows = await db.query(
      'notificacoes_sociais',
      where: 'destinatario_cpf = ? AND lida = 0',
      whereArgs: [cpfNorm],
      orderBy: 'criada_em DESC',
      limit: limit,
    );
    return rows
        .map(
          (r) => NotificacaoSocial.fromJson(
            jsonDecode(r['dados_json'] as String? ?? '{}')
                as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  static Future<void> marcarNotificacaoSocialLida(
    String id, {
    bool originadaDaRede = false,
  }) async {
    final db = await obterDb();
    final rows = await db.query(
      'notificacoes_sociais',
      columns: ['dados_json'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    Map<String, dynamic>? dadosAtualizados;
    if (rows.isNotEmpty) {
      try {
        final dec = jsonDecode(rows.first['dados_json'] as String? ?? '{}');
        if (dec is Map<String, dynamic>) {
          dec['lida'] = true;
          dadosAtualizados = dec;
        }
      } catch (_) {}
    }
    await db.update(
      'notificacoes_sociais',
      {
        'lida': 1,
        if (dadosAtualizados != null) 'dados_json': jsonEncode(dadosAtualizados),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    if (!originadaDaRede) {
      TimelineSyncService.despacharEventoRede('timeline_notificacao_lida', {
        'id': id,
      });
    }
  }

  static String normalizarCpf(String cpf) =>
      TimelineSqliteUtils.normalizarCpf(cpf);

  static Future<void> salvarPublicacao(PublicacaoSocial pub) async {
    final db = await obterDb();
    final autorNorm = normalizarCpf(pub.autorCpf);
    await db.transaction((txn) async {
      await txn.insert(
        'publicacoes_sociais',
        {
          'id': pub.id,
          'autor_cpf': autorNorm,
          'tipo': pub.tipo.name,
          'criada_em': pub.criadaEm.toIso8601String(),
          'atualizada_em': pub.atualizadaEm.toIso8601String(),
          'excluida': pub.excluida ? 1 : 0,
          'arquivada': pub.arquivada ? 1 : 0,
          'dados_json': jsonEncode(pub.toJson()),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.delete(
        'publicacoes_coautores',
        where: 'publicacao_id = ?',
        whereArgs: [pub.id],
      );
      for (final cpf in pub.coautoresCpfs) {
        final norm = normalizarCpf(cpf);
        if (norm.isNotEmpty) {
          await txn.insert(
            'publicacoes_coautores',
            {'publicacao_id': pub.id, 'cpf': norm},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }

      await txn.delete(
        'publicacoes_tags',
        where: 'publicacao_id = ?',
        whereArgs: [pub.id],
      );
      for (final tag in pub.tags) {
        final t = tag.trim().toLowerCase().replaceAll('#', '');
        if (t.isNotEmpty) {
          await txn.insert(
            'publicacoes_tags',
            {'publicacao_id': pub.id, 'tag': t},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
    });
  }

  static Future<PublicacaoSocial?> buscarPublicacaoPorId(String id) async {
    final db = await obterDb();
    final rows = await db.query(
      'publicacoes_sociais',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final jsonStr = rows.first['dados_json'] as String? ?? '{}';
    return PublicacaoSocial.fromJson(
      jsonDecode(jsonStr) as Map<String, dynamic>,
    );
  }

  static Future<List<PublicacaoSocial>> listarPublicacoesDoUsuario({
    required String cpf,
    TipoFeedSocial? tipo,
    bool incluirExcluidas = false,
    int limit = 60,
    int offset = 0,
  }) async {
    final db = await obterDb();
    final cpfNorm = normalizarCpf(cpf);
    if (cpfNorm.isEmpty) return const [];

    final whereTipo = tipo != null ? 'AND p.tipo = ?' : '';
    final whereExcluida = incluirExcluidas
        ? ''
        : 'p.excluida = 0 AND COALESCE(p.arquivada, 0) = 0 AND ';
    final args = <Object?>[
      cpfNorm,
      cpfNorm,
      if (tipo != null) tipo.name,
      limit,
      offset,
    ];

    final rows = await db.rawQuery('''
      SELECT DISTINCT p.dados_json, p.criada_em
      FROM publicacoes_sociais p
      LEFT JOIN publicacoes_coautores c ON c.publicacao_id = p.id
      WHERE $whereExcluida(p.autor_cpf = ? OR c.cpf = ?)
        $whereTipo
      ORDER BY p.criada_em DESC
      LIMIT ? OFFSET ?;
    ''', args);

    return rows
        .map((r) {
          final jsonStr = r['dados_json'] as String? ?? '{}';
          return PublicacaoSocial.fromJson(
            jsonDecode(jsonStr) as Map<String, dynamic>,
          );
        })
        .where((p) => incluirExcluidas || (!p.excluida && !p.arquivada))
        .toList();
  }

  static Future<List<PublicacaoSocial>> listarPublicacoesArquivadasDoUsuario(
    String cpf,
  ) async {
    final db = await obterDb();
    final cpfNorm = normalizarCpf(cpf);
    if (cpfNorm.isEmpty) return const [];
    final rows = await db.query(
      'publicacoes_sociais',
      where: 'excluida = 0 AND COALESCE(arquivada, 0) = 1 AND autor_cpf = ?',
      whereArgs: [cpfNorm],
      orderBy: 'criada_em DESC',
    );
    return rows
        .map((r) => PublicacaoSocial.fromJson(
              jsonDecode(r['dados_json'] as String? ?? '{}')
                  as Map<String, dynamic>,
            ))
        .where((p) => !p.excluida && p.arquivada)
        .toList();
  }

  static Future<List<PublicacaoSocial>> listarPublicacoesExcluidasDoUsuario(
    String cpf,
  ) async {
    final db = await obterDb();
    final cpfNorm = normalizarCpf(cpf);
    if (cpfNorm.isEmpty) return const [];
    final rows = await db.query(
      'publicacoes_sociais',
      where: 'excluida = 1 AND autor_cpf = ?',
      whereArgs: [cpfNorm],
      orderBy: 'atualizada_em DESC',
    );
    return rows
        .map((r) => PublicacaoSocial.fromJson(
              jsonDecode(r['dados_json'] as String? ?? '{}')
                  as Map<String, dynamic>,
            ))
        .where((p) => p.excluida)
        .toList();
  }

  static Future<void> salvarReacao(ReacaoSocial reacao) async =>
      TimelineInteracoesSqliteHelper.salvarReacao(await obterDb(), reacao);

  static Future<void> removerReacao({
    required String publicacaoId,
    required String usuarioCpf,
  }) async =>
      TimelineInteracoesSqliteHelper.removerReacao(
        await obterDb(),
        publicacaoId: publicacaoId,
        usuarioCpf: usuarioCpf,
      );

  static Future<List<ReacaoSocial>> listarReacoesDaPublicacao(
    String publicacaoId,
  ) async =>
      TimelineInteracoesSqliteHelper.listarReacoesDaPublicacao(
        await obterDb(),
        publicacaoId,
      );

  static Future<List<ReacaoSocial>> listarReacoesDoUsuario(String cpf) async =>
      TimelineInteracoesSqliteHelper.listarReacoesDoUsuario(
        await obterDb(),
        cpf,
      );

  static Future<void> salvarComentario(ComentarioSocial comentario) async =>
      TimelineInteracoesSqliteHelper.salvarComentario(
        await obterDb(),
        comentario,
      );

  static Future<List<ComentarioSocial>> listarComentariosDaPublicacao(
    String publicacaoId,
  ) async =>
      TimelineInteracoesSqliteHelper.listarComentariosDaPublicacao(
        await obterDb(),
        publicacaoId,
      );

  static Future<List<ComentarioSocial>> listarComentariosDoUsuario(
    String cpf,
  ) async =>
      TimelineInteracoesSqliteHelper.listarComentariosDoUsuario(
        await obterDb(),
        cpf,
      );

  static Future<void> salvarStory(StorySocial story) async =>
      TimelineStoriesSqliteHelper.salvarStory(await obterDb(), story);

  static Future<StorySocial?> buscarStoryPorId(String storyId) async =>
      TimelineStoriesSqliteHelper.buscarStoryPorId(await obterDb(), storyId);

  static Future<List<StorySocial>> listarStoriesDoUsuario(String cpf) async =>
      TimelineStoriesSqliteHelper.listarStoriesDoUsuario(await obterDb(), cpf);

  /// Lista todos os stories ativos (24h) da rede para a barra superior do Feed.
  static Future<List<StorySocial>> listarStoriesAtivosDaRede() async =>
      TimelineStoriesSqliteHelper.listarStoriesAtivosDaRede(await obterDb());

  /// Lista todo o histórico de stories do usuário (inclusive expirados >24h)
  /// para o Arquivo e Calendário de Stories na página Conta.
  static Future<List<StorySocial>> listarTodosStoriesDoUsuario(
    String cpf,
  ) async =>
      TimelineStoriesSqliteHelper.listarTodosStoriesDoUsuario(
        await obterDb(),
        cpf,
      );

  static Future<int> contarPublicacoesDoUsuario(String cpf) async {
    final db = await obterDb();
    final cpfNorm = normalizarCpf(cpf);
    if (cpfNorm.isEmpty) return 0;
    final rows = await db.rawQuery('''
      SELECT COUNT(DISTINCT p.id) AS total
      FROM publicacoes_sociais p
      LEFT JOIN publicacoes_coautores c ON c.publicacao_id = p.id
      WHERE p.excluida = 0
        AND COALESCE(p.arquivada, 0) = 0
        AND p.tipo != 'republicacoes'
        AND (p.autor_cpf = ? OR c.cpf = ?);
    ''', [cpfNorm, cpfNorm]);
    if (rows.isEmpty) return 0;
    return (rows.first['total'] as int?) ?? 0;
  }

  static Future<void> salvarFeedPersonalizado(FeedPersonalizado feed) async =>
      TimelineFeedsConfigSqliteHelper.salvarFeedPersonalizado(
        await obterDb(),
        feed,
      );

  static Future<void> removerFeedPersonalizado(String id) async =>
      TimelineFeedsConfigSqliteHelper.removerFeedPersonalizado(
        await obterDb(),
        id,
      );

  static Future<List<FeedPersonalizado>> listarFeedsPersonalizados(
    String cpf,
  ) async =>
      TimelineFeedsConfigSqliteHelper.listarFeedsPersonalizados(
        await obterDb(),
        cpf,
      );

  static Future<void> salvarListaSalvos(ListaSalvosSocial lista) async =>
      TimelineSalvosDenunciasSqliteHelper.salvarListaSalvos(
        await obterDb(),
        lista,
      );

  static Future<List<ListaSalvosSocial>> listarListasSalvosDoUsuario(
    String cpf,
  ) async =>
      TimelineSalvosDenunciasSqliteHelper.listarListasSalvosDoUsuario(
        await obterDb(),
        cpf,
      );

  static Future<void> salvarItemSalvo(ItemSalvoSocial item) async =>
      TimelineSalvosDenunciasSqliteHelper.salvarItemSalvo(
        await obterDb(),
        item,
      );

  static Future<List<ItemSalvoSocial>> listarItensSalvosPorLista(
    String listaId,
  ) async =>
      TimelineSalvosDenunciasSqliteHelper.listarItensSalvosPorLista(
        await obterDb(),
        listaId,
      );

  static Future<List<ItemSalvoSocial>> listarItensSalvosDoUsuario(
    String cpf,
  ) async =>
      TimelineSalvosDenunciasSqliteHelper.listarItensSalvosDoUsuario(
        await obterDb(),
        cpf,
      );

  static Future<void> salvarDenuncia(DenunciaSocial denuncia) async =>
      TimelineSalvosDenunciasSqliteHelper.salvarDenuncia(
        await obterDb(),
        denuncia,
      );

  static Future<List<DenunciaSocial>> listarDenunciasEnvolvendoUsuario(
    String cpf,
  ) async =>
      TimelineSalvosDenunciasSqliteHelper.listarDenunciasEnvolvendoUsuario(
        await obterDb(),
        cpf,
      );

  static Future<List<String>?> carregarTimelinesVisiveis(String cpf) async =>
      TimelineFeedsConfigSqliteHelper.carregarTimelinesVisiveis(
        await obterDb(),
        cpf,
      );

  static Future<void> salvarTimelinesVisiveis(
    String cpf,
    List<String> tipos,
  ) async =>
      TimelineFeedsConfigSqliteHelper.salvarTimelinesVisiveis(
        await obterDb(),
        cpf,
        tipos,
      );

  static Future<Map<String, PublicacaoSocial>> buscarPublicacoesPorIds(
    List<String> ids, {
    bool incluirExcluidas = false,
  }) async {
    final unicos = ids.where((id) => id.trim().isNotEmpty).toSet().toList();
    if (unicos.isEmpty) return {};
    final db = await obterDb();
    final placeholders = List.filled(unicos.length, '?').join(', ');
    final rows = await db.query(
      'publicacoes_sociais',
      where: 'id IN ($placeholders)',
      whereArgs: unicos,
    );
    final mapa = <String, PublicacaoSocial>{};
    for (final r in rows) {
      try {
        final pub = PublicacaoSocial.fromJson(
          jsonDecode(r['dados_json'] as String? ?? '{}')
              as Map<String, dynamic>,
        );
        if (pub.id.isEmpty) continue;
        if (!incluirExcluidas && (pub.excluida || pub.arquivada)) continue;
        mapa[pub.id] = pub;
      } catch (_) {}
    }
    return mapa;
  }

  static Future<List<PublicacaoSocial>> listarPublicacoesDescoberta({
    List<String> tags = const [],
    List<String>? apenasAutoresCpfs,
    int limit = 60,
    int offset = 0,
  }) async {
    final db = await obterDb();
    final tagsLimpas = tags
        .map((t) => t.trim().toLowerCase().replaceAll('#', ''))
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();

    final autoresNorm = apenasAutoresCpfs
        ?.map(normalizarCpf)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    if (autoresNorm != null && autoresNorm.isEmpty) {
      return const [];
    }

    final args = <Object?>[];
    final whereBuf = StringBuffer(
      "p.excluida = 0 AND COALESCE(p.arquivada, 0) = 0 AND p.tipo != 'republicacoes'",
    );
    if (autoresNorm != null) {
      final phAut = List.filled(autoresNorm.length, '?').join(', ');
      whereBuf.write(
        ' AND (p.autor_cpf IN ($phAut) OR p.id IN (SELECT publicacao_id FROM publicacoes_coautores WHERE cpf IN ($phAut)))',
      );
      args.addAll(autoresNorm);
      args.addAll(autoresNorm);
    }

    if (tagsLimpas.isEmpty) {
      args.addAll([limit, offset]);
      final rows = await db.rawQuery('''
        SELECT p.dados_json
        FROM publicacoes_sociais p
        WHERE $whereBuf
        ORDER BY p.criada_em DESC
        LIMIT ? OFFSET ?;
      ''', args);
      return rows
          .map(
            (r) => PublicacaoSocial.fromJson(
              jsonDecode(r['dados_json'] as String? ?? '{}')
                  as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    final placeholders = List.filled(tagsLimpas.length, '?').join(', ');
    args.addAll([...tagsLimpas, limit, offset]);
    final rows = await db.rawQuery('''
      SELECT DISTINCT p.dados_json, p.criada_em
      FROM publicacoes_sociais p
      INNER JOIN publicacoes_tags t ON t.publicacao_id = p.id
      WHERE $whereBuf
        AND t.tag IN ($placeholders)
      ORDER BY p.criada_em DESC
      LIMIT ? OFFSET ?;
    ''', args);

    return rows
        .map(
          (r) => PublicacaoSocial.fromJson(
            jsonDecode(r['dados_json'] as String? ?? '{}')
                as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  static Future<List<Map<String, dynamic>>?> carregarAbasDescoberta(
    String cpf,
  ) async =>
      TimelineFeedsConfigSqliteHelper.carregarAbasDescoberta(
        await obterDb(),
        cpf,
      );

  static Future<void> salvarAbasDescoberta(
    String cpf,
    List<Map<String, dynamic>> abas,
  ) async =>
      TimelineFeedsConfigSqliteHelper.salvarAbasDescoberta(
        await obterDb(),
        cpf,
        abas,
      );
}
