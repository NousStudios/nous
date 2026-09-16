import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/pdv/views/perfis_pdv_view.dart';

class LoginButtonsWidget extends StatelessWidget {
  const LoginButtonsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    final canSubmit = authProvider.isValid && !authProvider.isCheckingWithServer;

    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return Column(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.buttonColor,
                foregroundColor: theme.buttonTextColor,
                disabledBackgroundColor: theme.buttonColor.withValues(alpha: 0.3),
                disabledForegroundColor: theme.buttonTextColor.withValues(alpha: 0.4),
                elevation: 0,
                minimumSize: const Size.fromHeight(55),
                side: BorderSide(
                  color: canSubmit
                      ? theme.borderColor
                      : theme.borderColor.withValues(alpha: 0.4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: canSubmit
                  ? () => context.read<AuthProvider>().submitCpf()
                  : null,
              child: authProvider.isCheckingWithServer
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.buttonTextColor,
                      ),
                    )
                  : Text(
                      'Entrar',
                      style: theme.getTextStyle(
                        fontSize: 16,
                        color: canSubmit
                            ? theme.buttonTextColor
                            : theme.buttonTextColor.withValues(alpha: 0.4),
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Botão Entrar como Visitante — agora leva até a tela de Perfis
            // (PerfisPdvView). Não depende do CPF, continua sempre habilitado.
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.buttonColor,
                foregroundColor: theme.buttonTextColor,
                elevation: 0,
                minimumSize: const Size.fromHeight(55),
                side: BorderSide(color: theme.borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PerfisPdvView(),
                  ),
                );
              },
              child: Text(
                'Entrar como visitante',
                style: theme.getTextStyle(
                  fontSize: 16,
                  color: theme.buttonTextColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}