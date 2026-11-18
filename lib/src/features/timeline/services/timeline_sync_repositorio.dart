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

    final pubs = await db.query('publicacoes_sociais');
    final stories = await db.query('stories_sociais');
    final reacoes = await db.query('reacoes_sociais');
    final comentarios = await db.query('comentarios_sociais');
    final listas = await db.query('listas_salvos_sociais');
    final itens = await db.query('itens_salvos_sociais');
    final denuncias = await db.query('denuncias_sociais');

    return {
      'geradoEm': DateTime.now().toIso8601String(),
      'incremental': desde != null,
      'publicacoes': decodificar(
        pubs,
        (d) => (d['atualizadaEm'] ?? d['criadaEm'])?.toString(),
      ),
      'stories': decodificar(stories, (d) => d['criadoEm']?.toString()),
      'reacoes': decodificar(reacoes, (d) => d['criadaEm']?.toString()),
      'comentarios': decodificar(comentarios, (d) => d['criadaEm']?.toString()),
      'listasSalvos': decodificar(listas, (d) => d['criadaEm']?.toString()),
      'itensSalvos': decodificar(itens, (d) => d['salvoEm']?.toString()),
      'denuncias': decodificar(denuncias, (d) => d['criadaEm']?.toString()),
    };
  }

  /// Mescla um snapshot social remoto usando Last-Write-Wins (com prioridade
  /// para tombstones `excluida = true` em caso de empate de horário).
  static Future<void> mesclarSnapshotSocial(
    Map<String, dynamic> snapshot,
  ) async {
    final pubsBrutas = snapshot['publicacoes'] as List<dynamic>? ?? const [];
    for (final item in pubsBrutas) {
      if (item is! Map) continue;
      final remota = PublicacaoSocial.fromJson(Map<String, dynamic>.from(item));
      if (remota.id.isEmpty) continue;

      final local =
          await TimelineRepositorioSqlite.buscarPublicacaoPorId(remota.id);
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

    final storiesBrutos = snapshot['stories'] as List<dynamic>? ?? const [];
    for (final item in storiesBrutos) {
      if (item is! Map) continue;
      final story = StorySocial.fromJson(Map<String, dynamic>.from(item));
      if (story.id.isNotEmpty) {
        await TimelineRepositorioSqlite.salvarStory(story);
      }
    }

    final reacoesBrutas = snapshot['reacoes'] as List<dynamic>? ?? const [];
    for (final item in reacoesBrutas) {
      if (item is! Map) continue;
      final r = ReacaoSocial.fromJson(Map<String, dynamic>.from(item));
      if (r.id.isNotEmpty) {
        await TimelineRepositorioSqlite.salvarReacao(r);
      }
    }

    final comBrutos = snapshot['comentarios'] as List<dynamic>? ?? const [];
    for (final item in comBrutos) {
      if (item is! Map) continue;
      final c = ComentarioSocial.fromJson(Map<String, dynamic>.from(item));
      if (c.id.isNotEmpty) {
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
