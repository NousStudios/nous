import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/theme/theme_customizer_dialog.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
  });

  void _showThemeSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Escutamos DOIS ValueNotifiers ao mesmo tempo: o tema atual (para saber
        // as cores certas de desenhar o próprio seletor) e a lista de temas salvos
        // (para exibi-los e atualizar a lista assim que um novo tema é salvo/apagado).
        return ValueListenableBuilder<AppTheme>(
          valueListenable: ThemeController.currentTheme,
          builder: (context, currentTheme, child) {
            return ValueListenableBuilder<List<SavedTheme>>(
              valueListenable: ThemeController.savedThemes,
              builder: (context, savedThemesList, child) {
                // Largura responsiva, para não repetir o mesmo bug de overflow em
                // telas pequenas que já corrigimos no popup de personalização.
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
                    ),
                  ),
                  content: SizedBox(
                    width: selectorWidth,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ============ TEMAS PRÉ-DEFINIDOS ============
                          ListTile(
                            leading: Icon(Icons.dark_mode, color: currentTheme.textColor),
                            title: Text('Modo Escuro (Padrão)', style: currentTheme.getTextStyle()),
                            onTap: () {
                              ThemeController.updateTheme(AppTheme.dark);
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.light_mode, color: currentTheme.textColor),
                            title: Text('Modo Claro', style: currentTheme.getTextStyle()),
                            onTap: () {
                              ThemeController.updateTheme(AppTheme.light);
                              Navigator.pop(context);
                            },
                          ),

                          // ============ TEMAS SALVOS PELO USUÁRIO ============
                          // Essa seção só aparece se existir pelo menos um tema salvo
                          if (savedThemesList.isNotEmpty) ...[
                            Divider(color: currentTheme.borderColor),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                                leading: Icon(Icons.palette, color: currentTheme.textColor),
                                title: Text(saved.name, style: currentTheme.getTextStyle()),
                                // Botão de lixeira para apagar esse tema salvo específico
                                trailing: IconButton(
                                  icon: Icon(Icons.delete_outline, color: currentTheme.secondaryTextColor),
                                  tooltip: 'Excluir tema',
                                  onPressed: () => ThemeController.deleteSavedTheme(saved.name),
                                ),
                                onTap: () {
                                  ThemeController.updateTheme(saved.theme);
                                  Navigator.pop(context);
                                },
                              );
                            }),
                          ],

                          Divider(color: currentTheme.borderColor),

                          // ============ ABRIR A PALETA COMPLETA DE PERSONALIZAÇÃO ============
                          // É lá dentro que agora mora a opção "Salvar Tema Atual..."
                          ListTile(
                            leading: Icon(Icons.color_lens_outlined, color: currentTheme.textColor),
                            title: Text(
                              'Personalizar Cores e Fontes...',
                              style: currentTheme.getTextStyle(),
                            ),
                            onTap: () {
                              Navigator.pop(context); // Fecha o seletor simples
                              showDialog(
                                context: context,
                                builder: (_) => const ThemeCustomizerDialog(), // Abre a paleta completa
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
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return ValueListenableBuilder<AppTheme>(
          valueListenable: ThemeController.currentTheme,
          builder: (context, currentTheme, child) {
            return AlertDialog(
              backgroundColor: currentTheme.cardBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: BorderSide(color: currentTheme.borderColor),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 8.0),
              title: Text(
                'Configurações',
                textAlign: TextAlign.center,
                style: currentTheme.getTextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(Icons.palette_outlined, color: currentTheme.secondaryTextColor),
                    title: Text('Tema', style: currentTheme.getTextStyle()),
                    onTap: () {
                      Navigator.pop(context); // Fecha o menu principal de configurações antes de abrir a seleção de temas
                      _showThemeSelector(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.language, color: currentTheme.secondaryTextColor),
                    title: Text('Idioma', style: currentTheme.getTextStyle()),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: Icon(Icons.info_outline, color: currentTheme.secondaryTextColor),
                    title: Text('Sobre o App', style: currentTheme.getTextStyle()),
                    onTap: () {},
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Fechar',
                    style: currentTheme.getTextStyle(color: currentTheme.secondaryTextColor),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return AppBar(
          backgroundColor: theme.backgroundColor,
          elevation: 0,
          title: Text(
            title,
            style: theme.getTextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          leading: showBackButton
              ? IconButton(
                  icon: Icon(Icons.arrow_back, color: theme.textColor),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null,
          actions: [
            IconButton(
              tooltip: 'Configurações',
              icon: Image.asset(
                'assets/icons/settings_icon.png',
                width: 24,
                height: 24,
                color: theme.textColor,
              ),
              onPressed: () => _showSettingsDialog(context),
            ),
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}