import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

class AjustarImagemDialog extends StatefulWidget {
  final AppTheme theme;
  final String caminhoImagem;

  const AjustarImagemDialog({
    super.key,
    required this.theme,
    required this.caminhoImagem,
  });

  static Future<String?> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required String caminhoImagem,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AjustarImagemDialog(
        theme: theme,
        caminhoImagem: caminhoImagem,
      ),
    );
  }

  @override
  State<AjustarImagemDialog> createState() => _AjustarImagemDialogState();
}

class _AjustarImagemDialogState extends State<AjustarImagemDialog> {
  final GlobalKey _cropKey = GlobalKey();
  final TransformationController _transformController =
      TransformationController();
  bool _salvando = false;
  double _zoomAtual = 1.0;

  AppTheme get theme => widget.theme;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _ajustarZoom(double delta) {
    final scale =
        (_transformController.value.getMaxScaleOnAxis() + delta).clamp(1.0, 4.0);
    final matrix = Matrix4.diagonal3Values(scale, scale, 1.0);
    setState(() {
      _zoomAtual = scale;
      _transformController.value = matrix;
    });
  }

  void _resetarZoom() {
    setState(() {
      _zoomAtual = 1.0;
      _transformController.value = Matrix4.identity();
    });
  }

  Future<void> _concluirCorte() async {
    if (_salvando) return;
    setState(() => _salvando = true);

    try {
      final boundary =
          _cropKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) Navigator.of(context).pop(null);
        return;
      }

      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        if (mounted) Navigator.of(context).pop(null);
        return;
      }

      final bytes = byteData.buffer.asUint8List();
      final baseDir = await ImagemService.obterDiretorioBase();
      final pasta = Directory('${baseDir.path}/imagens');
      if (!await pasta.exists()) {
        await pasta.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final arquivoDestino =
          File('${pasta.path}/crop_$timestamp.png');
      await arquivoDestino.writeAsBytes(bytes);

      if (mounted) {
        Navigator.of(context).pop(arquivoDestino.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.cardBackgroundColor,
            content: Text(
              'Erro ao salvar recorte: $e',
              style: theme.getTextStyle(color: Colors.redAccent),
            ),
          ),
        );
        Navigator.of(context).pop(null);
      }
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final arquivo = File(widget.caminhoImagem);
    final existe = arquivo.existsSync();

    return AlertDialog(
      backgroundColor: theme.cardBackgroundColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor),
      ),
      title: Text(
        'Ajustar e Recortar Imagem',
        textAlign: TextAlign.center,
        style: theme.getTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: theme.textColor,
        ),
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Arraste e aproxime para enquadrar a parte desejada.',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 12,
                color: theme.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 12),

            // Área quadrada de recorte com RepaintBoundary
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.textColor,
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: RepaintBoundary(
                  key: _cropKey,
                  child: Container(
                    color: theme.backgroundColor,
                    child: existe
                        ? InteractiveViewer(
                            transformationController: _transformController,
                            minScale: 1.0,
                            maxScale: 4.0,
                            boundaryMargin: const EdgeInsets.all(80),
                            child: Image.file(
                              arquivo,
                              fit: BoxFit.contain,
                              width: 300,
                              height: 300,
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 48,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Controles de zoom rápido
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Diminuir zoom',
                  icon: Icon(Icons.zoom_out, color: theme.textColor, size: 20),
                  onPressed: () => _ajustarZoom(-0.25),
                ),
                Text(
                  '${(_zoomAtual * 100).toInt()}%',
                  style: theme.getTextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.secondaryTextColor,
                  ),
                ),
                IconButton(
                  tooltip: 'Aumentar zoom',
                  icon: Icon(Icons.zoom_in, color: theme.textColor, size: 20),
                  onPressed: () => _ajustarZoom(0.25),
                ),
                IconButton(
                  tooltip: 'Resetar enquadramento',
                  icon: Icon(Icons.restart_alt,
                      color: theme.secondaryTextColor, size: 20),
                  onPressed: _resetarZoom,
                ),
              ],
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: _salvando ? null : () => Navigator.of(context).pop(null),
          child: Text(
            'Cancelar',
            style: theme.getTextStyle(color: theme.secondaryTextColor),
          ),
        ),
        SizedBox(
          width: 130,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.textColor,
              side: BorderSide(color: theme.textColor, width: 1.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onPressed: _salvando ? null : _concluirCorte,
            child: _salvando
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.textColor,
                    ),
                  )
                : Text(
                    'Salvar Ajuste',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
