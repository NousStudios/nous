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
    // ValueListenableBuilder reconstrói a árvore de widgets quando o tema muda
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Nous',
          theme: ThemeData(
            scaffoldBackgroundColor: theme.backgroundColor,
            brightness: theme == AppTheme.dark ? Brightness.dark : Brightness.light,
          ),
          home: const LoginView(),
        );
      },
    );
  }
}