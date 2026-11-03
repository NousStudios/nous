import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/widgets/categoria_loja_container.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/pdv/views/widgets/grupo_componentes_loja_container.dart';
import 'package:nous/src/features/pdv/views/widgets/item_loja_card.dart';
import 'package:provider/provider.dart';

class AbaCatalogoLojaWidget extends StatelessWidget {
  final AppTheme theme;
  final String lojaId;
  final bool podeEditarLoja;
  final bool expandido;
  final TextEditingController pesquisaItens;
  final TextEditingController pesquisaCategorias;
  final TextEditingController pesquisaGrupos;
  final List<ItemLoja> itens;
  final List<CategoriaLoja> categorias;
  final List<GrupoComponentesLoja> gruposComponentes;
  final String? categoriaExpandidaId;
  final String? grupoExpandidoId;
  final ScrollController scrollCategorias;
  final ScrollController scrollGrupos;
  final BoxDecoration decoracaoBloco;
  final double Function(String itemId) onObterSaldoEstoque;
  final void Function(ItemLoja item) onAbrirPopupEditarItem;
  final void Function(String id) onRemoverItem;
  final void Function(String id, String novoNome) onEditarNomeItem;
  final void Function(String id, String novoPreco) onEditarPrecoItem;
  final void Function(int oldIndex, int newIndex) onReordenarItens;
  final void Function(int oldIndex, int newIndex) onReordenarCategorias;
  final void Function(int oldIndex, int newIndex) onReordenarGrupos;
  final void Function(String categoriaId) onAlternarExpansaoCategoria;
  final void Function(CategoriaLoja cat, String itemId) onAdicionarItemNaCategoria;
  final void Function(CategoriaLoja cat, String itemId) onRemoverItemDaCategoria;
  final void Function(CategoriaLoja cat) onAbrirPopupEditarCategoria;
  final void Function(String catId) onRemoverCategoria;
  final void Function(String catId, String novoNome) onEditarNomeCategoria;
  final void Function(String grupoId) onAlternarExpansaoGrupo;
  final void Function(GrupoComponentesLoja grp, String itemId) onAdicionarItemNoGrupo;
  final void Function(GrupoComponentesLoja grp, String itemId) onRemoverItemDoGrupo;
  final void Function(GrupoComponentesLoja grp) onAbrirPopupEditarGrupo;
  final void Function(String grpId) onRemoverGrupo;
  final void Function(String grpId, String novoNome) onEditarNomeGrupo;

  const AbaCatalogoLojaWidget({
    super.key,
    required this.theme,
    required this.lojaId,
    required this.podeEditarLoja,
    required this.expandido,
    required this.pesquisaItens,
    required this.pesquisaCategorias,
    required this.pesquisaGrupos,
    required this.itens,
    required this.categorias,
    required this.gruposComponentes,
    required this.categoriaExpandidaId,
    required this.grupoExpandidoId,
    required this.scrollCategorias,
    required this.scrollGrupos,
    required this.decoracaoBloco,
    required this.onObterSaldoEstoque,
    required this.onAbrirPopupEditarItem,
    required this.onRemoverItem,
    required this.onEditarNomeItem,
    required this.onEditarPrecoItem,
    required this.onReordenarItens,
    required this.onReordenarCategorias,
    required this.onReordenarGrupos,
    required this.onAlternarExpansaoCategoria,
    required this.onAdicionarItemNaCategoria,
    required this.onRemoverItemDaCategoria,
    required this.onAbrirPopupEditarCategoria,
    required this.onRemoverCategoria,
    required this.onEditarNomeCategoria,
    required this.onAlternarExpansaoGrupo,
    required this.onAdicionarItemNoGrupo,
    required this.onRemoverItemDoGrupo,
    required this.onAbrirPopupEditarGrupo,
    required this.onRemoverGrupo,
    required this.onEditarNomeGrupo,
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

  Widget _construirCategoria(
    BuildContext context,
    CategoriaLoja categoria,
  ) {
    return CategoriaLojaContainer(
      key: ValueKey('cat_${categoria.id}'),
      theme: theme,
      nome: categoria.nome,
      preco: categoria.preco,
      foto: categoria.foto,
      itemIds: categoria.itemIds,
      itensDisponiveis: itens,
      expandida: categoria.id == categoriaExpandidaId,
      podeEditar: podeEditarLoja,
      aoAlternarExpansao: () => onAlternarExpansaoCategoria(categoria.id),
      onAdicionarItem: (itemId) => onAdicionarItemNaCategoria(categoria, itemId),
      onRemoverItem: (itemId) => onRemoverItemDaCategoria(categoria, itemId),
      onEditar: () => onAbrirPopupEditarCategoria(categoria),
      onExcluir: () => onRemoverCategoria(categoria.id),
      onNomeAlterado: (novoNome) => onEditarNomeCategoria(categoria.id, novoNome),
      onEditarNomeItem: onEditarNomeItem,
      onEditarPrecoItem: onEditarPrecoItem,
      onEditarItem: onAbrirPopupEditarItem,
    );
  }

  Widget _listaCategorias(
    BuildContext context,
    List<CategoriaLoja> cats,
  ) {
    if (cats.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: EstadoVazioContainer(
          theme: theme,
          mensagem: categorias.isEmpty
              ? 'Nenhuma categoria criada ainda.'
              : 'Nenhuma categoria encontrada.',
        ),
      );
    }

    if (categoriaExpandidaId == null) {
      final podeReordenar =
          podeEditarLoja && pesquisaCategorias.text.trim().isEmpty;
      final larguraDaTela = MediaQuery.sizeOf(context).width;
      final ehDesktop = context
          .read<PdvProvider>()
          .layoutDesktopAtivo(lojaId, larguraDaTela);
      final alturaMaxima = ehDesktop ? 440.0 : 180.0;

      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: alturaMaxima),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ListView.separated(
              controller: scrollCategorias,
              shrinkWrap: true,
              padding: const EdgeInsets.only(right: 8),
              itemCount: cats.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final cat = cats[index];
                final cardWidget = _construirCategoria(context, cat);

                if (!podeReordenar) {
                  return cardWidget;
                }

                return DragTarget<int>(
                  key: ValueKey('target_cat_${cat.id}'),
                  onWillAcceptWithDetails: (details) => details.data != index,
                  onAcceptWithDetails: (details) {
                    onReordenarCategorias(details.data, index);
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isSobre = candidateData.isNotEmpty;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          child: isSobre
                              ? Container(
                                  height: 48,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: theme.textColor.withValues(
                                      alpha: 0.08,
                                    ),
                                    border: Border.all(
                                      color: theme.textColor.withValues(
                                        alpha: 0.6,
                                      ),
                                      width: 1.6,
                                    ),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.swap_vert_rounded,
                                          size: 18,
                                          color: theme.textColor.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Mover categoria para cá',
                                          style: theme.getTextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: theme.textColor.withValues(
                                              alpha: 0.8,
                                            ),
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
                            elevation: 8,
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: constraints.maxWidth > 0
                                  ? constraints.maxWidth
                                  : 260,
                              child: cardWidget,
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: cardWidget,
                          ),
                          child: cardWidget,
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      );
    }

    return Column(
      children: cats
          .map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _construirCategoria(context, c),
              ))
          .toList(),
    );
  }

  Widget _construirGrupo(
    BuildContext context,
    GrupoComponentesLoja grupo,
  ) {
    return GrupoComponentesLojaContainer(
      key: ValueKey('grp_${grupo.id}'),
      theme: theme,
      nome: grupo.nome,
      foto: grupo.foto,
      itemIds: grupo.itemIds,
      itensDisponiveis: itens,
      expandida: grupo.id == grupoExpandidoId,
      podeEditar: podeEditarLoja,
      aoAlternarExpansao: () => onAlternarExpansaoGrupo(grupo.id),
      onAdicionarItem: (itemId) => onAdicionarItemNoGrupo(grupo, itemId),
      onRemoverItem: (itemId) => onRemoverItemDoGrupo(grupo, itemId),
      onEditar: () => onAbrirPopupEditarGrupo(grupo),
      onExcluir: () => onRemoverGrupo(grupo.id),
      onNomeAlterado: (novoNome) => onEditarNomeGrupo(grupo.id, novoNome),
      onEditarNomeItem: onEditarNomeItem,
      onEditarPrecoItem: onEditarPrecoItem,
      onEditarItem: onAbrirPopupEditarItem,
    );
  }

  Widget _listaGrupos(
    BuildContext context,
    List<GrupoComponentesLoja> grps,
  ) {
    if (grps.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: EstadoVazioContainer(
          theme: theme,
          mensagem: gruposComponentes.isEmpty
              ? 'Nenhum grupo de componentes criado ainda.'
              : 'Nenhum grupo de componentes encontrado.',
        ),
      );
    }

    if (grupoExpandidoId == null) {
      final podeReordenar =
          podeEditarLoja && pesquisaGrupos.text.trim().isEmpty;
      final larguraDaTela = MediaQuery.sizeOf(context).width;
      final ehDesktop = context
          .read<PdvProvider>()
          .layoutDesktopAtivo(lojaId, larguraDaTela);
      final alturaMaxima = ehDesktop ? 440.0 : 180.0;

      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: alturaMaxima),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ListView.separated(
              controller: scrollGrupos,
              shrinkWrap: true,
              padding: const EdgeInsets.only(right: 8),
              itemCount: grps.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final grp = grps[index];
                final cardWidget = _construirGrupo(context, grp);

                if (!podeReordenar) {
                  return cardWidget;
                }

                return DragTarget<int>(
                  key: ValueKey('target_grp_${grp.id}'),
                  onWillAcceptWithDetails: (details) => details.data != index,
                  onAcceptWithDetails: (details) {
                    onReordenarGrupos(details.data, index);
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isSobre = candidateData.isNotEmpty;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          child: isSobre
                              ? Container(
                                  height: 48,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: theme.textColor.withValues(
                                      alpha: 0.08,
                                    ),
                                    border: Border.all(
                                      color: theme.textColor.withValues(
                                        alpha: 0.6,
                                      ),
                                      width: 1.6,
                                    ),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.swap_vert_rounded,
                                          size: 18,
                                          color: theme.textColor.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Mover grupo para cá',
                                          style: theme.getTextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: theme.textColor.withValues(
                                              alpha: 0.8,
                                            ),
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
                            elevation: 8,
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: constraints.maxWidth > 0
                                  ? constraints.maxWidth
                                  : 260,
                              child: cardWidget,
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: cardWidget,
                          ),
                          child: cardWidget,
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      );
    }

    return Column(
      children: grps
          .map((g) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _construirGrupo(context, g),
              ))
          .toList(),
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
    final termoCategorias = pesquisaCategorias.text.trim().toLowerCase();
    final termoGrupos = pesquisaGrupos.text.trim().toLowerCase();

    final itensFiltrados = termoItens.isEmpty
        ? itens
        : itens.where((i) => i.nome.toLowerCase().contains(termoItens)).toList();

    final categoriasFiltradas = termoCategorias.isEmpty
        ? categorias
        : categorias
            .where((c) => c.nome.toLowerCase().contains(termoCategorias))
            .toList();

    final gruposFiltrados = termoGrupos.isEmpty
        ? gruposComponentes
        : gruposComponentes
            .where((g) => g.nome.toLowerCase().contains(termoGrupos))
            .toList();

    if (expandido) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coluna Esquerda: Categorias e Grupos de Componentes
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: decoracaoBloco,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _tituloDeSecao('Categorias'),
                  const SizedBox(height: 12),
                  _campoDePesquisa(
                    pesquisaCategorias,
                    'Pesquisar categorias...',
                  ),
                  const SizedBox(height: 12),
                  _listaCategorias(context, categoriasFiltradas),
                  const SizedBox(height: 24),
                  _tituloDeSecao('Grupos de Componentes'),
                  const SizedBox(height: 12),
                  _campoDePesquisa(
                    pesquisaGrupos,
                    'Pesquisar grupos...',
                  ),
                  const SizedBox(height: 12),
                  _listaGrupos(context, gruposFiltrados),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Coluna Direita: Catálogo Expandido de Itens
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: decoracaoBloco,
              child: Column(
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

                        if (podeEditarLoja &&
                            pesquisaItens.text.trim().isEmpty) {
                          return DragTarget<int>(
                            key: ValueKey('target_item_w_${item.id}'),
                            onWillAcceptWithDetails: (details) =>
                                details.data != index,
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
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: theme.textColor
                                                          .withValues(
                                                            alpha: 0.8,
                                                          ),
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
                                    dragAnchorStrategy:
                                        pointerDragAnchorStrategy,
                                    feedback: Material(
                                      color: Colors.transparent,
                                      elevation: 16,
                                      shadowColor: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
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
              ),
            ),
          ),
        ],
      );
    }

    // Layout Compacto (Mobile / Tablet estreito)
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: decoracaoBloco,
      child: Column(
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
                separatorBuilder: (context, index) =>
                    const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = itensFiltrados[index];
                  final card = _buildCardItem(item);

                  if (podeEditarLoja &&
                      pesquisaItens.text.trim().isEmpty) {
                    return DragTarget<int>(
                      key: ValueKey('target_item_h_${item.id}'),
                      onWillAcceptWithDetails: (details) =>
                          details.data != index,
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
                                        borderRadius:
                                            BorderRadius.circular(12),
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
                                shadowColor:
                                    Colors.black.withValues(alpha: 0.5),
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

          const SizedBox(height: 24),
          _tituloDeSecao('Categorias'),
          const SizedBox(height: 12),
          _campoDePesquisa(
            pesquisaCategorias,
            'Pesquisar categorias...',
          ),
          const SizedBox(height: 12),
          _listaCategorias(context, categoriasFiltradas),

          const SizedBox(height: 24),
          _tituloDeSecao('Grupos de Componentes'),
          const SizedBox(height: 12),
          _campoDePesquisa(
            pesquisaGrupos,
            'Pesquisar grupos...',
          ),
          const SizedBox(height: 12),
          _listaGrupos(context, gruposFiltrados),
        ],
      ),
    );
  }
}
