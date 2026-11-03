import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';

String formatarQuantidadeEstoque(double v, UnidadeItemLoja unidade) {
  String numero;
  if (v == v.truncateToDouble()) {
    numero = v.toInt().toString();
  } else {
    numero = v.toStringAsFixed(2).replaceAll('.', ',');
  }
  switch (unidade) {
    case UnidadeItemLoja.un:
      return numero;
    case UnidadeItemLoja.g:
      return '$numero g';
    case UnidadeItemLoja.ml:
      return '$numero ml';
  }
}

/// Widget que exibe uma movimentação de estoque individual (Kardex).
class LinhaMovimentoWidget extends StatefulWidget {
  final AppTheme theme;
  final MovimentoEstoque movimento;
  final UnidadeItemLoja unidade;
  final bool podeExcluir;
  final VoidCallback onExcluir;

  const LinhaMovimentoWidget({
    super.key,
    required this.theme,
    required this.movimento,
    required this.unidade,
    required this.podeExcluir,
    required this.onExcluir,
  });

  @override
  State<LinhaMovimentoWidget> createState() => _LinhaMovimentoWidgetState();
}

class _LinhaMovimentoWidgetState extends State<LinhaMovimentoWidget> {
  bool _hover = false;

  AppTheme get theme => widget.theme;

  String _dataHora(DateTime d) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year} '
        '${dois(d.hour)}:${dois(d.minute)}';
  }

  String _valor(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  String _rotuloCategoria(CategoriaMovimentoEstoque c) {
    switch (c) {
      case CategoriaMovimentoEstoque.compra:
        return 'Compra';
      case CategoriaMovimentoEstoque.venda:
        return 'Venda';
      case CategoriaMovimentoEstoque.ajuste:
        return 'Ajuste';
      case CategoriaMovimentoEstoque.perda:
        return 'Perda';
      case CategoriaMovimentoEstoque.producao:
        return 'Produção';
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.movimento;
    final ehEntrada = m.ehEntrada;

    final sinal = ehEntrada ? '+' : '-';
    final sufixoCusto =
        m.custoUnitario > 0 ? ' • ${_valor(m.custoUnitario)}/un' : '';
    final linha1 =
        '$sinal${formatarQuantidadeEstoque(m.quantidade, widget.unidade)}$sufixoCusto';

    final sufixoAutor =
        m.nomeAutor.isNotEmpty ? ' • ${m.nomeAutor}' : '';
    final categoria = _rotuloCategoria(m.categoria);
    final linha2 = '${_dataHora(m.dataHora)} • $categoria$sufixoAutor';

    final sufixoFornecedor =
        m.fornecedorNome.isNotEmpty ? ' • ${m.fornecedorNome}' : '';

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _hover
              ? theme.borderColor.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _hover ? theme.textColor : theme.borderColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              ehEntrada ? Icons.arrow_downward : Icons.arrow_upward,
              size: 18,
              color: ehEntrada ? theme.textColor : Colors.redAccent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    linha1,
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.textColor,
                    ),
                  ),
                  Text(
                    linha2,
                    style: theme.getTextStyle(
                      fontSize: 10,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  if (sufixoFornecedor.isNotEmpty)
                    Text(
                      'Fornecedor$sufixoFornecedor',
                      style: theme.getTextStyle(
                        fontSize: 10,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  if (m.motivo.trim().isNotEmpty)
                    Text(
                      m.motivo.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.getTextStyle(
                        fontSize: 10,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                ],
              ),
            ),
            if (widget.podeExcluir)
              IconButton(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(Icons.delete_outline,
                    size: 18, color: theme.secondaryTextColor),
                onPressed: widget.onExcluir,
              ),
          ],
        ),
      ),
    );
  }
}
