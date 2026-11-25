import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/services/gravador_audio_service.dart';

/// Barra exibida enquanto o usuário segura o botão de microfone para gravar áudio.
class BarraGravacaoSegurandoWidget extends StatelessWidget {
  final AppTheme theme;
  final AnimationController pulseController;
  final double dx;
  final double dy;
  final void Function(PointerMoveEvent) onPointerMove;
  final VoidCallback onPointerEnd;

  const BarraGravacaoSegurandoWidget({
    super.key,
    required this.theme,
    required this.pulseController,
    required this.dx,
    required this.dy,
    required this.onPointerMove,
    required this.onPointerEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: onPointerMove,
      onPointerUp: (_) => onPointerEnd(),
      onPointerCancel: (_) => onPointerEnd(),
      child: Row(
        children: [
          Expanded(
            child: Transform.translate(
              offset: Offset(dx * 0.4, 0),
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
                      opacity: Tween(begin: 0.35, end: 1.0)
                          .animate(pulseController),
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
                offset: Offset(0, (dy * 0.35).clamp(-22.0, 0.0)),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: dy < -28 ? theme.textColor : theme.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 2),
              ScaleTransition(
                scale: Tween(begin: 1.0, end: 1.16).animate(pulseController),
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
}

/// Barra exibida quando a gravação de áudio está travada (modo mãos livres).
class BarraGravacaoTravadaWidget extends StatelessWidget {
  final AppTheme theme;
  final VoidCallback onCancelar;
  final VoidCallback onFinalizarParaPreEscuta;
  final VoidCallback onFinalizarEEnviar;

  const BarraGravacaoTravadaWidget({
    super.key,
    required this.theme,
    required this.onCancelar,
    required this.onFinalizarParaPreEscuta,
    required this.onFinalizarEEnviar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            Icons.delete_outline_rounded,
            color: theme.dangerColor,
            size: 24,
          ),
          tooltip: 'Cancelar e descartar áudio',
          onPressed: onCancelar,
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
                pausado
                    ? Icons.mic_rounded
                    : Icons.pause_circle_outline_rounded,
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
          onPressed: onFinalizarParaPreEscuta,
        ),
        const SizedBox(width: 4),
        InkWell(
          onTap: onFinalizarEEnviar,
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
}
