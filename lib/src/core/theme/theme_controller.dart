import 'package:flutter/material.dart';

/// Modelo de dados para armazenar tanto cores sólidas quanto gradientes nas seleções rápidas
class ColorOption {
  final Color color;
  final Gradient? gradient;

  const ColorOption({required this.color, this.gradient});
}

/// Modelo de dados para o Tema do aplicativo
class AppTheme {
  final Color backgroundColor;
  final Gradient? backgroundGradient;
  final Color cardBackgroundColor;
  final Gradient? cardGradient;
  final Color textColor;
  final Color secondaryTextColor;
  final Color buttonColor;
  final Gradient? buttonGradient;
  final Color borderColor;
  final String fontName;

  const AppTheme({
    this.backgroundColor = const Color(0xFF030303),
    this.backgroundGradient,
    this.cardBackgroundColor = const Color(0xFF1E1E1E),
    this.cardGradient,
    this.textColor = Colors.white,
    this.secondaryTextColor = Colors.white70,
    this.buttonColor = Colors.blue,
    this.buttonGradient,
    this.borderColor = const Color(0xFF333333),
    this.fontName = 'Belleza',
  });

  /// Instância predefinida para Tema Escuro
  static AppTheme get dark => const AppTheme(
        backgroundColor: Color(0xFF030303),
        cardBackgroundColor: Color(0xFF1E1E1E),
        textColor: Colors.white,
        secondaryTextColor: Colors.white70,
        buttonColor: Colors.blue,
        borderColor: Color(0xFF333333),
        fontName: 'Belleza',
      );

  /// Instância predefinida para Tema Claro
  static AppTheme get light => const AppTheme(
        backgroundColor: Color(0xFFF8F9FA),
        cardBackgroundColor: Colors.white,
        textColor: Color(0xFF1A1A1A),
        secondaryTextColor: Color(0xFF6C757D),
        buttonColor: Colors.blue,
        borderColor: Color(0xFFE0E0E0),
        fontName: 'Belleza',
      );

  /// Método copyWith atualizado para permitir a substituição ou remoção dos gradientes
  AppTheme copyWith({
    Color? backgroundColor,
    Gradient? backgroundGradient,
    bool clearBackgroundGradient = false,
    Color? cardBackgroundColor,
    Gradient? cardGradient,
    bool clearCardGradient = false,
    Color? textColor,
    Color? secondaryTextColor,
    Color? buttonColor,
    Gradient? buttonGradient,
    bool clearButtonGradient = false,
    Color? borderColor,
    String? fontName,
  }) {
    return AppTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundGradient: clearBackgroundGradient
          ? null
          : (backgroundGradient ?? this.backgroundGradient),
      cardBackgroundColor: cardBackgroundColor ?? this.cardBackgroundColor,
      cardGradient:
          clearCardGradient ? null : (cardGradient ?? this.cardGradient),
      textColor: textColor ?? this.textColor,
      secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
      buttonColor: buttonColor ?? this.buttonColor,
      buttonGradient:
          clearButtonGradient ? null : (buttonGradient ?? this.buttonGradient),
      borderColor: borderColor ?? this.borderColor,
      fontName: fontName ?? this.fontName,
    );
  }

  TextStyle getTextStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: fontName,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? textColor,
    );
  }
}

/// Gerenciador de estado do Tema (ThemeController)
class ThemeController {
  static final ValueNotifier<AppTheme> currentTheme =
      ValueNotifier<AppTheme>(AppTheme.dark);

  // Listas de cores/gradientes recentes utilizando ColorOption
  static List<ColorOption> recentBackgroundColors = [
    const ColorOption(color: Color(0xFF030303)),
    const ColorOption(color: Color(0xFF1A1A2E)),
    const ColorOption(color: Color(0xFF0F172A)),
    const ColorOption(color: Colors.white),
  ];

  static List<ColorOption> recentCardColors = [
    const ColorOption(color: Color(0xFF1E1E1E)),
    const ColorOption(color: Color(0xFF16213E)),
    const ColorOption(color: Color(0xFF1E293B)),
    const ColorOption(color: Color(0xFFF1F5F9)),
  ];

  static List<ColorOption> recentTextColors = [
    const ColorOption(color: Colors.white),
    const ColorOption(color: Colors.black),
    const ColorOption(color: Color(0xFFE2E8F0)),
    const ColorOption(color: Color(0xFF94A3B8)),
  ];

  static List<ColorOption> recentButtonColors = [
    const ColorOption(color: Colors.blue),
    const ColorOption(color: Colors.deepPurple),
    const ColorOption(color: Colors.teal),
    const ColorOption(color: Colors.orange),
  ];

  static List<ColorOption> recentBorderColors = [
    const ColorOption(color: Color(0xFF333333)),
    const ColorOption(color: Color(0xFF475569)),
    const ColorOption(color: Colors.grey),
    const ColorOption(color: Colors.transparent),
  ];

  /// Método genérico updateTheme para atualizar o objeto AppTheme completo
  static void updateTheme(AppTheme newTheme) {
    currentTheme.value = newTheme;
  }

  /// Auxiliar privado para inserir a nova opção na primeira posição da lista recente
  static void _addRecent(List<ColorOption> list, Color color, Gradient? gradient) {
    // Remove duplicadas idênticas se já existirem na lista
    list.removeWhere(
        (opt) => opt.color.toARGB32() == color.toARGB32() && opt.gradient == gradient);

    // Insere no início
    list.insert(0, ColorOption(color: color, gradient: gradient));

    // Mantém no máximo 4 itens salvos na memória
    if (list.length > 4) {
      list.removeLast();
    }
  }

  /// Métodos de atualização chamados pela interface:
  static void updateBackgroundColor(Color color, {Gradient? gradient}) {
    currentTheme.value = currentTheme.value.copyWith(
      backgroundColor: color,
      backgroundGradient: gradient,
      clearBackgroundGradient: gradient == null,
    );
    _addRecent(recentBackgroundColors, color, gradient);
  }

  static void updateCardColor(Color color, {Gradient? gradient}) {
    currentTheme.value = currentTheme.value.copyWith(
      cardBackgroundColor: color,
      cardGradient: gradient,
      clearCardGradient: gradient == null,
    );
    _addRecent(recentCardColors, color, gradient);
  }

  static void updateTextColor(Color color) {
    currentTheme.value = currentTheme.value.copyWith(textColor: color);
    _addRecent(recentTextColors, color, null);
  }

  static void updateButtonColor(Color color, {Gradient? gradient}) {
    currentTheme.value = currentTheme.value.copyWith(
      buttonColor: color,
      buttonGradient: gradient,
      clearButtonGradient: gradient == null,
    );
    _addRecent(recentButtonColors, color, gradient);
  }

  static void updateBorderColor(Color color) {
    currentTheme.value = currentTheme.value.copyWith(borderColor: color);
    _addRecent(recentBorderColors, color, null);
  }

  static void updateFont(String fontName) {
    currentTheme.value = currentTheme.value.copyWith(fontName: fontName);
  }
}