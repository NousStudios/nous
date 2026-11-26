import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/busca/controllers/helpers/busca_mapa_modelos.dart';
import 'package:nous/src/features/compras/services/carrinho_compras_service.dart';
import 'package:nous/src/features/compras/services/helpers/efeito_pacote_carrinho_helper.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

/// Diálogo centralizado (padrão Nous, sem Bottom Sheet) para escolher variações,
/// acompanhamentos/adicionais e quantidade antes de empacotar e enviar ao Carrinho.
class DialogAdicionarCarrinhoVariantes extends StatefulWidget {
  final ProdutoMapaItem produto;
  final AppTheme theme;
  final PdvProvider pdv;

  const DialogAdicionarCarrinhoVariantes({
    super.key,
    required this.produto,
    required this.theme,
    required this.pdv,
  });

  @override
  State<DialogAdicionarCarrinhoVariantes> createState() =>
      _DialogAdicionarCarrinhoVariantesState();
}

class _DialogAdicionarCarrinhoVariantesState
    extends State<DialogAdicionarCarrinhoVariantes> {
  final GlobalKey _chaveDialogo = GlobalKey();
  VarianteItem? _varianteSelecionada;
  final Map<String, int> _qtdAcompanhamentos = {};
  late final List<GrupoComponentesLoja> _gruposDoItem;
  int _quantidade = 1;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final item = widget.produto.item;
    final loja = widget.produto.loja;
    if (item.variantes.isNotEmpty) {
      _varianteSelecionada = item.variantes.first;
    }

    // Descobre os grupos de componentes/acompanhamentos vinculados à categoria do item
    final grupoIds = <String>{};
    for (final cat in loja.categoriasLoja) {
      if (cat.itemIds.contains(item.id)) {
        grupoIds.addAll(cat.grupoIds);
      }
    }
    _gruposDoItem = loja.gruposComponentesLoja
        .where((g) => grupoIds.contains(g.id))
        .toList();
  }

  double get _precoBaseUnitario {
    if (_varianteSelecionada != null) {
      final pv = CarrinhoComprasService.parsePreco(_varianteSelecionada!.preco);
      if (pv > 0) return pv;
    }
    return CarrinhoComprasService.parsePreco(widget.produto.item.preco);
  }

  double get _somaAcompanhamentos {
    double soma = 0.0;
    final todosItens = widget.produto.loja.itensLoja;
    for (final entry in _qtdAcompanhamentos.entries) {
      if (entry.value <= 0) continue;
      final comp = todosItens.where((i) => i.id == entry.key).firstOrNull;
      if (comp != null) {
        soma += CarrinhoComprasService.parsePreco(comp.preco) * entry.value;
      }
    }
    return soma;
  }

  double get _subtotal => (_precoBaseUnitario + _somaAcompanhamentos) * _quantidade;

  List<AcompanhamentoEscolhido> _montarListaAcompanhamentos() {
    final lista = <AcompanhamentoEscolhido>[];
    final todosItens = widget.produto.loja.itensLoja;
    for (final entry in _qtdAcompanhamentos.entries) {
      if (entry.value <= 0) continue;
      final comp = todosItens.where((i) => i.id == entry.key).firstOrNull;
      if (comp != null) {
        lista.add(
          AcompanhamentoEscolhido(
            itemId: comp.id,
            nomeItem: comp.nome,
            precoItem: CarrinhoComprasService.parsePreco(comp.preco),
            quantidadePorUnidade: entry.value,
          ),
        );
      }
    }
    return lista;
  }

  Future<void> _confirmarEEnviarPacote() async {
    if (_salvando) return;
    setState(() => _salvando = true);

    final box = _chaveDialogo.currentContext?.findRenderObject() as RenderBox?;
    final media = MediaQuery.sizeOf(context);
    final origem = (box != null && box.hasSize)
        ? box.localToGlobal(Offset(box.size.width / 2, box.size.height / 2))
        : Offset(media.width / 2, media.height / 2);

    final ok = await CarrinhoComprasService.adicionarProduto(
      pdv: widget.pdv,
      loja: widget.produto.loja,
      item: widget.produto.item,
      variante: _varianteSelecionada,
      acompanhamentos: _montarListaAcompanhamentos(),
      quantidade: _quantidade,
    );

    if (!mounted) return;
    final fotoUrl = widget.produto.item.imagens.isNotEmpty
        ? widget.produto.item.imagens.first
        : '';

    Navigator.of(context).pop();

    if (ok) {
      EfeitoPacoteCarrinhoHelper.dispararAnimacaoPacote(
        context: context,
        origemGlobal: origem,
        theme: widget.theme,
        fotoUrl: fotoUrl,
        nomeItem: widget.produto.item.nome,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final item = widget.produto.item;
    final loja = widget.produto.loja;
    final fotoUrl = item.imagens.isNotEmpty ? item.imagens.first : '';
    final variantes = item.variantes;

    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.borderColor),
      ),
      child: ConstrainedBox(
        key: _chaveDialogo,
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: MediaQuery.sizeOf(context).height * 0.90,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Foto centralizada (conforme Print 4)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 130,
                  height: 130,
                  child: ImagemService.construirImagem(
                    fotoUrl,
                    fit: BoxFit.cover,
                    fallback: Container(
                      color: theme.backgroundColor.withValues(alpha: 0.6),
                      child: Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: theme.secondaryTextColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Nome e curta descrição
              Text(
                item.nome,
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              if (item.descricao.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.descricao,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Variações (se o produto possuir)
              if (variantes.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Variações',
                    style: theme.getTextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: variantes.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final v = variantes[i];
                      final ativa = _varianteSelecionada?.nome == v.nome;
                      return ChoiceChip(
                        label: Text(
                          v.preco.trim().isNotEmpty
                              ? '${v.nome} • R\$ ${v.preco}'
                              : v.nome,
                          style: theme.getTextStyle(
                            fontSize: 12,
                            fontWeight:
                                ativa ? FontWeight.bold : FontWeight.normal,
                            color: ativa
                                ? theme.buttonTextColor
                                : theme.textColor,
                          ),
                        ),
                        selected: ativa,
                        selectedColor: theme.buttonColor,
                        backgroundColor:
                            theme.backgroundColor.withValues(alpha: 0.5),
                        side: BorderSide(color: theme.borderColor),
                        onSelected: (_) =>
                            setState(() => _varianteSelecionada = v),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Acompanhamentos / Componentes (quando configurados na categoria do item)
              if (_gruposDoItem.isNotEmpty) ...[
                for (final grupo in _gruposDoItem) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      grupo.nome,
                      style: theme.getTextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...grupo.itemIds.map((compId) {
                    final comp = loja.itensLoja
                        .where((x) => x.id == compId)
                        .firstOrNull;
                    if (comp == null) return const SizedBox.shrink();
                    final qtdComp = _qtdAcompanhamentos[comp.id] ?? 0;
                    final precoComp =
                        CarrinhoComprasService.parsePreco(comp.preco);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.backgroundColor.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: qtdComp > 0
                              ? theme.buttonColor
                              : theme.borderColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comp.nome,
                                  style: theme.getTextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textColor,
                                  ),
                                ),
                                Text(
                                  precoComp > 0
                                      ? '+ R\$ ${precoComp.toStringAsFixed(2).replaceAll('.', ',')}'
                                      : 'Incluso',
                                  style: theme.getTextStyle(
                                    fontSize: 10.5,
                                    color: theme.secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: qtdComp > 0
                                ? () => setState(() =>
                                    _qtdAcompanhamentos[comp.id] = qtdComp - 1)
                                : null,
                            icon: Icon(
                              Icons.remove_circle_outline,
                              size: 18,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                          Text(
                            '$qtdComp',
                            style: theme.getTextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () => setState(() =>
                                _qtdAcompanhamentos[comp.id] = qtdComp + 1),
                            icon: Icon(
                              Icons.add_circle_outline,
                              size: 18,
                              color: theme.textColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                ],
              ],

              // Quantidade
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Quantidade',
                  style: theme.getTextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.backgroundColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: _quantidade > 1
                          ? () => setState(() => _quantidade--)
                          : null,
                      icon: Icon(
                        Icons.remove_rounded,
                        color: theme.textColor,
                        size: 20,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        '$_quantidade',
                        style: theme.getTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _quantidade++),
                      icon: Icon(
                        Icons.add_rounded,
                        color: theme.textColor,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Rodapé: Valor + Botão Adicionar ao Carrinho
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Valor total',
                        style: theme.getTextStyle(
                          fontSize: 11,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                      Text(
                        'R\$ ${_subtotal.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: theme.getTextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancelar',
                          style: theme.getTextStyle(
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.buttonColor,
                          foregroundColor: theme.buttonTextColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _salvando ? null : _confirmarEEnviarPacote,
                        icon: const Icon(
                          Icons.add_shopping_cart_rounded,
                          size: 18,
                        ),
                        label: Text(
                          _salvando ? 'Enviando...' : 'Adicionar',
                          style: theme.getTextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.buttonTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
