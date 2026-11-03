import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';

/// Painel para conferência dos valores físicos na gaveta e fechamento de turno do caixa.
class PainelFechamentoTurno extends StatelessWidget {
  final AppTheme theme;
  final BoxDecoration decoracao;
  final TextEditingController saldoFechamentoController;
  final TextEditingController observacaoFechamentoController;
  final double saldoEsperadoDinheiro;
  final double Function(String) parsearValor;
  final String Function(double) formatarMoeda;
  final Widget Function(String, String, {bool destaque}) linhaResumo;
  final bool salvando;
  final VoidCallback aoVoltar;
  final VoidCallback aoFechar;
  final VoidCallback aoFecharEImprimir;
  final VoidCallback aoAlterarTexto;

  const PainelFechamentoTurno({
    super.key,
    required this.theme,
    required this.decoracao,
    required this.saldoFechamentoController,
    required this.observacaoFechamentoController,
    required this.saldoEsperadoDinheiro,
    required this.parsearValor,
    required this.formatarMoeda,
    required this.linhaResumo,
    required this.salvando,
    required this.aoVoltar,
    required this.aoFechar,
    required this.aoFecharEImprimir,
    required this.aoAlterarTexto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: decoracao,
      child: Column(
        children: [
          Text(
            'Conferência e Fechamento de Caixa',
            style: theme.getTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Conte todo o dinheiro físico presente na gaveta e informe abaixo:',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 11,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 12),
          ThemedTextField(
            theme: theme,
            controller: saldoFechamentoController,
            label: 'Valor contado na gaveta (ex: 125,50)',
            tipoDeTeclado: TextInputType.number,
            onChanged: (_) => aoAlterarTexto(),
          ),
          const SizedBox(height: 8),
          ThemedTextField(
            theme: theme,
            controller: observacaoFechamentoController,
            label: 'Observação do fechamento (opcional)',
          ),
          const SizedBox(height: 12),
          Builder(builder: (context) {
            final contado = parsearValor(saldoFechamentoController.text);
            final diferenca = contado - saldoEsperadoDinheiro;
            final bateu = diferenca.abs() < 0.01;
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.borderColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  linhaResumo('Saldo Esperado:', formatarMoeda(saldoEsperadoDinheiro)),
                  linhaResumo('Valor Informado:', formatarMoeda(contado)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        bateu
                            ? 'Conferência exata'
                            : (diferenca > 0 ? 'Sobra de caixa:' : 'Quebra / Falta:'),
                        style: theme.getTextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: bateu
                              ? theme.textColor
                              : (diferenca < 0 ? Colors.redAccent : theme.textColor),
                        ),
                      ),
                      Text(
                        bateu ? 'R\$ 0,00' : formatarMoeda(diferenca.abs()),
                        style: theme.getTextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: bateu
                              ? theme.textColor
                              : (diferenca < 0 ? Colors.redAccent : theme.textColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: aoVoltar,
                child: Text(
                  'Voltar',
                  style: theme.getTextStyle(color: theme.secondaryTextColor),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.textColor,
                  side: BorderSide(color: theme.borderColor),
                ),
                onPressed: salvando ? null : aoFecharEImprimir,
                icon: Icon(Icons.print_outlined, size: 16, color: theme.textColor),
                label: Text(
                  'Fechar e Imprimir',
                  style: theme.getTextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: theme.buttonColor,
                  foregroundColor: theme.buttonTextColor,
                  side: BorderSide(color: theme.borderColor),
                ),
                onPressed: salvando ? null : aoFechar,
                child: Text(
                  salvando ? 'Fechando...' : 'Fechar',
                  style: theme.getTextStyle(
                    color: theme.buttonTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
