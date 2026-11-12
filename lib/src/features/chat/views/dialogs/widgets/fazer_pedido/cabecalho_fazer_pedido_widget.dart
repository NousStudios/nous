import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Cabeçalho padrão do Autoatendimento: Botão "Minha Ficha" alinhado ao "Fechar",
/// e Título com Subtítulo centralizados no topo.
class CabecalhoFazerPedidoChatWidget extends StatelessWidget {
  final AppTheme theme;
  final String nomeLoja;
  final bool vendoCarrinho;
  final VoidCallback onAbrirMinhaFicha;
  final VoidCallback onFechar;

  const CabecalhoFazerPedidoChatWidget({
    super.key,
    required this.theme,
    required this.nomeLoja,
    required this.vendoCarrinho,
    required this.onAbrirMinhaFicha,
    required this.onFechar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                icon: Icon(
                  Icons.badge_outlined,
                  size: 16,
                  color: theme.textColor,
                ),
                label: Text(
                  'Minha Ficha',
                  style: theme.getTextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                onPressed: onAbrirMinhaFicha,
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: theme.secondaryTextColor,
                  size: 20,
                ),
                onPressed: onFechar,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Column(
            children: [
              Text(
                'Pedido • $nomeLoja',
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                vendoCarrinho
                    ? 'Confira sua comanda e forma de pagamento'
                    : 'Toque nos itens para adicionar ou personalizar',
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 11,
                  color: theme.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: theme.borderColor.withValues(alpha: 0.3)),
      ],
    );
  }
}
