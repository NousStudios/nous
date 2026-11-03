import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_categoria_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/novo_grupo_componentes_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/novo_item_dialog.dart';

/// Controlador desacoplado responsável pela gestão do catálogo de produtos,
/// categorias e grupos de componentes da loja no PDV.
class GerenciadorCatalogoLoja {
  final BuildContext Function() obterContext;
  final bool Function() estaMontado;
  final String lojaId;
  final List<ItemLoja> Function() obterItens;
  final List<CategoriaLoja> Function() obterCategorias;
  final List<GrupoComponentesLoja> Function() obterGrupos;
  final List<MovimentoEstoque> Function() obterMovimentos;
  final String Function() obterCpfLogado;
  final String Function() obterNomeLogado;
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
  final String Function(UnidadeItemLoja u) rotuloUnidadeCurto;
  final String Function(double qtd) formatarQuantidade;
  final String? Function() obterCategoriaExpandidaId;
  final void Function(String?) definirCategoriaExpandidaId;
  final String? Function() obterGrupoExpandidoId;
  final void Function(String?) definirGrupoExpandidoId;
  final Future<void> Function({ItemLoja? itemInicial}) abrirPopupNovoMovimento;

  GerenciadorCatalogoLoja({
    required this.obterContext,
    required this.estaMontado,
    required this.lojaId,
    required this.obterItens,
    required this.obterCategorias,
    required this.obterGrupos,
    required this.obterMovimentos,
    required this.obterCpfLogado,
    required this.obterNomeLogado,
    required this.podeEditarAbaLoja,
    required this.avisarSemPermissao,
    required this.setState,
    required this.aoPersistir,
    required this.registrarAcao,
    required this.confirmarExclusao,
    required this.rotuloUnidadeCurto,
    required this.formatarQuantidade,
    required this.obterCategoriaExpandidaId,
    required this.definirCategoriaExpandidaId,
    required this.obterGrupoExpandidoId,
    required this.definirGrupoExpandidoId,
    required this.abrirPopupNovoMovimento,
  });

  BuildContext get context => obterContext();

  double saldoEstoqueDoItem(String itemId) {
    var saldo = 0.0;
    for (final m in obterMovimentos()) {
      if (m.itemId == itemId) {
        saldo += m.quantidadeComSinal;
      }
    }
    return saldo;
  }

  MovimentoEstoque? ultimaEntradaComCustoDoItem(String itemId) {
    for (final m in obterMovimentos().reversed) {
      if (m.itemId == itemId && m.ehEntrada && m.custoUnitario > 0) {
        return m;
      }
    }
    return null;
  }

  void sincronizarVinculosItem(
    String itemId,
    List<String> categoriaIds,
    List<String> grupoIds,
  ) {
    final categorias = obterCategorias();
    final grupos = obterGrupos();

    setState(() {
      for (var i = 0; i < categorias.length; i++) {
        final categoria = categorias[i];
        final deveConter = categoriaIds.contains(categoria.id);
        final contem = categoria.itemIds.contains(itemId);
        if (deveConter && !contem) {
          categorias[i] = categoria.copyWith(
            itemIds: [...categoria.itemIds, itemId],
          );
        } else if (!deveConter && contem) {
          categorias[i] = categoria.copyWith(
            itemIds: categoria.itemIds.where((id) => id != itemId).toList(),
          );
        }
      }

      for (var i = 0; i < grupos.length; i++) {
        final grupo = grupos[i];
        final deveConter = grupoIds.contains(grupo.id);
        final contem = grupo.itemIds.contains(itemId);
        if (deveConter && !contem) {
          grupos[i] = grupo.copyWith(itemIds: [...grupo.itemIds, itemId]);
        } else if (!deveConter && contem) {
          grupos[i] = grupo.copyWith(
            itemIds: grupo.itemIds.where((id) => id != itemId).toList(),
          );
        }
      }
    });
  }

  void abrirPopupNovoItem() {
    if (!podeEditarAbaLoja()) {
      avisarSemPermissao();
      return;
    }

    double? estoqueInicialInformado;
    final categorias = obterCategorias();
    final grupos = obterGrupos();
    final itens = obterItens();
    final movimentos = obterMovimentos();

    NovoItemDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      categorias: categorias,
      gruposComponentes: grupos,
      layoutExpandido:
          context.read<PdvProvider>().buscarPorId(lojaId)?.layoutExpandido ??
          false,
      onEstoqueAjustado: (novoSaldo) {
        estoqueInicialInformado = novoSaldo;
      },
      onCategoriaCriada: (novaCategoria) {
        setState(() => categorias.add(novaCategoria));
        aoPersistir();
        registrarAcao(
          TipoAcao.categoriaCriada,
          'Categoria "${novaCategoria.nome}" criada pelo cadastro de item',
        );
      },
      onGrupoCriado: (novoGrupo) {
        setState(() => grupos.add(novoGrupo));
        aoPersistir();
        registrarAcao(
          TipoAcao.grupoCriado,
          'Grupo de componentes "${novoGrupo.nome}" criado pelo cadastro de item',
        );
      },
      onCriar: (item, categoriaIds, grupoIds) {
        setState(() => itens.add(item));
        sincronizarVinculosItem(item.id, categoriaIds, grupoIds);

        if (estoqueInicialInformado != null && estoqueInicialInformado! > 0) {
          final custoTexto = item.precoCusto
              .trim()
              .replaceAll('.', '')
              .replaceAll(',', '.');
          final custo = double.tryParse(custoTexto) ?? 0.0;
          final mov = MovimentoEstoque.novo(
            itemId: item.id,
            tipo: TipoMovimentoEstoque.entrada,
            quantidade: estoqueInicialInformado!,
            custoUnitario: custo,
            motivo: 'Estoque inicial cadastrado na criação do item',
            cpfAutor: obterCpfLogado(),
            nomeAutor: obterNomeLogado(),
            categoria: CategoriaMovimentoEstoque.ajuste,
          );
          setState(() => movimentos.add(mov));
        }

        aoPersistir();

        registrarAcao(TipoAcao.itemCriado, 'Item "${item.nome}" criado');
      },
    );
  }

  void abrirPopupEditarItem(ItemLoja item) {
    if (!podeEditarAbaLoja()) {
      avisarSemPermissao();
      return;
    }

    final itens = obterItens();
    final categorias = obterCategorias();
    final grupos = obterGrupos();
    final movimentos = obterMovimentos();

    final itemAtualizado = itens.firstWhere(
      (i) => i.id == item.id,
      orElse: () => item,
    );

    final categoriaIdsIniciais = categorias
        .where((c) => c.itemIds.contains(itemAtualizado.id))
        .map((c) => c.id)
        .toList();
    final grupoIdsIniciais = grupos
        .where((g) => g.itemIds.contains(itemAtualizado.id))
        .map((g) => g.id)
        .toList();

    double? novoEstoqueInformado;
    final ultimaEntrada = ultimaEntradaComCustoDoItem(itemAtualizado.id);

    NovoItemDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      categorias: categorias,
      gruposComponentes: grupos,
      itemParaEditar: itemAtualizado,
      categoriaIdsIniciais: categoriaIdsIniciais,
      grupoIdsIniciais: grupoIdsIniciais,
      saldoEstoqueAtual: saldoEstoqueDoItem(itemAtualizado.id),
      ultimaQuantidadeCompra: ultimaEntrada?.quantidade,
      ultimoCustoTotalCompra: ultimaEntrada != null
          ? (ultimaEntrada.quantidade * ultimaEntrada.custoUnitario)
          : null,
      layoutExpandido:
          context.read<PdvProvider>().buscarPorId(lojaId)?.layoutExpandido ??
          false,
      onEstoqueAjustado: (novoSaldo) {
        novoEstoqueInformado = novoSaldo;
      },
      onAbrirMovimentoDetalhado: (itemParaMovimento) {
        abrirPopupNovoMovimento(itemInicial: itemParaMovimento);
      },
      onCategoriaCriada: (novaCategoria) {
        setState(() => categorias.add(novaCategoria));
        aoPersistir();
        registrarAcao(
          TipoAcao.categoriaCriada,
          'Categoria "${novaCategoria.nome}" criada pelo cadastro de item',
        );
      },
      onGrupoCriado: (novoGrupo) {
        setState(() => grupos.add(novoGrupo));
        aoPersistir();
        registrarAcao(
          TipoAcao.grupoCriado,
          'Grupo de componentes "${novoGrupo.nome}" criado pelo cadastro de item',
        );
      },
      onCriar: (itemEditado, categoriaIds, grupoIds) {
        final anterior = itens.firstWhere(
          (i) => i.id == itemEditado.id,
          orElse: () => itemEditado,
        );

        setState(() {
          final indice = itens.indexWhere((i) => i.id == itemEditado.id);
          if (indice != -1) itens[indice] = itemEditado;
        });
        sincronizarVinculosItem(itemEditado.id, categoriaIds, grupoIds);

        if (novoEstoqueInformado != null) {
          final saldoAtual = saldoEstoqueDoItem(itemEditado.id);
          final delta = novoEstoqueInformado! - saldoAtual;
          if (delta.abs() > 0.0001) {
            final custoTexto = itemEditado.precoCusto
                .trim()
                .replaceAll('.', '')
                .replaceAll(',', '.');
            final custo = double.tryParse(custoTexto) ?? 0.0;
            final mov = MovimentoEstoque.novo(
              itemId: itemEditado.id,
              tipo: delta > 0
                  ? TipoMovimentoEstoque.entrada
                  : TipoMovimentoEstoque.saida,
              quantidade: delta.abs(),
              custoUnitario: custo,
              motivo: 'Ajuste direto de saldo na edição do item',
              cpfAutor: obterCpfLogado(),
              nomeAutor: obterNomeLogado(),
              categoria: CategoriaMovimentoEstoque.ajuste,
            );
            setState(() => movimentos.add(mov));
          }
        }

        aoPersistir();

        final mudouNome = anterior.nome != itemEditado.nome;
        final mudouPreco = anterior.preco != itemEditado.preco;

        if (mudouPreco && mudouNome) {
          registrarAcao(
            TipoAcao.itemAtualizado,
            'Item "${anterior.nome}" renomeado para '
            '"${itemEditado.nome}" e preço alterado de '
            'R\$ ${anterior.preco} para R\$ ${itemEditado.preco}',
          );
        } else if (mudouPreco) {
          registrarAcao(
            TipoAcao.itemAtualizado,
            'Preço de "${itemEditado.nome}" alterado de '
            'R\$ ${anterior.preco} para R\$ ${itemEditado.preco}',
          );
        } else {
          registrarAcao(
            TipoAcao.itemAtualizado,
            'Item "${itemEditado.nome}" atualizado',
          );
        }
      },
    );
  }

  void editarNomeItem(String id, String novoNome) {
    if (!podeEditarAbaLoja()) return;
    final itens = obterItens();
    final indice = itens.indexWhere((i) => i.id == id);
    if (indice == -1) return;
    final anterior = itens[indice];
    if (anterior.nome == novoNome) return;

    setState(() {
      itens[indice] = anterior.copyWith(nome: novoNome);
    });
    aoPersistir();

    registrarAcao(
      TipoAcao.itemAtualizado,
      'Item "${anterior.nome}" renomeado para "$novoNome"',
    );
  }

  void editarPrecoItem(String id, String novoPreco) {
    if (!podeEditarAbaLoja()) return;
    final itens = obterItens();
    final indice = itens.indexWhere((i) => i.id == id);
    if (indice == -1) return;
    final anterior = itens[indice];
    if (anterior.preco == novoPreco) return;

    setState(() {
      itens[indice] = anterior.copyWith(preco: novoPreco);
    });
    aoPersistir();

    registrarAcao(
      TipoAcao.itemAtualizado,
      'Preço de "${anterior.nome}" alterado de '
      'R\$ ${anterior.preco} para R\$ $novoPreco',
    );
  }

  Future<void> removerItem(String id) async {
    if (!podeEditarAbaLoja()) {
      avisarSemPermissao();
      return;
    }

    final itens = obterItens();
    final categorias = obterCategorias();
    final grupos = obterGrupos();

    final indice = itens.indexWhere((i) => i.id == id);
    final nome = indice == -1 ? '' : itens[indice].nome;

    final confirmou = await confirmarExclusao(
      titulo: 'Excluir Item',
      mensagem:
          'Tem certeza que deseja excluir o item "$nome"? Essa ação não pode ser desfeita.',
    );
    if (!confirmou) return;

    setState(() {
      itens.removeWhere((item) => item.id == id);

      for (var i = 0; i < categorias.length; i++) {
        if (categorias[i].itemIds.contains(id)) {
          categorias[i] = categorias[i].copyWith(
            itemIds: categorias[i].itemIds
                .where((itemId) => itemId != id)
                .toList(),
          );
        }
      }

      for (var i = 0; i < grupos.length; i++) {
        if (grupos[i].itemIds.contains(id)) {
          grupos[i] = grupos[i].copyWith(
            itemIds: grupos[i].itemIds.where((itemId) => itemId != id).toList(),
          );
        }
      }
    });
    aoPersistir();

    registrarAcao(TipoAcao.itemExcluido, 'Item "$nome" excluído');
  }

  void abrirPopupNovaCategoria() {
    if (!podeEditarAbaLoja()) {
      avisarSemPermissao();
      return;
    }

    final categorias = obterCategorias();
    final grupos = obterGrupos();

    NovaCategoriaDialog.mostrar(
      context,
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
      context,
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

  void abrirPopupNovoGrupoComponentes() {
    if (!podeEditarAbaLoja()) {
      avisarSemPermissao();
      return;
    }

    final grupos = obterGrupos();
    final itens = obterItens();

    NovoGrupoComponentesDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      itensDisponiveis: itens,
      onCriar: (grupo) {
        setState(() => grupos.add(grupo));
        aoPersistir();

        registrarAcao(
          TipoAcao.grupoCriado,
          'Grupo de componentes "${grupo.nome}" criado',
        );
      },
    );
  }

  void abrirPopupEditarGrupoComponentes(GrupoComponentesLoja grupo) {
    if (!podeEditarAbaLoja()) {
      avisarSemPermissao();
      return;
    }

    final grupos = obterGrupos();
    final itens = obterItens();

    NovoGrupoComponentesDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      itensDisponiveis: itens,
      grupoParaEditar: grupo,
      onCriar: (grupoEditado) {
        setState(() {
          final indice = grupos.indexWhere((g) => g.id == grupoEditado.id);
          if (indice != -1) grupos[indice] = grupoEditado;
        });
        aoPersistir();

        registrarAcao(
          TipoAcao.grupoAtualizado,
          'Grupo de componentes "${grupoEditado.nome}" atualizado',
        );
      },
    );
  }

  void editarNomeGrupoComponentes(String id, String novoNome) {
    if (!podeEditarAbaLoja()) return;
    final grupos = obterGrupos();
    final indice = grupos.indexWhere((g) => g.id == id);
    if (indice == -1) return;
    final anterior = grupos[indice];
    if (anterior.nome == novoNome) return;

    setState(() {
      grupos[indice] = anterior.copyWith(nome: novoNome);
    });
    aoPersistir();

    registrarAcao(
      TipoAcao.grupoAtualizado,
      'Grupo de componentes "${anterior.nome}" renomeado para "$novoNome"',
    );
  }

  Future<void> removerGrupoComponentes(String id) async {
    if (!podeEditarAbaLoja()) {
      avisarSemPermissao();
      return;
    }

    final grupos = obterGrupos();
    final categorias = obterCategorias();
    final indice = grupos.indexWhere((g) => g.id == id);
    final nome = indice == -1 ? '' : grupos[indice].nome;

    final confirmou = await confirmarExclusao(
      titulo: 'Excluir Grupo',
      mensagem:
          'Tem certeza que deseja excluir o grupo de componentes "$nome"? Essa ação não pode ser desfeita.',
    );
    if (!confirmou) return;

    setState(() {
      grupos.removeWhere((grupo) => grupo.id == id);
      if (obterGrupoExpandidoId() == id) {
        definirGrupoExpandidoId(null);
      }

      for (var i = 0; i < categorias.length; i++) {
        if (categorias[i].grupoIds.contains(id)) {
          categorias[i] = categorias[i].copyWith(
            grupoIds: categorias[i].grupoIds.where((gId) => gId != id).toList(),
          );
        }
      }
    });
    aoPersistir();

    registrarAcao(
      TipoAcao.grupoExcluido,
      'Grupo de componentes "$nome" excluído',
    );
  }

  void adicionarItemNoGrupoComponentes(
    GrupoComponentesLoja grupo,
    String itemId,
  ) {
    if (!podeEditarAbaLoja()) return;
    final grupos = obterGrupos();
    final itens = obterItens();

    setState(() {
      final indice = grupos.indexWhere((g) => g.id == grupo.id);
      if (indice == -1) return;
      final novosIds = [...grupo.itemIds, itemId];
      grupos[indice] = grupo.copyWith(itemIds: novosIds);
    });
    aoPersistir();

    final itemIndice = itens.indexWhere((i) => i.id == itemId);
    final nomeItem = itemIndice == -1 ? '' : itens[itemIndice].nome;

    registrarAcao(
      TipoAcao.itemVinculadoGrupo,
      'Item "$nomeItem" vinculado ao grupo "${grupo.nome}"',
    );
  }

  void removerItemDoGrupoComponentes(
    GrupoComponentesLoja grupo,
    String itemId,
  ) {
    if (!podeEditarAbaLoja()) return;
    final grupos = obterGrupos();
    final itens = obterItens();

    setState(() {
      final indice = grupos.indexWhere((g) => g.id == grupo.id);
      if (indice == -1) return;
      final novosIds = grupo.itemIds.where((id) => id != itemId).toList();
      grupos[indice] = grupo.copyWith(itemIds: novosIds);
    });
    aoPersistir();

    final itemIndice = itens.indexWhere((i) => i.id == itemId);
    final nomeItem = itemIndice == -1 ? '' : itens[itemIndice].nome;

    registrarAcao(
      TipoAcao.itemDesvinculadoGrupo,
      'Item "$nomeItem" desvinculado do grupo "${grupo.nome}"',
    );
  }
}
