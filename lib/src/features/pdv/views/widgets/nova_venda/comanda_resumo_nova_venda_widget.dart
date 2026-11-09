import 'package:flutter/material.dart';
import '../../../../../core/theme/theme_controller.dart';
import '../../../models/cliente.dart';
import '../../../models/item_loja.dart';
import '../../../models/modelos_nova_venda.dart';

/// Widget que renderiza o cupom/comanda visual da Nova Venda com o estilo de comanda de papel.
class ComandaResumoNovaVendaWidget extends StatelessWidget {
  final AppTheme theme;
  final ScrollController scrollController;
  final double larguraComanda;
  final String nomeVendedor;
  final String cnpjVendedor;
  final int proximoNumero;
  final String dataHoraFormatada;
  final String nomeClienteDigitado;
  final Cliente? clienteSelecionado;
  final bool Function(String) deveMostrarCampoCliente;
  final List<LinhaCarrinho> carrinho;
  final String Function(LinhaCarrinho) nomeExibicaoLinha;
  final double Function(LinhaCarrinho) subtotalBaseLinha;
  final ItemLoja? Function(String) buscarItem;
  final double Function(String) precoComoNumero;
  final String Function(double) valorComVirgula;
  final double subtotalDosItens;
  final double frete;
  final double desconto;
  final String rotuloDesconto;
  final double acrescimo;
  final String rotuloAcrescimo;
  final double total;
  final List<LinhaPagamento> pagamentos;
  final double troco;
  final BoxDecoration decoracaoDoBloco;
  final Widget Function(String) tituloDoBloco;
  final bool expandirAltura;

  const ComandaResumoNovaVendaWidget({
    super.key,
    required this.theme,
    required this.scrollController,
    required this.larguraComanda,
    required this.nomeVendedor,
    required this.cnpjVendedor,
    required this.proximoNumero,
    required this.dataHoraFormatada,
    required this.nomeClienteDigitado,
    required this.clienteSelecionado,
    required this.deveMostrarCampoCliente,
    required this.carrinho,
    required this.nomeExibicaoLinha,
    required this.subtotalBaseLinha,
    required this.buscarItem,
    required this.precoComoNumero,
    required this.valorComVirgula,
    required this.subtotalDosItens,
    required this.frete,
    required this.desconto,
    required this.rotuloDesconto,
    required this.acrescimo,
    required this.rotuloAcrescimo,
    required this.total,
    required this.pagamentos,
    required this.troco,
    required this.decoracaoDoBloco,
    required this.tituloDoBloco,
    this.expandirAltura = false,
  });

  Widget _linhaComanda(String esquerda, String direita, {bool destaque = false}) {
    final ehPreco = direita.trim().startsWith('R\$') ||
        direita.trim().startsWith('-R\$') ||
        direita.trim() == '-';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ehPreco)
            Expanded(
              child: Text(
                esquerda,
                softWrap: true,
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: destaque ? theme.textColor : theme.secondaryTextColor,
                  fontWeight: destaque ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            )
          else
            Text(
              esquerda,
              style: theme.getTextStyle(
                fontSize: 12,
                color: destaque ? theme.textColor : theme.secondaryTextColor,
                fontWeight: destaque ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          const SizedBox(width: 8),
          if (ehPreco)
            Text(
              direita,
              textAlign: TextAlign.right,
              softWrap: false,
              style: theme.getTextStyle(
                fontSize: 12,
                color: destaque ? theme.textColor : theme.secondaryTextColor,
                fontWeight: destaque ? FontWeight.bold : FontWeight.normal,
              ),
            )
          else
            Expanded(
              child: Text(
                direita,
                textAlign: TextAlign.right,
                softWrap: true,
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: destaque ? theme.textColor : theme.secondaryTextColor,
                  fontWeight: destaque ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalLinhas = carrinho.length;

    final papelComanda = Center(
      child: Container(
        width: larguraComanda,
        constraints: const BoxConstraints(maxWidth: 340, minHeight: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                          nomeVendedor.isEmpty
                              ? 'Nome do vendedor'
                              : nomeVendedor,
                          textAlign: TextAlign.center,
                          style: theme.getTextStyle(
                              fontSize: 12, color: theme.textColor),
                        ),
                      ),
                      Center(
                        child: Text(
                          'CNPJ: $cnpjVendedor',
                          textAlign: TextAlign.center,
                          style: theme.getTextStyle(
                              fontSize: 11,
                              color: theme.secondaryTextColor),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Pedido #${proximoNumero.toString().padLeft(4, '0')}',
                          textAlign: TextAlign.center,
                          style: theme.getTextStyle(
                              fontSize: 12, color: theme.textColor),
                        ),
                      ),
                      Center(
                        child: Text(
                          'Data: $dataHoraFormatada',
                          textAlign: TextAlign.center,
                          style: theme.getTextStyle(
                              fontSize: 11,
                              color: theme.secondaryTextColor),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _linhaComanda(
                        'Cliente',
                        nomeClienteDigitado.trim().isEmpty
                            ? '-'
                            : nomeClienteDigitado.trim(),
                      ),
                      if (clienteSelecionado != null) ...[
                        if (deveMostrarCampoCliente('cnpj') &&
                            clienteSelecionado!.cnpj.trim().isNotEmpty)
                          _linhaComanda(
                              'CNPJ', clienteSelecionado!.cnpj.trim()),
                        if (deveMostrarCampoCliente('telefone') &&
                            clienteSelecionado!.telefone.trim().isNotEmpty)
                          _linhaComanda('Telefone',
                              clienteSelecionado!.telefone.trim()),
                        if (deveMostrarCampoCliente('endereco')) ...[
                          if (clienteSelecionado!.endereco.trim().isNotEmpty)
                            _linhaComanda(
                              'Endereço',
                              clienteSelecionado!.numero.trim().isEmpty
                                  ? clienteSelecionado!.endereco.trim()
                                  : '${clienteSelecionado!.endereco.trim()}, '
                                      '${clienteSelecionado!.numero.trim()}',
                            )
                          else if (clienteSelecionado!.numero.trim().isNotEmpty)
                            _linhaComanda(
                              'Número',
                              clienteSelecionado!.numero.trim(),
                            ),
                        ],
                        if (deveMostrarCampoCliente('email') &&
                            clienteSelecionado!.email.trim().isNotEmpty)
                          _linhaComanda(
                              'Email', clienteSelecionado!.email.trim()),
                        if (deveMostrarCampoCliente('redesSociais') &&
                            clienteSelecionado!.redesSociais.trim().isNotEmpty)
                          _linhaComanda('Redes sociais',
                              clienteSelecionado!.redesSociais.trim()),
                        if (deveMostrarCampoCliente('descricao') &&
                            clienteSelecionado!.descricao.trim().isNotEmpty)
                          _linhaComanda('Descrição',
                              clienteSelecionado!.descricao.trim()),
                      ],
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
                            'Nenhum item adicionado.',
                            textAlign: TextAlign.center,
                            style: theme.getTextStyle(
                                fontSize: 11,
                                color: theme.secondaryTextColor),
                          ),
                        )
                      else
                        for (final linha in carrinho)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _linhaComanda(
                                  '${linha.quantidade}x ${nomeExibicaoLinha(linha)}',
                                  'R\$ ${valorComVirgula(subtotalBaseLinha(linha))}',
                                ),
                                for (final entrada
                                    in linha.acompanhamentosPorItemId.entries)
                                  Builder(builder: (context) {
                                    final item = buscarItem(entrada.key);
                                    if (item == null || entrada.value <= 0) {
                                      return const SizedBox.shrink();
                                    }
                                    final subtotalAcomp =
                                        precoComoNumero(item.preco) *
                                            entrada.value *
                                            linha.quantidade;
                                    return _linhaComanda(
                                      '   ${entrada.value}x ${item.nome} por unidade',
                                      'R\$ ${valorComVirgula(subtotalAcomp)}',
                                    );
                                  }),
                                if (linha.observacaoController.text
                                    .trim()
                                    .isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(
                                      'Obs: ${linha.observacaoController.text.trim()}',
                                      style: theme.getTextStyle(
                                          fontSize: 11,
                                          color: theme.secondaryTextColor),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      const SizedBox(height: 8),
                      Divider(
                          color: theme.borderColor.withValues(alpha: 0.6)),
                      _linhaComanda('Subtotal',
                          'R\$ ${valorComVirgula(subtotalDosItens)}'),
                      _linhaComanda(
                          'Frete', 'R\$ ${valorComVirgula(frete)}'),
                      if (desconto > 0)
                        _linhaComanda(rotuloDesconto,
                            '-R\$ ${valorComVirgula(desconto)}'),
                      if (acrescimo > 0)
                        _linhaComanda(rotuloAcrescimo,
                            'R\$ ${valorComVirgula(acrescimo)}'),
                      _linhaComanda(
                          'TOTAL', 'R\$ ${valorComVirgula(total)}',
                          destaque: true),
                      const SizedBox(height: 4),
                      if (pagamentos.isEmpty)
                        _linhaComanda('Pagamento', '-')
                      else
                        for (final p in pagamentos)
                          _linhaComanda(
                            p.forma,
                            'R\$ ${valorComVirgula(precoComoNumero(p.controller.text))}',
                          ),
                      if (troco > 0)
                        _linhaComanda('Troco',
                            'R\$ ${valorComVirgula(troco)}',
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
              );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: decoracaoDoBloco,
      child: Column(
        children: [
          tituloDoBloco('Comanda'),
          if (expandirAltura)
            papelComanda
          else
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 160, maxHeight: 520),
              child: SingleChildScrollView(
                controller: scrollController,
                child: papelComanda,
              ),
            ),
        ],
      ),
    );
  }
}
