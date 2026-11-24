import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nous/src/core/services/gerador_id.dart';
import 'package:nous/src/features/timeline/models/notificacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/outbox_midia_service.dart';
import 'package:nous/src/features/timeline/services/timeline_interacoes_service.dart';
import 'package:nous/src/features/timeline/services/timeline_midia_service.dart';
import 'package:nous/src/features/timeline/services/timeline_repositorio_sqlite.dart';
import 'package:nous/src/features/timeline/services/timeline_sync_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

/// Serviço especializado em publicações sociais: criação, edição, exclusão,
/// arquivamento, colaboração, fixação, reordenação, visualizações e feeds do usuário.
class TimelinePublicacoesService {
  TimelinePublicacoesService._();

  static final Set<String> _visualizadasSessao = {};

  static const List<TipoFeedSocial> timelinesPadrao = [
    TipoFeedSocial.fotos,
    TipoFeedSocial.videos,
    TipoFeedSocial.interacoes,
  ];

  static Future<PublicacaoSocial> criarPublicacao({
    required String autorCpf,
    required String autorNome,
    String autorFoto = '',
    required TipoFeedSocial tipo,
    String texto = '',
    List<MidiaPublicacao> midias = const [],
    List<String> coautoresCpfs = const [],
    PadraoExibicaoMidia padraoExibicao = PadraoExibicaoMidia.original,
    double? proporcaoCustom,
    int colunasMosaico = 3,
    bool permitirDownload = true,
    double alinhamentoX = 0.0,
    double alinhamentoY = 0.0,
    double escalaZoom = 1.0,
    String lojaIdTag = '',
    String itemLojaIdTag = '',
    String itemLojaNomeTag = '',
    String itemLojaPrecoTag = '',
    String capaCaminho = '',
    String cifraLetra = '',
    VoidCallback? onNotificar,
  }) async {
    final agora = DateTime.now();
    final textoLimpo = texto.trim();
    final autorNorm = TimelineRepositorioSqlite.normalizarCpf(autorCpf);
    final convidadosPendentes = coautoresCpfs
        .map(TimelineRepositorioSqlite.normalizarCpf)
        .where((c) => c.isNotEmpty && c != autorNorm)
        .toSet()
        .toList();
    final pub = PublicacaoSocial(
      id: 'pub_${gerarIdUnico()}',
      autorCpf: autorNorm,
      autorNome: autorNome,
      autorFoto: autorFoto,
      coautoresCpfs: const [],
      coautoresPendentesCpfs: convidadosPendentes,
      tipo: tipo,
      texto: textoLimpo,
      midias: midias,
      padraoExibicao: padraoExibicao,
      proporcaoCustom: proporcaoCustom,
      colunasMosaico: colunasMosaico.clamp(1, 6),
      permitirDownload: permitirDownload,
      alinhamentoX: alinhamentoX.clamp(-1.0, 1.0),
      alinhamentoY: alinhamentoY.clamp(-1.0, 1.0),
      escalaZoom: escalaZoom.clamp(1.0, 3.5),
      tags: PublicacaoSocial.extrairTags(textoLimpo),
      lojaIdTag: lojaIdTag,
      itemLojaIdTag: itemLojaIdTag,
      itemLojaNomeTag: itemLojaNomeTag,
      itemLojaPrecoTag: itemLojaPrecoTag,
      capaCaminho: capaCaminho,
      cifraLetra: cifraLetra,
      criadaEm: agora,
      atualizadaEm: agora,
    );

    await TimelineRepositorioSqlite.salvarPublicacao(pub);
    await ativarTimelineAutomaticamente(
      autorCpf,
      tipo,
      onNotificar: onNotificar,
    );
    onNotificar?.call();
    unawaited(
      TimelineInteracoesService.processarMencoesTexto(
        texto: textoLimpo,
        autorCpf: autorCpf,
        autorNome: autorNome,
        autorFoto: autorFoto,
        publicacaoId: pub.id,
      ),
    );
    if (convidadosPendentes.isNotEmpty) {
      unawaited(
        _notificarConvitesColaboracao(
          convidadosCpfs: convidadosPendentes,
          autorCpf: autorCpf,
          autorNome: autorNome,
          autorFoto: autorFoto,
          publicacaoId: pub.id,
        ),
      );
    }

    unawaited(() async {
      try {
        if (!ClienteRedeLocal().conectado && !ServidorRedeLocal().ativo) {
          for (final m in midias) {
            final ext = m.mimeTipo.toLowerCase();
            final ehImg = ext == 'jpg' ||
                ext == 'jpeg' ||
                ext == 'png' ||
                ext == 'webp' ||
                ext == 'gif';
            await OutboxMidiaService.enfileirar(
              entidadeTipo: 'publicacao',
              entidadeId: pub.id,
              caminhoLocal: m.caminhoRelativo,
              ehImagem: ehImg,
            );
          }
          if (capaCaminho.isNotEmpty) {
            await OutboxMidiaService.enfileirar(
              entidadeTipo: 'publicacao',
              entidadeId: pub.id,
              caminhoLocal: capaCaminho,
            );
          }
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
        final pubFinal = pub.copyWith(
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

    return pub;
  }

  static Future<void> excluirPublicacao(
    PublicacaoSocial pub, {
    VoidCallback? onNotificar,
  }) async {
    // Compactação simbólica: remove listas pesadas/tags/coautores do índice,
    // preservando metadados mínimos para eventual restauração administrativa/usuário.
    final excluida = pub.copyWith(
      excluida: true,
      arquivada: false,
      fixada: false,
      tags: const [],
      coautoresCpfs: const [],
      atualizadaEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarPublicacao(excluida);
    onNotificar?.call();
    TimelineSyncService.despacharEventoRede(
      'timeline_publicacao',
      {'publicacao': excluida.toJson()},
    );
  }

  static Future<void> arquivarPublicacao(
    PublicacaoSocial pub, {
    required bool arquivar,
    VoidCallback? onNotificar,
  }) async {
    final atualizada = pub.copyWith(
      arquivada: arquivar,
      fixada: arquivar ? false : pub.fixada,
      atualizadaEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarPublicacao(atualizada);
    onNotificar?.call();
    TimelineSyncService.despacharEventoRede(
      'timeline_publicacao',
      {'publicacao': atualizada.toJson()},
    );
  }

  static Future<void> restaurarPublicacaoExcluida(
    PublicacaoSocial pub, {
    VoidCallback? onNotificar,
  }) async {
    final restaurada = pub.copyWith(
      excluida: false,
      arquivada: false,
      tags: PublicacaoSocial.extrairTags(pub.texto),
      atualizadaEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarPublicacao(restaurada);
    onNotificar?.call();
    TimelineSyncService.despacharEventoRede(
      'timeline_publicacao',
      {'publicacao': restaurada.toJson()},
    );
  }

  static Future<void> registrarVisualizacaoPublicacao(
    PublicacaoSocial pub, {
    required String origem,
    String? visualizadorCpf,
    int segundosVisualizados = 4,
    VoidCallback? onNotificar,
  }) async {
    final cpfNorm = TimelineRepositorioSqlite.normalizarCpf(visualizadorCpf ?? '');
    if (cpfNorm.isEmpty && _visualizadasSessao.contains(pub.id)) return;
    _visualizadasSessao.add(pub.id);

    final atual =
        await TimelineRepositorioSqlite.buscarPublicacaoPorId(pub.id) ?? pub;
    if (cpfNorm.isNotEmpty && atual.visualizadoresCpfs.contains(cpfNorm)) {
      return;
    }

    final novosVisualizadores = cpfNorm.isNotEmpty
        ? [...atual.visualizadoresCpfs, cpfNorm]
        : atual.visualizadoresCpfs;
    final origens = Map<String, int>.from(atual.visualizacoesPorOrigem);
    origens[origem] = (origens[origem] ?? 0) + 1;
    final total = atual.visualizacoes + 1;
    final mediaAnterior = atual.tempoMedioVisualizacaoSegundos;
    final novaMedia = total <= 1
        ? segundosVisualizados
        : ((mediaAnterior * (total - 1) + segundosVisualizados) / total)
            .round();
    final atualizada = atual.copyWith(
      visualizacoes: total,
      visualizadoresCpfs: novosVisualizadores,
      visualizacoesPorOrigem: origens,
      tempoMedioVisualizacaoSegundos: novaMedia,
      atualizadaEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarPublicacao(atualizada);
    onNotificar?.call();
    TimelineSyncService.despacharEventoRede(
      'timeline_publicacao',
      {'publicacao': atualizada.toJson()},
    );
  }

  /// Acumula o tempo real (em segundos) que um usuário permaneceu vendo a publicação
  /// e recalcula o tempo médio a partir de todos os visualizadores.
  static Future<void> registrarTempoVisualizacao(
    String publicacaoId,
    String? visualizadorCpf,
    int segundos, {
    VoidCallback? onNotificar,
  }) async {
    if (segundos < 1) return;
    final cpfNorm = TimelineRepositorioSqlite.normalizarCpf(visualizadorCpf ?? '');
    if (cpfNorm.isEmpty) return;

    final atual =
        await TimelineRepositorioSqlite.buscarPublicacaoPorId(publicacaoId);
    if (atual == null) return;

    final tempos = Map<String, int>.from(atual.tempoPorVisualizador);
    tempos[cpfNorm] = (tempos[cpfNorm] ?? 0) + segundos;
    final visualizadores = atual.visualizadoresCpfs.contains(cpfNorm)
        ? atual.visualizadoresCpfs
        : [...atual.visualizadoresCpfs, cpfNorm];

    final somaTempos = tempos.values.fold<int>(0, (a, b) => a + b);
    final novaMedia =
        tempos.isNotEmpty ? (somaTempos / tempos.length).round() : segundos;

    final atualizada = atual.copyWith(
      visualizadoresCpfs: visualizadores,
      visualizacoes: visualizadores.length > atual.visualizacoes
          ? visualizadores.length
          : atual.visualizacoes,
      tempoPorVisualizador: tempos,
      tempoMedioVisualizacaoSegundos: novaMedia,
      atualizadaEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarPublicacao(atualizada);
    onNotificar?.call();
    TimelineSyncService.despacharEventoRede(
      'timeline_publicacao',
      {'publicacao': atualizada.toJson()},
    );
  }

  static Future<PublicacaoSocial> editarPublicacao(
    PublicacaoSocial pub, {
    required String novoTexto,
    bool? permitirDownload,
    List<String>? coautoresCpfs,
    List<MidiaPublicacao>? midias,
    PadraoExibicaoMidia? padraoExibicao,
    double? proporcaoCustom,
    VoidCallback? onNotificar,
  }) async {
    final textoLimpo = novoTexto.trim();
    final autorNorm = TimelineRepositorioSqlite.normalizarCpf(pub.autorCpf);
    List<String> aceitos = pub.coautoresCpfs;
    List<String> pendentes = pub.coautoresPendentesCpfs;
    List<String> novosConvidados = const [];

    if (coautoresCpfs != null) {
      final desejados = coautoresCpfs
          .map(TimelineRepositorioSqlite.normalizarCpf)
          .where((c) => c.isNotEmpty && c != autorNorm)
          .toSet();
      final jaAceitos =
          pub.coautoresCpfs.map(TimelineRepositorioSqlite.normalizarCpf).toSet();
      final jaPendentes = pub.coautoresPendentesCpfs
          .map(TimelineRepositorioSqlite.normalizarCpf)
          .toSet();
      aceitos = desejados.where((c) => jaAceitos.contains(c)).toList();
      pendentes = desejados.where((c) => !jaAceitos.contains(c)).toList();
      novosConvidados =
          pendentes.where((c) => !jaPendentes.contains(c)).toList();
    }

    final atualizada = pub.copyWith(
      texto: textoLimpo,
      tags: PublicacaoSocial.extrairTags(textoLimpo),
      permitirDownload: permitirDownload ?? pub.permitirDownload,
      coautoresCpfs: aceitos,
      coautoresPendentesCpfs: pendentes,
      midias: midias ?? pub.midias,
      padraoExibicao: padraoExibicao ?? pub.padraoExibicao,
      proporcaoCustom: proporcaoCustom ?? pub.proporcaoCustom,
      atualizadaEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarPublicacao(atualizada);
    onNotificar?.call();
    TimelineSyncService.despacharEventoRede(
      'timeline_publicacao',
      {'publicacao': atualizada.toJson()},
    );
    if (novosConvidados.isNotEmpty) {
      unawaited(
        _notificarConvitesColaboracao(
          convidadosCpfs: novosConvidados,
          autorCpf: pub.autorCpf,
          autorNome: pub.autorNome,
          autorFoto: pub.autorFoto,
          publicacaoId: pub.id,
        ),
      );
    }
    return atualizada;
  }

  static Future<void> _notificarConvitesColaboracao({
    required List<String> convidadosCpfs,
    required String autorCpf,
    required String autorNome,
    required String autorFoto,
    required String publicacaoId,
  }) async {
    for (final destCpf in convidadosCpfs) {
      await TimelineInteracoesService.emitirNotificacaoSocial(
        destinatarioCpf: destCpf,
        autorCpf: autorCpf,
        autorNome: autorNome,
        autorFoto: autorFoto,
        tipo: TipoNotificacaoSocial.conviteColaboracao,
        publicacaoId: publicacaoId,
        resumo: '$autorNome marcou você para colaborar em uma publicação.',
      );
    }
  }

  static Future<PublicacaoSocial?> responderConviteColaboracao({
    required String publicacaoId,
    required String usuarioCpf,
    required bool aceitar,
    String? notificacaoId,
    VoidCallback? onNotificar,
  }) async {
    final cpfNorm = TimelineRepositorioSqlite.normalizarCpf(usuarioCpf);
    if (cpfNorm.isEmpty) return null;
    final pub = await TimelineRepositorioSqlite.buscarPublicacaoPorId(
      publicacaoId,
    );
    if (pub != null) {
      final novosPendentes = pub.coautoresPendentesCpfs
          .map(TimelineRepositorioSqlite.normalizarCpf)
          .where((c) => c.isNotEmpty && c != cpfNorm)
          .toSet()
          .toList();
      final novosAceitos = pub.coautoresCpfs
          .map(TimelineRepositorioSqlite.normalizarCpf)
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList();
      if (aceitar && !novosAceitos.contains(cpfNorm)) {
        novosAceitos.add(cpfNorm);
      }
      final atualizada = pub.copyWith(
        coautoresCpfs: novosAceitos,
        coautoresPendentesCpfs: novosPendentes,
        atualizadaEm: DateTime.now(),
      );
      await TimelineRepositorioSqlite.salvarPublicacao(atualizada);
      if (aceitar) {
        await ativarTimelineAutomaticamente(
          cpfNorm,
          atualizada.tipo,
          onNotificar: onNotificar,
        );
      }
      onNotificar?.call();
      TimelineSyncService.despacharEventoRede(
        'timeline_publicacao',
        {'publicacao': atualizada.toJson()},
      );
      if (notificacaoId != null && notificacaoId.isNotEmpty) {
        await TimelineRepositorioSqlite.marcarNotificacaoSocialLida(
          notificacaoId,
        );
      }
      return atualizada;
    }
    if (notificacaoId != null && notificacaoId.isNotEmpty) {
      await TimelineRepositorioSqlite.marcarNotificacaoSocialLida(
        notificacaoId,
      );
      onNotificar?.call();
    }
    return null;
  }

  static Future<PublicacaoSocial> cancelarConviteColaboracao({
    required PublicacaoSocial publicacao,
    required String cpfAlvo,
    VoidCallback? onNotificar,
  }) async {
    final cpfNorm = TimelineRepositorioSqlite.normalizarCpf(cpfAlvo);
    final novosPendentes = publicacao.coautoresPendentesCpfs
        .map(TimelineRepositorioSqlite.normalizarCpf)
        .where((c) => c.isNotEmpty && c != cpfNorm)
        .toSet()
        .toList();
    final atualizada = publicacao.copyWith(
      coautoresPendentesCpfs: novosPendentes,
      atualizadaEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarPublicacao(atualizada);
    onNotificar?.call();
    TimelineSyncService.despacharEventoRede(
      'timeline_publicacao',
      {'publicacao': atualizada.toJson()},
    );
    return atualizada;
  }

  static Future<void> reenviarConviteColaboracao({
    required PublicacaoSocial publicacao,
    required String cpfAlvo,
  }) async {
    final cpfNorm = TimelineRepositorioSqlite.normalizarCpf(cpfAlvo);
    if (cpfNorm.isEmpty) return;
    await _notificarConvitesColaboracao(
      convidadosCpfs: [cpfNorm],
      autorCpf: publicacao.autorCpf,
      autorNome: publicacao.autorNome,
      autorFoto: publicacao.autorFoto,
      publicacaoId: publicacao.id,
    );
  }

  static String _extensaoMidia(MidiaPublicacao m) {
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

  static bool _ehMidiaImagem(MidiaPublicacao m) {
    const exts = {'png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp', 'heic'};
    return exts.contains(_extensaoMidia(m));
  }

  static bool _ehMidiaVideo(MidiaPublicacao m) {
    const exts = {'mp4', 'mov', 'mkv', 'webm', 'avi', '3gp', 'm4v'};
    return exts.contains(_extensaoMidia(m));
  }

  static bool _ehMidiaAudio(MidiaPublicacao m) {
    const exts = {'mp3', 'wav', 'm4a', 'ogg', 'flac', 'aac'};
    return exts.contains(_extensaoMidia(m));
  }

  static bool _ehMidiaDocumento(MidiaPublicacao m) {
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
    return exts.contains(_extensaoMidia(m));
  }

  static bool _publicacaoPertenceAoFeed(
    PublicacaoSocial p,
    TipoFeedSocial feed,
  ) {
    switch (feed) {
      case TipoFeedSocial.fotos:
        if (p.tipo != TipoFeedSocial.fotos) return false;
        if (p.midias.isEmpty) return true;
        return p.midias.any(_ehMidiaImagem) &&
            !p.midias.every(_ehMidiaDocumento);
      case TipoFeedSocial.videos:
        if (p.tipo != TipoFeedSocial.videos) return false;
        if (p.midias.isEmpty) return true;
        return p.midias.any(_ehMidiaVideo);
      case TipoFeedSocial.musicas:
        if (p.tipo != TipoFeedSocial.musicas) return false;
        if (p.midias.isEmpty) return true;
        return p.midias.any(_ehMidiaAudio);
      case TipoFeedSocial.documentos:
        if (p.tipo == TipoFeedSocial.livros) return false;
        if (p.tipo == TipoFeedSocial.documentos) {
          return p.midias.isEmpty || p.midias.any(_ehMidiaDocumento);
        }
        return p.midias.isNotEmpty && p.midias.every(_ehMidiaDocumento);
      case TipoFeedSocial.livros:
        if (p.tipo != TipoFeedSocial.livros) return false;
        return p.midias.isEmpty || p.midias.any(_ehMidiaDocumento);
      case TipoFeedSocial.escritos:
        return p.tipo == TipoFeedSocial.escritos && p.midias.isEmpty;
      default:
        return true;
    }
  }

  static Future<List<PublicacaoSocial>> listarFeedDoUsuario({
    required String cpf,
    required TipoFeedSocial tipo,
    int limit = 60,
    int offset = 0,
  }) async {
    var lista = await TimelineRepositorioSqlite.listarPublicacoesDoUsuario(
      cpf: cpf,
      tipo: tipo == TipoFeedSocial.documentos ? null : tipo,
      limit: tipo == TipoFeedSocial.documentos ? (limit * 3) : limit,
      offset: offset,
    );
    lista = lista.where((p) => _publicacaoPertenceAoFeed(p, tipo)).toList();
    if (tipo == TipoFeedSocial.republicacoes && lista.isNotEmpty) {
      final originaisIds = lista
          .map((p) => p.publicacaoOriginalId)
          .where((id) => id.isNotEmpty)
          .toList();
      if (originaisIds.isNotEmpty) {
        final mapaAtivas =
            await TimelineRepositorioSqlite.buscarPublicacoesPorIds(
          originaisIds,
        );
        lista = lista
            .where(
              (p) =>
                  p.publicacaoOriginalId.isEmpty ||
                  mapaAtivas.containsKey(p.publicacaoOriginalId),
            )
            .toList();
      }
    }
    lista.sort((a, b) {
      if (a.fixada != b.fixada) return a.fixada ? -1 : 1;
      if (a.ordemManual != b.ordemManual) {
        if (a.ordemManual == 0) return -1;
        if (b.ordemManual == 0) return 1;
        return a.ordemManual.compareTo(b.ordemManual);
      }
      return b.criadaEm.compareTo(a.criadaEm);
    });
    return lista;
  }

  static Future<PublicacaoSocial> alternarFixarPublicacao(
    PublicacaoSocial pub, {
    VoidCallback? onNotificar,
  }) async {
    final atualizada = pub.copyWith(
      fixada: !pub.fixada,
      atualizadaEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarPublicacao(atualizada);
    onNotificar?.call();
    TimelineSyncService.despacharEventoRede(
      'timeline_publicacao',
      {'publicacao': atualizada.toJson()},
    );
    return atualizada;
  }

  static Future<void> reordenarPublicacaoNaLista({
    required List<PublicacaoSocial> listaAtual,
    required int indiceAtual,
    required int novoIndice,
    VoidCallback? onNotificar,
  }) async {
    if (indiceAtual < 0 ||
        indiceAtual >= listaAtual.length ||
        novoIndice < 0 ||
        novoIndice >= listaAtual.length ||
        indiceAtual == novoIndice) {
      return;
    }
    final reordenada = List<PublicacaoSocial>.from(listaAtual);
    final movida = reordenada.removeAt(indiceAtual);
    reordenada.insert(novoIndice, movida);

    final agora = DateTime.now();
    for (int i = 0; i < reordenada.length; i++) {
      final p = reordenada[i];
      final novaOrdem = i + 1;
      if (p.ordemManual != novaOrdem) {
        final atualizada = p.copyWith(
          ordemManual: novaOrdem,
          atualizadaEm: agora,
        );
        await TimelineRepositorioSqlite.salvarPublicacao(atualizada);
        TimelineSyncService.despacharEventoRede(
          'timeline_publicacao',
          {'publicacao': atualizada.toJson()},
        );
      }
    }
    onNotificar?.call();
  }

  static Future<int> contarPublicacoesDoUsuario(String cpf) =>
      TimelineRepositorioSqlite.contarPublicacoesDoUsuario(cpf);

  static Future<List<PublicacaoSocial>> listarTodosPostsContabilizados(
    String cpf,
  ) async {
    final todas = await TimelineRepositorioSqlite.listarPublicacoesDoUsuario(
      cpf: cpf,
      tipo: null,
      limit: 300,
      offset: 0,
    );
    return todas
        .where((p) => p.tipo != TipoFeedSocial.republicacoes)
        .toList();
  }

  static Future<FeedPersonalizado> adicionarFeedPersonalizado({
    required String donoCpf,
    required String titulo,
    required OrigemFeedExterno origem,
    String urlOuIdentificador = '',
    VoidCallback? onNotificar,
  }) async {
    final feed = FeedPersonalizado(
      id: 'feed_${gerarIdUnico()}',
      donoCpf: TimelineRepositorioSqlite.normalizarCpf(donoCpf),
      titulo: titulo.trim(),
      origem: origem,
      urlOuIdentificador: urlOuIdentificador.trim(),
      criadoEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarFeedPersonalizado(feed);
    onNotificar?.call();
    return feed;
  }

  static Future<List<FeedPersonalizado>> listarFeedsPersonalizados(
    String cpf,
  ) =>
      TimelineRepositorioSqlite.listarFeedsPersonalizados(cpf);

  static Future<List<TipoFeedSocial>> obterTimelinesVisiveis(String cpf) async {
    final salvo = await TimelineRepositorioSqlite.carregarTimelinesVisiveis(cpf);
    if (salvo == null) return List<TipoFeedSocial>.from(timelinesPadrao);
    return salvo
        .map(
          (nome) => TipoFeedSocial.values.firstWhere(
            (e) => e.name == nome,
            orElse: () => TipoFeedSocial.fotos,
          ),
        )
        .toSet()
        .toList();
  }

  static Future<void> ativarTimelineAutomaticamente(
    String cpf,
    TipoFeedSocial tipo, {
    VoidCallback? onNotificar,
  }) async {
    final salvo = await TimelineRepositorioSqlite.carregarTimelinesVisiveis(cpf);
    final lista = salvo != null
        ? await obterTimelinesVisiveis(cpf)
        : List<TipoFeedSocial>.from(timelinesPadrao);
    if (!lista.contains(tipo)) {
      lista.add(tipo);
      await salvarTimelinesVisiveis(cpf, lista, onNotificar: onNotificar);
    }
  }

  static Future<void> salvarTimelinesVisiveis(
    String cpf,
    List<TipoFeedSocial> tipos, {
    VoidCallback? onNotificar,
  }) async {
    final nomes = tipos.map((e) => e.name).toSet().toList();
    await TimelineRepositorioSqlite.salvarTimelinesVisiveis(cpf, nomes);
    onNotificar?.call();
    TimelineSyncService.despacharEventoRede('timeline_config', {
      'cpf': TimelineRepositorioSqlite.normalizarCpf(cpf),
      'tipos': nomes,
    });
  }
}
