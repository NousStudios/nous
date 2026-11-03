import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';

class DialogoVarianteBalcao {
  static Future<VarianteItem?> mostrar({
    required BuildContext context,
    required AppTheme theme,
    required ItemLoja item,
  }) {
    return showDialog<VarianteItem>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.borderColor),
        ),
        title: Text(
          'Escolha a Variante\n${item.nome}',
          textAlign: TextAlign.center,
          style: theme.getTextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        content: SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: theme.borderColor.withValues(alpha: 0.5),
                    ),
                  ),
                  title: Text(
                    'Padrão',
                    style: theme.getTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                  trailing: Text(
                    'R\$ ${item.preco}',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                  onTap: () => Navigator.of(dialogCtx).pop(
                    VarianteItem(nome: '', preco: item.preco),
                  ),
                ),
                const SizedBox(height: 8),
                for (final v in item.variantes) ...[
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: theme.borderColor.withValues(alpha: 0.5),
                      ),
                    ),
                    title: Text(
                      v.nome,
                      style: theme.getTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    trailing: Text(
                      'R\$ ${v.preco.isNotEmpty ? v.preco : item.preco}',
                      style: theme.getTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    onTap: () => Navigator.of(dialogCtx).pop(v),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(null),
            child: Text(
              'Cancelar',
              style: theme.getTextStyle(color: theme.secondaryTextColor),
            ),
          ),
        ],
      ),
    );
  }
}
