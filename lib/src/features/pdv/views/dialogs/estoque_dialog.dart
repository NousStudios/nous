import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/views/widgets/estoque_container.dart';

/// Diálogo modal do painel de Estoque da loja.
class EstoqueDialog {
  static Future<void> mostrar(
    BuildContext context, {
    required List<ItemLoja> itens,
    required List<MovimentoEstoque> movimentos,
    required bool podeEditar,
    required Future<void> Function() onNovoMovimento,
    required void Function(MovimentoEstoque) onRemoverMovimento,
    required VoidCallback onAvisarSemPermissao,
    required Future<void> Function() onAbrirFornecedores,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return ValueListenableBuilder<AppTheme>(
          valueListenable: ThemeController.currentTheme,
          builder: (valueContext, theme, child) {
            return StatefulBuilder(
              builder: (statefulContext, setDialogState) {
                return Dialog(
                  backgroundColor: theme.cardBackgroundColor,
                  insetPadding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: theme.borderColor),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 500,
                      maxHeight: 600,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.arrow_back,
                                  color: theme.textColor,
                                ),
                                onPressed: () =>
                                    Navigator.of(statefulContext).pop(),
                              ),
                              Expanded(
                                child: Text(
                                  'Estoque',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.getTextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 48),
                            ],
                          ),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: EstoqueContainer(
                              theme: theme,
                              itens: itens,
                              movimentos: movimentos,
                              podeEditar: podeEditar,
                              onNovoMovimento: () async {
                                await onNovoMovimento();
                                setDialogState(() {});
                              },
                              onRemoverMovimento: (movimento) {
                                onRemoverMovimento(movimento);
                                setDialogState(() {});
                              },
                              onAvisarSemPermissao: onAvisarSemPermissao,
                              onAbrirFornecedores: () async {
                                await onAbrirFornecedores();
                                setDialogState(() {});
                              },
                              emDialog: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
