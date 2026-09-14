import 'package:flutter/material.dart';

class LoginButtonsWidget extends StatelessWidget {
  const LoginButtonsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Botão Entrar
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            minimumSize: const Size.fromHeight(55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: () {},
          child: const Text(
            'Entrar',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),

        // Botão Entrar como Visitante
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(55),
            side: const BorderSide(color: Colors.white54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: () {},
          child: const Text(
            'Entrar como visitante',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}