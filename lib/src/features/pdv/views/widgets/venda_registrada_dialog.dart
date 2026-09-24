import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

String _dataHora(DateTime d) =>
    '${_doisDigitos(d.day)}/${_doisDigitos(d.month)}/${d.year} '
    '${_doisDigitos(d.hour)}:${_doisDigitos(d.minute)}';

String _valor(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

String _numero(int n) => '#${n.toString().padLeft(4, '0')}';

double _paddingAdaptavel(BuildContext context) {
  final largura = MediaQuery.sizeOf(context).width;
  if (largura < 380) return 12;
  if (largura < 500) return 18;
  return 24;
}

class VendaRegistradaDialog {
  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required PedidoLoja pedido,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: theme.cardBackgroundColor,
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: _VendaConteudo(theme: theme, pedido: pedido),
          ),
        );
      },
    );
  }
}

class _VendaConteudo extends StatelessWidget {
  final AppTheme theme;
  final PedidoLoja pedido;

  const _VendaConteudo({required this.theme, required this.pedido});

  BoxDecoration get _decoracaoDoBloco => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

  Widget _tituloDoBloco(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: theme.getTextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: theme.textColor,
        ),
      ),
    );
  }

  Widget _linha(BuildContext context, String rotulo, String valor) {
    final padding = _paddingAdaptavel(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo, style: theme.getTextStyle(fontSize: 12)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
            ),
          ),
        ],
      ),
    );
  }

  String get _situacao {
    switch (pedido.status) {
      case StatusPedido.novo:
        return 'Novo';
      case StatusPedido.aceito:
        return 'Aceito';
      case StatusPedido.concluido:
        return 'Concluído';
    }
  }

  Widget _blocoResumo(BuildContext context) {
    final aPrazo = pedido.formaPagamento == 'À Prazo';
    final pago = pedido.quitado ? pedido.valor : pedido.valorPago;
    final restante = pedido.quitado ? 0.0 : pedido.valorRestante;

    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: _decoracaoDoBloco,
        child: Column(
          children: [
            _tituloDoBloco('Resumo'),
            _linha(context, 'Pedido', _numero(pedido.numero)),
            _linha(context, 'Data', _dataHora(pedido.dataHora)),
            _linha(context, 'Cliente', pedido.clienteNome),
            _linha(context, 'Produtos', pedido.produtoNome),
            _linha(
              context,
              'Forma de pagamento',
              pedido.formaPagamento.isEmpty
                  ? 'Não informada'
                  : pedido.formaPagamento,
            ),
            _linha(context, 'Situação', _situacao),
            if (pedido.frete > 0)
              _linha(context, 'Frete', _valor(pedido.frete)),
            if (pedido.desconto > 0)
              _linha(context, 'Desconto', '-${_valor(pedido.desconto)}'),
            if (pedido.acrescimo > 0)
              _linha(context, 'Acréscimo', _valor(pedido.acrescimo)),
            _linha(context, 'Valor total', _valor(pedido.valor)),
            if (aPrazo) ...[
              _linha(context, 'Pagamento',
                  pedido.quitado ? 'Quitado' : 'Em aberto'),
              _linha(context, 'Já pago', _valor(pago)),
              _linha(context, 'Restante', _valor(restante)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _blocoItens(BuildContext context) {
    final padding = _paddingAdaptavel(context);
    if (pedido.itens.isEmpty) {
      return Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: _decoracaoDoBloco,
          child: Column(
            children: [
              _tituloDoBloco('Itens'),
              EstadoVazioContainer(
                theme: theme,
                mensagem: 'Sem itens detalhados nesta venda.',
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: _decoracaoDoBloco,
        child: Column(
          children: [
            _tituloDoBloco('Itens'),
            for (final item in pedido.itens) ...[
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: padding, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.quantidade}x ${item.nomeExibicao}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.getTextStyle(
                              fontSize: 12,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                        Text(
                          _valor(item.subtotal),
                          style: theme.getTextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    if (item.acompanhamentos.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: Text(
                          item.acompanhamentos
                              .map((a) =>
                                  '${a.quantidadePorUnidade}x ${a.nomeItem} por unidade')
                              .join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 10,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ),
                    if (item.observacao.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: Text(
                          'Obs: ${item.observacao.trim()}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 10,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double get _subtotalDosItens {
    var soma = 0.0;
    for (final item in pedido.itens) {
      soma += item.subtotal;
    }
    return soma;
  }

  Widget _linhaComanda(String esquerda, String direita, {bool destaque = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              esquerda,
              style: theme.getTextStyle(
                fontSize: 12,
                color: destaque ? theme.textColor : theme.secondaryTextColor,
                fontWeight: destaque ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            direita,
            style: theme.getTextStyle(
              fontSize: 12,
              color: destaque ? theme.textColor : theme.secondaryTextColor,
              fontWeight: destaque ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _blocoComanda() {
    final totalLinhas = pedido.itens.length;
    final isDinheiro = pedido.formaPagamento == 'Dinheiro';

    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: _decoracaoDoBloco,
        child: Column(
          children: [
            _tituloDoBloco('Comanda'),
            Center(
              child: Container(
                width: 280,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: theme.backgroundColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Text(
                        'Pedido ${_numero(pedido.numero)}',
                        textAlign: TextAlign.center,
                        style: theme.getTextStyle(
                            fontSize: 12, color: theme.textColor),
                      ),
                    ),
                    Center(
                      child: Text(
                        'Data: ${_dataHora(pedido.dataHora)}',
                        textAlign: TextAlign.center,
                        style: theme.getTextStyle(
                            fontSize: 11, color: theme.secondaryTextColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _linhaComanda('Cliente', pedido.clienteNome),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'ITENS',
                        style: theme.getTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.textColor),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (totalLinhas == 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Nenhum item registrado.',
                          textAlign: TextAlign.center,
                          style: theme.getTextStyle(
                              fontSize: 11,
                              color: theme.secondaryTextColor),
                        ),
                      )
                    else
                      for (final item in pedido.itens)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _linhaComanda(
                                '${item.quantidade}x ${item.nomeExibicao}',
                                _valor(item.subtotal),
                              ),
                              for (final a in item.acompanhamentos)
                                _linhaComanda(
                                  '   ${a.quantidadePorUnidade}x ${a.nomeItem} por unidade',
                                  _valor(a.precoItem *
                                      a.quantidadePorUnidade *
                                      item.quantidade),
                                ),
                              if (item.observacao.trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    'Obs: ${item.observacao.trim()}',
                                    style: theme.getTextStyle(
                                        fontSize: 11,
                                        color: theme.secondaryTextColor),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    const SizedBox(height: 8),
                    Divider(color: theme.borderColor.withValues(alpha: 0.6)),
                    _linhaComanda('Subtotal', _valor(_subtotalDosItens)),
                    _linhaComanda('Frete', _valor(pedido.frete)),
                    if (pedido.desconto > 0)
                      _linhaComanda('Desconto', '-${_valor(pedido.desconto)}'),
                    if (pedido.acrescimo > 0)
                      _linhaComanda('Acréscimo', _valor(pedido.acrescimo)),
                    _linhaComanda('TOTAL', _valor(pedido.valor),
                        destaque: true),
                    const SizedBox(height: 4),
                    _linhaComanda(
                      'Pagamento',
                      pedido.formaPagamento.isEmpty
                          ? '-'
                          : pedido.formaPagamento,
                    ),
                    if (isDinheiro) ...[
                      _linhaComanda('Valor recebido', '-'),
                      _linhaComanda('Troco', '-', destaque: true),
                    ],
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'linktr.ee/nous72',
                        textAlign: TextAlign.center,
                        style: theme.getTextStyle(
                            fontSize: 11,
                            color: theme.secondaryTextColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: theme.textColor),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  'Venda Registrada',
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                _blocoResumo(context),
                const SizedBox(height: 12),
                _blocoItens(context),
                const SizedBox(height: 12),
                _blocoComanda(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BarraVenda extends StatefulWidget {
  final AppTheme theme;
  final PedidoLoja pedido;
  final bool mostrarCliente;

  const BarraVenda({
    super.key,
    required this.theme,
    required this.pedido,
    this.mostrarCliente = false,
  });

  @override
  State<BarraVenda> createState() => _BarraVendaState();
}

class _BarraVendaState extends State<BarraVenda> {
  bool _hover = false;

  AppTheme get theme => widget.theme;

  String get _detalhe {
    final pedido = widget.pedido;
    return [
      if (widget.mostrarCliente) pedido.clienteNome,
      _dataHora(pedido.dataHora),
      if (pedido.formaPagamento.isNotEmpty) pedido.formaPagamento,
      if (pedido.aPrazoEmAberto) 'em aberto',
      if (pedido.aPrazoEmAberto && pedido.valorPago > 0)
        'pago ${_valor(pedido.valorPago)}',
      if (pedido.formaPagamento == 'À Prazo' && pedido.quitado) 'quitado',
    ].join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final pedido = widget.pedido;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => VendaRegistradaDialog.mostrar(
          context,
          theme: theme,
          pedido: pedido,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _hover
                ? theme.borderColor.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _hover ? theme.textColor : theme.borderColor,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_numero(pedido.numero)}  ${pedido.produtoNome}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.textColor,
                      ),
                    ),
                    Text(
                      _detalhe,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.getTextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(_valor(pedido.valor), style: theme.getTextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}