import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_programado.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/comanda_pedido_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/programar_pedido_dialog.dart';

class PedidosProgramadosDialog extends StatelessWidget {
  final String lojaId;
  final List<PedidoProgramado> pedidos;

  const PedidosProgramadosDialog({
    super.key,
    required this.lojaId,
    required this.pedidos,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required String lojaId,
    required List<PedidoProgramado> pedidos,
  }) {
    if (pedidos.isEmpty) return Future.value();
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => PedidosProgramadosDialog(
        lojaId: lojaId,
        pedidos: pedidos,
      ),
    );
  }

  String _formatarValor(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, _) {
        final auth = context.read<AuthProvider>();
        final pdv = context.watch<PdvProvider>();
        final loja = pdv.buscarPorId(lojaId);
        final agora = DateTime.now();
        final diaStr = agora.day.toString().padLeft(2, '0');
        final mesStr = agora.month.toString().padLeft(2, '0');

        final idsIniciais = pedidos.map((p) => p.id).toSet();
        final listaAtiva = loja != null
            ? pdv.pedidosProgramadosDoDia(lojaId).where((prog) {
                if (!idsIniciais.contains(prog.id) &&
                    !prog.coincideComData(agora)) {
                  return false;
                }
                final idEsperadoHoje =
                    'prog_${prog.id}_${agora.year}_${mesStr}_$diaStr';
                final pedidoExistente = loja.pedidosLoja.where((p) {
                  if (p.id == idEsperadoHoje) return true;
                  if (p.id.startsWith('prog_${prog.id}_') &&
                      p.dataHora.year == agora.year &&
                      p.dataHora.month == agora.month &&
                      p.dataHora.day == agora.day) {
                    return true;
                  }
                  return false;
                }).firstOrNull;
                if (pedidoExistente != null &&
                    pedidoExistente.status != StatusPedido.novo) {
                  return false;
                }
                return true;
              }).toList()
            : pedidos;

        return Dialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor.withValues(alpha: 0.6)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.alarm_on, color: theme.textColor, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pedidos Programados de Hoje',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.getTextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                            Text(
                              '${listaAtiva.length} pedido(s) agendado(s) para hoje',
                              style: theme.getTextStyle(
                                fontSize: 11,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: theme.secondaryTextColor, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: listaAtiva.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final prog = listaAtiva[index];
                        final cliente = prog.resolverCliente(
                          loja?.clientesLoja ?? const [],
                        );

                        String foto = cliente.foto;
                        if (foto.isEmpty && cliente.cnpj.isNotEmpty) {
                          foto = auth.buscarFotoPorCpf(cliente.cnpj);
                          if (foto.isEmpty) {
                            foto = pdv.buscarFotoClientePorCpf(cliente.cnpj) ?? '';
                          }
                        }
                        final fotoResolvida = ImagemService.resolverCaminhoExistente(foto);
                        final temFoto = fotoResolvida != null;
                        final pedidoDoDia = prog.resolverPedidoDoDia(
                          pedidosExistentes: loja?.pedidosLoja ?? const [],
                          nomeVendedor: loja?.nome ?? '',
                          cnpjVendedor: loja?.cnpj ?? '',
                          lojaId: lojaId,
                        );

                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.backgroundColor.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.borderColor.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Row(
                            children: [
                              temFoto
                                  ? CircleAvatar(
                                      radius: 16,
                                      backgroundImage: FileImage(File(fotoResolvida)),
                                      backgroundColor:
                                          theme.borderColor.withValues(alpha: 0.2),
                                    )
                                  : CircleAvatar(
                                      radius: 16,
                                      backgroundColor:
                                          theme.borderColor.withValues(alpha: 0.2),
                                      child: Icon(Icons.person,
                                          size: 18, color: theme.textColor),
                                    ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            prog.clienteNome,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.getTextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: theme.textColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: theme.textColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: theme.borderColor.withValues(alpha: 0.5),
                                            ),
                                          ),
                                          child: Text(
                                            prog.horario,
                                            style: theme.getTextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: theme.textColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            '• ${prog.descricaoFrequenciaCurta}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.getTextStyle(
                                              fontSize: 10,
                                              color: theme.secondaryTextColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      prog.itens.map((i) => '${i.quantidade}x ${i.nomeExibicao}').join(', '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.getTextStyle(
                                        fontSize: 11,
                                        color: theme.secondaryTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Valor: ${_formatarValor(prog.valorTotal)} • ${prog.formaPagamento}'
                                      '${pedidoDoDia.numero > 0 ? " • #${pedidoDoDia.numero.toString().padLeft(4, '0')}" : ""}',
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
                                icon: Icon(Icons.edit_outlined,
                                    color: theme.textColor, size: 18),
                                tooltip: 'Editar Programação',
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  ProgramarPedidoDialog.mostrar(
                                    context,
                                    lojaId: lojaId,
                                    cliente: cliente,
                                    pedidoExistente: prog,
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.receipt_long,
                                    color: theme.textColor, size: 20),
                                tooltip: 'Ver Comanda',
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  ComandaPedidoDialog.mostrar(
                                    context,
                                    lojaId: lojaId,
                                    pedido: pedidoDoDia,
                                    cliente: cliente,
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.buttonColor,
                      foregroundColor: theme.textColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Entendido'),
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
