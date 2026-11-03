import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/item_loja_card.dart';

class PainelItensCatalogoWidget extends StatelessWidget {
  final AppTheme theme;
  final bool podeEditarLoja;
  final bool expandido;
  final TextEditingController pesquisaItens;
  final List<ItemLoja> itens;
  final double Function(String itemId) onObterSaldoEstoque;
  final void Function(ItemLoja item) onAbrirPopupEditarItem;
  final void Function(String id) onRemoverItem;
  final void Function(String id, String novoNome) onEditarNomeItem;
  final void Function(String id, String novoPreco) onEditarPrecoItem;
  final void Function(int oldIndex, int newIndex) onReordenarItens;

  const PainelItensCatalogoWidget({
    super.key,
    required this.theme,
    required this.podeEditarLoja,
    required this.expandido,
    required this.pesquisaItens,
    required this.itens,
    required this.onObterSaldoEstoque,
    required this.onAbrirPopupEditarItem,
    required this.onRemoverItem,
    required this.onEditarNomeItem,
    required this.onEditarPrecoItem,
    required this.onReordenarItens,
  });

  Widget _tituloDeSecao(String titulo) {
    return Text(
      titulo,
      style: theme.getTextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: theme.textColor,
      ),
    );
  }

  Widget _campoDePesquisa(
    TextEditingController controller,
    String hint,
  ) {
    return TextField(
      controller: controller,
      style: theme.getTextStyle(fontSize: 13, color: theme.textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: theme.getTextStyle(
          fontSize: 12,
          color: theme.secondaryTextColor,
        ),
        prefixIcon: Icon(
          Icons.search,
          size: 18,
          color: theme.secondaryTextColor,
        ),
        isDense: true,
        filled: true,
        fillColor: theme.backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: theme.borderColor.withValues(alpha: 0.6),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: theme.borderColor.withValues(alpha: 0.6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.buttonColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }

  Widget _textoListaVazia(String mensagem) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          mensagem,
          style: theme.getTextStyle(
            fontSize: 13,
            color: theme.secondaryTextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildCardItem(ItemLoja item) {
    return ItemLojaCard(
      key: ValueKey('item_${item.id}'),
      theme: theme,
      nome: item.nome,
      preco: item.preco,
      tipo: item.tipo,
      imagemUrl: item.imagens.isNotEmpty ? item.imagens.first : null,
      saldoEstoque: onObterSaldoEstoque(item.id),
      unidade: item.unidadeBase,
      podeEditar: podeEditarLoja,
      onEditar: () => onAbrirPopupEditarItem(item),
      onExcluir: () => onRemoverItem(item.id),
      onNomeAlterado: (novoNome) => onEditarNomeItem(item.id, novoNome),
      onPrecoAlterado: (novoPreco) => onEditarPrecoItem(item.id, novoPreco),
    );
  }

  @override
  Widget build(BuildContext context) {
    final termoItens = pesquisaItens.text.trim().toLowerCase();
    final itensFiltrados = termoItens.isEmpty
        ? itens
        : itens.where((i) => i.nome.toLowerCase().contains(termoItens)).toList();

    if (expandido) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _tituloDeSecao('Catálogo de Produtos'),
              Text(
                '${itensFiltrados.length} ${itensFiltrados.length == 1 ? 'item' : 'itens'}',
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _campoDePesquisa(
            pesquisaItens,
            'Pesquisar itens do catálogo...',
          ),
          const SizedBox(height: 16),
          if (itensFiltrados.isNotEmpty)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: itensFiltrados.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final card = _buildCardItem(item);

                if (podeEditarLoja && pesquisaItens.text.trim().isEmpty) {
                  return DragTarget<int>(
                    key: ValueKey('target_item_w_${item.id}'),
                    onWillAcceptWithDetails: (details) => details.data != index,
                    onAcceptWithDetails: (details) {
                      onReordenarItens(details.data, index);
                    },
                    builder: (context, candidateData, rejectedData) {
                      final isSobre = candidateData.isNotEmpty;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            child: isSobre
                                ? Container(
                                    width: 130,
                                    height: (175 *
                                            (theme.fontScale > 1.0
                                                ? theme.fontScale
                                                : 1.0))
                                        .clamp(175.0, 235.0),
                                    margin: const EdgeInsets.only(
                                      right: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: theme.textColor
                                          .withValues(alpha: 0.08),
                                      border: Border.all(
                                        color: theme.textColor
                                            .withValues(alpha: 0.6),
                                        width: 1.6,
                                      ),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.swap_horiz_rounded,
                                            size: 24,
                                            color: theme.textColor
                                                .withValues(alpha: 0.7),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Mover para cá',
                                            textAlign: TextAlign.center,
                                            style: theme.getTextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: theme.textColor
                                                  .withValues(alpha: 0.8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          LongPressDraggable<int>(
                            delay: const Duration(seconds: 1),
                            data: index,
                            dragAnchorStrategy: pointerDragAnchorStrategy,
                            feedback: Material(
                              color: Colors.transparent,
                              elevation: 16,
                              shadowColor: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              child: Transform.scale(
                                scale: 1.05,
                                child: Opacity(
                                  opacity: 0.95,
                                  child: SizedBox(
                                    width: 130,
                                    child: card,
                                  ),
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.25,
                              child: card,
                            ),
                            child: card,
                          ),
                        ],
                      );
                    },
                  );
                }

                return card;
              }).toList(),
            )
          else if (itens.isEmpty)
            _textoListaVazia('Nenhum item criado ainda.')
          else
            _textoListaVazia('Nenhum item encontrado.'),
        ],
      );
    }

    // Layout compacto (Mobile)
    return Column(
      children: [
        _tituloDeSecao('Itens'),
        const SizedBox(height: 12),
        _campoDePesquisa(
          pesquisaItens,
          'Pesquisar itens...',
        ),
        const SizedBox(height: 12),
        if (itensFiltrados.isNotEmpty)
          SizedBox(
            height: (175 * (theme.fontScale > 1.0 ? theme.fontScale : 1.0))
                .clamp(175.0, 235.0),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: itensFiltrados.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = itensFiltrados[index];
                final card = _buildCardItem(item);

                if (podeEditarLoja && pesquisaItens.text.trim().isEmpty) {
                  return DragTarget<int>(
                    key: ValueKey('target_item_h_${item.id}'),
                    onWillAcceptWithDetails: (details) => details.data != index,
                    onAcceptWithDetails: (details) {
                      onReordenarItens(details.data, index);
                    },
                    builder: (context, candidateData, rejectedData) {
                      final isSobre = candidateData.isNotEmpty;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            child: isSobre
                                ? Container(
                                    width: 130,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: theme.textColor
                                          .withValues(alpha: 0.08),
                                      border: Border.all(
                                        color: theme.textColor
                                            .withValues(alpha: 0.6),
                                        width: 1.6,
                                      ),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.swap_horiz_rounded,
                                            size: 24,
                                            color: theme.textColor
                                                .withValues(alpha: 0.7),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Mover para cá',
                                            textAlign: TextAlign.center,
                                            style: theme.getTextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: theme.textColor
                                                  .withValues(alpha: 0.8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          LongPressDraggable<int>(
                            delay: const Duration(seconds: 1),
                            data: index,
                            dragAnchorStrategy: pointerDragAnchorStrategy,
                            feedback: Material(
                              color: Colors.transparent,
                              elevation: 16,
                              shadowColor: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              child: Transform.scale(
                                scale: 1.05,
                                child: Opacity(
                                  opacity: 0.95,
                                  child: SizedBox(
                                    width: 130,
                                    child: card,
                                  ),
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.25,
                              child: card,
                            ),
                            child: card,
                          ),
                        ],
                      );
                    },
                  );
                }

                return card;
              },
            ),
          )
        else if (itens.isEmpty)
          _textoListaVazia('Nenhum item criado ainda.')
        else
          _textoListaVazia('Nenhum item encontrado.'),
      ],
    );
  }
}
