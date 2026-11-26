import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Carcaça visual modular da seção "Carteira" (Print 1 do protótipo),
/// pronta para futura integração do módulo bancário soberano (moedas, faturas e transferências).
class SecaoCarteiraCarcacaWidget extends StatelessWidget {
  final AppTheme theme;

  const SecaoCarteiraCarcacaWidget({
    super.key,
    required this.theme,
  });

  void _mostrarAvisoEmBreve(BuildContext context, String recurso) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: theme.borderColor),
        ),
        title: Text(
          recurso,
          style: theme.getTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        content: Text(
          'A estrutura da Carteira Soberana já está preparada. A movimentação financeira completa (saldos, câmbio, crédito e transferências) será ativada na próxima etapa do módulo Bancário do Nous.',
          style: theme.getTextStyle(
            fontSize: 13,
            color: theme.secondaryTextColor,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.buttonColor,
              foregroundColor: theme.buttonTextColor,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Entendi',
              style: theme.getTextStyle(color: theme.buttonTextColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardMoeda(BuildContext context, String simbolo, String rotulo) {
    return Expanded(
      child: InkWell(
        onTap: () => _mostrarAvisoEmBreve(context, 'Carteira ($rotulo)'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: theme.backgroundColor.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.borderColor.withValues(alpha: 0.7),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: theme.buttonColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    simbolo,
                    style: theme.getTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.buttonTextColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '0,00',
                style: theme.getTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              Text(
                rotulo,
                style: theme.getTextStyle(
                  fontSize: 10,
                  color: theme.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 3 Cards de Moedas (R$, $, €)
        Row(
          children: [
            _cardMoeda(context, 'R\$', 'Real'),
            const SizedBox(width: 10),
            _cardMoeda(context, '\$', 'Dólar'),
            const SizedBox(width: 10),
            _cardMoeda(context, '€', 'Euro'),
          ],
        ),
        const SizedBox(height: 14),

        // Sub-seção Faturas Abertas
        Center(
          child: Text(
            'Faturas Abertas',
            style: theme.getTextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: theme.secondaryTextColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _mostrarAvisoEmBreve(context, 'Faturas Abertas'),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.backgroundColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.credit_card_outlined,
                  size: 18,
                  color: theme.textColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Nenhuma fatura em aberto',
                    style: theme.getTextStyle(
                      fontSize: 12.5,
                      color: theme.textColor,
                    ),
                  ),
                ),
                Text(
                  'R\$ 0,00',
                  style: theme.getTextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Botão Fazer Transferência (alinhado à direita como no protótipo)
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.borderColor),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () =>
                _mostrarAvisoEmBreve(context, 'Fazer Transferência'),
            icon: Icon(
              Icons.swap_horiz_rounded,
              size: 16,
              color: theme.textColor,
            ),
            label: Text(
              'Fazer Transferência',
              style: theme.getTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
