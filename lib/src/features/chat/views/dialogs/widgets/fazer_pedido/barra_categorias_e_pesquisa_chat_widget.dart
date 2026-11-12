import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';

/// Barra horizontal de Categorias (Chips) e Campo de Pesquisa em tempo real de itens do cardápio.
class BarraCategoriasEPesquisaChatWidget extends StatelessWidget {
  final AppTheme theme;
  final List<CategoriaLoja> categorias;
  final String? categoriaSelecionadaId;
  final TextEditingController buscaController;
  final String termoBusca;
  final void Function(String? categoriaId) onSelecionarCategoria;
  final void Function(String termo) onChangedBusca;
  final VoidCallback onLimparBusca;

  const BarraCategoriasEPesquisaChatWidget({
    super.key,
    required this.theme,
    required this.categorias,
    required this.categoriaSelecionadaId,
    required this.buscaController,
    required this.termoBusca,
    required this.onSelecionarCategoria,
    required this.onChangedBusca,
    required this.onLimparBusca,
  });

  double _parsePreco(String p) => double.tryParse(p.replaceAll(',', '.')) ?? 0.0;
  String _formatarPreco(double v) => 'R\$ ${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (categorias.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    selected: categoriaSelecionadaId == null,
                    label: const Text('Todos'),
                    labelStyle: theme.getTextStyle(
                      fontSize: 11.5,
                      fontWeight: categoriaSelecionadaId == null
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: categoriaSelecionadaId == null
                          ? theme.buttonTextColor
                          : theme.textColor,
                    ),
                    backgroundColor: theme.backgroundColor,
                    selectedColor: theme.buttonColor,
                    onSelected: (_) => onSelecionarCategoria(null),
                  ),
                ),
                for (final cat in categorias)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      selected: categoriaSelecionadaId == cat.id,
                      label: Text(
                        _parsePreco(cat.preco) > 0
                            ? '${cat.nome} (${_formatarPreco(_parsePreco(cat.preco))})'
                            : cat.nome,
                      ),
                      labelStyle: theme.getTextStyle(
                        fontSize: 11.5,
                        fontWeight: categoriaSelecionadaId == cat.id
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: categoriaSelecionadaId == cat.id
                            ? theme.buttonTextColor
                            : theme.textColor,
                      ),
                      backgroundColor: theme.backgroundColor,
                      selectedColor: theme.buttonColor,
                      onSelected: (_) => onSelecionarCategoria(cat.id),
                    ),
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: TextField(
            controller: buscaController,
            style: theme.getTextStyle(
              fontSize: 12.5,
              color: theme.textColor,
            ),
            onChanged: onChangedBusca,
            decoration: InputDecoration(
              hintText: 'Pesquisar itens no cardápio...',
              hintStyle: theme.getTextStyle(
                fontSize: 11.5,
                color: theme.secondaryTextColor,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 18,
                color: theme.secondaryTextColor,
              ),
              suffixIcon: termoBusca.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        size: 16,
                        color: theme.secondaryTextColor,
                      ),
                      onPressed: onLimparBusca,
                    )
                  : null,
              isDense: true,
              filled: true,
              fillColor: theme.backgroundColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.borderColor.withValues(alpha: 0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.borderColor.withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.buttonColor),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
