import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:nous/src/features/chat/models/chamada_sessao.dart';
import 'package:nous/src/features/chat/services/chamada_historico_service.dart';
import 'package:nous/src/features/chat/services/chamada_tela_helper.dart';
import 'package:nous/src/features/chat/services/chamada_webrtc_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

class ChamadaAtivaView extends StatefulWidget {
  final ChamadaSessao sessao;

  const ChamadaAtivaView({
    super.key,
    required this.sessao,
  });

  static Future<void> abrir(BuildContext context, ChamadaSessao sessao) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ChamadaAtivaView(sessao: sessao),
      ),
    );
  }

  @override
  State<ChamadaAtivaView> createState() => _ChamadaAtivaViewState();
}

class _ChamadaAtivaViewState extends State<ChamadaAtivaView> {
  final _service = ChamadaWebRtcService.instancia;

  @override
  void initState() {
    super.initState();
    _service.chamadaMinimizada.value = false;

    _service.onChamadaEncerrada = () {
      if (mounted) {
        Navigator.of(context).maybePop();
      }
    };
  }

  @override
  void dispose() {
    if (_service.sessaoAtiva.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_service.sessaoAtiva.value != null) {
          _service.chamadaMinimizada.value = true;
        }
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ChamadaSessao?>(
      valueListenable: _service.sessaoAtiva,
      builder: (context, sessao, _) {
        final sessaoAtual = sessao ?? widget.sessao;
        final ehVideo = sessaoAtual.tipo == TipoChamada.video ||
            sessaoAtual.videoHabilitado ||
            sessaoAtual.compartilhandoTela;
        final estaConectada = sessaoAtual.estado == EstadoChamada.conectada;

        return Scaffold(
          backgroundColor: const Color(0xFF0F141C),
          body: SafeArea(
            child: Stack(
              children: [
                // 1. Área Principal (Vídeo/Tela Remoto ou Avatar Central de Voz)
                ValueListenableBuilder<bool>(
                  valueListenable: _service.videoRemotoAtivo,
                  builder: (context, videoRemoto, _) {
                    if ((ehVideo || videoRemoto) && estaConectada) {
                      return Positioned.fill(
                        child: ValueListenableBuilder<
                            List<({String id, RTCVideoRenderer renderer})>>(
                          valueListenable: _service.streamsVideoRemotos,
                          builder: (context, streams, _) {
                            if (streams.length > 1) {
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  80,
                                  12,
                                  110,
                                ),
                                child: GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: 16 / 10,
                                  ),
                                  itemCount: streams.length,
                                  itemBuilder: (_, idx) => ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      color: Colors.black,
                                      child: InteractiveViewer(
                                        minScale: 1.0,
                                        maxScale: 4.0,
                                        child: RTCVideoView(
                                          streams[idx].renderer,
                                          mirror: false,
                                          objectFit: RTCVideoViewObjectFit
                                              .RTCVideoViewObjectFitContain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }

                            return ValueListenableBuilder<bool>(
                              valueListenable: _service.telaRemotaAtiva,
                              builder: (context, telaRemota, _) {
                                final videoView = RTCVideoView(
                                  streams.isNotEmpty
                                      ? streams.first.renderer
                                      : _service.renderizadorRemoto,
                                  mirror: false,
                                  objectFit: telaRemota
                                      ? RTCVideoViewObjectFit
                                          .RTCVideoViewObjectFitContain
                                      : RTCVideoViewObjectFit
                                          .RTCVideoViewObjectFitCover,
                                );
                                if (telaRemota) {
                                  return InteractiveViewer(
                                    minScale: 1.0,
                                    maxScale: 4.0,
                                    child: videoView,
                                  );
                                }
                                return videoView;
                              },
                            );
                          },
                        ),
                      );
                    }
                    return _buildFundoVoz(sessaoAtual, estaConectada);
                  },
                ),

                // 2. PiP do Vídeo Local (Câmera ou Prévia da Tela Transmitida)
                if (sessaoAtual.videoHabilitado ||
                    sessaoAtual.compartilhandoTela)
                  Positioned(
                    top: 20,
                    right: 20,
                    width: 110,
                    height: 160,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _service.cameraFrontalAtiva,
                        builder: (context, ehFrontal, _) {
                          return RTCVideoView(
                            _service.renderizadorLocal,
                            mirror: ehFrontal && !sessaoAtual.compartilhandoTela,
                            objectFit: sessaoAtual.compartilhandoTela
                                ? RTCVideoViewObjectFit
                                    .RTCVideoViewObjectFitContain
                                : RTCVideoViewObjectFit
                                    .RTCVideoViewObjectFitCover,
                          );
                        },
                      ),
                    ),
                  ),

                // 3. Barra Superior com Botão Minimizar, Nome e Status/Qualidade
                Positioned(
                  top: 20,
                  left: 12,
                  right: ehVideo ? 140 : 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        tooltip: 'Minimizar Chamada',
                        onPressed: () {
                          _service.chamadaMinimizada.value = true;
                          Navigator.of(context).maybePop();
                        },
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sessaoAtual.destinatarioNome.isNotEmpty
                                  ? sessaoAtual.destinatarioNome
                                  : sessaoAtual.remetenteNome,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(color: Colors.black87, blurRadius: 6),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            ValueListenableBuilder<String>(
                              valueListenable: _service.statusConexao,
                              builder: (context, statusRede, _) {
                                final reconectando = statusRede == 'reconectando';
                                return Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: reconectando
                                            ? Colors.orangeAccent
                                            : (estaConectada
                                                ? Colors.greenAccent
                                                : Colors.amberAccent),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (reconectando)
                                      Text(
                                        'Reconectando Wi-Fi...',
                                        style: TextStyle(
                                          color: Colors.orangeAccent
                                              .withValues(alpha: 0.95),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          shadows: const [
                                            Shadow(
                                              color: Colors.black87,
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      ValueListenableBuilder<int>(
                                        valueListenable:
                                            _service.segundosChamada,
                                        builder: (context, segundos, _) {
                                          return Text(
                                            estaConectada
                                                ? ChamadaHistoricoService
                                                    .formatarDuracao(segundos)
                                                : (sessaoAtual.estado ==
                                                        EstadoChamada.chamando
                                                    ? 'Chamando...'
                                                    : 'Conectando na rede local...'),
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.8),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              shadows: const [
                                                Shadow(
                                                  color: Colors.black87,
                                                  blurRadius: 6,
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Participantes e Mute',
                        onPressed: () => _abrirPainelParticipantes(sessaoAtual),
                        icon: const Icon(
                          Icons.people_outline_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. Barra Inferior de Controles da Chamada (Estilo WhatsApp)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 30,
                  child: _buildBarraControles(sessaoAtual, ehVideo),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFundoVoz(ChamadaSessao sessao, bool estaConectada) {
    final foto = sessao.destinatarioFoto.isNotEmpty
        ? sessao.destinatarioFoto
        : sessao.remetenteFoto;

    final imageProvider = ImagemService.obterImageProvider(foto);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            Color(0xFF1E2838),
            Color(0xFF0F141C),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar Pulsante com anéis de onda
            Stack(
              alignment: Alignment.center,
              children: [
                if (estaConectada)
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.greenAccent.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                  ),
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: estaConectada
                          ? Colors.greenAccent.withValues(alpha: 0.6)
                          : Colors.white24,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: estaConectada
                            ? Colors.greenAccent.withValues(alpha: 0.25)
                            : Colors.black45,
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 65,
                    backgroundColor: const Color(0xFF2A3649),
                    backgroundImage: imageProvider,
                    child: imageProvider == null
                        ? const Icon(
                            Icons.person_rounded,
                            size: 64,
                            color: Colors.white70,
                          )
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              sessao.destinatarioNome.isNotEmpty
                  ? sessao.destinatarioNome
                  : sessao.remetenteNome,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              sessao.tipo == TipoChamada.video
                  ? 'Chamada de Vídeo Nous'
                  : 'Chamada de Voz Nous (Rede Local)',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarraControles(ChamadaSessao sessao, bool ehVideo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2838).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. Mute Microfone
          _botaoAcao(
            icone: _service.microfoneMutado
                ? Icons.mic_off_rounded
                : Icons.mic_rounded,
            ativo: !_service.microfoneMutado,
            corAtiva: Colors.white24,
            corIcone:
                _service.microfoneMutado ? Colors.redAccent : Colors.white,
            tooltip: _service.microfoneMutado ? 'Desmutar' : 'Silenciar',
            onTap: () {
              setState(() {
                _service.alternarMicrofone();
              });
            },
          ),

          // 2. Viva-Voz
          _botaoAcao(
            icone: _service.vivaVozAtivo
                ? Icons.volume_up_rounded
                : Icons.volume_down_rounded,
            ativo: _service.vivaVozAtivo,
            corAtiva: Colors.white24,
            corIcone: Colors.white,
            tooltip: 'Viva-Voz',
            onTap: () {
              setState(() {
                _service.alternarVivaVoz();
              });
            },
          ),

          // 3. Mudar para Chamada de Vídeo / Ligar ou Desligar Câmera (disponível em toda chamada)
          _botaoAcao(
            icone: (_service.cameraDesativada || !sessao.videoHabilitado || sessao.compartilhandoTela)
                ? Icons.videocam_off_rounded
                : Icons.videocam_rounded,
            ativo: sessao.videoHabilitado && !sessao.compartilhandoTela && !_service.cameraDesativada,
            corAtiva: Colors.white24,
            corIcone: (sessao.videoHabilitado && !sessao.compartilhandoTela && !_service.cameraDesativada)
                ? Colors.white
                : Colors.white70,
            tooltip: (sessao.videoHabilitado && !sessao.compartilhandoTela && !_service.cameraDesativada)
                ? 'Desligar Vídeo'
                : 'Mudar para Vídeo',
            onTap: () async {
              await _service.alternarCamera();
              if (mounted) setState(() {});
            },
          ),

          // 4. Transmitir Tela (estilo Discord - Windows e Android)
          _botaoAcao(
            icone: sessao.compartilhandoTela
                ? Icons.stop_screen_share_rounded
                : Icons.screen_share_rounded,
            ativo: sessao.compartilhandoTela,
            corAtiva: const Color(0xFF2E7D32),
            corIcone: Colors.white,
            tooltip: sessao.compartilhandoTela
                ? 'Parar Transmissão de Tela'
                : 'Transmitir Tela',
            onTap: () async {
              final estavaCompartilhando = sessao.compartilhandoTela;
              String? sourceId;
              if (!estavaCompartilhando) {
                final fontes = await ChamadaTelaHelper.listarFontesDesktop();
                if (fontes.length > 1 && mounted) {
                  sourceId = await _selecionarFonteTela(fontes);
                  if (sourceId == null) return;
                }
              }
              final ativo = await _service.alternarCompartilhamentoTela(
                sourceId: sourceId,
              );
              if (!mounted) return;
              if (!estavaCompartilhando && !ativo) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Não foi possível iniciar o compartilhamento de tela.'),
                  ),
                );
              }
              setState(() {});
            },
          ),

          // 5. Inverter Câmera (apenas quando a câmera estiver ativa)
          if (sessao.videoHabilitado &&
              !_service.cameraDesativada &&
              !sessao.compartilhandoTela)
            _botaoAcao(
              icone: Icons.cameraswitch_rounded,
              ativo: true,
              corAtiva: Colors.white24,
              corIcone: Colors.white,
              tooltip: 'Inverter Câmera',
              onTap: () {
                _service.alternarCameraFrontalTraseira();
              },
            ),

          // 4. Encerrar Chamada (Botão Vermelho)
          InkWell(
            onTap: () async {
              await _service.encerrarChamada(notificarRede: true);
              if (mounted) {
                Navigator.of(context).maybePop();
              }
            },
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent,
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.call_end_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _selecionarFonteTela(
    List<DesktopCapturerSource> fontes,
  ) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1A222E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 460,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.80,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Escolha a tela ou janela para transmitir',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: fontes.length,
                    itemBuilder: (_, i) {
                      final f = fontes[i];
                      return ListTile(
                        leading: Icon(
                          f.type == SourceType.Screen
                              ? Icons.desktop_windows_rounded
                              : Icons.web_asset_rounded,
                          color: Colors.white70,
                        ),
                        title: Text(
                          f.name,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.pop(ctx, f.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _abrirPainelParticipantes(ChamadaSessao sessao) async {
    final idsParticipantes = <String>{
      if (sessao.destinatarioId.isNotEmpty) sessao.destinatarioId,
      ...sessao.participantesIds,
      ..._service.streamsVideoRemotos.value.map((s) => s.id),
    }.toList();

    await showDialog<void>(
      context: context,
      builder: (ctx) => ValueListenableBuilder<Set<String>>(
        valueListenable: _service.participantesMutadosLocalmente,
        builder: (_, mutados, _) => Dialog(
          backgroundColor: const Color(0xFF1A222E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.80,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Participantes na Chamada',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (idsParticipantes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Aguardando participantes conectarem...',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: idsParticipantes.length,
                        itemBuilder: (_, i) {
                          final pid = idsParticipantes[i];
                          final mutado = mutados.contains(pid);
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.white12,
                              child: Icon(
                                Icons.person_rounded,
                                color: Colors.white70,
                              ),
                            ),
                            title: Text(
                              pid == sessao.destinatarioId
                                  ? sessao.destinatarioNome
                                  : pid,
                              style: const TextStyle(color: Colors.white),
                            ),
                            trailing: IconButton(
                              tooltip: mutado
                                  ? 'Desmutar participante para mim'
                                  : 'Mutar participante para mim',
                              icon: Icon(
                                mutado
                                    ? Icons.volume_off_rounded
                                    : Icons.volume_up_rounded,
                                color: mutado
                                    ? Colors.redAccent
                                    : Colors.greenAccent,
                              ),
                              onPressed: () =>
                                  _service.alternarMuteParticipante(pid),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _botaoAcao({
    required IconData icone,
    required bool ativo,
    required Color corAtiva,
    required Color corIcone,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ativo ? corAtiva : Colors.white10,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icone,
            color: corIcone,
            size: 22,
          ),
        ),
      ),
    );
  }
}
