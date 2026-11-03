import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/pdv/models/turno_caixa.dart';

/// Painel para digitação e lançamento de sangria (retirada) ou suprimento (troco).
class PainelLancamentoMovimento extends StatelessWidget {
  final AppTheme theme;
  final BoxDecoration decoracao;
  final TipoMovimentoCaixa modoMovimento;
  final TextEditingController valorController;
  final TextEditingController motivoController;
  final bool salvando;
  final VoidCallback aoCancelar;
  final VoidCallback aoConfirmar;
  final VoidCallback aoConfirmarEImprimir;

  const PainelLancamentoMovimento({
    super.key,
    required this.theme,
    required this.decoracao,
    required this.modoMovimento,
    required this.valorController,
    required this.motivoController,
    required this.salvando,
    required this.aoCancelar,
    required this.aoConfirmar,
    required this.aoConfirmarEImprimir,
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
            modoMovimento == TipoMovimentoCaixa.sangria
                ? 'Lançar Sangria (Retirada de Dinheiro)'
                : 'Lançar Suprimento (Adicionar Moedas/Troco)',
            style: theme.getTextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 10),
          ThemedTextField(
            theme: theme,
            controller: valorController,
            label: 'Valor (ex: 20,00)',
            tipoDeTeclado: TextInputType.number,
          ),
          const SizedBox(height: 8),
          ThemedTextField(
            theme: theme,
            controller: motivoController,
            label: 'Motivo (ex: Troco de moedas, Pagamento de água)',
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: aoCancelar,
                child: Text(
                  'Cancelar',
                  style: theme.getTextStyle(color: theme.secondaryTextColor),
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.textColor,
                  side: BorderSide(color: theme.borderColor),
                ),
                onPressed: salvando ? null : aoConfirmar,
                child: Text(
                  'Confirmar',
                  style: theme.getTextStyle(
                    color: theme.textColor,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: theme.buttonColor,
                  foregroundColor: theme.buttonTextColor,
                  side: BorderSide(color: theme.borderColor),
                ),
                onPressed: salvando ? null : aoConfirmarEImprimir,
                icon: Icon(Icons.print_outlined,
                    size: 14, color: theme.buttonTextColor),
                label: Text(
                  'Confirmar e Imprimir',
                  style: theme.getTextStyle(
                    color: theme.buttonTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
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
