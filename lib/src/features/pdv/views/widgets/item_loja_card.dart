import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

// Um "quadrado" de item dentro da aba Loja (um produto/serviço do
// catálogo). Recebe o nome e o preço reais do item.
class ItemLojaCard extends StatelessWidget {
  final AppTheme theme;
  final String nome;
  final String preco;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  const ItemLojaCard({
    super.key,
    required this.theme,
    required this.nome,
    required this.preco,
    required this.onEditar,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    // Mesmo texto de reserva usado em ProdutoLojaRow, pra manter a
    // consistência: itens sem preço definido mostram "R$ 00,00".
    final textoPreco = preco.isEmpty ? 'R\$ 00,00' : 'R\$ $preco';

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
            nome,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.getTextStyle(fontSize: 11),
          ),
          // NOVO: preço, num tom mais discreto que o nome.
          Text(
            textoPreco,
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 10,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 2),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: Icon(Icons.more_horiz, size: 16, color: theme.secondaryTextColor),
            color: theme.cardBackgroundColor,
            onSelected: (valor) {
              if (valor == 'editar') onEditar();
              if (valor == 'excluir') onExcluir();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'editar',
                child: Text('Editar Item', style: theme.getTextStyle()),
              ),
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