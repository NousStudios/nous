import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nous/src/core/services/preferencias_soberanas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/models/salvos_denuncia_social.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_repositorio_sqlite.dart';
import 'package:nous/src/features/timeline/services/timeline_sync_repositorio.dart';

/// Serviço de sincronização em rede local (WebSocket + Delta Sync HTTP) da Timeline.
class TimelineSyncService {
  TimelineSyncService._();

  static Future<Map<String, dynamic>> exportarSnapshotSocial({
    DateTime? desde,
  }) {
    return TimelineSyncRepositorio.exportarSnapshotSocial(desde: desde);
  }

  static Future<void> mesclarSnapshotSocial(
    Map<String, dynamic> snapshot, {
    VoidCallback? aoConcluir,
  }) async {
    await TimelineSyncRepositorio.mesclarSnapshotSocial(snapshot);
    aoConcluir?.call();
  }

  /// Sincroniza bidirecionalmente com o servidor usando Delta Sync por timestamp (`desde`),
  /// reduzindo drasticamente o tráfego conforme o histórico cresce.
  static Future<bool> sincronizarComServidorHttp({
    required String ip,
    required int porta,
    VoidCallback? aoConcluir,
  }) async {
    if (ip.trim().isEmpty || porta <= 0) return false;
    final chaveUltimaSync = 'timeline_ultima_sync_${ip}_$porta';
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      DateTime? desde;
      try {
        final rawDesde =
            await PreferenciasSoberanasService.obterTexto(chaveUltimaSync);
        if (rawDesde != null && rawDesde.isNotEmpty) {
          desde = DateTime.tryParse(rawDesde);
        }
      } catch (_) {}

      final snapshotLocal = await exportarSnapshotSocial(desde: desde);
      final payload = <String, dynamic>{
        ...snapshotLocal,
        if (desde != null) 'desde': desde.toIso8601String(),
      };

      final req = await client
          .post(ip, porta, '/api/timeline/sincronizar')
          .timeout(const Duration(seconds: 6));
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode(payload));
      final resp = await req.close().timeout(const Duration(seconds: 8));
      final corpo = await utf8.decodeStream(resp);
      if (resp.statusCode == HttpStatus.ok && corpo.isNotEmpty) {
        final json = jsonDecode(corpo);
        if (json is Map<String, dynamic> && json['snapshot'] is Map) {
          final snapRemoto = Map<String, dynamic>.from(json['snapshot'] as Map);
          await mesclarSnapshotSocial(snapRemoto, aoConcluir: aoConcluir);
          final geradoEm = snapRemoto['geradoEm'] as String? ??
              DateTime.now().toIso8601String();
          await PreferenciasSoberanasService.salvarTexto(
            chaveUltimaSync,
            geradoEm,
          );
          return true;
        }
      }
    } catch (e) {
      debugPrint(
        '[TimelineSyncService] Erro ao sincronizar com servidor HTTP: $e',
      );
    } finally {
      client.close(force: true);
    }
    return false;
  }

  static void despacharEventoRede(
    String tipo,
    Map<String, dynamic> payload,
  ) {
    final evento = <String, dynamic>{'tipo': tipo, ...payload};
    final servidor = ServidorRedeLocal();
    if (servidor.ativo) {
      servidor.notificarTodos(evento);
      return;
    }
    final cliente = ClienteRedeLocal();
    if (cliente.conectado) {
      cliente.enviarMensagemRaw(evento);
    }
  }

  static Future<void> processarEventoRemoto(
    Map<String, dynamic> dados, {
    VoidCallback? aoConcluir,
  }) async {
    final tipo = dados['tipo'] as String? ?? '';
    try {
      if (tipo == 'timeline_publicacao' && dados['publicacao'] is Map) {
        final pub = PublicacaoSocial.fromJson(
          Map<String, dynamic>.from(dados['publicacao'] as Map),
        );
        if (pub.id.isNotEmpty) {
          await TimelineRepositorioSqlite.salvarPublicacao(pub);
          aoConcluir?.call();
        }
      } else if (tipo == 'timeline_reacao' && dados['reacao'] is Map) {
        final reacao = ReacaoSocial.fromJson(
          Map<String, dynamic>.from(dados['reacao'] as Map),
        );
        if (reacao.id.isNotEmpty) {
          await TimelineRepositorioSqlite.salvarReacao(reacao);
          aoConcluir?.call();
        }
      } else if (tipo == 'timeline_reacao_removida') {
        final pubId = dados['publicacaoId'] as String? ?? '';
        final cpf = dados['usuarioCpf'] as String? ?? '';
        if (pubId.isNotEmpty && cpf.isNotEmpty) {
          await TimelineRepositorioSqlite.removerReacao(
            publicacaoId: pubId,
            usuarioCpf: cpf,
          );
          aoConcluir?.call();
        }
      } else if (tipo == 'timeline_comentario' && dados['comentario'] is Map) {
        final com = ComentarioSocial.fromJson(
          Map<String, dynamic>.from(dados['comentario'] as Map),
        );
        if (com.id.isNotEmpty) {
          await TimelineRepositorioSqlite.salvarComentario(com);
          aoConcluir?.call();
        }
      } else if (tipo == 'timeline_story' && dados['story'] is Map) {
        final story = StorySocial.fromJson(
          Map<String, dynamic>.from(dados['story'] as Map),
        );
        if (story.id.isNotEmpty) {
          await TimelineRepositorioSqlite.salvarStory(story);
          aoConcluir?.call();
        }
      } else if (tipo == 'timeline_lista_salvos' && dados['lista'] is Map) {
        final lista = ListaSalvosSocial.fromJson(
          Map<String, dynamic>.from(dados['lista'] as Map),
        );
        if (lista.id.isNotEmpty) {
          await TimelineRepositorioSqlite.salvarListaSalvos(lista);
          aoConcluir?.call();
        }
      } else if (tipo == 'timeline_item_salvo' && dados['item'] is Map) {
        final item = ItemSalvoSocial.fromJson(
          Map<String, dynamic>.from(dados['item'] as Map),
        );
        if (item.id.isNotEmpty) {
          await TimelineRepositorioSqlite.salvarItemSalvo(item);
          aoConcluir?.call();
        }
      } else if (tipo == 'timeline_denuncia' && dados['denuncia'] is Map) {
        final den = DenunciaSocial.fromJson(
          Map<String, dynamic>.from(dados['denuncia'] as Map),
        );
        if (den.id.isNotEmpty) {
          await TimelineRepositorioSqlite.salvarDenuncia(den);
          aoConcluir?.call();
        }
      } else if (tipo == 'timeline_config') {
        final cpf = dados['cpf'] as String? ?? '';
        final tipos = (dados['tipos'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList();
        if (cpf.isNotEmpty) {
          await TimelineRepositorioSqlite.salvarTimelinesVisiveis(cpf, tipos);
          aoConcluir?.call();
        }
      }
    } catch (e) {
      debugPrint(
        '[TimelineSyncService] Erro ao processar evento remoto $tipo: $e',
      );
    }
  }
}
