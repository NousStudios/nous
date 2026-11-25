import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/timeline/controllers/player_universal_controller.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';

/// Barra superior do player universal expandido com minimizar, alternância
/// Música/Vídeo e atalho para detalhes da publicação original.
class PlayerUniversalBarraTopo extends StatelessWidget {
  final AppTheme theme;
  final PublicacaoSocial publicacao;
  final PlayerUniversalController controller;
  final VoidCallback onAbrirDetalhes;

  const PlayerUniversalBarraTopo({
    super.key,
    required this.theme,
    required this.publicacao,
    required this.controller,
    required this.onAbrirDetalhes,
  });

  @override
  Widget build(BuildContext context) {
    final temAudio = PlayerUniversalController.possuiAudio(publicacao);
    final temVideo = PlayerUniversalController.possuiVideo(publicacao);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Minimizar',
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: theme.textColor,
              size: 28,
            ),
          ),
          const Spacer(),
          if (temAudio || temVideo)
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: theme.cardBackgroundColor.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.borderColor.withValues(alpha: 0.65),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BotaoModoPlayer(
                    theme: theme,
                    label: 'Música',
                    ativo: !controller.modoVideo,
                    habilitado: temAudio,
                    onTap: () => controller.definirModoVideo(false),
                  ),
                  _BotaoModoPlayer(
                    theme: theme,
                    label: 'Vídeo',
                    ativo: controller.modoVideo,
                    habilitado: temVideo,
                    onTap: () => controller.definirModoVideo(true),
                  ),
                ],
              ),
            ),
          const Spacer(),
          IconButton(
            tooltip: 'Abrir publicação original',
            onPressed: onAbrirDetalhes,
            icon: Icon(
              Icons.open_in_new_rounded,
              color: theme.textColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _BotaoModoPlayer extends StatelessWidget {
  final AppTheme theme;
  final String label;
  final bool ativo;
  final bool habilitado;
  final VoidCallback onTap;

  const _BotaoModoPlayer({
    required this.theme,
    required this.label,
    required this.ativo,
    required this.habilitado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: habilitado ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: ativo
              ? theme.textColor.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: !habilitado
                ? theme.secondaryTextColor.withValues(alpha: 0.38)
                : ativo
                    ? theme.textColor
                    : theme.secondaryTextColor,
            fontSize: 12.5,
            fontWeight: ativo ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
