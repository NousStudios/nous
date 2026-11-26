import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/busca/controllers/busca_mapa_controller.dart';
import 'package:nous/src/features/busca/views/widgets/catalogo_produtos/card_produto_mercado_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

class GradeProdutosMercadoWidget extends StatelessWidget {
  final BuscaMapaController controller;
  final AppTheme theme;
  final void Function(ProdutoMapaItem produto) onAbrirDetalhes;
  final void Function(ProdutoMapaItem produto, Offset posicaoClique)
      onAdicionarAoCarrinho;

  const GradeProdutosMercadoWidget({
    super.key,
    required this.controller,
    required this.theme,
    required this.onAbrirDetalhes,
    required this.onAdicionarAoCarrinho,
  });

  @override
  Widget build(BuildContext context) {
    final produtos = controller.produtosFiltrados;
    final ehServico = controller.filtroAtivo == FiltroBuscaMapa.servicos;
    final tipoRotulo = ehServico ? 'Serviços' : 'Produtos';
    final temGps = controller.posicaoUsuario != null;

    if (produtos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: EstadoVazioContainer(
            theme: theme,
            mensagem: controller.termoBusca.trim().isNotEmpty
                ? 'Nenhum $tipoRotulo encontrado para "${controller.termoBusca}".'
                : 'Nenhum $tipoRotulo cadastrado nas lojas disponíveis.',
          ),
        ),
      );
    }

    final largura = MediaQuery.sizeOf(context).width;
    final int crossAxisCount =
        largura > 960 ? 4 : (largura > 620 ? 3 : 2);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        temGps
                            ? Icons.gps_fixed_rounded
                            : Icons.near_me_rounded,
                        size: 15,
                        color: theme.textColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          temGps
                              ? '$tipoRotulo ordenados por proximidade (GPS)'
                              : '$tipoRotulo ordenados por proximidade',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${produtos.length} ${produtos.length == 1 ? 'item' : 'itens'}',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 96),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.66,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final produto = produtos[index];
                return Builder(
                  builder: (itemCtx) => CardProdutoMercadoWidget(
                    produto: produto,
                    theme: theme,
                    onTap: () => onAbrirDetalhes(produto),
                    onAdicionarAoCarrinho: () {
                      final box = itemCtx.findRenderObject() as RenderBox?;
                      final posicao = box != null
                          ? box.localToGlobal(
                              Offset(box.size.width / 2, box.size.height / 2),
                            )
                          : Offset(largura / 2, 300);
                      onAdicionarAoCarrinho(produto, posicao);
                    },
                  ),
                );
              },
              childCount: produtos.length,
            ),
          ),
        ),
      ],
    );
  }
}
