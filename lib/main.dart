import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/views/login/login_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder escuta as alterações do ThemeController em tempo real
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Nous',
          theme: ThemeData(
            // Define a cor de fundo padrão de todos os Scaffolds do app
            scaffoldBackgroundColor: theme.backgroundColor,
            
            // Define a cor da AppBar globalmente
            appBarTheme: AppBarTheme(
              backgroundColor: theme.backgroundColor,
              foregroundColor: theme.textColor,
              elevation: 0,
            ),

            // Define a cor de diálogos/modais
            dialogTheme: DialogThemeData(
              backgroundColor: theme.cardBackgroundColor,
            ),

            // Define o tema de cores base do Material
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: theme.backgroundColor.toARGB32() == Colors.black.toARGB32()
                  ? Brightness.dark
                  : Brightness.light,
            ),
          ),
          home: const LoginView(),
        );
      },
    );
  }
}