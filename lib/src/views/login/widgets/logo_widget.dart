import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  const LogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
       
      ),
      // Corta a imagem no formato circular do Container se necessário
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(12), // Espaçamento interno para a logo respirar
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.contain, // Garante que a imagem caiba perfeitamente
      ),
    );
  }
}