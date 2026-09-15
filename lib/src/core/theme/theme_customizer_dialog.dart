import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

class ThemeCustomizerDialog extends StatelessWidget {
  const ThemeCustomizerDialog({super.key});

  static const List<String> fonts = ['Inter', 'Roboto', 'Poppins', 'Lato'];

  // Utilitário para converter String Hexadecimal em Color
  static Color? _parseHexColor(String hexString) {
    final cleanHex = hexString.replaceAll('#', '').trim();
    if (cleanHex.length == 6) {
      final val = int.tryParse('FF$cleanHex', radix: 16);
      if (val != null) return Color(val);
    } else if (cleanHex.length == 8) {
      final val = int.tryParse(cleanHex, radix: 16);
      if (val != null) return Color(val);
    }
    return null;
  }

  // Modal para escolher qualquer cor via Hexadecimal ou presets livres
  void _openCustomColorPicker(
    BuildContext context,
    AppTheme theme,
    String title,
    Color currentColor,
    Function(Color) onColorSelected,
  ) {
    final controller = TextEditingController(
      text: '#${currentColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
    );

    showDialog(
      context: context,
      builder: (dialogCtx) {
        Color tempColor = currentColor;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: theme.cardBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.borderColor),
              ),
              title: Text(title, style: theme.getTextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: tempColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.borderColor, width: 2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    style: theme.getTextStyle(color: theme.textColor),
                    decoration: InputDecoration(
                      labelText: 'Código Hexadecimal',
                      labelStyle: theme.getTextStyle(color: theme.secondaryTextColor),
                      hintText: '#FF0000',
                      hintStyle: theme.getTextStyle(color: theme.secondaryTextColor),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: theme.borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.blue),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (val) {
                      final parsed = _parseHexColor(val);
                      if (parsed != null) {
                        setState(() => tempColor = parsed);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text('Cancelar', style: theme.getTextStyle(color: theme.secondaryTextColor)),
                ),
                TextButton(
                  onPressed: () {
                    onColorSelected(tempColor);
                    Navigator.of(dialogCtx).pop();
                  },
                  child: Text('Aplicar', style: theme.getTextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildColorRow({
    required BuildContext context,
    required AppTheme theme,
    required String title,
    required Color currentColor,
    required List<Color> recentColors,
    required Function(Color) onSelectColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.getTextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            // Exibe as duas últimas cores selecionadas
            ...recentColors.map((color) {
              final isSelected = currentColor.toARGB32() == color.toARGB32();
              return GestureDetector(
                onTap: () => onSelectColor(color),
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.blue : theme.borderColor,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                ),
              );
            }),
            // Botão "+" para abrir o menu de personalização Hex/Livre
            GestureDetector(
              onTap: () => _openCustomColorPicker(context, theme, 'Escolher $title', currentColor, onSelectColor),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.borderColor, width: 1.5),
                ),
                child: Icon(Icons.add, color: theme.textColor, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Personalizar Aparência',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Cor de Fundo
                _buildColorRow(
                  context: context,
                  theme: theme,
                  title: 'Cor de Fundo',
                  currentColor: theme.backgroundColor,
                  recentColors: ThemeController.recentBackgroundColors,
                  onSelectColor: ThemeController.updateBackgroundColor,
                ),
                const SizedBox(height: 20),

                // 2. Cor do Texto
                _buildColorRow(
                  context: context,
                  theme: theme,
                  title: 'Cor do Texto',
                  currentColor: theme.textColor,
                  recentColors: ThemeController.recentTextColors,
                  onSelectColor: ThemeController.updateTextColor,
                ),
                const SizedBox(height: 20),

                // 3. Cor dos Botões
                _buildColorRow(
                  context: context,
                  theme: theme,
                  title: 'Cor dos Botões',
                  currentColor: theme.buttonColor,
                  recentColors: ThemeController.recentButtonColors,
                  onSelectColor: ThemeController.updateButtonColor,
                ),
                const SizedBox(height: 20),

                // 4. Fonte da Aplicação
                Text(
                  'Fonte da Aplicação',
                  style: theme.getTextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                InputDecorator(
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.blue),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: theme.fontName,
                      dropdownColor: theme.cardBackgroundColor,
                      isExpanded: true,
                      items: fonts.map((font) {
                        return DropdownMenuItem<String>(
                          value: font,
                          child: Text(
                            font,
                            style: theme.getTextStyle(color: theme.textColor),
                          ),
                        );
                      }).toList(),
                      onChanged: (newFont) {
                        if (newFont != null) {
                          ThemeController.updateFont(newFont);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Concluído',
                style: theme.getTextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}