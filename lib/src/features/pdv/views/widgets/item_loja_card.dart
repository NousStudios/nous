import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

// Um "quadrado" de item dentro da aba Loja (um produto do catálogo).
// Puramente visual por enquanto — ícone, nome de exemplo e um menu
// "..." que hoje só sabe tirar o card da tela, sem salvar nada de
// verdade ainda (falta o provider de itens).
class ItemLojaCard extends StatelessWidget {
  final AppTheme theme;
  final VoidCallback onExcluir;

  const ItemLojaCard({
    super.key,
    required this.theme,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 32, color: theme.secondaryTextColor),
          const SizedBox(height: 6),
          Text(
            'Nome do produto',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.getTextStyle(fontSize: 11),
          ),
          const SizedBox(height: 2),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: Icon(Icons.more_horiz, size: 16, color: theme.secondaryTextColor),
            color: theme.cardBackgroundColor,
            onSelected: (valor) {
              if (valor == 'excluir') onExcluir();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'excluir',
                child: Text('Excluir Item', style: theme.getTextStyle()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}