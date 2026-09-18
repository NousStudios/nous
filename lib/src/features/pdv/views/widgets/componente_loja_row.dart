import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

// Uma linha de "Componente" dentro de um Grupo de Componentes (ex: um
// ingrediente extra de um lanche). É o nível mais "de dentro" dessa
// árvore Categoria > Produto > Grupo > Componente. Puramente visual por
// enquanto: nome de exemplo, toggle de ativo e preço fixo.
class ComponenteLojaRow extends StatefulWidget {
  final AppTheme theme;
  final VoidCallback onExcluir;

  const ComponenteLojaRow({
    super.key,
    required this.theme,
    required this.onExcluir,
  });

  @override
  State<ComponenteLojaRow> createState() => _ComponenteLojaRowState();
}

class _ComponenteLojaRowState extends State<ComponenteLojaRow> {
  bool _ativo = true;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Nome do Componente',
              overflow: TextOverflow.ellipsis,
              style: theme.getTextStyle(fontSize: 11),
            ),
          ),
          Switch(
            value: _ativo,
            activeThumbColor: theme.buttonColor,
            onChanged: (valor) => setState(() => _ativo = valor),
          ),
          SizedBox(
            width: 64,
            child: Text(
              'R\$ 00,00',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(fontSize: 11),
            ),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: Icon(Icons.more_vert,
                size: 16, color: theme.secondaryTextColor),
            color: theme.cardBackgroundColor,
            onSelected: (valor) {
              if (valor == 'excluir') widget.onExcluir();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'excluir',
                child: Text('Excluir Componente', style: theme.getTextStyle()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}