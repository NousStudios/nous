import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';

class DialogCompartilharComanda {
  static void mostrar(
    BuildContext context, {
    required AppTheme theme,
    required List<PedidoLoja> pedidos,
    required void Function(PedidoLoja pedido) onCompartilhar,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                color: theme.textColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Selecionar Comanda',
                style: theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 380,
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.70,
            ),
            child: pedidos.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Nenhum pedido encontrado para compartilhar.',
                        textAlign: TextAlign.center,
                        style: theme.getTextStyle(
                          fontSize: 13,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: pedidos.length,
                    separatorBuilder: (dialogCtx, index) => Divider(
                      height: 1,
                      color: theme.borderColor.withValues(alpha: 0.3),
                    ),
                    itemBuilder: (dialogCtx, index) {
                      final p = pedidos[index];
                      final numStr = p.numero.toString().padLeft(4, '0');
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: theme.buttonColor.withValues(
                            alpha: 0.15,
                          ),
                          child: Icon(
                            Icons.receipt_rounded,
                            color: theme.buttonColor,
                            size: 18,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              'Pedido #$numStr',
                              style: theme.getTextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'R\$ ${p.valor.toStringAsFixed(2)}',
                              style: theme.getTextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            Expanded(
                              child: Text(
                                p.clienteNome.isNotEmpty
                                    ? p.clienteNome
                                    : 'Balcão',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.getTextStyle(
                                  fontSize: 11,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                            ),
                            Text(
                              p.status.name.toUpperCase(),
                              style: theme.getTextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          onCompartilhar(p);
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancelar',
                style: theme.getTextStyle(color: theme.secondaryTextColor),
              ),
            ),
          ],
        );
      },
    );
  }
}
