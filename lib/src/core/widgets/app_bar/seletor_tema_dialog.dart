import 'package:flutter/material.dart';
import 'package:nous/src/core/services/guarda_acao_ui.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/theme/theme_customizer_dialog.dart';

/// Diálogo de seleção rápida de tema (Escuro, Claro, salvos e personalização).
class SeletorTemaDialog {
  const SeletorTemaDialog._();

  static Future<void> mostrar(BuildContext context) {
    return GuardaAcaoUi.executarUnico<void>(
      'dialog_theme_selector',
      () => showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return ValueListenableBuilder<AppTheme>(
            valueListenable: ThemeController.currentTheme,
            builder: (context, currentTheme, child) {
              return ValueListenableBuilder<List<SavedTheme>>(
                valueListenable: ThemeController.savedThemes,
                builder: (context, savedThemesList, child) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final selectorWidth =
                      screenWidth < 360 ? screenWidth * 0.9 : 320.0;

                  return AlertDialog(
                    backgroundColor: currentTheme.cardBackgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      side: BorderSide(color: currentTheme.borderColor),
                    ),
                    title: Text(
                      'Aparência',
                      textAlign: TextAlign.center,
                      style: currentTheme.getTextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: currentTheme.textColor,
                      ),
                    ),
                    content: SizedBox(
                      width: selectorWidth,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: Icon(
                                Icons.dark_mode,
                                color: currentTheme.secondaryTextColor,
                              ),
                              title: Text(
                                'Modo Escuro (Padrão)',
                                style: currentTheme.getTextStyle(),
                              ),
                              onTap: () {
                                ThemeController.updateTheme(AppTheme.dark);
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              leading: Icon(
                                Icons.light_mode,
                                color: currentTheme.secondaryTextColor,
                              ),
                              title: Text(
                                'Modo Claro',
                                style: currentTheme.getTextStyle(),
                              ),
                              onTap: () {
                                ThemeController.updateTheme(AppTheme.light);
                                Navigator.pop(context);
                              },
                            ),
                            if (savedThemesList.isNotEmpty) ...[
                              Divider(color: currentTheme.borderColor),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Meus Temas',
                                    style: currentTheme.getTextStyle(
                                      fontSize: 12,
                                      color: currentTheme.secondaryTextColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              ...savedThemesList.map((saved) {
                                return ListTile(
                                  leading: Icon(
                                    Icons.palette,
                                    color: currentTheme.textColor,
                                  ),
                                  title: Text(
                                    saved.name,
                                    style: currentTheme.getTextStyle(),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: currentTheme.secondaryTextColor,
                                    ),
                                    tooltip: 'Excluir tema',
                                    onPressed: () => ThemeController
                                        .deleteSavedTheme(saved.name),
                                  ),
                                  onTap: () {
                                    ThemeController.updateTheme(saved.theme);
                                    Navigator.pop(context);
                                  },
                                );
                              }),
                            ],
                            Divider(color: currentTheme.borderColor),
                            ListTile(
                              leading: Icon(
                                Icons.color_lens_outlined,
                                color: currentTheme.secondaryTextColor,
                              ),
                              title: Text(
                                'Personalizar Cores e Fontes...',
                                style: currentTheme.getTextStyle(),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                showDialog<void>(
                                  context: context,
                                  builder: (_) => const ThemeCustomizerDialog(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
