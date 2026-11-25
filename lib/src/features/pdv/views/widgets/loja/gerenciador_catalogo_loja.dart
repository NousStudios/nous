import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/helpers/catalogo_categorias_helper.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/helpers/catalogo_grupos_componentes_helper.dart';
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

  late final CatalogoCategoriasHelper _categoriasHelper =
      CatalogoCategoriasHelper(
        obterContext: obterContext,
        obterItens: obterItens,
        obterCategorias: obterCategorias,
        obterGrupos: obterGrupos,
        podeEditarAbaLoja: podeEditarAbaLoja,
        avisarSemPermissao: avisarSemPermissao,
        setState: setState,
        aoPersistir: aoPersistir,
        registrarAcao: registrarAcao,
        confirmarExclusao: confirmarExclusao,
        obterCategoriaExpandidaId: obterCategoriaExpandidaId,
        definirCategoriaExpandidaId: definirCategoriaExpandidaId,
      );

  late final CatalogoGruposComponentesHelper _gruposHelper =
      CatalogoGruposComponentesHelper(
        obterContext: obterContext,
        obterItens: obterItens,
        obterCategorias: obterCategorias,
        obterGrupos: obterGrupos,
        podeEditarAbaLoja: podeEditarAbaLoja,
        avisarSemPermissao: avisarSemPermissao,
        setState: setState,
        aoPersistir: aoPersistir,
        registrarAcao: registrarAcao,
        confirmarExclusao: confirmarExclusao,
        obterGrupoExpandidoId: obterGrupoExpandidoId,
        definirGrupoExpandidoId: definirGrupoExpandidoId,
      );

  double _parseCustoUnitario(String precoCusto) {
    final texto = precoCusto.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(texto) ?? 0.0;
  }

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
          final mov = MovimentoEstoque.novo(
            itemId: item.id,
            tipo: TipoMovimentoEstoque.entrada,
            quantidade: estoqueInicialInformado!,
            custoUnitario: _parseCustoUnitario(item.precoCusto),
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
            final mov = MovimentoEstoque.novo(
              itemId: itemEditado.id,
              tipo: delta > 0
                  ? TipoMovimentoEstoque.entrada
                  : TipoMovimentoEstoque.saida,
              quantidade: delta.abs(),
              custoUnitario: _parseCustoUnitario(itemEditado.precoCusto),
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

  void abrirPopupNovaCategoria() => _categoriasHelper.abrirPopupNovaCategoria();

  void abrirPopupEditarCategoria(CategoriaLoja categoria) =>
      _categoriasHelper.abrirPopupEditarCategoria(categoria);

  void editarNomeCategoria(String id, String novoNome) =>
      _categoriasHelper.editarNomeCategoria(id, novoNome);

  Future<void> removerCategoria(String id) =>
      _categoriasHelper.removerCategoria(id);

  void adicionarItemNaCategoria(CategoriaLoja categoria, String itemId) =>
      _categoriasHelper.adicionarItemNaCategoria(categoria, itemId);

  void removerItemDaCategoria(CategoriaLoja categoria, String itemId) =>
      _categoriasHelper.removerItemDaCategoria(categoria, itemId);

  void abrirPopupNovoGrupoComponentes() =>
      _gruposHelper.abrirPopupNovoGrupoComponentes();

  void abrirPopupEditarGrupoComponentes(GrupoComponentesLoja grupo) =>
      _gruposHelper.abrirPopupEditarGrupoComponentes(grupo);

  void editarNomeGrupoComponentes(String id, String novoNome) =>
      _gruposHelper.editarNomeGrupoComponentes(id, novoNome);

  Future<void> removerGrupoComponentes(String id) =>
      _gruposHelper.removerGrupoComponentes(id);

  void adicionarItemNoGrupoComponentes(
    GrupoComponentesLoja grupo,
    String itemId,
  ) => _gruposHelper.adicionarItemNoGrupoComponentes(grupo, itemId);

  void removerItemDoGrupoComponentes(
    GrupoComponentesLoja grupo,
    String itemId,
  ) => _gruposHelper.removerItemDoGrupoComponentes(grupo, itemId);
}
