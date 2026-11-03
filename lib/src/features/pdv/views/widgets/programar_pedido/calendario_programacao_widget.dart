import 'package:flutter/material.dart';
import '../../../../../core/theme/theme_controller.dart';

/// Componente visual de calendário mensal interativo para seleção de datas específicas de pedidos programados.
class CalendarioProgramacaoWidget extends StatelessWidget {
  final AppTheme theme;
  final DateTime mesCalendario;
  final Iterable<DateTime> datasSelecionadas;
  final ValueChanged<DateTime> onMesAlterado;
  final ValueChanged<DateTime> onDataAlternada;

  const CalendarioProgramacaoWidget({
    super.key,
    required this.theme,
    required this.mesCalendario,
    required this.datasSelecionadas,
    required this.onMesAlterado,
    required this.onDataAlternada,
  });

  static const List<String> _nomesMeses = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ];

  @override
  Widget build(BuildContext context) {
    final primeiroDiaMes = DateTime(mesCalendario.year, mesCalendario.month, 1);
    final ultimoDiaMes = DateTime(mesCalendario.year, mesCalendario.month + 1, 0);

    // weekday: 1 (segunda) ... 7 (domingo). No Brasil normalmente a coluna 0 é Domingo.
    final offsetDomingo = primeiroDiaMes.weekday % 7;
    final totalDias = ultimoDiaMes.day;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          // Barra de Navegação do Mês
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: theme.textColor,
                onPressed: () {
                  onMesAlterado(DateTime(mesCalendario.year, mesCalendario.month - 1, 1));
                },
              ),
              Text(
                '${_nomesMeses[mesCalendario.month - 1]} ${mesCalendario.year}',
                style: theme.getTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: theme.textColor,
                onPressed: () {
                  onMesAlterado(DateTime(mesCalendario.year, mesCalendario.month + 1, 1));
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Cabeçalho dos dias da semana (Dom, Seg, Ter, Qua, Qui, Sex, Sáb)
          Row(
            children: ['D', 'S', 'T', 'Q', 'Q', 'S', 'S']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: theme.getTextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
          // Grade dos Dias
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: offsetDomingo + totalDias,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
              childAspectRatio: 1.3,
            ),
            itemBuilder: (context, index) {
              if (index < offsetDomingo) {
                return const SizedBox.shrink();
              }
              final dia = index - offsetDomingo + 1;
              final dataCorrente =
                  DateTime(mesCalendario.year, mesCalendario.month, dia);

              final selecionada = datasSelecionadas.any((d) =>
                  d.year == dataCorrente.year &&
                  d.month == dataCorrente.month &&
                  d.day == dataCorrente.day);

              return InkWell(
                onTap: () => onDataAlternada(dataCorrente),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  decoration: BoxDecoration(
                    color: selecionada
                        ? theme.textColor.withValues(alpha: 0.22)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: selecionada
                          ? theme.textColor
                          : theme.borderColor.withValues(alpha: 0.3),
                      width: selecionada ? 1.6 : 1.0,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$dia',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        fontWeight: selecionada ? FontWeight.bold : FontWeight.normal,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
