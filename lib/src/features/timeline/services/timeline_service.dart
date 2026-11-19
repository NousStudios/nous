import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nous/src/core/services/gerador_id.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/notificacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/models/salvos_denuncia_social.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_midia_service.dart';
import 'package:nous/src/features/timeline/services/timeline_repositorio_sqlite.dart';
import 'package:nous/src/features/timeline/services/timeline_stories_service.dart';
import 'package:nous/src/features/timeline/services/timeline_sync_service.dart';

/// Fachada principal da rede social Nous (Timeline, Feeds, Reações, Stories e Sincronização Wi-Fi).
/// Delega mídia para [TimelineMidiaService], stories para [TimelineStoriesService]
/// e sincronização em rede para [TimelineSyncService].
class TimelineService {
  TimelineService._();

  static final ValueNotifier<int> alteracoesTimelineNotifier =
      ValueNotifier<int>(0);

  static void notificarAlteracao() {
    alteracoesTimelineNotifier.value++;
  }

  // --- Mídia e Cache ---

  static Future<MidiaPublicacao?> importarMidiaLocal(
    String caminhoOrigem, {
    String nomeArquivo = '',
  }) =>
      TimelineMidiaService.importarMidiaLocal(
        caminhoOrigem,
        nomeArquivo: nomeArquivo,
      );

  static String? resolverCaminhoMidiaSync(String caminho) =>
      TimelineMidiaService.resolverCaminhoMidiaSync(caminho);

  static Future<String?> resolverCaminhoMidia(String caminho) =>
      TimelineMidiaService.resolverCaminhoMidia(caminho);

  static Future<String?> baixarMidia(MidiaPublicacao midia) =>
      TimelineMidiaService.baixarMidia(midia);

  static Future<int> limparMidiasStoriesExpiradosDeTerceiros(String meuCpf) =>
      TimelineMidiaService.limparMidiasStoriesExpiradosDeTerceiros(meuCpf);

  // --- Publicações ---

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
  }) async {
    final agora = DateTime.now();
    final textoLimpo = texto.trim();
    final pub = PublicacaoSocial(
      id: 'pub_${gerarIdUnico()}',
      autorCpf: TimelineRepositorioSqlite.normalizarCpf(autorCpf),
      autorNome: autorNome,
      autorFoto: autorFoto,
      coautoresCpfs: coautoresCpfs
          .map(TimelineRepositorioSqlite.normalizarCpf)
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList(),
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
      criadaEm: agora,
      atualizadaEm: agora,
    );

    await TimelineRepositorioSqlite.salvarPublicacao(pub);
    await ativarTimelineAutomaticamente(autorCpf, tipo);
    notificarAlteracao();
    unawaited(_processarMencoesTexto(
      texto: textoLimpo,
      autorCpf: autorCpf,
      autorNome: autorNome,
      autorFoto: autorFoto,
      publicacaoId: pub.id,
    ));

    unawaited(() async {
      try {
        final midiasSinc =
            await TimelineMidiaService.sincronizarMidiasParaServidor(midias);
        final pubFinal = pub.copyWith(midias: midiasSinc);
        if (midiasSinc != midias) {
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

  static Future<void> excluirPublicacao(PublicacaoSocial pub) async {
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
    notificarAlteracao();
    TimelineSyncService.despacharEventoRede(
      'timeline_publicacao',
      {'publicacao': excluida.toJson()},
    );
  }

  static Future<void> arquivarPublicacao(
    PublicacaoSocial pub, {
    required bool arquivar,
  }) async {
    final atualizada = pub.copyWith(
      arquivada: arquivar,
      fixada: arquivar ? false : pub.fixada,
      atualizadaEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarPublicacao(atualizada);
    notificarAlteracao();
    TimelineSyncService.despacharEventoRede(
      'timeline_publicacao',
      {'publicacao': atualizada.toJson()},
    );
  }

  static Future<void> restaurarPublicacaoExcluida(PublicacaoSocial pub) async {
    final restaurada = pub.copyWith(
      excluida: false,
      arquivada: false,
      tags: PublicacaoSocial.extrairTags(pub.texto),
      atualizadaEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarPublicacao(restaurada);
    notificarAlteracao();
    TimelineSyncService.despacharEventoRede(
      'timeline_publicacao',
      {'publicacao': restaurada.toJson()},
    );
  }

  static Future<void> registrarVisualizacaoPublicacao(
    PublicacaoSocial pub, {
    required String origem,
    int segundosVisualizados = 4,
  }) async {
    final origens = Map<String, int>.from(pub.visualizacoesPorOrigem);
    origens[origem] = (origens[origem] ?? 0) + 1;
    final total = pub.visualizacoes + 1;
    final mediaAnterior = pub.tempoMedioVisualizacaoSegundos;
    final novaMedia = total <= 1
        ? segundosVisualizados
        : ((mediaAnterior * (total - 1) + segundosVisualizados) / total)
            .round();
    final atualizada = pub.copyWith(
      visualizacoes: total,
      visualizacoesPorOrigem: origens,
      tempoMedioVisualizacaoSegundos: novaMedia,
    );
    await TimelineRepositorioSqlite.salvarPublicacao(atualizada);
    notificarAlteracao();
  }

  static Future<PublicacaoSocial> editarPublicacao(
    PublicacaoSocial pub, {
    required String novoTexto,
    bool? permitirDownload,
  }) async {
    final textoLimpo = novoTexto.trim();
    final atualizada = pub.copyWith(
      texto: textoLimpo,
      tags: PublicacaoSocial.extrairTags(textoLimpo),
      permitirDownload: permitirDownload ?? pub.permitirDownload,
      atualizadaEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarPublicacao(atualizada);
    notificarAlteracao();
    TimelineSyncService.despacharEventoRede(
      'timeline_publicacao',
      {'publicacao': atualizada.toJson()},
    );
    return atualizada;
  }

  static Future<List<PublicacaoSocial>> listarFeedDoUsuario({
    required String cpf,
    required TipoFeedSocial tipo,
    int limit = 60,
    int offset = 0,
  }) async {
    var lista = await TimelineRepositorioSqlite.listarPublicacoesDoUsuario(
      cpf: cpf,
      tipo: tipo,
      limit: limit,
      offset: offset,
    );
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
        if (a.ordemManual == 0) return 1;
        if (b.ordemManual == 0) return -1;
        return a.ordemManual.compareTo(b.ordemManual);
      }
      return b.criadaEm.compareTo(a.criadaEm);
    });
    return lista;
  }

  static Future<PublicacaoSocial> alternarFixarPublicacao(
    PublicacaoSocial pub,
  ) async {
    final atualizada = pub.copyWith(
      fixada: !pub.fixada,
      atualizadaEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarPublicacao(atualizada);
    notificarAlteracao();
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
    notificarAlteracao();
  }

  static Future<int> contarPublicacoesDoUsuario(String cpf) =>
      TimelineRepositorioSqlite.contarPublicacoesDoUsuario(cpf);

  // --- Reações, Comentários e Republicações ---

  static Future<void> alternarReacao({
    required String publicacaoId,
    required String usuarioCpf,
    required String usuarioNome,
    String usuarioFoto = '',
    required TipoReacaoSocial tipo,
  }) async {
    final cpfNorm = TimelineRepositorioSqlite.normalizarCpf(usuarioCpf);
    if (cpfNorm.isEmpty) return;

    final atuais =
        await TimelineRepositorioSqlite.listarReacoesDaPublicacao(publicacaoId);
    final existente = atuais
        .where(
          (r) => TimelineRepositorioSqlite.normalizarCpf(r.usuarioCpf) == cpfNorm,
        )
        .firstOrNull;

    if (existente != null && existente.tipo == tipo) {
      await TimelineRepositorioSqlite.removerReacao(
        publicacaoId: publicacaoId,
        usuarioCpf: cpfNorm,
      );
      notificarAlteracao();
      TimelineSyncService.despacharEventoRede('timeline_reacao_removida', {
        'publicacaoId': publicacaoId,
        'usuarioCpf': cpfNorm,
      });
      return;
    }

    final reacao = ReacaoSocial(
      id: 'reacao_${publicacaoId}_$cpfNorm',
      publicacaoId: publicacaoId,
      usuarioCpf: cpfNorm,
      usuarioNome: usuarioNome,
      usuarioFoto: usuarioFoto,
      tipo: tipo,
      criadaEm: DateTime.now(),
    );

    await TimelineRepositorioSqlite.salvarReacao(reacao);
    notificarAlteracao();
    TimelineSyncService.despacharEventoRede(
      'timeline_reacao',
      {'reacao': reacao.toJson()},
    );
    if (tipo == TipoReacaoSocial.like) {
      unawaited(() async {
        final pub =
            await TimelineRepositorioSqlite.buscarPublicacaoPorId(publicacaoId);
        if (pub != null) {
          await emitirNotificacaoSocial(
            destinatarioCpf: pub.autorCpf,
            autorCpf: cpfNorm,
            autorNome: usuarioNome,
            autorFoto: usuarioFoto,
            tipo: TipoNotificacaoSocial.curtida,
            publicacaoId: publicacaoId,
            resumo: '$usuarioNome curtiu sua publicação.',
          );
        }
      }());
    }
  }

  static Future<List<ReacaoSocial>> listarReacoes(String publicacaoId) =>
      TimelineRepositorioSqlite.listarReacoesDaPublicacao(publicacaoId);

  static Future<ComentarioSocial> adicionarComentario({
    required String publicacaoId,
    required String autorCpf,
    required String autorNome,
    String autorFoto = '',
    required String texto,
    String respostaDeId = '',
  }) async {
    final comentario = ComentarioSocial(
      id: 'com_${gerarIdUnico()}',
      publicacaoId: publicacaoId,
      autorCpf: TimelineRepositorioSqlite.normalizarCpf(autorCpf),
      autorNome: autorNome,
      autorFoto: autorFoto,
      texto: texto.trim(),
      respostaDeId: respostaDeId,
      criadaEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarComentario(comentario);
    notificarAlteracao();
    TimelineSyncService.despacharEventoRede(
      'timeline_comentario',
      {'comentario': comentario.toJson()},
    );
    unawaited(() async {
      final pub =
          await TimelineRepositorioSqlite.buscarPublicacaoPorId(publicacaoId);
      if (pub != null) {
        await emitirNotificacaoSocial(
          destinatarioCpf: pub.autorCpf,
          autorCpf: autorCpf,
          autorNome: autorNome,
          autorFoto: autorFoto,
          tipo: TipoNotificacaoSocial.comentario,
          publicacaoId: publicacaoId,
          resumo: '$autorNome comentou: "${comentario.texto}"',
        );
      }
      await _processarMencoesTexto(
        texto: comentario.texto,
        autorCpf: autorCpf,
        autorNome: autorNome,
        autorFoto: autorFoto,
        publicacaoId: publicacaoId,
      );
    }());
    return comentario;
  }

  static Future<void> emitirNotificacaoSocial({
    required String destinatarioCpf,
    required String autorCpf,
    required String autorNome,
    String autorFoto = '',
    required TipoNotificacaoSocial tipo,
    String publicacaoId = '',
    required String resumo,
  }) async {
    final dest = TimelineRepositorioSqlite.normalizarCpf(destinatarioCpf);
    final autor = TimelineRepositorioSqlite.normalizarCpf(autorCpf);
    if (dest.isEmpty || autor.isEmpty || dest == autor) return;
    final notif = NotificacaoSocial(
      id: 'nsoc_${gerarIdUnico()}',
      destinatarioCpf: dest,
      autorCpf: autor,
      autorNome: autorNome,
      autorFoto: autorFoto,
      tipo: tipo,
      publicacaoId: publicacaoId,
      resumo: resumo,
      criadaEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarNotificacaoSocial(notif);
    TimelineSyncService.despacharEventoRede(
      'timeline_notificacao',
      {'notificacao': notif.toJson(), 'usuarioCpf': autor},
    );
  }

  static Future<void> _processarMencoesTexto({
    required String texto,
    required String autorCpf,
    required String autorNome,
    required String autorFoto,
    required String publicacaoId,
  }) async {
    final mencoes = PublicacaoSocial.extrairMencoes(texto);
    if (mencoes.isEmpty) return;
    final contas = await ContasNousService.carregarTodas();
    for (final handle in mencoes) {
      final alvo = contas.where((u) {
        final un = u.nomeDeUsuario.replaceAll('@', '').trim().toLowerCase();
        return un == handle;
      }).firstOrNull;
      if (alvo != null) {
        await emitirNotificacaoSocial(
          destinatarioCpf: alvo.cpf,
          autorCpf: autorCpf,
          autorNome: autorNome,
          autorFoto: autorFoto,
          tipo: TipoNotificacaoSocial.mencao,
          publicacaoId: publicacaoId,
          resumo: '$autorNome mencionou você em uma publicação.',
        );
      }
    }
  }

  static Future<List<ComentarioSocial>> listarComentarios(String publicacaoId) =>
      TimelineRepositorioSqlite.listarComentariosDaPublicacao(publicacaoId);

  static Future<ComentarioSocial> alternarFixarComentario(
    ComentarioSocial comentario,
  ) async {
    final atualizado = comentario.copyWith(
      fixado: !comentario.fixado,
      atualizadaEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarComentario(atualizado);
    notificarAlteracao();
    TimelineSyncService.despacharEventoRede(
      'timeline_comentario',
      {'comentario': atualizado.toJson()},
    );
    return atualizado;
  }

  static Future<void> excluirComentario(ComentarioSocial comentario) async {
    final excluido = comentario.copyWith(
      excluido: true,
      atualizadaEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarComentario(excluido);
    notificarAlteracao();
    TimelineSyncService.despacharEventoRede(
      'timeline_comentario',
      {'comentario': excluido.toJson()},
    );
  }

  static Future<PublicacaoSocial> republicar({
    required PublicacaoSocial original,
    required String meuCpf,
    required String meuNome,
    String minhaFoto = '',
  }) async {
    final cpfNorm = TimelineRepositorioSqlite.normalizarCpf(meuCpf);
    final repostId = 'repost_${original.id}_$cpfNorm';
    final agora = DateTime.now();

    final repost = original.copyWith(
      id: repostId,
      autorCpf: cpfNorm,
      autorNome: meuNome,
      autorFoto: minhaFoto,
      coautoresCpfs: const [],
      tipo: TipoFeedSocial.republicacoes,
      publicacaoOriginalId: original.id,
      criadaEm: agora,
      atualizadaEm: agora,
      excluida: false,
    );

    await TimelineRepositorioSqlite.salvarPublicacao(repost);
    notificarAlteracao();
    TimelineSyncService.despacharEventoRede(
      'timeline_publicacao',
      {'publicacao': repost.toJson()},
    );
    return repost;
  }

  static Future<void> enviarPublicacaoNoChat({
    required PublicacaoSocial pub,
    required String conversaId,
    required String meuCpf,
    required String meuNome,
    String minhaFoto = '',
    String destinatarioId = '',
  }) async {
    final resumoTexto = pub.texto.isNotEmpty
        ? pub.texto
        : 'Publicação (${pub.tipo.name}) de ${pub.autorNome}';
    final msg = MensagemChat(
      id: 'msg_${gerarIdUnico()}',
      conversaId: conversaId,
      remetenteId: meuCpf,
      remetenteNome: meuNome,
      remetenteFoto: minhaFoto,
      destinatarioId: destinatarioId,
      texto: '📌 Publicação compartilhada de ${pub.autorNome}:\n$resumoTexto',
      dataHora: DateTime.now(),
      enviadaPorMim: true,
      lida: true,
      tipo: 'texto',
    );
    await ChatService.enviarMensagemInstantanea(msg);
  }

  // --- Interações na Rede ---

  static String _rotuloFeed(TipoFeedSocial tipo) {
    switch (tipo) {
      case TipoFeedSocial.fotos:
        return 'Fotos';
      case TipoFeedSocial.videos:
        return 'Vídeos';
      case TipoFeedSocial.documentos:
        return 'Documentos';
      case TipoFeedSocial.musicas:
        return 'Músicas';
      case TipoFeedSocial.escritos:
        return 'Escritos';
      case TipoFeedSocial.republicacoes:
        return 'Republicações';
      case TipoFeedSocial.interacoes:
        return 'Interações';
      case TipoFeedSocial.salvos:
        return 'Salvos';
      case TipoFeedSocial.likes:
        return 'Likes';
      case TipoFeedSocial.deslikes:
        return 'Deslikes';
      case TipoFeedSocial.denuncias:
        return 'Denúncias';
    }
  }

  static Future<List<RegistroInteracaoUsuario>> listarInteracoesDoUsuario(
    String cpf,
  ) async {
    final reacoes = await TimelineRepositorioSqlite.listarReacoesDoUsuario(cpf);
    final comentarios =
        await TimelineRepositorioSqlite.listarComentariosDoUsuario(cpf);
    final reposts = await TimelineRepositorioSqlite.listarPublicacoesDoUsuario(
      cpf: cpf,
      tipo: TipoFeedSocial.republicacoes,
    );
    final itensSalvosBrutos =
        await TimelineRepositorioSqlite.listarItensSalvosDoUsuario(cpf);
    final listasUsuario =
        await TimelineRepositorioSqlite.listarListasSalvosDoUsuario(cpf);
    final listasPublicasIds = listasUsuario
        .where((l) => l.visibilidade == VisibilidadeListaSalvos.publicaFeed)
        .map((l) => l.id)
        .toSet();
    final itensSalvos = itensSalvosBrutos
        .where((s) => !s.excluida && listasPublicasIds.contains(s.listaId))
        .toList();

    // Resolve em lote as publicações alvo para exibir autor, feed e trecho (sem N+1)
    final idsUnicos = <String>{
      ...reacoes.map((r) => r.publicacaoId),
      ...comentarios.map((c) => c.publicacaoId),
      ...reposts.map(
        (p) => p.publicacaoOriginalId.isNotEmpty ? p.publicacaoOriginalId : p.id,
      ),
      ...itensSalvos.map((s) => s.publicacaoId),
    }..removeWhere((id) => id.trim().isEmpty);

    final mapaPubs = await TimelineRepositorioSqlite.buscarPublicacoesPorIds(
      idsUnicos.toList(),
    );

    RegistroInteracaoUsuario criar({
      required String id,
      required String tipoAcao,
      required String pubId,
      required String resumo,
      required DateTime dataHora,
      String alvoCpfFallback = '',
      String alvoNomeFallback = '',
    }) {
      final pub = mapaPubs[pubId];
      return RegistroInteracaoUsuario(
        id: id,
        tipoAcao: tipoAcao,
        publicacaoId: pubId,
        resumo: resumo,
        dataHora: dataHora,
        alvoCpf: pub?.autorCpf ?? alvoCpfFallback,
        alvoNome: pub?.autorNome.isNotEmpty == true
            ? pub!.autorNome
            : alvoNomeFallback,
        alvoFoto: pub?.autorFoto ?? '',
        tipoFeed: pub != null ? _rotuloFeed(pub.tipo) : '',
        trechoPost: pub?.texto ?? '',
        publicacao: pub,
      );
    }

    final itens = <RegistroInteracaoUsuario>[
      ...reacoes
          .where((r) => mapaPubs.containsKey(r.publicacaoId))
          .map(
            (r) => criar(
              id: r.id,
              tipoAcao: r.tipo.name,
              pubId: r.publicacaoId,
              resumo: r.tipo == TipoReacaoSocial.like
                  ? 'Deu Like na publicação'
                  : 'Deu Deslike na publicação',
              dataHora: r.criadaEm,
            ),
          ),
      ...comentarios
          .where((c) => mapaPubs.containsKey(c.publicacaoId))
          .map(
            (c) => criar(
              id: c.id,
              tipoAcao: 'comentario',
              pubId: c.publicacaoId,
              resumo: c.respostaDeId.isNotEmpty
                  ? 'Respondeu em um comentário: "${c.texto}"'
                  : 'Comentou: "${c.texto}"',
              dataHora: c.criadaEm,
            ),
          ),
      ...reposts
          .where((p) {
            final alvoId = p.publicacaoOriginalId.isNotEmpty
                ? p.publicacaoOriginalId
                : p.id;
            return mapaPubs.containsKey(alvoId);
          })
          .map(
            (p) => criar(
              id: p.id,
              tipoAcao: 'republicacao',
              pubId: p.publicacaoOriginalId.isNotEmpty
                  ? p.publicacaoOriginalId
                  : p.id,
              resumo: p.texto.isNotEmpty
                  ? 'Republicou: "${p.texto}"'
                  : 'Republicou uma mídia no perfil',
              dataHora: p.criadaEm,
            ),
          ),
      ...itensSalvos
          .where((s) => mapaPubs.containsKey(s.publicacaoId))
          .map(
            (s) => criar(
              id: s.id,
              tipoAcao: 'salvo',
              pubId: s.publicacaoId,
              resumo: 'Salvou a publicação na coleção pública',
              dataHora: s.salvoEm,
            ),
          ),
    ];

    itens.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return itens;
  }

  // --- Stories e Destaques ---

  static Future<StorySocial> criarStory({
    required String autorCpf,
    required String autorNome,
    String autorFoto = '',
    String tituloDestaque = '',
    String caminhoMidia = '',
    String tipoMidia = 'texto',
    String texto = '',
    bool ehDestaquePermanente = false,
    String perguntaEnquete = '',
    List<String> opcoesEnquete = const [],
  }) =>
      TimelineStoriesService.criarStory(
        autorCpf: autorCpf,
        autorNome: autorNome,
        autorFoto: autorFoto,
        tituloDestaque: tituloDestaque,
        caminhoMidia: caminhoMidia,
        tipoMidia: tipoMidia,
        texto: texto,
        ehDestaquePermanente: ehDestaquePermanente,
        perguntaEnquete: perguntaEnquete,
        opcoesEnquete: opcoesEnquete,
        onNotificar: notificarAlteracao,
      );

  static Future<StorySocial> votarEnqueteStory(
    StorySocial story,
    String cpfEleitor,
    int indiceOpcao,
  ) =>
      TimelineStoriesService.votarEnqueteStory(
        story,
        cpfEleitor,
        indiceOpcao,
        onNotificar: notificarAlteracao,
      );

  static Future<List<StorySocial>> listarStoriesAtivosDaRede() =>
      TimelineRepositorioSqlite.listarStoriesAtivosDaRede();

  static Future<void> excluirStory(StorySocial story) =>
      TimelineStoriesService.excluirStory(
        story,
        onNotificar: notificarAlteracao,
      );

  static Future<List<StorySocial>> listarStories(String cpf) =>
      TimelineRepositorioSqlite.listarStoriesDoUsuario(cpf);

  static Future<List<StorySocial>> listarTodosStoriesHistorico(String cpf) =>
      TimelineRepositorioSqlite.listarTodosStoriesDoUsuario(cpf);

  static Future<List<StorySocial>> listarStoriesAtivos24h(String cpf) =>
      TimelineStoriesService.listarStoriesAtivos24h(cpf);

  static Future<StorySocial> registrarVisualizacaoStory(
    StorySocial story,
    String cpfVisualizador,
  ) =>
      TimelineStoriesService.registrarVisualizacaoStory(
        story,
        cpfVisualizador,
        onNotificar: notificarAlteracao,
      );

  static Future<StorySocial> alternarDestaqueStory(
    StorySocial story, {
    String? tituloDestaque,
  }) =>
      TimelineStoriesService.alternarDestaqueStory(
        story,
        tituloDestaque: tituloDestaque,
        onNotificar: notificarAlteracao,
      );

  static Future<void> enviarRespostaStoryNoChat({
    required StorySocial story,
    required String meuCpf,
    required String meuNome,
    String minhaFoto = '',
    required String respostaTexto,
  }) =>
      TimelineStoriesService.enviarRespostaStoryNoChat(
        story: story,
        meuCpf: meuCpf,
        meuNome: meuNome,
        minhaFoto: minhaFoto,
        respostaTexto: respostaTexto,
      );

  // --- Feeds Personalizados / Externos (+) e Timelines Visíveis ---

  static Future<FeedPersonalizado> adicionarFeedPersonalizado({
    required String donoCpf,
    required String titulo,
    required OrigemFeedExterno origem,
    String urlOuIdentificador = '',
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
    notificarAlteracao();
    return feed;
  }

  static Future<List<FeedPersonalizado>> listarFeedsPersonalizados(
    String cpf,
  ) =>
      TimelineRepositorioSqlite.listarFeedsPersonalizados(cpf);

  static const List<TipoFeedSocial> timelinesPadrao = [
    TipoFeedSocial.fotos,
    TipoFeedSocial.videos,
    TipoFeedSocial.interacoes,
  ];

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
    TipoFeedSocial tipo,
  ) async {
    final salvo = await TimelineRepositorioSqlite.carregarTimelinesVisiveis(cpf);
    final lista = salvo != null
        ? await obterTimelinesVisiveis(cpf)
        : List<TipoFeedSocial>.from(timelinesPadrao);
    if (!lista.contains(tipo)) {
      lista.add(tipo);
      await salvarTimelinesVisiveis(cpf, lista);
    }
  }

  static Future<void> salvarTimelinesVisiveis(
    String cpf,
    List<TipoFeedSocial> tipos,
  ) async {
    final nomes = tipos.map((e) => e.name).toSet().toList();
    await TimelineRepositorioSqlite.salvarTimelinesVisiveis(cpf, nomes);
    notificarAlteracao();
    TimelineSyncService.despacharEventoRede('timeline_config', {
      'cpf': TimelineRepositorioSqlite.normalizarCpf(cpf),
      'tipos': nomes,
    });
  }

  // --- Conteúdos Salvos e Denúncias ---

  static Future<ListaSalvosSocial> obterOuCriarListaPadraoSalvos(
    String cpf,
  ) async {
    final cpfNorm = TimelineRepositorioSqlite.normalizarCpf(cpf);
    final listas =
        await TimelineRepositorioSqlite.listarListasSalvosDoUsuario(cpfNorm);
    final padrao = listas
        .where((l) => l.visibilidade == VisibilidadeListaSalvos.publicaFeed)
        .firstOrNull;
    if (padrao != null) return padrao;

    final nova = ListaSalvosSocial(
      id: 'lista_padrao_$cpfNorm',
      donoCpf: cpfNorm,
      nome: 'Conteúdos Salvos',
      visibilidade: VisibilidadeListaSalvos.publicaFeed,
      criadaEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarListaSalvos(nova);
    TimelineSyncService.despacharEventoRede(
      'timeline_lista_salvos',
      {'lista': nova.toJson()},
    );
    return nova;
  }

  static Future<ListaSalvosSocial> criarListaSalvos({
    required String donoCpf,
    required String nome,
    required VisibilidadeListaSalvos visibilidade,
    List<String> colaboradoresCpfs = const [],
  }) async {
    final lista = ListaSalvosSocial(
      id: 'lista_${gerarIdUnico()}',
      donoCpf: TimelineRepositorioSqlite.normalizarCpf(donoCpf),
      nome: nome.trim(),
      visibilidade: visibilidade,
      colaboradoresCpfs: colaboradoresCpfs
          .map(TimelineRepositorioSqlite.normalizarCpf)
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList(),
      criadaEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarListaSalvos(lista);
    notificarAlteracao();
    TimelineSyncService.despacharEventoRede(
      'timeline_lista_salvos',
      {'lista': lista.toJson()},
    );
    return lista;
  }

  static Future<List<ListaSalvosSocial>> listarListasSalvos(String cpf) =>
      TimelineRepositorioSqlite.listarListasSalvosDoUsuario(cpf);

  static Future<void> salvarPublicacaoEmLista({
    required String listaId,
    required String usuarioCpf,
    required String publicacaoId,
  }) async {
    final cpfNorm = TimelineRepositorioSqlite.normalizarCpf(usuarioCpf);
    final item = ItemSalvoSocial(
      id: 'salvo_${listaId}_$publicacaoId',
      listaId: listaId,
      usuarioCpf: cpfNorm,
      publicacaoId: publicacaoId,
      salvoEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarItemSalvo(item);
    notificarAlteracao();
    TimelineSyncService.despacharEventoRede(
      'timeline_item_salvo',
      {'item': item.toJson()},
    );
  }

  static Future<List<PublicacaoSocial>> listarPublicacoesSalvas({
    required String donoPerfilCpf,
    required String visualizadorCpf,
  }) async {
    final donoNorm = TimelineRepositorioSqlite.normalizarCpf(donoPerfilCpf);
    final visNorm = TimelineRepositorioSqlite.normalizarCpf(visualizadorCpf);
    final listas =
        await TimelineRepositorioSqlite.listarListasSalvosDoUsuario(donoNorm);
    final publicacoes = <PublicacaoSocial>[];
    final idsVistos = <String>{};

    for (final lista in listas) {
      final ehDono =
          TimelineRepositorioSqlite.normalizarCpf(lista.donoCpf) == visNorm;
      final ehColab = lista.colaboradoresCpfs
          .any((c) => TimelineRepositorioSqlite.normalizarCpf(c) == visNorm);
      final podeVer = lista.visibilidade == VisibilidadeListaSalvos.publicaFeed ||
          ehDono ||
          (lista.visibilidade == VisibilidadeListaSalvos.colaboradores &&
              ehColab);
      if (!podeVer) continue;

      final itens =
          await TimelineRepositorioSqlite.listarItensSalvosPorLista(lista.id);
      for (final item in itens) {
        if (idsVistos.contains(item.publicacaoId)) continue;
        final pub = await TimelineRepositorioSqlite.buscarPublicacaoPorId(
          item.publicacaoId,
        );
        if (pub != null && !pub.excluida) {
          idsVistos.add(pub.id);
          publicacoes.add(pub);
        }
      }
    }
    return publicacoes;
  }

  static Future<List<PublicacaoSocial>> listarPublicacoesPorReacao({
    required String cpf,
    required TipoReacaoSocial tipo,
  }) async {
    final reacoes = await TimelineRepositorioSqlite.listarReacoesDoUsuario(cpf);
    final filtradas = reacoes.where((r) => r.tipo == tipo);
    final pubs = <PublicacaoSocial>[];
    final vistos = <String>{};
    for (final r in filtradas) {
      if (vistos.contains(r.publicacaoId)) continue;
      final pub =
          await TimelineRepositorioSqlite.buscarPublicacaoPorId(r.publicacaoId);
      if (pub != null && !pub.excluida) {
        vistos.add(pub.id);
        pubs.add(pub);
      }
    }
    return pubs;
  }

  static Future<DenunciaSocial> registrarDenuncia({
    required String denuncianteCpf,
    required String denuncianteNome,
    required String alvoCpf,
    required String alvoNome,
    String publicacaoId = '',
    required String motivo,
  }) async {
    final denuncia = DenunciaSocial(
      id: 'den_${gerarIdUnico()}',
      denuncianteCpf: TimelineRepositorioSqlite.normalizarCpf(denuncianteCpf),
      denuncianteNome: denuncianteNome,
      alvoCpf: TimelineRepositorioSqlite.normalizarCpf(alvoCpf),
      alvoNome: alvoNome,
      publicacaoId: publicacaoId,
      motivo: motivo.trim(),
      criadaEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarDenuncia(denuncia);
    notificarAlteracao();
    TimelineSyncService.despacharEventoRede(
      'timeline_denuncia',
      {'denuncia': denuncia.toJson()},
    );
    return denuncia;
  }

  static Future<List<DenunciaSocial>> listarDenunciasDoUsuario(String cpf) =>
      TimelineRepositorioSqlite.listarDenunciasEnvolvendoUsuario(cpf);

  // --- Feed de Descoberta & #Tags ---

  static List<Map<String, dynamic>> get abasDescobertaPadrao => [
        {
          'id': 'desc_rede_local',
          'titulo': 'Rede Local',
          'tags': <String>[],
          'ehPadrao': true,
        },
        {
          'id': 'desc_memes',
          'titulo': 'Memes',
          'tags': <String>['meme', 'memes', 'humor'],
          'ehPadrao': true,
        },
        {
          'id': 'desc_noticias',
          'titulo': 'Notícias',
          'tags': <String>['noticia', 'noticias', 'novidade', 'novidades'],
          'ehPadrao': true,
        },
        {
          'id': 'desc_comercio',
          'titulo': 'Comércio',
          'tags': <String>['promocao', 'cardapio', 'loja', 'comercio'],
          'ehPadrao': true,
        },
      ];

  static Future<List<Map<String, dynamic>>> obterAbasDescoberta(
    String cpf,
  ) async {
    if (cpf.trim().isEmpty) return abasDescobertaPadrao;
    final salvas = await TimelineRepositorioSqlite.carregarAbasDescoberta(cpf);
    if (salvas == null || salvas.isEmpty) return abasDescobertaPadrao;
    return salvas;
  }

  static Future<void> salvarAbasDescoberta(
    String cpf,
    List<Map<String, dynamic>> abas,
  ) async {
    if (cpf.trim().isEmpty) return;
    await TimelineRepositorioSqlite.salvarAbasDescoberta(cpf, abas);
    notificarAlteracao();
  }

  static Future<List<PublicacaoSocial>> listarPublicacoesDescoberta({
    List<String> tags = const [],
    List<String>? apenasAutoresCpfs,
    int limit = 30,
    int offset = 0,
  }) =>
      TimelineRepositorioSqlite.listarPublicacoesDescoberta(
        tags: tags,
        apenasAutoresCpfs: apenasAutoresCpfs,
        limit: limit,
        offset: offset,
      );

  // --- Rede Local Wi-Fi (4 Elos + Delta Sync) ---

  static Future<Map<String, dynamic>> exportarSnapshotSocial({
    DateTime? desde,
    int offset = 0,
  }) =>
      TimelineSyncService.exportarSnapshotSocial(desde: desde, offset: offset);

  static Future<void> mesclarSnapshotSocial(Map<String, dynamic> snapshot) =>
      TimelineSyncService.mesclarSnapshotSocial(
        snapshot,
        aoConcluir: notificarAlteracao,
      );

  static Future<bool> sincronizarComServidorHttp({
    required String ip,
    required int porta,
  }) =>
      TimelineSyncService.sincronizarComServidorHttp(
        ip: ip,
        porta: porta,
        aoConcluir: notificarAlteracao,
      );

  static Future<void> processarEventoRemoto(Map<String, dynamic> dados) =>
      TimelineSyncService.processarEventoRemoto(
        dados,
        aoConcluir: notificarAlteracao,
      );
}
