import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

String _dataHoraCurta(DateTime d) =>
    '${_doisDigitos(d.day)}/${_doisDigitos(d.month)}/${d.year} '
    '${_doisDigitos(d.hour)}:${_doisDigitos(d.minute)}';

String _valorCurto(double v) =>
    'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

String _numeroCurto(int n) => '#${n.toString().padLeft(4, '0')}';

class PendenciaClienteAgrupada {
  final String clienteNome;
  final String? clienteId;
  final double totalDevido;
  final PedidoLoja ultimoPedido;
  final int totalPedidos;
  final List<PedidoLoja> pedidos;

  const PendenciaClienteAgrupada({
    required this.clienteNome,
    required this.clienteId,
    required this.totalDevido,
    required this.ultimoPedido,
    required this.totalPedidos,
    required this.pedidos,
  });

  static List<PendenciaClienteAgrupada> agrupar(List<PedidoLoja> pedidos) {
    final abertos = pedidos.where((p) => p.aPrazoEmAberto).toList();
    final grupos = <String, List<PedidoLoja>>{};
    for (final p in abertos) {
      final chave = (p.clienteId != null && p.clienteId!.trim().isNotEmpty)
          ? 'id:${p.clienteId!.trim()}'
          : 'nome:${p.clienteNome.trim().toLowerCase()}';
      grupos.putIfAbsent(chave, () => []).add(p);
    }

    final lista = <PendenciaClienteAgrupada>[];
    for (final grupo in grupos.values) {
      grupo.sort((a, b) => b.dataHora.compareTo(a.dataHora));
      final ultimo = grupo.first;
      final totalDevido =
          grupo.fold<double>(0.0, (s, p) => s + p.valorRestante);
      lista.add(PendenciaClienteAgrupada(
        clienteNome: ultimo.clienteNome,
        clienteId: ultimo.clienteId,
        totalDevido: totalDevido,
        ultimoPedido: ultimo,
        totalPedidos: grupo.length,
        pedidos: grupo,
      ));
    }
    lista.sort((a, b) =>
        b.ultimoPedido.dataHora.compareTo(a.ultimoPedido.dataHora));
    return lista;
  }
}

class PendenciasRelatorioWidget extends StatelessWidget {
  final AppTheme theme;
  final String lojaId;
  final List<PendenciaClienteAgrupada> pendencias;
  final ValueChanged<PendenciaClienteAgrupada> onClicarPendencia;

  const PendenciasRelatorioWidget({
    super.key,
    required this.theme,
    required this.lojaId,
    required this.pendencias,
    required this.onClicarPendencia,
  });

  BoxDecoration get _decoracaoDoBloco => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

  Widget _cardPendenciaCliente(
      BuildContext context, PendenciaClienteAgrupada item) {
    final pdv = context.read<PdvProvider>();
    final auth = context.read<AuthProvider>();
    final loja = pdv.buscarPorId(lojaId);
    Cliente? cliente;
    if (loja != null) {
      if (item.clienteId != null && item.clienteId!.isNotEmpty) {
        for (final c in loja.clientesLoja) {
          if (c.id == item.clienteId) {
            cliente = c;
            break;
          }
        }
      }
      if (cliente == null) {
        final nomeLimpo = item.clienteNome.trim().toLowerCase();
        for (final c in loja.clientesLoja) {
          if (c.nome.trim().toLowerCase() == nomeLimpo) {
            cliente = c;
            break;
          }
        }
      }
    }

    String foto = '';
    if (cliente != null) {
      foto = cliente.foto.trim();
      if (foto.isEmpty && cliente.cnpj.isNotEmpty) {
        foto = auth.buscarFotoPorCpf(cliente.cnpj);
        if (foto.isEmpty) {
          foto = pdv.buscarFotoClientePorCpf(cliente.cnpj) ?? '';
        }
      }
    }
    final fotoResolvida = ImagemService.resolverCaminhoExistente(foto);
    final temFoto = fotoResolvida != null;

    final textoSubtitulo = item.totalPedidos > 1
        ? 'Último pedido: ${_numeroCurto(item.ultimoPedido.numero)} • ${_dataHoraCurta(item.ultimoPedido.dataHora)}'
        : 'Pedido ${_numeroCurto(item.ultimoPedido.numero)} • ${_dataHoraCurta(item.ultimoPedido.dataHora)}';

    return _LinhaComHover(
      aoClicar: () => onClicarPendencia(item),
      builder: (hover) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    backgroundColor: theme.borderColor.withValues(alpha: 0.2),
                  )
                : CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.borderColor.withValues(alpha: 0.2),
                    child: Icon(Icons.person, size: 14, color: theme.textColor),
                  ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: TextoRolante(
                          texto: item.clienteNome,
                          textAlign: TextAlign.start,
                          style: theme.getTextStyle(
                            fontSize: 12,
                            color: theme.textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (item.totalPedidos > 1) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: theme.borderColor.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${item.totalPedidos} pedidos',
                            style: theme.getTextStyle(
                              fontSize: 9,
                              color: theme.secondaryTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  TextoRolante(
                    texto: textoSubtitulo,
                    textAlign: TextAlign.start,
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
                  _valorCurto(item.totalDevido),
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (item.totalPedidos > 1)
                  Text(
                    'total devido',
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Pendências',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
          ),
          if (pendencias.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhuma venda a prazo em aberto.',
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: pendencias.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    _cardPendenciaCliente(context, pendencias[index]),
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
