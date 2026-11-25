import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Card com o resumo de alcance e interações da publicação nos insights.
class InsightsResumoAlcanceCard extends StatelessWidget {
  final AppTheme theme;
  final int totalVisualizacoes;
  final String tempoMedioFormatado;
  final int totalLikes;
  final int totalComentarios;
  final int totalDeslikes;
  final VoidCallback onTapVisualizacoes;
  final VoidCallback onTapTempoMedio;
  final VoidCallback onTapLikes;
  final VoidCallback onTapComentarios;
  final VoidCallback onTapDeslikes;

  const InsightsResumoAlcanceCard({
    super.key,
    required this.theme,
    required this.totalVisualizacoes,
    required this.tempoMedioFormatado,
    required this.totalLikes,
    required this.totalComentarios,
    required this.totalDeslikes,
    required this.onTapVisualizacoes,
    required this.onTapTempoMedio,
    required this.onTapLikes,
    required this.onTapComentarios,
    required this.onTapDeslikes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo de Alcance (toque para ver detalhes)',
            style: theme.getTextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricaInsightTile(
                  theme: theme,
                  icone: Icons.visibility_outlined,
                  rotulo: 'Visualizações',
                  valor: '$totalVisualizacoes',
                  onTap: onTapVisualizacoes,
                ),
              ),
              Expanded(
                child: _MetricaInsightTile(
                  theme: theme,
                  icone: Icons.timer_outlined,
                  rotulo: 'Tempo médio',
                  valor: tempoMedioFormatado,
                  onTap: onTapTempoMedio,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricaInsightTile(
                  theme: theme,
                  icone: Icons.thumb_up_off_alt_rounded,
                  rotulo: 'Likes',
                  valor: '$totalLikes',
                  onTap: onTapLikes,
                ),
              ),
              Expanded(
                child: _MetricaInsightTile(
                  theme: theme,
                  icone: Icons.mode_comment_outlined,
                  rotulo: 'Comentários',
                  valor: '$totalComentarios',
                  onTap: onTapComentarios,
                ),
              ),
              Expanded(
                child: _MetricaInsightTile(
                  theme: theme,
                  icone: Icons.thumb_down_off_alt_rounded,
                  rotulo: 'Deslikes',
                  valor: '$totalDeslikes',
                  onTap: onTapDeslikes,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricaInsightTile extends StatelessWidget {
  final AppTheme theme;
  final IconData icone;
  final String rotulo;
  final String valor;
  final VoidCallback onTap;

  const _MetricaInsightTile({
    required this.theme,
    required this.icone,
    required this.rotulo,
    required this.valor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: theme.backgroundColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.borderColor.withValues(alpha: 0.45)),
        ),
        child: Column(
          children: [
            Icon(icone, size: 18, color: theme.textColor),
            const SizedBox(height: 6),
            Text(
              valor,
              style: theme.getTextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              rotulo,
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 11,
                color: theme.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
