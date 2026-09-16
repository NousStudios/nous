import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modelo de dados para armazenar tanto cores sólidas quanto gradientes nas seleções rápidas
class ColorOption {
  final Color color;
  final Gradient? gradient;

  const ColorOption({required this.color, this.gradient});
}

/// Transforma um Gradient (só tratamos LinearGradient, que é o único tipo usado no app)
/// em um Map simples, que pode ser convertido em texto (JSON) para ser salvo.
Map<String, dynamic>? _gradientToJson(Gradient? gradient) {
  if (gradient == null) return null;
  if (gradient is LinearGradient) {
    return {
      'colors': gradient.colors.map((c) => c.toARGB32()).toList(),
    };
  }
  return null;
}

/// Faz o caminho inverso: recebe o Map salvo e reconstrói o LinearGradient.
Gradient? _gradientFromJson(Map<String, dynamic>? json) {
  if (json == null) return null;
  final colorsList = (json['colors'] as List)
      .map((value) => Color(value as int))
      .toList();
  return LinearGradient(
    colors: colorsList,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
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
  final Color buttonTextColor;
  final Color borderColor;
  final String fontName;
  final double fontScale;

  const AppTheme({
    this.backgroundColor = const Color(0xFF030303),
    this.backgroundGradient,
    this.cardBackgroundColor = const Color(0xFF1E1E1E),
    this.cardGradient,
    this.textColor = Colors.white,
    this.secondaryTextColor = Colors.white70,
    this.buttonColor = Colors.blue,
    this.buttonGradient,
    this.buttonTextColor = Colors.white,
    this.borderColor = const Color(0xFF333333),
    this.fontName = 'Belleza',
    this.fontScale = 1.0,
  });

  /// Instância predefinida para Tema Escuro
  static AppTheme get dark => const AppTheme(
        backgroundColor: Color(0xFF030303),
        cardBackgroundColor: Color(0xFF1E1E1E),
        textColor: Colors.white,
        secondaryTextColor: Colors.white70,
        buttonColor: Colors.blue,
        buttonTextColor: Colors.white,
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
        buttonTextColor: Colors.white,
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
    Color? buttonTextColor,
    Color? borderColor,
    String? fontName,
    double? fontScale,
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
      buttonTextColor: buttonTextColor ?? this.buttonTextColor,
      borderColor: borderColor ?? this.borderColor,
      fontName: fontName ?? this.fontName,
      fontScale: fontScale ?? this.fontScale,
    );
  }

  TextStyle getTextStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: fontName,
      // Multiplica pelo fontScale: é isso que faz o "aumentar/diminuir fonte" valer para o app inteiro
      fontSize: fontSize * fontScale,
      fontWeight: fontWeight,
      // MUDANÇA IMPORTANTE: antes o padrão era "textColor" (cor de título).
      // Isso fazia QUALQUER texto que esquecesse de dizer sua cor virar título sem querer.
      // Agora o padrão é "secondaryTextColor" (texto normal) — o comportamento mais seguro.
      // Só os textos que passarem "color: theme.textColor" explicitamente (os títulos de
      // verdade, como cabeçalhos de tela e de popups) vão continuar usando a cor de título.
      color: color ?? secondaryTextColor,
    );
  }

  /// Transforma esse tema em um Map simples (chave-valor), que dá pra converter em texto (JSON)
  /// e guardar no armazenamento do aparelho.
  Map<String, dynamic> toJson() {
    return {
      'backgroundColor': backgroundColor.toARGB32(),
      'backgroundGradient': _gradientToJson(backgroundGradient),
      'cardBackgroundColor': cardBackgroundColor.toARGB32(),
      'cardGradient': _gradientToJson(cardGradient),
      'textColor': textColor.toARGB32(),
      'secondaryTextColor': secondaryTextColor.toARGB32(),
      'buttonColor': buttonColor.toARGB32(),
      'buttonGradient': _gradientToJson(buttonGradient),
      'buttonTextColor': buttonTextColor.toARGB32(),
      'borderColor': borderColor.toARGB32(),
      'fontName': fontName,
      'fontScale': fontScale,
    };
  }

  /// Faz o caminho inverso do toJson(): recebe o Map salvo e reconstrói um AppTheme de verdade.
  factory AppTheme.fromJson(Map<String, dynamic> json) {
    return AppTheme(
      backgroundColor: Color(json['backgroundColor'] as int),
      backgroundGradient:
          _gradientFromJson(json['backgroundGradient'] as Map<String, dynamic>?),
      cardBackgroundColor: Color(json['cardBackgroundColor'] as int),
      cardGradient: _gradientFromJson(json['cardGradient'] as Map<String, dynamic>?),
      textColor: Color(json['textColor'] as int),
      secondaryTextColor: Color(json['secondaryTextColor'] as int),
      buttonColor: Color(json['buttonColor'] as int),
      buttonGradient: _gradientFromJson(json['buttonGradient'] as Map<String, dynamic>?),
      buttonTextColor: Color(json['buttonTextColor'] as int),
      borderColor: Color(json['borderColor'] as int),
      fontName: json['fontName'] as String,
      fontScale: (json['fontScale'] as num).toDouble(),
    );
  }
}

/// Representa um tema personalizado que o usuário salvou, com um nome escolhido por ele.
class SavedTheme {
  final String name;
  final AppTheme theme;

  const SavedTheme({required this.name, required this.theme});

  Map<String, dynamic> toJson() => {
        'name': name,
        'theme': theme.toJson(),
      };

  factory SavedTheme.fromJson(Map<String, dynamic> json) {
    return SavedTheme(
      name: json['name'] as String,
      theme: AppTheme.fromJson(json['theme'] as Map<String, dynamic>),
    );
  }
}

/// Gerenciador de estado do Tema (ThemeController)
class ThemeController {
  static final ValueNotifier<AppTheme> currentTheme =
      ValueNotifier<AppTheme>(AppTheme.dark);

  // Lista reativa dos temas que o usuário salvou. Qualquer widget que "escutar"
  // esse ValueNotifier é atualizado automaticamente quando um tema é salvo ou apagado.
  static final ValueNotifier<List<SavedTheme>> savedThemes =
      ValueNotifier<List<SavedTheme>>([]);

  // Chave usada para guardar a lista de temas no armazenamento do aparelho
  static const String _savedThemesPrefsKey = 'nous_saved_themes';

  // Limites da escala de fonte, para não deixar o texto pequeno demais nem gigante demais
  static const double minFontScale = 0.8;
  static const double maxFontScale = 1.6;
  static const double fontScaleStep = 0.1;

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

  // Cores recentes para o texto de títulos (theme.textColor)
  static List<ColorOption> recentTextColors = [
    const ColorOption(color: Colors.white),
    const ColorOption(color: Colors.black),
    const ColorOption(color: Color(0xFFE2E8F0)),
    const ColorOption(color: Color(0xFF94A3B8)),
  ];

  // Cores recentes para o texto normal/secundário (theme.secondaryTextColor)
  static List<ColorOption> recentSecondaryTextColors = [
    const ColorOption(color: Colors.white70),
    const ColorOption(color: Color(0xFF6C757D)),
    const ColorOption(color: Color(0xFF94A3B8)),
    const ColorOption(color: Color(0xFFB0B0B0)),
  ];

  static List<ColorOption> recentButtonColors = [
    const ColorOption(color: Colors.blue),
    const ColorOption(color: Colors.deepPurple),
    const ColorOption(color: Colors.teal),
    const ColorOption(color: Colors.orange),
  ];

  // Lista de cores recentes específica para o texto dos botões
  static List<ColorOption> recentButtonTextColors = [
    const ColorOption(color: Colors.white),
    const ColorOption(color: Colors.black),
    const ColorOption(color: Color(0xFFE2E8F0)),
    const ColorOption(color: Color(0xFF1A1A1A)),
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

  // Atualiza a cor do texto de títulos (ex: "Nous")
  static void updateTextColor(Color color) {
    currentTheme.value = currentTheme.value.copyWith(textColor: color);
    _addRecent(recentTextColors, color, null);
  }

  // Atualiza a cor do texto normal (ex: o subtítulo "Software Universal de Autogestão...")
  static void updateSecondaryTextColor(Color color) {
    currentTheme.value = currentTheme.value.copyWith(secondaryTextColor: color);
    _addRecent(recentSecondaryTextColors, color, null);
  }

  static void updateButtonColor(Color color, {Gradient? gradient}) {
    currentTheme.value = currentTheme.value.copyWith(
      buttonColor: color,
      buttonGradient: gradient,
      clearButtonGradient: gradient == null,
    );
    _addRecent(recentButtonColors, color, gradient);
  }

  // Atualiza a cor do texto dos botões
  static void updateButtonTextColor(Color color) {
    currentTheme.value = currentTheme.value.copyWith(buttonTextColor: color);
    _addRecent(recentButtonTextColors, color, null);
  }

  static void updateBorderColor(Color color) {
    currentTheme.value = currentTheme.value.copyWith(borderColor: color);
    _addRecent(recentBorderColors, color, null);
  }

  static void updateFont(String fontName) {
    currentTheme.value = currentTheme.value.copyWith(fontName: fontName);
  }

  /// Aumenta a escala de fonte em um "degrau", respeitando o limite máximo
  static void increaseFontScale() {
    final next = currentTheme.value.fontScale + fontScaleStep;
    currentTheme.value = currentTheme.value.copyWith(
      fontScale: next > maxFontScale ? maxFontScale : next,
    );
  }

  /// Diminui a escala de fonte em um "degrau", respeitando o limite mínimo
  static void decreaseFontScale() {
    final next = currentTheme.value.fontScale - fontScaleStep;
    currentTheme.value = currentTheme.value.copyWith(
      fontScale: next < minFontScale ? minFontScale : next,
    );
  }

  /// Deve ser chamado uma única vez, antes do runApp(), para carregar do armazenamento
  /// do aparelho os temas que o usuário salvou em sessões anteriores.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_savedThemesPrefsKey);

    if (rawList == null) return; // Nenhum tema salvo ainda, mantém a lista vazia

    savedThemes.value = rawList
        .map((jsonText) => SavedTheme.fromJson(
            jsonDecode(jsonText) as Map<String, dynamic>))
        .toList();
  }

  /// Salva o tema atualmente em uso com o nome escolhido pelo usuário.
  /// Se já existir um tema salvo com o mesmo nome, ele é substituído.
  static Future<void> saveCurrentThemeAs(String name) async {
    final newSavedTheme = SavedTheme(name: name, theme: currentTheme.value);

    final updatedList =
        savedThemes.value.where((saved) => saved.name != name).toList();
    updatedList.add(newSavedTheme);

    savedThemes.value = updatedList;
    await _persistSavedThemes();
  }

  /// Remove um tema salvo pelo nome.
  static Future<void> deleteSavedTheme(String name) async {
    savedThemes.value =
        savedThemes.value.where((saved) => saved.name != name).toList();
    await _persistSavedThemes();
  }

  /// Grava a lista atual de temas salvos no armazenamento do aparelho,
  /// transformando cada tema em um texto (JSON) antes de guardar.
  static Future<void> _persistSavedThemes() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList =
        savedThemes.value.map((saved) => jsonEncode(saved.toJson())).toList();
    await prefs.setStringList(_savedThemesPrefsKey, rawList);
  }
}