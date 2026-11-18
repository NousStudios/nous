import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:nous/src/core/services/gerador_id.dart';
import 'package:nous/src/core/services/navigator_key_service.dart';
import 'package:nous/src/features/chat/models/chamada_sessao.dart';
import 'package:nous/src/features/chat/services/chamada_historico_service.dart';
import 'package:nous/src/features/chat/services/chamada_som_service.dart';
import 'package:nous/src/features/chat/services/chamada_tela_helper.dart';
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
  MediaStream? _streamTela;
  MediaStream? _streamRemoto;
  RTCRtpSender? _videoSender;

  bool _renderersInicializados = false;
  bool microfoneMutado = false;
  bool cameraDesativada = false;
  bool compartilhandoTela = false;
  bool vivaVozAtivo = true;
  final ValueNotifier<bool> cameraFrontalAtiva = ValueNotifier<bool>(true);
  final ValueNotifier<bool> videoRemotoAtivo = ValueNotifier<bool>(false);
  final ValueNotifier<bool> telaRemotaAtiva = ValueNotifier<bool>(false);
  final ValueNotifier<bool> chamadaMinimizada = ValueNotifier<bool>(false);
  final ValueNotifier<int> segundosChamada = ValueNotifier<int>(0);
  /// 'normal', 'reconectando' ou 'instavel'
  final ValueNotifier<String> statusConexao = ValueNotifier<String>('normal');

  Timer? _timerTimeoutChamada;
  Timer? _timerDuracao;
  Timer? _timerReconexao;
  bool _ehChamadorLocal = false;
  bool _foiConectada = false;
  bool _foiRejeitada = false;

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
    compartilhandoTela = false;
    chamadaMinimizada.value = false;
    segundosChamada.value = 0;
    statusConexao.value = 'normal';
    _ehChamadorLocal = true;
    _foiConectada = false;
    _foiRejeitada = false;
    videoRemotoAtivo.value = tipo == TipoChamada.video;
    telaRemotaAtiva.value = false;
    _iniciarTimeoutChamada(chamadaId);
    unawaited(ChamadaSomService.instancia.iniciarToqueChamando());
    unawaited(
      ChamadaTelaHelper.iniciarServicoChamadaAndroid(
        nomeContato: destinatarioNome,
        ehVideo: tipo == TipoChamada.video,
      ),
    );

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
        final sender = await _peerConnection!.addTrack(track, _streamLocal!);
        if (track.kind == 'video') {
          _videoSender = sender;
        }
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
    chamadaMinimizada.value = false;
    segundosChamada.value = 0;
    statusConexao.value = 'normal';
    _ehChamadorLocal = false;
    _foiConectada = false;
    _foiRejeitada = false;
    _iniciarTimeoutChamada(sessao.id);
    unawaited(ChamadaSomService.instancia.iniciarToqueRecebida());
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
      _cancelarTimeoutChamada();
      unawaited(ChamadaSomService.instancia.pararToque());
      _foiConectada = true;
      _iniciarCronometroChamada();
      sessaoAtiva.value = sessao.copyWith(estado: EstadoChamada.conectada);
      unawaited(
        ChamadaTelaHelper.iniciarServicoChamadaAndroid(
          nomeContato: sessao.remetenteNome.isNotEmpty
              ? sessao.remetenteNome
              : sessao.destinatarioNome,
          ehVideo: sessao.tipo == TipoChamada.video,
        ),
      );

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
        final sender = await _peerConnection!.addTrack(track, _streamLocal!);
        if (track.kind == 'video') {
          _videoSender = sender;
        }
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
        _cancelarTimeoutChamada();
        unawaited(ChamadaSomService.instancia.pararToque());
        _foiConectada = true;
        _iniciarCronometroChamada();
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
    _foiRejeitada = true;
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
    final duracaoFinal = segundosChamada.value;
    final conectadaFinal = _foiConectada;
    final rejeitadaFinal = _foiRejeitada;
    final ehChamadorFinal = _ehChamadorLocal;

    _cancelarTimeoutChamada();
    _timerDuracao?.cancel();
    _timerDuracao = null;
    _timerReconexao?.cancel();
    _timerReconexao = null;
    unawaited(ChamadaSomService.instancia.pararToque());

    if (sessao != null && notificarRede) {
      _enviarSinalizacao({
        'tipo': 'chamada_encerrada',
        'chamadaId': sessao.id,
      });
    }

    try {
      _streamTela?.getTracks().forEach((track) {
        track.stop();
      });
      await _streamTela?.dispose();
      _streamTela = null;
    } catch (_) {}

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

    _videoSender = null;
    compartilhandoTela = false;
    await ChamadaTelaHelper.pararServicoAndroid();
    await ChamadaTelaHelper.pararServicoChamadaAndroid();
    videoRemotoAtivo.value = false;
    telaRemotaAtiva.value = false;
    chamadaMinimizada.value = false;
    segundosChamada.value = 0;
    statusConexao.value = 'normal';
    _foiConectada = false;
    _foiRejeitada = false;
    _ehChamadorLocal = false;
    renderizadorLocal.srcObject = null;
    renderizadorRemoto.srcObject = null;
    _streamRemoto = null;

    sessaoAtiva.value = null;

    if (sessao != null) {
      unawaited(
        ChamadaHistoricoService.registrarEncerramento(
          sessao: sessao,
          foiConectada: conectadaFinal,
          duracaoSegundos: duracaoFinal,
          rejeitada: rejeitadaFinal,
          ehChamadorLocal: ehChamadorFinal,
        ),
      );
    }

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

  Future<void> _renegociarConexao() async {
    final pc = _peerConnection;
    final sessao = sessaoAtiva.value;
    if (pc == null || sessao == null) return;
    try {
      final offer = await pc.createOffer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': 1,
      });
      await pc.setLocalDescription(offer);
      _enviarSinalizacao({
        'tipo': 'chamada_renegociar_oferta',
        'chamadaId': sessao.id,
        'videoHabilitado': sessao.videoHabilitado,
        'compartilhandoTela': sessao.compartilhandoTela,
        'sdp': {'sdp': offer.sdp, 'type': offer.type},
      });
    } catch (e) {
      debugPrint('[ChamadaWebRtcService] Erro ao renegociar mídia: $e');
    }
  }

  Future<void> receberRenegociacaoOferta(Map<String, dynamic> dados) async {
    final pc = _peerConnection;
    final sdpOferta = dados['sdp'] as Map<String, dynamic>?;
    if (pc == null || sdpOferta == null) return;
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

      final videoRem = dados['videoHabilitado'] == true;
      final telaRem = dados['compartilhandoTela'] == true;
      videoRemotoAtivo.value = videoRem || telaRem;
      telaRemotaAtiva.value = telaRem;
      if (sessaoAtiva.value != null && (videoRem || telaRem)) {
        sessaoAtiva.value = sessaoAtiva.value!.copyWith(
          tipo: TipoChamada.video,
        );
      }

      _enviarSinalizacao({
        'tipo': 'chamada_renegociar_resposta',
        'chamadaId': dados['chamadaId'] ?? sessaoAtiva.value?.id ?? '',
        'sdp': {'sdp': answer.sdp, 'type': answer.type},
      });
    } catch (e) {
      debugPrint('[ChamadaWebRtcService] Erro ao processar renegociação SDP: $e');
    }
  }

  Future<void> receberRenegociacaoResposta(Map<String, dynamic> sdpResposta) async {
    final pc = _peerConnection;
    if (pc == null) return;
    try {
      final description = RTCSessionDescription(
        sdpResposta['sdp'] as String?,
        sdpResposta['type'] as String?,
      );
      await pc.setRemoteDescription(description);
    } catch (e) {
      debugPrint('[ChamadaWebRtcService] Erro ao aplicar resposta de renegociação: $e');
    }
  }

  Future<void> _pararStreamTela() async {
    try {
      _streamTela?.getTracks().forEach((t) => t.stop());
      await _streamTela?.dispose();
    } catch (_) {}
    _streamTela = null;
    compartilhandoTela = false;
    await ChamadaTelaHelper.pararServicoAndroid();
  }

  Future<void> alternarCamera() async {
    if (_streamLocal == null) return;
    if (compartilhandoTela) {
      await _pararStreamTela();
    }

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
        final track = videoStream.getVideoTracks().first;
        _streamLocal!.addTrack(track);
        renderizadorLocal.srcObject = _streamLocal;

        if (_peerConnection != null) {
          if (_videoSender != null) {
            await _videoSender!.replaceTrack(track);
          } else {
            _videoSender = await _peerConnection!.addTrack(track, _streamLocal!);
          }
        }

        cameraDesativada = false;
        if (sessaoAtiva.value != null) {
          sessaoAtiva.value = sessaoAtiva.value!.copyWith(
            tipo: TipoChamada.video,
            videoHabilitado: true,
            compartilhandoTela: false,
          );
        }
        await _renegociarConexao();
        return;
      } catch (e) {
        debugPrint('[ChamadaWebRtcService] Erro ao obter vídeo na chamada de voz: $e');
        return;
      }
    }

    cameraDesativada = !cameraDesativada;
    final track = videoTracks.first;
    track.enabled = !cameraDesativada;
    if (!cameraDesativada && _videoSender != null) {
      await _videoSender!.replaceTrack(track);
      renderizadorLocal.srcObject = _streamLocal;
    }
    if (sessaoAtiva.value != null) {
      sessaoAtiva.value = sessaoAtiva.value!.copyWith(
        tipo: !cameraDesativada ? TipoChamada.video : sessaoAtiva.value!.tipo,
        videoHabilitado: !cameraDesativada,
        compartilhandoTela: false,
      );
    }
    await _renegociarConexao();
  }

  /// Inicia ou encerra a transmissão de tela do dispositivo durante a chamada (estilo Discord).
  Future<bool> alternarCompartilhamentoTela() async {
    if (_peerConnection == null) return false;

    if (compartilhandoTela) {
      await _pararStreamTela();
      final camTracks = _streamLocal?.getVideoTracks() ?? const <MediaStreamTrack>[];
      final temCameraAtiva = camTracks.isNotEmpty && !cameraDesativada;
      if (_videoSender != null) {
        await _videoSender!.replaceTrack(temCameraAtiva ? camTracks.first : null);
      }
      renderizadorLocal.srcObject = _streamLocal;
      if (sessaoAtiva.value != null) {
        sessaoAtiva.value = sessaoAtiva.value!.copyWith(
          videoHabilitado: temCameraAtiva,
          compartilhandoTela: false,
        );
      }
      await _renegociarConexao();
      return false;
    }

    try {
      final telaStream = await ChamadaTelaHelper.capturarTela();
      if (telaStream == null) {
        await ChamadaTelaHelper.pararServicoAndroid();
        return false;
      }
      final tracks = telaStream.getVideoTracks();
      if (tracks.isEmpty) {
        await telaStream.dispose();
        return false;
      }

      _streamTela = telaStream;
      compartilhandoTela = true;
      final screenTrack = tracks.first;
      screenTrack.onEnded = () {
        if (compartilhandoTela) {
          unawaited(alternarCompartilhamentoTela());
        }
      };

      renderizadorLocal.srcObject = _streamTela;
      if (_videoSender != null) {
        await _videoSender!.replaceTrack(screenTrack);
      } else {
        _videoSender = await _peerConnection!.addTrack(screenTrack, _streamTela!);
      }

      if (sessaoAtiva.value != null) {
        sessaoAtiva.value = sessaoAtiva.value!.copyWith(
          tipo: TipoChamada.video,
          videoHabilitado: true,
          compartilhandoTela: true,
        );
      }
      await _renegociarConexao();
      return true;
    } catch (e) {
      debugPrint('[ChamadaWebRtcService] Erro ao compartilhar tela: $e');
      await _pararStreamTela();
      return false;
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

  void _iniciarTimeoutChamada(String chamadaId) {
    _cancelarTimeoutChamada();
    _timerTimeoutChamada = Timer(const Duration(seconds: 45), () {
      final atual = sessaoAtiva.value;
      if (atual != null &&
          atual.id == chamadaId &&
          (atual.estado == EstadoChamada.chamando ||
              atual.estado == EstadoChamada.tocando)) {
        debugPrint('[ChamadaWebRtcService] Tempo limite de 45s sem resposta.');
        unawaited(encerrarChamada(notificarRede: _ehChamadorLocal));
      }
    });
  }

  void _cancelarTimeoutChamada() {
    _timerTimeoutChamada?.cancel();
    _timerTimeoutChamada = null;
  }

  void _iniciarCronometroChamada() {
    _timerDuracao?.cancel();
    segundosChamada.value = 0;
    _timerDuracao = Timer.periodic(const Duration(seconds: 1), (_) {
      final atual = sessaoAtiva.value;
      if (atual != null && atual.estado == EstadoChamada.conectada) {
        segundosChamada.value = segundosChamada.value + 1;
      }
    });
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
        if (event.track.kind == 'video') {
          videoRemotoAtivo.value = true;
          if (sessaoAtiva.value != null &&
              sessaoAtiva.value!.tipo != TipoChamada.video) {
            sessaoAtiva.value = sessaoAtiva.value!.copyWith(
              tipo: TipoChamada.video,
            );
          }
        }
        debugPrint(
          '[ChamadaWebRtcService] Stream remoto recebido com sucesso!',
        );
      }
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint('[ChamadaWebRtcService] Estado de conexão WebRTC: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _timerReconexao?.cancel();
        _timerReconexao = null;
        statusConexao.value = 'normal';
        _cancelarTimeoutChamada();
        unawaited(ChamadaSomService.instancia.pararToque());
        if (sessaoAtiva.value != null) {
          if (!_foiConectada) {
            _foiConectada = true;
            _iniciarCronometroChamada();
          }
          sessaoAtiva.value = sessaoAtiva.value!.copyWith(
            estado: EstadoChamada.conectada,
          );
        }
      } else if (state ==
          RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        statusConexao.value = 'reconectando';
        _timerReconexao?.cancel();
        _timerReconexao = Timer(const Duration(seconds: 15), () {
          if (statusConexao.value == 'reconectando') {
            statusConexao.value = 'instavel';
            unawaited(encerrarChamada(notificarRede: false));
          }
        });
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        _timerReconexao?.cancel();
        _timerReconexao = null;
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
