import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/features/auth/views/login_view.dart';

class PerfisPdvView extends StatelessWidget {
  const PerfisPdvView({super.key});

  // Função chamada quando o usuário clica em "Sair" dentro do popup de
  // Configurações. pushAndRemoveUntil troca de tela E apaga toda a pilha de
  // navegação anterior — ou seja, depois disso não existe mais "voltar" para
  // a tela de Perfis por engano; a única forma de chegar aqui de novo é
  // fazendo login/entrando como visitante outra vez.
  void _handleLogout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginView()),
      (route) => false, // false para TODAS as rotas = apaga tudo
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: CustomAppBar(
            title: 'Meus Perfis',
            // false: esta é a "tela raiz" pós-login/visitante. Não existe
            // "voltar" para o login a partir daqui — só existe ir PRA
            // FRENTE, para outras telas do app.
            showBackButton: false,
            onLogout: () => _handleLogout(context),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.backgroundColor.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meus Perfis Profissionais',
                          style: theme.getTextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _PerfilCard(
                          theme: theme,
                          icon: Icons.storefront,
                          label: 'Loja Padrão',
                          onTap: () {},
                        ),

                        const SizedBox(height: 20),

                        Center(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.textColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              side: BorderSide(color: theme.borderColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {},
                            icon: Icon(
                              Icons.add,
                              color: theme.textColor,
                              size: 18,
                            ),
                            label: Text(
                              'Criar Perfil',
                              style: theme.getTextStyle(
                                fontSize: 14,
                                color: theme.textColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PerfilCard extends StatelessWidget {
  final AppTheme theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PerfilCard({
    required this.theme,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        height: 100,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.cardBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: theme.secondaryTextColor),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.getTextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}