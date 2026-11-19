import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';

/// Página de Insights da Publicação (visualizações, tempo médio e origens).
/// Visível para qualquer cidadão Nous, conforme princípio de transparência.
class InsightsPublicacaoView extends StatelessWidget {
  final AppTheme theme;
  final PublicacaoSocial publicacao;
  final int totalCurtidas;
  final int totalDeslikes;
  final int totalComentarios;

  const InsightsPublicacaoView({
    super.key,
    required this.theme,
    required this.publicacao,
    required this.totalCurtidas,
    required this.totalDeslikes,
    required this.totalComentarios,
  });

  static Future<void> abrir(
    BuildContext context, {
    required AppTheme theme,
    required PublicacaoSocial publicacao,
    int totalCurtidas = 0,
    int totalDeslikes = 0,
    int totalComentarios = 0,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InsightsPublicacaoView(
          theme: theme,
          publicacao: publicacao,
          totalCurtidas: totalCurtidas,
          totalDeslikes: totalDeslikes,
          totalComentarios: totalComentarios,
        ),
      ),
    );
  }

  String _formatarTempo(int segundos) {
    if (segundos <= 0) return '0s';
    if (segundos < 60) return '${segundos}s';
    final min = segundos ~/ 60;
    final seg = segundos % 60;
    return '${min}m ${seg}s';
  }

  @override
  Widget build(BuildContext context) {
    final totalVis = publicacao.visualizacoes;
    final origens = publicacao.visualizacoesPorOrigem.isEmpty
        ? <String, int>{
            'Feed Principal': totalVis,
            'Perfil Público': 0,
            'Descoberta / Busca': 0,
          }
        : publicacao.visualizacoesPorOrigem;
    final somaOrigens = origens.values.fold<int>(0, (a, b) => a + b);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardBackgroundColor,
        foregroundColor: theme.textColor,
        elevation: 0,
        title: Text(
          'Insights da Publicação',
          style: theme.getTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
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
                      'Resumo de Alcance',
                      style: theme.getTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetrica(
                            icone: Icons.visibility_outlined,
                            rotulo: 'Visualizações',
                            valor: '$totalVis',
                          ),
                        ),
                        Expanded(
                          child: _buildMetrica(
                            icone: Icons.timer_outlined,
                            rotulo: 'Tempo médio',
                            valor: _formatarTempo(
                              publicacao.tempoMedioVisualizacaoSegundos,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetrica(
                            icone: Icons.thumb_up_off_alt_rounded,
                            rotulo: 'Likes',
                            valor: '$totalCurtidas',
                          ),
                        ),
                        Expanded(
                          child: _buildMetrica(
                            icone: Icons.mode_comment_outlined,
                            rotulo: 'Comentários',
                            valor: '$totalComentarios',
                          ),
                        ),
                        Expanded(
                          child: _buildMetrica(
                            icone: Icons.thumb_down_off_alt_rounded,
                            rotulo: 'Deslikes',
                            valor: '$totalDeslikes',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
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
                      _buildBarraOrigem(
                        rotulo: entry.key,
                        valor: entry.value,
                        total: somaOrigens > 0 ? somaOrigens : 1,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetrica({
    required IconData icone,
    required String rotulo,
    required String valor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.35)),
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
    );
  }

  Widget _buildBarraOrigem({
    required String rotulo,
    required int valor,
    required int total,
  }) {
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
