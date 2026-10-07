import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nous/src/core/services/gerador_id.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

double _precoComoNumero(String texto) {
  var limpo = texto.replaceAll(RegExp(r'[^0-9,.]'), '');
  if (limpo.contains(',')) {
    limpo = limpo.replaceAll('.', '').replaceAll(',', '.');
  }
  return double.tryParse(limpo) ?? 0;
}

String _valorFormatado(double valor) =>
    'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

class AdicionarItemMesaDialog extends StatefulWidget {
  final AppTheme theme;
  final List<CategoriaLoja> categoriasDisponiveis;
  final List<ItemLoja> itensDisponiveis;
  final List<GrupoComponentesLoja> gruposDisponiveis;
  final String autorCpf;
  final String autorNome;
  final ValueChanged<ItemComandaMesa> aoAdicionar;

  const AdicionarItemMesaDialog({
    super.key,
    required this.theme,
    this.categoriasDisponiveis = const [],
    required this.itensDisponiveis,
    this.gruposDisponiveis = const [],
    required this.autorCpf,
    required this.autorNome,
    required this.aoAdicionar,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    List<CategoriaLoja> categoriasDisponiveis = const [],
    required List<ItemLoja> itensDisponiveis,
    List<GrupoComponentesLoja> gruposDisponiveis = const [],
    required String autorCpf,
    required String autorNome,
    required ValueChanged<ItemComandaMesa> aoAdicionar,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: theme.cardBackgroundColor,
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 660),
            child: AdicionarItemMesaDialog(
              theme: theme,
              categoriasDisponiveis: categoriasDisponiveis,
              itensDisponiveis: itensDisponiveis,
              gruposDisponiveis: gruposDisponiveis,
              autorCpf: autorCpf,
              autorNome: autorNome,
              aoAdicionar: (item) {
                Navigator.of(dialogContext).pop();
                aoAdicionar(item);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  State<AdicionarItemMesaDialog> createState() =>
      _AdicionarItemMesaDialogState();
}

class _AdicionarItemMesaDialogState extends State<AdicionarItemMesaDialog> {
  final _pesquisaController = TextEditingController();
  final _observacaoController = TextEditingController();

  CategoriaLoja? _categoriaSelecionada;
  bool _modoAvulso = false;
  ItemLoja? _itemSelecionado;
  int _quantidade = 1;
  final Map<String, int> _acompanhamentosQuantidades = {};

  @override
  void dispose() {
    _pesquisaController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  bool get _temCategorias => widget.categoriasDisponiveis.isNotEmpty;

  double get _precoBaseItemAtual {
    if (_itemSelecionado == null) return 0.0;
    var base = _precoComoNumero(_itemSelecionado!.preco);
    if (_categoriaSelecionada != null) {
      base += _precoComoNumero(_categoriaSelecionada!.preco);
    }
    return base;
  }

  double get _subtotalCalculado {
    if (_itemSelecionado == null) return 0.0;
    var totalUnitario = _precoBaseItemAtual;

    for (final entrada in _acompanhamentosQuantidades.entries) {
      if (entrada.value > 0) {
        final acompItem = widget.itensDisponiveis
            .where((i) => i.id == entrada.key)
            .firstOrNull;
        if (acompItem != null) {
          totalUnitario += _precoComoNumero(acompItem.preco) * entrada.value;
        }
      }
    }
    return totalUnitario * _quantidade;
  }

  void _selecionarItem(ItemLoja item) {
    setState(() {
      _itemSelecionado = item;
      _quantidade = 1;
      _acompanhamentosQuantidades.clear();
      _observacaoController.clear();
    });
  }

  void _confirmarLancamento() {
    if (_itemSelecionado == null) return;

    final listaAcompanhamentos = <AcompanhamentoEscolhido>[];
    for (final entrada in _acompanhamentosQuantidades.entries) {
      if (entrada.value > 0) {
        final acompItem = widget.itensDisponiveis
            .where((i) => i.id == entrada.key)
            .firstOrNull;
        if (acompItem != null) {
          listaAcompanhamentos.add(
            AcompanhamentoEscolhido(
              itemId: acompItem.id,
              nomeItem: acompItem.nome,
              precoItem: _precoComoNumero(acompItem.preco),
              quantidadePorUnidade: entrada.value,
            ),
          );
        }
      }
    }

    final fotoItem = _itemSelecionado!.imagens.isNotEmpty
        ? _itemSelecionado!.imagens.first
        : '';

    final precoItem = _precoComoNumero(_itemSelecionado!.preco);
    final precoCategoria = _categoriaSelecionada != null
        ? _precoComoNumero(_categoriaSelecionada!.preco)
        : 0.0;

    final itemVendido = ItemVendido(
      itemId: _itemSelecionado!.id,
      nomeItem: _itemSelecionado!.nome,
      foto: fotoItem,
      categoriaId: _categoriaSelecionada?.id,
      nomeCategoria: _categoriaSelecionada?.nome,
      precoItem: precoItem,
      precoCategoria: precoCategoria,
      quantidade: _quantidade,
      acompanhamentos: listaAcompanhamentos,
      observacao: _observacaoController.text.trim(),
    );

    final itemComanda = ItemComandaMesa(
      id: gerarIdUnico(),
      item: itemVendido,
      autorCpf: widget.autorCpf,
      autorNome: widget.autorNome,
      dataHora: DateTime.now(),
    );

    widget.aoAdicionar(itemComanda);
  }

  Widget _miniaturaItem(ItemLoja item) {
    if (item.imagens.isNotEmpty && File(item.imagens.first).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(
          File(item.imagens.first),
          width: 38,
          height: 38,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.inventory_2_outlined,
            size: 24,
            color: widget.theme.textColor,
          ),
        ),
      );
    }
    return Icon(
      Icons.inventory_2_outlined,
      size: 28,
      color: widget.theme.textColor,
    );
  }

  Widget _miniaturaCategoria(CategoriaLoja cat) {
    if (cat.foto.isNotEmpty && File(cat.foto).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(cat.foto),
          width: 42,
          height: 42,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.restaurant_menu,
            size: 24,
            color: widget.theme.textColor,
          ),
        ),
      );
    }
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: widget.theme.backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.theme.borderColor.withValues(alpha: 0.5),
        ),
      ),
      child: Icon(
        Icons.restaurant_menu,
        size: 22,
        color: widget.theme.textColor,
      ),
    );
  }

  Widget _seletorDeCategorias() {
    final query = _pesquisaController.text.trim().toLowerCase();
    final categoriasFiltradas = query.isEmpty
        ? widget.categoriasDisponiveis
        : widget.categoriasDisponiveis
            .where((c) => c.nome.toLowerCase().contains(query))
            .toList();

    final itensAvulsosFiltrados = query.isEmpty
        ? <ItemLoja>[]
        : widget.itensDisponiveis
            .where((i) => i.nome.toLowerCase().contains(query))
            .toList();

    return Column(
      children: [
        ThemedTextField(
          theme: widget.theme,
          controller: _pesquisaController,
          label: 'Buscar categoria ou produto...',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: [
              if (query.isEmpty) ...[
                // Card de Venda Avulsa
                InkWell(
                  onTap: () {
                    setState(() {
                      _modoAvulso = true;
                      _pesquisaController.clear();
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color:
                          widget.theme.backgroundColor.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.theme.borderColor.withValues(alpha: 0.7),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: widget.theme.backgroundColor
                                .withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: widget.theme.borderColor
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          child: Icon(
                            Icons.sell_outlined,
                            size: 22,
                            color: widget.theme.textColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Venda Avulsa / Itens Individuais',
                                style: widget.theme.getTextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: widget.theme.textColor,
                                ),
                              ),
                              Text(
                                'Embalagens, bebidas ou itens pelo valor unitário avulso',
                                style: widget.theme.getTextStyle(
                                  fontSize: 11,
                                  color: widget.theme.secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: widget.theme.secondaryTextColor,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 4),
                  child: Text(
                    'Categorias do Cardápio:',
                    style: widget.theme.getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.theme.secondaryTextColor,
                    ),
                  ),
                ),
              ],
              if (categoriasFiltradas.isEmpty && itensAvulsosFiltrados.isEmpty)
                EstadoVazioContainer(
                  theme: widget.theme,
                  mensagem: 'Nenhum resultado encontrado para a busca.',
                )
              else ...[
                for (final cat in categoriasFiltradas)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _categoriaSelecionada = cat;
                          _pesquisaController.clear();
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: widget.theme.backgroundColor
                              .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.theme.borderColor
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        child: Row(
                          children: [
                            _miniaturaCategoria(cat),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat.nome,
                                    style: widget.theme.getTextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: widget.theme.textColor,
                                    ),
                                  ),
                                  Text(
                                    cat.preco.isNotEmpty &&
                                            _precoComoNumero(cat.preco) > 0
                                        ? 'Preço base: ${_valorFormatado(_precoComoNumero(cat.preco))} • ${cat.itemIds.length} opções'
                                        : '${cat.itemIds.length} opções vinculadas',
                                    style: widget.theme.getTextStyle(
                                      fontSize: 11,
                                      color: widget.theme.secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: widget.theme.secondaryTextColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (itensAvulsosFiltrados.isNotEmpty) ...[
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 12, bottom: 8, left: 4),
                    child: Text(
                      'Itens Individuais Encontrados:',
                      style: widget.theme.getTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.theme.secondaryTextColor,
                      ),
                    ),
                  ),
                  for (final item in itensAvulsosFiltrados)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _modoAvulso = true;
                            _selecionarItem(item);
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: widget.theme.backgroundColor
                                .withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: widget.theme.borderColor
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              _miniaturaItem(item),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.nome,
                                  style: widget.theme.getTextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: widget.theme.textColor,
                                  ),
                                ),
                              ),
                              Text(
                                _valorFormatado(_precoComoNumero(item.preco)),
                                style: widget.theme.getTextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: widget.theme.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _seletorDeItensDaCategoria() {
    final cat = _categoriaSelecionada!;
    final precoCat = _precoComoNumero(cat.preco);

    final itensDaCategoria = widget.itensDisponiveis
        .where((i) => cat.itemIds.contains(i.id))
        .toList();

    final query = _pesquisaController.text.trim().toLowerCase();
    final itensFiltrados = query.isEmpty
        ? itensDaCategoria
        : itensDaCategoria
            .where((i) => i.nome.toLowerCase().contains(query))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Barra superior de navegação da categoria
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.theme.backgroundColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.theme.borderColor.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(Icons.arrow_back,
                    size: 20, color: widget.theme.textColor),
                onPressed: () {
                  setState(() {
                    _categoriaSelecionada = null;
                    _pesquisaController.clear();
                  });
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.nome,
                      style: widget.theme.getTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: widget.theme.textColor,
                      ),
                    ),
                    if (precoCat > 0)
                      Text(
                        'Base da categoria: ${_valorFormatado(precoCat)}',
                        style: widget.theme.getTextStyle(
                          fontSize: 11,
                          color: widget.theme.secondaryTextColor,
                        ),
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _categoriaSelecionada = null;
                    _pesquisaController.clear();
                  });
                },
                child: Text(
                  'Trocar categoria',
                  style: widget.theme.getTextStyle(
                    fontSize: 11,
                    color: widget.theme.textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ThemedTextField(
          theme: widget.theme,
          controller: _pesquisaController,
          label: 'Buscar item em ${cat.nome}...',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        if (itensFiltrados.isEmpty)
          Expanded(
            child: EstadoVazioContainer(
              theme: widget.theme,
              mensagem: itensDaCategoria.isEmpty
                  ? 'Nenhum item vinculado a esta categoria.'
                  : 'Nenhum item encontrado nesta busca.',
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              itemCount: itensFiltrados.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final item = itensFiltrados[index];
                final precoItem = _precoComoNumero(item.preco);
                final precoTotal = precoCat + precoItem;

                return InkWell(
                  onTap: () => _selecionarItem(item),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          widget.theme.backgroundColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: widget.theme.borderColor.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      children: [
                        _miniaturaItem(item),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.nome,
                                style: widget.theme.getTextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: widget.theme.textColor,
                                ),
                              ),
                              if (precoCat > 0)
                                Text(
                                  'Item ${_valorFormatado(precoItem)} + ${cat.nome}',
                                  style: widget.theme.getTextStyle(
                                    fontSize: 11,
                                    color: widget.theme.secondaryTextColor,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          _valorFormatado(precoTotal),
                          style: widget.theme.getTextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: widget.theme.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _seletorDeItensAvulsos() {
    final query = _pesquisaController.text.trim().toLowerCase();
    final itens = query.isEmpty
        ? widget.itensDisponiveis
        : widget.itensDisponiveis
            .where((i) => i.nome.toLowerCase().contains(query))
            .toList();

    return Column(
      children: [
        if (_temCategorias) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: widget.theme.backgroundColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.theme.borderColor.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(Icons.arrow_back,
                      size: 20, color: widget.theme.textColor),
                  onPressed: () {
                    setState(() {
                      _modoAvulso = false;
                      _pesquisaController.clear();
                    });
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Venda Avulsa (Preço do Item)',
                    style: widget.theme.getTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: widget.theme.textColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _modoAvulso = false;
                      _pesquisaController.clear();
                    });
                  },
                  child: Text(
                    'Ver categorias',
                    style: widget.theme.getTextStyle(
                      fontSize: 11,
                      color: widget.theme.textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        ThemedTextField(
          theme: widget.theme,
          controller: _pesquisaController,
          label: 'Buscar item individual...',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        if (itens.isEmpty)
          Expanded(
            child: EstadoVazioContainer(
              theme: widget.theme,
              mensagem: 'Nenhum item encontrado.',
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              itemCount: itens.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final item = itens[index];
                return InkWell(
                  onTap: () => _selecionarItem(item),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          widget.theme.backgroundColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: widget.theme.borderColor.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      children: [
                        _miniaturaItem(item),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.nome,
                            style: widget.theme.getTextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: widget.theme.textColor,
                            ),
                          ),
                        ),
                        Text(
                          _valorFormatado(_precoComoNumero(item.preco)),
                          style: widget.theme.getTextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: widget.theme.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _configuracaoItem() {
    final item = _itemSelecionado!;

    final gruposVinculados = <GrupoComponentesLoja>[];
    if (_categoriaSelecionada != null) {
      for (final gId in _categoriaSelecionada!.grupoIds) {
        final g = widget.gruposDisponiveis
            .where((x) => x.id == gId)
            .firstOrNull;
        if (g != null && !gruposVinculados.contains(g)) {
          gruposVinculados.add(g);
        }
      }
    }
    for (final g in widget.gruposDisponiveis) {
      if (g.itemIds.contains(item.id) && !gruposVinculados.contains(g)) {
        gruposVinculados.add(g);
      }
    }

    final tituloExibicao = _categoriaSelecionada != null
        ? '${_categoriaSelecionada!.nome} • ${item.nome}'
        : item.nome;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _miniaturaItem(item),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tituloExibicao,
                      style: widget.theme.getTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: widget.theme.textColor,
                      ),
                    ),
                    Text(
                      '${_valorFormatado(_precoBaseItemAtual)} por unidade',
                      style: widget.theme.getTextStyle(
                        fontSize: 13,
                        color: widget.theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _itemSelecionado = null),
                child: Text(
                  'Trocar item',
                  style: widget.theme.getTextStyle(
                    fontSize: 12,
                    color: widget.theme.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Seletor de Quantidade
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Quantidade:',
                style: widget.theme.getTextStyle(
                  fontSize: 14,
                  color: widget.theme.textColor,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: widget.theme.textColor,
                onPressed: _quantidade > 1
                    ? () => setState(() => _quantidade--)
                    : null,
              ),
              Text(
                '$_quantidade',
                style: widget.theme.getTextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.theme.textColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: widget.theme.textColor,
                onPressed: () => setState(() => _quantidade++),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Grupos de Adicionais
          if (gruposVinculados.isNotEmpty) ...[
            for (final grupo in gruposVinculados) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 6),
                child: Text(
                  grupo.nome,
                  style: widget.theme.getTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.theme.textColor,
                  ),
                ),
              ),
              for (final itemIdAcomp in grupo.itemIds) ...[
                if (itemIdAcomp != item.id) ...[
                  Builder(
                    builder: (context) {
                      final acomp = widget.itensDisponiveis
                          .where((i) => i.id == itemIdAcomp)
                          .firstOrNull;
                      if (acomp == null) return const SizedBox.shrink();

                      final qtdAtual =
                          _acompanhamentosQuantidades[acomp.id] ?? 0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${acomp.nome} (+${_valorFormatado(_precoComoNumero(acomp.preco))})',
                                style: widget.theme.getTextStyle(
                                  fontSize: 13,
                                  color: widget.theme.secondaryTextColor,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              color: widget.theme.textColor,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 28, minHeight: 28),
                              onPressed: qtdAtual > 0
                                  ? () => setState(() =>
                                      _acompanhamentosQuantidades[acomp.id] =
                                          qtdAtual - 1)
                                  : null,
                            ),
                            Text(
                              '$qtdAtual',
                              style: widget.theme.getTextStyle(fontSize: 13),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              color: widget.theme.textColor,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 28, minHeight: 28),
                              onPressed: () => setState(() =>
                                  _acompanhamentosQuantidades[acomp.id] =
                                      qtdAtual + 1),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ],
            const SizedBox(height: 12),
          ],
          ThemedTextField(
            theme: widget.theme,
            controller: _observacaoController,
            label: 'Observações (ex: sem cebola, bem passado)',
            linhas: 2,
          ),
          const SizedBox(height: 16),
          // Subtotal e botão de lançamento
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: widget.theme.backgroundColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.theme.borderColor.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal do item:',
                  style: widget.theme.getTextStyle(
                    fontSize: 14,
                    color: widget.theme.secondaryTextColor,
                  ),
                ),
                Text(
                  _valorFormatado(_subtotalCalculado),
                  style: widget.theme.getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.theme.textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: widget.theme.buttonColor,
              foregroundColor: widget.theme.buttonTextColor,
              side: BorderSide(color: widget.theme.borderColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _confirmarLancamento,
            child: Text(
              'Lançar na Mesa',
              style: widget.theme.getTextStyle(
                fontSize: 14,
                color: widget.theme.buttonTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: widget.theme.textColor),
                onPressed: () {
                  if (_itemSelecionado != null) {
                    setState(() => _itemSelecionado = null);
                  } else if (_categoriaSelecionada != null) {
                    setState(() => _categoriaSelecionada = null);
                  } else if (_modoAvulso) {
                    setState(() => _modoAvulso = false);
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
              Expanded(
                child: Text(
                  _itemSelecionado != null
                      ? 'Personalizar Item'
                      : _categoriaSelecionada != null
                          ? _categoriaSelecionada!.nome
                          : _modoAvulso
                              ? 'Itens Avulsos'
                              : 'Adicionar à Mesa',
                  textAlign: TextAlign.center,
                  style: widget.theme.getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.theme.textColor,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _itemSelecionado != null
                ? _configuracaoItem()
                : _categoriaSelecionada != null
                    ? _seletorDeItensDaCategoria()
                    : (_modoAvulso || !_temCategorias)
                        ? _seletorDeItensAvulsos()
                        : _seletorDeCategorias(),
          ),
        ],
      ),
    );
  }
}
