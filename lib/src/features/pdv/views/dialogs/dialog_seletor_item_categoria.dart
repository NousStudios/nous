import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';

/// Diálogo modal para selecionar um produto pertencente a uma categoria específica.
class DialogSeletorItemCategoria extends StatefulWidget {
  final AppTheme theme;
  final CategoriaLoja categoria;
  final ItemLoja? Function(String id) buscarItem;
  final void Function(ItemLoja item) onSelecionarItem;

  const DialogSeletorItemCategoria({
    super.key,
    required this.theme,
    required this.categoria,
    required this.buscarItem,
    required this.onSelecionarItem,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required CategoriaLoja categoria,
    required ItemLoja? Function(String id) buscarItem,
    required void Function(ItemLoja item) onSelecionarItem,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => DialogSeletorItemCategoria(
        theme: theme,
        categoria: categoria,
        buscarItem: buscarItem,
        onSelecionarItem: onSelecionarItem,
      ),
    );
  }

  @override
  State<DialogSeletorItemCategoria> createState() =>
      _DialogSeletorItemCategoriaState();
}

class _DialogSeletorItemCategoriaState
    extends State<DialogSeletorItemCategoria> {
  final TextEditingController _buscaCtrl = TextEditingController();
  String _termo = '';

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  double _precoComoNumero(String texto) {
    final limpo = texto.replaceAll(RegExp(r'[^0-9,\.]'), '').replaceAll(',', '.');
    return double.tryParse(limpo) ?? 0.0;
  }

  String _valorComVirgula(double valor) =>
      valor.toStringAsFixed(2).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final todosItens = widget.categoria.itemIds
        .map((id) => widget.buscarItem(id))
        .whereType<ItemLoja>()
        .toList();
    final t = _termo.trim().toLowerCase();
    final itens = t.isEmpty
        ? todosItens
        : todosItens
            .where(
              (item) =>
                  item.nome.toLowerCase().contains(t) ||
                  item.codigoBarras.toLowerCase().contains(t),
            )
            .toList();

    return AlertDialog(
      backgroundColor: theme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: theme.borderColor),
      ),
      title: Text(
        widget.categoria.nome,
        textAlign: TextAlign.center,
        style: theme.getTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: theme.textColor,
        ),
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 360,
          maxHeight: MediaQuery.sizeOf(context).height * 0.70,
        ),
        child: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (todosItens.isNotEmpty) ...[
                TextField(
                  controller: _buscaCtrl,
                  autofocus: true,
                  onChanged: (v) => setState(() => _termo = v),
                  style: theme.getTextStyle(
                    fontSize: 12.5,
                    color: theme.textColor,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: theme.backgroundColor,
                    hintText: 'Pesquisar item na categoria...',
                    hintStyle: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.secondaryTextColor,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 18,
                      color: theme.secondaryTextColor,
                    ),
                    suffixIcon: _termo.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: 16,
                              color: theme.secondaryTextColor,
                            ),
                            onPressed: () {
                              _buscaCtrl.clear();
                              setState(() => _termo = '');
                            },
                          )
                        : null,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: theme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: theme.borderColor.withValues(alpha: 0.6),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: theme.textColor),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Flexible(
                child: itens.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          todosItens.isEmpty
                              ? 'Nenhum item nesta categoria ainda.'
                              : 'Nenhum item encontrado para "$_termo".',
                          textAlign: TextAlign.center,
                          style: theme.getTextStyle(
                            fontSize: 13,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: itens.length,
                        itemBuilder: (_, idx) {
                          final item = itens[idx];
                          return ListTile(
                            title: Text(
                              item.nome,
                              style: theme.getTextStyle(),
                            ),
                            trailing: Text(
                              'R\$ ${_valorComVirgula(_precoComoNumero(item.preco) + _precoComoNumero(widget.categoria.preco))}',
                              style: theme.getTextStyle(fontSize: 11),
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              widget.onSelecionarItem(item);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
