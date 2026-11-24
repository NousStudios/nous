import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/notificacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/models/salvos_denuncia_social.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_schema_sqlite.dart';

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

  static Future<void> marcarNotificacaoSocialLida(String id) async {
    final db = await obterDb();
    await db.update(
      'notificacoes_sociais',
      {'lida': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static String normalizarCpf(String cpf) =>
      cpf.replaceAll(RegExp(r'\D'), '');

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

  static Future<void> salvarReacao(ReacaoSocial reacao) async {
    final db = await obterDb();
    await db.insert(
      'reacoes_sociais',
      {
        'id': reacao.id,
        'publicacao_id': reacao.publicacaoId,
        'usuario_cpf': normalizarCpf(reacao.usuarioCpf),
        'tipo': reacao.tipo.name,
        'criada_em': reacao.criadaEm.toIso8601String(),
        'atualizada_em': reacao.criadaEm.toIso8601String(),
        'dados_json': jsonEncode(reacao.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> removerReacao({
    required String publicacaoId,
    required String usuarioCpf,
  }) async {
    final db = await obterDb();
    final cpfNorm = normalizarCpf(usuarioCpf);
    final rows = await db.query(
      'reacoes_sociais',
      where: 'publicacao_id = ? AND usuario_cpf = ?',
      whereArgs: [publicacaoId, cpfNorm],
    );
    final agora = DateTime.now();
    for (final r in rows) {
      try {
        final reacao = ReacaoSocial.fromJson(
          jsonDecode(r['dados_json'] as String? ?? '{}')
              as Map<String, dynamic>,
        );
        final tombstone = reacao.copyWith(
          excluida: true,
          atualizadaEm: agora,
        );
        await salvarReacao(tombstone);
      } catch (_) {}
    }
  }

  static Future<List<ReacaoSocial>> listarReacoesDaPublicacao(
    String publicacaoId,
  ) async {
    final db = await obterDb();
    final rows = await db.query(
      'reacoes_sociais',
      where: 'publicacao_id = ?',
      whereArgs: [publicacaoId],
      orderBy: 'criada_em DESC',
    );
    return rows
        .map((r) {
          final jsonStr = r['dados_json'] as String? ?? '{}';
          return ReacaoSocial.fromJson(
            jsonDecode(jsonStr) as Map<String, dynamic>,
          );
        })
        .where((r) => !r.excluida)
        .toList();
  }

  static Future<List<ReacaoSocial>> listarReacoesDoUsuario(String cpf) async {
    final db = await obterDb();
    final cpfNorm = normalizarCpf(cpf);
    final rows = await db.query(
      'reacoes_sociais',
      where: 'usuario_cpf = ?',
      whereArgs: [cpfNorm],
      orderBy: 'criada_em DESC',
      limit: 100,
    );
    return rows
        .map((r) {
          final jsonStr = r['dados_json'] as String? ?? '{}';
          return ReacaoSocial.fromJson(
            jsonDecode(jsonStr) as Map<String, dynamic>,
          );
        })
        .where((r) => !r.excluida)
        .toList();
  }

  static Future<void> salvarComentario(ComentarioSocial comentario) async {
    final db = await obterDb();
    await db.insert(
      'comentarios_sociais',
      {
        'id': comentario.id,
        'publicacao_id': comentario.publicacaoId,
        'autor_cpf': normalizarCpf(comentario.autorCpf),
        'criada_em': comentario.criadaEm.toIso8601String(),
        'atualizada_em': comentario.atualizadaEfetiva.toIso8601String(),
        'excluido': comentario.excluido ? 1 : 0,
        'dados_json': jsonEncode(comentario.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<ComentarioSocial>> listarComentariosDaPublicacao(
    String publicacaoId,
  ) async {
    final db = await obterDb();
    final rows = await db.query(
      'comentarios_sociais',
      where: 'publicacao_id = ? AND excluido = 0',
      whereArgs: [publicacaoId],
      orderBy: 'criada_em ASC',
    );
    return rows.map((r) {
      final jsonStr = r['dados_json'] as String? ?? '{}';
      return ComentarioSocial.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );
    }).toList();
  }

  static Future<List<ComentarioSocial>> listarComentariosDoUsuario(
    String cpf,
  ) async {
    final db = await obterDb();
    final cpfNorm = normalizarCpf(cpf);
    final rows = await db.query(
      'comentarios_sociais',
      where: 'autor_cpf = ?',
      whereArgs: [cpfNorm],
      orderBy: 'criada_em DESC',
      limit: 100,
    );
    return rows.map((r) {
      final jsonStr = r['dados_json'] as String? ?? '{}';
      return ComentarioSocial.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );
    }).toList();
  }

  static Future<void> salvarStory(StorySocial story) async {
    final db = await obterDb();
    await db.insert(
      'stories_sociais',
      {
        'id': story.id,
        'autor_cpf': normalizarCpf(story.autorCpf),
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

  static Future<List<StorySocial>> listarStoriesDoUsuario(String cpf) async {
    final todos = await listarTodosStoriesDoUsuario(cpf);
    return todos.where((s) => s.estaAtivo).toList();
  }

  /// Lista todos os stories ativos (24h) da rede para a barra superior do Feed.
  static Future<List<StorySocial>> listarStoriesAtivosDaRede() async {
    final db = await obterDb();
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
            jsonDecode(r['dados_json'] as String? ?? '{}')
                as Map<String, dynamic>,
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
    String cpf,
  ) async {
    final db = await obterDb();
    final cpfNorm = normalizarCpf(cpf);
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
            jsonDecode(r['dados_json'] as String? ?? '{}')
                as Map<String, dynamic>,
          ),
        )
        .toList();
  }

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

  static Future<void> salvarFeedPersonalizado(FeedPersonalizado feed) async {
    final db = await obterDb();
    await db.insert(
      'feeds_personalizados',
      {
        'id': feed.id,
        'dono_cpf': normalizarCpf(feed.donoCpf),
        'criado_em': feed.criadoEm.toIso8601String(),
        'dados_json': jsonEncode(feed.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> removerFeedPersonalizado(String id) async {
    final db = await obterDb();
    await db.delete('feeds_personalizados', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<FeedPersonalizado>> listarFeedsPersonalizados(
    String cpf,
  ) async {
    final db = await obterDb();
    final cpfNorm = normalizarCpf(cpf);
    final rows = await db.query(
      'feeds_personalizados',
      where: 'dono_cpf = ?',
      whereArgs: [cpfNorm],
      orderBy: 'criado_em ASC',
    );
    return rows.map((r) {
      final jsonStr = r['dados_json'] as String? ?? '{}';
      return FeedPersonalizado.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );
    }).toList();
  }

  static Future<void> salvarListaSalvos(ListaSalvosSocial lista) async {
    final db = await obterDb();
    await db.insert(
      'listas_salvos_sociais',
      {
        'id': lista.id,
        'dono_cpf': normalizarCpf(lista.donoCpf),
        'criada_em': lista.criadaEm.toIso8601String(),
        'atualizada_em': lista.atualizadaEfetiva.toIso8601String(),
        'dados_json': jsonEncode(lista.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<ListaSalvosSocial>> listarListasSalvosDoUsuario(
    String cpf,
  ) async {
    final db = await obterDb();
    final cpfNorm = normalizarCpf(cpf);
    final rows = await db.query(
      'listas_salvos_sociais',
      orderBy: 'criada_em ASC',
    );
    return rows
        .map(
          (r) => ListaSalvosSocial.fromJson(
            jsonDecode(r['dados_json'] as String? ?? '{}')
                as Map<String, dynamic>,
          ),
        )
        .where((l) =>
            normalizarCpf(l.donoCpf) == cpfNorm ||
            l.colaboradoresCpfs.any((c) => normalizarCpf(c) == cpfNorm))
        .toList();
  }

  static Future<void> salvarItemSalvo(ItemSalvoSocial item) async {
    final db = await obterDb();
    await db.insert(
      'itens_salvos_sociais',
      {
        'id': item.id,
        'lista_id': item.listaId,
        'usuario_cpf': normalizarCpf(item.usuarioCpf),
        'publicacao_id': item.publicacaoId,
        'salvo_em': item.salvoEm.toIso8601String(),
        'atualizada_em': item.salvoEm.toIso8601String(),
        'dados_json': jsonEncode(item.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<ItemSalvoSocial>> listarItensSalvosPorLista(
    String listaId,
  ) async {
    final db = await obterDb();
    final rows = await db.query(
      'itens_salvos_sociais',
      where: 'lista_id = ?',
      whereArgs: [listaId],
      orderBy: 'salvo_em DESC',
    );
    return rows
        .map(
          (r) => ItemSalvoSocial.fromJson(
            jsonDecode(r['dados_json'] as String? ?? '{}')
                as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  static Future<List<ItemSalvoSocial>> listarItensSalvosDoUsuario(
    String cpf,
  ) async {
    final db = await obterDb();
    final cpfNorm = normalizarCpf(cpf);
    if (cpfNorm.isEmpty) return const [];
    final rows = await db.query(
      'itens_salvos_sociais',
      where: 'usuario_cpf = ?',
      whereArgs: [cpfNorm],
      orderBy: 'salvo_em DESC',
      limit: 80,
    );
    return rows
        .map(
          (r) => ItemSalvoSocial.fromJson(
            jsonDecode(r['dados_json'] as String? ?? '{}')
                as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  static Future<void> salvarDenuncia(DenunciaSocial denuncia) async {
    final db = await obterDb();
    await db.insert(
      'denuncias_sociais',
      {
        'id': denuncia.id,
        'denunciante_cpf': normalizarCpf(denuncia.denuncianteCpf),
        'alvo_cpf': normalizarCpf(denuncia.alvoCpf),
        'publicacao_id': denuncia.publicacaoId,
        'criada_em': denuncia.criadaEm.toIso8601String(),
        'atualizada_em': denuncia.criadaEm.toIso8601String(),
        'dados_json': jsonEncode(denuncia.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<DenunciaSocial>> listarDenunciasEnvolvendoUsuario(
    String cpf,
  ) async {
    final db = await obterDb();
    final cpfNorm = normalizarCpf(cpf);
    final rows = await db.query(
      'denuncias_sociais',
      where: 'denunciante_cpf = ? OR alvo_cpf = ?',
      whereArgs: [cpfNorm, cpfNorm],
      orderBy: 'criada_em DESC',
    );
    return rows
        .map(
          (r) => DenunciaSocial.fromJson(
            jsonDecode(r['dados_json'] as String? ?? '{}')
                as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  static Future<List<String>?> carregarTimelinesVisiveis(String cpf) async {
    final db = await obterDb();
    final cpfNorm = normalizarCpf(cpf);
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
    String cpf,
    List<String> tipos,
  ) async {
    final db = await obterDb();
    final cpfNorm = normalizarCpf(cpf);
    await db.insert(
      'timelines_visiveis_perfil',
      {
        'cpf': cpfNorm,
        'tipos_json': jsonEncode(tipos.toSet().toList()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

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
  ) async {
    final db = await obterDb();
    final cpfNorm = normalizarCpf(cpf);
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
    String cpf,
    List<Map<String, dynamic>> abas,
  ) async {
    final db = await obterDb();
    final cpfNorm = normalizarCpf(cpf);
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
