import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Bloco encapsulado de configuração do tempo de conclusão de pedidos.
class BlocoTempoConclusaoWidget extends StatelessWidget {
  final AppTheme theme;
  final BoxDecoration decoracaoBloco;
  final bool podeEditar;
  final int tempoConclusaoMinutos;
  final void Function(int minutos) onSalvarTempoConclusao;

  const BlocoTempoConclusaoWidget({
    super.key,
    required this.theme,
    required this.decoracaoBloco,
    required this.podeEditar,
    required this.tempoConclusaoMinutos,
    required this.onSalvarTempoConclusao,
  });

  @override
  Widget build(BuildContext context) {
    final opcoesMinutos = [0, 5, 10, 15, 20, 30, 45, 60];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: decoracaoBloco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: theme.buttonColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tempo de Conclusão de Pedido',
                  style: theme.getTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Defina um tempo limite para o preparo ou entrega. Ao atingir o prazo, o sistema perguntará se o pedido foi concluído.',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 12,
                color: theme.secondaryTextColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.backgroundColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.4),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: opcoesMinutos.contains(tempoConclusaoMinutos)
                    ? tempoConclusaoMinutos
                    : 0,
                isExpanded: true,
                dropdownColor: theme.cardBackgroundColor,
                borderRadius: BorderRadius.circular(10),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: podeEditar
                      ? theme.textColor
                      : theme.secondaryTextColor.withValues(alpha: 0.5),
                ),
                items: opcoesMinutos.map((minutos) {
                  final rotulo = minutos == 0
                      ? 'Desativado (Sem limite de tempo)'
                      : '$minutos minutos';
                  return DropdownMenuItem<int>(
                    value: minutos,
                    child: Text(
                      rotulo,
                      style: theme.getTextStyle(
                        fontSize: 13,
                        color: minutos == 0
                            ? theme.secondaryTextColor
                            : theme.textColor,
                        fontWeight: minutos == tempoConclusaoMinutos
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: podeEditar
                    ? (novo) {
                        if (novo != null) onSalvarTempoConclusao(novo);
                      }
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
