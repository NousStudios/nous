import 'dart:async';

import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/services/outbox_midia_service.dart';
import 'package:nous/src/features/timeline/services/timeline_midia_service.dart';
import 'package:nous/src/features/timeline/services/timeline_repositorio_sqlite.dart';
import 'package:nous/src/features/timeline/services/timeline_sync_service.dart';

/// Helper responsável por sincronização de mídias/capa de publicações
/// e classificação de tipos de mídia por feed.
class TimelinePublicacaoMidiaHelper {
  TimelinePublicacaoMidiaHelper._();

  static void agendarSincronizacaoMidiasECapa({
    required PublicacaoSocial publicacao,
    required List<MidiaPublicacao> midias,
    required String capaCaminho,
  }) {
    unawaited(() async {
      try {
        if (!ClienteRedeLocal().conectado && !ServidorRedeLocal().ativo) {
          await _enfileirarMidiasOffline(
            publicacaoId: publicacao.id,
            midias: midias,
            capaCaminho: capaCaminho,
          );
          return;
        }
        final midiasSinc =
            await TimelineMidiaService.sincronizarMidiasParaServidor(midias);
        var capaSinc = capaCaminho;
        if (capaSinc.isNotEmpty) {
          final capaLocal = await TimelineMidiaService.resolverCaminhoMidia(
            capaSinc,
          );
          if (capaLocal != null) {
            final capaRemota = await ClienteRedeLocal().enviarUploadImagem(
              capaLocal,
            );
            if (capaRemota.isNotEmpty) capaSinc = capaRemota;
          }
        }
        final pubFinal = publicacao.copyWith(
          midias: midiasSinc,
          capaCaminho: capaSinc,
        );
        if (midiasSinc != midias || capaSinc != capaCaminho) {
          await TimelineRepositorioSqlite.salvarPublicacao(pubFinal);
        }
        TimelineSyncService.despacharEventoRede(
          'timeline_publicacao',
          {'publicacao': pubFinal.toJson()},
        );
      } catch (_) {}
    }());
  }

  static Future<void> _enfileirarMidiasOffline({
    required String publicacaoId,
    required List<MidiaPublicacao> midias,
    required String capaCaminho,
  }) async {
    for (final m in midias) {
      final ext = m.mimeTipo.toLowerCase();
      final ehImg = ext == 'jpg' ||
          ext == 'jpeg' ||
          ext == 'png' ||
          ext == 'webp' ||
          ext == 'gif';
      await OutboxMidiaService.enfileirar(
        entidadeTipo: 'publicacao',
        entidadeId: publicacaoId,
        caminhoLocal: m.caminhoRelativo,
        ehImagem: ehImg,
      );
    }
    if (capaCaminho.isNotEmpty) {
      await OutboxMidiaService.enfileirar(
        entidadeTipo: 'publicacao',
        entidadeId: publicacaoId,
        caminhoLocal: capaCaminho,
      );
    }
  }

  static String extensaoMidia(MidiaPublicacao m) {
    final fontes = [m.nomeArquivo, m.caminhoRelativo, m.mimeTipo];
    for (final f in fontes) {
      final limpo = f.trim().toLowerCase();
      if (limpo.isEmpty) continue;
      final idx = limpo.lastIndexOf('.');
      if (idx != -1 && idx < limpo.length - 1) {
        return limpo.substring(idx + 1);
      }
      if (!limpo.contains('/') && !limpo.contains('\\') && limpo.length <= 5) {
        return limpo;
      }
    }
    return '';
  }

  static bool ehMidiaImagem(MidiaPublicacao m) {
    const exts = {'png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp', 'heic'};
    return exts.contains(extensaoMidia(m));
  }

  static bool ehMidiaVideo(MidiaPublicacao m) {
    const exts = {'mp4', 'mov', 'mkv', 'webm', 'avi', '3gp', 'm4v'};
    return exts.contains(extensaoMidia(m));
  }

  static bool ehMidiaAudio(MidiaPublicacao m) {
    const exts = {'mp3', 'wav', 'm4a', 'ogg', 'flac', 'aac'};
    return exts.contains(extensaoMidia(m));
  }

  static bool ehMidiaDocumento(MidiaPublicacao m) {
    const exts = {
      'pdf',
      'txt',
      'doc',
      'docx',
      'xls',
      'xlsx',
      'csv',
      'zip',
      'json',
      'md',
      'epub',
    };
    return exts.contains(extensaoMidia(m));
  }

  static bool publicacaoPertenceAoFeed(
    PublicacaoSocial p,
    TipoFeedSocial feed,
  ) {
    switch (feed) {
      case TipoFeedSocial.fotos:
        if (p.tipo != TipoFeedSocial.fotos) return false;
        if (p.midias.isEmpty) return true;
        return p.midias.any(ehMidiaImagem) && !p.midias.every(ehMidiaDocumento);
      case TipoFeedSocial.videos:
        if (p.tipo != TipoFeedSocial.videos) return false;
        if (p.midias.isEmpty) return true;
        return p.midias.any(ehMidiaVideo);
      case TipoFeedSocial.musicas:
        if (p.tipo != TipoFeedSocial.musicas) return false;
        if (p.midias.isEmpty) return true;
        return p.midias.any(ehMidiaAudio);
      case TipoFeedSocial.documentos:
        if (p.tipo == TipoFeedSocial.livros) return false;
        if (p.tipo == TipoFeedSocial.documentos) {
          return p.midias.isEmpty || p.midias.any(ehMidiaDocumento);
        }
        return p.midias.isNotEmpty && p.midias.every(ehMidiaDocumento);
      case TipoFeedSocial.livros:
        if (p.tipo != TipoFeedSocial.livros) return false;
        return p.midias.isEmpty || p.midias.any(ehMidiaDocumento);
      case TipoFeedSocial.escritos:
        return p.tipo == TipoFeedSocial.escritos && p.midias.isEmpty;
      default:
        return true;
    }
  }
}
