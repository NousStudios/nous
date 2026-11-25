import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/services/som_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/modelos_nova_venda.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/dialogs/dialog_editar_acompanhamentos.dart';
import 'package:nous/src/features/pdv/views/dialogs/dialog_escolher_variante_item.dart';
import 'package:nous/src/features/pdv/views/dialogs/dialog_seletor_item_categoria.dart';
import 'package:nous/src/features/pdv/views/widgets/novo_item_dialog.dart';

/// Operações sobre o carrinho, montagem de chaves, acompanhamentos e diálogos de item.
class NovaVendaCarrinhoHelper {
  const NovaVendaCarrinhoHelper._();

  /// Monta a chave única da linha no carrinho considerando categoria e variante.
  static String montarChave({
    required String itemId,
    required String prefixoItem,
    required String prefixoCategoria,
    String? categoriaId,
    String varianteNome = '',
  }) {
    var base = categoriaId == null
        ? '$prefixoItem$itemId'
        : '$prefixoCategoria$categoriaId|$prefixoItem$itemId';
    if (varianteNome.trim().isNotEmpty) {
      base = '$base|var:${varianteNome.trim()}';
    }
    return base;
  }

  /// Lista os grupos de componentes associados à categoria da linha.
  static List<GrupoComponentesLoja> gruposDaCategoria({
    required LinhaCarrinho linha,
    required CategoriaLoja? Function(String id) buscarCategoria,
    required GrupoComponentesLoja? Function(String id) buscarGrupo,
  }) {
    final categoriaId = linha.categoriaId;
    if (categoriaId == null) return [];
    final categoria = buscarCategoria(categoriaId);
    if (categoria == null) return [];
    return categoria.grupoIds
        .map((id) => buscarGrupo(id))
        .whereType<GrupoComponentesLoja>()
        .toList();
  }

  /// Monta o nome de exibição da linha com categoria e variante quando presentes.
  static String nomeExibicaoDaLinha({
    required LinhaCarrinho linha,
    required ItemLoja? Function(String id) buscarItem,
    required CategoriaLoja? Function(String id) buscarCategoria,
  }) {
    final item = buscarItem(linha.itemId);
    if (item == null) return 'Item removido';
    final base = linha.categoriaId == null
        ? item.nome
        : '${buscarCategoria(linha.categoriaId!)?.nome ?? ''} ${item.nome}'.trim();
    if (linha.varianteNome.trim().isNotEmpty) {
      return '$base (${linha.varianteNome.trim()})';
    }
    return base;
  }

  /// Localiza uma linha do carrinho pela chave.
  static LinhaCarrinho? linhaPorChave(List<LinhaCarrinho> carrinho, String chave) {
    for (final linha in carrinho) {
      if (linha.chave == chave) return linha;
    }
    return null;
  }

  /// Adiciona um item ou incrementa sua quantidade no carrinho e dispara o som de venda.
  static void adicionarLinhaAoCarrinho({
    required List<LinhaCarrinho> carrinho,
    required String chave,
    required String itemId,
    String? categoriaId,
    String varianteNome = '',
    String precoVariante = '',
    String? lojaId,
    BuildContext? context,
  }) {
    final existente = linhaPorChave(carrinho, chave);
    if (existente != null) {
      existente.quantidade++;
    } else {
      carrinho.add(LinhaCarrinho(
        chave: chave,
        itemId: itemId,
        categoriaId: categoriaId,
        varianteNome: varianteNome,
        precoVariante: precoVariante,
      ));
    }

    if (context != null) {
      try {
        final loja = lojaId != null
            ? context.read<PdvProvider>().buscarPorId(lojaId)
            : null;
        SomService.tocarEvento(SomService.eventoBipVenda, loja: loja);
      } catch (_) {}
    }
  }

  /// Altera a quantidade da linha no carrinho, removendo-a se chegar a zero ou menos.
  static void alterarQuantidade({
    required List<LinhaCarrinho> carrinho,
    required String chave,
    required int variacao,
  }) {
    final linha = linhaPorChave(carrinho, chave);
    if (linha == null) return;
    final nova = linha.quantidade + variacao;
    if (nova <= 0) {
      linha.dispose();
      carrinho.remove(linha);
    } else {
      linha.quantidade = nova;
    }
  }

  /// Resolve variante (quando houver) e delega a adição do item ao carrinho.
  static Future<void> processarAdicaoItemAoCarrinho({
    required ItemLoja? item,
    required String itemId,
    String? categoriaId,
    required BuildContext context,
    required AppTheme theme,
    required void Function({
      required String itemId,
      String? categoriaId,
      String varianteNome,
      String precoVariante,
      BuildContext? context,
    }) onAdicionarLinha,
  }) async {
    if (item == null) return;
    if (item.variantes.isNotEmpty) {
      final varianteEscolhida = await DialogEscolherVarianteItem.mostrar(
        context,
        theme: theme,
        item: item,
      );
      if (varianteEscolhida == null || !context.mounted) return;
      onAdicionarLinha(
        itemId: itemId,
        categoriaId: categoriaId,
        varianteNome: varianteEscolhida.nome,
        precoVariante: varianteEscolhida.preco,
        context: context,
      );
    } else {
      if (!context.mounted) return;
      onAdicionarLinha(
        itemId: itemId,
        categoriaId: categoriaId,
        context: context,
      );
    }
  }

  /// Abre o diálogo de acompanhamentos da linha e aplica as seleções confirmadas.
  static Future<bool> editarAcompanhamentosDaLinha({
    required LinhaCarrinho? linha,
    required BuildContext context,
    required AppTheme theme,
    required List<GrupoComponentesLoja> grupos,
    required ItemLoja? Function(String id) buscarItem,
    required void Function(String texto) onMostrarAviso,
  }) async {
    if (linha == null) return false;
    if (grupos.isEmpty) {
      onMostrarAviso('Esta categoria nao tem grupos de componentes associados.');
      return false;
    }

    final selecionados = await DialogEditarAcompanhamentos.mostrar(
      context,
      theme: theme,
      grupos: grupos,
      selecionadosIniciais: linha.acompanhamentosPorItemId,
      buscarItem: buscarItem,
    );

    if (selecionados != null) {
      linha.acompanhamentosPorItemId
        ..clear()
        ..addAll(selecionados);
      return true;
    }
    return false;
  }

  /// Abre o seletor de item de uma categoria e encaminha a seleção para o carrinho.
  static void abrirSeletorDeItemDaCategoria({
    required CategoriaLoja categoria,
    required BuildContext context,
    required AppTheme theme,
    required ItemLoja? Function(String id) buscarItem,
    required VoidCallback onLimparBusca,
    required Future<void> Function(ItemLoja item) onSelecionar,
  }) {
    DialogSeletorItemCategoria.mostrar(
      context,
      theme: theme,
      categoria: categoria,
      buscarItem: buscarItem,
      onSelecionarItem: (item) {
        onLimparBusca();
        onSelecionar(item);
      },
    );
  }

  /// Abre o diálogo de criação rápida de produto durante a venda.
  static Future<void> abrirNovoProduto({
    required BuildContext context,
    required AppTheme theme,
    required List<CategoriaLoja> categoriasDisponiveis,
    required List<GrupoComponentesLoja> gruposDisponiveis,
    required bool expandido,
    required Future<void> Function(
      ItemLoja item,
      List<String> categoriaIds,
      List<String> grupoIds, [
      double? estoqueInicial,
    ]) aoCriarItem,
  }) async {
    double? estoqueInicialInformado;
    await NovoItemDialog.mostrar(
      context,
      theme: theme,
      categorias: categoriasDisponiveis,
      gruposComponentes: gruposDisponiveis,
      layoutExpandido: expandido,
      onEstoqueAjustado: (novoSaldo) {
        estoqueInicialInformado = novoSaldo;
      },
      onCriar: (item, categoriaIds, grupoIds) async {
        await aoCriarItem(
          item,
          categoriaIds,
          grupoIds,
          estoqueInicialInformado,
        );
      },
    );
  }

  /// Libera os recursos das listas de carrinho e pagamentos.
  static void disporListas({
    required List<LinhaCarrinho> carrinho,
    required List<LinhaPagamento> pagamentos,
  }) {
    for (final linha in carrinho) {
      linha.dispose();
    }
    for (final pagamento in pagamentos) {
      pagamento.dispose();
    }
  }

  /// Limpa carrinho, pagamentos e campos de texto da venda atual.
  static void limparTudo({
    required List<LinhaCarrinho> carrinho,
    required List<LinhaPagamento> pagamentos,
    required List<TextEditingController> controllers,
  }) {
    disporListas(carrinho: carrinho, pagamentos: pagamentos);
    carrinho.clear();
    pagamentos.clear();
    for (final controller in controllers) {
      controller.clear();
    }
  }
}
