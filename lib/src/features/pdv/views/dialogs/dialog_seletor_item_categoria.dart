import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';

/// Diálogo modal para selecionar um produto pertencente a uma categoria específica.
class DialogSeletorItemCategoria extends StatelessWidget {
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

  double _precoComoNumero(String texto) {
    final limpo = texto.replaceAll(RegExp(r'[^0-9,\.]'), '').replaceAll(',', '.');
    return double.tryParse(limpo) ?? 0.0;
  }

  String _valorComVirgula(double valor) =>
      valor.toStringAsFixed(2).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    final itens = categoria.itemIds
        .map((id) => buscarItem(id))
        .whereType<ItemLoja>()
        .toList();

    return AlertDialog(
      backgroundColor: theme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: theme.borderColor),
      ),
      title: Text(
        categoria.nome,
        textAlign: TextAlign.center,
        style: theme.getTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: theme.textColor,
        ),
      ),
      content: SizedBox(
        width: 280,
        child: itens.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Nenhum item nesta categoria ainda.',
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 13,
                    color: theme.secondaryTextColor,
                  ),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final item in itens)
                      ListTile(
                        title: Text(item.nome, style: theme.getTextStyle()),
                        trailing: Text(
                          'R\$ ${_valorComVirgula(_precoComoNumero(item.preco) + _precoComoNumero(categoria.preco))}',
                          style: theme.getTextStyle(fontSize: 11),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          onSelecionarItem(item);
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
