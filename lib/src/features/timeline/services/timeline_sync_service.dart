import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nous/src/core/services/assinatura_rede_service.dart';
import 'package:nous/src/core/services/preferencias_soberanas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/helpers/resolvedor_url_rede.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/notificacao_social.dart';
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
    int offset = 0,
  }) {
    return TimelineSyncRepositorio.exportarSnapshotSocial(
      desde: desde,
      offset: offset,
    );
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

      int offset = 0;
      bool temMais = true;
      String? ultimoGeradoEm;
      int paginas = 0;

      while (temMais && paginas < 25) {
        paginas++;
        final snapshotLocal = offset == 0
            ? await exportarSnapshotSocial(desde: desde, offset: 0)
            : <String, dynamic>{};
        final payload = <String, dynamic>{
          ...snapshotLocal,
          if (desde != null) 'desde': desde.toIso8601String(),
          'offset': offset,
        };

        final uri = ResolvedorUrlRede.montarUriHttp(
          hostOuIp: ip,
          porta: porta,
          path: '/api/timeline/sincronizar',
        );
        final req = await client
            .postUrl(uri)
            .timeout(const Duration(seconds: 6));
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode(payload));
        final resp = await req.close().timeout(const Duration(seconds: 8));
        final corpo = await utf8.decodeStream(resp);
        if (resp.statusCode != HttpStatus.ok || corpo.isEmpty) {
          return paginas > 1;
        }
        final json = jsonDecode(corpo);
        if (json is Map<String, dynamic> && json['snapshot'] is Map) {
          final snapRemoto = Map<String, dynamic>.from(json['snapshot'] as Map);
          await mesclarSnapshotSocial(snapRemoto, aoConcluir: aoConcluir);
          ultimoGeradoEm = snapRemoto['geradoEm'] as String? ??
              DateTime.now().toIso8601String();
          temMais = snapRemoto['temMais'] == true;
          offset = (snapRemoto['proximoOffset'] as num?)?.toInt() ??
              (offset + 400);
        } else {
          break;
        }
      }

      if (ultimoGeradoEm != null) {
        await PreferenciasSoberanasService.salvarTexto(
          chaveUltimaSync,
          ultimoGeradoEm,
        );
        return true;
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
    unawaited(() async {
      String cpfAssinante = '';
      if (payload['publicacao'] is Map) {
        cpfAssinante = (payload['publicacao'] as Map)['autorCpf']?.toString() ?? '';
      } else if (payload['comentario'] is Map) {
        cpfAssinante = (payload['comentario'] as Map)['autorCpf']?.toString() ?? '';
      } else if (payload['story'] is Map) {
        cpfAssinante = (payload['story'] as Map)['autorCpf']?.toString() ?? '';
      } else if (payload['reacao'] is Map) {
        cpfAssinante = (payload['reacao'] as Map)['usuarioCpf']?.toString() ?? '';
      } else if (payload['usuarioCpf'] != null) {
        cpfAssinante = payload['usuarioCpf'].toString();
      }
      final eventoAssinado = cpfAssinante.isNotEmpty
          ? await AssinaturaRedeService.assinarPayload(evento, cpfAssinante)
          : evento;

      final servidor = ServidorRedeLocal();
      if (servidor.ativo) {
        servidor.notificarTodos(eventoAssinado);
        return;
      }
      final cliente = ClienteRedeLocal();
      if (cliente.conectado) {
        cliente.enviarMensagemRaw(eventoAssinado);
      }
    }());
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
      } else if (tipo == 'timeline_notificacao' && dados['notificacao'] is Map) {
        final notif = NotificacaoSocial.fromJson(
          Map<String, dynamic>.from(dados['notificacao'] as Map),
        );
        if (notif.id.isNotEmpty) {
          await TimelineRepositorioSqlite.salvarNotificacaoSocial(notif);
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
