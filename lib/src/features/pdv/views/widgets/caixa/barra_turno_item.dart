import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/turno_caixa.dart';

class BarraTurnoItem extends StatefulWidget {
  final AppTheme theme;
  final TurnoCaixa turno;
  final String Function(DateTime) formatarDataHora;
  final String Function(double) formatarMoeda;
  final VoidCallback aoClicar;
  final VoidCallback aoReimprimir;

  const BarraTurnoItem({
    super.key,
    required this.theme,
    required this.turno,
    required this.formatarDataHora,
    required this.formatarMoeda,
    required this.aoClicar,
    required this.aoReimprimir,
  });

  @override
  State<BarraTurnoItem> createState() => _BarraTurnoItemState();
}

class _BarraTurnoItemState extends State<BarraTurnoItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.turno;
    final theme = widget.theme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.aoClicar,
        child: Tooltip(
          message: 'Clique para ver detalhes do turno, retiradas e histórico',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: _hover
                  ? theme.borderColor.withValues(alpha: 0.18)
                  : theme.borderColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _hover
                    ? theme.textColor
                    : theme.borderColor.withValues(alpha: 0.4),
                width: _hover ? 1.4 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Fechado em ${widget.formatarDataHora(t.dataFechamento ?? t.dataAbertura)}',
                            style: theme.getTextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                          if (t.movimentacoes.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color:
                                    theme.borderColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${t.movimentacoes.length} mov.',
                                style: theme.getTextStyle(
                                  fontSize: 9,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Saldo Final: ${widget.formatarMoeda(t.saldoFinalInformado ?? 0.0)}'
                        '${t.fechadoPorNome.isNotEmpty ? " • Operador: ${t.fechadoPorNome}" : ""}',
                        style: theme.getTextStyle(
                          fontSize: 10,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                      if (t.observacao.trim().isNotEmpty)
                        Text(
                          'Obs: ${t.observacao.trim()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 10,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Reimprimir comprovante',
                  icon: Icon(Icons.print_outlined,
                      size: 16, color: theme.textColor),
                  onPressed: widget.aoReimprimir,
                ),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: _hover ? theme.textColor : theme.secondaryTextColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
