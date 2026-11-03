import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';

/// Card especializado para exibição e resolução de alertas de estoque baixo ou esgotado.
class CardNotificacaoEstoque extends StatelessWidget {
  final AppTheme theme;
  final ({ItemLoja item, double saldo, String lojaNome, String lojaId}) alerta;
  final VoidCallback onTap;

  const CardNotificacaoEstoque({
    super.key,
    required this.theme,
    required this.alerta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final saldoFormatado = alerta.saldo.truncateToDouble() == alerta.saldo
        ? alerta.saldo.toInt().toString()
        : alerta.saldo.toStringAsFixed(1);
    final unidadeTexto = alerta.item.unidadeBase.name;
    final esgotado = alerta.saldo <= 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: theme.backgroundColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.redAccent.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  esgotado
                      ? Icons.remove_shopping_cart_outlined
                      : Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            esgotado
                                ? 'Estoque Esgotado: ${alerta.item.nome}'
                                : 'Estoque Baixo: ${alerta.item.nome}',
                            style: theme.getTextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$saldoFormatado $unidadeTexto',
                            style: theme.getTextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Loja: ${alerta.lojaNome}',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      esgotado
                          ? 'O item está sem saldo disponível. Toque para registrar uma nova entrada imediatamente.'
                          : 'O saldo está abaixo de 10 unidades. Toque para reabastecer agora.',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Adicionar ao estoque',
                          style: theme.getTextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: theme.textColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
