import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/notificacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/models/salvos_denuncia_social.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_interacoes_service.dart';
import 'package:nous/src/features/timeline/services/timeline_midia_service.dart';
import 'package:nous/src/features/timeline/services/timeline_publicacoes_service.dart';
import 'package:nous/src/features/timeline/services/timeline_repositorio_sqlite.dart';
import 'package:nous/src/features/timeline/services/timeline_salvos_denuncias_service.dart';
import 'package:nous/src/features/timeline/services/timeline_stories_service.dart';
import 'package:nous/src/features/timeline/services/timeline_sync_service.dart';

/// Fachada principal da rede social Nous (Timeline, Feeds, Reações, Stories e Sincronização Wi-Fi).
/// Delega mídia para [TimelineMidiaService], publicações para [TimelinePublicacoesService],
/// interações para [TimelineInteracoesService], salvos/denúncias/descoberta para
/// [TimelineSalvosDenunciasService], stories para [TimelineStoriesService]
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
  }) => TimelineMidiaService.importarMidiaLocal(caminhoOrigem, nomeArquivo: nomeArquivo);

  static String? resolverCaminhoMidiaSync(String caminho) =>
      TimelineMidiaService.resolverCaminhoMidiaSync(caminho);

  static Future<String?> resolverCaminhoMidia(String caminho) =>
      TimelineMidiaService.resolverCaminhoMidia(caminho);

  static Future<Uint8List?> obterOuGerarMiniaturaPdf(String caminhoPdf) =>
      TimelineMidiaService.obterOuGerarMiniaturaPdf(caminhoPdf);

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
    String capaCaminho = '',
    String cifraLetra = '',
  }) => TimelinePublicacoesService.criarPublicacao(
        autorCpf: autorCpf, autorNome: autorNome, autorFoto: autorFoto,
        tipo: tipo, texto: texto, midias: midias,
        coautoresCpfs: coautoresCpfs, padraoExibicao: padraoExibicao,
        proporcaoCustom: proporcaoCustom, colunasMosaico: colunasMosaico,
        permitirDownload: permitirDownload, alinhamentoX: alinhamentoX,
        alinhamentoY: alinhamentoY, escalaZoom: escalaZoom,
        lojaIdTag: lojaIdTag, itemLojaIdTag: itemLojaIdTag,
        itemLojaNomeTag: itemLojaNomeTag, itemLojaPrecoTag: itemLojaPrecoTag,
        capaCaminho: capaCaminho, cifraLetra: cifraLetra,
        onNotificar: notificarAlteracao,
      );

  static Future<void> excluirPublicacao(PublicacaoSocial pub) =>
      TimelinePublicacoesService.excluirPublicacao(pub, onNotificar: notificarAlteracao);

  static Future<void> arquivarPublicacao(
    PublicacaoSocial pub, {
    required bool arquivar,
  }) => TimelinePublicacoesService.arquivarPublicacao(
        pub, arquivar: arquivar, onNotificar: notificarAlteracao,
      );

  static Future<void> restaurarPublicacaoExcluida(PublicacaoSocial pub) =>
      TimelinePublicacoesService.restaurarPublicacaoExcluida(pub, onNotificar: notificarAlteracao);

  static Future<void> registrarVisualizacaoPublicacao(
    PublicacaoSocial pub, {
    required String origem,
    String? visualizadorCpf,
    int segundosVisualizados = 4,
  }) => TimelinePublicacoesService.registrarVisualizacaoPublicacao(
        pub, origem: origem, visualizadorCpf: visualizadorCpf,
        segundosVisualizados: segundosVisualizados, onNotificar: notificarAlteracao,
      );

  static Future<void> registrarTempoVisualizacao(
    String publicacaoId,
    String? visualizadorCpf,
    int segundos,
  ) => TimelinePublicacoesService.registrarTempoVisualizacao(
        publicacaoId, visualizadorCpf, segundos, onNotificar: notificarAlteracao,
      );

  static Future<PublicacaoSocial> editarPublicacao(
    PublicacaoSocial pub, {
    required String novoTexto,
    bool? permitirDownload,
    List<String>? coautoresCpfs,
    List<MidiaPublicacao>? midias,
    PadraoExibicaoMidia? padraoExibicao,
    double? proporcaoCustom,
  }) => TimelinePublicacoesService.editarPublicacao(
        pub, novoTexto: novoTexto, permitirDownload: permitirDownload,
        coautoresCpfs: coautoresCpfs, midias: midias,
        padraoExibicao: padraoExibicao, proporcaoCustom: proporcaoCustom,
        onNotificar: notificarAlteracao,
      );

  static Future<PublicacaoSocial?> responderConviteColaboracao({
    required String publicacaoId,
    required String usuarioCpf,
    required bool aceitar,
    String? notificacaoId,
  }) => TimelinePublicacoesService.responderConviteColaboracao(
        publicacaoId: publicacaoId, usuarioCpf: usuarioCpf, aceitar: aceitar,
        notificacaoId: notificacaoId, onNotificar: notificarAlteracao,
      );

  static Future<PublicacaoSocial> cancelarConviteColaboracao({
    required PublicacaoSocial publicacao,
    required String cpfAlvo,
  }) => TimelinePublicacoesService.cancelarConviteColaboracao(
        publicacao: publicacao, cpfAlvo: cpfAlvo, onNotificar: notificarAlteracao,
      );

  static Future<void> reenviarConviteColaboracao({
    required PublicacaoSocial publicacao,
    required String cpfAlvo,
  }) => TimelinePublicacoesService.reenviarConviteColaboracao(
        publicacao: publicacao, cpfAlvo: cpfAlvo,
      );

  static Future<List<PublicacaoSocial>> listarFeedDoUsuario({
    required String cpf,
    required TipoFeedSocial tipo,
    int limit = 60,
    int offset = 0,
  }) => TimelinePublicacoesService.listarFeedDoUsuario(
        cpf: cpf, tipo: tipo, limit: limit, offset: offset,
      );

  static Future<PublicacaoSocial> alternarFixarPublicacao(PublicacaoSocial pub) =>
      TimelinePublicacoesService.alternarFixarPublicacao(pub, onNotificar: notificarAlteracao);

  static Future<void> reordenarPublicacaoNaLista({
    required List<PublicacaoSocial> listaAtual,
    required int indiceAtual,
    required int novoIndice,
  }) => TimelinePublicacoesService.reordenarPublicacaoNaLista(
        listaAtual: listaAtual, indiceAtual: indiceAtual, novoIndice: novoIndice,
        onNotificar: notificarAlteracao,
      );

  static Future<int> contarPublicacoesDoUsuario(String cpf) =>
      TimelinePublicacoesService.contarPublicacoesDoUsuario(cpf);

  static Future<List<PublicacaoSocial>> listarTodosPostsContabilizados(String cpf) =>
      TimelinePublicacoesService.listarTodosPostsContabilizados(cpf);

  // --- Reações, Comentários e Republicações ---

  static Future<void> alternarReacao({
    required String publicacaoId,
    required String usuarioCpf,
    required String usuarioNome,
    String usuarioFoto = '',
    required TipoReacaoSocial tipo,
  }) => TimelineInteracoesService.alternarReacao(
        publicacaoId: publicacaoId, usuarioCpf: usuarioCpf, usuarioNome: usuarioNome,
        usuarioFoto: usuarioFoto, tipo: tipo, onNotificar: notificarAlteracao,
      );

  static Future<List<ReacaoSocial>> listarReacoes(String publicacaoId) =>
      TimelineInteracoesService.listarReacoes(publicacaoId);

  static Future<ComentarioSocial> adicionarComentario({
    required String publicacaoId,
    required String autorCpf,
    required String autorNome,
    String autorFoto = '',
    required String texto,
    String respostaDeId = '',
  }) => TimelineInteracoesService.adicionarComentario(
        publicacaoId: publicacaoId, autorCpf: autorCpf, autorNome: autorNome,
        autorFoto: autorFoto, texto: texto, respostaDeId: respostaDeId,
        onNotificar: notificarAlteracao,
      );

  static Future<void> emitirNotificacaoSocial({
    required String destinatarioCpf,
    required String autorCpf,
    required String autorNome,
    String autorFoto = '',
    required TipoNotificacaoSocial tipo,
    String publicacaoId = '',
    required String resumo,
  }) => TimelineInteracoesService.emitirNotificacaoSocial(
        destinatarioCpf: destinatarioCpf, autorCpf: autorCpf, autorNome: autorNome,
        autorFoto: autorFoto, tipo: tipo, publicacaoId: publicacaoId, resumo: resumo,
      );

  static Future<List<ComentarioSocial>> listarComentarios(String publicacaoId) =>
      TimelineInteracoesService.listarComentarios(publicacaoId);

  static Future<ComentarioSocial> alternarFixarComentario(ComentarioSocial comentario) =>
      TimelineInteracoesService.alternarFixarComentario(
        comentario, onNotificar: notificarAlteracao,
      );

  static Future<void> excluirComentario(ComentarioSocial comentario) =>
      TimelineInteracoesService.excluirComentario(
        comentario, onNotificar: notificarAlteracao,
      );

  static Future<ComentarioSocial> alternarReacaoComentario({
    required ComentarioSocial comentario,
    required String usuarioCpf,
    required bool ehLike,
  }) => TimelineInteracoesService.alternarReacaoComentario(
        comentario: comentario, usuarioCpf: usuarioCpf, ehLike: ehLike,
        onNotificar: notificarAlteracao,
      );

  static Future<PublicacaoSocial> republicar({
    required PublicacaoSocial original,
    required String meuCpf,
    required String meuNome,
    String minhaFoto = '',
    String? comentarioCitacao,
  }) => TimelineInteracoesService.republicar(
        original: original, meuCpf: meuCpf, meuNome: meuNome,
        minhaFoto: minhaFoto, comentarioCitacao: comentarioCitacao,
        onNotificar: notificarAlteracao,
      );

  static Future<void> enviarPublicacaoNoChat({
    required PublicacaoSocial pub,
    required String conversaId,
    required String meuCpf,
    required String meuNome,
    String minhaFoto = '',
    String destinatarioId = '',
  }) => TimelineInteracoesService.enviarPublicacaoNoChat(
        pub: pub, conversaId: conversaId, meuCpf: meuCpf, meuNome: meuNome,
        minhaFoto: minhaFoto, destinatarioId: destinatarioId,
      );

  // --- Interações na Rede ---

  static Future<List<RegistroInteracaoUsuario>> listarInteracoesDoUsuario(String cpf) =>
      TimelineInteracoesService.listarInteracoesDoUsuario(cpf);

  // --- Stories e Destaques ---

  static Future<StorySocial> criarStory({
    required String autorCpf,
    required String autorNome,
    String autorFoto = '',
    String tituloDestaque = '',
    String caminhoMidia = '',
    String tipoMidia = 'texto',
    String texto = '',
    String corFundoHex = '',
    bool ehDestaquePermanente = false,
    String perguntaEnquete = '',
    List<String> opcoesEnquete = const [],
    List<CamadaTextoStory> camadasTexto = const [],
    String storyOriginalId = '',
    String autorOriginalNome = '',
  }) => TimelineStoriesService.criarStory(
        autorCpf: autorCpf, autorNome: autorNome, autorFoto: autorFoto,
        tituloDestaque: tituloDestaque, caminhoMidia: caminhoMidia,
        tipoMidia: tipoMidia, texto: texto, corFundoHex: corFundoHex,
        ehDestaquePermanente: ehDestaquePermanente,
        perguntaEnquete: perguntaEnquete, opcoesEnquete: opcoesEnquete,
        camadasTexto: camadasTexto, storyOriginalId: storyOriginalId,
        autorOriginalNome: autorOriginalNome, onNotificar: notificarAlteracao,
      );

  static Future<StorySocial> votarEnqueteStory(
    StorySocial story,
    String cpfEleitor,
    int indiceOpcao,
  ) => TimelineStoriesService.votarEnqueteStory(
        story, cpfEleitor, indiceOpcao, onNotificar: notificarAlteracao,
      );

  static Future<List<StorySocial>> listarStoriesAtivosDaRede() =>
      TimelineRepositorioSqlite.listarStoriesAtivosDaRede();

  static Future<void> excluirStory(StorySocial story) =>
      TimelineStoriesService.excluirStory(story, onNotificar: notificarAlteracao);

  static Future<List<StorySocial>> listarStories(String cpf) =>
      TimelineRepositorioSqlite.listarStoriesDoUsuario(cpf);

  static Future<List<StorySocial>> listarTodosStoriesHistorico(String cpf) =>
      TimelineRepositorioSqlite.listarTodosStoriesDoUsuario(cpf);

  static Future<List<StorySocial>> listarStoriesAtivos24h(String cpf) =>
      TimelineStoriesService.listarStoriesAtivos24h(cpf);

  static Future<StorySocial> registrarVisualizacaoStory(
    StorySocial story,
    String cpfVisualizador,
  ) => TimelineStoriesService.registrarVisualizacaoStory(
        story, cpfVisualizador, onNotificar: notificarAlteracao,
      );

  static Future<StorySocial> alternarDestaqueStory(
    StorySocial story, {
    String? tituloDestaque,
  }) => TimelineStoriesService.alternarDestaqueStory(
        story, tituloDestaque: tituloDestaque, onNotificar: notificarAlteracao,
      );

  static Future<void> enviarRespostaStoryNoChat({
    required StorySocial story,
    required String meuCpf,
    required String meuNome,
    String minhaFoto = '',
    required String respostaTexto,
  }) => TimelineStoriesService.enviarRespostaStoryNoChat(
        story: story, meuCpf: meuCpf, meuNome: meuNome,
        minhaFoto: minhaFoto, respostaTexto: respostaTexto,
      );

  static Future<StorySocial> repostarStory({
    required StorySocial original,
    required String meuCpf,
    required String meuNome,
    String minhaFoto = '',
    List<CamadaTextoStory>? camadasExtras,
  }) => TimelineStoriesService.repostarStory(
        original: original, meuCpf: meuCpf, meuNome: meuNome,
        minhaFoto: minhaFoto, camadasExtras: camadasExtras,
        onNotificar: notificarAlteracao,
      );

  static Future<void> encaminharStoryNoChat({
    required StorySocial story,
    required String meuCpf,
    required String meuNome,
    String minhaFoto = '',
    required String destinatarioCpf,
    String mensagemOpcional = '',
  }) => TimelineStoriesService.encaminharStoryNoChat(
        story: story, meuCpf: meuCpf, meuNome: meuNome,
        minhaFoto: minhaFoto, destinatarioCpf: destinatarioCpf,
        mensagemOpcional: mensagemOpcional,
      );

  // --- Feeds Personalizados / Externos (+) e Timelines Visíveis ---

  static Future<FeedPersonalizado> adicionarFeedPersonalizado({
    required String donoCpf,
    required String titulo,
    required OrigemFeedExterno origem,
    String urlOuIdentificador = '',
  }) => TimelinePublicacoesService.adicionarFeedPersonalizado(
        donoCpf: donoCpf, titulo: titulo, origem: origem,
        urlOuIdentificador: urlOuIdentificador, onNotificar: notificarAlteracao,
      );

  static Future<List<FeedPersonalizado>> listarFeedsPersonalizados(String cpf) =>
      TimelinePublicacoesService.listarFeedsPersonalizados(cpf);

  static const List<TipoFeedSocial> timelinesPadrao =
      TimelinePublicacoesService.timelinesPadrao;

  static Future<List<TipoFeedSocial>> obterTimelinesVisiveis(String cpf) =>
      TimelinePublicacoesService.obterTimelinesVisiveis(cpf);

  static Future<void> ativarTimelineAutomaticamente(String cpf, TipoFeedSocial tipo) =>
      TimelinePublicacoesService.ativarTimelineAutomaticamente(
        cpf, tipo, onNotificar: notificarAlteracao,
      );

  static Future<void> salvarTimelinesVisiveis(String cpf, List<TipoFeedSocial> tipos) =>
      TimelinePublicacoesService.salvarTimelinesVisiveis(
        cpf, tipos, onNotificar: notificarAlteracao,
      );

  // --- Conteúdos Salvos e Denúncias ---

  static Future<ListaSalvosSocial> obterOuCriarListaPadraoSalvos(String cpf) =>
      TimelineSalvosDenunciasService.obterOuCriarListaPadraoSalvos(cpf);

  static Future<ListaSalvosSocial> criarListaSalvos({
    required String donoCpf,
    required String nome,
    required VisibilidadeListaSalvos visibilidade,
    List<String> colaboradoresCpfs = const [],
  }) => TimelineSalvosDenunciasService.criarListaSalvos(
        donoCpf: donoCpf, nome: nome, visibilidade: visibilidade,
        colaboradoresCpfs: colaboradoresCpfs, onNotificar: notificarAlteracao,
      );

  static Future<List<ListaSalvosSocial>> listarListasSalvos(String cpf) =>
      TimelineSalvosDenunciasService.listarListasSalvos(cpf);

  static Future<void> salvarPublicacaoEmLista({
    required String listaId,
    required String usuarioCpf,
    required String publicacaoId,
  }) => TimelineSalvosDenunciasService.salvarPublicacaoEmLista(
        listaId: listaId, usuarioCpf: usuarioCpf, publicacaoId: publicacaoId,
        onNotificar: notificarAlteracao,
      );

  static Future<List<PublicacaoSocial>> listarPublicacoesSalvas({
    required String donoPerfilCpf,
    required String visualizadorCpf,
  }) => TimelineSalvosDenunciasService.listarPublicacoesSalvas(
        donoPerfilCpf: donoPerfilCpf, visualizadorCpf: visualizadorCpf,
      );

  static Future<List<PublicacaoSocial>> listarPublicacoesPorReacao({
    required String cpf,
    required TipoReacaoSocial tipo,
  }) => TimelineSalvosDenunciasService.listarPublicacoesPorReacao(cpf: cpf, tipo: tipo);

  static Future<DenunciaSocial> registrarDenuncia({
    required String denuncianteCpf,
    required String denuncianteNome,
    required String alvoCpf,
    required String alvoNome,
    String publicacaoId = '',
    required String motivo,
  }) => TimelineSalvosDenunciasService.registrarDenuncia(
        denuncianteCpf: denuncianteCpf, denuncianteNome: denuncianteNome,
        alvoCpf: alvoCpf, alvoNome: alvoNome, publicacaoId: publicacaoId,
        motivo: motivo, onNotificar: notificarAlteracao,
      );

  static Future<List<DenunciaSocial>> listarDenunciasDoUsuario(String cpf) =>
      TimelineSalvosDenunciasService.listarDenunciasDoUsuario(cpf);

  // --- Feed de Descoberta & #Tags ---

  static List<Map<String, dynamic>> get abasDescobertaPadrao =>
      TimelineSalvosDenunciasService.abasDescobertaPadrao;

  static Future<List<Map<String, dynamic>>> obterAbasDescoberta(String cpf) =>
      TimelineSalvosDenunciasService.obterAbasDescoberta(cpf);

  static Future<void> salvarAbasDescoberta(String cpf, List<Map<String, dynamic>> abas) =>
      TimelineSalvosDenunciasService.salvarAbasDescoberta(
        cpf, abas, onNotificar: notificarAlteracao,
      );

  static Future<List<PublicacaoSocial>> listarPublicacoesDescoberta({
    List<String> tags = const [],
    List<String>? apenasAutoresCpfs,
    int limit = 30,
    int offset = 0,
  }) => TimelineSalvosDenunciasService.listarPublicacoesDescoberta(
        tags: tags, apenasAutoresCpfs: apenasAutoresCpfs, limit: limit, offset: offset,
      );

  // --- Rede Local Wi-Fi (4 Elos + Delta Sync) ---

  static Future<Map<String, dynamic>> exportarSnapshotSocial({
    DateTime? desde,
    int offset = 0,
  }) => TimelineSyncService.exportarSnapshotSocial(desde: desde, offset: offset);

  static Future<void> mesclarSnapshotSocial(Map<String, dynamic> snapshot) =>
      TimelineSyncService.mesclarSnapshotSocial(snapshot, aoConcluir: notificarAlteracao);

  static Future<bool> sincronizarComServidorHttp({
    required String ip,
    required int porta,
  }) => TimelineSyncService.sincronizarComServidorHttp(
        ip: ip, porta: porta, aoConcluir: notificarAlteracao,
      );

  static Future<void> processarEventoRemoto(Map<String, dynamic> dados) =>
      TimelineSyncService.processarEventoRemoto(dados, aoConcluir: notificarAlteracao);
}
