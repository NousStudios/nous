import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:nous/src/features/chat/services/chamada_tela_helper.dart';

/// Resultado da inicialização do stream local de áudio/vídeo.
class StreamLocalInicializado {
  const StreamLocalInicializado({
    required this.stream,
    required this.videoSender,
  });

  final MediaStream stream;
  final RTCRtpSender? videoSender;
}

/// Helper responsável pela captura de mídia local, renderizadores,
/// alternância de dispositivos e compartilhamento de tela em chamadas WebRTC.
class ChamadaMidiaHelper {
  ChamadaMidiaHelper._();

  static Map<String, dynamic> _constraintsMidia({
    required bool comVideo,
    bool cameraFrontal = true,
  }) {
    return <String, dynamic>{
      'audio': true,
      'video': comVideo
          ? {
              'facingMode': cameraFrontal ? 'user' : 'environment',
              'width': {'ideal': 1280},
              'height': {'ideal': 720},
            }
          : false,
    };
  }

  /// Obtém o stream local de áudio/câmera, vincula ao renderizador e adiciona
  /// as tracks na PeerConnection.
  static Future<StreamLocalInicializado> obterStreamLocalEAdicionarTracks({
    required RTCPeerConnection peerConnection,
    required RTCVideoRenderer renderizadorLocal,
    required bool comVideo,
  }) async {
    final stream = await navigator.mediaDevices.getUserMedia(
      _constraintsMidia(comVideo: comVideo),
    );
    renderizadorLocal.srcObject = stream;

    RTCRtpSender? videoSender;
    for (final track in stream.getTracks()) {
      final sender = await peerConnection.addTrack(track, stream);
      if (track.kind == 'video') {
        videoSender = sender;
      }
    }

    return StreamLocalInicializado(
      stream: stream,
      videoSender: videoSender,
    );
  }

  /// Adiciona uma track de vídeo a um stream local já existente (upgrade voz -> vídeo).
  static Future<RTCRtpSender?> adicionarVideoAoStreamLocal({
    required MediaStream streamLocal,
    required RTCVideoRenderer renderizadorLocal,
    required RTCPeerConnection? peerConnection,
    required RTCRtpSender? videoSenderAtual,
    required bool cameraFrontal,
  }) async {
    final videoStream = await navigator.mediaDevices.getUserMedia({
      'audio': false,
      'video': {
        'facingMode': cameraFrontal ? 'user' : 'environment',
        'width': {'ideal': 1280},
        'height': {'ideal': 720},
      },
    });
    final track = videoStream.getVideoTracks().first;
    streamLocal.addTrack(track);
    renderizadorLocal.srcObject = streamLocal;

    if (peerConnection != null) {
      if (videoSenderAtual != null) {
        await videoSenderAtual.replaceTrack(track);
        return videoSenderAtual;
      }
      return peerConnection.addTrack(track, streamLocal);
    }
    return videoSenderAtual;
  }

  /// Inicia a captura de tela e vincula a track ao sender de vídeo.
  static Future<({MediaStream stream, RTCRtpSender? videoSender})?>
      iniciarCapturaTela({
    required RTCPeerConnection peerConnection,
    required RTCVideoRenderer renderizadorLocal,
    required RTCRtpSender? videoSenderAtual,
    required VoidCallback onTelaEncerrada,
  }) async {
    final telaStream = await ChamadaTelaHelper.capturarTela();
    if (telaStream == null) {
      await ChamadaTelaHelper.pararServicoAndroid();
      return null;
    }

    final tracks = telaStream.getVideoTracks();
    if (tracks.isEmpty) {
      await telaStream.dispose();
      return null;
    }

    final screenTrack = tracks.first;
    screenTrack.onEnded = onTelaEncerrada;
    renderizadorLocal.srcObject = telaStream;

    RTCRtpSender? sender = videoSenderAtual;
    if (sender != null) {
      await sender.replaceTrack(screenTrack);
    } else {
      sender = await peerConnection.addTrack(screenTrack, telaStream);
    }

    return (stream: telaStream, videoSender: sender);
  }

  /// Para todas as tracks e descarta um MediaStream com segurança.
  static Future<void> encerrarStream(MediaStream? stream) async {
    if (stream == null) return;
    try {
      for (final track in stream.getTracks()) {
        track.stop();
      }
      await stream.dispose();
    } catch (_) {}
  }

  /// Alterna a câmera local (adiciona track de vídeo em chamada de voz ou
  /// habilita/desabilita a track existente).
  static Future<
      ({
        bool cameraDesativada,
        RTCRtpSender? videoSender,
        bool virouChamadaVideo,
      })?> alternarCamera({
    required MediaStream streamLocal,
    required RTCVideoRenderer renderizadorLocal,
    required RTCPeerConnection? peerConnection,
    required RTCRtpSender? videoSenderAtual,
    required bool cameraDesativadaAtual,
    required bool cameraFrontal,
  }) async {
    final videoTracks = streamLocal.getVideoTracks();
    if (videoTracks.isEmpty) {
      try {
        final novoSender = await adicionarVideoAoStreamLocal(
          streamLocal: streamLocal,
          renderizadorLocal: renderizadorLocal,
          peerConnection: peerConnection,
          videoSenderAtual: videoSenderAtual,
          cameraFrontal: cameraFrontal,
        );
        return (
          cameraDesativada: false,
          videoSender: novoSender,
          virouChamadaVideo: true,
        );
      } catch (e) {
        debugPrint(
          '[ChamadaMidiaHelper] Erro ao obter vídeo na chamada de voz: $e',
        );
        return null;
      }
    }

    final novaDesativada = !cameraDesativadaAtual;
    final track = videoTracks.first;
    track.enabled = !novaDesativada;
    if (!novaDesativada && videoSenderAtual != null) {
      await videoSenderAtual.replaceTrack(track);
      renderizadorLocal.srcObject = streamLocal;
    }

    return (
      cameraDesativada: novaDesativada,
      videoSender: videoSenderAtual,
      virouChamadaVideo: !novaDesativada,
    );
  }

  /// Restaura a track da câmera (ou null) após encerrar o compartilhamento de tela.
  static Future<bool> restaurarCameraAposTela({
    required MediaStream? streamLocal,
    required RTCVideoRenderer renderizadorLocal,
    required RTCRtpSender? videoSender,
    required bool cameraDesativada,
  }) async {
    final camTracks =
        streamLocal?.getVideoTracks() ?? const <MediaStreamTrack>[];
    final temCameraAtiva = camTracks.isNotEmpty && !cameraDesativada;
    if (videoSender != null) {
      await videoSender.replaceTrack(temCameraAtiva ? camTracks.first : null);
    }
    renderizadorLocal.srcObject = streamLocal;
    return temCameraAtiva;
  }

  /// Encerra o stream de compartilhamento de tela e o serviço Android associado.
  static Future<void> pararStreamTela(MediaStream? streamTela) async {
    await encerrarStream(streamTela);
    await ChamadaTelaHelper.pararServicoAndroid();
  }

  /// Alterna o estado do viva-voz do dispositivo.
  static Future<void> definirVivaVoz(bool ativo) async {
    try {
      await Helper.setSpeakerphoneOn(ativo);
    } catch (_) {}
  }

  /// Alterna entre câmera frontal e traseira quando houver track de vídeo ativa.
  static Future<bool> alternarCameraFrontalTraseira(
    MediaStream? streamLocal,
  ) async {
    if (streamLocal == null) return false;
    final videoTracks = streamLocal.getVideoTracks();
    if (videoTracks.isEmpty) return false;

    try {
      await Helper.switchCamera(videoTracks.first);
      return true;
    } catch (e) {
      debugPrint('[ChamadaMidiaHelper] Erro ao alternar câmera: $e');
      return false;
    }
  }
}
