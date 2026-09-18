import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

// Um "card" de categoria dentro da aba Loja (ex: "Bebidas", "Lanches").
// Puramente visual por enquanto, igual aos outros containers novos da
// tela (Dados Bancários, Delivery, etc.) antes de ganharem provider: o
// nome ainda é só um texto de exemplo, e o toggle / "Adicionar item" /
// seta / "⋮" ainda não salvam nem carregam nada de verdade.
class CategoriaLojaContainer extends StatefulWidget {
  final AppTheme theme;

  // Chamado quando o usuário escolhe "Excluir Categoria" no menu "⋮".
  // Quem decide o que fazer com isso é a tela que criou este card (ela
  // que sabe tirar este card da lista).
  final VoidCallback onExcluir;

  const CategoriaLojaContainer({
    super.key,
    required this.theme,
    required this.onExcluir,
  });

  @override
  State<CategoriaLojaContainer> createState() =>
      _CategoriaLojaContainerState();
}

class _CategoriaLojaContainerState extends State<CategoriaLojaContainer> {
  // Se a categoria está "ativa" (toggle da esquerda no protótipo).
  bool _ativa = true;

  // Se a seta está apontando pra cima (expandida) ou pra baixo
  // (fechada). Por enquanto não existe conteúdo pra mostrar/esconder de
  // verdade quando expande — é só o desenho da seta que muda.
  bool _expandida = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Nome da Categoria',
              overflow: TextOverflow.ellipsis,
              style: theme.getTextStyle(fontSize: 13),
            ),
          ),
          Switch(
            value: _ativa,
            activeThumbColor: theme.buttonColor,
            onChanged: (valor) => setState(() => _ativa = valor),
          ),
          GestureDetector(
            onTap: () {
              // todo: abrir formulário de novo item já vinculado a esta
              // categoria, quando o provider de itens existir.
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Adicionar item', style: theme.getTextStyle(fontSize: 11)),
                const SizedBox(width: 2),
                Icon(Icons.add_circle_outline,
                    size: 14, color: theme.secondaryTextColor),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _expandida ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: theme.secondaryTextColor,
            ),
            onPressed: () => setState(() => _expandida = !_expandida),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: theme.secondaryTextColor),
            color: theme.cardBackgroundColor,
            onSelected: (valor) {
              if (valor == 'excluir') widget.onExcluir();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'excluir',
                child: Text('Excluir Categoria', style: theme.getTextStyle()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}