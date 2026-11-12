import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';

/// Visão de Revisão do Carrinho: listagem com botões de incremento/decremento,
/// seletor de forma de pagamento e campo de observações.
class VisaoCarrinhoChatWidget extends StatelessWidget {
  final AppTheme theme;
  final Loja loja;
  final List<ItemVendido> carrinho;
  final String formaPagamento;
  final TextEditingController observacaoController;
  final TextEditingController trocoController;
  final void Function(int index) onDecrementarOuRemover;
  final void Function(int index) onIncrementar;
  final void Function(String forma) onSelecionarFormaPagamento;

  const VisaoCarrinhoChatWidget({
    super.key,
    required this.theme,
    required this.loja,
    required this.carrinho,
    required this.formaPagamento,
    required this.observacaoController,
    required this.trocoController,
    required this.onDecrementarOuRemover,
    required this.onIncrementar,
    required this.onSelecionarFormaPagamento,
  });

  String _formatarPreco(double v) => 'R\$ ${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    const formas = [
      'PIX',
      'Dinheiro',
      'Cartão de Crédito',
      'Cartão de Débito',
      'Voucher',
      'A prazo',
      'A combinar no chat',
    ];

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (int i = 0; i < carrinho.length; i++)
          Builder(
            builder: (_) {
              final item = carrinho[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.nomeExibicao,
                            style: theme.getTextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                          for (final a in item.acompanhamentos)
                            Text(
                              ' + ${a.quantidadePorUnidade}x ${a.nomeItem}',
                              style: theme.getTextStyle(
                                fontSize: 11,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          if (item.observacao.isNotEmpty)
                            Text(
                              ' Obs: ${item.observacao}',
                              style: theme.getTextStyle(
                                fontSize: 11,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            _formatarPreco(item.subtotal),
                            style: theme.getTextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.buttonColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            item.quantidade > 1
                                ? Icons.remove
                                : Icons.delete_outline,
                            size: 18,
                          ),
                          color: item.quantidade > 1
                              ? theme.textColor
                              : theme.dangerColor,
                          onPressed: () => onDecrementarOuRemover(i),
                        ),
                        Text(
                          '${item.quantidade}',
                          style: theme.getTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          color: theme.textColor,
                          onPressed: () => onIncrementar(i),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 8),
        Text(
          'Forma de pagamento preferida:',
          style: theme.getTextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: theme.secondaryTextColor,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final fp in formas)
              ChoiceChip(
                selected: formaPagamento == fp,
                label: Text(fp),
                labelStyle: theme.getTextStyle(
                  fontSize: 11.5,
                  fontWeight: formaPagamento == fp
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: formaPagamento == fp
                      ? theme.buttonTextColor
                      : theme.textColor,
                ),
                backgroundColor: theme.backgroundColor,
                selectedColor: theme.buttonColor,
                checkmarkColor: theme.buttonTextColor,
                side: BorderSide(
                  color: formaPagamento == fp
                      ? theme.buttonColor
                      : theme.borderColor.withValues(alpha: 0.6),
                ),
                onSelected: (_) => onSelecionarFormaPagamento(fp),
              ),
          ],
        ),
        if (formaPagamento == 'Dinheiro') ...[
          const SizedBox(height: 10),
          TextField(
            controller: trocoController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.backgroundColor,
              labelText: 'Troco para quanto? (opcional)',
              labelStyle: theme.getTextStyle(
                fontSize: 11,
                color: theme.secondaryTextColor,
              ),
              hintText: 'Ex: 50,00 (deixe vazio se não precisar de troco)',
              hintStyle: theme.getTextStyle(
                fontSize: 11,
                color: theme.secondaryTextColor.withValues(alpha: 0.5),
              ),
              prefixText: 'R\$ ',
              prefixStyle: theme.getTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: theme.borderColor.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.textColor),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: observacaoController,
          maxLines: 2,
          style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.backgroundColor,
            labelText: 'Observações de Entrega / Pedido',
            labelStyle: theme.getTextStyle(
              fontSize: 11,
              color: theme.secondaryTextColor,
            ),
            hintText: 'Ex: Entregar no portão preto, sem cebola...',
            hintStyle: theme.getTextStyle(
              fontSize: 11,
              color: theme.secondaryTextColor.withValues(alpha: 0.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: theme.borderColor.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.textColor),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
          ),
        ),
      ],
    );
  }
}
