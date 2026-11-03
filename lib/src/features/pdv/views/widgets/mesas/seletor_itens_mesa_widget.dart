import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
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

/// Componente que exibe a navegação por categorias ou catálogo de itens avulsos para mesas.
class SeletorItensMesaWidget extends StatefulWidget {
  final AppTheme theme;
  final List<CategoriaLoja> categoriasDisponiveis;
  final List<ItemLoja> itensDisponiveis;
  final CategoriaLoja? categoriaSelecionada;
  final bool modoAvulso;
  final ValueChanged<CategoriaLoja?> onSelecionarCategoria;
  final ValueChanged<bool> onAlternarModoAvulso;
  final ValueChanged<ItemLoja> onSelecionarItem;

  const SeletorItensMesaWidget({
    super.key,
    required this.theme,
    required this.categoriasDisponiveis,
    required this.itensDisponiveis,
    required this.categoriaSelecionada,
    required this.modoAvulso,
    required this.onSelecionarCategoria,
    required this.onAlternarModoAvulso,
    required this.onSelecionarItem,
  });

  @override
  State<SeletorItensMesaWidget> createState() => _SeletorItensMesaWidgetState();
}

class _SeletorItensMesaWidgetState extends State<SeletorItensMesaWidget> {
  final _pesquisaController = TextEditingController();

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  bool get _temCategorias => widget.categoriasDisponiveis.isNotEmpty;

  Widget _miniaturaItem(ItemLoja item) {
    final fotoResolvida = item.imagens.isNotEmpty
        ? ImagemService.resolverCaminhoExistente(item.imagens.first)
        : null;
    if (fotoResolvida != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(
          File(fotoResolvida),
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
    final fotoResolvida = ImagemService.resolverCaminhoExistente(cat.foto);
    if (fotoResolvida != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(fotoResolvida),
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
                    _pesquisaController.clear();
                    widget.onAlternarModoAvulso(true);
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
                        _pesquisaController.clear();
                        widget.onSelecionarCategoria(cat);
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
                          widget.onAlternarModoAvulso(true);
                          widget.onSelecionarItem(item);
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
    final cat = widget.categoriaSelecionada!;
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
                  _pesquisaController.clear();
                  widget.onSelecionarCategoria(null);
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
                  _pesquisaController.clear();
                  widget.onSelecionarCategoria(null);
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
                  onTap: () => widget.onSelecionarItem(item),
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
                    _pesquisaController.clear();
                    widget.onAlternarModoAvulso(false);
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
                    _pesquisaController.clear();
                    widget.onAlternarModoAvulso(false);
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
                  onTap: () => widget.onSelecionarItem(item),
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

  @override
  Widget build(BuildContext context) {
    if (widget.categoriaSelecionada != null) {
      return _seletorDeItensDaCategoria();
    }
    if (widget.modoAvulso || !_temCategorias) {
      return _seletorDeItensAvulsos();
    }
    return _seletorDeCategorias();
  }
}
