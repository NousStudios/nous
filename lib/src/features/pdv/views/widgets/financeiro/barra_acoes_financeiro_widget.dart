import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/loja.dart';

/// Barra de ações superiores da tela financeira (DRE, Imprimir, Exportar PDF).
class BarraAcoesFinanceiroWidget extends StatelessWidget {
  final AppTheme theme;
  final Loja? loja;
  final bool imprimindo;
  final bool exportando;
  final VoidCallback? onAbrirDRE;
  final VoidCallback? onImprimir;
  final VoidCallback? onExportar;

  const BarraAcoesFinanceiroWidget({
    super.key,
    required this.theme,
    required this.loja,
    required this.imprimindo,
    required this.exportando,
    this.onAbrirDRE,
    this.onImprimir,
    this.onExportar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _botaoAcao(
          theme,
          'DRE Simples',
          carregando: false,
          aoPressionar: loja == null ? null : onAbrirDRE,
        ),
        const SizedBox(width: 8),
        _botaoAcao(
          theme,
          'Imprimir',
          carregando: imprimindo,
          aoPressionar: loja == null ? null : onImprimir,
        ),
        const SizedBox(width: 8),
        _botaoAcao(
          theme,
          'Exportar PDF',
          carregando: exportando,
          aoPressionar: loja == null ? null : onExportar,
        ),
      ],
    );
  }

  Widget _botaoAcao(
    AppTheme theme,
    String rotulo, {
    required bool carregando,
    required VoidCallback? aoPressionar,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.textColor,
        side: BorderSide(color: theme.borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: carregando ? null : aoPressionar,
      child: carregando
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.textColor,
              ),
            )
          : Text(rotulo, style: theme.getTextStyle(fontSize: 12)),
    );
  }
}
