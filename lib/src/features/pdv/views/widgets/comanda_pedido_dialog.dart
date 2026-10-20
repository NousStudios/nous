import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/impressao_service.dart';
import 'package:nous/src/features/pdv/views/widgets/comanda_pedido.dart';

class ComandaPedidoDialog extends StatelessWidget {
  final String lojaId;
  final PedidoLoja pedido;
  final Cliente? cliente;

  const ComandaPedidoDialog({
    super.key,
    required this.lojaId,
    required this.pedido,
    this.cliente,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required String lojaId,
    required PedidoLoja pedido,
    Cliente? cliente,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => ComandaPedidoDialog(
        lojaId: lojaId,
        pedido: pedido,
        cliente: cliente,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, _) {
        final pdv = context.read<PdvProvider>();
        final loja = pdv.buscarPorId(lojaId);
        final configImpressora = loja?.configuracoesImpressora;

        var pedidoEfetivo = pedido;
        if (loja != null &&
            (pedidoEfetivo.nomeVendedor.isEmpty ||
                pedidoEfetivo.cnpjVendedor.isEmpty)) {
          pedidoEfetivo = pedidoEfetivo.copyWith(
            nomeVendedor: pedidoEfetivo.nomeVendedor.isNotEmpty
                ? pedidoEfetivo.nomeVendedor
                : loja.nome,
            cnpjVendedor: pedidoEfetivo.cnpjVendedor.isNotEmpty
                ? pedidoEfetivo.cnpjVendedor
                : loja.cnpj,
          );
        }

        return Dialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.borderColor.withValues(alpha: 0.6),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 680),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long, color: theme.textColor, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Comanda do Pedido',
                          style: theme.getTextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: theme.secondaryTextColor, size: 20),
                        tooltip: 'Fechar',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: ComandaPedido(
                        theme: theme,
                        pedido: pedidoEfetivo,
                        cliente: cliente,
                        largura: 360,
                        mostrarTitulo: false,
                        camposClienteComanda: configImpressora?.camposClienteComanda ??
                            kCamposClienteComandaPadrao,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (configImpressora != null) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.textColor,
                              side: BorderSide(color: theme.borderColor),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.print, size: 18),
                            label: const Text('Imprimir'),
                            onPressed: () async {
                              await ImpressaoService.imprimirComanda(
                                config: configImpressora,
                                pedido: pedidoEfetivo,
                                cliente: cliente,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: theme.cardBackgroundColor,
                                    content: Text(
                                      'Comanda enviada para a impressora.',
                                      style: theme.getTextStyle(color: theme.textColor),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.buttonColor,
                            foregroundColor: theme.textColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Fechar'),
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
  }
}
