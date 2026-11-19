import 'dart:convert';

import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/models/salvos_denuncia_social.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_repositorio_sqlite.dart';

/// Repositório especializado em exportação incremental (Delta Sync) e mesclagem
/// LWW (Last-Write-Wins) do estado social para sincronização na rede local.
class TimelineSyncRepositorio {
  TimelineSyncRepositorio._();

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
  }) async {
    final db = await TimelineRepositorioSqlite.obterDb();
    final corte = desde?.subtract(const Duration(seconds: 2));

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

    final temMais = pubs.length >= limit ||
        stories.length >= limit ||
        reacoes.length >= limit ||
        comentarios.length >= limit ||
        listas.length >= limit ||
        itens.length >= limit ||
        denuncias.length >= limit;

    return {
      'geradoEm': DateTime.now().toIso8601String(),
      'incremental': desde != null,
      'offset': offset,
      'proximoOffset': offset + limit,
      'temMais': temMais,
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
    };
  }

  /// Mescla um snapshot social remoto usando Last-Write-Wins (com prioridade
  /// para tombstones `excluida = true` em caso de empate de horário).
  static Future<void> mesclarSnapshotSocial(
    Map<String, dynamic> snapshot,
  ) async {
    final pubsBrutas = snapshot['publicacoes'] as List<dynamic>? ?? const [];
    final pubsRemotas = pubsBrutas
        .whereType<Map>()
        .map((m) => PublicacaoSocial.fromJson(Map<String, dynamic>.from(m)))
        .where((p) => p.id.isNotEmpty)
        .toList();
    final mapaLocais = await TimelineRepositorioSqlite.buscarPublicacoesPorIds(
      pubsRemotas.map((p) => p.id).toList(),
    );
    for (final remota in pubsRemotas) {
      final local = mapaLocais[remota.id];
      if (local == null) {
        await TimelineRepositorioSqlite.salvarPublicacao(remota);
        continue;
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

    final db = await TimelineRepositorioSqlite.obterDb();

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

    final listasBrutas = snapshot['listasSalvos'] as List<dynamic>? ?? const [];
    for (final item in listasBrutas) {
      if (item is! Map) continue;
      final l = ListaSalvosSocial.fromJson(Map<String, dynamic>.from(item));
      if (l.id.isNotEmpty) {
        await TimelineRepositorioSqlite.salvarListaSalvos(l);
      }
    }

    final itensBrutos = snapshot['itensSalvos'] as List<dynamic>? ?? const [];
    for (final item in itensBrutos) {
      if (item is! Map) continue;
      final it = ItemSalvoSocial.fromJson(Map<String, dynamic>.from(item));
      if (it.id.isNotEmpty) {
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
  }
}
