import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/turno_caixa.dart';
import 'package:nous/src/features/pdv/views/widgets/caixa/barra_turno_item.dart';

/// Painel que exibe a listagem dos últimos turnos de caixa fechados com suporte à re-impressão e detalhes.
class PainelHistoricoTurnos extends StatelessWidget {
  final AppTheme theme;
  final BoxDecoration decoracao;
  final List<TurnoCaixa> turnosFechados;
  final String Function(DateTime) formatarDataHora;
  final String Function(double) formatarMoeda;
  final void Function(TurnoCaixa) aoClicarDetalhes;
  final void Function(TurnoCaixa) aoReimprimir;

  const PainelHistoricoTurnos({
    super.key,
    required this.theme,
    required this.decoracao,
    required this.turnosFechados,
    required this.formatarDataHora,
    required this.formatarMoeda,
    required this.aoClicarDetalhes,
    required this.aoReimprimir,
  });

  @override
  Widget build(BuildContext context) {
    if (turnosFechados.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: decoracao,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, size: 16, color: theme.textColor),
              const SizedBox(width: 6),
              Text(
                'Últimos Turnos Fechados (${turnosFechados.length})',
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
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: turnosFechados.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final t = turnosFechados[index];
                return BarraTurnoItem(
                  theme: theme,
                  turno: t,
                  formatarDataHora: formatarDataHora,
                  formatarMoeda: formatarMoeda,
                  aoClicar: () => aoClicarDetalhes(t),
                  aoReimprimir: () => aoReimprimir(t),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
