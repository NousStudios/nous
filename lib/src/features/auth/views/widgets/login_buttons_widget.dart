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
                // Mesma combinação usada no botão "Entendi e Concordo" do TermsView
                backgroundColor: theme.textColor,
                foregroundColor: theme.backgroundColor,
                minimumSize: const Size.fromHeight(55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {},
              child: Text(
                'Entrar',
                style: theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.backgroundColor,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Botão Entrar como Visitante
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.textColor,
                minimumSize: const Size.fromHeight(55),
                // Agora usa a cor de aresta real do tema, personalizável pelo usuário
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