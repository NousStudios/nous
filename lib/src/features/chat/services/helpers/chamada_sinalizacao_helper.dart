import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:nous/src/features/chat/models/chamada_sessao.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

/// Helper responsável pela configuração WebRTC, negociação SDP/ICE e
/// despacho de sinalização na malha da rede local.
class ChamadaSinalizacaoHelper {
  ChamadaSinalizacaoHelper._();

  static const Map<String, dynamic> configuracaoWebRtc = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  static const Map<String, dynamic> restricoesLoopback = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  /// Despacha sinais de chamada pelo WebSocket ativo (via Servidor ou Cliente).
  static void enviarSinalizacao(Map<String, dynamic> sinal) {
    final servidor = ServidorRedeLocal();
    if (servidor.ativo) {
      servidor.notificarTodos(sinal);
      return;
    }

    final cliente = ClienteRedeLocal();
    if (cliente.conectado) {
      cliente.enviarMensagemRaw(sinal);
    }
  }

  /// Cria a oferta SDP inicial e envia o convite de chamada pela rede local.
  static Future<void> enviarOfertaInicial(
    RTCPeerConnection pc,
    ChamadaSessao sessao,
  ) async {
    final RTCSessionDescription offer = await pc.createOffer({
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': sessao.tipo == TipoChamada.video ? 1 : 0,
    });
    await pc.setLocalDescription(offer);

    enviarSinalizacao({
      'tipo': 'chamada_iniciar',
      'chamada': sessao.toJson(),
      'sdp': {'sdp': offer.sdp, 'type': offer.type},
    });
  }

  /// Aplica a oferta SDP remota, gera a resposta e envia o aceite ao chamador.
  static Future<void> responderOfertaInicial(
    RTCPeerConnection pc,
    ChamadaSessao sessao,
    Map<String, dynamic> sdpOferta,
  ) async {
    final description = RTCSessionDescription(
      sdpOferta['sdp'] as String?,
      sdpOferta['type'] as String?,
    );
    await pc.setRemoteDescription(description);

    final answer = await pc.createAnswer({
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': sessao.tipo == TipoChamada.video ? 1 : 0,
    });
    await pc.setLocalDescription(answer);

    enviarSinalizacao({
      'tipo': 'chamada_aceita',
      'chamadaId': sessao.id,
      'sdp': {'sdp': answer.sdp, 'type': answer.type},
    });
  }

  /// Aplica a resposta SDP remota (Answer) na PeerConnection ativa.
  static Future<bool> aplicarRespostaSdp(
    RTCPeerConnection pc,
    Map<String, dynamic> sdpResposta,
  ) async {
    try {
      final description = RTCSessionDescription(
        sdpResposta['sdp'] as String?,
        sdpResposta['type'] as String?,
      );
      await pc.setRemoteDescription(description);
      return true;
    } catch (e) {
      debugPrint(
        '[ChamadaSinalizacaoHelper] Erro ao aplicar SDP de resposta: $e',
      );
      return false;
    }
  }

  /// Adiciona um candidato ICE remoto na PeerConnection ativa.
  static Future<void> adicionarCandidatoIce(
    RTCPeerConnection pc,
    Map<String, dynamic> candidatoJson,
  ) async {
    try {
      final candidate = RTCIceCandidate(
        candidatoJson['candidate'] as String?,
        candidatoJson['sdpMid'] as String?,
        candidatoJson['sdpMLineIndex'] as int?,
      );
      await pc.addCandidate(candidate);
    } catch (e) {
      debugPrint(
        '[ChamadaSinalizacaoHelper] Erro ao adicionar ICE candidate: $e',
      );
    }
  }

  /// Envia um candidato ICE local descoberto para o par remoto.
  static void enviarCandidatoIceLocal(
    String chamadaId,
    RTCIceCandidate candidate,
  ) {
    if (candidate.candidate == null) return;
    enviarSinalizacao({
      'tipo': 'chamada_candidato_ice',
      'chamadaId': chamadaId,
      'candidate': {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      },
    });
  }

  /// Envia oferta de renegociação SDP durante a chamada (câmera ou tela).
  static Future<void> enviarRenegociacaoOferta(
    RTCPeerConnection pc,
    ChamadaSessao sessao,
  ) async {
    try {
      final offer = await pc.createOffer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': 1,
      });
      await pc.setLocalDescription(offer);
      enviarSinalizacao({
        'tipo': 'chamada_renegociar_oferta',
        'chamadaId': sessao.id,
        'videoHabilitado': sessao.videoHabilitado,
        'compartilhandoTela': sessao.compartilhandoTela,
        'sdp': {'sdp': offer.sdp, 'type': offer.type},
      });
    } catch (e) {
      debugPrint(
        '[ChamadaSinalizacaoHelper] Erro ao renegociar mídia: $e',
      );
    }
  }

  /// Processa uma oferta de renegociação recebida e envia a resposta SDP.
  static Future<bool> processarRenegociacaoOferta(
    RTCPeerConnection pc,
    Map<String, dynamic> dados, {
    required String chamadaIdFallback,
  }) async {
    final sdpOferta = dados['sdp'] as Map<String, dynamic>?;
    if (sdpOferta == null) return false;
    try {
      final description = RTCSessionDescription(
        sdpOferta['sdp'] as String?,
        sdpOferta['type'] as String?,
      );
      await pc.setRemoteDescription(description);

      final answer = await pc.createAnswer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': 1,
      });
      await pc.setLocalDescription(answer);

      enviarSinalizacao({
        'tipo': 'chamada_renegociar_resposta',
        'chamadaId': dados['chamadaId'] ?? chamadaIdFallback,
        'sdp': {'sdp': answer.sdp, 'type': answer.type},
      });
      return true;
    } catch (e) {
      debugPrint(
        '[ChamadaSinalizacaoHelper] Erro ao processar renegociação SDP: $e',
      );
      return false;
    }
  }

  /// Envia sinal de rejeição de chamada.
  static void enviarRejeicao(String chamadaId, {String? motivo}) {
    enviarSinalizacao({
      'tipo': 'chamada_rejeitada',
      'chamadaId': chamadaId,
      'motivo': ?motivo,
    });
  }

  /// Envia sinal de encerramento de chamada.
  static void enviarEncerramento(String chamadaId) {
    enviarSinalizacao({
      'tipo': 'chamada_encerrada',
      'chamadaId': chamadaId,
    });
  }
}
