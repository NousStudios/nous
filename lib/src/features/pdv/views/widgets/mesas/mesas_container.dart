import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

String _valorFormatado(double valor) =>
    'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

class MesasContainer extends StatefulWidget {
  final AppTheme theme;
  final List<MesaLoja> mesas;
  final VoidCallback aoCriarMesa;
  final ValueChanged<MesaLoja> aoClicarMesa;

  const MesasContainer({
    super.key,
    required this.theme,
    required this.mesas,
    required this.aoCriarMesa,
    required this.aoClicarMesa,
  });

  @override
  State<MesasContainer> createState() => _MesasContainerState();
}

class _MesasContainerState extends State<MesasContainer> {
  bool _expandido = true;

  BoxDecoration get _decoracaoDoBloco => BoxDecoration(
        color: widget.theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.theme.borderColor.withValues(alpha: 0.6),
        ),
      );

  Widget _cardMesa(MesaLoja mesa) {
    final isOcupada = mesa.status == StatusMesa.ocupada;

    return _CardMesaComHover(
      theme: widget.theme,
      aoClicar: () => widget.aoClicarMesa(mesa),
      builder: (hover) {
        return Container(
          width: 145,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hover
                ? widget.theme.borderColor.withValues(alpha: 0.18)
                : widget.theme.backgroundColor.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOcupada
                  ? widget.theme.textColor
                  : (hover
                      ? widget.theme.textColor
                      : widget.theme.borderColor.withValues(alpha: 0.6)),
              width: isOcupada ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      mesa.numero,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: widget.theme.getTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: widget.theme.textColor,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isOcupada
                          ? widget.theme.textColor.withValues(alpha: 0.15)
                          : widget.theme.backgroundColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isOcupada
                            ? widget.theme.textColor
                            : widget.theme.borderColor,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      isOcupada ? 'OCUPADA' : 'LIVRE',
                      style: widget.theme.getTextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isOcupada
                            ? widget.theme.textColor
                            : widget.theme.secondaryTextColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (mesa.descricao.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  mesa.descricao,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: widget.theme.getTextStyle(
                    fontSize: 11,
                    color: widget.theme.secondaryTextColor,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              if (isOcupada) ...[
                Text(
                  _valorFormatado(mesa.totalAcumulado),
                  style: widget.theme.getTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: widget.theme.textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${mesa.quantidadeItensTotal} ${mesa.quantidadeItensTotal == 1 ? "item" : "itens"}',
                  style: widget.theme.getTextStyle(
                    fontSize: 10,
                    color: widget.theme.secondaryTextColor,
                  ),
                ),
                if (mesa.atendenteNome.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    mesa.atendenteNome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: widget.theme.getTextStyle(
                      fontSize: 10,
                      color: widget.theme.secondaryTextColor,
                    ),
                  ),
                ],
              ] else ...[
                Text(
                  'Disponível',
                  style: widget.theme.getTextStyle(
                    fontSize: 12,
                    color: widget.theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalMesas = widget.mesas.length;
    final totalOcupadas =
        widget.mesas.where((m) => m.status == StatusMesa.ocupada).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _decoracaoDoBloco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho colapsável
          Row(
            children: [
              Icon(
                Icons.table_restaurant_outlined,
                size: 22,
                color: widget.theme.textColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Mesas e Comandas',
                style: widget.theme.getTextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: widget.theme.textColor,
                ),
              ),
              const SizedBox(width: 8),
              if (totalMesas > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.theme.backgroundColor.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: widget.theme.borderColor),
                  ),
                  child: Text(
                    '$totalMesas ($totalOcupadas ocupadas)',
                    style: widget.theme.getTextStyle(
                      fontSize: 11,
                      color: widget.theme.secondaryTextColor,
                    ),
                  ),
                ),
              const Spacer(),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: widget.theme.borderColor),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(Icons.add, size: 16, color: widget.theme.textColor),
                label: Text(
                  'Nova Mesa',
                  style: widget.theme.getTextStyle(
                    fontSize: 12,
                    color: widget.theme.textColor,
                  ),
                ),
                onPressed: widget.aoCriarMesa,
              ),
              const SizedBox(width: 6),
              IconButton(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  _expandido ? Icons.expand_less : Icons.expand_more,
                  color: widget.theme.textColor,
                ),
                onPressed: () => setState(() => _expandido = !_expandido),
              ),
            ],
          ),
          if (_expandido) ...[
            const SizedBox(height: 14),
            if (widget.mesas.isEmpty)
              EstadoVazioContainer(
                theme: widget.theme,
                mensagem:
                    'Nenhuma mesa cadastrada. Clique em "Nova Mesa" para começar.',
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: widget.mesas.map(_cardMesa).toList(),
              ),
          ],
        ],
      ),
    );
  }
}

class _CardMesaComHover extends StatefulWidget {
  final AppTheme theme;
  final VoidCallback aoClicar;
  final Widget Function(bool hover) builder;

  const _CardMesaComHover({
    required this.theme,
    required this.aoClicar,
    required this.builder,
  });

  @override
  State<_CardMesaComHover> createState() => _CardMesaComHoverState();
}

class _CardMesaComHoverState extends State<_CardMesaComHover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.aoClicar,
        child: widget.builder(_hover),
      ),
    );
  }
}
