import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/views/associar_cpf_view.dart';
import 'package:nous/src/features/auth/views/contas_usuario_view.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/perfis_pdv_view.dart';

class LoginButtonsWidget extends StatelessWidget {
  const LoginButtonsWidget({super.key});

  Future<void> _entrar(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final contaEncontrada = await authProvider.buscarConta();

    if (!context.mounted) return;

    if (contaEncontrada) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const ContasUsuarioView()),
        (route) => false,
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AssociarCpfView()),
      );
    }
  }

  void _entrarComoVisitante(BuildContext context) {
    context.read<AuthProvider>().sair();
    context.read<PdvProvider>().entrarComoVisitante();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const PerfisPdvView()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    final canSubmit = authProvider.isValid && !authProvider.carregando;

    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return Column(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.buttonColor,
                foregroundColor: theme.buttonTextColor,
                disabledBackgroundColor:
                    theme.buttonColor.withValues(alpha: 0.3),
                disabledForegroundColor:
                    theme.buttonTextColor.withValues(alpha: 0.4),
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
              onPressed: canSubmit ? () => _entrar(context) : null,
              child: authProvider.carregando
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
              onPressed: () => _entrarComoVisitante(context),
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