import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_conversas_service.dart';
import 'package:nous/src/features/chat/services/chat_grupos_service.dart';
import 'package:nous/src/features/chat/services/chat_media_service.dart';
import 'package:nous/src/features/chat/services/chat_mensagens_service.dart';
import 'package:nous/src/features/chat/services/chat_repositorio_sqlite.dart';
import 'package:nous/src/features/chat/services/chat_sincronizacao_service.dart';
import 'package:nous/src/features/chat/services/comunidade_chat_service.dart';
import 'package:nous/src/features/chat/services/helpers/chat_acoes_helper.dart';
import 'package:nous/src/features/chat/services/helpers/chat_identidade_helper.dart';
import 'package:nous/src/features/chat/services/helpers/chat_notificacoes_helper.dart';
import 'package:nous/src/features/chat/services/helpers/chat_recibos_rede_helper.dart';
import 'package:nous/src/features/chat/services/sincronizador_chat_balcao.dart';

/// Fachada Soberana e Unificada de Mensageria Nous
class ChatService {
  ChatService._();

  static final ValueNotifier<int> alteracoesChatNotifier =
      ValueNotifier<int>(0);
  static String? idConversaAtiva;
  static Timer? _timerDebounceNotificacao;

  static const String idLojaColetivaNous = 'loja_nous_coletiva';
  static const String idTopicoGeral = 'loja_nous_coletiva_topico_geral';

  static void notificarAlteracao({bool imediato = false}) {
    if (imediato) {
      _timerDebounceNotificacao?.cancel();
      alteracoesChatNotifier.value++;
      return;
    }
    if (_timerDebounceNotificacao?.isActive ?? false) return;
    _timerDebounceNotificacao = Timer(const Duration(milliseconds: 50), () {
      alteracoesChatNotifier.value++;
    });
  }

  static String normalizarCpf(String cpf) =>
      ChatRepositorioSqlite.normalizarCpf(cpf);

  static Future<String> obterCpfLogadoLocal() =>
      ChatIdentidadeHelper.obterCpfLogadoLocal();

  static String conversaIdLojaUsuario(String lojaId, String usuarioCpf) =>
      ChatIdentidadeHelper.conversaIdLojaUsuario(lojaId, usuarioCpf);

  static String conversaIdEntreUsuarios(String cpfA, String cpfB) =>
      ChatIdentidadeHelper.conversaIdEntreUsuarios(cpfA, cpfB);

  static String extrairOutroCpf(String convId, String meuCpf) =>
      ChatRepositorioSqlite.extrairOutroCpf(convId, meuCpf);

  static Future<Database> obterDb() => ChatRepositorioSqlite.obterDb();

  static Future<String?> salvarArquivoAnexo(String caminhoOriginal) =>
      ChatMediaService.salvarArquivoAnexo(caminhoOriginal);

  static String gerarResumoMensagem(MensagemChat msg) =>
      ChatMediaService.gerarResumoMensagem(msg);

  static List<String> decodificarParticipantes(String? raw) =>
      ChatRepositorioSqlite.decodificarParticipantes(raw);

  static Future<void> consolidarConversasDuplicadas() =>
      ChatMensagensService.consolidarConversasDuplicadas();

  static Future<List<ConversaChat>> obterTodasConversas({
    String? cpfUsuario,
    String? lojaId,
    bool incluirArquivadas = false,
    Map<String, UsuarioNous>? mapaContasPreCarregado,
  }) =>
      ChatConversasService.obterTodasConversas(
        cpfUsuario: cpfUsuario,
        lojaId: lojaId,
        incluirArquivadas: incluirArquivadas,
        mapaContasPreCarregado: mapaContasPreCarregado,
        aoNotificar: notificarAlteracao,
      );

  static Future<ConversaChat> obterOuCriarConversa({
    required String id,
    required String titulo,
    String subtitulo = '',
    String foto = '',
    required String identificador,
    bool ehLoja = false,
    bool ehGrupo = false,
    String? lojaId,
    String? cpfUsuario,
    List<String> participantesIds = const [],
  }) =>
      ChatConversasService.obterOuCriarConversa(
        id: id,
        titulo: titulo,
        subtitulo: subtitulo,
        foto: foto,
        identificador: identificador,
        ehLoja: ehLoja,
        ehGrupo: ehGrupo,
        lojaId: lojaId,
        cpfUsuario: cpfUsuario,
        participantesIds: participantesIds,
        aoNotificar: notificarAlteracao,
      );

  static Future<void> salvarConversa(ConversaChat conversa) =>
      ChatConversasService.salvarConversa(
        conversa,
        aoNotificar: notificarAlteracao,
      );

  static Future<void> alternarFixarConversa(
    String conversaId, [
    bool? fixar,
  ]) =>
      ChatConversasService.alternarFixarConversa(
        conversaId,
        fixar,
        notificarAlteracao,
      );

  static Future<void> alternarArquivarConversa(
    String conversaId, [
    bool? arquivar,
  ]) =>
      ChatConversasService.alternarArquivarConversa(
        conversaId,
        arquivar,
        notificarAlteracao,
      );

  static Future<void> drenarFilaDeSaida() async {
    final alterou = await ChatSincronizacaoService.drenarFilaDeSaida();
    if (alterou) notificarAlteracao();
  }

  static Future<MensagemChat> enviarMensagemInstantanea(
    MensagemChat mensagem,
  ) =>
      ChatMensagensService.enviarMensagemInstantanea(
        mensagem,
        aoNotificar: notificarAlteracao,
      );

  static Future<bool> salvarMensagem(
    MensagemChat mensagem, {
    bool originadaDaRede = false,
    bool notificar = true,
  }) =>
      ChatMensagensService.salvarMensagem(
        mensagem,
        originadaDaRede: originadaDaRede,
        obterCpfLogadoLocal: obterCpfLogadoLocal,
        aoNotificar: notificar ? notificarAlteracao : () {},
      );

  static Future<bool> despacharMensagemParaRede(MensagemChat msg) =>
      ChatSincronizacaoService.despacharMensagemParaRede(msg);

  static Future<void> processarMensagemRecebidaRede(
    Map<String, dynamic> payloadMensagem, {
    bool emitirAlertaSonoro = true,
  }) =>
      ChatMensagensService.processarMensagemRecebidaRede(
        payloadMensagem,
        emitirAlertaSonoro: emitirAlertaSonoro,
        idConversaAtiva: idConversaAtiva,
        obterCpfLogadoLocal: obterCpfLogadoLocal,
        deveNotificarConversa: deveNotificarConversa,
        aoNotificar: notificarAlteracao,
      );

  static Future<void> processarMensagemRecebidaDaRede(
    Map<String, dynamic> payloadMensagem, {
    bool emitirAlertaSonoro = true,
  }) =>
      processarMensagemRecebidaRede(
        payloadMensagem,
        emitirAlertaSonoro: emitirAlertaSonoro,
      );

  /// Processa evento de entrega de mensagem recebido da rede local (2 checks cinzas)
  static Future<void> processarMensagemEntregueDaRede(
    String msgId, {
    String? conversaId,
  }) =>
      ChatRecibosRedeHelper.processarMensagemEntregueDaRede(
        msgId,
        conversaId: conversaId,
        aoNotificar: notificarAlteracao,
      );

  /// Identifica se uma conversa é coletiva (grupos, tópicos da Ágora Digital, comunidade ou chat de equipe)
  static bool ehConversaColetivaOuGrupo(String conversaId) =>
      ChatRecibosRedeHelper.ehConversaColetivaOuGrupo(conversaId);

  /// Processa confirmação de mensagens lidas recebida da rede local (2 checks azuis)
  static Future<void> processarMensagensLidasDaRede(
    String conversaId,
    String idLeitor,
  ) =>
      ChatRecibosRedeHelper.processarMensagensLidasDaRede(
        conversaId,
        idLeitor,
        aoNotificar: notificarAlteracao,
      );

  /// Alterna o status de favorita de uma mensagem
  static Future<bool> alternarFavoritaMensagem(String id) async {
    final res = await ChatRepositorioSqlite.alternarFavoritaMensagem(id);
    notificarAlteracao(imediato: true);
    return res;
  }

  /// Alterna o silenciamento de notificações de uma conversa
  static Future<bool> alternarSilenciarConversa(String conversaId) =>
      ChatNotificacoesHelper.alternarSilenciarConversa(
        conversaId,
        aoNotificar: notificarAlteracao,
      );

  static Future<void> curarTimestampsAnomalosDoPassado() =>
      ChatRepositorioSqlite.curarTimestampsAnomalosDoPassado();

  static void despacharConfirmacaoLida(String convId, String idLeitor) =>
      ChatSincronizacaoService.despacharConfirmacaoLida(convId, idLeitor);

  static void despacharConfirmacaoEntrega(String msgId, String convId) =>
      ChatSincronizacaoService.despacharConfirmacaoEntrega(msgId, convId);

  static Future<void> sincronizarMensagensComBalcao({
    required String ipServidor,
    required int portaServidor,
    String? cpfUsuario,
    String? lojaId,
  }) =>
      SincronizadorChatBalcao.sincronizarMensagensComBalcao(
        ipServidor: ipServidor,
        portaServidor: portaServidor,
        cpfUsuario: cpfUsuario,
        lojaId: lojaId,
      );

  static Future<List<Map<String, dynamic>>> obterConversasParaSincronizacao({
    String? cpf,
    String? lojaId,
  }) =>
      SincronizadorChatBalcao.obterConversasParaSincronizacao(
        cpf: cpf,
        lojaId: lojaId,
      );

  static Future<bool> salvarConversaLocal(
    Map<String, dynamic> c, {
    bool notificar = true,
  }) =>
      SincronizadorChatBalcao.salvarConversaLocal(c, notificar: notificar);

  static Future<List<Map<String, dynamic>>> obterMensagensParaSincronizacao({
    String? cpf,
    String? lojaId,
  }) =>
      SincronizadorChatBalcao.obterMensagensParaSincronizacao(
        cpf: cpf,
        lojaId: lojaId,
      );

  static Future<List<MensagemChat>> carregarMensagens(
    String conversaId, {
    String? idVisualizador,
    int? limite,
    int? offset,
  }) =>
      ChatIdentidadeHelper.carregarMensagens(
        conversaId,
        idVisualizador: idVisualizador,
        limite: limite,
        offset: offset,
      );

  static Future<void> marcarComoLidas(
    String conversaId,
    String idLeitor, {
    bool notificar = true,
  }) =>
      ChatRecibosRedeHelper.marcarComoLidas(
        conversaId,
        idLeitor,
        notificar: notificar,
        aoNotificar: notificarAlteracao,
      );

  static Future<bool> temMensagensNaoLidasNaLoja(String lojaId) =>
      ChatRepositorioSqlite.temMensagensNaoLidasNaLoja(
          lojaId, idConversaAtiva);

  static Future<List<MensagemChat>> obterMensagensNaoLidasDaLoja(
    String lojaId,
  ) =>
      ChatMensagensService.obterMensagensNaoLidasDaLoja(
        lojaId,
        idConversaAtiva: idConversaAtiva,
      );

  static Future<void> marcarMensagensDaLojaComoLidas(
    String lojaId,
    String idLeitor,
  ) =>
      ChatRecibosRedeHelper.marcarMensagensDaLojaComoLidas(
        lojaId,
        idLeitor,
        aoNotificar: notificarAlteracao,
      );

  static Future<void> processarMensagensLidasDaLojaDaRede(
    String lojaId,
    String idLeitor,
  ) =>
      ChatRecibosRedeHelper.processarMensagensLidasDaLojaDaRede(
        lojaId,
        idLeitor,
        aoNotificar: notificarAlteracao,
      );

  static Future<bool> temMensagensNaoLidasNoUsuario(String cpf) =>
      ChatRepositorioSqlite.temMensagensNaoLidasNoUsuario(
          cpf, idConversaAtiva);

  static Future<List<MensagemChat>> obterMensagensNaoLidasDoUsuario(
    String cpf,
  ) =>
      ChatMensagensService.obterMensagensNaoLidasDoUsuario(
        cpf,
        idConversaAtiva: idConversaAtiva,
      );

  static Future<void> marcarMensagensDoUsuarioComoLidas(
    String cpf,
    List<String> conversaIds,
  ) =>
      ChatRecibosRedeHelper.marcarMensagensDoUsuarioComoLidas(
        cpf,
        conversaIds,
        aoNotificar: notificarAlteracao,
      );

  static Future<Map<String, ({String nome, String foto})>>
      obterInterlocutoresDoUsuario(String cpf) =>
          ChatMensagensService.obterInterlocutoresDoUsuario(cpf);

  static Future<int> contarNaoLidasNaConversa(
    String conversaId,
    String idVisualizador,
  ) =>
      ChatRepositorioSqlite.contarNaoLidasNaConversa(
          conversaId, idVisualizador);

  static Future<ConversaChat> criarGrupo({
    required String nome,
    required List<String> membrosCpfs,
    required String autorCpf,
    required String autorNome,
    String? lojaOrigemId,
  }) =>
      ChatGruposService.criarGrupo(
        nome: nome,
        membrosCpfs: membrosCpfs,
        autorCpf: autorCpf,
        autorNome: autorNome,
        lojaOrigemId: lojaOrigemId,
        salvarMensagem: salvarMensagem,
        despacharMensagemParaRede: despacharMensagemParaRede,
        aoNotificar: notificarAlteracao,
      );

  static Future<List<ConversaChat>> carregarGrupos({
    String? cpfParticipante,
    String? lojaId,
  }) =>
      ChatGruposService.carregarGrupos(
        cpfParticipante: cpfParticipante,
        lojaId: lojaId,
      );

  static Future<void> atualizarFotoGrupo(
    String grupoId,
    String caminhoFoto,
  ) =>
      ChatGruposService.atualizarFotoGrupo(
        grupoId,
        caminhoFoto,
        aoNotificar: notificarAlteracao,
      );

  static Future<void> editarMensagem(String id, String novoTexto) =>
      ChatMensagensService.editarMensagem(
        id,
        novoTexto,
        aoNotificar: notificarAlteracao,
      );

  static Future<bool> excluirMensagem(String id) =>
      ChatMensagensService.excluirMensagem(
        id,
        aoNotificar: notificarAlteracao,
      );

  static Future<bool> deveNotificarConversa(String conversaId) =>
      ChatNotificacoesHelper.deveNotificarConversa(conversaId);

  static Future<void> alternarNotificacaoConversa(
    String conversaId,
    bool notificar,
  ) =>
      ChatNotificacoesHelper.alternarNotificacaoConversa(
        conversaId,
        notificar,
        aoNotificar: notificarAlteracao,
      );

  static Future<List<ConversaChat>> obterTopicosComunidadeNous({
    String? cpfUsuario,
  }) =>
      ComunidadeChatService.obterTopicosComunidadeNous(
        cpfUsuario: cpfUsuario,
      );

  static Future<List<ConversaChat>> obterTodasSalasComunitarias() =>
      ComunidadeChatService.obterTodasSalasComunitarias();

  static Future<ConversaChat> criarOuObterTopicoComunidadeNous(
    String topicoIdOuTitulo, [
    String? nomeTopico,
    String? criadorCpf,
  ]) =>
      ComunidadeChatService.criarOuObterTopicoComunidadeNous(
        topicoIdOuTitulo,
        nomeTopico,
        criadorCpf,
      );

  static Future<void> entrarTopicoComunidade({
    required String topicoId,
    required String cpf,
    required String nomeUsuario,
  }) =>
      ComunidadeChatService.entrarTopicoComunidade(
        topicoId: topicoId,
        cpf: cpf,
        nomeUsuario: nomeUsuario,
      );

  static Future<void> sairTopicoComunidade({
    required String topicoId,
    required String cpf,
    required String nomeUsuario,
  }) =>
      ComunidadeChatService.sairTopicoComunidade(
        topicoId: topicoId,
        cpf: cpf,
        nomeUsuario: nomeUsuario,
      );

  static Future<void> renomearTopicoComunidadeNous(
    String topicoId,
    String novoNome,
  ) =>
      ComunidadeChatService.renomearTopicoComunidadeNous(
        topicoId,
        novoNome,
      );

  static Future<void> renomearConversa(
    String conversaId,
    String novoTitulo, {
    bool originadoDaRede = false,
  }) =>
      ChatConversasService.renomearConversa(
        conversaId,
        novoTitulo,
        originadoDaRede: originadoDaRede,
        aoNotificar: notificarAlteracao,
      );

  static Future<void> atualizarMetadadosContatoConversa({
    required String conversaId,
    required String titulo,
    required String subtitulo,
    required String foto,
  }) =>
      ChatConversasService.atualizarMetadadosContatoConversa(
        conversaId: conversaId,
        titulo: titulo,
        subtitulo: subtitulo,
        foto: foto,
      );

  static Future<Map<String, String>> obterTitulosCustomizados([
    String? cpfLogado,
  ]) =>
      ChatConversasService.obterTitulosCustomizados(cpfLogado);

  static Future<List<String>> obterIdsConversasExcluidas() =>
      ChatRepositorioSqlite.obterIdsConversasExcluidas();

  static Future<bool> isConversaExcluida(String conversaId) =>
      ChatRepositorioSqlite.isConversaExcluida(conversaId);

  static Future<void> desmarcarConversaExcluida(String conversaId) =>
      ChatRepositorioSqlite.desmarcarConversaExcluida(conversaId);

  static Future<void> excluirConversaLocal(
    String conversaId, {
    bool originadoDaRede = false,
  }) =>
      ChatAcoesHelper.excluirConversaLocal(
        conversaId,
        originadoDaRede: originadoDaRede,
        aoNotificar: notificarAlteracao,
      );

  static void despacharConversaRenomeada(
          String conversaId, String novoTitulo) =>
      ChatSincronizacaoService.despacharConversaRenomeada(
          conversaId, novoTitulo);

  static void despacharConversaAtualizada(ConversaChat conversa) =>
      ChatSincronizacaoService.despacharConversaAtualizada(conversa);

  static Future<bool> alternarFixarMensagem(
    String msgId, {
    bool? fixar,
    String? conversaId,
  }) =>
      ChatAcoesHelper.alternarFixarMensagem(
        msgId,
        fixar: fixar,
        conversaId: conversaId,
        aoNotificar: notificarAlteracao,
      );

  static Future<Map<String, String>> reagirMensagem(
    String msgId,
    String autorId,
    String emoji, {
    String? conversaId,
  }) =>
      ChatAcoesHelper.reagirMensagem(
        msgId,
        autorId,
        emoji,
        conversaId: conversaId,
        aoNotificar: notificarAlteracao,
      );

  static Future<void> atualizarDadosComandaMensagem({
    required String msgId,
    required String dadosPedidoJson,
    String? texto,
  }) =>
      ChatAcoesHelper.atualizarDadosComandaMensagem(
        msgId: msgId,
        dadosPedidoJson: dadosPedidoJson,
        texto: texto,
        aoNotificar: notificarAlteracao,
      );
}
