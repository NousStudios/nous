import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

/// Painel lateral da Comanda Ampliada no Modo Balcão do PDV.
///
/// Exibe a lista viva de itens escaneados, adicionais, observações,
/// seletor rápido de formas de pagamento, troco calculado e botão de conclusão.
class ComandaBalcaoWidget extends StatelessWidget {
  final AppTheme theme;
  final List<ItemVendido> carrinho;
  final String formaPagamentoSelecionada;
  final List<String> formasDePagamento;
  final TextEditingController valorRecebidoController;
  final double subtotal;
  final double total;
  final double troco;
  final double descontoValor;
  final double acrescimoValor;
  final double freteValor;
  final String? aviso;
  final List<GrupoComponentesLoja> Function(ItemVendido item) obterGruposDoItemVendido;
  final void Function(int indice, int variacao) onAlterarQuantidade;
  final void Function(int indice) onRemoverItem;
  final void Function(int indice) onAbrirComponentes;
  final void Function(int indice) onEditarObservacao;
  final void Function(String forma) onSelecionarForma;
  final VoidCallback onFinalizarVenda;

  const ComandaBalcaoWidget({
    super.key,
    required this.theme,
    required this.carrinho,
    required this.formaPagamentoSelecionada,
    required this.formasDePagamento,
    required this.valorRecebidoController,
    required this.subtotal,
    required this.total,
    required this.troco,
    required this.descontoValor,
    required this.acrescimoValor,
    required this.freteValor,
    required this.aviso,
    required this.obterGruposDoItemVendido,
    required this.onAlterarQuantidade,
    required this.onRemoverItem,
    required this.onAbrirComponentes,
    required this.onEditarObservacao,
    required this.onSelecionarForma,
    required this.onFinalizarVenda,
  });

  String _valorFormatado(double valor) =>
      valor.toStringAsFixed(2).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cabeçalho da Comanda do Balcão
        Row(
          children: [
            Icon(Icons.receipt_long_rounded, size: 24, color: theme.textColor),
            const SizedBox(width: 10),
            Text(
              'COMANDA DA COMPRA',
              style: theme.getTextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ).copyWith(letterSpacing: 0.8),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.borderColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${carrinho.length} ${carrinho.length == 1 ? "item" : "itens"}',
                style: theme.getTextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Divider(height: 1, color: theme.borderColor.withValues(alpha: 0.4)),
        const SizedBox(height: 8),

        // Lista de Itens Ampliada (Visível com clareza para o Cliente no Balcão)
        Expanded(
          child: carrinho.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: theme.secondaryTextColor.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'CAIXA LIVRE',
                        style: theme.getTextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Passe o primeiro produto no leitor de código de barras.',
                        textAlign: TextAlign.center,
                        style: theme.getTextStyle(
                          fontSize: 13,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: carrinho.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 12,
                    color: theme.borderColor.withValues(alpha: 0.2),
                  ),
                  itemBuilder: (context, index) {
                    final item = carrinho[index];
                    final itemTotal = item.subtotal;
                    final fotoResolvida =
                        ImagemService.resolverCaminhoExistente(item.foto);
                    final temFoto = fotoResolvida != null;

                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.backgroundColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: theme.borderColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              image: temFoto
                                  ? DecorationImage(
                                      image: FileImage(File(fotoResolvida)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: !temFoto
                                ? Icon(Icons.shopping_bag_outlined,
                                    size: 20, color: theme.secondaryTextColor)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.nomeExibicao,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.getTextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.quantidade}x R\$ ${_valorFormatado(item.precoUnitario)}',
                                  style: theme.getTextStyle(
                                    fontSize: 12,
                                    color: theme.secondaryTextColor,
                                  ),
                                ),
                                if (item.acompanhamentos.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    item.acompanhamentos
                                        .map((a) =>
                                            '${a.quantidadePorUnidade}x ${a.nomeItem} (+R\$ ${_valorFormatado(a.precoItem * a.quantidadePorUnidade)})')
                                        .join(' • '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.getTextStyle(
                                      fontSize: 10,
                                      color: theme.secondaryTextColor,
                                    ),
                                  ),
                                ],
                                if (item.observacao.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    'Obs: ${item.observacao}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.getTextStyle(
                                      fontSize: 11,
                                      color: theme.textColor
                                          .withValues(alpha: 0.85),
                                    ).copyWith(fontStyle: FontStyle.italic),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    if (obterGruposDoItemVendido(item).isNotEmpty)
                                      InkWell(
                                        onTap: () => onAbrirComponentes(index),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: item.acompanhamentos.isNotEmpty
                                                ? theme.textColor
                                                    .withValues(alpha: 0.12)
                                                : theme.borderColor
                                                    .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: item
                                                      .acompanhamentos.isNotEmpty
                                                  ? theme.textColor
                                                  : theme.borderColor
                                                      .withValues(alpha: 0.4),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.tune,
                                                  size: 11,
                                                  color: theme.textColor),
                                              const SizedBox(width: 4),
                                              Text(
                                                item.acompanhamentos.isNotEmpty
                                                    ? 'Componentes (${item.acompanhamentos.length})'
                                                    : '+ Componentes',
                                                style: theme.getTextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w600,
                                                  color: theme.textColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    InkWell(
                                      onTap: () => onEditarObservacao(index),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: item.observacao.isNotEmpty
                                              ? theme.textColor
                                                  .withValues(alpha: 0.12)
                                              : theme.borderColor
                                                  .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: item.observacao.isNotEmpty
                                                ? theme.textColor
                                                : theme.borderColor
                                                    .withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.edit_note,
                                                size: 12,
                                                color: theme.textColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              item.observacao.isNotEmpty
                                                  ? 'Obs adicionada'
                                                  : '+ Observação',
                                              style: theme.getTextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w600,
                                                color: theme.textColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Preço Total do Item e Botões de Quantidade
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'R\$ ${_valorFormatado(itemTotal)}',
                                style: theme.getTextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                        Icons.remove_circle_outline,
                                        size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    color: theme.secondaryTextColor,
                                    onPressed: () =>
                                        onAlterarQuantidade(index, -1),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text(
                                      '${item.quantidade}',
                                      style: theme.getTextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: theme.textColor,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline,
                                        size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    color: theme.secondaryTextColor,
                                    onPressed: () =>
                                        onAlterarQuantidade(index, 1),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 20, color: Colors.redAccent),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => onRemoverItem(index),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 12),
        Divider(height: 1, color: theme.borderColor.withValues(alpha: 0.4)),
        const SizedBox(height: 12),

        // ═══ SELETOR DE FORMA DE PAGAMENTO EM GRADE COMPACTA ═══
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final forma in formasDePagamento)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => onSelecionarForma(forma),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: formaPagamentoSelecionada == forma
                            ? (theme.buttonColor != Colors.transparent
                                ? theme.buttonColor.withValues(alpha: 0.8)
                                : theme.borderColor.withValues(alpha: 0.35))
                            : theme.backgroundColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: formaPagamentoSelecionada == forma
                              ? theme.textColor
                              : theme.borderColor.withValues(alpha: 0.4),
                          width: formaPagamentoSelecionada == forma ? 1.4 : 1.0,
                        ),
                      ),
                      child: Text(
                        forma,
                        style: theme.getTextStyle(
                          fontSize: 11,
                          fontWeight: formaPagamentoSelecionada == forma
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: formaPagamentoSelecionada == forma
                              ? theme.textColor
                              : theme.secondaryTextColor,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Se forma for dinheiro: Campo de valor recebido e Troco Gigante
        if (formaPagamentoSelecionada == 'Dinheiro') ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.backgroundColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: valorRecebidoController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: theme.getTextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                    decoration: InputDecoration(
                      labelText: 'VALOR RECEBIDO (R\$)',
                      labelStyle: theme.getTextStyle(
                        fontSize: 11,
                        color: theme.secondaryTextColor,
                      ),
                      prefixText: 'R\$ ',
                      prefixStyle: theme.getTextStyle(
                        fontSize: 16,
                        color: theme.textColor,
                      ),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.borderColor),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.borderColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'TROCO DO CLIENTE',
                        style: theme.getTextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                      Text(
                        'R\$ ${_valorFormatado(troco)}',
                        style: theme.getTextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Bloco do TOTAL GERAL em Destaque Gigante
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.backgroundColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.textColor.withValues(alpha: 0.7),
              width: 1.6,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL A PAGAR',
                    style: theme.getTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.secondaryTextColor,
                    ).copyWith(letterSpacing: 1.0),
                  ),
                  if (descontoValor > 0 || acrescimoValor > 0 || freteValor > 0)
                    Text(
                      'Subtotal: R\$ ${_valorFormatado(subtotal)}',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                ],
              ),
              Text(
                'R\$ ${_valorFormatado(total)}',
                style: theme.getTextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
        ),
        if (aviso != null) ...[
          const SizedBox(height: 8),
          Text(
            aviso!,
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 12,
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
        const SizedBox(height: 12),

        // Botão Gigante de Finalizar Venda
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.buttonColor != Colors.transparent
                ? theme.buttonColor
                : theme.borderColor.withValues(alpha: 0.35),
            foregroundColor: theme.textColor,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: theme.textColor, width: 1.5),
            ),
            elevation: 2,
          ),
          onPressed: onFinalizarVenda,
          icon: const Icon(Icons.check_circle_outline, size: 24),
          label: Text(
            'FINALIZAR VENDA',
            style: theme.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ).copyWith(letterSpacing: 0.8),
          ),
        ),
      ],
    );
  }
}
