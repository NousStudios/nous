import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';

class BlocoComandaProgramadaWidget extends StatelessWidget {
  final AppTheme theme;
  final List<ItemVendido> itensAdicionados;
  final double totalGeralPedido;
  final ValueChanged<int> onRemoverItem;
  final String formaPagamento;
  final List<String> formasDisponiveis;
  final ValueChanged<String?> onFormaPagamentoChanged;
  final TextEditingController obsGeralController;
  final String Function(double valor) valorFormatado;

  const BlocoComandaProgramadaWidget({
    super.key,
    required this.theme,
    required this.itensAdicionados,
    required this.totalGeralPedido,
    required this.onRemoverItem,
    required this.formaPagamento,
    required this.formasDisponiveis,
    required this.onFormaPagamentoChanged,
    required this.obsGeralController,
    required this.valorFormatado,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bloco Itens do Pedido
        if (itensAdicionados.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.backgroundColor.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: theme.borderColor.withValues(alpha: 0.4)),
            ),
            child: Center(
              child: Text(
                'Nenhum item adicionado ao pedido ainda.',
                style: theme.getTextStyle(
                    fontSize: 12, color: theme.secondaryTextColor),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.backgroundColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, size: 16, color: theme.textColor),
                    const SizedBox(width: 6),
                    Text(
                      'Comanda do Pedido (${itensAdicionados.length} itens) • ${valorFormatado(totalGeralPedido)}',
                      textAlign: TextAlign.center,
                      style: theme.getTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: itensAdicionados.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final item = itensAdicionados[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: theme.borderColor.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.quantidade}x ${item.nomeExibicao}',
                                  style: theme.getTextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textColor,
                                  ),
                                ),
                                if (item.acompanhamentos.isNotEmpty)
                                  Text(
                                    item.acompanhamentos
                                        .map((a) =>
                                            '+ ${a.quantidadePorUnidade}x ${a.nomeItem}')
                                        .join(', '),
                                    style: theme.getTextStyle(
                                      fontSize: 10,
                                      color: theme.secondaryTextColor,
                                    ),
                                  ),
                                if (item.observacao.isNotEmpty)
                                  Text(
                                    'Obs: ${item.observacao}',
                                    style: theme.getTextStyle(
                                      fontSize: 10,
                                      color: theme.secondaryTextColor,
                                    ).copyWith(fontStyle: FontStyle.italic),
                                  ),
                                Text(
                                  valorFormatado(item.subtotal),
                                  style: theme.getTextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: Colors.redAccent),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => onRemoverItem(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        // Bloco Forma de Pagamento e Observações
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.backgroundColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment, size: 16, color: theme.textColor),
                  const SizedBox(width: 6),
                  Text(
                    'Forma de Pagamento e Detalhes',
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: formaPagamento,
                dropdownColor: theme.cardBackgroundColor,
                decoration: InputDecoration(
                  labelText: 'Forma de Pagamento',
                  labelStyle: theme.getTextStyle(
                      fontSize: 11, color: theme.secondaryTextColor),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.borderColor),
                  ),
                ),
                items: formasDisponiveis.map((f) {
                  return DropdownMenuItem<String>(
                    value: f,
                    child: Text(
                      f,
                      style: theme.getTextStyle(
                          fontSize: 12, color: theme.textColor),
                    ),
                  );
                }).toList(),
                onChanged: onFormaPagamentoChanged,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: obsGeralController,
                cursorColor: theme.textColor,
                style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
                decoration: InputDecoration(
                  labelText:
                      'Observações do Contrato / Pedido Programado (opcional)',
                  labelStyle: theme.getTextStyle(
                      fontSize: 11, color: theme.secondaryTextColor),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.borderColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
