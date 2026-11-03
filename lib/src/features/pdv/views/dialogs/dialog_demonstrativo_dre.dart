import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

class DialogDemonstrativoDRE {
  static void mostrar(
    BuildContext context, {
    required AppTheme theme,
    required String rotuloPeriodo,
    required double receita,
    required double cmv,
    required double despesasPessoal,
    required String Function(double) formatarValor,
    required String Function(double) formatarValorComSinal,
    required VoidCallback onExportarPdf,
  }) {
    final lucroBruto = receita - cmv;
    final margemBruta = receita > 0 ? (lucroBruto / receita * 100) : 0.0;
    final resultadoLiquido = lucroBruto - despesasPessoal;
    final margemLiquida =
        receita > 0 ? (resultadoLiquido / receita * 100) : 0.0;

    Widget linha(
      String rotulo,
      String valor, {
      bool destaque = false,
      bool negativo = false,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                rotulo,
                style: theme.getTextStyle(
                  fontSize: destaque ? 12 : 11,
                  fontWeight: destaque ? FontWeight.bold : FontWeight.normal,
                  color: destaque ? theme.textColor : theme.secondaryTextColor,
                ),
              ),
            ),
            Text(
              valor,
              style: theme.getTextStyle(
                fontSize: destaque ? 13 : 12,
                fontWeight: destaque ? FontWeight.bold : FontWeight.w600,
                color: negativo
                    ? Colors.redAccent
                    : (destaque ? theme.textColor : theme.textColor),
              ),
            ),
          ],
        ),
      );
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: theme.cardBackgroundColor,
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: theme.textColor),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Demonstrativo de Resultado (DRE)',
                              textAlign: TextAlign.center,
                              style: theme.getTextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                            Text(
                              'Período: $rotuloPeriodo',
                              textAlign: TextAlign.center,
                              style: theme.getTextStyle(
                                fontSize: 11,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.backgroundColor.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Column(
                      children: [
                        linha('1. Receita Operacional Bruta',
                            formatarValor(receita),
                            destaque: true),
                        const SizedBox(height: 4),
                        linha(
                          '2. (-) Custo dos Produtos / Insumos',
                          formatarValor(cmv),
                        ),
                        const Divider(height: 16),
                        linha(
                          '3. (=) Lucro Operacional Bruto',
                          formatarValorComSinal(lucroBruto),
                          destaque: true,
                          negativo: lucroBruto < 0,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Margem Bruta: ${margemBruta.toStringAsFixed(1)}%',
                              style: theme.getTextStyle(
                                fontSize: 10,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          ),
                        ),
                        linha(
                          '4. (-) Pagamentos a Trabalhadores',
                          formatarValor(despesasPessoal),
                        ),
                        const Divider(height: 16),
                        linha(
                          '5. (=) Resultado Líquido do Período',
                          formatarValorComSinal(resultadoLiquido),
                          destaque: true,
                          negativo: resultadoLiquido < 0,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Margem Líquida: ${margemLiquida.toStringAsFixed(1)}%',
                            style: theme.getTextStyle(
                              fontSize: 10,
                              color: resultadoLiquido < 0
                                  ? Colors.redAccent
                                  : theme.secondaryTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(
                          'Fechar',
                          style: theme.getTextStyle(
                            fontSize: 12,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.textColor,
                          side: BorderSide(color: theme.borderColor),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          onExportarPdf();
                        },
                        icon: Icon(Icons.picture_as_pdf_outlined,
                            size: 14, color: theme.textColor),
                        label: Text(
                          'Exportar DRE em PDF',
                          style: theme.getTextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
