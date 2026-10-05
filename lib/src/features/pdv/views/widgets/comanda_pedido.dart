import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

String _dataHora(DateTime d) =>
    '${_doisDigitos(d.day)}/${_doisDigitos(d.month)}/${d.year} '
    '${_doisDigitos(d.hour)}:${_doisDigitos(d.minute)}';

String _valor(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

String _numero(int n) => '#${n.toString().padLeft(4, '0')}';

class ComandaPedido extends StatelessWidget {
  final AppTheme theme;
  final PedidoLoja pedido;
  final double largura;
  final bool mostrarTitulo;
  final Cliente? cliente;
  final List<String> camposClienteComanda;

  const ComandaPedido({
    super.key,
    required this.theme,
    required this.pedido,
    this.largura = 320,
    this.mostrarTitulo = true,
    this.cliente,
    this.camposClienteComanda = const [
      'cnpj',
      'telefone',
      'endereco',
      'email',
      'redesSociais',
      'descricao',
    ],
  });

  BoxDecoration get _decoracaoDoBloco => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

  double get _subtotalDosItens {
    var soma = 0.0;
    for (final item in pedido.itens) {
      soma += item.subtotal;
    }
    return soma;
  }

  bool _deveMostrar(String chave) =>
      camposClienteComanda.contains(chave);

  Widget _linhaComanda(String esquerda, String direita,
      {bool destaque = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
          const SizedBox(width: 8),
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

  List<Widget> _linhasCliente() {
    final linhas = <Widget>[];

    linhas.add(_linhaComanda('Cliente', pedido.clienteNome));

    if (cliente == null) return linhas;

    if (_deveMostrar('cnpj') && cliente!.cnpj.trim().isNotEmpty) {
      linhas.add(_linhaComanda('CNPJ', cliente!.cnpj.trim()));
    }
    if (_deveMostrar('telefone') && cliente!.telefone.trim().isNotEmpty) {
      linhas.add(_linhaComanda('Telefone', cliente!.telefone.trim()));
    }
    if (_deveMostrar('endereco')) {
      final endereco = cliente!.endereco.trim();
      final numero = cliente!.numero.trim();
      if (endereco.isNotEmpty) {
        final completo = numero.isEmpty ? endereco : '$endereco, $numero';
        linhas.add(_linhaComanda('Endereço', completo));
      } else if (numero.isNotEmpty) {
        linhas.add(_linhaComanda('Número', numero));
      }
    }
    if (_deveMostrar('email') && cliente!.email.trim().isNotEmpty) {
      linhas.add(_linhaComanda('Email', cliente!.email.trim()));
    }
    if (_deveMostrar('redesSociais') &&
        cliente!.redesSociais.trim().isNotEmpty) {
      linhas.add(
          _linhaComanda('Redes sociais', cliente!.redesSociais.trim()));
    }
    if (_deveMostrar('descricao') && cliente!.descricao.trim().isNotEmpty) {
      linhas.add(_linhaComanda('Descrição', cliente!.descricao.trim()));
    }

    return linhas;
  }

  @override
  Widget build(BuildContext context) {
    final totalLinhas = pedido.itens.length;
    final pagamentos = pedido.todosPagamentos;

    return Center(
      child: Container(
        width: largura,
        padding: const EdgeInsets.all(12),
        decoration: _decoracaoDoBloco,
        child: Column(
          children: [
            if (mostrarTitulo)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Comanda',
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
              ),
            Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
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
                    if (pedido.nomeVendedor.isNotEmpty)
                      Center(
                        child: Text(
                          pedido.nomeVendedor,
                          textAlign: TextAlign.center,
                          style: theme.getTextStyle(
                              fontSize: 12, color: theme.textColor),
                        ),
                      ),
                    if (pedido.cnpjVendedor.isNotEmpty)
                      Center(
                        child: Text(
                          'CNPJ: ${pedido.cnpjVendedor}',
                          textAlign: TextAlign.center,
                          style: theme.getTextStyle(
                              fontSize: 11,
                              color: theme.secondaryTextColor),
                        ),
                      ),
                    const SizedBox(height: 8),
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
                            fontSize: 11,
                            color: theme.secondaryTextColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final linha in _linhasCliente()) linha,
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
                                _valor(item.subtotalBase),
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
                                  padding: const EdgeInsets.only(top: 3),
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
                    if (pagamentos.isEmpty)
                      _linhaComanda('Pagamento', '-')
                    else
                      for (final p in pagamentos)
                        _linhaComanda(p.forma, _valor(p.valor)),
                    if (pedido.troco > 0)
                      _linhaComanda('Troco', _valor(pedido.troco),
                          destaque: true),
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
}