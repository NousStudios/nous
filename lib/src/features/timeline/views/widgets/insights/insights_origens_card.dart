import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Card que exibe a distribuição de visualizações por origem.
class InsightsOrigensCard extends StatelessWidget {
  final AppTheme theme;
  final Map<String, int> origens;

  const InsightsOrigensCard({
    super.key,
    required this.theme,
    required this.origens,
  });

  @override
  Widget build(BuildContext context) {
    final somaOrigens = origens.values.fold<int>(0, (a, b) => a + b);
    final total = somaOrigens > 0 ? somaOrigens : 1;

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
            'Por onde a publicação foi vista',
            style: theme.getTextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 12),
          for (final entry in origens.entries) ...[
            _BarraOrigemInsight(
              theme: theme,
              rotulo: entry.key,
              valor: entry.value,
              total: total,
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _BarraOrigemInsight extends StatelessWidget {
  final AppTheme theme;
  final String rotulo;
  final int valor;
  final int total;

  const _BarraOrigemInsight({
    required this.theme,
    required this.rotulo,
    required this.valor,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final fracao = (valor / total).clamp(0.0, 1.0);
    final pct = (fracao * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              rotulo,
              style: theme.getTextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.textColor,
              ),
            ),
            Text(
              '$valor ($pct%)',
              style: theme.getTextStyle(
                fontSize: 12,
                color: theme.secondaryTextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fracao,
            minHeight: 7,
            backgroundColor: theme.borderColor.withValues(alpha: 0.25),
            valueColor: AlwaysStoppedAnimation<Color>(theme.buttonColor),
          ),
        ),
      ],
    );
  }
}
