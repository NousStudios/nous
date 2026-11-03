import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';

class BlocoSelecaoItemProgramadoWidget extends StatelessWidget {
  final AppTheme theme;
  final List<CategoriaLoja> categorias;
  final List<ItemLoja> todosItens;
  final List<GrupoComponentesLoja> grupos;
  final CategoriaLoja? categoriaSelecionada;
  final bool modoItemSolto;
  final ValueChanged<CategoriaLoja?> onCategoriaChanged;
  final ItemLoja? itemSelecionado;
  final ValueChanged<ItemLoja?> onItemChanged;
  final VarianteItem? varianteSelecionada;
  final ValueChanged<VarianteItem?> onVarianteChanged;
  final Map<String, int> acompanhamentosQuantidades;
  final void Function(String itemId, int delta) onAlterarQuantidadeAcompanhamento;
  final int quantidadeItem;
  final void Function(int delta) onAlterarQuantidadeItem;
  final TextEditingController obsItemController;
  final double subtotalItemAtual;
  final VoidCallback? onAdicionarItem;
  final String Function(double valor) valorFormatado;
  final double Function(String texto) precoComoNumero;

  const BlocoSelecaoItemProgramadoWidget({
    super.key,
    required this.theme,
    required this.categorias,
    required this.todosItens,
    required this.grupos,
    required this.categoriaSelecionada,
    required this.modoItemSolto,
    required this.onCategoriaChanged,
    required this.itemSelecionado,
    required this.onItemChanged,
    required this.varianteSelecionada,
    required this.onVarianteChanged,
    required this.acompanhamentosQuantidades,
    required this.onAlterarQuantidadeAcompanhamento,
    required this.quantidadeItem,
    required this.onAlterarQuantidadeItem,
    required this.obsItemController,
    required this.subtotalItemAtual,
    required this.onAdicionarItem,
    required this.valorFormatado,
    required this.precoComoNumero,
  });

  @override
  Widget build(BuildContext context) {
    final List<ItemLoja> itensElegiveis;
    if (modoItemSolto || categoriaSelecionada == null) {
      itensElegiveis = todosItens;
    } else {
      itensElegiveis = categoriaSelecionada!.itemIds
          .map((id) => todosItens.where((i) => i.id == id).firstOrNull)
          .whereType<ItemLoja>()
          .toList();
    }

    final List<GrupoComponentesLoja> gruposElegiveis;
    if (!modoItemSolto && categoriaSelecionada != null) {
      gruposElegiveis = categoriaSelecionada!.grupoIds
          .map((gId) => grupos.where((g) => g.id == gId).firstOrNull)
          .whereType<GrupoComponentesLoja>()
          .toList();
    } else {
      gruposElegiveis = const [];
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant_menu, size: 16, color: theme.textColor),
              const SizedBox(width: 6),
              Text(
                'Adicionar Item ao Pedido',
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<CategoriaLoja?>(
            initialValue: modoItemSolto ? null : categoriaSelecionada,
            isExpanded: true,
            dropdownColor: theme.cardBackgroundColor,
            decoration: InputDecoration(
              labelText: 'Categoria (opcional)',
              labelStyle: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.borderColor),
              ),
            ),
            items: [
              DropdownMenuItem<CategoriaLoja?>(
                value: null,
                child: Text(
                  'Item Solto / Avulso (sem categoria)',
                  style: theme.getTextStyle(
                    fontSize: 11,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ),
              ...categorias.map((cat) {
                final precoCat = precoComoNumero(cat.preco) > 0
                    ? ' (+ ${valorFormatado(precoComoNumero(cat.preco))})'
                    : '';
                return DropdownMenuItem<CategoriaLoja?>(
                  value: cat,
                  child: Text(
                    '${cat.nome}$precoCat',
                    style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            ],
            onChanged: onCategoriaChanged,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<ItemLoja?>(
            key: ValueKey('${categoriaSelecionada?.id}_$modoItemSolto'),
            initialValue: itemSelecionado,
            isExpanded: true,
            dropdownColor: theme.cardBackgroundColor,
            decoration: InputDecoration(
              labelText: modoItemSolto
                  ? 'Produto / Item Solto'
                  : (categoriaSelecionada != null
                      ? 'Item da Categoria ${categoriaSelecionada!.nome}'
                      : 'Produto / Item'),
              labelStyle: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.borderColor),
              ),
            ),
            items: itensElegiveis.map((item) {
              final precoTotalUnit = precoComoNumero(item.preco) +
                  (!modoItemSolto && categoriaSelecionada != null
                      ? precoComoNumero(categoriaSelecionada!.preco)
                      : 0.0);
              return DropdownMenuItem<ItemLoja?>(
                value: item,
                child: Text(
                  '${item.nome} (${valorFormatado(precoTotalUnit)})',
                  style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: onItemChanged,
          ),
          if (itemSelecionado != null && itemSelecionado!.variantes.isNotEmpty) ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<VarianteItem?>(
              key: ValueKey('${itemSelecionado?.id}_variante'),
              initialValue: varianteSelecionada,
              isExpanded: true,
              dropdownColor: theme.cardBackgroundColor,
              decoration: InputDecoration(
                labelText: 'Opção / Variante (opcional)',
                labelStyle: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.borderColor),
                ),
              ),
              items: [
                DropdownMenuItem<VarianteItem?>(
                  value: null,
                  child: Text(
                    'Desativado',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ),
                ...itemSelecionado!.variantes.map((v) {
                  final precoVar = v.preco.isNotEmpty
                      ? ' (${valorFormatado(precoComoNumero(v.preco))})'
                      : '';
                  return DropdownMenuItem<VarianteItem?>(
                    value: v,
                    child: Text(
                      '${v.nome}$precoVar',
                      style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
                    ),
                  );
                }),
              ],
              onChanged: onVarianteChanged,
            ),
          ],
          if (gruposElegiveis.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Acompanhamentos e Adicionais:',
              style: theme.getTextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 6),
            for (final grupo in gruposElegiveis) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.borderColor.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grupo.nome,
                      style: theme.getTextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    for (final itemId in grupo.itemIds)
                      Builder(builder: (ctx) {
                        final acomp =
                            todosItens.where((i) => i.id == itemId).firstOrNull;
                        if (acomp == null) return const SizedBox.shrink();
                        final qtdAtual = acompanhamentosQuantidades[itemId] ?? 0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  acomp.nome,
                                  style: theme.getTextStyle(fontSize: 11, color: theme.textColor),
                                ),
                              ),
                              Text(
                                valorFormatado(precoComoNumero(acomp.preco)),
                                style: theme.getTextStyle(
                                    fontSize: 10, color: theme.secondaryTextColor),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.remove, size: 14),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(2),
                                color: theme.textColor,
                                onPressed: qtdAtual > 0
                                    ? () => onAlterarQuantidadeAcompanhamento(itemId, -1)
                                    : null,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  '$qtdAtual',
                                  style: theme.getTextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textColor,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 14),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(2),
                                color: theme.textColor,
                                onPressed: () => onAlterarQuantidadeAcompanhamento(itemId, 1),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Quantidade:',
                style: theme.getTextStyle(fontSize: 12, color: theme.secondaryTextColor),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                color: theme.textColor,
                onPressed: quantidadeItem > 1
                    ? () => onAlterarQuantidadeItem(-1)
                    : null,
              ),
              Text(
                '$quantidadeItem',
                style: theme.getTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                color: theme.textColor,
                onPressed: () => onAlterarQuantidadeItem(1),
              ),
              const Spacer(),
              if (itemSelecionado != null) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Subtotal Item:',
                      style: theme.getTextStyle(fontSize: 10, color: theme.secondaryTextColor),
                    ),
                    Text(
                      valorFormatado(subtotalItemAtual),
                      style: theme.getTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: obsItemController,
            cursorColor: theme.textColor,
            style: theme.getTextStyle(fontSize: 11, color: theme.textColor),
            decoration: InputDecoration(
              labelText: 'Observação do item (ex.: sem cebola, bem passado)',
              labelStyle: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.borderColor),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.buttonColor,
                foregroundColor: theme.textColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.add_shopping_cart, size: 16),
              label: const Text('Adicionar Item ao Pedido'),
              onPressed: onAdicionarItem,
            ),
          ),
        ],
      ),
    );
  }
}
