import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_conversas_service.dart';
import 'package:nous/src/features/chat/services/chat_grupos_service.dart';
import 'package:nous/src/features/chat/services/chat_media_service.dart';
import 'package:nous/src/features/chat/services/chat_mensagens_service.dart';
import 'package:nous/src/features/chat/services/chat_repositorio_sqlite.dart';
import 'package:nous/src/features/chat/services/chat_sincronizacao_service.dart';
import 'package:nous/src/features/chat/services/comunidade_chat_service.dart';
import 'package:nous/src/features/chat/services/sincronizador_chat_balcao.dart';

/// Fachada Soberana e Unificada de Mensageria Nous
class ChatService {
  ChatService._();

  static final ValueNotifier<int> alteracoesChatNotifier =
      ValueNotifier<int>(0);
  static String? idConversaAtiva;
  static Timer? _timerDebounceNotificacao;

  static const String _chaveConversasSilenciadas =
      'nous_conversas_silenciadas';
  static const String idLojaColetivaNous = 'loja_nous_coletiva';
  static const String idTopicoGeral = 'loja_nous_coletiva_geral';

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

  static Future<String> obterCpfLogadoLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cpf = prefs.getString('ultimo_cpf_login') ?? '';
      return normalizarCpf(cpf);
    } catch (_) {
      return '';
    }
  }

  static String conversaIdLojaUsuario(String lojaId, String usuarioCpf) {
    final prefixo = lojaId.startsWith('loja_') ? lojaId : 'loja_$lojaId';
    return '${prefixo}_usuario_${normalizarCpf(usuarioCpf)}';
  }

  static String conversaIdEntreUsuarios(String cpfA, String cpfB) {
    final c1 = normalizarCpf(cpfA);
    final c2 = normalizarCpf(cpfB);
    final lista = [c1, c2]..sort();
    return 'user_${lista[0]}_user_${lista[1]}';
  }

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
  }) =>
      ChatConversasService.obterTodasConversas(
        cpfUsuario: cpfUsuario,
        lojaId: lojaId,
        incluirArquivadas: incluirArquivadas,
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
  }) async {
    if (msgId.isEmpty) return;
    try {
      final db = await ChatRepositorioSqlite.obterDb();
      final alterou = await db.update(
        'mensagens_chat',
        {'status_envio': 'entregue', 'entregue': 1},
        where: 'id = ? AND status_envio != "lida"',
        whereArgs: [msgId],
      );
      if (alterou > 0) {
        notificarAlteracao();
      }
    } catch (e) {
      debugPrint('[ChatService] Erro ao processar mensagem entregue da rede: $e');
    }
  }

  /// Processa confirmação de mensagens lidas recebida da rede local (2 checks azuis)
  static Future<void> processarMensagensLidasDaRede(
    String conversaId,
    String idLeitor,
  ) async {
    if (conversaId.isEmpty) return;
    try {
      final db = await ChatRepositorioSqlite.obterDb();

      // Em grupos, uma leitura individual não deve passar a mensagem para azul (lida por todos)
      // prematuramente. Passa para 'entregue' (2 checks cinzas) até que todos confirmem.
      if (conversaId.startsWith('grupo_')) {
        final alterou = await db.update(
          'mensagens_chat',
          {'status_envio': 'entregue', 'entregue': 1},
          where: 'conversa_id = ? AND status_envio = "enviada"',
          whereArgs: [conversaId],
        );
        if (alterou > 0) {
          notificarAlteracao();
        }
        return;
      }

      final alterou = await db.update(
        'mensagens_chat',
        {'status_envio': 'lida', 'lida': 1},
        where: 'conversa_id = ? AND status_envio != "lida"',
        whereArgs: [conversaId],
      );
      if (alterou > 0) {
        notificarAlteracao();
      }
    } catch (e) {
      debugPrint('[ChatService] Erro ao processar mensagens lidas da rede: $e');
    }
  }

  /// Alterna o status de favorita de uma mensagem
  static Future<bool> alternarFavoritaMensagem(String id) async {
    final res = await ChatRepositorioSqlite.alternarFavoritaMensagem(id);
    notificarAlteracao(imediato: true);
    return res;
  }

  /// Alterna o silenciamento de notificações de uma conversa
  static Future<bool> alternarSilenciarConversa(String conversaId) async {
    final res = await ChatRepositorioSqlite.alternarSilenciarConversa(conversaId);
    notificarAlteracao(imediato: true);
    return res;
  }

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
      ChatRepositorioSqlite.carregarMensagens(
        conversaId,
        idVisualizador: idVisualizador,
        limite: limite,
        offset: offset,
      );

  static Future<void> marcarComoLidas(
    String conversaId,
    String idLeitor, {
    bool notificar = true,
  }) async {
    await ChatRepositorioSqlite.marcarComoLidas(
      conversaId,
      idLeitor,
    );
    if (notificar) {
      notificarAlteracao();
    }
    despacharConfirmacaoLida(conversaId, idLeitor);
  }

  static Future<bool> temMensagensNaoLidasNaLoja(String lojaId) =>
      ChatRepositorioSqlite.temMensagensNaoLidasNaLoja(
          lojaId, idConversaAtiva);

  static Future<List<MensagemChat>> obterMensagensNaoLidasDaLoja(
    String lojaId,
  ) =>
      ChatMensagensService.obterMensagensNaoLidasDaLoja(lojaId);

  static Future<void> marcarMensagensDaLojaComoLidas(
    String lojaId,
    String idLeitor,
  ) async {
    final alterou =
        await ChatRepositorioSqlite.marcarMensagensDaLojaComoLidas(
      lojaId,
      idLeitor,
    );
    if (alterou) {
      notificarAlteracao();
    }
    ChatSincronizacaoService.despacharEventoRede({
      'tipo': 'mensagens_lidas_loja',
      'lojaId': lojaId,
      'idLeitor': idLeitor,
    });
  }

  static Future<void> processarMensagensLidasDaLojaDaRede(
    String lojaId,
    String idLeitor,
  ) async {
    if (lojaId.isEmpty) return;
    try {
      final alterou =
          await ChatRepositorioSqlite.marcarMensagensDaLojaComoLidas(
        lojaId,
        idLeitor,
      );
      if (alterou) {
        notificarAlteracao();
      }
    } catch (e) {
      debugPrint('[ChatService] Erro ao processar mensagens_lidas_loja da rede: $e');
    }
  }

  static Future<bool> temMensagensNaoLidasNoUsuario(String cpf) =>
      ChatRepositorioSqlite.temMensagensNaoLidasNoUsuario(
          cpf, idConversaAtiva);

  static Future<List<MensagemChat>> obterMensagensNaoLidasDoUsuario(
    String cpf,
  ) =>
      ChatMensagensService.obterMensagensNaoLidasDoUsuario(cpf);

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

  static Future<bool> deveNotificarConversa(String conversaId) async {
    try {
      final db = await ChatRepositorioSqlite.obterDb();
      final rows = await db.query(
        'conversas_chat',
        columns: ['silenciada'],
        where: 'id = ?',
        whereArgs: [conversaId],
        limit: 1,
      );
      if (rows.isNotEmpty && (rows.first['silenciada'] as int? ?? 0) == 1) {
        return false;
      }
      final prefs = await SharedPreferences.getInstance();
      final silenciadas =
          prefs.getStringList(_chaveConversasSilenciadas) ?? [];
      return !silenciadas.contains(conversaId);
    } catch (_) {
      return true;
    }
  }

  static Future<void> alternarNotificacaoConversa(
    String conversaId,
    bool notificar,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final silenciadas =
          (prefs.getStringList(_chaveConversasSilenciadas) ?? []).toSet();
      if (notificar) {
        silenciadas.remove(conversaId);
      } else {
        silenciadas.add(conversaId);
      }
      await prefs.setStringList(
        _chaveConversasSilenciadas,
        silenciadas.toList(),
      );
      notificarAlteracao();
    } catch (e) {
      debugPrint('[ChatService] Erro ao alternar notificação de conversa: $e');
    }
  }

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
  }) async {
    await ChatRepositorioSqlite.excluirConversaLocal(conversaId);
    notificarAlteracao();
    if (!originadoDaRede) {
      ChatSincronizacaoService.despacharEventoRede({
        'tipo': 'conversa_excluida',
        'conversaId': conversaId,
      });
    }
  }

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
  }) async {
    final novo = await ChatRepositorioSqlite.alternarFixarMensagem(
      msgId,
      fixar: fixar,
    );
    notificarAlteracao();
    ChatSincronizacaoService.despacharEventoRede({
      'tipo': 'mensagem_fixada',
      'id': msgId,
      'conversaId': conversaId ?? '',
      'fixada': novo,
    });
    return novo;
  }

  static Future<Map<String, String>> reagirMensagem(
    String msgId,
    String autorId,
    String emoji, {
    String? conversaId,
  }) async {
    final reacoes = await ChatRepositorioSqlite.reagirMensagem(
      msgId,
      autorId,
      emoji,
    );
    notificarAlteracao();
    ChatSincronizacaoService.despacharEventoRede({
      'tipo': 'mensagem_reacao',
      'id': msgId,
      'conversaId': conversaId ?? '',
      'reacoes': reacoes,
    });
    return reacoes;
  }

  static Future<void> atualizarDadosComandaMensagem({
    required String msgId,
    required String dadosPedidoJson,
    String? texto,
  }) async {
    final db = await ChatRepositorioSqlite.obterDb();
    await db.update(
      'mensagens_chat',
      {
        'dados_pedido_json': dadosPedidoJson,
        if (texto != null && texto.isNotEmpty) 'texto': texto,
      },
      where: 'id = ?',
      whereArgs: [msgId],
    );
    notificarAlteracao();
    ChatSincronizacaoService.despacharEventoRede({
      'tipo': 'comanda_atualizada',
      'id': msgId,
      'dadosPedidoJson': dadosPedidoJson,
      'texto': ?texto,
    });
  }
}
