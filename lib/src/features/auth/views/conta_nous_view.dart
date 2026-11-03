import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/views/widgets/conta_nous/bloco_emails_conta_widget.dart';
import 'package:nous/src/features/auth/views/widgets/conta_nous/bloco_identidade_conta_widget.dart';
import 'package:nous/src/features/auth/views/widgets/conta_nous/bloco_privacidade_conta_widget.dart';
import 'package:nous/src/features/auth/views/widgets/conta_nous/bloco_seguranca_conta_widget.dart';

/// Tela dedicada para gerenciamento da Conta Nous Soberana do Cidadão.
/// Reúne Identidade, Privacidade dos dados, E-mails associados, Backup e Exclusão.
class ContaNousView extends StatelessWidget {
  const ContaNousView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final conta = auth.contaAtual;

    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: CustomAppBar(
            title: 'Conta Nous',
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Bloco 1: Identidade do Usuário
                      BlocoIdentidadeContaWidget(
                        conta: conta,
                        theme: theme,
                      ),
                      const SizedBox(height: 16),

                      // Bloco 2: Privacidade e Transparência dos Dados
                      BlocoPrivacidadeContaWidget(
                        conta: conta,
                        theme: theme,
                      ),
                      const SizedBox(height: 16),

                      // Bloco 3: E-mails Associados
                      BlocoEmailsContaWidget(
                        conta: conta,
                        theme: theme,
                      ),
                      const SizedBox(height: 16),

                      // Bloco 4 & 5: Backup Soberano e Zona de Perigo
                      BlocoSegurancaContaWidget(
                        theme: theme,
                      ),
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
