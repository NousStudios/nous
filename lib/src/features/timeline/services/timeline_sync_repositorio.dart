import 'dart:convert';

import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/notificacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/models/salvos_denuncia_social.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_repositorio_sqlite.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Repositório especializado em exportação incremental (Delta Sync) e mesclagem
/// LWW (Last-Write-Wins) do estado social para sincronização na rede local.
class TimelineSyncRepositorio {
  TimelineSyncRepositorio._();

  static Future<String> obterCpfLogadoEfetivo([String? cpfExplicito]) async {
    final normExplicito =
        TimelineRepositorioSqlite.normalizarCpf(cpfExplicito ?? '');
    if (normExplicito.isNotEmpty) return normExplicito;
    try {
      final prefs = await SharedPreferences.getInstance();
      return TimelineRepositorioSqlite.normalizarCpf(
        prefs.getString('ultimo_cpf_login') ?? '',
      );
    } catch (_) {
      return '';
    }
  }

  static bool _ehMaisRecenteQue(String? isoData, DateTime? corte) {
    if (corte == null) return true;
    final dt = DateTime.tryParse(isoData ?? '');
    if (dt == null) return true;
    return !dt.isBefore(corte);
  }

  /// Exporta o estado social local (incluindo registros excluídos para propagar
  /// tombstones). Quando [desde] é informado, retorna apenas o delta alterado.
  static Future<Map<String, dynamic>> exportarSnapshotSocial({
    DateTime? desde,
    int offset = 0,
    int limit = 400,
    String? cpfRemetente,
  }) async {
    final db = await TimelineRepositorioSqlite.obterDb();
    final corte = desde?.subtract(const Duration(seconds: 2));
    final remetente = await obterCpfLogadoEfetivo(cpfRemetente);
    bool autorPossuiHistorico = false;
    if (remetente.isNotEmpty) {
      final hist = await db.query(
        'publicacoes_sociais',
        columns: ['id'],
        where: 'autor_cpf = ?',
        whereArgs: [remetente],
        limit: 1,
      );
      autorPossuiHistorico = hist.isNotEmpty;
    }

    List<Map<String, dynamic>> decodificar(
      List<Map<String, Object?>> rows,
      String? Function(Map<String, dynamic> dec) extrairData,
    ) {
      final saida = <Map<String, dynamic>>[];
      for (final r in rows) {
        try {
          final dec = jsonDecode(r['dados_json'] as String? ?? '{}');
          if (dec is Map<String, dynamic>) {
            if (_ehMaisRecenteQue(extrairData(dec), corte)) {
              saida.add(dec);
            }
          }
        } catch (_) {}
      }
      return saida;
    }

    final corteIso = corte?.toIso8601String();
    Future<List<Map<String, Object?>>> consultarDelta(String tabela) {
      if (corteIso == null) {
        return db.query(tabela, limit: limit, offset: offset);
      }
      return db.query(
        tabela,
        where: 'atualizada_em >= ? OR atualizada_em IS NULL',
        whereArgs: [corteIso],
        limit: limit,
        offset: offset,
      );
    }

    final resultados = await Future.wait([
      consultarDelta('publicacoes_sociais'),
      consultarDelta('stories_sociais'),
      consultarDelta('reacoes_sociais'),
      consultarDelta('comentarios_sociais'),
      consultarDelta('listas_salvos_sociais'),
      consultarDelta('itens_salvos_sociais'),
      consultarDelta('denuncias_sociais'),
    ]);
    final pubs = resultados[0];
    final stories = resultados[1];
    final reacoes = resultados[2];
    final comentarios = resultados[3];
    final listas = resultados[4];
    final itens = resultados[5];
    final denuncias = resultados[6];

    final notifs = offset == 0
        ? (corteIso == null
            ? await db.query('notificacoes_sociais', limit: limit)
            : await db.query(
                'notificacoes_sociais',
                where: 'criada_em >= ?',
                whereArgs: [corteIso],
                limit: limit,
              ))
        : const <Map<String, Object?>>[];

    final temMais = pubs.length >= limit ||
        stories.length >= limit ||
        reacoes.length >= limit ||
        comentarios.length >= limit ||
        listas.length >= limit ||
        itens.length >= limit ||
        denuncias.length >= limit;

    final pubsExcluidasRows = offset == 0
        ? await db.query(
            'publicacoes_sociais',
            columns: ['id', 'atualizada_em'],
            where: 'excluida = 1',
          )
        : const <Map<String, Object?>>[];
    final idsPublicacoesExcluidas = pubsExcluidasRows
        .map((r) => <String, dynamic>{
              'id': (r['id'] ?? '').toString(),
              'atualizadaEm': (r['atualizada_em'] ?? '').toString(),
            })
        .where((m) => (m['id'] as String).isNotEmpty)
        .toList();

    final pubsAtivasRows = offset == 0
        ? await db.query(
            'publicacoes_sociais',
            columns: ['id'],
            where: 'excluida = 0',
          )
        : const <Map<String, Object?>>[];
    final idsPublicacoesAtivas = pubsAtivasRows
        .map((r) => (r['id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toList();

    Future<List<Map<String, dynamic>>> coletarExcluidos(String tabela) async {
      if (offset != 0) return const [];
      final rows = await db.query(
        tabela,
        columns: ['id', 'atualizada_em'],
        where: 'excluido = 1',
      );
      return rows
          .map((r) => <String, dynamic>{
                'id': (r['id'] ?? '').toString(),
                'atualizadaEm': (r['atualizada_em'] ?? '').toString(),
              })
          .where((m) => (m['id'] as String).isNotEmpty)
          .toList();
    }

    final idsStoriesExcluidos = await coletarExcluidos('stories_sociais');
    final idsComentariosExcluidos =
        await coletarExcluidos('comentarios_sociais');

    return {
      'geradoEm': DateTime.now().toIso8601String(),
      'incremental': desde != null,
      'offset': offset,
      'proximoOffset': offset + limit,
      'temMais': temMais,
      if (remetente.isNotEmpty) 'remetenteCpf': remetente,
      'autorPossuiHistorico': autorPossuiHistorico,
      'idsPublicacoesExcluidas': idsPublicacoesExcluidas,
      'idsPublicacoesAtivas': idsPublicacoesAtivas,
      'idsStoriesExcluidos': idsStoriesExcluidos,
      'idsComentariosExcluidos': idsComentariosExcluidos,
      'publicacoes': decodificar(
        pubs,
        (d) => (d['atualizadaEm'] ?? d['criadaEm'])?.toString(),
      ),
      'stories': decodificar(
        stories,
        (d) => (d['atualizadoEm'] ?? d['criadoEm'])?.toString(),
      ),
      'reacoes': decodificar(
        reacoes,
        (d) => (d['atualizadaEm'] ?? d['criadaEm'])?.toString(),
      ),
      'comentarios': decodificar(
        comentarios,
        (d) => (d['atualizadaEm'] ?? d['criadaEm'])?.toString(),
      ),
      'listasSalvos': decodificar(
        listas,
        (d) => (d['atualizadaEm'] ?? d['criadaEm'])?.toString(),
      ),
      'itensSalvos': decodificar(
        itens,
        (d) => (d['atualizadaEm'] ?? d['salvoEm'])?.toString(),
      ),
      'denuncias': decodificar(denuncias, (d) => d['criadaEm']?.toString()),
      'notificacoes': decodificar(notifs, (d) => d['criadaEm']?.toString()),
    };
  }

  /// Mescla um snapshot social remoto usando Last-Write-Wins (com prioridade
  /// para tombstones `excluida = true` em caso de empate de horário) e
  /// Soberania do Autor (CPF dono do post prevalece sobre cópias defasadas).
  static Future<void> mesclarSnapshotSocial(
    Map<String, dynamic> snapshot, {
    DateTime? corteReconciliacaoAtivas,
    String? cpfLogado,
  }) async {
    final db = await TimelineRepositorioSqlite.obterDb();
    final cpfLogadoNorm = await obterCpfLogadoEfetivo(cpfLogado);
    bool autorLocalTemHistorico = false;
    if (cpfLogadoNorm.isNotEmpty) {
      final hist = await db.query(
        'publicacoes_sociais',
        columns: ['id'],
        where: 'autor_cpf = ?',
        whereArgs: [cpfLogadoNorm],
        limit: 1,
      );
      autorLocalTemHistorico = hist.isNotEmpty;
    }
    final agora = DateTime.now();
    final limiteRecente = agora.subtract(const Duration(minutes: 5));

    final pubsBrutas = snapshot['publicacoes'] as List<dynamic>? ?? const [];
    final pubsRemotas = pubsBrutas
        .whereType<Map>()
        .map((m) => PublicacaoSocial.fromJson(Map<String, dynamic>.from(m)))
        .where((p) => p.id.isNotEmpty)
        .toList();
    final mapaLocais = await TimelineRepositorioSqlite.buscarPublicacoesPorIds(
      pubsRemotas.map((p) => p.id).toList(),
      incluirExcluidas: true,
    );
    for (final remota in pubsRemotas) {
      final local = mapaLocais[remota.id];
      final ehAutorLocal = cpfLogadoNorm.isNotEmpty &&
          TimelineRepositorioSqlite.normalizarCpf(remota.autorCpf) ==
              cpfLogadoNorm;
      if (local == null) {
        // Escudo 1: Se o autor logado já possui histórico local e não tem esta
        // publicação antiga ativa no próprio cofre, impede ressurreição por nó
        // terceiro e grava tombstone para propagar a exclusão de volta.
        if (ehAutorLocal &&
            !remota.excluida &&
            autorLocalTemHistorico &&
            remota.criadaEm.isBefore(limiteRecente)) {
          await TimelineRepositorioSqlite.salvarPublicacao(
            remota.copyWith(
              excluida: true,
              arquivada: false,
              fixada: false,
              tags: const [],
              coautoresCpfs: const [],
              atualizadaEm: agora,
            ),
          );
          continue;
        }
        await TimelineRepositorioSqlite.salvarPublicacao(remota);
        continue;
      }

      if (ehAutorLocal && local.excluida && !remota.excluida) {
        // Exclusão no aparelho do próprio autor não deve ser revertida por
        // cópia antiga de terceiros (só aceita restauração explícita > 5 min).
        if (!remota.atualizadaEm
            .isAfter(local.atualizadaEm.add(const Duration(minutes: 5)))) {
          continue;
        }
      }

      final remotaMaisNova = remota.atualizadaEm.isAfter(local.atualizadaEm);
      final empateComExclusao =
          !remota.atualizadaEm.isBefore(local.atualizadaEm) &&
              remota.excluida &&
              !local.excluida;
      if (remotaMaisNova || empateComExclusao) {
        await TimelineRepositorioSqlite.salvarPublicacao(remota);
      }
    }

    // Aplica tombstones completos de publicações excluídas (mesmo anteriores ao `desde`)
    final excluidasBrutas =
        snapshot['idsPublicacoesExcluidas'] as List<dynamic>? ?? const [];
    if (excluidasBrutas.isNotEmpty) {
      final mapaExcluidas = <String, DateTime?>{};
      for (final item in excluidasBrutas) {
        if (item is Map) {
          final id = (item['id'] ?? '').toString();
          if (id.isEmpty) continue;
          final dt = DateTime.tryParse((item['atualizadaEm'] ?? '').toString());
          mapaExcluidas[id] = dt;
        } else if (item is String && item.isNotEmpty) {
          mapaExcluidas[item] = null;
        }
      }
      if (mapaExcluidas.isNotEmpty) {
        final locaisExcl = await TimelineRepositorioSqlite.buscarPublicacoesPorIds(
          mapaExcluidas.keys.toList(),
        );
        for (final entry in locaisExcl.entries) {
          final local = entry.value;
          if (local.excluida) continue;
          final dtRemoto = mapaExcluidas[entry.key];
          // Exclusão prevalece, salvo se o local foi restaurado/editado bem depois (> 1h)
          final restauradoBemDepois = dtRemoto != null &&
              local.atualizadaEm.isAfter(
                dtRemoto.add(const Duration(hours: 1)),
              );
          if (!restauradoBemDepois) {
            await TimelineRepositorioSqlite.salvarPublicacao(
              local.copyWith(
                excluida: true,
                arquivada: false,
                fixada: false,
                tags: const [],
                coautoresCpfs: const [],
                atualizadaEm: dtRemoto ?? DateTime.now(),
              ),
            );
          }
        }
      }
    }

    // Escudo 2: Limpeza Soberana no nó terceiro (balcão) quando o próprio autor
    // envia sua lista completa de publicações ativas (`offset == 0`).
    final ativasRemotasBrutas = snapshot['idsPublicacoesAtivas'];
    final remetenteCpf = TimelineRepositorioSqlite.normalizarCpf(
      (snapshot['remetenteCpf'] ?? '').toString(),
    );
    final autorPossuiHistRemoto = snapshot['autorPossuiHistorico'] == true;
    final paginaInicial =
        snapshot['offset'] == null || (snapshot['offset'] as num?)?.toInt() == 0;

    if (remetenteCpf.isNotEmpty &&
        autorPossuiHistRemoto &&
        paginaInicial &&
        ativasRemotasBrutas is List &&
        remetenteCpf != cpfLogadoNorm) {
      final conjuntoAtivasAutor =
          ativasRemotasBrutas.map((e) => e.toString()).toSet();
      final rowsAutorLocais = await db.query(
        'publicacoes_sociais',
        columns: ['id', 'criada_em', 'dados_json'],
        where: 'excluida = 0 AND autor_cpf = ?',
        whereArgs: [remetenteCpf],
      );
      final limiteSegurancaAutor = agora.subtract(const Duration(minutes: 2));
      for (final row in rowsAutorLocais) {
        final id = (row['id'] ?? '').toString();
        if (id.isEmpty || conjuntoAtivasAutor.contains(id)) continue;
        final criadaEm = DateTime.tryParse((row['criada_em'] ?? '').toString());
        if (criadaEm != null && criadaEm.isBefore(limiteSegurancaAutor)) {
          try {
            final pubLocal = PublicacaoSocial.fromJson(
              jsonDecode(row['dados_json'] as String? ?? '{}')
                  as Map<String, dynamic>,
            );
            await TimelineRepositorioSqlite.salvarPublicacao(
              pubLocal.copyWith(
                excluida: true,
                arquivada: false,
                fixada: false,
                tags: const [],
                coautoresCpfs: const [],
                atualizadaEm: agora,
              ),
            );
          } catch (_) {}
        }
      }
    }

    // Reconciliação de posts antigos expurgados no servidor antes do soft-delete
    if (corteReconciliacaoAtivas != null && ativasRemotasBrutas is List) {
      final conjuntoAtivasRemotas =
          ativasRemotasBrutas.map((e) => e.toString()).toSet();
      final conjuntoExcluidasRemotas = excluidasBrutas
          .map((e) => e is Map ? (e['id'] ?? '').toString() : e.toString())
          .where((id) => id.isNotEmpty)
          .toSet();
      final rowsAtivasLocais = await db.query(
        'publicacoes_sociais',
        columns: ['id', 'criada_em', 'dados_json'],
        where: 'excluida = 0',
      );
      final limiteSeguranca =
          corteReconciliacaoAtivas.subtract(const Duration(minutes: 5));
      for (final row in rowsAtivasLocais) {
        final id = (row['id'] ?? '').toString();
        if (id.isEmpty ||
            conjuntoAtivasRemotas.contains(id) ||
            conjuntoExcluidasRemotas.contains(id)) {
          continue;
        }
        final criadaEm = DateTime.tryParse((row['criada_em'] ?? '').toString());
        if (criadaEm != null && criadaEm.isBefore(limiteSeguranca)) {
          try {
            final pubLocal = PublicacaoSocial.fromJson(
              jsonDecode(row['dados_json'] as String? ?? '{}')
                  as Map<String, dynamic>,
            );
            await TimelineRepositorioSqlite.salvarPublicacao(
              pubLocal.copyWith(
                excluida: true,
                arquivada: false,
                fixada: false,
                tags: const [],
                coautoresCpfs: const [],
                atualizadaEm: DateTime.now(),
              ),
            );
          } catch (_) {}
        }
      }
    }

    final storiesBrutos = snapshot['stories'] as List<dynamic>? ?? const [];
    for (final item in storiesBrutos) {
      if (item is! Map) continue;
      final remoto = StorySocial.fromJson(Map<String, dynamic>.from(item));
      if (remoto.id.isEmpty) continue;
      final rows = await db.query(
        'stories_sociais',
        where: 'id = ?',
        whereArgs: [remoto.id],
        limit: 1,
      );
      if (rows.isEmpty) {
        await TimelineRepositorioSqlite.salvarStory(remoto);
        continue;
      }
      final local = StorySocial.fromJson(
        jsonDecode(rows.first['dados_json'] as String? ?? '{}')
            as Map<String, dynamic>,
      );
      final maisNovo = remoto.atualizadoEfetivo.isAfter(local.atualizadoEfetivo);
      final empateExcl =
          !remoto.atualizadoEfetivo.isBefore(local.atualizadoEfetivo) &&
              remoto.excluido &&
              !local.excluido;
      if (maisNovo || empateExcl) {
        final visualizadoresMesclados = {
          ...local.visualizadoPorCpfs,
          ...remoto.visualizadoPorCpfs,
        }.toList();
        final votosMesclados = {
          ...local.votosEnquete,
          ...remoto.votosEnquete,
        };
        await TimelineRepositorioSqlite.salvarStory(
          remoto.copyWith(
            visualizadoPorCpfs: visualizadoresMesclados,
            votosEnquete: votosMesclados,
          ),
        );
      }
    }

    final storiesExclBrutos =
        snapshot['idsStoriesExcluidos'] as List<dynamic>? ?? const [];
    for (final item in storiesExclBrutos) {
      final id = item is Map ? (item['id'] ?? '').toString() : item.toString();
      if (id.isEmpty) continue;
      final rows = await db.query(
        'stories_sociais',
        where: 'id = ? AND excluido = 0',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) continue;
      final local = StorySocial.fromJson(
        jsonDecode(rows.first['dados_json'] as String? ?? '{}')
            as Map<String, dynamic>,
      );
      final dtRemoto = item is Map
          ? DateTime.tryParse((item['atualizadaEm'] ?? '').toString())
          : null;
      await TimelineRepositorioSqlite.salvarStory(
        local.copyWith(
          excluido: true,
          atualizadoEm: dtRemoto ?? DateTime.now(),
        ),
      );
    }

    final reacoesBrutas = snapshot['reacoes'] as List<dynamic>? ?? const [];
    for (final item in reacoesBrutas) {
      if (item is! Map) continue;
      final r = ReacaoSocial.fromJson(Map<String, dynamic>.from(item));
      if (r.id.isEmpty) continue;
      final rows = await db.query(
        'reacoes_sociais',
        where: 'id = ?',
        whereArgs: [r.id],
        limit: 1,
      );
      if (rows.isEmpty) {
        await TimelineRepositorioSqlite.salvarReacao(r);
        continue;
      }
      final local = ReacaoSocial.fromJson(
        jsonDecode(rows.first['dados_json'] as String? ?? '{}')
            as Map<String, dynamic>,
      );
      if (r.atualizadaEfetiva.isAfter(local.atualizadaEfetiva) ||
          (!r.atualizadaEfetiva.isBefore(local.atualizadaEfetiva) &&
              r.excluida &&
              !local.excluida)) {
        await TimelineRepositorioSqlite.salvarReacao(r);
      }
    }

    final comBrutos = snapshot['comentarios'] as List<dynamic>? ?? const [];
    for (final item in comBrutos) {
      if (item is! Map) continue;
      final c = ComentarioSocial.fromJson(Map<String, dynamic>.from(item));
      if (c.id.isEmpty) continue;
      final rows = await db.query(
        'comentarios_sociais',
        where: 'id = ?',
        whereArgs: [c.id],
        limit: 1,
      );
      if (rows.isEmpty) {
        await TimelineRepositorioSqlite.salvarComentario(c);
        continue;
      }
      final local = ComentarioSocial.fromJson(
        jsonDecode(rows.first['dados_json'] as String? ?? '{}')
            as Map<String, dynamic>,
      );
      if (c.atualizadaEfetiva.isAfter(local.atualizadaEfetiva) ||
          (!c.atualizadaEfetiva.isBefore(local.atualizadaEfetiva) &&
              c.excluido &&
              !local.excluido)) {
        await TimelineRepositorioSqlite.salvarComentario(c);
      }
    }

    final comExclBrutos =
        snapshot['idsComentariosExcluidos'] as List<dynamic>? ?? const [];
    for (final item in comExclBrutos) {
      final id = item is Map ? (item['id'] ?? '').toString() : item.toString();
      if (id.isEmpty) continue;
      final rows = await db.query(
        'comentarios_sociais',
        where: 'id = ? AND excluido = 0',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) continue;
      final local = ComentarioSocial.fromJson(
        jsonDecode(rows.first['dados_json'] as String? ?? '{}')
            as Map<String, dynamic>,
      );
      final dtRemoto = item is Map
          ? DateTime.tryParse((item['atualizadaEm'] ?? '').toString())
          : null;
      await TimelineRepositorioSqlite.salvarComentario(
        local.copyWith(
          excluido: true,
          atualizadaEm: dtRemoto ?? DateTime.now(),
        ),
      );
    }

    final listasBrutas = snapshot['listasSalvos'] as List<dynamic>? ?? const [];
    for (final item in listasBrutas) {
      if (item is! Map) continue;
      final l = ListaSalvosSocial.fromJson(Map<String, dynamic>.from(item));
      if (l.id.isEmpty) continue;
      final rows = await db.query(
        'listas_salvos_sociais',
        where: 'id = ?',
        whereArgs: [l.id],
        limit: 1,
      );
      if (rows.isEmpty) {
        await TimelineRepositorioSqlite.salvarListaSalvos(l);
        continue;
      }
      final local = ListaSalvosSocial.fromJson(
        jsonDecode(rows.first['dados_json'] as String? ?? '{}')
            as Map<String, dynamic>,
      );
      if (l.atualizadaEfetiva.isAfter(local.atualizadaEfetiva) ||
          (!l.atualizadaEfetiva.isBefore(local.atualizadaEfetiva) &&
              l.excluida &&
              !local.excluida)) {
        await TimelineRepositorioSqlite.salvarListaSalvos(l);
      }
    }

    final itensBrutos = snapshot['itensSalvos'] as List<dynamic>? ?? const [];
    for (final item in itensBrutos) {
      if (item is! Map) continue;
      final it = ItemSalvoSocial.fromJson(Map<String, dynamic>.from(item));
      if (it.id.isEmpty) continue;
      final rows = await db.query(
        'itens_salvos_sociais',
        where: 'id = ?',
        whereArgs: [it.id],
        limit: 1,
      );
      if (rows.isEmpty) {
        await TimelineRepositorioSqlite.salvarItemSalvo(it);
        continue;
      }
      final local = ItemSalvoSocial.fromJson(
        jsonDecode(rows.first['dados_json'] as String? ?? '{}')
            as Map<String, dynamic>,
      );
      if (it.atualizadaEfetiva.isAfter(local.atualizadaEfetiva) ||
          (!it.atualizadaEfetiva.isBefore(local.atualizadaEfetiva) &&
              it.excluida &&
              !local.excluida)) {
        await TimelineRepositorioSqlite.salvarItemSalvo(it);
      }
    }

    final denBrutas = snapshot['denuncias'] as List<dynamic>? ?? const [];
    for (final item in denBrutas) {
      if (item is! Map) continue;
      final d = DenunciaSocial.fromJson(Map<String, dynamic>.from(item));
      if (d.id.isNotEmpty) {
        await TimelineRepositorioSqlite.salvarDenuncia(d);
      }
    }

    final notifsBrutas = snapshot['notificacoes'] as List<dynamic>? ?? const [];
    for (final item in notifsBrutas) {
      if (item is! Map) continue;
      final n = NotificacaoSocial.fromJson(Map<String, dynamic>.from(item));
      if (n.id.isEmpty) continue;
      final rows = await db.query(
        'notificacoes_sociais',
        columns: ['lida'],
        where: 'id = ?',
        whereArgs: [n.id],
        limit: 1,
      );
      final jaLidaLocal =
          rows.isNotEmpty && ((rows.first['lida'] as int? ?? 0) == 1);
      await TimelineRepositorioSqlite.salvarNotificacaoSocial(
        jaLidaLocal && !n.lida ? n.copyWith(lida: true) : n,
      );
    }
  }
}
