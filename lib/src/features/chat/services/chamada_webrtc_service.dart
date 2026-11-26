import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:nous/src/core/services/gerador_id.dart';
import 'package:nous/src/core/services/navigator_key_service.dart';
import 'package:nous/src/features/chat/models/chamada_sessao.dart';
import 'package:nous/src/features/chat/services/chamada_historico_service.dart';
import 'package:nous/src/features/chat/services/chamada_som_service.dart';
import 'package:nous/src/features/chat/services/chamada_tela_helper.dart';
import 'package:nous/src/features/chat/services/helpers/chamada_midia_helper.dart';
import 'package:nous/src/features/chat/services/helpers/chamada_sinalizacao_helper.dart';
import 'package:nous/src/features/chat/views/widgets/dialog_chamada_recebida.dart';

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
  final ValueNotifier<Set<String>> participantesMutadosLocalmente =
      ValueNotifier<Set<String>>({});
  final ValueNotifier<List<({String id, RTCVideoRenderer renderer})>>
      streamsVideoRemotos = ValueNotifier([]);
  final Map<String, MediaStream> _streamsRemotosPorId = {};

  Timer? _timerTimeoutChamada;
  Timer? _timerDuracao;
  Timer? _timerReconexao;
  bool _ehChamadorLocal = false;
  bool _foiConectada = false;
  bool _foiRejeitada = false;
  bool _encerrando = false;

  // Callback acionado pela interface quando uma chamada for recebida
  void Function(ChamadaSessao sessao)? onChamadaRecebida;
  void Function()? onChamadaEncerrada;

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
      await _prepararPeerConnectionEMidia(
        chamadaId: chamadaId,
        comVideo: tipo == TipoChamada.video,
      );
      await ChamadaSinalizacaoHelper.enviarOfertaInicial(
        _peerConnection!,
        sessao,
      );
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
      ChamadaSinalizacaoHelper.enviarRejeicao(sessao.id, motivo: 'ocupado');
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

      await _prepararPeerConnectionEMidia(
        chamadaId: sessao.id,
        comVideo: sessao.tipo == TipoChamada.video,
      );
      await ChamadaSinalizacaoHelper.responderOfertaInicial(
        _peerConnection!,
        sessao,
        sdpOferta,
      );
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
    final aplicada = await ChamadaSinalizacaoHelper.aplicarRespostaSdp(
      _peerConnection!,
      sdpResposta,
    );
    if (!aplicada || sessaoAtiva.value == null) return;

    _cancelarTimeoutChamada();
    unawaited(ChamadaSomService.instancia.pararToque());
    _foiConectada = true;
    _iniciarCronometroChamada();
    sessaoAtiva.value = sessaoAtiva.value!.copyWith(
      estado: EstadoChamada.conectada,
    );
  }

  /// Aplica candidato ICE remoto
  Future<void> receberCandidatoIce(Map<String, dynamic> candidatoJson) async {
    if (_peerConnection == null) return;
    await ChamadaSinalizacaoHelper.adicionarCandidatoIce(
      _peerConnection!,
      candidatoJson,
    );
  }

  /// Rejeita uma chamada recebida
  Future<void> rejeitarChamada() async {
    final sessao = sessaoAtiva.value;
    _foiRejeitada = true;
    if (sessao != null) {
      ChamadaSinalizacaoHelper.enviarRejeicao(sessao.id);
    }
    await encerrarChamada(notificarRede: false);
  }

  /// Encerra a chamada ativa e limpa recursos de hardware
  Future<void> encerrarChamada({bool notificarRede = true}) async {
    if (_encerrando) return;
    _encerrando = true;
    try {
      final sessao = sessaoAtiva.value;
      final duracaoFinal = segundosChamada.value;
      final conectadaFinal = _foiConectada;
      final rejeitadaFinal = _foiRejeitada;
      final ehChamadorFinal = _ehChamadorLocal;

      // Limpa referências reativas e _peerConnection antes dos awaits
      // para evitar reentrância quando close() disparar onConnectionState.
      sessaoAtiva.value = null;
      final pc = _peerConnection;
      _peerConnection = null;
      final streamTela = _streamTela;
      _streamTela = null;
      final streamLocal = _streamLocal;
      _streamLocal = null;

      _cancelarTimeoutChamada();
      _timerDuracao?.cancel();
      _timerDuracao = null;
      _timerReconexao?.cancel();
      _timerReconexao = null;
      unawaited(ChamadaSomService.instancia.pararToque());

      if (sessao != null && notificarRede) {
        ChamadaSinalizacaoHelper.enviarEncerramento(sessao.id);
      }

      await ChamadaMidiaHelper.encerrarStream(streamTela);
      await ChamadaMidiaHelper.encerrarStream(streamLocal);

      try {
        await pc?.close();
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
      for (final item in streamsVideoRemotos.value) {
        item.renderer.srcObject = null;
        unawaited(item.renderer.dispose());
      }
      streamsVideoRemotos.value = const [];
      _streamsRemotosPorId.clear();
      participantesMutadosLocalmente.value = const {};

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

      onChamadaEncerrada?.call();
    } finally {
      _encerrando = false;
    }
  }

  // --- Controles de Áudio e Câmera ---

  void alternarMicrofone() {
    if (_streamLocal == null) return;
    final audioTracks = _streamLocal!.getAudioTracks();
    if (audioTracks.isEmpty) return;

    microfoneMutado = !microfoneMutado;
    audioTracks.first.enabled = !microfoneMutado;
    if (sessaoAtiva.value != null) {
      sessaoAtiva.value = sessaoAtiva.value!.copyWith(
        audioHabilitado: !microfoneMutado,
      );
    }
  }

  Future<void> _renegociarConexao() async {
    final pc = _peerConnection;
    final sessao = sessaoAtiva.value;
    if (pc == null || sessao == null) return;
    await ChamadaSinalizacaoHelper.enviarRenegociacaoOferta(pc, sessao);
  }

  Future<void> receberRenegociacaoOferta(Map<String, dynamic> dados) async {
    final pc = _peerConnection;
    if (pc == null) return;
    final ok = await ChamadaSinalizacaoHelper.processarRenegociacaoOferta(
      pc,
      dados,
      chamadaIdFallback: sessaoAtiva.value?.id ?? '',
    );
    if (!ok) return;

    final videoRem = dados['videoHabilitado'] == true;
    final telaRem = dados['compartilhandoTela'] == true;
    videoRemotoAtivo.value = videoRem || telaRem;
    telaRemotaAtiva.value = telaRem;
    if (sessaoAtiva.value != null && (videoRem || telaRem)) {
      sessaoAtiva.value = sessaoAtiva.value!.copyWith(
        tipo: TipoChamada.video,
      );
    }
  }

  Future<void> receberRenegociacaoResposta(
    Map<String, dynamic> sdpResposta,
  ) async {
    final pc = _peerConnection;
    if (pc == null) return;
    await ChamadaSinalizacaoHelper.aplicarRespostaSdp(pc, sdpResposta);
  }

  Future<void> _pararStreamTela() async {
    final stream = _streamTela;
    _streamTela = null;
    compartilhandoTela = false;
    await ChamadaMidiaHelper.pararStreamTela(stream);
  }

  Future<void> alternarCamera() async {
    if (_streamLocal == null) return;
    if (compartilhandoTela) {
      await _pararStreamTela();
    }

    final resultado = await ChamadaMidiaHelper.alternarCamera(
      streamLocal: _streamLocal!,
      renderizadorLocal: renderizadorLocal,
      peerConnection: _peerConnection,
      videoSenderAtual: _videoSender,
      cameraDesativadaAtual: cameraDesativada,
      cameraFrontal: cameraFrontalAtiva.value,
    );
    if (resultado == null) return;

    cameraDesativada = resultado.cameraDesativada;
    _videoSender = resultado.videoSender;
    if (sessaoAtiva.value != null) {
      sessaoAtiva.value = sessaoAtiva.value!.copyWith(
        tipo: resultado.virouChamadaVideo
            ? TipoChamada.video
            : sessaoAtiva.value!.tipo,
        videoHabilitado: !cameraDesativada,
        compartilhandoTela: false,
      );
    }
    await _renegociarConexao();
  }

  /// Muta ou desmuta localmente um participante ou stream remoto durante a chamada.
  void alternarMuteParticipante(String participanteId) {
    final atual = Set<String>.from(participantesMutadosLocalmente.value);
    final mutar = !atual.contains(participanteId);
    if (mutar) {
      atual.add(participanteId);
    } else {
      atual.remove(participanteId);
    }
    participantesMutadosLocalmente.value = atual;

    final streamEspecifico = _streamsRemotosPorId[participanteId];
    if (streamEspecifico != null) {
      for (final t in streamEspecifico.getAudioTracks()) {
        t.enabled = !mutar;
      }
    } else if (_streamRemoto != null) {
      for (final t in _streamRemoto!.getAudioTracks()) {
        t.enabled = !mutar;
      }
    }
  }

  /// Inicia ou encerra a transmissão de tela do dispositivo durante a chamada (estilo Discord).
  Future<bool> alternarCompartilhamentoTela({String? sourceId}) async {
    if (_peerConnection == null) return false;

    if (compartilhandoTela) {
      await _pararStreamTela();
      final temCameraAtiva = await ChamadaMidiaHelper.restaurarCameraAposTela(
        streamLocal: _streamLocal,
        renderizadorLocal: renderizadorLocal,
        videoSender: _videoSender,
        cameraDesativada: cameraDesativada,
      );
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
      final captura = await ChamadaMidiaHelper.iniciarCapturaTela(
        peerConnection: _peerConnection!,
        renderizadorLocal: renderizadorLocal,
        videoSenderAtual: _videoSender,
        sourceId: sourceId,
        onTelaEncerrada: () {
          if (compartilhandoTela) {
            unawaited(alternarCompartilhamentoTela());
          }
        },
      );
      if (captura == null) return false;

      _streamTela = captura.stream;
      _videoSender = captura.videoSender;
      compartilhandoTela = true;

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
    await ChamadaMidiaHelper.definirVivaVoz(vivaVozAtivo);
  }

  Future<void> alternarCameraFrontalTraseira() async {
    final alternou = await ChamadaMidiaHelper.alternarCameraFrontalTraseira(
      _streamLocal,
    );
    if (alternou) {
      cameraFrontalAtiva.value = !cameraFrontalAtiva.value;
    }
  }

  Future<void> _prepararPeerConnectionEMidia({
    required String chamadaId,
    required bool comVideo,
  }) async {
    _peerConnection = await createPeerConnection(
      ChamadaSinalizacaoHelper.configuracaoWebRtc,
      ChamadaSinalizacaoHelper.restricoesLoopback,
    );
    _configurarListenersPeerConnection(chamadaId);

    final midiaLocal = await ChamadaMidiaHelper.obterStreamLocalEAdicionarTracks(
      peerConnection: _peerConnection!,
      renderizadorLocal: renderizadorLocal,
      comVideo: comVideo,
    );
    _streamLocal = midiaLocal.stream;
    _videoSender = midiaLocal.videoSender;
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
      ChamadaSinalizacaoHelper.enviarCandidatoIceLocal(chamadaId, candidate);
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) async {
      if (event.streams.isNotEmpty) {
        final stream = event.streams[0];
        _streamRemoto = stream;
        _streamsRemotosPorId[stream.id] = stream;
        renderizadorRemoto.srcObject = stream;

        if (event.track.kind == 'audio') {
          final mutado = participantesMutadosLocalmente.value.contains(stream.id);
          event.track.enabled = !mutado;
        }

        if (event.track.kind == 'video') {
          videoRemotoAtivo.value = true;
          if (!streamsVideoRemotos.value.any((s) => s.id == stream.id)) {
            final renderer = RTCVideoRenderer();
            await renderer.initialize();
            renderer.srcObject = stream;
            streamsVideoRemotos.value = [
              ...streamsVideoRemotos.value,
              (id: stream.id, renderer: renderer),
            ];
          }
          if (sessaoAtiva.value != null &&
              sessaoAtiva.value!.tipo != TipoChamada.video) {
            sessaoAtiva.value = sessaoAtiva.value!.copyWith(
              tipo: TipoChamada.video,
            );
          }
        }
        debugPrint(
          '[ChamadaWebRtcService] Stream remoto recebido (${stream.id})!',
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
}
