import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

class VendaConcluidaDialog {
  static Future<bool> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required int numeroPedido,
    required double valorTotal,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: theme.cardBackgroundColor,
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Venda concluída',
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pedido #${numeroPedido.toString().padLeft(4, '0')}',
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(
                      fontSize: 14,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${valorTotal.toStringAsFixed(2).replaceAll('.', ',')}',
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(
                      fontSize: 14,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.textColor,
                            side: BorderSide(color: theme.borderColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: theme.cardBackgroundColor,
                                content: Text(
                                  'Impressora ainda não configurada.',
                                  style: theme.getTextStyle(
                                      color: theme.textColor),
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'Imprimir',
                            style: theme.getTextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: theme.buttonColor,
                            foregroundColor: theme.buttonTextColor,
                            side: BorderSide(color: theme.borderColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: Text(
                            'Concluído',
                            style: theme.getTextStyle(
                              fontSize: 13,
                              color: theme.buttonTextColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    return resultado ?? false;
  }
}