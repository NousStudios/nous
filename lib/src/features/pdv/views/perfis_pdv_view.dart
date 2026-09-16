import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';

// Essa é a tela que aparece depois de "Entrar como visitante" (e, no futuro,
// depois de um login normal também). Por enquanto ela só mostra o primeiro
// bloco da tela de "Lojas": os perfis profissionais do usuário — hoje, só
// "Loja Padrão", como você pediu.
class PerfisPdvView extends StatelessWidget {
  const PerfisPdvView({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.backgroundColor,
          // Reaproveitando o CustomAppBar que você já tem: o botão de
          // configurações (⚙) aparece aqui automaticamente, sem precisar
          // reescrever nada. showBackButton fica true por enquanto, porque
          // ainda estamos testando o fluxo — mais pra frente, quando essa
          // virar de fato a "tela inicial" do app, provavelmente vamos
          // querer tirar essa seta de voltar.
          appBar: const CustomAppBar(
            title: 'Meus Perfis',
            showBackButton: true,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===================================================
                  // CONTAINER "Meus Perfis Profissionais"
                  // Reaproveitei o mesmo estilo visual de "cartão" que já
                  // existe no popup de Personalizar Aparência (fundo com
                  // transparência + borda arredondada), pra manter a
                  // aparência consistente em todo o app.
                  // ===================================================
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
                        // Título de SEÇÃO dentro da página → cor de texto
                        // normal (secondaryTextColor), como definimos lá no
                        // começo ("1. Aceitação dos Termos" segue essa
                        // mesma regra).
                        Text(
                          'Meus Perfis Profissionais',
                          style: theme.getTextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // O card "Loja Padrão". Por enquanto só existe este;
                        // não criei Motoboy nem Professor, como você pediu.
                        _PerfilCard(
                          theme: theme,
                          icon: Icons.storefront,
                          label: 'Loja Padrão',
                          // Ainda não faz nada ao clicar — não existe
                          // nenhuma loja criada pra abrir ainda.
                          onTap: () {},
                        ),

                        const SizedBox(height: 20),

                        // Botão "Criar Perfil". Segue o mesmo estilo
                        // "vazado" (outline) que o botão "Salvar Tema
                        // Atual..." já usa no popup de personalização —
                        // reaproveitando um padrão que já existe no app.
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
                            // Igual ao card acima: ainda não faz nada.
                            // Criar um perfil de verdade é uma lógica à
                            // parte, que vamos construir com calma depois.
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

// Widget pequeno e reutilizável para cada "card" de perfil profissional.
// Extraí ele em uma classe separada porque, quando você quiser adicionar
// Motoboy e Professor no futuro, vai bastar chamar _PerfilCard de novo —
// sem copiar e colar o mesmo bloco de código várias vezes.
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
    // InkWell dá aquele efeito de "onda" ao tocar, como o resto do app.
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
              // Rótulo do card → texto normal (secondaryTextColor).
              style: theme.getTextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}