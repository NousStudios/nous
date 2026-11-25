import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Capa exibida antes da ativação do player de vídeo, com botão central de play.
class PlayerVideoCapaWidget extends StatelessWidget {
  final AppTheme theme;
  final String? capaResolvida;
  final Uint8List? bytesCapaFallback;
  final String titulo;
  final VoidCallback onTapIniciar;

  const PlayerVideoCapaWidget({
    super.key,
    required this.theme,
    required this.capaResolvida,
    required this.bytesCapaFallback,
    required this.titulo,
    required this.onTapIniciar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapIniciar,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (capaResolvida != null && File(capaResolvida!).existsSync())
            Image.file(
              File(capaResolvida!),
              fit: BoxFit.cover,
              cacheWidth: 1080,
            )
          else if (bytesCapaFallback != null)
            Image.memory(
              bytesCapaFallback!,
              fit: BoxFit.cover,
              cacheWidth: 1080,
            )
          else
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam_outlined,
                  size: 40,
                  color: theme.secondaryTextColor,
                ),
                if (titulo.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          Center(
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: theme.cardBackgroundColor.withValues(alpha: 0.80),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.textColor.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                size: 32,
                color: theme.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
