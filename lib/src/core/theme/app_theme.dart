import 'package:flutter/material.dart';

class AppTheme {
  // Construtor privado para evitar que a classe seja instanciada
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF121212), // Fundo escuro principal
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        surface: Color(0xFF1E1E1E),
        secondary: Color(0xFF8E8E8E),
      ),
      // Estilo padrão dos campos de texto (TextFormField)
      inputDecorationTheme: OutlineInputBorderTheme.theme,
      // Estilo padrão dos botões principais
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

// Auxiliar para bordas dos inputs
class OutlineInputBorderTheme {
  static InputDecorationTheme get theme {
    return InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      labelStyle: const TextStyle(color: Color(0xFFA0A0A0)),
      prefixIconColor: const Color(0xFFA0A0A0),
      suffixIconColor: const Color(0xFFA0A0A0),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Color(0xFF333333)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.white, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}