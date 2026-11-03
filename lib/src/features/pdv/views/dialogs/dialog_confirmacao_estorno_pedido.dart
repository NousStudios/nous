import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';

/// Diálogo de confirmação de estorno de itens ao estoque ao excluir um pedido.
class DialogConfirmacaoEstornoPedido {
  static Future<bool> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required PedidoLoja pedido,
  }) async {
    String numeroPedido(int n) => '#${n.toString().padLeft(4, '0')}';

    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Estorno de Estoque',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: Text(
            'Deseja devolver os ${pedido.itens.length} itens do Pedido ${numeroPedido(pedido.numero)} de volta ao estoque?',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(fontSize: 14),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Não devolver',
                style: theme.getTextStyle(color: theme.secondaryTextColor),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.buttonColor,
                foregroundColor: theme.buttonTextColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                'Sim, devolver ao estoque',
                style: theme.getTextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.buttonTextColor,
                ),
              ),
            ),
          ],
        );
      },
    );

    return resultado == true;
  }
}
