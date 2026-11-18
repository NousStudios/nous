import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nous/src/core/services/gerador_id.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
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
    final excluida = pub.copyWith(
      excluida: true,
      atualizadaEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarPublicacao(excluida);
    notificarAlteracao();
    TimelineSyncService.despacharEventoRede(
      'timeline_publicacao',
      {'publicacao': excluida.toJson()},
    );
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
  }) =>
      TimelineRepositorioSqlite.listarPublicacoesDoUsuario(
        cpf: cpf,
        tipo: tipo,
        limit: limit,
        offset: offset,
      );

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
    return comentario;
  }

  static Future<List<ComentarioSocial>> listarComentarios(String publicacaoId) =>
      TimelineRepositorioSqlite.listarComentariosDaPublicacao(publicacaoId);

  static Future<ComentarioSocial> alternarFixarComentario(
    ComentarioSocial comentario,
  ) async {
    final atualizado = comentario.copyWith(fixado: !comentario.fixado);
    await TimelineRepositorioSqlite.salvarComentario(atualizado);
    notificarAlteracao();
    TimelineSyncService.despacharEventoRede(
      'timeline_comentario',
      {'comentario': atualizado.toJson()},
    );
    return atualizado;
  }

  static Future<void> excluirComentario(ComentarioSocial comentario) async {
    final excluido = comentario.copyWith(excluido: true);
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
    final itensSalvos =
        await TimelineRepositorioSqlite.listarItensSalvosDoUsuario(cpf);
    final denuncias =
        await TimelineRepositorioSqlite.listarDenunciasEnvolvendoUsuario(cpf);

    final itens = <RegistroInteracaoUsuario>[
      ...reacoes.map(
        (r) => RegistroInteracaoUsuario(
          id: r.id,
          tipoAcao: r.tipo.name,
          publicacaoId: r.publicacaoId,
          resumo: r.tipo == TipoReacaoSocial.like
              ? 'Deu Like em uma publicação'
              : 'Deu Deslike em uma publicação',
          dataHora: r.criadaEm,
        ),
      ),
      ...comentarios.map(
        (c) => RegistroInteracaoUsuario(
          id: c.id,
          tipoAcao: 'comentario',
          publicacaoId: c.publicacaoId,
          resumo: c.respostaDeId.isNotEmpty
              ? 'Respondeu em um comentário: "${c.texto}"'
              : 'Comentou: "${c.texto}"',
          dataHora: c.criadaEm,
        ),
      ),
      ...reposts.map(
        (p) => RegistroInteracaoUsuario(
          id: p.id,
          tipoAcao: 'republicacao',
          publicacaoId: p.publicacaoOriginalId.isNotEmpty
              ? p.publicacaoOriginalId
              : p.id,
          resumo: p.texto.isNotEmpty
              ? 'Republicou: "${p.texto}"'
              : 'Republicou uma mídia no perfil',
          dataHora: p.criadaEm,
        ),
      ),
      ...itensSalvos.map(
        (s) => RegistroInteracaoUsuario(
          id: s.id,
          tipoAcao: 'salvo',
          publicacaoId: s.publicacaoId,
          resumo: 'Salvou uma publicação na coleção',
          dataHora: s.salvoEm,
        ),
      ),
      ...denuncias.map(
        (d) => RegistroInteracaoUsuario(
          id: d.id,
          tipoAcao: 'denuncia',
          publicacaoId: d.publicacaoId,
          resumo: 'Registro de denúncia: ${d.motivo}',
          dataHora: d.criadaEm,
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
    List<String> apenasAutoresCpfs = const [],
  }) async {
    final todas = await TimelineRepositorioSqlite.listarPublicacoesDescoberta(
      tags: tags,
    );
    if (apenasAutoresCpfs.isEmpty) return todas;
    final norm =
        apenasAutoresCpfs.map(TimelineRepositorioSqlite.normalizarCpf).toSet();
    return todas
        .where(
          (p) => norm.contains(
            TimelineRepositorioSqlite.normalizarCpf(p.autorCpf),
          ),
        )
        .toList();
  }

  // --- Rede Local Wi-Fi (4 Elos + Delta Sync) ---

  static Future<Map<String, dynamic>> exportarSnapshotSocial({
    DateTime? desde,
  }) =>
      TimelineSyncService.exportarSnapshotSocial(desde: desde);

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
