import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:nous/src/features/chat/models/chamada_sessao.dart';
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
  Timer? _timerDuracao;
  int _segundosChamada = 0;

  @override
  void initState() {
    super.initState();
    _iniciarTimerDuracao();

    _service.onChamadaEncerrada = () {
      if (mounted) {
        Navigator.of(context).maybePop();
      }
    };
  }

  void _iniciarTimerDuracao() {
    _timerDuracao?.cancel();
    _timerDuracao = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final sessao = _service.sessaoAtiva.value;
      if (sessao != null && sessao.estado == EstadoChamada.conectada) {
        setState(() {
          _segundosChamada++;
        });
      }
    });
  }

  String _formatarDuracao(int segundos) {
    final m = (segundos ~/ 60).toString().padLeft(2, '0');
    final s = (segundos % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _timerDuracao?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ChamadaSessao?>(
      valueListenable: _service.sessaoAtiva,
      builder: (context, sessao, _) {
        final sessaoAtual = sessao ?? widget.sessao;
        final ehVideo = sessaoAtual.tipo == TipoChamada.video || sessaoAtual.videoHabilitado;
        final estaConectada = sessaoAtual.estado == EstadoChamada.conectada;

        return Scaffold(
          backgroundColor: const Color(0xFF0F141C),
          body: SafeArea(
            child: Stack(
              children: [
                // 1. Área Principal (Vídeo Remoto ou Avatar Central de Voz)
                if (ehVideo && estaConectada)
                  Positioned.fill(
                    child: RTCVideoView(
                      _service.renderizadorRemoto,
                      mirror: false,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  )
                else
                  _buildFundoVoz(sessaoAtual, estaConectada),

                // 2. PiP do Vídeo Local (Câmera do próprio usuário - apenas frontal espelhada)
                if (ehVideo && sessaoAtual.videoHabilitado)
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
                            mirror: ehFrontal,
                            objectFit:
                                RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                          );
                        },
                      ),
                    ),
                  ),

                // 3. Barra Superior com Informações do Contato e Status
                Positioned(
                  top: 20,
                  left: 20,
                  right: ehVideo ? 140 : 20,
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
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: estaConectada
                                  ? Colors.greenAccent
                                  : Colors.amberAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            estaConectada
                                ? _formatarDuracao(_segundosChamada)
                                : (sessaoAtual.estado == EstadoChamada.chamando
                                    ? 'Chamando...'
                                    : 'Conectando na rede local...'),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              shadows: const [
                                Shadow(color: Colors.black87, blurRadius: 6),
                              ],
                            ),
                          ),
                        ],
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

          // 3. Alternar Câmera / Ligar Câmera se vídeo
          if (ehVideo) ...[
            _botaoAcao(
              icone: _service.cameraDesativada
                  ? Icons.videocam_off_rounded
                  : Icons.videocam_rounded,
              ativo: !_service.cameraDesativada,
              corAtiva: Colors.white24,
              corIcone:
                  _service.cameraDesativada ? Colors.redAccent : Colors.white,
              tooltip:
                  _service.cameraDesativada ? 'Ligar Câmera' : 'Desligar Câmera',
              onTap: () {
                setState(() {
                  _service.alternarCamera();
                });
              },
            ),
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
          ],

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
