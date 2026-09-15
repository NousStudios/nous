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
        return ValueListenableBuilder<AppTheme>(
          valueListenable: ThemeController.currentTheme,
          builder: (context, currentTheme, child) {
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
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  Divider(color: currentTheme.borderColor),
                  
                  // BOTÃO PARA ABRIR A PALETA PERSONALIZADA / CÍRCULO CROMÁTICO
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