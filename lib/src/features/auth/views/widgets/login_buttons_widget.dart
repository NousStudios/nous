import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

class LoginButtonsWidget extends StatelessWidget {
  const LoginButtonsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuta o tema global, igual ao padrão usado nos outros widgets da tela de login
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return Column(
          children: [
            // Botão Entrar
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                // Fundo transparente, igual ao botão "Entrar como visitante"
                backgroundColor: Colors.transparent,
                foregroundColor: theme.textColor,
                elevation: 0, // Remove a sombra, já que não faz sentido num botão transparente
                minimumSize: const Size.fromHeight(55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide(color: theme.borderColor),
                ),
              ),
              onPressed: () {},
              child: Text(
                'Entrar',
                style: theme.getTextStyle(
                  fontSize: 16,
                  color: theme.textColor,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Botão Entrar como Visitante
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.textColor,
                minimumSize: const Size.fromHeight(55),
                side: BorderSide(color: theme.borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {},
              child: Text(
                'Entrar como visitante',
                style: theme.getTextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }
}