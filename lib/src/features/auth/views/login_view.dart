// IMPORTS: Trazem os arquivos que esse widget precisa para funcionar
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/views/widgets/cpf_input_widget.dart';
import 'package:nous/src/features/auth/views/widgets/login_buttons_widget.dart';
import 'package:nous/src/features/auth/views/widgets/logo_widget.dart';

// IMPORT NOVO: Importamos a tela dos Termos de Uso criada para podermos navegar até ela
import 'package:nous/src/features/auth/views/terms_view.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return Scaffold(
          // Define a cor de fundo com base no tema dinâmico
          backgroundColor: theme.backgroundColor,

          // SafeArea garante que o conteúdo não fique sob barras do sistema (notificações, entalhes)
          body: SafeArea(
            child: Center(
              // Permite rolar a tela se o teclado subir ou em telas menores
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),

                // ConstrainedBox limita a largura máxima em 420px (para ficar bonito em desktop/tablet)
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),

                  // Column organiza os elementos um embaixo do outro
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20), // Espaçamento topo

                      // 1. COMPONENTE DA LOGO
                      const LogoWidget(),
                      const SizedBox(height: 16), // Espaço abaixo da logo

                      // 2. TÍTULO 'Nous' (letterSpacing padrão da fonte, tamanho aumentado)
                      // É um título de verdade, então precisa dizer isso explicitamente.
                      Text(
                        'Nous',
                        style: theme.getTextStyle(fontSize: 36, color: theme.textColor),
                      ),
                      const SizedBox(height: 8),

                      // 3. SUBTÍTULO
                      Text(
                        'Software Universal de Autogestão\nComercial e Social',
                        textAlign: TextAlign.center,
                        style: theme.getTextStyle(
                          fontSize: 16,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 40), // Espaçamento grande antes do formulário

                      // 4. CAMPO DE ENTRADA DO CPF
                      const CpfInputWidget(),
                      const SizedBox(height: 12), // Espaço pequeno entre o CPF e o botão dos termos

                      // ====================================================================
                      // 5. BOTÃO DOS TERMOS DE USO
                      // ====================================================================
                      TextButton(
                        // onPressed é a função executada ao clicar no botão
                        onPressed: () {
                          // Com o Navigator.push, ao clicar no texto ele abre a tela dos Termos
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TermsView(),
                            ),
                          );
                        },
                        // Visual do texto do botão reativo ao tema
                        child: Text(
                          'Leia os Termos de Uso',
                          style: theme.getTextStyle(
                            fontSize: 14,
                            color: theme.secondaryTextColor,
                          ).copyWith(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      // ====================================================================

                      const SizedBox(height: 24), // Espaço entre os termos e os botões de ação

                      // 6. BOTÕES DE ENTRAR E ENTRAR COMO VISITANTE
                      const LoginButtonsWidget(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}