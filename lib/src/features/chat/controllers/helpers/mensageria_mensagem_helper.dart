import 'dart:math';
import 'package:nous/src/core/services/relogio_rede_service.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';

/// Helper especialista para montagem de novas mensagens e ações de envio/edição/reação.
class MensageriaMensagemHelper {
  MensageriaMensagemHelper._();

  static MensagemChat criarNovaMensagem({
    required ConversaChat conversa,
    required String texto,
    required String tipo,
    required String caminhoAnexo,
    required String nomeAnexo,
    required int tamanhoAnexo,
    required String pedidoId,
    required String dadosPedidoJson,
    required bool modoLoja,
    required String? lojaId,
    required String? nomeLoja,
    required String? logoLoja,
    required String? operadorNome,
    required String? operadorCpf,
    required String? usuarioNome,
    required String? usuarioCpf,
    required String? usuarioFoto,
    required AuthProvider auth,
  }) {
    final agora = RelogioRedeService.agora().toLocal();
    var dataHoraEfetiva = agora;
    if (conversa.mensagens.isNotEmpty) {
      final ultimaData = conversa.mensagens.last.dataHora.toLocal();
      if (!dataHoraEfetiva.isAfter(ultimaData)) {
        if (ultimaData.difference(agora).inSeconds > 30) {
          dataHoraEfetiva = agora;
        } else {
          dataHoraEfetiva = ultimaData.add(const Duration(milliseconds: 10));
        }
      }
    }
    final conta = auth.contaAtual;

    final remetenteId = modoLoja
        ? (lojaId != null && lojaId.isNotEmpty
            ? (lojaId.startsWith('loja_') ? lojaId : 'loja_$lojaId')
            : 'loja')
        : (usuarioCpf ?? conta?.cpf ?? 'usuario');
    final remetenteNome = modoLoja
        ? (nomeLoja ?? 'Loja')
        : (usuarioNome ?? conta?.nomeExibicao ?? 'Usuário');
    final atendenteNome = modoLoja
        ? (operadorNome ?? conta?.nomeExibicao ?? 'Atendente')
        : '';
    final remetenteFoto = modoLoja
        ? (logoLoja ?? '')
        : (usuarioFoto ??
            conta?.fotoExibicao ??
            auth.buscarFotoPorCpf(conta?.cpf ?? ''));

    var destinatarioId = conversa.identificador;
    if (conversa.id.startsWith('user_')) {
      final outro = ChatService.extrairOutroCpf(conversa.id, remetenteId);
      if (outro.length == 11) {
        destinatarioId = outro;
      }
    } else if (conversa.id.startsWith('loja_')) {
      if (modoLoja) {
        final cpfCli = ChatService.normalizarCpf(
          conversa.id.split('_usuario_').last,
        );
        if (cpfCli.length == 11) {
          destinatarioId = cpfCli;
        }
      } else {
        destinatarioId = conversa.lojaId?.isNotEmpty == true
            ? conversa.lojaId!
            : conversa.identificador;
      }
    }

    final salt = Random().nextInt(9999);
    return MensagemChat(
      id: 'msg_${dataHoraEfetiva.millisecondsSinceEpoch}_${remetenteId.hashCode.abs()}_$salt',
      conversaId: conversa.id,
      remetenteId: remetenteId,
      remetenteNome: remetenteNome,
      remetenteFoto: remetenteFoto,
      destinatarioId: destinatarioId,
      texto: texto.trim(),
      dataHora: dataHoraEfetiva,
      enviadaPorMim: true,
      nomeAtendente: atendenteNome,
      cpfAtendente: operadorCpf ?? conta?.cpf ?? '',
      lida: false,
      entregue: false,
      statusEnvio: 'enviada',
      tipo: tipo,
      caminhoAnexo: caminhoAnexo,
      nomeAnexo: nomeAnexo,
      tamanhoAnexo: tamanhoAnexo,
      pedidoId: pedidoId,
      dadosPedidoJson: dadosPedidoJson,
    );
  }

  static ConversaChat integrarNovaMensagemNaConversa({
    required ConversaChat conversa,
    required MensagemChat novaMensagem,
    required String resumo,
  }) {
    final msgsAtuais = List<MensagemChat>.from(conversa.mensagens)..add(novaMensagem);
    msgsAtuais.sort((a, b) {
      final cmp = a.dataHora.compareTo(b.dataHora);
      if (cmp != 0) return cmp;
      return a.id.compareTo(b.id);
    });

    return conversa.copyWith(
      mensagens: msgsAtuais,
      ultimaMensagem: resumo,
      dataHoraUltimaMensagem: novaMensagem.dataHora,
      ultimaMensagemEnviadaPorMim: true,
      statusUltimaMensagem: 'enviada',
    );
  }

  static void atualizarListaConversasComNova(
    List<ConversaChat> conversas,
    ConversaChat atualizada,
  ) {
    final idx = conversas.indexWhere((c) => c.id == atualizada.id);
    if (idx != -1) {
      conversas.removeAt(idx);
    }
    conversas.insert(0, atualizada);
  }
}
