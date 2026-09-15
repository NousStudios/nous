import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  final Color backgroundColor;
  final Color textColor;
  final Color secondaryTextColor;
  final Color borderColor;
  final Color cardBackgroundColor;
  final String fontName;

  AppTheme({
    required this.backgroundColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.borderColor,
    required this.cardBackgroundColor,
    required this.fontName,
  });

  // Retorna o TextStyle correto baseado na fonte escolhida
  TextStyle getTextStyle({double fontSize = 14, FontWeight fontWeight = FontWeight.normal, Color? color}) {
    final targetColor = color ?? textColor;
    switch (fontName) {
      case 'Roboto':
        return GoogleFonts.roboto(fontSize: fontSize, fontWeight: fontWeight, color: targetColor);
      case 'Inter':
        return GoogleFonts.inter(fontSize: fontSize, fontWeight: fontWeight, color: targetColor);
      case 'Poppins':
        return GoogleFonts.poppins(fontSize: fontSize, fontWeight: fontWeight, color: targetColor);
      case 'Lato':
        return GoogleFonts.lato(fontSize: fontSize, fontWeight: fontWeight, color: targetColor);
      default:
        return TextStyle(fontFamily: fontName, fontSize: fontSize, fontWeight: fontWeight, color: targetColor);
    }
  }

  // Permite copiar o tema alterando apenas propriedades específicas
  AppTheme copyWith({
    Color? backgroundColor,
    Color? textColor,
    Color? secondaryTextColor,
    Color? borderColor,
    Color? cardBackgroundColor,
    String? fontName,
  }) {
    return AppTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
      borderColor: borderColor ?? this.borderColor,
      cardBackgroundColor: cardBackgroundColor ?? this.cardBackgroundColor,
      fontName: fontName ?? this.fontName,
    );
  }

  static AppTheme dark = AppTheme(
    backgroundColor: Colors.black,
    textColor: Colors.white,
    secondaryTextColor: Colors.grey,
    borderColor: Colors.white24,
    cardBackgroundColor: const Color(0xFF1E1E1E),
    fontName: 'Inter',
  );

  static AppTheme light = AppTheme(
    backgroundColor: const Color(0xFFF5F5F5),
    textColor: Colors.black87,
    secondaryTextColor: Colors.black54,
    borderColor: Colors.black12,
    cardBackgroundColor: Colors.white,
    fontName: 'Inter',
  );
}

class ThemeController {
  static final ValueNotifier<AppTheme> currentTheme = ValueNotifier<AppTheme>(AppTheme.dark);

  static void updateTheme(AppTheme newTheme) {
    currentTheme.value = newTheme;
  }

  static void updateBackgroundColor(Color color) {
    currentTheme.value = currentTheme.value.copyWith(backgroundColor: color);
  }

  static void updateTextColor(Color color) {
    currentTheme.value = currentTheme.value.copyWith(textColor: color);
  }

  static void updateFont(String fontName) {
    currentTheme.value = currentTheme.value.copyWith(fontName: fontName);
  }
}