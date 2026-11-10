import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

enum AcaoAberturaCaixa {
  abrirCaixaAgora,
  prosseguirSemCaixa,
  cancelar,
}

class DialogConfirmarAberturaCaixa extends StatelessWidget {
  final AppTheme theme;
  final String lojaNome;

  const DialogConfirmarAberturaCaixa({
    super.key,
    required this.theme,
    required this.lojaNome,
  });

  static Future<AcaoAberturaCaixa?> mostrar({
    required BuildContext context,
    required AppTheme theme,
    required String lojaNome,
  }) {
    return showDialog<AcaoAberturaCaixa>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DialogConfirmarAberturaCaixa(
        theme: theme,
        lojaNome: lojaNome,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: theme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      actionsPadding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      title: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.buttonColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.point_of_sale_rounded,
              color: theme.buttonColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Abrir Caixa Agora?',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'A loja "$lojaNome" foi colocada online. Deseja realizar a abertura do caixa agora para registrar o saldo inicial?',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 13,
                color: theme.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.textColor,
                  side: BorderSide(
                    color: theme.borderColor.withValues(alpha: 0.8),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                onPressed: () => Navigator.pop(
                  context,
                  AcaoAberturaCaixa.prosseguirSemCaixa,
                ),
                child: Text(
                  'Agora Não',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.buttonColor,
                  foregroundColor: theme.buttonTextColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: Text(
                  'Abrir Caixa',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.buttonTextColor,
                  ),
                ),
                onPressed: () => Navigator.pop(
                  context,
                  AcaoAberturaCaixa.abrirCaixaAgora,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
