import 'package:flutter/material.dart';
import 'package:nous/view/login_view.dart'; // O import está certinho!

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(), // Deixa o app em modo escuro
      home: const LoginNousPage(), // Aqui ele chama a sua tela da pasta view
    );
  }
}