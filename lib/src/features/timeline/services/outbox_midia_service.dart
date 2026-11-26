import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/gerador_id.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/transferencia_arquivos_rede.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/services/timeline_midia_service.dart';
import 'package:nous/src/features/timeline/services/timeline_repositorio_sqlite.dart';

/// Fila Outbox persistida em SQLite para garantir entrega confiável de mídias
/// (posts, stories e avatares) criadas offline até o servidor balcão.
class OutboxMidiaService {
  OutboxMidiaService._();

  static final ValueNotifier<int> pendenciasNotifier = ValueNotifier<int>(0);
  static bool _tabelaGarantida = false;
  static bool _drenando = false;

  static Future<Database> _obterDb() async {
    final db = await TimelineRepositorioSqlite.obterDb();
    if (!_tabelaGarantida) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS outbox_midias (
          id TEXT PRIMARY KEY,
          entidade_tipo TEXT NOT NULL,
          entidade_id TEXT NOT NULL,
          caminho_local TEXT NOT NULL,
          eh_imagem INTEGER NOT NULL DEFAULT 1,
          tentativas INTEGER NOT NULL DEFAULT 0,
          criado_em TEXT NOT NULL,
          ultimo_erro TEXT NOT NULL DEFAULT ''
        );
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_outbox_midias_entidade ON outbox_midias (entidade_tipo, entidade_id);',
      );
      _tabelaGarantida = true;
    }
    return db;
  }

  static Future<void> atualizarContagemPendencias() async {
    try {
      final db = await _obterDb();
      final res = await db.rawQuery('SELECT COUNT(*) as total FROM outbox_midias');
      final total = (res.firstOrNull?['total'] as num?)?.toInt() ?? 0;
      if (pendenciasNotifier.value != total) {
        pendenciasNotifier.value = total;
      }
    } catch (_) {}
  }

  /// Enfileira uma mídia local para upload posterior quando houver conexão.
  static Future<void> enfileirar({
    required String entidadeTipo,
    required String entidadeId,
    required String caminhoLocal,
    bool ehImagem = true,
  }) async {
    final limpo = caminhoLocal.trim();
    if (limpo.isEmpty || ImagemService.ehAsset(limpo)) return;

    try {
      final db = await _obterDb();
      final existentes = await db.query(
        'outbox_midias',
        columns: ['id'],
        where: 'entidade_tipo = ? AND entidade_id = ? AND caminho_local = ?',
        whereArgs: [entidadeTipo, entidadeId, limpo],
        limit: 1,
      );
      if (existentes.isNotEmpty) return;

      await db.insert('outbox_midias', {
        'id': gerarIdUnico(),
        'entidade_tipo': entidadeTipo,
        'entidade_id': entidadeId,
        'caminho_local': limpo,
        'eh_imagem': ehImagem ? 1 : 0,
        'tentativas': 0,
        'criado_em': DateTime.now().toIso8601String(),
        'ultimo_erro': '',
      });
      await atualizarContagemPendencias();
    } catch (e) {
      debugPrint('[OutboxMidiaService] Erro ao enfileirar mídia: $e');
    }
  }

  /// Drena a fila enviando as mídias pendentes para o servidor balcão conectado.
  static Future<int> drenarFila({
    required String ip,
    required int porta,
  }) async {
    if (_drenando || ip.trim().isEmpty || porta <= 0) return 0;
    _drenando = true;
    int enviadas = 0;

    try {
      final db = await _obterDb();
      final rows = await db.query(
        'outbox_midias',
        orderBy: 'criado_em ASC',
        limit: 50,
      );
      if (rows.isEmpty) {
        await atualizarContagemPendencias();
        return 0;
      }

      final transfer = TransferenciaArquivosRede();
      for (final row in rows) {
        final id = row['id'] as String;
        final tipo = row['entidade_tipo'] as String;
        final entidadeId = row['entidade_id'] as String;
        final caminhoOriginal = row['caminho_local'] as String;
        final ehImagem = (row['eh_imagem'] as int? ?? 1) == 1;
        final tentativas = row['tentativas'] as int? ?? 0;

        final local = TimelineMidiaService.resolverCaminhoMidiaSync(
              caminhoOriginal,
            ) ??
            ImagemService.resolverCaminhoExistente(caminhoOriginal);

        if (local == null || !File(local).existsSync()) {
          await db.delete('outbox_midias', where: 'id = ?', whereArgs: [id]);
          continue;
        }

        try {
          final remoto = ehImagem
              ? await transfer.enviarUploadImagemParaServidor(
                  ipServidor: ip,
                  portaServidor: porta,
                  caminhoLocal: local,
                )
              : await transfer.enviarUploadAnexoParaServidor(
                  ipServidor: ip,
                  portaServidor: porta,
                  caminhoLocal: local,
                  subpasta: 'timeline_midias',
                );

          if (remoto.isNotEmpty) {
            await _atualizarEntidadeComCaminhoRemoto(
              tipo: tipo,
              entidadeId: entidadeId,
              caminhoAntigo: caminhoOriginal,
              caminhoRemoto: remoto,
            );
            await db.delete('outbox_midias', where: 'id = ?', whereArgs: [id]);
            enviadas++;
          } else {
            await db.update(
              'outbox_midias',
              {
                'tentativas': tentativas + 1,
                'ultimo_erro': 'Servidor não retornou caminho válido',
              },
              where: 'id = ?',
              whereArgs: [id],
            );
          }
        } catch (e) {
          await db.update(
            'outbox_midias',
            {
              'tentativas': tentativas + 1,
              'ultimo_erro': e.toString(),
            },
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      }

      await atualizarContagemPendencias();
    } catch (e) {
      debugPrint('[OutboxMidiaService] Erro ao drenar fila: $e');
    } finally {
      _drenando = false;
    }

    return enviadas;
  }

  static Future<void> _atualizarEntidadeComCaminhoRemoto({
    required String tipo,
    required String entidadeId,
    required String caminhoAntigo,
    required String caminhoRemoto,
  }) async {
    if (caminhoAntigo == caminhoRemoto) return;
    if (tipo == 'publicacao') {
      final pub = await TimelineRepositorioSqlite.buscarPublicacaoPorId(
        entidadeId,
      );
      if (pub != null) {
        var alterou = false;
        final novasMidias = <MidiaPublicacao>[];
        for (final m in pub.midias) {
          if (m.caminhoRelativo == caminhoAntigo) {
            novasMidias.add(m.copyWith(caminhoRelativo: caminhoRemoto));
            alterou = true;
          } else {
            novasMidias.add(m);
          }
        }
        final novaFotoAutor =
            pub.autorFoto == caminhoAntigo ? caminhoRemoto : pub.autorFoto;
        if (novaFotoAutor != pub.autorFoto) alterou = true;
        if (alterou) {
          await TimelineRepositorioSqlite.salvarPublicacao(
            pub.copyWith(
              midias: novasMidias,
              autorFoto: novaFotoAutor,
              atualizadaEm: DateTime.now(),
            ),
          );
        }
      }
    } else if (tipo == 'story') {
      final st = await TimelineRepositorioSqlite.buscarStoryPorId(entidadeId);
      if (st != null) {
        final novoMidia =
            st.caminhoMidia == caminhoAntigo ? caminhoRemoto : st.caminhoMidia;
        final novoAutorFoto =
            st.autorFoto == caminhoAntigo ? caminhoRemoto : st.autorFoto;
        if (novoMidia != st.caminhoMidia || novoAutorFoto != st.autorFoto) {
          await TimelineRepositorioSqlite.salvarStory(
            st.copyWith(
              caminhoMidia: novoMidia,
              autorFoto: novoAutorFoto,
              atualizadoEm: DateTime.now(),
            ),
          );
        }
      }
    } else if (tipo == 'usuario') {
      final conta = await ContasNousService.buscarPorCpf(entidadeId);
      if (conta != null) {
        final novaFoto =
            conta.foto == caminhoAntigo ? caminhoRemoto : conta.foto;
        final novaFotoPub = conta.fotoPublica == caminhoAntigo
            ? caminhoRemoto
            : conta.fotoPublica;
        if (novaFoto != conta.foto || novaFotoPub != conta.fotoPublica) {
          await ContasNousService.salvar(
            conta.copyWith(foto: novaFoto, fotoPublica: novaFotoPub),
          );
        }
      }
    }
  }
}
