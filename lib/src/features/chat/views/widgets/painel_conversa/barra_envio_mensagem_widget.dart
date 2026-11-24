import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/services/player_audio_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/controllers/mensageria_controller.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/gravador_audio_service.dart';

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

  Future<void> _finalizarParaPreEscuta() async {
    _pulseCtrl.stop();
    _resetarGesto();
    final gravado = await GravadorAudioService.instancia.finalizarGravacao();
    if (gravado == null) return;
    if (gravado.duracao.inMilliseconds < 450) {
      try {
        final f = File(gravado.caminho);
        if (f.existsSync()) await f.delete();
      } catch (_) {}
      return;
    }
    final tamanho = await File(gravado.caminho).length();
    final duracaoSegundos = gravado.duracao.inSeconds;
    final minutos = duracaoSegundos ~/ 60;
    final segundos = duracaoSegundos % 60;
    final duracaoTexto = '$minutos:${segundos.toString().padLeft(2, '0')}';
    if (!mounted) return;
    setState(() {
      _audioPendente = (
        caminho: gravado.caminho,
        duracaoTexto: duracaoTexto,
        tamanho: tamanho,
      );
    });
  }

  Future<void> _finalizarEEnviarAudio() async {
    _pulseCtrl.stop();
    _resetarGesto();
    final gravado = await GravadorAudioService.instancia.finalizarGravacao();
    if (gravado == null) return;
    if (gravado.duracao.inMilliseconds < 450) {
      try {
        final f = File(gravado.caminho);
        if (f.existsSync()) await f.delete();
      } catch (_) {}
      return;
    }
    final tamanho = await File(gravado.caminho).length();
    final duracaoSegundos = gravado.duracao.inSeconds;
    final minutos = duracaoSegundos ~/ 60;
    final segundos = duracaoSegundos % 60;
    final duracaoTexto = '$minutos:${segundos.toString().padLeft(2, '0')}';
    widget.onEnviarAudio(gravado.caminho, duracaoTexto, tamanho);
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
    widget.onEnviarAudio(pendente.caminho, pendente.duracaoTexto, pendente.tamanho);
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
              _buildBannerResposta(theme, widget.mensagemRespondendo!),
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
                        ? _buildBarraGravacaoTravada(theme)
                        : _buildBarraGravacaoSegurando(theme))
                  : (_audioPendente != null
                        ? _buildBarraPreEscutaAudio(theme, _audioPendente!)
                        : _buildBarraComposicao(theme, temTexto)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBannerResposta(AppTheme theme, MensagemChat resp) {
    final autor = resp.remetenteNome.isNotEmpty
        ? resp.remetenteNome
        : (resp.enviadaPorMim ? 'Você' : 'Contato');
    final preview = resp.texto.trim().isNotEmpty
        ? resp.texto.trim()
        : (resp.tipo == 'audio'
              ? 'Áudio'
              : (resp.tipo == 'imagem'
                    ? 'Foto'
                    : (resp.nomeAnexo.isNotEmpty ? resp.nomeAnexo : 'Mídia')));

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        border: Border(
          top: BorderSide(color: theme.borderColor.withValues(alpha: 0.45)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 34,
            decoration: BoxDecoration(
              color: theme.textColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  autor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.textColor,
                  ),
                ),
                Text(
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 11.5,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: theme.secondaryTextColor,
            ),
            tooltip: 'Cancelar resposta',
            onPressed: widget.onCancelarResposta,
          ),
        ],
      ),
    );
  }

  Widget _buildBarraGravacaoSegurando(AppTheme theme) {
    return Listener(
      onPointerMove: _aoMoverMic,
      onPointerUp: (_) => _aoSoltarMic(),
      onPointerCancel: (_) => _aoSoltarMic(),
      child: Row(
        children: [
          Expanded(
            child: Transform.translate(
              offset: Offset(_dx * 0.4, 0),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: theme.dangerColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: theme.dangerColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    FadeTransition(
                      opacity: Tween(begin: 0.35, end: 1.0).animate(_pulseCtrl),
                      child: Icon(
                        Icons.fiber_manual_record_rounded,
                        color: theme.dangerColor,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ValueListenableBuilder<Duration>(
                      valueListenable:
                          GravadorAudioService.instancia.duracaoNotifier,
                      builder: (_, dur, _) {
                        final min = dur.inMinutes;
                        final sec = dur.inSeconds % 60;
                        return Text(
                          '$min:${sec.toString().padLeft(2, '0')}',
                          style: theme.getTextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    Text(
                      '← Cancelar  •  ↑ Travar',
                      style: theme.getTextStyle(
                        fontSize: 11.5,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.translate(
                offset: Offset(0, (_dy * 0.35).clamp(-22.0, 0.0)),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: _dy < -28 ? theme.textColor : theme.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 2),
              ScaleTransition(
                scale: Tween(begin: 1.0, end: 1.16).animate(_pulseCtrl),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.dangerColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mic_rounded,
                    size: 21,
                    color: theme.buttonTextColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarraGravacaoTravada(AppTheme theme) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            Icons.delete_outline_rounded,
            color: theme.dangerColor,
            size: 24,
          ),
          tooltip: 'Cancelar e descartar áudio',
          onPressed: _cancelarAudio,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: theme.dangerColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(21),
              border: Border.all(
                color: theme.dangerColor.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_rounded,
                  color: theme.dangerColor,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  'Gravação travada',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.dangerColor,
                  ),
                ),
                const Spacer(),
                ValueListenableBuilder<Duration>(
                  valueListenable:
                      GravadorAudioService.instancia.duracaoNotifier,
                  builder: (_, dur, _) {
                    final min = dur.inMinutes;
                    final sec = dur.inSeconds % 60;
                    return Text(
                      '$min:${sec.toString().padLeft(2, '0')}',
                      style: theme.getTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        ValueListenableBuilder<bool>(
          valueListenable: GravadorAudioService.instancia.pausadoNotifier,
          builder: (_, pausado, _) {
            return IconButton(
              icon: Icon(
                pausado ? Icons.mic_rounded : Icons.pause_circle_outline_rounded,
                color: pausado ? theme.dangerColor : theme.textColor,
                size: 25,
              ),
              tooltip: pausado ? 'Retomar gravação' : 'Pausar gravação',
              onPressed: () {
                if (pausado) {
                  GravadorAudioService.instancia.retomarGravacao();
                } else {
                  GravadorAudioService.instancia.pausarGravacao();
                }
              },
            );
          },
        ),
        IconButton(
          icon: Icon(
            Icons.stop_circle_outlined,
            color: theme.textColor,
            size: 25,
          ),
          tooltip: 'Parar e ouvir antes de enviar',
          onPressed: _finalizarParaPreEscuta,
        ),
        const SizedBox(width: 4),
        InkWell(
          onTap: _finalizarEEnviarAudio,
          borderRadius: BorderRadius.circular(21),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.buttonColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.send_rounded,
              size: 18,
              color: theme.buttonTextColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarraPreEscutaAudio(
    AppTheme theme,
    ({String caminho, String duracaoTexto, int tamanho}) pendente,
  ) {
    return ValueListenableBuilder<DadosPlayerAudio>(
      valueListenable: PlayerAudioService.instancia.estadoNotifier,
      builder: (context, dados, _) {
        final ehEste = PlayerAudioService.instancia.ehMesmoAudio(
              pendente.caminho,
              dados.caminho,
            ) ||
            PlayerAudioService.instancia.ehMesmoAudio(
              pendente.caminho,
              dados.caminhoOriginal,
            );
        final tocando =
            ehEste && dados.estado == EstadoPlayerAudio.reproduzindo;
        final totalMs = dados.duracaoEstimada.inMilliseconds;
        final posMs = ehEste ? dados.posicao.inMilliseconds : 0;
        final progresso = (ehEste && totalMs > 0)
            ? (posMs / totalMs).clamp(0.0, 1.0)
            : 0.0;

        return Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: theme.dangerColor,
                size: 24,
              ),
              tooltip: 'Descartar áudio',
              onPressed: _descartarAudioPendente,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: theme.backgroundColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32),
                      tooltip: tocando ? 'Pausar' : 'Ouvir áudio',
                      onPressed: () => PlayerAudioService.instancia
                          .alternarPlayPause(pendente.caminho),
                      icon: Icon(
                        tocando
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: theme.textColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progresso,
                          minHeight: 4,
                          backgroundColor:
                              theme.borderColor.withValues(alpha: 0.35),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.textColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      pendente.duracaoTexto,
                      style: theme.getTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _enviarAudioPendente,
              borderRadius: BorderRadius.circular(21),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.buttonColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send_rounded,
                  size: 18,
                  color: theme.buttonTextColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBarraComposicao(AppTheme theme, bool temTexto) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            Icons.camera_alt_rounded,
            color: theme.textColor,
            size: 22,
          ),
          tooltip: 'Câmera / Tirar foto',
          onPressed: widget.onCapturarFotoCamera,
        ),
        IconButton(
          icon: Icon(
            Icons.attach_file_rounded,
            color: theme.textColor,
            size: 22,
          ),
          tooltip: 'Anexar imagem, arquivo, comanda ou áudio',
          onPressed: widget.onAbrirMenuAnexo,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 42, maxHeight: 110),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: theme.backgroundColor,
              borderRadius: BorderRadius.circular(21),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.6),
              ),
            ),
            child: Focus(
              onKeyEvent: (node, event) {
                if (!Platform.isAndroid && !Platform.isIOS) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.enter) {
                    if (HardwareKeyboard.instance.isShiftPressed) {
                      return KeyEventResult.ignored;
                    } else {
                      widget.onEnviarTexto();
                      return KeyEventResult.handled;
                    }
                  }
                }
                return KeyEventResult.ignored;
              },
              child: TextField(
                controller: widget.mensagemController,
                keyboardType: TextInputType.multiline,
                textInputAction: (Platform.isAndroid || Platform.isIOS)
                    ? TextInputAction.newline
                    : TextInputAction.send,
                minLines: 1,
                maxLines: 4,
                style: theme.getTextStyle(fontSize: 13, color: theme.textColor),
                onSubmitted: (Platform.isAndroid || Platform.isIOS)
                    ? null
                    : (_) => widget.onEnviarTexto(),
                decoration: InputDecoration(
                  hintText: widget.controller.modoLoja
                      ? 'Responder em nome de ${widget.controller.nomeLoja ?? "Loja"}...'
                      : 'Digite uma mensagem...',
                  hintStyle: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.secondaryTextColor,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (temTexto)
          InkWell(
            onTap: widget.onEnviarTexto,
            borderRadius: BorderRadius.circular(21),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.buttonColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send_rounded,
                size: 19,
                color: theme.buttonTextColor,
              ),
            ),
          )
        else
          Listener(
            onPointerDown: _aoPressionarMic,
            onPointerMove: _aoMoverMic,
            onPointerUp: (_) => _aoSoltarMic(),
            onPointerCancel: (_) => _aoSoltarMic(),
            child: Tooltip(
              message: 'Segure para gravar • Arraste ↑ para travar',
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.buttonColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mic_rounded,
                  size: 19,
                  color: theme.buttonTextColor,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
