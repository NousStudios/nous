import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nous/src/core/services/assinatura_rede_service.dart';
import 'package:nous/src/core/services/preferencias_soberanas_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/helpers/resolvedor_url_rede.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/transferencia_arquivos_rede.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/notificacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/models/salvos_denuncia_social.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/outbox_midia_service.dart';
import 'package:nous/src/features/timeline/services/timeline_midia_service.dart';
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
        if (paginas == 1) {
          await OutboxMidiaService.drenarFila(ip: ip, porta: porta);
          await _enviarMidiasLocaisPendentesParaServidor(ip: ip, porta: porta);
        }
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
          _preAquecerMidiasSnapshotRemoto(snapRemoto);
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
        unawaited(_curarMidiasAusentesEmDisco());
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
          _preAquecerMidiasPublicacao(pub);
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
          if (story.caminhoMidia.isNotEmpty) {
            unawaited(TimelineMidiaService.resolverCaminhoMidia(story.caminhoMidia));
          }
          if (story.autorFoto.isNotEmpty) {
            unawaited(TimelineMidiaService.resolverCaminhoMidia(story.autorFoto));
          }
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

  /// Faz upload para o servidor balcão de mídias de publicações e stories
  /// criados offline no dispositivo antes de enviar o snapshot JSON.
  static Future<void> _enviarMidiasLocaisPendentesParaServidor({
    required String ip,
    required int porta,
  }) async {
    try {
      final transfer = TransferenciaArquivosRede();
      final pubs = await TimelineRepositorioSqlite.listarPublicacoesDescoberta(
        limit: 200,
      );
      for (final pub in pubs) {
        bool alterou = false;
        final novasMidias = <MidiaPublicacao>[];
        for (final m in pub.midias) {
          if (m.caminhoRelativo.isEmpty) {
            novasMidias.add(m);
            continue;
          }
          final local = TimelineMidiaService.resolverCaminhoMidiaSync(
            m.caminhoRelativo,
          );
          if (local != null && File(local).existsSync()) {
            final ext = m.mimeTipo.toLowerCase();
            final ehImg = ext == 'jpg' ||
                ext == 'jpeg' ||
                ext == 'png' ||
                ext == 'webp' ||
                ext == 'gif';
            final remoto = ehImg
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
            if (remoto.isNotEmpty && remoto != m.caminhoRelativo) {
              novasMidias.add(m.copyWith(caminhoRelativo: remoto));
              alterou = true;
              continue;
            }
          }
          novasMidias.add(m);
        }

        var novaFotoAutor = pub.autorFoto;
        if (novaFotoAutor.isNotEmpty && !ImagemService.ehAsset(novaFotoAutor)) {
          final localFoto = ImagemService.resolverCaminhoExistente(novaFotoAutor);
          if (localFoto != null && File(localFoto).existsSync()) {
            final remotoFoto = await transfer.enviarUploadImagemParaServidor(
              ipServidor: ip,
              portaServidor: porta,
              caminhoLocal: localFoto,
            );
            if (remotoFoto.isNotEmpty && remotoFoto != novaFotoAutor) {
              novaFotoAutor = remotoFoto;
              alterou = true;
            }
          }
        }

        var novaCapa = pub.capaCaminho;
        if (novaCapa.isNotEmpty && !ImagemService.ehAsset(novaCapa)) {
          final localCapa = ImagemService.resolverCaminhoExistente(novaCapa);
          if (localCapa != null && File(localCapa).existsSync()) {
            final remotoCapa = await transfer.enviarUploadImagemParaServidor(
              ipServidor: ip,
              portaServidor: porta,
              caminhoLocal: localCapa,
            );
            if (remotoCapa.isNotEmpty && remotoCapa != novaCapa) {
              novaCapa = remotoCapa;
              alterou = true;
            }
          }
        }

        if (alterou) {
          await TimelineRepositorioSqlite.salvarPublicacao(
            pub.copyWith(
              midias: novasMidias,
              autorFoto: novaFotoAutor,
              capaCaminho: novaCapa,
              atualizadaEm: DateTime.now(),
            ),
          );
        }
      }

      final stories = await TimelineRepositorioSqlite.listarStoriesAtivosDaRede();
      for (final st in stories) {
        bool alterou = false;
        var novoCaminho = st.caminhoMidia;
        if (novoCaminho.isNotEmpty && !ImagemService.ehAsset(novoCaminho)) {
          final local = TimelineMidiaService.resolverCaminhoMidiaSync(novoCaminho);
          if (local != null && File(local).existsSync()) {
            final ehImg = st.tipoMidia == 'imagem';
            final remoto = ehImg
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
            if (remoto.isNotEmpty && remoto != novoCaminho) {
              novoCaminho = remoto;
              alterou = true;
            }
          }
        }

        var novaFotoAutor = st.autorFoto;
        if (novaFotoAutor.isNotEmpty && !ImagemService.ehAsset(novaFotoAutor)) {
          final localFoto = ImagemService.resolverCaminhoExistente(novaFotoAutor);
          if (localFoto != null && File(localFoto).existsSync()) {
            final remotoFoto = await transfer.enviarUploadImagemParaServidor(
              ipServidor: ip,
              portaServidor: porta,
              caminhoLocal: localFoto,
            );
            if (remotoFoto.isNotEmpty && remotoFoto != novaFotoAutor) {
              novaFotoAutor = remotoFoto;
              alterou = true;
            }
          }
        }

        if (alterou) {
          await TimelineRepositorioSqlite.salvarStory(
            st.copyWith(
              caminhoMidia: novoCaminho,
              autorFoto: novaFotoAutor,
              atualizadoEm: DateTime.now(),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint(
        '[TimelineSyncService] Erro ao enviar mídias pendentes para servidor: $e',
      );
    }
  }

  static void _preAquecerMidiasPublicacao(PublicacaoSocial pub) {
    if (!ClienteRedeLocal().conectado) return;
    for (final m in pub.midias) {
      if (m.caminhoRelativo.isNotEmpty) {
        unawaited(TimelineMidiaService.resolverCaminhoMidia(m.caminhoRelativo));
      }
    }
    if (pub.autorFoto.isNotEmpty) {
      unawaited(TimelineMidiaService.resolverCaminhoMidia(pub.autorFoto));
    }
  }

  static Future<void> _curarMidiasAusentesEmDisco() async {
    if (!ClienteRedeLocal().conectado) return;
    try {
      final pubs = await TimelineRepositorioSqlite.listarPublicacoesDescoberta(
        limit: 120,
      );
      int baixadas = 0;
      for (final pub in pubs) {
        if (!ClienteRedeLocal().conectado || baixadas >= 60) break;
        for (final m in pub.midias) {
          if (m.caminhoRelativo.isEmpty) continue;
          if (TimelineMidiaService.resolverCaminhoMidiaSync(m.caminhoRelativo) ==
              null) {
            await TimelineMidiaService.resolverCaminhoMidia(m.caminhoRelativo);
            baixadas++;
          }
        }
        if (pub.capaCaminho.isNotEmpty &&
            TimelineMidiaService.resolverCaminhoMidiaSync(pub.capaCaminho) ==
                null) {
          await TimelineMidiaService.resolverCaminhoMidia(pub.capaCaminho);
          baixadas++;
        }
      }
    } catch (_) {}
  }

  static void _preAquecerMidiasSnapshotRemoto(Map<String, dynamic> snap) {
    if (!ClienteRedeLocal().conectado) return;
    final pubsRaw = snap['publicacoes'] as List<dynamic>? ?? const [];
    for (final raw in pubsRaw.take(30)) {
      if (raw is Map<String, dynamic>) {
        final pub = PublicacaoSocial.fromJson(raw);
        _preAquecerMidiasPublicacao(pub);
      }
    }
    final storiesRaw = snap['stories'] as List<dynamic>? ?? const [];
    for (final raw in storiesRaw.take(20)) {
      if (raw is Map<String, dynamic>) {
        final st = StorySocial.fromJson(raw);
        if (st.caminhoMidia.isNotEmpty) {
          unawaited(TimelineMidiaService.resolverCaminhoMidia(st.caminhoMidia));
        }
        if (st.autorFoto.isNotEmpty) {
          unawaited(TimelineMidiaService.resolverCaminhoMidia(st.autorFoto));
        }
      }
    }
  }
}
