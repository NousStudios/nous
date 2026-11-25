import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nous/src/core/services/gerador_id.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/helpers/timeline_publicacao_colaboracao_helper.dart';
import 'package:nous/src/features/timeline/services/helpers/timeline_publicacao_feed_helper.dart';
import 'package:nous/src/features/timeline/services/helpers/timeline_publicacao_midia_helper.dart';
import 'package:nous/src/features/timeline/services/timeline_interacoes_service.dart';
import 'package:nous/src/features/timeline/services/timeline_repositorio_sqlite.dart';
import 'package:nous/src/features/timeline/services/timeline_sync_service.dart';

/// Serviço especializado em publicações sociais: criação, edição, exclusão,
/// arquivamento, colaboração, fixação, reordenação, visualizações e feeds do usuário.
class TimelinePublicacoesService {
  TimelinePublicacoesService._();

  static final Set<String> _visualizadasSessao = {};

  static const List<TipoFeedSocial> timelinesPadrao =
      TimelinePublicacaoFeedHelper.timelinesPadrao;

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
        TimelinePublicacaoColaboracaoHelper.notificarConvitesColaboracao(
          convidadosCpfs: convidadosPendentes,
          autorCpf: autorCpf,
          autorNome: autorNome,
          autorFoto: autorFoto,
          publicacaoId: pub.id,
        ),
      );
    }

    TimelinePublicacaoMidiaHelper.agendarSincronizacaoMidiasECapa(
      publicacao: pub,
      midias: midias,
      capaCaminho: capaCaminho,
    );

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
    final coautores =
        TimelinePublicacaoColaboracaoHelper.resolverCoautoresEdicao(
      pub: pub,
      coautoresCpfs: coautoresCpfs,
    );

    final atualizada = pub.copyWith(
      texto: textoLimpo,
      tags: PublicacaoSocial.extrairTags(textoLimpo),
      permitirDownload: permitirDownload ?? pub.permitirDownload,
      coautoresCpfs: coautores.aceitos,
      coautoresPendentesCpfs: coautores.pendentes,
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
    if (coautores.novosConvidados.isNotEmpty) {
      unawaited(
        TimelinePublicacaoColaboracaoHelper.notificarConvitesColaboracao(
          convidadosCpfs: coautores.novosConvidados,
          autorCpf: pub.autorCpf,
          autorNome: pub.autorNome,
          autorFoto: pub.autorFoto,
          publicacaoId: pub.id,
        ),
      );
    }
    return atualizada;
  }

  static Future<PublicacaoSocial?> responderConviteColaboracao({
    required String publicacaoId,
    required String usuarioCpf,
    required bool aceitar,
    String? notificacaoId,
    VoidCallback? onNotificar,
  }) =>
      TimelinePublicacaoColaboracaoHelper.responderConviteColaboracao(
        publicacaoId: publicacaoId,
        usuarioCpf: usuarioCpf,
        aceitar: aceitar,
        notificacaoId: notificacaoId,
        onNotificar: onNotificar,
      );

  static Future<PublicacaoSocial> cancelarConviteColaboracao({
    required PublicacaoSocial publicacao,
    required String cpfAlvo,
    VoidCallback? onNotificar,
  }) =>
      TimelinePublicacaoColaboracaoHelper.cancelarConviteColaboracao(
        publicacao: publicacao,
        cpfAlvo: cpfAlvo,
        onNotificar: onNotificar,
      );

  static Future<void> reenviarConviteColaboracao({
    required PublicacaoSocial publicacao,
    required String cpfAlvo,
  }) =>
      TimelinePublicacaoColaboracaoHelper.reenviarConviteColaboracao(
        publicacao: publicacao,
        cpfAlvo: cpfAlvo,
      );

  static Future<List<PublicacaoSocial>> listarFeedDoUsuario({
    required String cpf,
    required TipoFeedSocial tipo,
    int limit = 60,
    int offset = 0,
  }) =>
      TimelinePublicacaoFeedHelper.listarFeedDoUsuario(
        cpf: cpf,
        tipo: tipo,
        limit: limit,
        offset: offset,
      );

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
  }) =>
      TimelinePublicacaoFeedHelper.reordenarPublicacaoNaLista(
        listaAtual: listaAtual,
        indiceAtual: indiceAtual,
        novoIndice: novoIndice,
        onNotificar: onNotificar,
      );

  static Future<int> contarPublicacoesDoUsuario(String cpf) =>
      TimelineRepositorioSqlite.contarPublicacoesDoUsuario(cpf);

  static Future<List<PublicacaoSocial>> listarTodosPostsContabilizados(
    String cpf,
  ) =>
      TimelinePublicacaoFeedHelper.listarTodosPostsContabilizados(cpf);

  static Future<FeedPersonalizado> adicionarFeedPersonalizado({
    required String donoCpf,
    required String titulo,
    required OrigemFeedExterno origem,
    String urlOuIdentificador = '',
    VoidCallback? onNotificar,
  }) =>
      TimelinePublicacaoFeedHelper.adicionarFeedPersonalizado(
        donoCpf: donoCpf,
        titulo: titulo,
        origem: origem,
        urlOuIdentificador: urlOuIdentificador,
        onNotificar: onNotificar,
      );

  static Future<List<FeedPersonalizado>> listarFeedsPersonalizados(
    String cpf,
  ) =>
      TimelineRepositorioSqlite.listarFeedsPersonalizados(cpf);

  static Future<List<TipoFeedSocial>> obterTimelinesVisiveis(String cpf) =>
      TimelinePublicacaoFeedHelper.obterTimelinesVisiveis(cpf);

  static Future<void> ativarTimelineAutomaticamente(
    String cpf,
    TipoFeedSocial tipo, {
    VoidCallback? onNotificar,
  }) =>
      TimelinePublicacaoFeedHelper.ativarTimelineAutomaticamente(
        cpf,
        tipo,
        onNotificar: onNotificar,
      );

  static Future<void> salvarTimelinesVisiveis(
    String cpf,
    List<TipoFeedSocial> tipos, {
    VoidCallback? onNotificar,
  }) =>
      TimelinePublicacaoFeedHelper.salvarTimelinesVisiveis(
        cpf,
        tipos,
        onNotificar: onNotificar,
      );
}
