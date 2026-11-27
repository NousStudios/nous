import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

/// Carrossel de fotos do produto com contador e botão de tela cheia.
class GaleriaFotosProdutoWidget extends StatelessWidget {
  final AppTheme theme;
  final List<String> fotos;
  final int fotoAtual;
  final ValueChanged<int> onTrocarFoto;
  final VoidCallback onAbrirTelaCheia;

  const GaleriaFotosProdutoWidget({
    super.key,
    required this.theme,
    required this.fotos,
    required this.fotoAtual,
    required this.onTrocarFoto,
    required this.onAbrirTelaCheia,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 1.25,
        child: fotos.isEmpty
            ? _placeholderGrande()
            : Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: fotos.length,
                    onPageChanged: onTrocarFoto,
                    itemBuilder: (_, index) {
                      return GestureDetector(
                        onTap: onAbrirTelaCheia,
                        child: ImagemService.construirImagem(
                          fotos[index],
                          fit: BoxFit.cover,
                          fallback: _placeholderGrande(),
                        ),
                      );
                    },
                  ),
                  if (fotos.length > 1)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              theme.cardBackgroundColor.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.borderColor.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Text(
                          '${fotoAtual + 1}/${fotos.length}',
                          style: theme.getTextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: onAbrirTelaCheia,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color:
                              theme.cardBackgroundColor.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.borderColor.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Icon(
                          Icons.fullscreen_rounded,
                          size: 18,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _placeholderGrande() {
    return Container(
      color: theme.cardBackgroundColor,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 58,
          color: theme.secondaryTextColor.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
