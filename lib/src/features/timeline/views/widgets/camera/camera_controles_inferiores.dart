import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/timeline/views/widgets/camera_criacao_view.dart';

/// Controles inferiores da câmera: disparador foto/vídeo, atalho de galeria e seletor de destino.
class CameraControlesInferiores extends StatelessWidget {
  final AppTheme theme;
  final bool gravandoVideo;
  final bool processando;
  final DestinoCapturaCamera destino;
  final String Function(DestinoCapturaCamera) rotuloDestino;
  final VoidCallback onTirarFoto;
  final VoidCallback onIniciarGravacaoVideo;
  final VoidCallback onPararGravacaoVideo;
  final VoidCallback onAbrirGaleria;
  final ValueChanged<DestinoCapturaCamera> onSelecionarDestino;

  const CameraControlesInferiores({
    super.key,
    required this.theme,
    required this.gravandoVideo,
    required this.processando,
    required this.destino,
    required this.rotuloDestino,
    required this.onTirarFoto,
    required this.onIniciarGravacaoVideo,
    required this.onPararGravacaoVideo,
    required this.onAbrirGaleria,
    required this.onSelecionarDestino,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Toque para foto • Segure para gravar vídeo',
          child: GestureDetector(
            onTap: onTirarFoto,
            onLongPressStart: (_) => onIniciarGravacaoVideo(),
            onLongPressEnd: (_) => onPararGravacaoVideo(),
            child: Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: gravandoVideo ? theme.dangerColor : theme.textColor,
                  width: 4,
                ),
                color: gravandoVideo
                    ? theme.dangerColor.withValues(alpha: 0.7)
                    : theme.textColor.withValues(alpha: 0.2),
              ),
              child: processando
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: theme.textColor,
                      ),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 44,
          child: Row(
            children: [
              const SizedBox(width: 12),
              InkWell(
                onTap: onAbrirGaleria,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.textColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.textColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Icon(
                    Icons.photo_library_outlined,
                    color: theme.textColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: DestinoCapturaCamera.values.map((d) {
                    final ativo = destino == d;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          rotuloDestino(d),
                          style: theme.getTextStyle(
                            fontSize: 12,
                            fontWeight:
                                ativo ? FontWeight.bold : FontWeight.normal,
                            color: ativo
                                ? theme.backgroundColor
                                : theme.textColor,
                          ),
                        ),
                        selected: ativo,
                        selectedColor: theme.textColor,
                        backgroundColor: theme.textColor.withValues(alpha: 0.14),
                        onSelected: (_) => onSelecionarDestino(d),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
