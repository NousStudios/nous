import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:nous/src/core/services/gerador_id.dart';
import 'package:nous/src/core/services/navigator_key_service.dart';
import 'package:nous/src/features/chat/models/chamada_sessao.dart';
import 'package:nous/src/features/chat/views/widgets/dialog_chamada_recebida.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

/// Serviço de alta performance para chamadas de áudio e vídeo P2P via WebRTC
/// utilizando a malha da rede local Wi-Fi para sinalização e transmissão de mídia.
class ChamadaWebRtcService {
  ChamadaWebRtcService._();
  static final ChamadaWebRtcService instancia = ChamadaWebRtcService._();

  final ValueNotifier<ChamadaSessao?> sessaoAtiva =
      ValueNotifier<ChamadaSessao?>(null);

  final RTCVideoRenderer renderizadorLocal = RTCVideoRenderer();
  final RTCVideoRenderer renderizadorRemoto = RTCVideoRenderer();

  RTCPeerConnection? _peerConnection;
  MediaStream? _streamLocal;
  MediaStream? _streamRemoto;

  bool _renderersInicializados = false;
  bool microfoneMutado = false;
  bool cameraDesativada = false;
  bool vivaVozAtivo = true;
  final ValueNotifier<bool> cameraFrontalAtiva = ValueNotifier<bool>(true);

  // Callback acionado pela interface quando uma chamada for recebida
  void Function(ChamadaSessao sessao)? onChamadaRecebida;
  void Function()? onChamadaEncerrada;

  final Map<String, dynamic> _configuracaoWebRtc = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  final Map<String, dynamic> _restricoesLoopback = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  Future<void> inicializarRenderers() async {
    if (_renderersInicializados) return;
    try {
      await renderizadorLocal.initialize();
      await renderizadorRemoto.initialize();
      _renderersInicializados = true;
    } catch (e) {
      debugPrint('[ChamadaWebRtcService] Erro ao inicializar renderers: $e');
    }
  }

  /// Inicia uma chamada de voz ou vídeo para um contato ou grupo
  Future<ChamadaSessao?> iniciarChamada({
    required String conversaId,
    required TipoChamada tipo,
    required String meuCpf,
    required String meuNome,
    String minhaFoto = '',
    required String destinatarioId,
    required String destinatarioNome,
    String destinatarioFoto = '',
    bool ehGrupo = false,
    List<String> participantesIds = const [],
  }) async {
    await inicializarRenderers();
    await encerrarChamada(notificarRede: false);

    final chamadaId = 'call_${gerarIdUnico()}';

    final sessao = ChamadaSessao(
      id: chamadaId,
      conversaId: conversaId,
      tipo: tipo,
      estado: EstadoChamada.chamando,
      remetenteId: meuCpf,
      remetenteNome: meuNome,
      remetenteFoto: minhaFoto,
      destinatarioId: destinatarioId,
      destinatarioNome: destinatarioNome,
      destinatarioFoto: destinatarioFoto,
      ehGrupo: ehGrupo,
      participantesIds: participantesIds,
      videoHabilitado: tipo == TipoChamada.video,
      audioHabilitado: true,
      iniciadaEm: DateTime.now(),
    );

    sessaoAtiva.value = sessao;
    microfoneMutado = false;
    cameraDesativada = tipo != TipoChamada.video;

    try {
      _peerConnection = await createPeerConnection(
        _configuracaoWebRtc,
        _restricoesLoopback,
      );

      _configurarListenersPeerConnection(chamadaId);

      // Obtém stream local de áudio e câmera
      final mediaConstraints = <String, dynamic>{
        'audio': true,
        'video': tipo == TipoChamada.video
            ? {
                'facingMode': 'user',
                'width': {'ideal': 1280},
                'height': {'ideal': 720},
              }
            : false,
      };

      _streamLocal =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);
      renderizadorLocal.srcObject = _streamLocal;

      for (final track in _streamLocal!.getTracks()) {
        await _peerConnection!.addTrack(track, _streamLocal!);
      }

      // Cria a oferta SDP
      final RTCSessionDescription offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': tipo == TipoChamada.video ? 1 : 0,
      });

      await _peerConnection!.setLocalDescription(offer);

      // Despacha o convite de chamada com o SDP Offer pela rede local
      _enviarSinalizacao({
        'tipo': 'chamada_iniciar',
        'chamada': sessao.toJson(),
        'sdp': {'sdp': offer.sdp, 'type': offer.type},
      });

      return sessao;
    } catch (e) {
      debugPrint('[ChamadaWebRtcService] Erro ao iniciar chamada: $e');
      await encerrarChamada(notificarRede: true);
      return null;
    }
  }

  /// Processa um convite de chamada recebido de outro terminal
  Future<void> receberConvite(
    Map<String, dynamic> dadosChamada,
    Map<String, dynamic> sdpOferta,
  ) async {
    final sessao = ChamadaSessao.fromJson(dadosChamada)
        .copyWith(estado: EstadoChamada.tocando);

    // Se já estiver em outra chamada, rejeita automaticamente com ocupado
    if (sessaoAtiva.value != null &&
        sessaoAtiva.value!.estado == EstadoChamada.conectada) {
      _enviarSinalizacao({
        'tipo': 'chamada_rejeitada',
        'chamadaId': sessao.id,
        'motivo': 'ocupado',
      });
      return;
    }

    sessaoAtiva.value = sessao;
    await inicializarRenderers();

    if (onChamadaRecebida != null) {
      onChamadaRecebida!(sessao);
    } else {
      final context = NavigatorKeyService.currentContext;
      if (context != null && context.mounted) {
        DialogChamadaRecebida.exibir(
          context,
          sessao: sessao,
          sdpOferta: sdpOferta,
        );
      }
    }
  }

  /// Atende a chamada recebida
  Future<bool> aceitarChamada(Map<String, dynamic> sdpOferta) async {
    final sessao = sessaoAtiva.value;
    if (sessao == null) return false;

    try {
      sessaoAtiva.value = sessao.copyWith(estado: EstadoChamada.conectada);

      _peerConnection = await createPeerConnection(
        _configuracaoWebRtc,
        _restricoesLoopback,
      );

      _configurarListenersPeerConnection(sessao.id);

      final mediaConstraints = <String, dynamic>{
        'audio': true,
        'video': sessao.tipo == TipoChamada.video
            ? {
                'facingMode': 'user',
                'width': {'ideal': 1280},
                'height': {'ideal': 720},
              }
            : false,
      };

      _streamLocal =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);
      renderizadorLocal.srcObject = _streamLocal;

      for (final track in _streamLocal!.getTracks()) {
        await _peerConnection!.addTrack(track, _streamLocal!);
      }

      // Aplica a oferta SDP remota
      final description = RTCSessionDescription(
        sdpOferta['sdp'] as String?,
        sdpOferta['type'] as String?,
      );
      await _peerConnection!.setRemoteDescription(description);

      // Cria e aplica resposta SDP
      final answer = await _peerConnection!.createAnswer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': sessao.tipo == TipoChamada.video ? 1 : 0,
      });
      await _peerConnection!.setLocalDescription(answer);

      // Avisa ao chamador que a ligação foi aceita e transmite a resposta SDP
      _enviarSinalizacao({
        'tipo': 'chamada_aceita',
        'chamadaId': sessao.id,
        'sdp': {'sdp': answer.sdp, 'type': answer.type},
      });

      return true;
    } catch (e) {
      debugPrint('[ChamadaWebRtcService] Erro ao aceitar chamada: $e');
      await encerrarChamada(notificarRede: true);
      return false;
    }
  }

  /// Processa a resposta SDP (Answer) vinda de quem atendeu
  Future<void> receberRespostaAceita(Map<String, dynamic> sdpResposta) async {
    if (_peerConnection == null) return;
    try {
      final description = RTCSessionDescription(
        sdpResposta['sdp'] as String?,
        sdpResposta['type'] as String?,
      );
      await _peerConnection!.setRemoteDescription(description);

      if (sessaoAtiva.value != null) {
        sessaoAtiva.value = sessaoAtiva.value!.copyWith(
          estado: EstadoChamada.conectada,
        );
      }
    } catch (e) {
      debugPrint('[ChamadaWebRtcService] Erro ao aplicar SDP de resposta: $e');
    }
  }

  /// Aplica candidato ICE remoto
  Future<void> receberCandidatoIce(Map<String, dynamic> candidatoJson) async {
    if (_peerConnection == null) return;
    try {
      final candidate = RTCIceCandidate(
        candidatoJson['candidate'] as String?,
        candidatoJson['sdpMid'] as String?,
        candidatoJson['sdpMLineIndex'] as int?,
      );
      await _peerConnection!.addCandidate(candidate);
    } catch (e) {
      debugPrint('[ChamadaWebRtcService] Erro ao adicionar ICE candidate: $e');
    }
  }

  /// Rejeita uma chamada recebida
  Future<void> rejeitarChamada() async {
    final sessao = sessaoAtiva.value;
    if (sessao != null) {
      _enviarSinalizacao({
        'tipo': 'chamada_rejeitada',
        'chamadaId': sessao.id,
      });
    }
    await encerrarChamada(notificarRede: false);
  }

  /// Encerra a chamada ativa e limpa recursos de hardware
  Future<void> encerrarChamada({bool notificarRede = true}) async {
    final sessao = sessaoAtiva.value;
    if (sessao != null && notificarRede) {
      _enviarSinalizacao({
        'tipo': 'chamada_encerrada',
        'chamadaId': sessao.id,
      });
    }

    try {
      _streamLocal?.getTracks().forEach((track) {
        track.stop();
      });
      await _streamLocal?.dispose();
      _streamLocal = null;
    } catch (_) {}

    try {
      await _peerConnection?.close();
      _peerConnection = null;
    } catch (_) {}

    renderizadorLocal.srcObject = null;
    renderizadorRemoto.srcObject = null;
    _streamRemoto = null;

    sessaoAtiva.value = null;

    if (onChamadaEncerrada != null) {
      onChamadaEncerrada!();
    }
  }

  // --- Controles de Áudio e Câmera ---

  void alternarMicrofone() {
    if (_streamLocal == null) return;
    final audioTracks = _streamLocal!.getAudioTracks();
    if (audioTracks.isNotEmpty) {
      microfoneMutado = !microfoneMutado;
      audioTracks.first.enabled = !microfoneMutado;
      if (sessaoAtiva.value != null) {
        sessaoAtiva.value = sessaoAtiva.value!.copyWith(
          audioHabilitado: !microfoneMutado,
        );
      }
    }
  }

  Future<void> alternarCamera() async {
    if (_streamLocal == null) return;
    final videoTracks = _streamLocal!.getVideoTracks();
    if (videoTracks.isEmpty) {
      try {
        final videoStream = await navigator.mediaDevices.getUserMedia({
          'audio': false,
          'video': {
            'facingMode': cameraFrontalAtiva.value ? 'user' : 'environment',
            'width': {'ideal': 1280},
            'height': {'ideal': 720},
          },
        });
        for (final track in videoStream.getVideoTracks()) {
          _streamLocal!.addTrack(track);
          if (_peerConnection != null) {
            await _peerConnection!.addTrack(track, _streamLocal!);
          }
        }
        cameraDesativada = false;
        if (sessaoAtiva.value != null) {
          sessaoAtiva.value = sessaoAtiva.value!.copyWith(
            videoHabilitado: true,
          );
        }
        return;
      } catch (e) {
        debugPrint('[ChamadaWebRtcService] Erro ao obter vídeo na chamada de voz: $e');
        return;
      }
    }

    cameraDesativada = !cameraDesativada;
    videoTracks.first.enabled = !cameraDesativada;
    if (sessaoAtiva.value != null) {
      sessaoAtiva.value = sessaoAtiva.value!.copyWith(
        videoHabilitado: !cameraDesativada,
      );
    }
  }

  Future<void> alternarVivaVoz() async {
    if (_streamLocal == null) return;
    vivaVozAtivo = !vivaVozAtivo;
    try {
      await Helper.setSpeakerphoneOn(vivaVozAtivo);
    } catch (_) {}
  }

  Future<void> alternarCameraFrontalTraseira() async {
    if (_streamLocal == null) return;
    final videoTracks = _streamLocal!.getVideoTracks();
    if (videoTracks.isNotEmpty) {
      try {
        await Helper.switchCamera(videoTracks.first);
        cameraFrontalAtiva.value = !cameraFrontalAtiva.value;
      } catch (e) {
        debugPrint('[ChamadaWebRtcService] Erro ao alternar câmera: $e');
      }
    }
  }

  void _configurarListenersPeerConnection(String chamadaId) {
    if (_peerConnection == null) return;

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null) {
        _enviarSinalizacao({
          'tipo': 'chamada_candidato_ice',
          'chamadaId': chamadaId,
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        });
      }
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _streamRemoto = event.streams[0];
        renderizadorRemoto.srcObject = _streamRemoto;
        debugPrint(
          '[ChamadaWebRtcService] Stream remoto recebido com sucesso!',
        );
      }
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint('[ChamadaWebRtcService] Estado de conexão WebRTC: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        if (sessaoAtiva.value != null) {
          sessaoAtiva.value = sessaoAtiva.value!.copyWith(
            estado: EstadoChamada.conectada,
          );
        }
      } else if (state ==
              RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        encerrarChamada(notificarRede: false);
      }
    };
  }

  /// Despacha sinais de chamada pelo WebSocket ativo (via Servidor ou Cliente)
  void _enviarSinalizacao(Map<String, dynamic> sinal) {
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
}
