import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';

/// Helper especialista para ações de histórico, mensagens e conversas
/// (favoritar, fixar, reagir, renomear, excluir, silenciar).
class MensageriaAcoesMensagemHelper {
  MensageriaAcoesMensagemHelper._();

  static Future<void> alternarFavoritar({
    required MensagemChat msg,
    required ConversaChat? conversaSelecionada,
    required void Function(ConversaChat novaConversa) onAtualizarConversa,
  }) async {
    final novaFavorita = !msg.favorita;
    final msgAtualizada = msg.copyWith(favorita: novaFavorita);

    if (conversaSelecionada != null && conversaSelecionada.id == msg.conversaId) {
      final msgs = List<MensagemChat>.from(conversaSelecionada.mensagens);
      final idx = msgs.indexWhere((m) => m.id == msg.id);
      if (idx != -1) {
        msgs[idx] = msgAtualizada;
        onAtualizarConversa(conversaSelecionada.copyWith(mensagens: msgs));
      }
    }
    await ChatService.alternarFavoritaMensagem(msg.id);
  }

  static Future<void> alternarFixar({
    required MensagemChat msg,
    required ConversaChat? conversaSelecionada,
    required void Function(ConversaChat novaConversa) onAtualizarConversa,
  }) async {
    final novaFixada = !msg.fixada;
    final msgAtualizada = msg.copyWith(fixada: novaFixada);

    if (conversaSelecionada != null && conversaSelecionada.id == msg.conversaId) {
      final msgs = List<MensagemChat>.from(conversaSelecionada.mensagens);
      final idx = msgs.indexWhere((m) => m.id == msg.id);
      if (idx != -1) {
        msgs[idx] = msgAtualizada;
        onAtualizarConversa(conversaSelecionada.copyWith(mensagens: msgs));
      }
    }
    await ChatService.alternarFixarMensagem(
      msg.id,
      fixar: novaFixada,
      conversaId: msg.conversaId,
    );
  }

  static Future<void> reagir({
    required MensagemChat msg,
    required String emoji,
    required bool modoLoja,
    required String? lojaId,
    required String? usuarioCpf,
    required ConversaChat? conversaSelecionada,
    required void Function(ConversaChat novaConversa) onAtualizarConversa,
  }) async {
    final meuId = modoLoja ? (lojaId ?? '') : (usuarioCpf ?? '');
    final mapa = Map<String, String>.from(msg.reacoes);
    if (emoji.isEmpty || mapa[meuId] == emoji) {
      mapa.remove(meuId);
    } else {
      mapa[meuId] = emoji;
    }
    final msgAtualizada = msg.copyWith(reacoes: mapa);

    if (conversaSelecionada != null && conversaSelecionada.id == msg.conversaId) {
      final msgs = List<MensagemChat>.from(conversaSelecionada.mensagens);
      final idx = msgs.indexWhere((m) => m.id == msg.id);
      if (idx != -1) {
        msgs[idx] = msgAtualizada;
        onAtualizarConversa(conversaSelecionada.copyWith(mensagens: msgs));
      }
    }
    await ChatService.reagirMensagem(
      msg.id,
      meuId,
      emoji,
      conversaId: msg.conversaId,
    );
  }

  static Future<void> editar({
    required MensagemChat msg,
    required String novoTexto,
    required ConversaChat? conversaSelecionada,
    required void Function(ConversaChat novaConversa) onAtualizarConversa,
  }) async {
    final agora = DateTime.now();
    final historicoAtualizado = List<Map<String, dynamic>>.from(msg.historicoEdicoes)
      ..add({
        'textoAnterior': msg.texto,
        'dataHoraEdicao': agora.toIso8601String(),
      });

    final msgEditada = msg.copyWith(
      texto: novoTexto,
      editada: true,
      historicoEdicoes: historicoAtualizado,
    );

    if (conversaSelecionada != null && conversaSelecionada.id == msg.conversaId) {
      final msgs = List<MensagemChat>.from(conversaSelecionada.mensagens);
      final index = msgs.indexWhere((m) => m.id == msg.id);
      if (index != -1) {
        msgs[index] = msgEditada;
        onAtualizarConversa(conversaSelecionada.copyWith(mensagens: msgs));
      }
    }
    await ChatService.salvarMensagem(msgEditada);
  }

  static Future<void> excluir({
    required MensagemChat msg,
    required ConversaChat? conversaSelecionada,
    required void Function(ConversaChat novaConversa) onAtualizarConversa,
  }) async {
    if (conversaSelecionada != null && conversaSelecionada.id == msg.conversaId) {
      final msgs = List<MensagemChat>.from(conversaSelecionada.mensagens)
        ..removeWhere((m) => m.id == msg.id);
      onAtualizarConversa(conversaSelecionada.copyWith(mensagens: msgs));
    }
    await ChatService.excluirMensagem(msg.id);
  }
}
