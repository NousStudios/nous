import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';

/// Diálogo modal para selecionar acompanhamentos e componentes de um item no carrinho.
class DialogEditarAcompanhamentos extends StatefulWidget {
  final AppTheme theme;
  final List<GrupoComponentesLoja> grupos;
  final Map<String, int> selecionadosIniciais;
  final ItemLoja? Function(String id) buscarItem;

  const DialogEditarAcompanhamentos({
    super.key,
    required this.theme,
    required this.grupos,
    required this.selecionadosIniciais,
    required this.buscarItem,
  });

  static Future<Map<String, int>?> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required List<GrupoComponentesLoja> grupos,
    required Map<String, int> selecionadosIniciais,
    required ItemLoja? Function(String id) buscarItem,
  }) {
    return showDialog<Map<String, int>>(
      context: context,
      builder: (dialogContext) => DialogEditarAcompanhamentos(
        theme: theme,
        grupos: grupos,
        selecionadosIniciais: selecionadosIniciais,
        buscarItem: buscarItem,
      ),
    );
  }

  @override
  State<DialogEditarAcompanhamentos> createState() =>
      _DialogEditarAcompanhamentosState();
}

class _DialogEditarAcompanhamentosState
    extends State<DialogEditarAcompanhamentos> {
  late final Map<String, int> _selecionados;

  @override
  void initState() {
    super.initState();
    _selecionados = Map<String, int>.of(widget.selecionadosIniciais);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return AlertDialog(
      backgroundColor: theme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: theme.borderColor),
      ),
      title: Text(
        'Acompanhamentos',
        textAlign: TextAlign.center,
        style: theme.getTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: theme.textColor,
        ),
      ),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final grupo in widget.grupos) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 6),
                  child: Text(
                    grupo.nome,
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                ),
                for (final itemId in grupo.itemIds)
                  Builder(builder: (context) {
                    final item = widget.buscarItem(itemId);
                    if (item == null) return const SizedBox.shrink();
                    final quantidade = _selecionados[itemId] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.nome,
                              style: theme.getTextStyle(fontSize: 12),
                            ),
                          ),
                          Text(
                            'R\$ ${item.preco}',
                            style: theme.getTextStyle(fontSize: 11),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(
                              minWidth: 30,
                              minHeight: 30,
                            ),
                            icon: Icon(Icons.remove,
                                size: 16, color: theme.textColor),
                            onPressed: () {
                              setState(() {
                                final atual = _selecionados[itemId] ?? 0;
                                if (atual <= 1) {
                                  _selecionados.remove(itemId);
                                } else {
                                  _selecionados[itemId] = atual - 1;
                                }
                              });
                            },
                          ),
                          SizedBox(
                            width: 18,
                            child: Text(
                              '$quantidade',
                              textAlign: TextAlign.center,
                              style: theme.getTextStyle(fontSize: 12),
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(
                              minWidth: 30,
                              minHeight: 30,
                            ),
                            icon: Icon(Icons.add,
                                size: 16, color: theme.textColor),
                            onPressed: () {
                              setState(() {
                                _selecionados[itemId] =
                                    (_selecionados[itemId] ?? 0) + 1;
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                Divider(
                  color: theme.borderColor.withValues(alpha: 0.6),
                ),
              ],
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(
            'Cancelar',
            style: theme.getTextStyle(color: theme.secondaryTextColor),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_selecionados),
          child: Text(
            'Concluir',
            style: theme.getTextStyle(color: theme.textColor),
          ),
        ),
      ],
    );
  }
}
