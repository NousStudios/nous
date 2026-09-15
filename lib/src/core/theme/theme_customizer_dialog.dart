import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Modal dialog responsável pela customização em tempo real do tema da aplicação.
/// Permite alterar cor de fundo, cor do texto, cor dos botões e a fonte tipográfica.
class ThemeCustomizerDialog extends StatelessWidget {
  const ThemeCustomizerDialog({super.key});

  // Lista de cores disponíveis para o Fundo da aplicação
  static const List<Color> backgroundColors = [
    Colors.black,
    Color(0xFF121212),
    Color(0xFF1A1A24),
    Color(0xFF0F172A),
    Color(0xFF18181B),
    Color(0xFFF5F5F5),
    Colors.white,
  ];

  // Lista de cores disponíveis para os Textos da aplicação
  static const List<Color> textColors = [
    Colors.white,
    Color(0xFFE2E8F0),
    Color(0xFFA1A1AA),
    Color(0xFF38BDF8),
    Color(0xFF4ADE80),
    Colors.black87,
  ];

  // Lista de cores disponíveis para os Botões
  static const List<Color> buttonColors = [
    Colors.white,
    Color(0xFF38BDF8),
    Color(0xFF4ADE80),
    Color(0xFFA855F7),
    Color(0xFFF43F5E),
    Colors.black,
  ];

  // Lista de fontes suportadas
  static const List<String> fonts = ['Inter', 'Roboto', 'Poppins', 'Lato'];

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder escuta as alterações em tempo real do ThemeController
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return AlertDialog(
          // Cor de fundo dinâmica vinda do tema personalizado do projeto
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
                // --- 1. SELEÇÃO DA COR DE FUNDO ---
                Text(
                  'Cor de Fundo',
                  style: theme.getTextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: backgroundColors.map((color) {
                    final isSelected = theme.backgroundColor.toARGB32() == color.toARGB32();
                    return GestureDetector(
                      onTap: () => ThemeController.updateBackgroundColor(color),
                      child: Container(
                        width: 36,
                        height: 36,
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
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // --- 2. SELEÇÃO DA COR DO TEXTO ---
                Text(
                  'Cor do Texto',
                  style: theme.getTextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: textColors.map((color) {
                    final isSelected = theme.textColor.toARGB32() == color.toARGB32();
                    return GestureDetector(
                      onTap: () => ThemeController.updateTextColor(color),
                      child: Container(
                        width: 36,
                        height: 36,
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
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // --- 3. SELEÇÃO DA COR DOS BOTÕES ---
                Text(
                  'Cor dos Botões',
                  style: theme.getTextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: buttonColors.map((color) {
                    final isSelected = theme.buttonColor.toARGB32() == color.toARGB32();
                    return GestureDetector(
                      onTap: () => ThemeController.updateButtonColor(color),
                      child: Container(
                        width: 36,
                        height: 36,
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
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // --- 4. SELEÇÃO DA FONTE (DROPDOWN) ---
                Text(
                  'Fonte do Texto',
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