import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pagamento_funcionario.dart';

/// Formatador de máscara para datas no formato DD/MM/AAAA.
class DataInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limitado = digitos.length > 8 ? digitos.substring(0, 8) : digitos;
    final buffer = StringBuffer();
    for (var i = 0; i < limitado.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(limitado[i]);
    }
    final texto = buffer.toString();
    var offset = newValue.selection.end;
    if (offset > texto.length) offset = texto.length;
    if (texto.length > oldValue.text.length && (offset == 2 || offset == 5)) {
      offset++;
    }
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

/// Widget interativo para exibir e gerenciar um pagamento a funcionário.
class LinhaPagamentoFuncionarioWidget extends StatefulWidget {
  final AppTheme theme;
  final PagamentoFuncionario pagamento;
  final bool podeExcluir;
  final VoidCallback onExcluir;

  const LinhaPagamentoFuncionarioWidget({
    super.key,
    required this.theme,
    required this.pagamento,
    required this.podeExcluir,
    required this.onExcluir,
  });

  @override
  State<LinhaPagamentoFuncionarioWidget> createState() =>
      _LinhaPagamentoFuncionarioWidgetState();
}

class _LinhaPagamentoFuncionarioWidgetState
    extends State<LinhaPagamentoFuncionarioWidget> {
  bool _hover = false;

  AppTheme get theme => widget.theme;

  String _dataHora(DateTime d) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year} '
        '${dois(d.hour)}:${dois(d.minute)}';
  }

  String _valor(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    final p = widget.pagamento;
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.textColor,
                    ),
                  ),
                  Text(
                    '${_dataHora(p.dataHora)}'
                    '${p.nomeAutor.isNotEmpty ? ' • por ${p.nomeAutor}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.getTextStyle(
                      fontSize: 10,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  if (p.descricao.trim().isNotEmpty)
                    Text(
                      p.descricao.trim(),
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
            const SizedBox(width: 8),
            Text(
              _valor(p.valor),
              style: theme.getTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
            if (widget.podeExcluir)
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                iconSize: 16,
                icon: Icon(Icons.more_vert,
                    color: theme.secondaryTextColor),
                color: theme.cardBackgroundColor,
                onSelected: (valor) {
                  if (valor == 'excluir') widget.onExcluir();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'excluir',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: 16, color: theme.secondaryTextColor),
                        const SizedBox(width: 8),
                        Text('Excluir',
                            style: theme.getTextStyle()),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget interativo para exibir uma compra de estoque no financeiro.
class LinhaCompraEstoqueWidget extends StatefulWidget {
  final AppTheme theme;
  final MovimentoEstoque movimento;
  final String nomeItem;
  final String unidade;

  const LinhaCompraEstoqueWidget({
    super.key,
    required this.theme,
    required this.movimento,
    required this.nomeItem,
    required this.unidade,
  });

  @override
  State<LinhaCompraEstoqueWidget> createState() =>
      _LinhaCompraEstoqueWidgetState();
}

class _LinhaCompraEstoqueWidgetState extends State<LinhaCompraEstoqueWidget> {
  bool _hover = false;

  AppTheme get theme => widget.theme;

  String _dataHora(DateTime d) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year} '
        '${dois(d.hour)}:${dois(d.minute)}';
  }

  String _valor(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  String _formatarQuantidade(double qtd, String unidade) {
    final qtdFormatada = qtd == qtd.roundToDouble()
        ? qtd.toInt().toString()
        : qtd.toStringAsFixed(2).replaceAll('.', ',');
    return '$qtdFormatada $unidade';
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.movimento;
    final qtdFormatada = _formatarQuantidade(m.quantidade, widget.unidade);
    final custoUnit = _valor(m.custoUnitario);
    final detalhes = <String>[
      '$qtdFormatada x $custoUnit',
      if (m.fornecedorNome.trim().isNotEmpty) m.fornecedorNome.trim(),
      _dataHora(m.dataHora),
    ];

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.nomeItem,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detalhes.join(' • '),
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
            const SizedBox(width: 8),
            Text(
              _valor(m.custoTotal),
              style: theme.getTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget genérico para aplicar efeito de hover com cursor de clique.
class LinhaComHoverWidget extends StatefulWidget {
  final Widget Function(bool hover) builder;
  final VoidCallback aoClicar;

  const LinhaComHoverWidget({
    super.key,
    required this.builder,
    required this.aoClicar,
  });

  @override
  State<LinhaComHoverWidget> createState() => _LinhaComHoverWidgetState();
}

class _LinhaComHoverWidgetState extends State<LinhaComHoverWidget> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.aoClicar,
        child: widget.builder(_hover),
      ),
    );
  }
}
