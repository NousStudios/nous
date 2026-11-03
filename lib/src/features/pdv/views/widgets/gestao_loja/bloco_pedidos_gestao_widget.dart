import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/cancelar_pedido_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/comanda_novo_pedido_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/pdv/views/widgets/gestao_loja_container.dart';
import 'package:nous/src/features/pdv/views/widgets/pedido_aceito_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/venda_registrada_dialog.dart';

const double _alturaListaPedidos = 380;

String _numeroFormatado(int numero) => '#${numero.toString().padLeft(4, '0')}';

String _dataHoraFormatada(DateTime data) {
  String doisDigitos(int n) => n.toString().padLeft(2, '0');
  return '${doisDigitos(data.day)}/${doisDigitos(data.month)} '
      '${doisDigitos(data.hour)}:${doisDigitos(data.minute)}';
}

String _valorFormatado(double valor) =>
    'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

class BlocoPedidosGestaoWidget extends StatefulWidget {
  final AppTheme theme;
  final String lojaId;
  final String autorCpf;
  final String autorNome;
  final String autorEmail;
  final BoxDecoration decoracaoBloco;
  final AbaPedidos abaPedidos;
  final ValueChanged<AbaPedidos> aoTrocarAbaPedidos;
  final List<PedidoLoja> pedidos;
  final List<Cliente> clientes;
  final List<ItemLoja> itensDisponiveis;
  final ValueChanged<String> aoAceitar;
  final ValueChanged<String> aoRecusar;
  final ValueChanged<String> aoConcluir;
  final ValueChanged<String>? aoCancelarPedido;
  final void Function(String pedidoId, DadosComentario dados)? aoSalvarComentario;
  final ValueChanged<String>? aoExcluirPedido;

  const BlocoPedidosGestaoWidget({
    super.key,
    required this.theme,
    required this.lojaId,
    required this.autorCpf,
    required this.autorNome,
    required this.autorEmail,
    required this.decoracaoBloco,
    required this.abaPedidos,
    required this.aoTrocarAbaPedidos,
    required this.pedidos,
    this.clientes = const [],
    this.itensDisponiveis = const [],
    required this.aoAceitar,
    required this.aoRecusar,
    required this.aoConcluir,
    this.aoCancelarPedido,
    this.aoSalvarComentario,
    this.aoExcluirPedido,
  });

  @override
  State<BlocoPedidosGestaoWidget> createState() =>
      _BlocoPedidosGestaoWidgetState();
}

class _BlocoPedidosGestaoWidgetState extends State<BlocoPedidosGestaoWidget> {
  final TextEditingController _buscaPedidosController = TextEditingController();

  @override
  void dispose() {
    _buscaPedidosController.dispose();
    super.dispose();
  }

  AppTheme get theme => widget.theme;

  Widget _abaDePedidos(String rotulo, AbaPedidos aba) {
    final selecionada = aba == widget.abaPedidos;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        if (aba != widget.abaPedidos) {
          _buscaPedidosController.clear();
        }
        widget.aoTrocarAbaPedidos(aba);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Container(
          padding: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selecionada ? theme.textColor : Colors.transparent,
                width: 1.8,
              ),
            ),
          ),
          child: Text(
            rotulo,
            style: theme.getTextStyle(
              fontSize: 13,
              fontWeight: selecionada ? FontWeight.w600 : FontWeight.normal,
              color: selecionada ? theme.textColor : theme.secondaryTextColor,
            ),
          ),
        ),
      ),
    );
  }

  void _abrirMenuDoPedido(BuildContext context, PedidoLoja pedido) {
    void agir(BuildContext dialogContext, ValueChanged<String> acao) {
      Navigator.of(dialogContext).pop();
      acao(pedido.id);
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Pedido ${_numeroFormatado(pedido.numero)}',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: Text(
            pedido.produtoNome,
            textAlign: TextAlign.center,
            style: theme.getTextStyle(fontSize: 14),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            if (pedido.status == StatusPedido.novo) ...[
              TextButton(
                onPressed: () => agir(dialogContext, widget.aoRecusar),
                child: Text(
                  'Recusar',
                  style: theme.getTextStyle(color: Colors.redAccent),
                ),
              ),
              TextButton(
                onPressed: () => agir(dialogContext, widget.aoAceitar),
                child: Text(
                  'Aceitar',
                  style: theme.getTextStyle(color: theme.textColor),
                ),
              ),
            ],
            if (pedido.status == StatusPedido.aceito) ...[
              if (widget.aoCancelarPedido != null)
                TextButton(
                  onPressed: () =>
                      agir(dialogContext, widget.aoCancelarPedido!),
                  child: Text(
                    'Cancelar',
                    style: theme.getTextStyle(color: Colors.redAccent),
                  ),
                ),
              TextButton(
                onPressed: () => agir(dialogContext, widget.aoConcluir),
                child: Text(
                  'Concluir',
                  style: theme.getTextStyle(color: theme.textColor),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _aoClicarPedido(BuildContext context, PedidoLoja pedido) {
    if (pedido.status == StatusPedido.cancelado) {
      PedidoCanceladoDetalhesDialog.mostrar(
        context,
        theme: theme,
        pedido: pedido,
      );
      return;
    }
    if (pedido.status == StatusPedido.aceito) {
      PedidoAceitoDialog.mostrar(
        context,
        theme: theme,
        pedido: pedido,
        lojaId: widget.lojaId,
        aoConcluir: () => widget.aoConcluir(pedido.id),
        aoCancelar: widget.aoCancelarPedido == null
            ? null
            : () => widget.aoCancelarPedido!(pedido.id),
      );
      return;
    }
    if (pedido.status == StatusPedido.concluido) {
      VendaRegistradaDialog.mostrar(
        context,
        theme: theme,
        lojaId: widget.lojaId,
        pedido: pedido,
        autorCpf: widget.autorCpf,
        autorNome: widget.autorNome,
        autorEmail: widget.autorEmail,
        onSalvarComentario: widget.aoSalvarComentario == null
            ? null
            : (dados) => widget.aoSalvarComentario!(pedido.id, dados),
        onExcluir: widget.aoExcluirPedido == null
            ? null
            : () => widget.aoExcluirPedido!(pedido.id),
      );
      return;
    }
    if (pedido.status == StatusPedido.novo) {
      final cliente =
          widget.clientes.where((c) => c.id == pedido.clienteId).firstOrNull;
      ComandaNovoPedidoDialog.mostrar(
        context,
        lojaId: widget.lojaId,
        pedido: pedido,
        cliente: cliente,
      ).then((acao) {
        if (acao == AcaoComandaNovoPedido.aceitar) {
          widget.aoAceitar(pedido.id);
        } else if (acao == AcaoComandaNovoPedido.recusar) {
          widget.aoRecusar(pedido.id);
        }
      });
      return;
    }
    _abrirMenuDoPedido(context, pedido);
  }

  Widget _miniaturaProduto(PedidoLoja pedido, AppTheme theme) {
    String? fotoEncontrada;
    for (final item in pedido.itens) {
      final resolvido = ImagemService.resolverCaminhoExistente(item.foto);
      if (resolvido != null) {
        fotoEncontrada = resolvido;
        break;
      }
    }

    if (fotoEncontrada == null) {
      for (final item in pedido.itens) {
        final itemLoja = widget.itensDisponiveis
            .where((i) => i.id == item.itemId)
            .firstOrNull;
        if (itemLoja != null && itemLoja.imagens.isNotEmpty) {
          final resolvido =
              ImagemService.resolverCaminhoExistente(itemLoja.imagens.first);
          if (resolvido != null) {
            fotoEncontrada = resolvido;
            break;
          }
        }
      }
    }

    if (fotoEncontrada != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(
          File(fotoEncontrada),
          width: 26,
          height: 26,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.inventory_2_outlined,
            size: 22,
            color: theme.textColor,
          ),
        ),
      );
    }

    return Icon(Icons.inventory_2_outlined, size: 22, color: theme.textColor);
  }

  Widget _miniaturaCliente(
      PedidoLoja pedido, AppTheme theme, TextStyle fonteMiuda) {
    final cliente =
        widget.clientes.where((c) => c.id == pedido.clienteId).firstOrNull;
    final fotoResolvida =
        ImagemService.resolverCaminhoExistente(cliente?.foto);
    final temFoto = fotoResolvida != null;

    return SizedBox(
      width: 48,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          temFoto
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Image.file(
                    File(fotoResolvida),
                    width: 26,
                    height: 26,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.account_circle,
                      size: 26,
                      color: theme.textColor,
                    ),
                  ),
                )
              : Icon(Icons.account_circle, size: 26, color: theme.textColor),
          TextoRolante(
            texto: pedido.clienteNome,
            textAlign: TextAlign.center,
            style: fonteMiuda,
          ),
        ],
      ),
    );
  }

  Widget _barraDoPedido(BuildContext context, PedidoLoja pedido) {
    final fonteMiuda = theme.getTextStyle(fontSize: 9);

    return _ComHoverItemPedido(
      cursor: SystemMouseCursors.click,
      aoClicar: () => _aoClicarPedido(context, pedido),
      builder: (hover) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: hover
              ? theme.borderColor.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: hover ? theme.textColor : theme.borderColor,
          ),
        ),
        child: Row(
          children: [
            _miniaturaCliente(pedido, theme, fonteMiuda),
            const SizedBox(width: 8),
            _miniaturaProduto(pedido, theme),
            const SizedBox(width: 6),
            Expanded(
              child: TextoRolante(
                texto: pedido.produtoNome,
                style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
              ),
            ),
            const SizedBox(width: 6),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Pedido ${_numeroFormatado(pedido.numero)}',
                    style: fonteMiuda),
                Text(_dataHoraFormatada(pedido.dataHora), style: fonteMiuda),
                Text(_valorFormatado(pedido.valor), style: fonteMiuda),
              ],
            ),
            if (pedido.temMensagem)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.mark_email_unread_outlined,
                  size: 20,
                  color: theme.textColor,
                ),
              ),
            if (pedido.status == StatusPedido.concluido ||
                pedido.status == StatusPedido.cancelado)
              const SizedBox(width: 8)
            else
              IconButton(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(Icons.more_vert, size: 20, color: theme.textColor),
                onPressed: () => _abrirMenuDoPedido(context, pedido),
              ),
          ],
        ),
      ),
    );
  }

  Widget _listaDePedidos(BuildContext context) {
    final statusDaAba = switch (widget.abaPedidos) {
      AbaPedidos.novos => StatusPedido.novo,
      AbaPedidos.aceitos => StatusPedido.aceito,
      AbaPedidos.concluidos => StatusPedido.concluido,
      AbaPedidos.cancelados => StatusPedido.cancelado,
    };
    final pedidosDaAba =
        widget.pedidos.where((pedido) => pedido.status == statusDaAba).toList();

    pedidosDaAba.sort((a, b) {
      final cmp = b.dataHora.compareTo(a.dataHora);
      if (cmp != 0) return cmp;
      return b.numero.compareTo(a.numero);
    });

    final termo = _buscaPedidosController.text.trim().toLowerCase();
    final aplicarBusca = (widget.abaPedidos == AbaPedidos.concluidos ||
            widget.abaPedidos == AbaPedidos.cancelados) &&
        termo.isNotEmpty;

    final pedidosFiltrados = aplicarBusca
        ? pedidosDaAba.where((p) {
            final numStr = p.numero.toString();
            final numFormatado = _numeroFormatado(p.numero).toLowerCase();
            final cliente = p.clienteNome.toLowerCase();
            final produto = p.produtoNome.toLowerCase();
            final itensStr = p.itens
                .map((i) => '${i.nomeItem} ${i.nomeCategoria ?? ''}'.toLowerCase())
                .join(' ');
            return numStr.contains(termo) ||
                numFormatado.contains(termo) ||
                cliente.contains(termo) ||
                produto.contains(termo) ||
                itensStr.contains(termo);
          }).toList()
        : pedidosDaAba;

    if (pedidosFiltrados.isEmpty) {
      if (aplicarBusca) {
        return EstadoVazioContainer(
          theme: theme,
          mensagem: 'Nenhum pedido encontrado para "$termo".',
        );
      }
      final mensagem = switch (widget.abaPedidos) {
        AbaPedidos.novos => 'Nenhum pedido novo.',
        AbaPedidos.aceitos => 'Nenhum pedido aceito.',
        AbaPedidos.concluidos => 'Nenhum pedido concluído.',
        AbaPedidos.cancelados => 'Nenhum pedido cancelado.',
      };
      return EstadoVazioContainer(theme: theme, mensagem: mensagem);
    }

    return SizedBox(
      height: _alturaListaPedidos,
      child: ListView.separated(
        itemCount: pedidosFiltrados.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) =>
            _barraDoPedido(context, pedidosFiltrados[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exibirBusca = widget.abaPedidos == AbaPedidos.concluidos ||
        widget.abaPedidos == AbaPedidos.cancelados;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: widget.decoracaoBloco,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _abaDePedidos('Novos', AbaPedidos.novos),
                const SizedBox(width: 8),
                _abaDePedidos('Aceitos', AbaPedidos.aceitos),
                const SizedBox(width: 8),
                _abaDePedidos('Concluídos', AbaPedidos.concluidos),
                const SizedBox(width: 8),
                _abaDePedidos('Cancelados', AbaPedidos.cancelados),
              ],
            ),
          ),
          if (exibirBusca) ...[
            const SizedBox(height: 12),
            Container(
              height: 38,
              decoration: BoxDecoration(
                color: theme.backgroundColor.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.borderColor.withValues(alpha: 0.5),
                ),
              ),
              child: TextField(
                controller: _buscaPedidosController,
                onChanged: (_) => setState(() {}),
                style: theme.getTextStyle(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  hintText: 'Buscar pedido, cliente ou item...',
                  hintStyle: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.secondaryTextColor,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: theme.secondaryTextColor,
                  ),
                  suffixIcon: _buscaPedidosController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 16,
                            color: theme.secondaryTextColor,
                          ),
                          onPressed: () {
                            _buscaPedidosController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _listaDePedidos(context),
        ],
      ),
    );
  }
}

class _ComHoverItemPedido extends StatefulWidget {
  final Widget Function(bool hover) builder;
  final VoidCallback? aoClicar;
  final MouseCursor cursor;

  const _ComHoverItemPedido({
    required this.builder,
    this.aoClicar,
    this.cursor = SystemMouseCursors.basic,
  });

  @override
  State<_ComHoverItemPedido> createState() => _ComHoverItemPedidoState();
}

class _ComHoverItemPedidoState extends State<_ComHoverItemPedido> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.cursor,
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
