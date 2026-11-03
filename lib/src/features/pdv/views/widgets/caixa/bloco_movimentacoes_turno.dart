import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/turno_caixa.dart';

/// Painel que lista sangrias e suprimentos do turno de caixa em andamento.
class BlocoMovimentacoesTurno extends StatelessWidget {
  final AppTheme theme;
  final BoxDecoration decoracao;
  final TurnoCaixa turno;
  final String Function(double) formatarMoeda;
  final void Function(MovimentoCaixa) aoImprimirMovimento;

  const BlocoMovimentacoesTurno({
    super.key,
    required this.theme,
    required this.decoracao,
    required this.turno,
    required this.formatarMoeda,
    required this.aoImprimirMovimento,
  });

  @override
  Widget build(BuildContext context) {
    if (turno.movimentacoes.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: decoracao,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 16,
                color: theme.textColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Lançamentos do Turno (${turno.movimentacoes.length})',
                style: theme.getTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: turno.movimentacoes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final m = turno.movimentacoes.reversed.toList()[index];
                final ehSangria = m.tipo == TipoMovimentoCaixa.sangria;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.borderColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ehSangria
                          ? Colors.redAccent.withValues(alpha: 0.4)
                          : theme.borderColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        ehSangria
                            ? Icons.remove_circle_outline
                            : Icons.add_circle_outline,
                        size: 16,
                        color: ehSangria ? Colors.redAccent : theme.buttonColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${ehSangria ? "Sangria" : "Suprimento"}: ${formatarMoeda(m.valor)}',
                              style: theme.getTextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: ehSangria
                                    ? Colors.redAccent
                                    : theme.textColor,
                              ),
                            ),
                            if (m.motivo.isNotEmpty)
                              Text(
                                m.motivo,
                                style: theme.getTextStyle(
                                  fontSize: 11,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Imprimir comprovante',
                        icon: Icon(Icons.print_outlined,
                            size: 16, color: theme.textColor),
                        onPressed: () => aoImprimirMovimento(m),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
