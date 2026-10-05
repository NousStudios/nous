import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

class OpcoesImagemDialog {
  OpcoesImagemDialog._();

  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required String titulo,
    required VoidCallback onEscolherNova,
    required VoidCallback onRemover,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            titulo,
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.textColor,
                  side: BorderSide(color: theme.borderColor),
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  onEscolherNova();
                },
                icon: Icon(
                  Icons.photo_library_outlined,
                  size: 18,
                  color: theme.textColor,
                ),
                label: Text(
                  'Procurar nova imagem',
                  style: theme.getTextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: BorderSide(
                    color: Colors.redAccent.withValues(alpha: 0.6),
                  ),
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  onRemover();
                },
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.redAccent,
                ),
                label: Text(
                  'Retirar imagem',
                  style: theme.getTextStyle(
                    fontSize: 13,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancelar',
                style: theme.getTextStyle(color: theme.secondaryTextColor),
              ),
            ),
          ],
        );
      },
    );
  }
}
