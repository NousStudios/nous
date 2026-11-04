import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/modelos_nova_venda.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

class BlocoProdutosNovaVendaWidget extends StatelessWidget {
  final AppTheme theme;
  final TextEditingController buscaController;
  final FocusNode buscaFocusNode;
  final bool buscaFocada;
  final ValueChanged<bool> onBuscaFocadaChanged;
  final ValueChanged<String> onSubmeterBusca;
  final VoidCallback onAbrirNovoProduto;
  final List<CategoriaLoja> categoriasEncontradas;
  final List<ItemLoja> itensEncontrados;
  final List<CategoriaLoja> todasCategorias;
  final List<ItemLoja> todosItens;
  final List<LinhaCarrinho> carrinho;
  final double Function(String itemId) saldoDoItem;
  final String Function(LinhaCarrinho linha) nomeExibicaoLinha;
  final double Function(LinhaCarrinho linha) precoBaseUnitarioDaLinha;
  final double Function(LinhaCarrinho linha) subtotalBaseDaLinha;
  final String Function(LinhaCarrinho linha) resumoAcompanhamentos;
  final List<GrupoComponentesLoja> Function(LinhaCarrinho linha) gruposDaCategoria;
  final ItemLoja? Function(String itemId) buscarItem;
  final void Function(CategoriaLoja categoria) onSelecionarCategoriaNaBusca;
  final void Function(ItemLoja item) onSelecionarItemNaBusca;
  final void Function(String chave, int variacao) onAlterarQuantidade;
  final void Function(String chave) onEditarAcompanhamentos;
  final BoxDecoration decoracaoDoBloco;
  final InputDecoration Function(String dica) decoracaoCampo;
  final Widget Function(String texto) tituloDoBloco;
  final Widget Function(String rotulo, VoidCallback aoPressionar) botaoPequeno;
  final String Function(double valor) valorComVirgula;
  final double Function(String texto) precoComoNumero;

  const BlocoProdutosNovaVendaWidget({
    super.key,
    required this.theme,
    required this.buscaController,
    required this.buscaFocusNode,
    required this.buscaFocada,
    required this.onBuscaFocadaChanged,
    required this.onSubmeterBusca,
    required this.onAbrirNovoProduto,
    required this.categoriasEncontradas,
    required this.itensEncontrados,
    required this.todasCategorias,
    required this.todosItens,
    required this.carrinho,
    required this.saldoDoItem,
    required this.nomeExibicaoLinha,
    required this.precoBaseUnitarioDaLinha,
    required this.subtotalBaseDaLinha,
    required this.resumoAcompanhamentos,
    required this.gruposDaCategoria,
    required this.buscarItem,
    required this.onSelecionarCategoriaNaBusca,
    required this.onSelecionarItemNaBusca,
    required this.onAlterarQuantidade,
    required this.onEditarAcompanhamentos,
    required this.decoracaoDoBloco,
    required this.decoracaoCampo,
    required this.tituloDoBloco,
    required this.botaoPequeno,
    required this.valorComVirgula,
    required this.precoComoNumero,
  });

  bool get _temResultadoDeBusca =>
      categoriasEncontradas.isNotEmpty || itensEncontrados.isNotEmpty;

  Widget _linhaDeCategoriaNaBusca(CategoriaLoja categoria) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onSelecionarCategoriaNaBusca(categoria),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            if (ImagemService.resolverCaminhoExistente(categoria.foto) != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(
                  File(ImagemService.resolverCaminhoExistente(categoria.foto)!),
                  width: 18,
                  height: 18,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.category_outlined,
                    size: 16,
                    color: theme.secondaryTextColor,
                  ),
                ),
              )
            else
              Icon(Icons.category_outlined,
                  size: 16, color: theme.secondaryTextColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Categoria: ${categoria.nome}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linhaDeResultado(ItemLoja item) {
    final fotoResolvida = item.imagens.isNotEmpty
        ? ImagemService.resolverCaminhoExistente(item.imagens.first)
        : null;
    final temFoto = fotoResolvida != null;
    return InkWell(
      onTap: () => onSelecionarItemNaBusca(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            temFoto
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(
                      File(fotoResolvida),
                      width: 18,
                      height: 18,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  )
                : Icon(
                    Icons.inventory_2_outlined,
                    size: 16,
                    color: theme.secondaryTextColor,
                  ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
                  ),
                  Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (item.codigoBarras.trim().isNotEmpty)
                        Text(
                          'Cód: ${item.codigoBarras.trim()}',
                          style: theme.getTextStyle(
                            fontSize: 10,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      if (item.tipo != TipoItemLoja.servico)
                        Builder(
                          builder: (context) {
                            final saldo = saldoDoItem(item.id);
                            final unidade = item.unidadeBase.name;
                            return Text(
                              saldo <= 0
                                  ? 'Esgotado'
                                  : 'Est: ${saldo.toStringAsFixed(saldo % 1 == 0 ? 0 : 2)} $unidade',
                              style: theme.getTextStyle(
                                fontSize: 10,
                                color: saldo <= 0
                                    ? theme.dangerColor
                                    : theme.secondaryTextColor,
                                fontWeight: saldo <= 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              'R\$ ${valorComVirgula(precoComoNumero(item.preco))}',
              style: theme.getTextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linhaDoItemSelecionado(LinhaCarrinho linha) {
    final grupos = gruposDaCategoria(linha);
    final temGrupos = grupos.isNotEmpty;
    final acompanhamentos = linha.acompanhamentosPorItemId;
    final subtotalBase = subtotalBaseDaLinha(linha);
    final precoBase = precoBaseUnitarioDaLinha(linha);

    final itemOriginal = buscarItem(linha.itemId);
    final fotoResolvida =
        (itemOriginal != null && itemOriginal.imagens.isNotEmpty)
            ? ImagemService.resolverCaminhoExistente(itemOriginal.imagens.first)
            : null;
    final temFoto = fotoResolvida != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (temFoto) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.file(
                    File(fotoResolvida),
                    width: 20,
                    height: 20,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  nomeExibicaoLinha(linha),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.textColor,
                  ),
                ),
              ),
              Text(
                'R\$ ${valorComVirgula(precoBase)}',
                style: theme.getTextStyle(fontSize: 11),
              ),
              const SizedBox(width: 6),
              IconButton(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(Icons.remove, size: 18, color: theme.textColor),
                onPressed: () => onAlterarQuantidade(linha.chave, -1),
              ),
              Text('${linha.quantidade}',
                  style: theme.getTextStyle(fontSize: 12)),
              IconButton(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(Icons.add, size: 18, color: theme.textColor),
                onPressed: () => onAlterarQuantidade(linha.chave, 1),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 60),
                child: Text(
                  'R\$ ${valorComVirgula(subtotalBase)}',
                  textAlign: TextAlign.right,
                  style: theme.getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 2),
            child: Row(
              children: [
                Expanded(
                  child: acompanhamentos.isEmpty
                      ? (temGrupos
                          ? Text(
                              'sem acompanhamentos',
                              style: theme.getTextStyle(
                                fontSize: 10,
                                color: theme.secondaryTextColor,
                              ),
                            )
                          : const SizedBox.shrink())
                      : Text(
                          resumoAcompanhamentos(linha),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 10,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                ),
                if (temGrupos)
                  TextButton(
                    onPressed: () => onEditarAcompanhamentos(linha.chave),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Editar acompanhamentos',
                      style: theme.getTextStyle(fontSize: 10),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4, right: 4),
            child: TextField(
              controller: linha.observacaoController,
              cursorColor: theme.textColor,
              style: theme.getTextStyle(fontSize: 11),
              decoration: decoracaoCampo('Observação do item'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categorias = categoriasEncontradas;
    final itens = itensEncontrados;
    final buscando = buscaController.text.trim().isNotEmpty;
    final mostrarResultados = buscaFocada || buscando;

    return TapRegion(
      groupId: 'busca_produto',
      onTapOutside: (_) {
        if (buscaFocada) {
          onBuscaFocadaChanged(false);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: decoracaoDoBloco,
        child: Column(
          children: [
            tituloDoBloco('Produto Solicitado'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: buscaController,
                    focusNode: buscaFocusNode,
                    cursorColor: theme.textColor,
                    style: theme.getTextStyle(fontSize: 12),
                    decoration:
                        decoracaoCampo('Pesquisar nome ou bipar código de barras'),
                    onTap: () => onBuscaFocadaChanged(true),
                    onSubmitted: onSubmeterBusca,
                  ),
                ),
                const SizedBox(width: 8),
                botaoPequeno('Novo Produto', onAbrirNovoProduto),
              ],
            ),
            if (mostrarResultados) ...[
              if (buscando) ...[
                const SizedBox(height: 8),
                if (!_temResultadoDeBusca)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      todosItens.isEmpty && todasCategorias.isEmpty
                          ? 'Nenhum item ou categoria criado na aba Loja ainda.'
                          : 'Nenhum resultado.',
                      style: theme.getTextStyle(fontSize: 11),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (final categoria in categorias)
                            _linhaDeCategoriaNaBusca(categoria),
                          for (final item in itens) _linhaDeResultado(item),
                        ],
                      ),
                    ),
                  ),
              ] else if (todasCategorias.isNotEmpty) ...[
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final categoria in todasCategorias)
                          _linhaDeCategoriaNaBusca(categoria),
                      ],
                    ),
                  ),
                ),
              ],
            ],
            if (carrinho.isNotEmpty) ...[
              const SizedBox(height: 8),
              Divider(color: theme.borderColor.withValues(alpha: 0.6)),
              for (final linha in carrinho) _linhaDoItemSelecionado(linha),
            ],
          ],
        ),
      ),
    );
  }
}
