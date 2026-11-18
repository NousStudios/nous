import 'package:flutter/foundation.dart';
import 'package:nous/src/features/chat/models/chamada_sessao.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';

/// Registra o resumo da chamada (duração, recusada ou perdida) no histórico da conversa.
class ChamadaHistoricoService {
  ChamadaHistoricoService._();

  static String formatarDuracao(int segundos) {
    final m = (segundos ~/ 60).toString().padLeft(2, '0');
    final s = (segundos % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static Future<void> registrarEncerramento({
    required ChamadaSessao sessao,
    required bool foiConectada,
    required int duracaoSegundos,
    required bool rejeitada,
    required bool ehChamadorLocal,
  }) async {
    if (sessao.conversaId.isEmpty) return;

    // Apenas o chamador registra chamadas conectadas/perdidas (ou quem rejeitou,
    // caso o chamador não tenha recebido o aviso a tempo), usando ID determinístico.
    if (!ehChamadorLocal && !rejeitada) return;

    final prefixo = sessao.tipo == TipoChamada.video
        ? '📹 Chamada de vídeo'
        : '📞 Chamada de voz';

    final String texto;
    if (foiConectada) {
      texto = '$prefixo — ${formatarDuracao(duracaoSegundos)}';
    } else if (rejeitada) {
      texto = '$prefixo recusada';
    } else {
      texto = '$prefixo perdida';
    }

    final mensagem = MensagemChat(
      id: 'chamada_${sessao.id}',
      conversaId: sessao.conversaId,
      remetenteId: sessao.remetenteId,
      remetenteNome: sessao.remetenteNome,
      remetenteFoto: sessao.remetenteFoto,
      destinatarioId: sessao.destinatarioId,
      texto: texto,
      dataHora: DateTime.now(),
      enviadaPorMim: ehChamadorLocal,
      lida: true,
      tipo: 'texto',
    );

    try {
      await ChatService.enviarMensagemInstantanea(mensagem);
    } catch (e) {
      debugPrint('[ChamadaHistoricoService] Erro ao registrar chamada no chat: $e');
    }
  }
}
