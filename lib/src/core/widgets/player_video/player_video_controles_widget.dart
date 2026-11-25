import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Overlay de controles do player ativo: gestos de velocidade 2x,
/// indicador de velocidade e barra inferior de progresso, play/pause e volume.
class PlayerVideoControlesWidget extends StatelessWidget {
  final AppTheme theme;
  final bool mostrarControles;
  final bool tocando;
  final bool avancando2x;
  final bool voltando2x;
  final double posMs;
  final double maxMs;
  final Duration posicaoExibida;
  final Duration duracao;
  final double volume;
  final VoidCallback onIniciarRetrocesso2x;
  final VoidCallback onPararRetrocesso2x;
  final VoidCallback onIniciarAvanco2x;
  final VoidCallback onPararAvanco2x;
  final ValueChanged<double> onSliderChangeStart;
  final ValueChanged<double> onSliderChanged;
  final ValueChanged<double> onSliderChangeEnd;
  final VoidCallback onTogglePlayPause;
  final ValueChanged<bool> onVolumeHoverChanged;
  final VoidCallback onVolumeTap;

  const PlayerVideoControlesWidget({
    super.key,
    required this.theme,
    required this.mostrarControles,
    required this.tocando,
    required this.avancando2x,
    required this.voltando2x,
    required this.posMs,
    required this.maxMs,
    required this.posicaoExibida,
    required this.duracao,
    required this.volume,
    required this.onIniciarRetrocesso2x,
    required this.onPararRetrocesso2x,
    required this.onIniciarAvanco2x,
    required this.onPararAvanco2x,
    required this.onSliderChangeStart,
    required this.onSliderChanged,
    required this.onSliderChangeEnd,
    required this.onTogglePlayPause,
    required this.onVolumeHoverChanged,
    required this.onVolumeTap,
  });

  String _formatarDuracao(Duration d) {
    final total = d.inSeconds;
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Quadrantes superiores: segurar esquerda volta 2x, direita avança 2x
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 72,
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onLongPressStart: (_) => onIniciarRetrocesso2x(),
                  onLongPressEnd: (_) => onPararRetrocesso2x(),
                  onLongPressCancel: onPararRetrocesso2x,
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onLongPressStart: (_) => onIniciarAvanco2x(),
                  onLongPressEnd: (_) => onPararAvanco2x(),
                  onLongPressCancel: onPararAvanco2x,
                ),
              ),
            ],
          ),
        ),
        if (voltando2x || avancando2x)
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: theme.cardBackgroundColor.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  voltando2x ? '<< 2x' : '2x >>',
                  style: theme.getTextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
            ),
          ),
        if (mostrarControles)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    theme.cardBackgroundColor.withValues(alpha: 0.92),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4.0,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7.0,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                    ),
                    child: Slider(
                      value: posMs,
                      min: 0.0,
                      max: maxMs,
                      activeColor: theme.textColor,
                      inactiveColor: theme.borderColor.withValues(alpha: 0.45),
                      onChangeStart: onSliderChangeStart,
                      onChanged: onSliderChanged,
                      onChangeEnd: onSliderChangeEnd,
                    ),
                  ),
                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: onTogglePlayPause,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            tocando
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 22,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_formatarDuracao(posicaoExibida)} / ${_formatarDuracao(duracao)}',
                        style: theme.getTextStyle(
                          fontSize: 11.5,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      MouseRegion(
                        onEnter: (_) => onVolumeHoverChanged(true),
                        onExit: (_) => onVolumeHoverChanged(false),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: onVolumeTap,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              volume <= 0
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                              size: 20,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
