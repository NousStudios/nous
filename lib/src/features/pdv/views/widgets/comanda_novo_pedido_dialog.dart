import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/impressao_service.dart';
import 'package:nous/src/features/pdv/views/widgets/comanda_pedido.dart';

enum AcaoComandaNovoPedido {
  aceitar,
  recusar,
  fechar,
}

String _numeroPedido(int n) => '#${n.toString().padLeft(4, '0')}';

class ComandaNovoPedidoDialog extends StatelessWidget {
  final String lojaId;
  final PedidoLoja pedido;
  final Cliente? cliente;
  final int totalRestantes;

  const ComandaNovoPedidoDialog({
    super.key,
    required this.lojaId,
    required this.pedido,
    this.cliente,
    this.totalRestantes = 1,
  });

  static Future<AcaoComandaNovoPedido?> mostrar(
    BuildContext context, {
    required String lojaId,
    required PedidoLoja pedido,
    Cliente? cliente,
    int totalRestantes = 1,
  }) {
    return showDialog<AcaoComandaNovoPedido>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ComandaNovoPedidoDialog(
        lojaId: lojaId,
        pedido: pedido,
        cliente: cliente,
        totalRestantes: totalRestantes,
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

        return Dialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.borderColor.withValues(alpha: 0.6),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440, maxHeight: 720),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cabeçalho com identificação do novo pedido e contador
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.textColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_active_outlined,
                          color: theme.textColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Novo Pedido ${_numeroPedido(pedido.numero)}',
                              style: theme.getTextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                            if (totalRestantes > 1)
                              Text(
                                '$totalRestantes novos pedidos pendentes',
                                style: theme.getTextStyle(
                                  fontSize: 11,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (totalRestantes > 1)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.textColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.borderColor.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            'Fila: $totalRestantes',
                            style: theme.getTextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: theme.secondaryTextColor,
                          size: 20,
                        ),
                        tooltip: 'Fechar / Ver depois',
                        onPressed: () => Navigator.of(context)
                            .pop(AcaoComandaNovoPedido.fechar),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Visualização rica e completa da comanda
                  Flexible(
                    child: SingleChildScrollView(
                      child: ComandaPedido(
                        theme: theme,
                        pedido: pedido,
                        cliente: cliente,
                        largura: 380,
                        mostrarTitulo: false,
                        camposClienteComanda: configImpressora
                                ?.camposClienteComanda ??
                            kCamposClienteComandaPadrao,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Botões de ação solicitados: Recusar, Imprimir e Aceitar
                  Row(
                    children: [
                      // Botão Recusar
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: BorderSide(
                              color: Colors.redAccent.withValues(alpha: 0.8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.close, size: 18),
                          label: Text(
                            'Recusar',
                            style: theme.getTextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                          onPressed: () => Navigator.of(context)
                              .pop(AcaoComandaNovoPedido.recusar),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Botão Imprimir
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
                          label: Text(
                            'Imprimir',
                            style: theme.getTextStyle(
                              fontSize: 12,
                              color: theme.textColor,
                            ),
                          ),
                          onPressed: () async {
                            if (configImpressora == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: theme.cardBackgroundColor,
                                  content: Text(
                                    'Impressora não configurada em Ajustes da Loja.',
                                    style: theme.getTextStyle(
                                      color: theme.textColor,
                                    ),
                                  ),
                                ),
                              );
                              return;
                            }
                            await ImpressaoService.imprimirComanda(
                              config: configImpressora,
                              pedido: pedido,
                              cliente: cliente,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: theme.cardBackgroundColor,
                                  content: Text(
                                    'Comanda #${pedido.numero} enviada para impressão.',
                                    style: theme.getTextStyle(
                                      color: theme.textColor,
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Botão Aceitar
                      Expanded(
                        flex: 1,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.buttonColor,
                            foregroundColor: theme.textColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(
                            'Aceitar',
                            style: theme.getTextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                          onPressed: () => Navigator.of(context)
                              .pop(AcaoComandaNovoPedido.aceitar),
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
