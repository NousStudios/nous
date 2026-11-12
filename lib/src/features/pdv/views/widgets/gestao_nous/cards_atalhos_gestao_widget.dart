import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';

/// Cards de atalho ("Status da Loja", "Gestão", "Ágora Digital", "Validação de Identidades")
/// exibidos na aba Gestão Nous.
class CardsAtalhosGestaoWidget extends StatelessWidget {
  final AppTheme theme;
  final String textoOnline;
  final VoidCallback onAbrirStatusLoja;
  final VoidCallback onAbrirGestao;
  final VoidCallback onAbrirAgoraDigital;
  final VoidCallback onAbrirFilaValidacao;

  const CardsAtalhosGestaoWidget({
    super.key,
    required this.theme,
    required this.textoOnline,
    required this.onAbrirStatusLoja,
    required this.onAbrirGestao,
    required this.onAbrirAgoraDigital,
    required this.onAbrirFilaValidacao,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Barra Usuários Nous
        _buildCardBarra(
          onTap: onAbrirStatusLoja,
          icone: Icons.wifi_tethering_rounded,
          corIcone: const Color(0xFF4CAF50),
          titulo: 'Usuários Nous',
          conteudoSubtitulo: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                textoOnline,
                style: theme.getTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 2. Barra Gestão (Custos, Fundo e Apoio Financeiro)
        _buildCardBarra(
          onTap: onAbrirGestao,
          icone: Icons.account_balance_wallet_rounded,
          corIcone: const Color(0xFFFFB300),
          titulo: 'Gestão',
          subtituloTexto: 'Custos de manutenção, fundo coletivo e apoio financeiro',
        ),

        const SizedBox(height: 12),

        // 3. Barra Ágora Digital (Tela Cheia de Debates e Mensageria Coletiva)
        _buildCardBarra(
          onTap: onAbrirAgoraDigital,
          icone: Icons.forum_rounded,
          corIcone: const Color(0xFF7C4DFF),
          titulo: 'Ágora Digital',
          subtituloTexto: 'Salas de deliberação, tópicos temáticos e mensageria comunitária',
        ),

        const SizedBox(height: 12),

        // 4. Barra Validação de Identidades
        _buildCardBarra(
          onTap: onAbrirFilaValidacao,
          icone: Icons.verified_user_rounded,
          corIcone: const Color(0xFF2196F3),
          titulo: 'Validação de Identidades',
          subtituloTexto: 'Atestar novos cidadãos e fortalecer a rede de confiança',
        ),
      ],
    );
  }

  Widget _buildCardBarra({
    required VoidCallback onTap,
    required IconData icone,
    required Color corIcone,
    required String titulo,
    String? subtituloTexto,
    Widget? conteudoSubtitulo,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardBackgroundColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: corIcone.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icone,
                size: 20,
                color: corIcone,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextoRolante(
                    texto: titulo,
                    style: theme.getTextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (conteudoSubtitulo != null)
                    conteudoSubtitulo
                  else if (subtituloTexto != null)
                    TextoRolante(
                      texto: subtituloTexto,
                      style: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: theme.secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }
}
