import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/impressao_service.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/pdv/views/widgets/venda_registrada_dialog.dart';
import 'package:provider/provider.dart';

class HistoricoComprasClienteWidget extends StatelessWidget {
  final AppTheme theme;
  final String lojaId;
  final Cliente cliente;
  final List<PedidoLoja> historico;

  const HistoricoComprasClienteWidget({
    super.key,
    required this.theme,
    required this.lojaId,
    required this.cliente,
    required this.historico,
  });

  static String _valor(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  Future<void> _exportarExtratoPDF(BuildContext context) async {
    try {
      final pdv = context.read<PdvProvider>();
      final loja = pdv.buscarPorId(lojaId) ??
          (pdv.lojas.isNotEmpty ? pdv.lojas.first : null);

      if (loja == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: theme.cardBackgroundColor,
              content: Text(
                'Loja não encontrada para gerar o extrato.',
                style: theme.getTextStyle(color: Colors.redAccent),
              ),
            ),
          );
        }
        return;
      }

      final caminho = await ImpressaoService.exportarExtratoClientePDF(
        loja: loja,
        cliente: cliente,
        pedidos: historico,
      );

      if (caminho != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.cardBackgroundColor,
            content: Text(
              'Extrato do cliente exportado com sucesso em $caminho',
              style: theme.getTextStyle(color: theme.textColor),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.cardBackgroundColor,
            content: Text(
              'Falha ao exportar extrato: $e',
              style: theme.getTextStyle(color: Colors.redAccent),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalGasto = historico
        .where((p) => p.status != StatusPedido.cancelado)
        .fold<double>(0, (s, p) => s + p.valor);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Histórico de Compras',
                      style: theme.getTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    if (historico.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${historico.length} ${historico.length == 1 ? "compra" : "compras"} • Total: ${_valor(totalGasto)}',
                        style: theme.getTextStyle(
                          fontSize: 11,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (historico.isNotEmpty)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.textColor,
                    side: BorderSide(
                      color: theme.borderColor.withValues(alpha: 0.6),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  icon: Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 16,
                    color: theme.textColor,
                  ),
                  label: Text(
                    'Exportar Extrato PDF',
                    style: theme.getTextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                  onPressed: () => _exportarExtratoPDF(context),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (historico.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhuma compra registrada para este cliente.',
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: historico.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return BarraVenda(
                    theme: theme,
                    lojaId: lojaId,
                    pedido: historico[index],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
