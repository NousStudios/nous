import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Rodapé padrão do Autoatendimento: Total e quantidade na linha 1;
/// Botões de ação "Revisar" e "Despachar/Enviar Proposta" na linha 2.
class RodapeResumoPedidoChatWidget extends StatelessWidget {
  final AppTheme theme;
  final double total;
  final int quantidadeTotal;
  final bool temItens;
  final bool vendoCarrinho;
  final bool enviando;
  final bool modoLoja;
  final VoidCallback onAlternarVisaoCarrinho;
  final VoidCallback? onFinalizarPedido;

  const RodapeResumoPedidoChatWidget({
    super.key,
    required this.theme,
    required this.total,
    required this.quantidadeTotal,
    required this.temItens,
    required this.vendoCarrinho,
    required this.enviando,
    required this.modoLoja,
    required this.onAlternarVisaoCarrinho,
    required this.onFinalizarPedido,
  });

  String _formatarPreco(double v) => 'R\$ ${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        border: Border(
          top: BorderSide(color: theme.borderColor.withValues(alpha: 0.4)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Linha 1: Valor total e quantidade de itens selecionados
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ${_formatarPreco(total)}',
                style: theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              Text(
                '$quantidadeTotal item${quantidadeTotal == 1 ? '' : 's'} selecionado${quantidadeTotal == 1 ? '' : 's'}',
                style: theme.getTextStyle(
                  fontSize: 11.5,
                  color: theme.secondaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Linha 2: Botões de ação em largura completa
          Row(
            children: [
              if (temItens) ...[
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.textColor,
                      side: BorderSide(color: theme.borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: Icon(
                      vendoCarrinho
                          ? Icons.menu_book_rounded
                          : Icons.receipt_long_rounded,
                      size: 16,
                    ),
                    label: Text(
                      vendoCarrinho ? 'Cardápio' : 'Revisar ($quantidadeTotal)',
                      style: theme.getTextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    onPressed: onAlternarVisaoCarrinho,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.buttonColor,
                    foregroundColor: theme.buttonTextColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: enviando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, size: 17),
                  label: Text(
                    enviando
                        ? 'Enviando...'
                        : (modoLoja ? 'Enviar Proposta' : 'Despachar Pedido'),
                    style: theme.getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.buttonTextColor,
                    ),
                  ),
                  onPressed: enviando || !temItens ? null : onFinalizarPedido,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
