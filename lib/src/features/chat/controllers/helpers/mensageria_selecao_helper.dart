import 'dart:async';

import 'package:nous/src/features/chat/controllers/helpers/mensageria_solicitacoes_helper.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';

/// Helper para persistência e hidratação assíncrona ao selecionar/iniciar conversas.
class MensageriaSelecaoHelper {
  MensageriaSelecaoHelper._();

  static Future<void> carregarOuPersistirConversaNova({
    required String convId,
    required String titulo,
    required String subtitulo,
    required String identificador,
    required String foto,
    required bool ehLoja,
    required bool modoLoja,
    required String? lojaId,
    required String? usuarioCpf,
    required String idVisualizador,
    required String Function(MensagemChat) resumoMensagem,
    required bool Function() isDisposed,
    required void Function(ConversaChat conversa) onConversaHidratada,
    required Future<void> Function(ConversaChat conversa) onMarcarComoLida,
  }) async {
    try {
      await ChatService.desmarcarConversaExcluida(convId);
      final conversaBase = await ChatService.obterOuCriarConversa(
        id: convId,
        titulo: titulo,
        subtitulo: subtitulo,
        identificador: identificador,
        foto: foto,
        ehLoja: ehLoja,
        lojaId: lojaId ?? (modoLoja ? lojaId : null),
        cpfUsuario: modoLoja ? null : usuarioCpf,
      );
      if (isDisposed()) return;

      final msgs = await ChatService.carregarMensagens(
        convId,
        idVisualizador: idVisualizador,
      );
      if (isDisposed()) return;

      final conversa = conversaBase.copyWith(
        mensagens: msgs,
        ultimaMensagem: msgs.isNotEmpty
            ? resumoMensagem(msgs.last)
            : conversaBase.ultimaMensagem,
        dataHoraUltimaMensagem: msgs.isNotEmpty
            ? msgs.last.dataHora
            : conversaBase.dataHoraUltimaMensagem,
        naoLidasCount: 0,
      );

      onConversaHidratada(conversa);

      final meuNorm = ChatService.normalizarCpf(usuarioCpf ?? '');
      if (!modoLoja &&
          meuNorm.isNotEmpty &&
          msgs.any((m) => ChatService.normalizarCpf(m.remetenteId) == meuNorm)) {
        unawaited(MensageriaSolicitacoesHelper.aceitarSolicitacao(
          conversaId: convId,
          meuCpf: meuNorm,
        ));
      }
      ChatService.despacharConversaAtualizada(conversa);
      await onMarcarComoLida(conversa);
    } catch (_) {}
  }
}
