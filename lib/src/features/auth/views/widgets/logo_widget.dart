import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  const LogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      // Corta a imagem no formato circular do Container se necessário
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(20), // Espaçamento interno para a logo respirar
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.contain, // Garante que a imagem caiba perfeitamente
      ),
    );
  }
}