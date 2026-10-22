import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/core/widgets/floating_bottom_nav_bar.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';

class EmConstrucaoView extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icone;
  final int slotSelecionado;
  final int subIndiceSelecionado;

  const EmConstrucaoView({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.icone,
    required this.slotSelecionado,
    required this.subIndiceSelecionado,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: CustomAppBar(
            title: titulo,
            showBackButton: false,
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: theme.cardBackgroundColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.borderColor.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          icone,
                          size: 44,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextoRolante(
                        texto: titulo,
                        textAlign: TextAlign.center,
                        style: theme.getTextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextoRolante(
                        texto: subtitulo,
                        textAlign: TextAlign.center,
                        style: theme.getTextStyle(
                          fontSize: 13,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.cardBackgroundColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.borderColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.construction_rounded,
                              size: 16,
                              color: theme.secondaryTextColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Em construção',
                              style: theme.getTextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: FloatingBottomNavBar(
            maxWidth: 600,
            slotSelecionado: slotSelecionado,
            subIndiceSelecionado: subIndiceSelecionado,
          ),
        );
      },
    );
  }
}
