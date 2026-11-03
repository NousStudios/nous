import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Bloco que exibe o balanço orçamentário (entradas, saídas de funcionários/estoque e saldo final).
class BlocoBalancoFinanceiroWidget extends StatelessWidget {
  final AppTheme theme;
  final double entradas;
  final double totalPagamentos;
  final double saidaEstoque;
  final bool contarEstoque;
  final ValueChanged<bool> onToggleContarEstoque;
  final double saldo;
  final double aReceber;
  final String Function(double valor) valorFormatado;
  final String Function(double valor) valorComSinal;
  final BoxDecoration Function(AppTheme theme) decoracaoBloco;
  final Widget Function(AppTheme theme, String texto) tituloDoBloco;
  final Widget Function(
    AppTheme theme,
    String rotulo,
    String valor, {
    bool destaque,
    bool negativo,
  }) linha;

  const BlocoBalancoFinanceiroWidget({
    super.key,
    required this.theme,
    required this.entradas,
    required this.totalPagamentos,
    required this.saidaEstoque,
    required this.contarEstoque,
    required this.onToggleContarEstoque,
    required this.saldo,
    required this.aReceber,
    required this.valorFormatado,
    required this.valorComSinal,
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
          tituloDoBloco(theme, 'Balança orçamentária'),
          linha(theme, 'Entradas', valorFormatado(entradas)),
          linha(
            theme,
            'Saídas (funcionários)',
            valorFormatado(totalPagamentos),
          ),
          linha(
            theme,
            'Saídas (estoque)',
            contarEstoque
                ? valorFormatado(saidaEstoque)
                : '${valorFormatado(saidaEstoque)} (fora do cálculo)',
          ),
          const SizedBox(height: 4),
          _linhaToggleEstoque(theme),
          const Divider(height: 20),
          linha(
            theme,
            'Saldo',
            valorComSinal(saldo),
            destaque: true,
            negativo: saldo < 0,
          ),
          if (aReceber > 0) ...[
            const SizedBox(height: 8),
            Text(
              'A receber (pedidos e saldo a prazo): ${valorFormatado(aReceber)}',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 11,
                color: theme.secondaryTextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _linhaToggleEstoque(AppTheme theme) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onToggleContarEstoque(!contarEstoque),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: contarEstoque,
                onChanged: (valor) => onToggleContarEstoque(valor ?? false),
                activeColor: theme.buttonColor,
                checkColor: theme.buttonTextColor,
                side: BorderSide(color: theme.borderColor),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Contar custo de estoque no saldo',
                style: theme.getTextStyle(
                  fontSize: 11,
                  color: theme.secondaryTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
