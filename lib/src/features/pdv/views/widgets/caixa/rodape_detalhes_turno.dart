import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

class RodapeDetalhesTurno extends StatelessWidget {
  final AppTheme theme;
  final bool excluindo;
  final bool imprimindo;
  final VoidCallback aoConfirmarExclusao;
  final VoidCallback aoReimprimir;

  const RodapeDetalhesTurno({
    super.key,
    required this.theme,
    required this.excluindo,
    required this.imprimindo,
    required this.aoConfirmarExclusao,
    required this.aoReimprimir,
  });

  static Future<bool?> mostrarConfirmacaoExclusao(
    BuildContext context, {
    required AppTheme theme,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: theme.dangerColor,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Apagar Registro do Turno?',
                style: theme.getTextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          content: Text(
            'Tem certeza que deseja apagar o registro deste turno fechado? '
            'Todo o histórico de movimentações e fechamento vinculado a este turno será removido. '
            'Esta ação não pode ser desfeita.',
            style: theme.getTextStyle(
              fontSize: 13,
              color: theme.secondaryTextColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancelar',
                style: theme.getTextStyle(color: theme.textColor),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.dangerColor,
                foregroundColor: theme.buttonTextColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Sim, Apagar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.dangerColor, width: 1.2),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: excluindo
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.dangerColor,
                    ),
                  )
                : Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: theme.dangerColor,
                  ),
            label: Text(
              'Apagar Registro',
              style: theme.getTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.dangerColor,
              ),
            ),
            onPressed: excluindo ? null : aoConfirmarExclusao,
          ),
          const Spacer(),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.buttonColor,
              foregroundColor: theme.buttonTextColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: imprimindo
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.buttonTextColor,
                    ),
                  )
                : const Icon(Icons.print_outlined, size: 16),
            label: Text(
              'Reimprimir Comprovante',
              style: theme.getTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.buttonTextColor,
              ),
            ),
            onPressed: imprimindo ? null : aoReimprimir,
          ),
        ],
      ),
    );
  }
}
