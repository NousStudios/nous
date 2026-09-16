import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/theme/contrast_helper.dart';
import 'package:nous/src/features/auth/views/login_view.dart';

Future<void> main() async {
  // Garante que o Flutter está pronto para operações assíncronas antes do runApp,
  // necessário porque vamos carregar os temas salvos do armazenamento do aparelho.
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega os temas que o usuário salvou em sessões anteriores, antes de exibir qualquer tela.
  await ThemeController.init();

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
              // Calcula o brilho de verdade, com base na luminância da cor de fundo
              brightness: getBrightnessFor(theme.backgroundColor),
            ),
          ),
          home: const LoginView(),
        );
      },
    );
  }
}