import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Bloco que exibe o resumo de entradas agrupadas por forma de pagamento.
class BlocoEntradasFinanceiroWidget extends StatelessWidget {
  final AppTheme theme;
  final List<String> formasDePagamento;
  final double Function(String forma) entradasPorForma;
  final double totalEntradas;
  final String Function(double valor) valorFormatado;
  final BoxDecoration Function(AppTheme theme) decoracaoBloco;
  final Widget Function(AppTheme theme, String texto) tituloDoBloco;
  final Widget Function(
    AppTheme theme,
    String rotulo,
    String valor, {
    bool destaque,
    bool negativo,
  }) linha;

  const BlocoEntradasFinanceiroWidget({
    super.key,
    required this.theme,
    required this.formasDePagamento,
    required this.entradasPorForma,
    required this.totalEntradas,
    required this.valorFormatado,
    required this.decoracaoBloco,
    required this.tituloDoBloco,
    required this.linha,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: decoracaoBloco(theme),
      child: Column(
        children: [
          tituloDoBloco(theme, 'Entradas por forma de pagamento'),
          for (final forma in formasDePagamento)
            linha(theme, forma, valorFormatado(entradasPorForma(forma))),
          const Divider(height: 20),
          linha(
            theme,
            'Total',
            valorFormatado(totalEntradas),
            destaque: true,
          ),
        ],
      ),
    );
  }
}
