import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Painel para aplicação de descontos, acréscimos e cálculo rápido de 10% do garçom na mesa.
class PainelAjustesTotaisMesaWidget extends StatelessWidget {
  final AppTheme theme;
  final TextEditingController descontoController;
  final TextEditingController acrescimoController;
  final VoidCallback onAplicarDezPorCento;
  final VoidCallback onAlterado;

  const PainelAjustesTotaisMesaWidget({
    super.key,
    required this.theme,
    required this.descontoController,
    required this.acrescimoController,
    required this.onAplicarDezPorCento,
    required this.onAlterado,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ajustes no Total (Opcional):',
                style: theme.getTextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryTextColor,
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: onAplicarDezPorCento,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardBackgroundColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Text(
                    '+10% Garçom',
                    style: theme.getTextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: descontoController,
                  onChanged: (_) => onAlterado(),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
                  ],
                  cursorColor: theme.textColor,
                  style: theme.getTextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'Desconto (R\$)',
                    labelStyle: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.borderColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: acrescimoController,
                  onChanged: (_) => onAlterado(),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
                  ],
                  cursorColor: theme.textColor,
                  style: theme.getTextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'Taxa / Acréscimo (R\$)',
                    labelStyle: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.borderColor),
                    ),
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
