import 'package:flutter/material.dart';
import 'src/core/theme/app_theme.dart';
import 'src/views/login/login_view.dart'; // Ou o caminho da sua view atual

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nous',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // <-- Conecta o tema centralizado aqui
      home: const LoginView(),
    );
  }
}