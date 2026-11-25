import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';

/// Barra superior flutuante do visualizador Reels compacto, com botão de voltar,
/// título do tipo de mídia, contador de sequência e menu de opções.
class ReelsBarraSuperiorWidget extends StatelessWidget {
  final AppTheme theme;
  final TipoFeedSocial tipo;
  final int indiceAtivo;
  final int totalPublicacoes;
  final VoidCallback onVoltar;
  final VoidCallback onMaisOpcoes;

  const ReelsBarraSuperiorWidget({
    super.key,
    required this.theme,
    required this.tipo,
    required this.indiceAtivo,
    required this.totalPublicacoes,
    required this.onVoltar,
    required this.onMaisOpcoes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.backgroundColor.withValues(alpha: 0.80),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: theme.textColor),
            onPressed: onVoltar,
          ),
          const SizedBox(width: 4),
          Text(
            tipo == TipoFeedSocial.videos ? 'Vídeos' : 'Fotos',
            style: theme.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          if (totalPublicacoes > 1) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: theme.cardBackgroundColor.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.borderColor.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                '${indiceAtivo + 1}/$totalPublicacoes',
                style: theme.getTextStyle(
                  fontSize: 11,
                  color: theme.secondaryTextColor,
                ),
              ),
            ),
          ],
          const Spacer(),
          IconButton(
            tooltip: 'Mais opções da publicação',
            icon: Icon(Icons.more_horiz_rounded, color: theme.textColor),
            onPressed: onMaisOpcoes,
          ),
        ],
      ),
    );
  }
}
