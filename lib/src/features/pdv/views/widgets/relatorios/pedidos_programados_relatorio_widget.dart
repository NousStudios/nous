import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/comanda_pedido_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

String _valorCurto(double v) =>
    'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

class PedidosProgramadosRelatorioWidget extends StatelessWidget {
  final AppTheme theme;
  final String lojaId;
  final DateTime? dataInicial;

  const PedidosProgramadosRelatorioWidget({
    super.key,
    required this.theme,
    required this.lojaId,
    required this.dataInicial,
  });

  BoxDecoration get _decoracaoDoBloco => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

  @override
  Widget build(BuildContext context) {
    final pdv = context.watch<PdvProvider>();
    final loja = pdv.buscarPorId(lojaId);
    final diaAlvo = dataInicial ?? DateTime.now();

    final programados = (loja?.pedidosProgramados ?? [])
        .where((p) => p.coincideComData(diaAlvo))
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
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
          if (programados.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhum pedido programado para este dia.',
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: programados.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final prog = programados[index];
                  final cliente = prog.resolverCliente(
                    loja?.clientesLoja ?? const [],
                  );

                  final auth = context.read<AuthProvider>();
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
                    data: diaAlvo,
                    nomeVendedor: loja?.nome ?? '',
                    cnpjVendedor: loja?.cnpj ?? '',
                    lojaId: lojaId,
                  );

                  return _LinhaComHover(
                    aoClicar: () {
                      ComandaPedidoDialog.mostrar(
                        context,
                        lojaId: lojaId,
                        pedido: pedidoDoDia,
                        cliente: cliente,
                      );
                    },
                    builder: (hover) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: hover
                            ? theme.borderColor.withValues(alpha: 0.18)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hover ? theme.textColor : theme.borderColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          temFoto
                              ? CircleAvatar(
                                  radius: 12,
                                  backgroundImage: FileImage(File(fotoResolvida)),
                                  backgroundColor:
                                      theme.borderColor.withValues(alpha: 0.2),
                                )
                              : CircleAvatar(
                                  radius: 12,
                                  backgroundColor:
                                      theme.borderColor.withValues(alpha: 0.2),
                                  child: Icon(Icons.person,
                                      size: 14, color: theme.textColor),
                                ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        prog.clienteNome,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.getTextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: theme.textColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: theme.textColor
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: theme.borderColor
                                              .withValues(alpha: 0.5),
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
                                  prog.itens
                                      .map((i) =>
                                          '${i.quantidade}x ${i.nomeExibicao}')
                                      .join(', '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.getTextStyle(
                                    fontSize: 10,
                                    color: theme.secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _valorCurto(prog.valorTotal),
                                style: theme.getTextStyle(
                                  fontSize: 12,
                                  color: theme.textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                prog.formaPagamento,
                                style: theme.getTextStyle(
                                  fontSize: 9,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

class _LinhaComHover extends StatefulWidget {
  final Widget Function(bool hover) builder;
  final VoidCallback aoClicar;

  const _LinhaComHover({required this.builder, required this.aoClicar});

  @override
  State<_LinhaComHover> createState() => _LinhaComHoverState();
}

class _LinhaComHoverState extends State<_LinhaComHover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.aoClicar,
        child: widget.builder(_hover),
      ),
    );
  }
}
