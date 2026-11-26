import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/services/compras_usuario_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

/// Seção "Carrinho" (Print 1 do protótipo) com cards horizontais dos itens por loja,
/// ajuste rápido de quantidade e botão "Continuar a compra".
class SecaoCarrinhoComprasWidget extends StatelessWidget {
  final AppTheme theme;
  final List<CarrinhoPendenteLoja> carrinhos;
  final VoidCallback onExplorarProdutos;
  final void Function(CarrinhoPendenteLoja carrinho) onContinuarCompra;
  final void Function(CarrinhoPendenteLoja carrinho) onLimparCarrinho;
  final void Function(
    CarrinhoPendenteLoja carrinho,
    ItemVendido item,
    int novaQuantidade,
  ) onAlterarQuantidade;

  const SecaoCarrinhoComprasWidget({
    super.key,
    required this.theme,
    required this.carrinhos,
    required this.onExplorarProdutos,
    required this.onContinuarCompra,
    required this.onLimparCarrinho,
    required this.onAlterarQuantidade,
  });

  @override
  Widget build(BuildContext context) {
    if (carrinhos.isEmpty) {
      return Column(
        children: [
          EstadoVazioContainer(
            theme: theme,
            mensagem: 'Seu carrinho está vazio no momento.',
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.buttonColor,
                foregroundColor: theme.buttonTextColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onExplorarProdutos,
              icon: const Icon(Icons.search_rounded, size: 18),
              label: Text(
                'Explorar produtos e serviços',
                style: theme.getTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.buttonTextColor,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: carrinhos.map((carrinho) {
        final nomeLoja = carrinho.loja?.nome ?? 'Loja parceira';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.backgroundColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.borderColor.withValues(alpha: 0.7),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho da loja no carrinho
              Row(
                children: [
                  Icon(
                    Icons.storefront_outlined,
                    size: 16,
                    color: theme.textColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      nomeLoja,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.getTextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                  Text(
                    'R\$ ${carrinho.total.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: theme.getTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Carrossel horizontal de cards dos itens (conforme Print 1)
              SizedBox(
                height: 148,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: carrinho.itens.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final item = carrinho.itens[i];
                    return Container(
                      width: 118,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.cardBackgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.borderColor.withValues(alpha: 0.65),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              height: 54,
                              width: double.infinity,
                              child: ImagemService.construirImagem(
                                item.foto,
                                fit: BoxFit.cover,
                                cacheWidth: 200,
                                fallback: Container(
                                  color: theme.backgroundColor
                                      .withValues(alpha: 0.6),
                                  child: Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 22,
                                    color: theme.secondaryTextColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.nomeItem,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.getTextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                          if (item.varianteNome.isNotEmpty)
                            Text(
                              item.varianteNome,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.getTextStyle(
                                fontSize: 9.5,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () => onAlterarQuantidade(
                                  carrinho,
                                  item,
                                  item.quantidade - 1,
                                ),
                                child: Icon(
                                  Icons.remove_circle_outline,
                                  size: 18,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                              Text(
                                '${item.quantidade}',
                                style: theme.getTextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor,
                                ),
                              ),
                              InkWell(
                                onTap: () => onAlterarQuantidade(
                                  carrinho,
                                  item,
                                  item.quantidade + 1,
                                ),
                                child: Icon(
                                  Icons.add_circle_outline,
                                  size: 18,
                                  color: theme.textColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Botões Limpar (esquerda) + Continuar a compra (direita)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => onLimparCarrinho(carrinho),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: theme.dangerColor,
                    ),
                    label: Text(
                      'Limpar',
                      style: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.dangerColor,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.buttonColor,
                      foregroundColor: theme.buttonTextColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => onContinuarCompra(carrinho),
                    icon: const Icon(Icons.payment_rounded, size: 16),
                    label: Text(
                      'Continuar a compra',
                      style: theme.getTextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: theme.buttonTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
