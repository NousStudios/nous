import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/timeline/controllers/player_universal_controller.dart';

/// Barra de progresso (em modo áudio) e controles de reprodução do player
/// universal (aleatório, anterior, play/pause, próxima e repetir).
class PlayerUniversalControlesReproducao extends StatelessWidget {
  final AppTheme theme;
  final PlayerUniversalController controller;

  const PlayerUniversalControlesReproducao({
    super.key,
    required this.theme,
    required this.controller,
  });

  String _formatarDuracao(Duration d) {
    final total = d.inSeconds.clamp(0, 86400);
    final min = (total ~/ 60).toString().padLeft(2, '0');
    final seg = (total % 60).toString().padLeft(2, '0');
    return '$min:$seg';
  }

  @override
  Widget build(BuildContext context) {
    final duracao = controller.estadoAudio.duracaoEstimada;
    final pos = controller.estadoAudio.posicao;
    final maxMs = duracao.inMilliseconds > 0 ? duracao.inMilliseconds : 1;
    final posMs = pos.inMilliseconds.clamp(0, maxMs);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!controller.modoVideo) ...[
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: theme.textColor,
              inactiveTrackColor: theme.borderColor.withValues(alpha: 0.4),
              thumbColor: theme.textColor,
            ),
            child: Slider(
              value: posMs.toDouble(),
              min: 0,
              max: maxMs.toDouble(),
              onChanged: (v) {
                controller.buscarPosicao(Duration(milliseconds: v.round()));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatarDuracao(pos),
                  style: TextStyle(
                    color: theme.secondaryTextColor,
                    fontSize: 11.5,
                  ),
                ),
                Text(
                  _formatarDuracao(duracao),
                  style: TextStyle(
                    color: theme.secondaryTextColor,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              tooltip: 'Aleatório',
              onPressed: controller.alternarAleatorio,
              icon: Icon(
                Icons.shuffle_rounded,
                color: controller.aleatorio
                    ? theme.textColor
                    : theme.secondaryTextColor.withValues(alpha: 0.65),
                size: 22,
              ),
            ),
            IconButton(
              tooltip: 'Anterior',
              onPressed: controller.anterior,
              icon: Icon(
                Icons.skip_previous_rounded,
                color: theme.textColor,
                size: 32,
              ),
            ),
            if (!controller.modoVideo)
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: theme.textColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  tooltip: controller.estaTocando ? 'Pausar' : 'Reproduzir',
                  onPressed: controller.alternarPlayPause,
                  icon: Icon(
                    controller.estaTocando
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: theme.backgroundColor,
                    size: 32,
                  ),
                ),
              ),
            IconButton(
              tooltip: 'Próxima',
              onPressed: controller.proxima,
              icon: Icon(
                Icons.skip_next_rounded,
                color: theme.textColor,
                size: 32,
              ),
            ),
            IconButton(
              tooltip: 'Repetir',
              onPressed: controller.alternarRepetir,
              icon: Icon(
                Icons.repeat_rounded,
                color: controller.repetir
                    ? theme.textColor
                    : theme.secondaryTextColor.withValues(alpha: 0.65),
                size: 22,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
