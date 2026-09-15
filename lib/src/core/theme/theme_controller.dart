import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  final Color backgroundColor;
  final Color textColor;
  final Color secondaryTextColor;
  final Color borderColor;
  final Color buttonColor;
  final Color cardBackgroundColor;
  final String fontName;

  AppTheme({
    required this.backgroundColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.borderColor,
    required this.buttonColor,
    required this.cardBackgroundColor,
    required this.fontName,
  });

  TextStyle getTextStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? height,
  }) {
    final targetColor = color ?? textColor;

    switch (fontName) {
      case 'Roboto':
        return GoogleFonts.roboto(fontSize: fontSize, fontWeight: fontWeight, color: targetColor, height: height);
      case 'Inter':
        return GoogleFonts.inter(fontSize: fontSize, fontWeight: fontWeight, color: targetColor, height: height);
      case 'Poppins':
        return GoogleFonts.poppins(fontSize: fontSize, fontWeight: fontWeight, color: targetColor, height: height);
      case 'Lato':
        return GoogleFonts.lato(fontSize: fontSize, fontWeight: fontWeight, color: targetColor, height: height);
      default:
        return TextStyle(fontFamily: fontName, fontSize: fontSize, fontWeight: fontWeight, color: targetColor, height: height);
    }
  }

  AppTheme copyWith({
    Color? backgroundColor,
    Color? textColor,
    Color? secondaryTextColor,
    Color? borderColor,
    Color? buttonColor,
    Color? cardBackgroundColor,
    String? fontName,
  }) {
    return AppTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
      borderColor: borderColor ?? this.borderColor,
      buttonColor: buttonColor ?? this.buttonColor,
      cardBackgroundColor: cardBackgroundColor ?? this.cardBackgroundColor,
      fontName: fontName ?? this.fontName,
    );
  }

  static AppTheme dark = AppTheme(
    backgroundColor: Colors.black,
    textColor: Colors.white,
    secondaryTextColor: Colors.grey,
    borderColor: Colors.white24,
    buttonColor: Colors.white,
    cardBackgroundColor: const Color(0xFF1E1E1E),
    fontName: 'Inter',
  );

  static AppTheme light = AppTheme(
    backgroundColor: const Color(0xFFF5F5F5),
    textColor: Colors.black87,
    secondaryTextColor: Colors.black54,
    borderColor: Colors.black12,
    buttonColor: Colors.black,
    cardBackgroundColor: Colors.white,
    fontName: 'Inter',
  );
}

class ThemeController {
  static final ValueNotifier<AppTheme> currentTheme = ValueNotifier<AppTheme>(AppTheme.dark);

  // Histórico com até as duas últimas cores usadas por categoria
  static List<Color> recentBackgroundColors = [Colors.black, const Color(0xFF121212)];
  static List<Color> recentTextColors = [Colors.white, const Color(0xFFE2E8F0)];
  static List<Color> recentButtonColors = [Colors.white, const Color(0xFF38BDF8)];
  static List<Color> recentCardColors = [const Color(0xFF1E1E1E), const Color(0xFF2A2A2A)];
  static List<Color> recentBorderColors = [Colors.white24, Colors.grey];

  static void _addRecentColor(List<Color> history, Color color) {
    history.removeWhere((c) => c.toARGB32() == color.toARGB32());
    history.insert(0, color);
    if (history.length > 2) {
      history.removeLast();
    }
  }

  /// Método `updateTheme` para aplicar um tema completo diretamente
  static void updateTheme(AppTheme newTheme) {
    _addRecentColor(recentBackgroundColors, newTheme.backgroundColor);
    _addRecentColor(recentTextColors, newTheme.textColor);
    _addRecentColor(recentButtonColors, newTheme.buttonColor);
    _addRecentColor(recentCardColors, newTheme.cardBackgroundColor);
    _addRecentColor(recentBorderColors, newTheme.borderColor);
    currentTheme.value = newTheme;
  }

  static void updateBackgroundColor(Color color) {
    _addRecentColor(recentBackgroundColors, color);
    currentTheme.value = currentTheme.value.copyWith(backgroundColor: color);
  }

  static void updateTextColor(Color color) {
    _addRecentColor(recentTextColors, color);
    currentTheme.value = currentTheme.value.copyWith(textColor: color);
  }

  static void updateButtonColor(Color color) {
    _addRecentColor(recentButtonColors, color);
    currentTheme.value = currentTheme.value.copyWith(buttonColor: color);
  }

  /// Atualiza a cor das janelas (Cards e Popups)
  static void updateCardColor(Color color) {
    _addRecentColor(recentCardColors, color);
    currentTheme.value = currentTheme.value.copyWith(cardBackgroundColor: color);
  }

  /// Atualiza a cor das arestas / bordas
  static void updateBorderColor(Color color) {
    _addRecentColor(recentBorderColors, color);
    currentTheme.value = currentTheme.value.copyWith(borderColor: color);
  }

  static void updateSecondaryTextColor(Color color) {
    currentTheme.value = currentTheme.value.copyWith(secondaryTextColor: color);
  }

  static void updateFont(String fontName) {
    currentTheme.value = currentTheme.value.copyWith(fontName: fontName);
  }
}