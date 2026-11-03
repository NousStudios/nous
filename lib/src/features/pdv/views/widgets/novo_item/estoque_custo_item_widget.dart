import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';

class EstoqueCustoItemWidget extends StatelessWidget {
  final AppTheme theme;
  final bool editando;
  final double? saldoEstoqueAtual;
  final String rotuloUnidade;
  final TextEditingController estoqueAtualController;
  final TextEditingController estoqueMinimoController;
  final TextEditingController custoTotalCompraController;
  final TextEditingController quantidadeCompraController;
  final TextEditingController precoCustoController;
  final String? calculoTexto;
  final String? margemTexto;
  final VoidCallback? onAbrirMovimentoDetalhado;
  final String Function(double) formatarNumero;

  const EstoqueCustoItemWidget({
    super.key,
    required this.theme,
    required this.editando,
    required this.saldoEstoqueAtual,
    required this.rotuloUnidade,
    required this.estoqueAtualController,
    required this.estoqueMinimoController,
    required this.custoTotalCompraController,
    required this.quantidadeCompraController,
    required this.precoCustoController,
    required this.calculoTexto,
    required this.margemTexto,
    required this.onAbrirMovimentoDetalhado,
    required this.formatarNumero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 16,
                color: theme.textColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Estoque e Preço de Custo',
                  style: theme.getTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
              if (editando && saldoEstoqueAtual != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.borderColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'Saldo: ${formatarNumero(saldoEstoqueAtual!)} $rotuloUnidade',
                    style: theme.getTextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          ThemedTextField(
            theme: theme,
            controller: estoqueAtualController,
            label: editando
                ? 'Atualizar estoque atual ($rotuloUnidade)'
                : 'Estoque inicial ($rotuloUnidade) (opcional)',
            tipoDeTeclado: TextInputType.number,
          ),
          const SizedBox(height: 10),
          ThemedTextField(
            theme: theme,
            controller: estoqueMinimoController,
            label: 'Estoque mínimo em $rotuloUnidade (opcional)',
            tipoDeTeclado: TextInputType.number,
          ),
          if (editando && onAbrirMovimentoDetalhado != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.textColor,
                side: BorderSide(color: theme.borderColor),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onAbrirMovimentoDetalhado,
              icon: const Icon(Icons.sync_alt, size: 16),
              label: Text(
                'Lançar Movimento Detalhado',
                style: theme.getTextStyle(fontSize: 11),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: theme.borderColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.payments_outlined,
                size: 15,
                color: theme.secondaryTextColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Formação de Custo e Compra',
                style: theme.getTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ThemedTextField(
                  theme: theme,
                  controller: custoTotalCompraController,
                  label: 'Custo total (ex: 35,00)',
                  tipoDeTeclado: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ThemedTextField(
                  theme: theme,
                  controller: quantidadeCompraController,
                  label: 'Qtd comprada ($rotuloUnidade)',
                  tipoDeTeclado: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ThemedTextField(
            theme: theme,
            controller: precoCustoController,
            label: 'Preço de custo unitário (por $rotuloUnidade)',
            tipoDeTeclado: TextInputType.number,
          ),
          if (calculoTexto != null || margemTexto != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: theme.borderColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.borderColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (calculoTexto != null)
                    Row(
                      children: [
                        Icon(
                          Icons.calculate_outlined,
                          size: 14,
                          color: theme.textColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextoRolante(
                            texto: calculoTexto!,
                            style: theme.getTextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (margemTexto != null) ...[
                    if (calculoTexto != null) const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          size: 14,
                          color: theme.secondaryTextColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextoRolante(
                            texto: margemTexto!,
                            style: theme.getTextStyle(
                              fontSize: 11,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
