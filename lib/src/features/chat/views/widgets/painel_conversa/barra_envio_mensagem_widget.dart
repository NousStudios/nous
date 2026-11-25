import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nous/src/core/services/player_audio_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/controllers/mensageria_controller.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/gravador_audio_service.dart';
import 'package:nous/src/features/chat/views/widgets/painel_conversa/widgets/banner_resposta_widget.dart';
import 'package:nous/src/features/chat/views/widgets/painel_conversa/widgets/barra_composicao_mensagem_widget.dart';
import 'package:nous/src/features/chat/views/widgets/painel_conversa/widgets/barra_gravacao_audio_widget.dart';
import 'package:nous/src/features/chat/views/widgets/painel_conversa/widgets/barra_pre_escuta_audio_widget.dart';

/// Barra de composição e envio de mensagens (texto, áudio estilo WhatsApp com
/// hold/release e trava ao arrastar para cima, câmera, anexos e preview de resposta).
class BarraEnvioMensagemWidget extends StatefulWidget {
  final MensageriaController controller;
  final AppTheme theme;
  final TextEditingController mensagemController;
  final VoidCallback onEnviarTexto;
  final void Function(String caminho, String duracao, int tamanho) onEnviarAudio;
  final VoidCallback onCapturarFotoCamera;
  final VoidCallback onAbrirMenuAnexo;
  final MensagemChat? mensagemRespondendo;
  final VoidCallback? onCancelarResposta;

  const BarraEnvioMensagemWidget({
    super.key,
    required this.controller,
    required this.theme,
    required this.mensagemController,
    required this.onEnviarTexto,
    required this.onEnviarAudio,
    required this.onCapturarFotoCamera,
    required this.onAbrirMenuAnexo,
    this.mensagemRespondendo,
    this.onCancelarResposta,
  });

  @override
  State<BarraEnvioMensagemWidget> createState() =>
      _BarraEnvioMensagemWidgetState();
}

class _BarraEnvioMensagemWidgetState extends State<BarraEnvioMensagemWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  Offset? _ponteiroInicial;
  double _dx = 0;
  double _dy = 0;
  bool _gravacaoTravada = false;
  bool _gestoAtivo = false;
  bool _canceladoPorArrasto = false;
  ({String caminho, String duracaoTexto, int tamanho})? _audioPendente;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    widget.mensagemController.addListener(_aoDigitarTexto);
  }

  @override
  void didUpdateWidget(covariant BarraEnvioMensagemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller.conversaSelecionada?.id !=
        widget.controller.conversaSelecionada?.id) {
      _descartarAudioPendente(silencioso: true);
    }
  }

  void _aoDigitarTexto() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.mensagemController.removeListener(_aoDigitarTexto);
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<({String caminho, String duracaoTexto, int tamanho})?>
      _finalizarEProcessarAudio() async {
    _pulseCtrl.stop();
    _resetarGesto();
    final gravado = await GravadorAudioService.instancia.finalizarGravacao();
    if (gravado == null) return null;
    if (gravado.duracao.inMilliseconds < 450) {
      try {
        final f = File(gravado.caminho);
        if (f.existsSync()) await f.delete();
      } catch (_) {}
      return null;
    }
    final tamanho = await File(gravado.caminho).length();
    final duracaoSegundos = gravado.duracao.inSeconds;
    final minutos = duracaoSegundos ~/ 60;
    final segundos = duracaoSegundos % 60;
    final duracaoTexto = '$minutos:${segundos.toString().padLeft(2, '0')}';
    return (
      caminho: gravado.caminho,
      duracaoTexto: duracaoTexto,
      tamanho: tamanho,
    );
  }

  Future<void> _finalizarParaPreEscuta() async {
    final resultado = await _finalizarEProcessarAudio();
    if (resultado == null || !mounted) return;
    setState(() => _audioPendente = resultado);
  }

  Future<void> _finalizarEEnviarAudio() async {
    final resultado = await _finalizarEProcessarAudio();
    if (resultado == null) return;
    widget.onEnviarAudio(
      resultado.caminho,
      resultado.duracaoTexto,
      resultado.tamanho,
    );
  }

  Future<void> _enviarAudioPendente() async {
    final pendente = _audioPendente;
    if (pendente == null) return;
    final player = PlayerAudioService.instancia;
    if (player.ehMesmoAudio(pendente.caminho, player.estadoAtual.caminho)) {
      await player.parar();
    }
    if (!mounted) return;
    setState(() => _audioPendente = null);
    widget.onEnviarAudio(
      pendente.caminho,
      pendente.duracaoTexto,
      pendente.tamanho,
    );
  }

  Future<void> _descartarAudioPendente({bool silencioso = false}) async {
    final pendente = _audioPendente;
    if (pendente == null) return;
    final player = PlayerAudioService.instancia;
    if (player.ehMesmoAudio(pendente.caminho, player.estadoAtual.caminho)) {
      await player.parar();
    }
    try {
      final f = File(pendente.caminho);
      if (f.existsSync()) await f.delete();
    } catch (_) {}
    if (!silencioso && mounted) {
      setState(() => _audioPendente = null);
    } else {
      _audioPendente = null;
    }
  }

  Future<void> _cancelarAudio() async {
    _pulseCtrl.stop();
    _resetarGesto();
    await GravadorAudioService.instancia.cancelarGravacao();
  }

  void _resetarGesto() {
    if (!mounted) return;
    setState(() {
      _ponteiroInicial = null;
      _dx = 0;
      _dy = 0;
      _gravacaoTravada = false;
      _gestoAtivo = false;
      _canceladoPorArrasto = false;
    });
  }

  Future<void> _aoPressionarMic(PointerDownEvent ev) async {
    if (widget.mensagemController.text.trim().isNotEmpty) return;
    _ponteiroInicial = ev.position;
    _dx = 0;
    _dy = 0;
    _gravacaoTravada = false;
    _canceladoPorArrasto = false;
    _gestoAtivo = true;
    _pulseCtrl.repeat(reverse: true);
    setState(() {});
    final iniciou = await GravadorAudioService.instancia.iniciarGravacao();
    if (!iniciou && mounted) {
      _pulseCtrl.stop();
      _resetarGesto();
    }
  }

  void _aoMoverMic(PointerMoveEvent ev) {
    if (!_gestoAtivo || _gravacaoTravada || _ponteiroInicial == null) return;
    final delta = ev.position - _ponteiroInicial!;
    setState(() {
      _dx = delta.dx.clamp(-140.0, 0.0);
      _dy = delta.dy.clamp(-100.0, 0.0);
    });

    if (_dy <= -52) {
      setState(() {
        _gravacaoTravada = true;
        _gestoAtivo = false;
        _dx = 0;
        _dy = 0;
      });
      return;
    }
    if (_dx <= -88) {
      _canceladoPorArrasto = true;
      _gestoAtivo = false;
      _cancelarAudio();
    }
  }

  Future<void> _aoSoltarMic() async {
    if (!_gestoAtivo) return;
    _gestoAtivo = false;
    if (_gravacaoTravada || _canceladoPorArrasto) return;
    await _finalizarParaPreEscuta();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final temTexto = widget.mensagemController.text.trim().isNotEmpty;

    return ValueListenableBuilder<bool>(
      valueListenable: GravadorAudioService.instancia.gravandoNotifier,
      builder: (context, gravando, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.mensagemRespondendo != null)
              BannerRespostaWidget(
                theme: theme,
                mensagemRespondendo: widget.mensagemRespondendo!,
                onCancelarResposta: widget.onCancelarResposta,
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: theme.cardBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: theme.borderColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: gravando
                  ? (_gravacaoTravada
                        ? BarraGravacaoTravadaWidget(
                            theme: theme,
                            onCancelar: _cancelarAudio,
                            onFinalizarParaPreEscuta: _finalizarParaPreEscuta,
                            onFinalizarEEnviar: _finalizarEEnviarAudio,
                          )
                        : BarraGravacaoSegurandoWidget(
                            theme: theme,
                            pulseController: _pulseCtrl,
                            dx: _dx,
                            dy: _dy,
                            onPointerMove: _aoMoverMic,
                            onPointerEnd: _aoSoltarMic,
                          ))
                  : (_audioPendente != null
                        ? BarraPreEscutaAudioWidget(
                            theme: theme,
                            caminho: _audioPendente!.caminho,
                            duracaoTexto: _audioPendente!.duracaoTexto,
                            onDescartar: _descartarAudioPendente,
                            onEnviar: _enviarAudioPendente,
                          )
                        : BarraComposicaoMensagemWidget(
                            theme: theme,
                            controller: widget.controller,
                            mensagemController: widget.mensagemController,
                            temTexto: temTexto,
                            onEnviarTexto: widget.onEnviarTexto,
                            onCapturarFotoCamera: widget.onCapturarFotoCamera,
                            onAbrirMenuAnexo: widget.onAbrirMenuAnexo,
                            onPressionarMic: _aoPressionarMic,
                            onMoverMic: _aoMoverMic,
                            onSoltarMic: _aoSoltarMic,
                          )),
            ),
          ],
        );
      },
    );
  }
}
