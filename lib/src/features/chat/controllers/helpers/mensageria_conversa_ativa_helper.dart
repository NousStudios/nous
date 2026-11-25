import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nous/src/core/services/preferencias_soberanas_service.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/chat/controllers/helpers/mensageria_mensagem_helper.dart';
import 'package:nous/src/features/chat/controllers/helpers/mensageria_selecao_helper.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/services/notificacao_android_service.dart';

/// Helper para manipulação de estado da conversa ativa, mesclagem de
/// mensagens pendentes e montagem de metadados de resposta.
class MensageriaConversaAtivaHelper {
  const MensageriaConversaAtivaHelper._();

  static bool deveIgnorarConversaColetiva({
    required bool ehLoja,
    required String identificador,
    required String convId,
    required String titulo,
    required String idLojaColetiva,
  }) {
    return ehLoja &&
        (identificador == idLojaColetiva ||
            convId.contains(idLojaColetiva) ||
            titulo.trim().toLowerCase() == 'nous');
  }

  static String? resolverLojaIdConversa({
    required String convId,
    required bool modoLoja,
    String? lojaId,
    required bool ehLoja,
    required String identificador,
  }) {
    final ehConvLojaUsuario =
        convId.startsWith('loja_') && convId.contains('_usuario_');
    if (modoLoja) return lojaId;
    if (ehConvLojaUsuario) {
      return convId.substring(5, convId.indexOf('_usuario_'));
    }
    return ehLoja ? identificador.replaceFirst('loja_', '') : null;
  }

  static ConversaChat montarConversaOtimista({
    required String convId,
    required String titulo,
    required String subtitulo,
    required String identificador,
    required String foto,
    required bool ehLoja,
    required bool ehConvLojaUsuario,
    String? lojaIdResolvido,
  }) {
    return ConversaChat(
      id: convId,
      titulo: titulo,
      subtitulo: subtitulo,
      identificador: identificador,
      foto: foto,
      ehLoja: ehLoja || ehConvLojaUsuario,
      lojaId: lojaIdResolvido,
      naoLidasCount: 0,
      mensagens: const [],
      dataHoraUltimaMensagem: DateTime.now(),
      ultimaMensagem: '',
    );
  }

  static ConversaChat? mesclarMensagensRecarregadas({
    required ConversaChat conversaAtual,
    required List<MensagemChat> msgsBanco,
    required String Function(MensagemChat) resumoMensagem,
  }) {
    final msgsAtuais = conversaAtual.mensagens;
    final idsNoBanco = msgsBanco.map((m) => m.id).toSet();
    final pendentesLocais = msgsAtuais
        .where((m) => m.statusEnvio == 'pendente' && !idsNoBanco.contains(m.id))
        .toList();

    final List<MensagemChat> msgsFinais;
    if (pendentesLocais.isNotEmpty) {
      msgsFinais = [...msgsBanco, ...pendentesLocais]..sort((a, b) {
          final cmp = a.dataHora.compareTo(b.dataHora);
          if (cmp != 0) return cmp;
          return a.id.compareTo(b.id);
        });
    } else {
      msgsFinais = msgsBanco;
    }

    if (listasMensagensIguais(msgsAtuais, msgsFinais)) {
      return null;
    }

    return conversaAtual.copyWith(
      mensagens: msgsFinais,
      ultimaMensagem: msgsFinais.isNotEmpty
          ? resumoMensagem(msgsFinais.last)
          : conversaAtual.ultimaMensagem,
      dataHoraUltimaMensagem: msgsFinais.isNotEmpty
          ? msgsFinais.last.dataHora
          : conversaAtual.dataHoraUltimaMensagem,
    );
  }

  static bool listasMensagensIguais(
    List<MensagemChat> a,
    List<MensagemChat> b,
  ) {
    if (a.length != b.length) return false;
    for (int k = 0; k < b.length; k++) {
      final m1 = a[k];
      final m2 = b[k];
      if (m1.id != m2.id ||
          m1.statusEnvio != m2.statusEnvio ||
          m1.lida != m2.lida ||
          m1.entregue != m2.entregue ||
          m1.texto != m2.texto ||
          m1.editada != m2.editada ||
          m1.favorita != m2.favorita ||
          m1.fixada != m2.fixada ||
          m1.caminhoAnexo != m2.caminhoAnexo ||
          m1.dadosPedidoJson != m2.dadosPedidoJson ||
          !mapEquals(m1.reacoes, m2.reacoes)) {
        return false;
      }
    }
    return true;
  }

  static MensagemChat aplicarRespostaSeHouver(
    MensagemChat base,
    MensagemChat? resp,
  ) {
    if (resp == null) return base;
    final textoResp = resp.texto.trim().isNotEmpty
        ? resp.texto.trim()
        : (resp.tipo == 'audio'
            ? 'Áudio'
            : (resp.tipo == 'imagem'
                ? 'Foto'
                : (resp.nomeAnexo.isNotEmpty ? resp.nomeAnexo : 'Mídia')));
    final autorResp = resp.remetenteNome.isNotEmpty
        ? resp.remetenteNome
        : (resp.enviadaPorMim ? 'Você' : 'Contato');
    return base.copyWith(
      respostaAId: resp.id,
      respostaATexto: textoResp,
      respostaAAutor: autorResp,
    );
  }

  static ConversaChat? substituirMensagemSalva({
    required ConversaChat conversa,
    required String mensagemId,
    required MensagemChat msgSalva,
  }) {
    final msgs = List<MensagemChat>.from(conversa.mensagens);
    final i = msgs.indexWhere((m) => m.id == mensagemId);
    if (i == -1) return null;
    msgs[i] = msgSalva;
    msgs.sort((a, b) {
      final cmp = a.dataHora.compareTo(b.dataHora);
      if (cmp != 0) return cmp;
      return a.id.compareTo(b.id);
    });
    return conversa.copyWith(mensagens: msgs);
  }

  static ConversaChat? reconciliarSelecionadaAposRecarga({
    required List<ConversaChat> conversas,
    required ConversaChat? selecionadaAtual,
    required String idVisualizador,
  }) {
    if (selecionadaAtual == null) return null;
    var resultado = selecionadaAtual;
    final index = conversas.indexWhere((c) => c.id == selecionadaAtual.id);
    if (index != -1) {
      final msgsAtuais = selecionadaAtual.mensagens;
      final novasMsgs = conversas[index].mensagens;
      final msgsFinais = novasMsgs.isNotEmpty ? novasMsgs : msgsAtuais;
      resultado = conversas[index].copyWith(
        naoLidasCount: 0,
        mensagens: msgsFinais,
      );
      conversas[index] = resultado;
    }
    ChatService.idConversaAtiva = resultado.id;
    unawaited(ChatService.marcarComoLidas(
      resultado.id,
      idVisualizador,
      notificar: false,
    ));
    return resultado;
  }

  static ConversaChat prepararConversaSelecionada({
    required ConversaChat nova,
    required ConversaChat? selecionadaAtual,
  }) {
    final msgsEmMemoria = (selecionadaAtual?.id == nova.id &&
            selecionadaAtual!.mensagens.isNotEmpty)
        ? selecionadaAtual.mensagens
        : nova.mensagens;
    return nova.copyWith(
      naoLidasCount: 0,
      mensagens: msgsEmMemoria,
    );
  }

  static void sincronizarAberturaConversa({
    required ConversaChat conversa,
    required bool estavaNaLista,
    required bool modoLoja,
    String? lojaId,
    String? usuarioCpf,
    required String idVisualizador,
    required String Function(MensagemChat) resumoMensagem,
    required bool Function() deveAplicar,
    required void Function(ConversaChat atualizada) onMensagensCarregadas,
  }) {
    NotificacaoAndroidService.cancelarNotificacaoConversa(conversa.id);
    if (!estavaNaLista) {
      unawaited(
        ChatService.obterOuCriarConversa(
          id: conversa.id,
          titulo: conversa.titulo,
          subtitulo: conversa.subtitulo,
          identificador: conversa.identificador,
          foto: conversa.foto,
          ehLoja: conversa.ehLoja || conversa.id.startsWith('loja_'),
          ehGrupo: conversa.ehGrupo,
          lojaId: conversa.lojaId ?? (modoLoja ? lojaId : null),
          cpfUsuario: modoLoja ? null : usuarioCpf,
        ),
      );
    }

    salvarUltimaConversaAberta(
      convId: conversa.id,
      modoLoja: modoLoja,
      lojaId: lojaId,
      usuarioCpf: usuarioCpf,
    );
    unawaited(ChatService.desmarcarConversaExcluida(conversa.id));
    unawaited(ChatService.marcarComoLidas(
      conversa.id,
      idVisualizador,
      notificar: false,
    ));

    ChatService.carregarMensagens(conversa.id, idVisualizador: idVisualizador)
        .then((msgs) {
      if (!deveAplicar()) return;
      final comMsgs = conversa.copyWith(
        mensagens: msgs,
        ultimaMensagem: msgs.isNotEmpty
            ? resumoMensagem(msgs.last)
            : conversa.ultimaMensagem,
        dataHoraUltimaMensagem: msgs.isNotEmpty
            ? msgs.last.dataHora
            : conversa.dataHoraUltimaMensagem,
      );
      onMensagensCarregadas(comMsgs);
    }).catchError((Object e) {
      debugPrint('[MensageriaController] Erro ao carregar mensagens da conversa: $e');
    });
  }

  static Future<void> salvarUltimaConversaAberta({
    required String convId,
    required bool modoLoja,
    String? lojaId,
    String? usuarioCpf,
  }) async {
    try {
      final chave =
          'chat_ultima_conversa_${modoLoja ? (lojaId ?? "loja") : (usuarioCpf ?? "usr")}';
      await PreferenciasSoberanasService.salvarTexto(chave, convId);
    } catch (_) {}
  }

  static void enviarMensagemComConfirmacao({
    required ConversaChat conversaSelecionada,
    required List<ConversaChat> conversas,
    required MensagemChat? mensagemRespondendo,
    required String texto,
    required String tipo,
    required String caminhoAnexo,
    required String nomeAnexo,
    required int tamanhoAnexo,
    required String pedidoId,
    required String dadosPedidoJson,
    required bool modoLoja,
    String? lojaId,
    String? nomeLoja,
    String? logoLoja,
    String? operadorNome,
    String? operadorCpf,
    String? usuarioNome,
    String? usuarioCpf,
    String? usuarioFoto,
    required AuthProvider auth,
    required String Function(MensagemChat) resumoMensagem,
    required bool Function() isDisposed,
    required ConversaChat? Function() getConversaSelecionada,
    required void Function(ConversaChat) onConversaAtualizada,
  }) {
    final conversaBase = MensageriaMensagemHelper.criarNovaMensagem(
      conversa: conversaSelecionada,
      texto: texto,
      tipo: tipo,
      caminhoAnexo: caminhoAnexo,
      nomeAnexo: nomeAnexo,
      tamanhoAnexo: tamanhoAnexo,
      pedidoId: pedidoId,
      dadosPedidoJson: dadosPedidoJson,
      modoLoja: modoLoja,
      lojaId: lojaId,
      nomeLoja: nomeLoja,
      logoLoja: logoLoja,
      operadorNome: operadorNome,
      operadorCpf: operadorCpf,
      usuarioNome: usuarioNome,
      usuarioCpf: usuarioCpf,
      usuarioFoto: usuarioFoto,
      auth: auth,
    );
    final novaMensagem = aplicarRespostaSeHouver(
      conversaBase,
      mensagemRespondendo,
    );

    final resumo = resumoMensagem(novaMensagem);
    final integrada = MensageriaMensagemHelper.integrarNovaMensagemNaConversa(
      conversa: conversaSelecionada,
      novaMensagem: novaMensagem,
      resumo: resumo,
    );
    MensageriaMensagemHelper.atualizarListaConversasComNova(conversas, integrada);
    onConversaAtualizada(integrada);

    ChatService.enviarMensagemInstantanea(novaMensagem).then((msgSalva) {
      if (isDisposed()) return;
      final ativa = getConversaSelecionada();
      if (ativa?.id == novaMensagem.conversaId && ativa != null) {
        final atualizada = substituirMensagemSalva(
          conversa: ativa,
          mensagemId: novaMensagem.id,
          msgSalva: msgSalva,
        );
        if (atualizada != null) {
          onConversaAtualizada(atualizada);
        }
      }
    });
  }

  static void iniciarPersistenciaConversaNova({
    required String convId,
    required String titulo,
    required String subtitulo,
    required String identificador,
    required String foto,
    required bool ehLoja,
    required bool ehConvLojaUsuario,
    required bool modoLoja,
    String? lojaId,
    String? lojaIdResolvido,
    String? usuarioCpf,
    required String idVisualizador,
    required String Function(MensagemChat) resumoMensagem,
    required bool Function() isDisposed,
    required void Function(ConversaChat) onConversaHidratada,
    required Future<void> Function(ConversaChat) onMarcarComoLida,
  }) {
    salvarUltimaConversaAberta(
      convId: convId,
      modoLoja: modoLoja,
      lojaId: lojaId,
      usuarioCpf: usuarioCpf,
    );
    unawaited(
      MensageriaSelecaoHelper.carregarOuPersistirConversaNova(
        convId: convId,
        titulo: titulo,
        subtitulo: subtitulo,
        identificador: identificador,
        foto: foto,
        ehLoja: ehLoja || ehConvLojaUsuario,
        modoLoja: modoLoja,
        lojaId: lojaIdResolvido ?? (modoLoja ? lojaId : null),
        usuarioCpf: usuarioCpf,
        idVisualizador: idVisualizador,
        resumoMensagem: resumoMensagem,
        isDisposed: isDisposed,
        onConversaHidratada: onConversaHidratada,
        onMarcarComoLida: onMarcarComoLida,
      ),
    );
  }

  static Future<({bool alterou, ConversaChat? selecionada})>
      marcarConversaComoLida({
    required ConversaChat conversa,
    required List<ConversaChat> conversas,
    required ConversaChat? selecionadaAtual,
    required String idVisualizador,
    required bool Function() isDisposed,
  }) async {
    NotificacaoAndroidService.cancelarNotificacaoConversa(conversa.id);
    await ChatService.marcarComoLidas(
      conversa.id,
      idVisualizador,
      notificar: true,
    );
    if (isDisposed()) return (alterou: false, selecionada: selecionadaAtual);
    final idx = conversas.indexWhere((c) => c.id == conversa.id);
    if (idx != -1 && conversas[idx].naoLidasCount > 0) {
      conversas[idx] = conversas[idx].copyWith(naoLidasCount: 0);
      final novaSelecionada = selecionadaAtual?.id == conversa.id
          ? selecionadaAtual?.copyWith(naoLidasCount: 0)
          : selecionadaAtual;
      return (alterou: true, selecionada: novaSelecionada);
    }
    return (alterou: false, selecionada: selecionadaAtual);
  }
}
