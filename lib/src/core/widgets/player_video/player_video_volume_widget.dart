import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Controle vertical flutuante de volume e mute do player de vídeo.
class PlayerVideoVolumeWidget extends StatelessWidget {
  final AppTheme theme;
  final double volume;
  final ValueChanged<double> onChangedVolume;
  final VoidCallback onToggleMute;
  final ValueChanged<bool> onHoverChanged;

  const PlayerVideoVolumeWidget({
    super.key,
    required this.theme,
    required this.volume,
    required this.onChangedVolume,
    required this.onToggleMute,
    required this.onHoverChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 6,
      bottom: 42,
      child: MouseRegion(
        onEnter: (_) => onHoverChanged(true),
        onExit: (_) => onHoverChanged(false),
        child: Container(
          width: 40,
          height: 152,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: theme.cardBackgroundColor.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.borderColor.withValues(alpha: 0.55),
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: RotatedBox(
                  quarterTurns: 3,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3.5,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7.0,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                    ),
                    child: Slider(
                      value: volume,
                      min: 0.0,
                      max: 100.0,
                      activeColor: theme.textColor,
                      inactiveColor: theme.borderColor.withValues(alpha: 0.45),
                      onChanged: onChangedVolume,
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: onToggleMute,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    volume <= 0
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    size: 16,
                    color: theme.textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
