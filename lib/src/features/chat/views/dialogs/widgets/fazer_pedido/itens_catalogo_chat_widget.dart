import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

/// Cards visuais e interativos de Itens e Categorias do Catálogo no Autoatendimento.
class ItensCatalogoChatWidget {
  ItensCatalogoChatWidget._();

  static double parsePreco(String p) => double.tryParse(p.replaceAll(',', '.')) ?? 0.0;
  static String formatarPreco(double v) => 'R\$ ${v.toStringAsFixed(2)}';

  static Widget buildCardCategoriaDireta({
    required AppTheme theme,
    required CategoriaLoja cat,
    required Loja loja,
    required VoidCallback onTap,
  }) {
    final precoCat = parsePreco(cat.preco);
    return Card(
      color: theme.backgroundColor,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.borderColor.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: ImagemService.construirImagem(
                    cat.foto,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    fallback: Container(
                      color: theme.cardBackgroundColor,
                      child: Icon(
                        Icons.restaurant_rounded,
                        color: theme.secondaryTextColor,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.nome,
                      style: theme.getTextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    Text(
                      'Toque para montar e escolher acompanhamentos',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatarPreco(precoCat),
                style: theme.getTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.buttonColor,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.add_circle_rounded, color: theme.buttonColor, size: 26),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildCardItemInterativo({
    required AppTheme theme,
    required ItemLoja item,
    required Loja loja,
    required CategoriaLoja? cat,
    required String? categoriaSelecionadaId,
    required List<ItemVendido> carrinho,
    required VoidCallback onInteragir,
    required VoidCallback onPersonalizar,
    required VoidCallback onDecrementar,
  }) {
    final temComponentesOuVariantes =
        (cat != null && cat.grupoIds.isNotEmpty) || item.variantes.isNotEmpty;
    final precoBase = parsePreco(item.preco) + (cat != null ? parsePreco(cat.preco) : 0.0);
    final fotoItem = item.imagens.isNotEmpty ? item.imagens.first : (cat?.foto ?? '');

    final qtdNoCarrinho = carrinho
        .where((c) => c.itemId == item.id)
        .fold(0, (s, c) => s + c.quantidade);

    return Card(
      color: theme.backgroundColor,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: qtdNoCarrinho > 0
              ? theme.buttonColor
              : theme.borderColor.withValues(alpha: 0.4),
          width: qtdNoCarrinho > 0 ? 1.4 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onInteragir,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: ImagemService.construirImagem(
                    fotoItem,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    fallback: Container(
                      color: theme.cardBackgroundColor,
                      child: Icon(
                        Icons.fastfood_outlined,
                        color: theme.secondaryTextColor,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nome,
                      style: theme.getTextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    if (cat != null && categoriaSelecionadaId == null)
                      Text(
                        cat.nome,
                        style: theme.getTextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: theme.buttonColor,
                        ),
                      ),
                    if (item.descricao.isNotEmpty)
                      Text(
                        item.descricao,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.getTextStyle(
                          fontSize: 11,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          formatarPreco(precoBase),
                          style: theme.getTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: onPersonalizar,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Text(
                              temComponentesOuVariantes ? 'Escolher opções' : '+ Observação',
                              style: theme.getTextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.buttonColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (qtdNoCarrinho > 0 && !temComponentesOuVariantes)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 22),
                      color: theme.dangerColor,
                      visualDensity: VisualDensity.compact,
                      onPressed: onDecrementar,
                    ),
                    Text(
                      '$qtdNoCarrinho',
                      style: theme.getTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_rounded, size: 24),
                      color: theme.buttonColor,
                      visualDensity: VisualDensity.compact,
                      onPressed: onInteragir,
                    ),
                  ],
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.buttonColor,
                    foregroundColor: theme.buttonTextColor,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: onInteragir,
                  child: Text(
                    qtdNoCarrinho > 0 ? '+ Mais ($qtdNoCarrinho)' : 'Pedir',
                    style: theme.getTextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: theme.buttonTextColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
