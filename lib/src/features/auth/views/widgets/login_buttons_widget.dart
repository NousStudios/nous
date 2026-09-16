import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';

class LoginButtonsWidget extends StatelessWidget {
  const LoginButtonsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // context.watch aqui dentro do build() para que o botão seja
    // redesenhado (habilitado/desabilitado) automaticamente sempre que o
    // CPF digitado mudar de "inválido" para "válido" ou vice-versa.
    final authProvider = context.watch<AuthProvider>();

    // Botão fica habilitado só quando o CPF é válido E não estamos no meio
    // de uma checagem com o servidor (etapa 2, futura).
    final canSubmit = authProvider.isValid && !authProvider.isCheckingWithServer;

    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return Column(
          children: [
            // Botão Entrar — fundo com Cor dos Botões, texto com Cor do Texto dos Botões,
            // e agora também com borda (Cor das Arestas). Quando Cor dos Botões é
            // transparente (padrão do tema escuro), o resultado visual é um botão "vazado".
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.buttonColor,
                foregroundColor: theme.buttonTextColor,
                // Cores usadas SÓ quando o botão está desabilitado (onPressed: null).
                // Sem isso, o Flutter usaria um cinza padrão que ignoraria o tema
                // do app inteiro.
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
              // onPressed: null é a forma que o Flutter usa para "desabilitar"
              // um botão de verdade (ele para de responder a toque). Por isso
              // usamos um operador ternário: se pode enviar, chama
              // submitCpf(); se não pode, o valor é null.
              onPressed: canSubmit
                  ? () => context.read<AuthProvider>().submitCpf()
                  : null,
              child: authProvider.isCheckingWithServer
                  // Enquanto "checando", mostra uma bolinha de carregamento
                  // no lugar do texto.
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

            // Botão Entrar como Visitante — mesma aparência do botão "Entrar" acima.
            // Não depende do CPF, então continua sempre habilitado.
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
              onPressed: () {},
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