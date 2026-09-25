import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

class ComponenteLojaRow extends StatefulWidget {
  final AppTheme theme;
  final VoidCallback onExcluir;
  final bool podeEditar;

  const ComponenteLojaRow({
    super.key,
    required this.theme,
    required this.onExcluir,
    this.podeEditar = true,
  });

  @override
  State<ComponenteLojaRow> createState() => _ComponenteLojaRowState();
}

class _ComponenteLojaRowState extends State<ComponenteLojaRow> {
  bool _ativo = true;

  void _avisarSemPermissao() {
    final theme = widget.theme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardBackgroundColor,
        content: Text(
          'Você não tem permissão para fazer isso.',
          style: theme.getTextStyle(color: theme.textColor),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final podeEditar = widget.podeEditar;

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
            onChanged: podeEditar
                ? (valor) => setState(() => _ativo = valor)
                : null,
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
              if (!podeEditar) {
                _avisarSemPermissao();
                return;
              }
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