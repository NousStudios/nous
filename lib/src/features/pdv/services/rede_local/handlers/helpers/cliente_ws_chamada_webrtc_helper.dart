import 'package:flutter/foundation.dart';
import 'package:nous/src/features/chat/services/chamada_webrtc_service.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';

/// Processa sinais WebRTC de áudio e vídeo recebidos via WebSocket no cliente.
class ClienteWsChamadaWebRtcHelper {
  /// Roteia pacotes WebRTC de chamada recebidos via WebSocket.
  static void processarSinalChamada({
    required Map<String, dynamic> dados,
    required String meuCpf,
    required List<Loja>? lojasLocal,
  }) {
    try {
      final tipo = dados['tipo'] as String?;

      if (tipo == 'chamada_iniciar') {
        final chamadaJson = dados['chamada'] as Map<String, dynamic>?;
        final sdp = dados['sdp'] as Map<String, dynamic>?;
        if (chamadaJson != null && sdp != null) {
          final destId =
              (chamadaJson['destinatarioId'] as String? ?? '').replaceAll(RegExp(r'\D'), '');
          final participantes = (chamadaJson['participantesIds'] as List<dynamic>?)
                  ?.map((e) => e.toString().replaceAll(RegExp(r'\D'), ''))
                  .toList() ??
              [];
          final destEhLojaLocal = destId.isNotEmpty &&
              (lojasLocal?.any(
                    (l) =>
                        PdvProvider.normalizarIdLoja(l.id) == destId &&
                        (ChatService.normalizarCpf(l.cpfDonoOriginal) == meuCpf ||
                            l.membros.any(
                              (m) => ChatService.normalizarCpf(m.cpf) == meuCpf,
                            )),
                  ) ??
                  false);

          if (destId == meuCpf ||
              destEhLojaLocal ||
              participantes.contains(meuCpf) ||
              destId.isEmpty) {
            ChamadaWebRtcService.instancia.receberConvite(chamadaJson, sdp);
          }
        }
      } else if (tipo == 'chamada_aceita') {
        final sdp = dados['sdp'] as Map<String, dynamic>?;
        if (sdp != null) {
          ChamadaWebRtcService.instancia.receberRespostaAceita(sdp);
        }
      } else if (tipo == 'chamada_renegociar_oferta') {
        ChamadaWebRtcService.instancia.receberRenegociacaoOferta(dados);
      } else if (tipo == 'chamada_renegociar_resposta') {
        final sdp = dados['sdp'] as Map<String, dynamic>?;
        if (sdp != null) {
          ChamadaWebRtcService.instancia.receberRenegociacaoResposta(sdp);
        }
      } else if (tipo == 'chamada_candidato_ice') {
        final candidate = dados['candidate'] as Map<String, dynamic>?;
        if (candidate != null) {
          ChamadaWebRtcService.instancia.receberCandidatoIce(candidate);
        }
      } else if (tipo == 'chamada_rejeitada' || tipo == 'chamada_encerrada') {
        ChamadaWebRtcService.instancia.encerrarChamada(notificarRede: false);
      }
    } catch (e) {
      debugPrint('[ClienteWsMessageHandler] Erro ao processar sinal de chamada: $e');
    }
  }
}
