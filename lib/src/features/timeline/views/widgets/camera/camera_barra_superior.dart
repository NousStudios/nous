import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Barra superior da câmera com botão de retorno, indicador de gravação e troca de lente.
class CameraBarraSuperior extends StatelessWidget {
  final AppTheme theme;
  final bool gravandoVideo;
  final VoidCallback onVoltarPerfil;
  final VoidCallback onAlternarCamera;

  const CameraBarraSuperior({
    super.key,
    required this.theme,
    required this.gravandoVideo,
    required this.onVoltarPerfil,
    required this.onAlternarCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          tooltip: 'Voltar ao perfil',
          icon: Icon(
            Icons.arrow_forward_ios_rounded,
            color: theme.textColor,
          ),
          onPressed: onVoltarPerfil,
        ),
        if (gravandoVideo)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: theme.dangerColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'GRAVANDO...',
              style: theme.getTextStyle(
                color: theme.textColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        IconButton(
          tooltip: 'Inverter câmera',
          icon: Icon(
            Icons.cameraswitch_rounded,
            color: theme.textColor,
          ),
          onPressed: onAlternarCamera,
        ),
      ],
    );
  }
}
