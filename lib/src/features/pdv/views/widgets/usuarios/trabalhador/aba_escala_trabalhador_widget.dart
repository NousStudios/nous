import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/escala_trabalho_membro.dart';

/// Aba de Escala Semanal de Trabalho do Membro.
class AbaEscalaTrabalhadorWidget extends StatelessWidget {
  final AppTheme theme;
  final bool podeGerenciar;
  final EscalaTrabalhoMembro? escala;
  final List<int> diasEscala;
  final TextEditingController horarioEntradaController;
  final TextEditingController horarioSaidaController;
  final void Function(int dia) onAlternarDia;
  final VoidCallback onSalvarEscala;

  const AbaEscalaTrabalhadorWidget({
    super.key,
    required this.theme,
    required this.podeGerenciar,
    required this.escala,
    required this.diasEscala,
    required this.horarioEntradaController,
    required this.horarioSaidaController,
    required this.onAlternarDia,
    required this.onSalvarEscala,
  });

  @override
  Widget build(BuildContext context) {
    const nomesDias = {1: 'Seg', 2: 'Ter', 3: 'Qua', 4: 'Qui', 5: 'Sex', 6: 'Sáb', 7: 'Dom'};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Dias de Trabalho da Semana:',
          style: theme.getTextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.secondaryTextColor),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(7, (idx) {
            final dia = idx + 1;
            final selecionado = diasEscala.contains(dia);
            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: podeGerenciar ? () => onAlternarDia(dia) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: selecionado
                      ? (theme.buttonColor != Colors.transparent ? theme.buttonColor : theme.borderColor.withValues(alpha: 0.35))
                      : theme.backgroundColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selecionado ? theme.textColor : theme.borderColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  nomesDias[dia]!,
                  style: theme.getTextStyle(
                    fontSize: 11,
                    fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
                    color: theme.textColor,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Horário de Entrada', style: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: horarioEntradaController,
                    enabled: podeGerenciar,
                    style: theme.getTextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: '08:00',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.borderColor.withValues(alpha: 0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.textColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Horário de Saída', style: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: horarioSaidaController,
                    enabled: podeGerenciar,
                    style: theme.getTextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: '17:00',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.borderColor.withValues(alpha: 0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.textColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (podeGerenciar) ...[
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.buttonColor != Colors.transparent ? theme.buttonColor : theme.borderColor.withValues(alpha: 0.25),
                foregroundColor: theme.textColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: onSalvarEscala,
              child: Text('Salvar Escala Semanal', style: theme.getTextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ],
    );
  }
}
