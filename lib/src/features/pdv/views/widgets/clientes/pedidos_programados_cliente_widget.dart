import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/widgets/comanda_pedido_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/pdv/views/widgets/programar_pedido_dialog.dart';
import 'package:provider/provider.dart';

class PedidosProgramadosClienteWidget extends StatelessWidget {
  final AppTheme theme;
  final String lojaId;
  final Cliente cliente;

  const PedidosProgramadosClienteWidget({
    super.key,
    required this.theme,
    required this.lojaId,
    required this.cliente,
  });

  static String _valor(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    final pdv = context.watch<PdvProvider>();
    final loja = pdv.buscarPorId(lojaId);
    final programados = (loja?.pedidosProgramados ?? [])
        .where((p) =>
            p.clienteId == cliente.id ||
            p.clienteNome.trim().toLowerCase() ==
                cliente.nome.trim().toLowerCase())
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Pedidos Programados',
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                ),
                if (programados.isNotEmpty) ...[
                  Text(
                    '${programados.length} ${programados.length == 1 ? "pedido agendado" : "pedidos agendados"}',
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.textColor,
                    side: BorderSide(color: theme.borderColor),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.add_alarm, size: 16),
                  label: Text(
                    'Programar Pedido',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () {
                    ProgramarPedidoDialog.mostrar(
                      context,
                      lojaId: lojaId,
                      cliente: cliente,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (programados.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhum pedido programado para este cliente.',
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: programados.length,
                separatorBuilder: (context, index) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final p = programados[index];
                  final dataTexto = p.descricaoFrequencia;

                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.backgroundColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          p.recorrente ? Icons.repeat : Icons.event,
                          size: 18,
                          color: theme.textColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    dataTexto,
                                    style: theme.getTextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textColor,
                                    ),
                                  ),
                                  if (!p.ativo) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent
                                            .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Pausado',
                                        style: theme.getTextStyle(
                                          fontSize: 9,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p.itens
                                    .map((i) =>
                                        '${i.quantidade}x ${i.nomeExibicao}')
                                    .join(', '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.getTextStyle(
                                  fontSize: 11,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_valor(p.valorTotal)} • ${p.formaPagamento}',
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
                          icon: Icon(Icons.receipt_long,
                              size: 18, color: theme.textColor),
                          tooltip: 'Ver Comanda',
                          onPressed: () {
                            final pedidoLoja = p.toPedidoLoja(numero: 0);
                            ComandaPedidoDialog.mostrar(
                              context,
                              lojaId: lojaId,
                              pedido: pedidoLoja,
                              cliente: cliente,
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            p.ativo
                                ? Icons.pause_circle_outline
                                : Icons.play_circle_outline,
                            size: 18,
                            color: theme.textColor,
                          ),
                          tooltip: p.ativo ? 'Pausar' : 'Ativar',
                          onPressed: () {
                            pdv.alternarAtivoPedidoProgramado(lojaId, p.id);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Colors.redAccent),
                          tooltip: 'Excluir',
                          onPressed: () {
                            pdv.removerPedidoProgramado(lojaId, p.id);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
