import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/abas_loja/catalogo/painel_categorias_grupos_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/abas_loja/catalogo/painel_itens_catalogo_widget.dart';

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

  @override
  Widget build(BuildContext context) {
    final painelCategoriasGrupos = PainelCategoriasGruposWidget(
      theme: theme,
      lojaId: lojaId,
      podeEditarLoja: podeEditarLoja,
      pesquisaCategorias: pesquisaCategorias,
      pesquisaGrupos: pesquisaGrupos,
      itens: itens,
      categorias: categorias,
      gruposComponentes: gruposComponentes,
      categoriaExpandidaId: categoriaExpandidaId,
      grupoExpandidoId: grupoExpandidoId,
      scrollCategorias: scrollCategorias,
      scrollGrupos: scrollGrupos,
      onAbrirPopupEditarItem: onAbrirPopupEditarItem,
      onEditarNomeItem: onEditarNomeItem,
      onEditarPrecoItem: onEditarPrecoItem,
      onReordenarCategorias: onReordenarCategorias,
      onReordenarGrupos: onReordenarGrupos,
      onAlternarExpansaoCategoria: onAlternarExpansaoCategoria,
      onAdicionarItemNaCategoria: onAdicionarItemNaCategoria,
      onRemoverItemDaCategoria: onRemoverItemDaCategoria,
      onAbrirPopupEditarCategoria: onAbrirPopupEditarCategoria,
      onRemoverCategoria: onRemoverCategoria,
      onEditarNomeCategoria: onEditarNomeCategoria,
      onAlternarExpansaoGrupo: onAlternarExpansaoGrupo,
      onAdicionarItemNoGrupo: onAdicionarItemNoGrupo,
      onRemoverItemDoGrupo: onRemoverItemDoGrupo,
      onAbrirPopupEditarGrupo: onAbrirPopupEditarGrupo,
      onRemoverGrupo: onRemoverGrupo,
      onEditarNomeGrupo: onEditarNomeGrupo,
    );

    final painelItens = PainelItensCatalogoWidget(
      theme: theme,
      podeEditarLoja: podeEditarLoja,
      expandido: expandido,
      pesquisaItens: pesquisaItens,
      itens: itens,
      onObterSaldoEstoque: onObterSaldoEstoque,
      onAbrirPopupEditarItem: onAbrirPopupEditarItem,
      onRemoverItem: onRemoverItem,
      onEditarNomeItem: onEditarNomeItem,
      onEditarPrecoItem: onEditarPrecoItem,
      onReordenarItens: onReordenarItens,
    );

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
              child: painelCategoriasGrupos,
            ),
          ),
          const SizedBox(width: 16),
          // Coluna Direita: Catálogo Expandido de Itens
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: decoracaoBloco,
              child: painelItens,
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
          painelItens,
          const SizedBox(height: 24),
          painelCategoriasGrupos,
        ],
      ),
    );
  }
}
