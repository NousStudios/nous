import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';

/// Painel para informar o fundo de troco e abrir um novo turno de caixa.
class PainelAberturaTurno extends StatelessWidget {
  final AppTheme theme;
  final BoxDecoration decoracao;
  final TextEditingController saldoInicialController;
  final bool salvando;
  final VoidCallback aoAbrirCaixa;

  const PainelAberturaTurno({
    super.key,
    required this.theme,
    required this.decoracao,
    required this.saldoInicialController,
    required this.salvando,
    required this.aoAbrirCaixa,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: decoracao,
          child: Column(
            children: [
              Icon(Icons.lock_clock, size: 36, color: theme.textColor),
              const SizedBox(height: 8),
              Text(
                'O caixa está fechado',
                style: theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Informe o valor de fundo de troco para iniciar as vendas deste turno.',
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 16),
              ThemedTextField(
                theme: theme,
                controller: saldoInicialController,
                label: 'Fundo de troco inicial (ex: 50,00)',
                tipoDeTeclado: TextInputType.number,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: theme.buttonColor,
              foregroundColor: theme.buttonTextColor,
              side: BorderSide(color: theme.borderColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: salvando ? null : aoAbrirCaixa,
            child: Text(
              salvando ? 'Abrindo...' : 'Abrir Caixa',
              style: theme.getTextStyle(
                fontSize: 14,
                color: theme.buttonTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
