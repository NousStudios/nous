// IMPORTS: Trazem os pacotes e componentes necessários para construir a tela
import 'package:flutter/material.dart';

// IMPORT DO CONTROLLER DE TEMA: Para redefinir dinamicamente cores e fontes
import 'package:nous/src/core/theme/theme_controller.dart';

// IMPORT DO NOSSO COMPONENTE: Traz a barra superior customizada com o botão de configurações
import 'package:nous/src/core/widgets/custom_app_bar.dart';

// Widget principal da tela de Termos de Uso (Stateless pois não altera estado internamente)
class TermsView extends StatelessWidget {
  const TermsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: const CustomAppBar(
            title: 'Termos de Uso',
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Termos e Condições de Uso - Nous',
                              style: theme.getTextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                            const SizedBox(height: 16),

                            Text(
                              'Última atualização: Setembro de 2026',
                              style: theme.getTextStyle(
                                fontSize: 12,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 24),

                            _SectionTitle(title: '1. Aceitação dos Termos', theme: theme),
                            _SectionBody(
                              text: 'Ao acessar e utilizar a plataforma Nous, você concorda em cumprir e respeitar os presentes Termos de Uso. Caso não concorde com qualquer disposição, você não deve utilizar a aplicação.',
                              theme: theme,
                            ),

                            _SectionTitle(title: '2. Sobre o Serviço', theme: theme),
                            _SectionBody(
                              text: 'O Nous é uma plataforma de autogestão comercial e social focada em autonomia local, descentralização de serviços e privacidade dos dados do usuário.',
                              theme: theme,
                            ),

                            _SectionTitle(title: '3. Privacidade e Proteção de Dados', theme: theme),
                            _SectionBody(
                              text: 'Seus dados e informações de identificação (como CPF) são tratados com foco em segurança e confidencialidade, sendo utilizados estritamente para o funcionamento das ferramentas da plataforma.',
                              theme: theme,
                            ),

                            _SectionTitle(title: '4. Modificações dos Termos', theme: theme),
                            _SectionBody(
                              text: 'Reservamo-nos o direito de alterar estes termos a qualquer momento. Alterações significativas serão notificadas na própria aplicação.',
                              theme: theme,
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    ElevatedButton(
                      // Botão "Entendi e Concordo" — agora com borda (Cor das Arestas) também,
                      // além do fundo (Cor dos Botões) e do texto (Cor do Texto dos Botões).
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.buttonColor,
                        foregroundColor: theme.buttonTextColor,
                        minimumSize: const Size.fromHeight(50),
                        side: BorderSide(color: theme.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Entendi e Concordo',
                        style: theme.getTextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.buttonTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ==============================================================================
// WIDGETS AUXILIARES
// ==============================================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  final AppTheme theme;

  const _SectionTitle({
    required this.title,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: theme.getTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: theme.secondaryTextColor,
        ),
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  final String text;
  final AppTheme theme;

  const _SectionBody({
    required this.text,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: theme.getTextStyle(
        fontSize: 14,
        color: theme.secondaryTextColor,
      ),
    );
  }
}