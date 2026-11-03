import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

class CatalogoBalcaoWidget extends StatelessWidget {
  final AppTheme theme;
  final List<CategoriaLoja> categorias;
  final String? categoriaFiltroId;
  final List<ItemLoja> itens;
  final double Function(String itemId) obterSaldoEstoque;
  final ValueChanged<String?> onSelecionarCategoria;
  final ValueChanged<ItemLoja> onSelecionarItem;

  const CatalogoBalcaoWidget({
    super.key,
    required this.theme,
    required this.categorias,
    required this.categoriaFiltroId,
    required this.itens,
    required this.obterSaldoEstoque,
    required this.onSelecionarCategoria,
    required this.onSelecionarItem,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── BARRA DE CATEGORIAS ──
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildChipCategoria(
                titulo: 'Todos',
                selecionado: categoriaFiltroId == null,
                onTap: () => onSelecionarCategoria(null),
              ),
              for (final cat in categorias)
                _buildChipCategoria(
                  titulo: cat.nome,
                  selecionado: categoriaFiltroId == cat.id,
                  onTap: () => onSelecionarCategoria(cat.id),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ── GRID DE PRODUTOS ──
        Expanded(
          child: itens.isEmpty
              ? Center(
                  child: Text(
                    'Nenhum produto encontrado.',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 160,
                    mainAxisExtent: 120,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: itens.length,
                  itemBuilder: (context, index) {
                    final item = itens[index];
                    final foto = item.imagens.firstOrNull ?? '';
                    final fotoResolvida =
                        ImagemService.resolverCaminhoExistente(foto);
                    final temFoto = fotoResolvida != null;
                    final saldo = obterSaldoEstoque(item.id);
                    final esgotado = saldo <= 0;

                    return InkWell(
                      onTap: () => onSelecionarItem(item),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.backgroundColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.borderColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(9)),
                                      image: temFoto
                                          ? DecorationImage(
                                              image: FileImage(
                                                  File(fotoResolvida)),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                      color: theme.borderColor
                                          .withValues(alpha: 0.15),
                                    ),
                                    child: !temFoto
                                        ? Center(
                                            child: Icon(
                                                Icons.shopping_bag_outlined,
                                                size: 24,
                                                color:
                                                    theme.secondaryTextColor),
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: esgotado
                                            ? Colors.redAccent
                                                .withValues(alpha: 0.85)
                                            : theme.cardBackgroundColor
                                                .withValues(alpha: 0.85),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        esgotado
                                            ? 'Esgotado'
                                            : 'Est: ${formatarQuantidadeComUnidade(saldo, item.unidadeBase)}',
                                        style: theme.getTextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: theme.textColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.nome,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.getTextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textColor,
                                    ),
                                  ),
                                  Text(
                                    'R\$ ${item.preco}',
                                    style: theme.getTextStyle(
                                      fontSize: 11,
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
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildChipCategoria({
    required String titulo,
    required bool selecionado,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selecionado
                ? (theme.buttonColor != Colors.transparent
                    ? theme.buttonColor.withValues(alpha: 0.8)
                    : theme.borderColor.withValues(alpha: 0.35))
                : theme.backgroundColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selecionado
                  ? theme.textColor
                  : theme.borderColor.withValues(alpha: 0.5),
              width: selecionado ? 1.4 : 1.0,
            ),
          ),
          child: Text(
            titulo,
            style: theme.getTextStyle(
              fontSize: 11,
              fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
              color: selecionado ? theme.textColor : theme.secondaryTextColor,
            ),
          ),
        ),
      ),
    );
  }
}
