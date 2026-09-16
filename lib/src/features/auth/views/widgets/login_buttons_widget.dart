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
                // Antes usava theme.textColor (cor de título); agora usa
                // theme.secondaryTextColor (cor de texto normal), pra ficar
                // igual ao botão "Entrar como visitante" logo abaixo.
                foregroundColor: theme.secondaryTextColor,
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
                  color: theme.secondaryTextColor,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Botão Entrar como Visitante
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                // Também trocado para texto normal, mantendo os dois botões idênticos.
                foregroundColor: theme.secondaryTextColor,
                minimumSize: const Size.fromHeight(55),
                side: BorderSide(color: theme.borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {},
              child: Text(
                'Entrar como visitante',
                // Antes esse texto já caía em "texto normal" por acidente (dependia
                // do padrão do getTextStyle). Agora deixei explícito, pra não
                // depender de padrão nenhum e não quebrar de novo no futuro.
                style: theme.getTextStyle(
                  fontSize: 16,
                  color: theme.secondaryTextColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}