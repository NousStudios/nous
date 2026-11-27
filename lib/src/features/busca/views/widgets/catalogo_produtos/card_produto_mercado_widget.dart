import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/busca/controllers/helpers/busca_mapa_modelos.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

class CardProdutoMercadoWidget extends StatelessWidget {
  final ProdutoMapaItem produto;
  final AppTheme theme;
  final VoidCallback onTap;
  final VoidCallback onAdicionarAoCarrinho;

  const CardProdutoMercadoWidget({
    super.key,
    required this.produto,
    required this.theme,
    required this.onTap,
    required this.onAdicionarAoCarrinho,
  });

  @override
  Widget build(BuildContext context) {
    final item = produto.item;
    final loja = produto.loja;
    final fotoUrl = produto.fotoDestaque;
    final precoTexto = produto.precoTexto;
    final nomeExibicao = produto.nomeExibicao;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardBackgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.borderColor.withValues(alpha: 0.65),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Imagem de destaque do Produto
            AspectRatio(
              aspectRatio: 1.15,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ImagemService.construirImagem(
                    fotoUrl,
                    fit: BoxFit.cover,
                    cacheWidth: 420,
                    fallback: _placeholderImagem(theme),
                  ),
                  // Selo de distância no topo
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.cardBackgroundColor.withValues(alpha: 0.90),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.borderColor.withValues(alpha: 0.7),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 11,
                              color: theme.textColor,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                produto.distanciaFormatada,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.getTextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Informações, Loja, Preço e Carrinho
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomeExibicao,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.getTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (item.descricao.trim().isNotEmpty)
                      Text(
                        item.descricao,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.getTextStyle(
                          fontSize: 11,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.storefront_outlined,
                          size: 12,
                          color: theme.secondaryTextColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            loja.cidade.trim().isNotEmpty
                                ? '${loja.nome} • ${loja.cidade}'
                                : loja.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.getTextStyle(
                              fontSize: 10.5,
                              color: theme.secondaryTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            precoTexto,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.getTextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: onAdicionarAoCarrinho,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: theme.buttonColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.add_shopping_cart_rounded,
                              size: 16,
                              color: theme.buttonTextColor,
                            ),
                          ),
                        ),
                      ],
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

  Widget _placeholderImagem(AppTheme theme) {
    return Container(
      color: theme.backgroundColor.withValues(alpha: 0.6),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 32,
          color: theme.secondaryTextColor.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
