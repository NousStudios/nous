import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Fundo da tela de câmera exibindo o preview ao vivo ou estado de espera.
class CameraPreviewFundo extends StatelessWidget {
  final AppTheme theme;
  final RTCVideoRenderer renderer;
  final bool cameraPronta;
  final bool cameraFrontal;

  const CameraPreviewFundo({
    super.key,
    required this.theme,
    required this.renderer,
    required this.cameraPronta,
    required this.cameraFrontal,
  });

  @override
  Widget build(BuildContext context) {
    if (cameraPronta) {
      return RTCVideoView(
        renderer,
        mirror: cameraFrontal,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 56,
            color: theme.textColor.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 10),
          Text(
            kIsWeb || Platform.isWindows
                ? 'Toque na câmera ou escolha da galeria'
                : 'Preparando câmera...',
            style: theme.getTextStyle(
              fontSize: 13,
              color: theme.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
