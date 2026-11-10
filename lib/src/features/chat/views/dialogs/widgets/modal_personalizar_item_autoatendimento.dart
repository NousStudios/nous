import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';

/// Modal interativo de autoatendimento para personalizar variantes,
/// grupos de componentes/acompanhamentos, quantidade e observações de um item ou categoria.
class ModalPersonalizarItemAutoatendimento {
  static double _parsePreco(String p) =>
      double.tryParse(p.replaceAll(',', '.')) ?? 0.0;

  static String _formatarPreco(double v) => 'R\$ ${v.toStringAsFixed(2)}';

  static Future<void> mostrar({
    required BuildContext context,
    required AppTheme theme,
    required ItemLoja? item,
    required CategoriaLoja? categoria,
    required List<GrupoComponentesLoja> gruposDisponiveis,
    required List<ItemLoja> todosItens,
    required void Function(ItemVendido itemPersonalizado) onConfirmar,
  }) async {
    final gruposIds = categoria?.grupoIds ?? const <String>[];
    final gruposDoItem = gruposDisponiveis
        .where((g) => gruposIds.contains(g.id))
        .toList();

    final variantes = item?.variantes ?? const <VarianteItem>[];
    String? varianteSelecionada = variantes.isNotEmpty
        ? variantes.first.nome
        : null;

    final precoCategoria = categoria != null ? _parsePreco(categoria.preco) : 0.0;
    final precoItemPadrao = item != null ? _parsePreco(item.preco) : 0.0;

    final Map<String, int> selecionados = {};
    final obsItemCtrl = TextEditingController();
    int qtd = 1;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            double precoItemEfetivo = precoItemPadrao;
            if (varianteSelecionada != null && variantes.isNotEmpty) {
              final vObj = variantes
                  .where((v) => v.nome == varianteSelecionada)
                  .firstOrNull;
              if (vObj != null && _parsePreco(vObj.preco) > 0) {
                precoItemEfetivo = _parsePreco(vObj.preco);
              }
            }

            final precoBaseUnitario = precoItemEfetivo + precoCategoria;
            double somaAcompanhamentos = 0.0;
            for (final entry in selecionados.entries) {
              if (entry.value > 0) {
                final it = todosItens
                    .where((x) => x.id == entry.key)
                    .firstOrNull;
                if (it != null) {
                  somaAcompanhamentos += _parsePreco(it.preco) * entry.value;
                }
              }
            }
            final subtotalItem =
                (precoBaseUnitario + somaAcompanhamentos) * qtd;

            final tituloModal = item != null
                ? (categoria != null
                      ? '${categoria.nome} • ${item.nome}'
                      : item.nome)
                : (categoria?.nome ?? 'Item');

            return Dialog(
              backgroundColor: theme.cardBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.borderColor),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 440,
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.88,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tituloModal,
                                  style: theme.getTextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Base: ${_formatarPreco(precoBaseUnitario)}',
                                  style: theme.getTextStyle(
                                    fontSize: 12,
                                    color: theme.buttonColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: theme.secondaryTextColor,
                              size: 20,
                            ),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Divider(color: theme.borderColor.withValues(alpha: 0.4)),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (variantes.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    'Escolha a Opção / Variante:',
                                    style: theme.getTextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: theme.secondaryTextColor,
                                    ),
                                  ),
                                ),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    for (final v in variantes)
                                      ChoiceChip(
                                        selected: varianteSelecionada == v.nome,
                                        label: Text(
                                          _parsePreco(v.preco) > 0
                                              ? '${v.nome} (${_formatarPreco(_parsePreco(v.preco))})'
                                              : v.nome,
                                        ),
                                        labelStyle: theme.getTextStyle(
                                          fontSize: 11.5,
                                          fontWeight:
                                              varianteSelecionada == v.nome
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: varianteSelecionada == v.nome
                                              ? theme.buttonTextColor
                                              : theme.textColor,
                                        ),
                                        backgroundColor: theme.backgroundColor,
                                        selectedColor: theme.buttonColor,
                                        onSelected: (_) {
                                          setModalState(() {
                                            varianteSelecionada = v.nome;
                                          });
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                              ],
                              for (final grupo in gruposDoItem) ...[
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(
                                    top: 8,
                                    bottom: 4,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.backgroundColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    grupo.nome,
                                    style: theme.getTextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textColor,
                                    ),
                                  ),
                                ),
                                for (final cId in grupo.itemIds)
                                  Builder(
                                    builder: (_) {
                                      final compItem = todosItens
                                          .where((x) => x.id == cId)
                                          .firstOrNull;
                                      if (compItem == null) {
                                        return const SizedBox.shrink();
                                      }
                                      final qtdSel =
                                          selecionados[compItem.id] ?? 0;
                                      final precoComp = _parsePreco(
                                        compItem.preco,
                                      );

                                      return InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () {
                                          setModalState(() {
                                            selecionados[compItem.id] =
                                                qtdSel == 0 ? 1 : 0;
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 6,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                qtdSel > 0
                                                    ? Icons.check_box_rounded
                                                    : Icons
                                                          .check_box_outline_blank_rounded,
                                                size: 19,
                                                color: qtdSel > 0
                                                    ? theme.buttonColor
                                                    : theme.secondaryTextColor,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      compItem.nome,
                                                      style: theme.getTextStyle(
                                                        fontSize: 13,
                                                        fontWeight: qtdSel > 0
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                        color: theme.textColor,
                                                      ),
                                                    ),
                                                    if (precoComp > 0)
                                                      Text(
                                                        '+ ${_formatarPreco(precoComp)}',
                                                        style: theme
                                                            .getTextStyle(
                                                              fontSize: 11,
                                                              color: theme
                                                                  .buttonColor,
                                                            ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (qtdSel > 0) ...[
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons
                                                            .remove_circle_outline,
                                                        size: 20,
                                                      ),
                                                      color: theme.dangerColor,
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                      onPressed: () {
                                                        setModalState(() {
                                                          selecionados[compItem
                                                                  .id] =
                                                              qtdSel - 1;
                                                        });
                                                      },
                                                    ),
                                                    Text(
                                                      '$qtdSel',
                                                      style: theme.getTextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: theme.textColor,
                                                      ),
                                                    ),
                                                  ],
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.add_circle_outline,
                                                      size: 20,
                                                    ),
                                                    color: theme.buttonColor,
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    onPressed: () {
                                                      setModalState(() {
                                                        selecionados[compItem
                                                                .id] =
                                                            qtdSel + 1;
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                              const SizedBox(height: 12),
                              TextField(
                                controller: obsItemCtrl,
                                style: theme.getTextStyle(
                                  fontSize: 12,
                                  color: theme.textColor,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Observação do item (opcional)',
                                  labelStyle: theme.getTextStyle(
                                    fontSize: 11,
                                    color: theme.secondaryTextColor,
                                  ),
                                  hintText:
                                      'Ex: bem passado, sem cebola, caprichado...',
                                  hintStyle: theme.getTextStyle(
                                    fontSize: 11,
                                    color: theme.secondaryTextColor.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: theme.backgroundColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: theme.borderColor),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 18),
                                  color: theme.textColor,
                                  visualDensity: VisualDensity.compact,
                                  onPressed: qtd > 1
                                      ? () => setModalState(() => qtd--)
                                      : null,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: Text(
                                    '$qtd',
                                    style: theme.getTextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textColor,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 18),
                                  color: theme.textColor,
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => setModalState(() => qtd++),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.buttonColor,
                                foregroundColor: theme.buttonTextColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(
                                Icons.add_shopping_cart_rounded,
                                size: 18,
                              ),
                              label: Text(
                                'Adicionar • ${_formatarPreco(subtotalItem)}',
                                style: theme.getTextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: theme.buttonTextColor,
                                ),
                              ),
                              onPressed: () {
                                final listaAcomp = <AcompanhamentoEscolhido>[];
                                for (final entry in selecionados.entries) {
                                  if (entry.value > 0) {
                                    final it = todosItens
                                        .where((x) => x.id == entry.key)
                                        .firstOrNull;
                                    if (it != null) {
                                      listaAcomp.add(
                                        AcompanhamentoEscolhido(
                                          itemId: it.id,
                                          nomeItem: it.nome,
                                          precoItem: _parsePreco(it.preco),
                                          quantidadePorUnidade: entry.value,
                                        ),
                                      );
                                    }
                                  }
                                }

                                final itemVendido = ItemVendido(
                                  itemId: item?.id ?? 'cat_${categoria?.id ?? ''}',
                                  nomeItem: item?.nome ?? categoria?.nome ?? 'Item',
                                  foto: (item != null && item.imagens.isNotEmpty)
                                      ? item.imagens.first
                                      : (categoria?.foto ?? ''),
                                  categoriaId: categoria?.id,
                                  nomeCategoria: categoria?.nome,
                                  precoCategoria: precoCategoria,
                                  precoItem: precoItemEfetivo,
                                  quantidade: qtd,
                                  varianteNome: varianteSelecionada ?? '',
                                  acompanhamentos: listaAcomp,
                                  observacao: obsItemCtrl.text.trim(),
                                );

                                Navigator.pop(ctx);
                                onConfirmar(itemVendido);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
