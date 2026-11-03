import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';

class CardVendaTurno extends StatefulWidget {
  final AppTheme theme;
  final PedidoLoja pedido;
  final String Function(double) formatarMoeda;
  final String Function(DateTime) formatarDataHora;

  const CardVendaTurno({
    super.key,
    required this.theme,
    required this.pedido,
    required this.formatarMoeda,
    required this.formatarDataHora,
  });

  @override
  State<CardVendaTurno> createState() => _CardVendaTurnoState();
}

class _CardVendaTurnoState extends State<CardVendaTurno> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.pedido;
    final theme = widget.theme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _hover
              ? theme.borderColor.withValues(alpha: 0.18)
              : theme.borderColor.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _hover
                ? theme.textColor
                : theme.borderColor.withValues(alpha: 0.35),
            width: _hover ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.shopping_bag_outlined,
                size: 16, color: theme.secondaryTextColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Venda #${p.id.length > 6 ? p.id.substring(p.id.length - 6) : p.id}',
                        style: theme.getTextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                      if (p.clienteNome.isNotEmpty) ...[
                        Text(
                          ' • ${p.clienteNome}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 11,
                            color: theme.textColor,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        widget.formatarMoeda(p.valor),
                        style: theme.getTextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'Pagamento: ${p.todosPagamentos.isNotEmpty ? p.todosPagamentos.map((x) => x.forma).join(", ") : p.formaPagamento}',
                        style: theme.getTextStyle(
                          fontSize: 10,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        widget.formatarDataHora(p.dataHora),
                        style: theme.getTextStyle(
                          fontSize: 10,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
