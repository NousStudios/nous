import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_categoria_dialog.dart';

/// Helper responsável pela gestão de categorias do catálogo da loja.
class CatalogoCategoriasHelper {
  final BuildContext Function() obterContext;
  final List<ItemLoja> Function() obterItens;
  final List<CategoriaLoja> Function() obterCategorias;
  final List<GrupoComponentesLoja> Function() obterGrupos;
  final bool Function() podeEditarAbaLoja;
  final VoidCallback avisarSemPermissao;
  final void Function(void Function()) setState;
  final VoidCallback aoPersistir;
  final void Function(TipoAcao tipo, String descricao) registrarAcao;
  final Future<bool> Function({
    required String titulo,
    required String mensagem,
  })
  confirmarExclusao;
  final String? Function() obterCategoriaExpandidaId;
  final void Function(String?) definirCategoriaExpandidaId;

  const CatalogoCategoriasHelper({
    required this.obterContext,
    required this.obterItens,
    required this.obterCategorias,
    required this.obterGrupos,
    required this.podeEditarAbaLoja,
    required this.avisarSemPermissao,
    required this.setState,
    required this.aoPersistir,
    required this.registrarAcao,
    required this.confirmarExclusao,
    required this.obterCategoriaExpandidaId,
    required this.definirCategoriaExpandidaId,
  });

  void abrirPopupNovaCategoria() {
    if (!podeEditarAbaLoja()) {
      avisarSemPermissao();
      return;
    }

    final categorias = obterCategorias();
    final grupos = obterGrupos();

    NovaCategoriaDialog.mostrar(
      obterContext(),
      theme: ThemeController.currentTheme.value,
      gruposComponentes: grupos,
      onCriar: (categoria) {
        setState(() => categorias.add(categoria));
        aoPersistir();

        registrarAcao(
          TipoAcao.categoriaCriada,
          'Categoria "${categoria.nome}" criada',
        );
      },
    );
  }

  void abrirPopupEditarCategoria(CategoriaLoja categoria) {
    if (!podeEditarAbaLoja()) {
      avisarSemPermissao();
      return;
    }

    final categorias = obterCategorias();
    final grupos = obterGrupos();

    NovaCategoriaDialog.mostrar(
      obterContext(),
      theme: ThemeController.currentTheme.value,
      gruposComponentes: grupos,
      categoriaParaEditar: categoria,
      onCriar: (categoriaEditada) {
        setState(() {
          final indice = categorias.indexWhere(
            (c) => c.id == categoriaEditada.id,
          );
          if (indice != -1) categorias[indice] = categoriaEditada;
        });
        aoPersistir();

        registrarAcao(
          TipoAcao.categoriaAtualizada,
          'Categoria "${categoriaEditada.nome}" atualizada',
        );
      },
    );
  }

  void editarNomeCategoria(String id, String novoNome) {
    if (!podeEditarAbaLoja()) return;
    final categorias = obterCategorias();
    final indice = categorias.indexWhere((c) => c.id == id);
    if (indice == -1) return;
    final anterior = categorias[indice];
    if (anterior.nome == novoNome) return;

    setState(() {
      categorias[indice] = anterior.copyWith(nome: novoNome);
    });
    aoPersistir();

    registrarAcao(
      TipoAcao.categoriaAtualizada,
      'Categoria "${anterior.nome}" renomeada para "$novoNome"',
    );
  }

  Future<void> removerCategoria(String id) async {
    if (!podeEditarAbaLoja()) {
      avisarSemPermissao();
      return;
    }

    final categorias = obterCategorias();
    final indice = categorias.indexWhere((c) => c.id == id);
    final nome = indice == -1 ? '' : categorias[indice].nome;

    final confirmou = await confirmarExclusao(
      titulo: 'Excluir Categoria',
      mensagem:
          'Tem certeza que deseja excluir a categoria "$nome"? Essa ação não pode ser desfeita.',
    );
    if (!confirmou) return;

    setState(() {
      categorias.removeWhere((categoria) => categoria.id == id);
      if (obterCategoriaExpandidaId() == id) {
        definirCategoriaExpandidaId(null);
      }
    });
    aoPersistir();

    registrarAcao(TipoAcao.categoriaExcluida, 'Categoria "$nome" excluída');
  }

  void adicionarItemNaCategoria(CategoriaLoja categoria, String itemId) {
    if (!podeEditarAbaLoja()) return;
    final categorias = obterCategorias();
    final itens = obterItens();

    setState(() {
      final indice = categorias.indexWhere((c) => c.id == categoria.id);
      if (indice == -1) return;
      final novosIds = [...categoria.itemIds, itemId];
      categorias[indice] = categoria.copyWith(itemIds: novosIds);
    });
    aoPersistir();

    final itemIndice = itens.indexWhere((i) => i.id == itemId);
    final nomeItem = itemIndice == -1 ? '' : itens[itemIndice].nome;

    registrarAcao(
      TipoAcao.itemVinculadoCategoria,
      'Item "$nomeItem" vinculado à categoria "${categoria.nome}"',
    );
  }

  void removerItemDaCategoria(CategoriaLoja categoria, String itemId) {
    if (!podeEditarAbaLoja()) return;
    final categorias = obterCategorias();
    final itens = obterItens();

    setState(() {
      final indice = categorias.indexWhere((c) => c.id == categoria.id);
      if (indice == -1) return;
      final novosIds = categoria.itemIds.where((id) => id != itemId).toList();
      categorias[indice] = categoria.copyWith(itemIds: novosIds);
    });
    aoPersistir();

    final itemIndice = itens.indexWhere((i) => i.id == itemId);
    final nomeItem = itemIndice == -1 ? '' : itens[itemIndice].nome;

    registrarAcao(
      TipoAcao.itemDesvinculadoCategoria,
      'Item "$nomeItem" desvinculado da categoria "${categoria.nome}"',
    );
  }
}
