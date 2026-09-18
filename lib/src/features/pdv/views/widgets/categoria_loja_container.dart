import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/views/widgets/produto_loja_row.dart';

// Um "card" de categoria dentro da aba Loja (ex: "Bebidas", "Lanches").
// Guarda sua própria lista de Produtos, criada pelo link "Adicionar
// item" no cabeçalho. Ao expandir (seta), mostra esses produtos, cada
// um podendo ser expandido de novo para mostrar seus grupos de
// componentes — é a árvore Categoria > Produto > Grupo > Componente.
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
  // (fechada).
  bool _expandida = false;

  // Produtos desta categoria. Ainda em memória (sem provider) — cada
  // categoria guarda sua própria lista, criada pelo link "Adicionar
  // item".
  final List<int> _produtoIds = [];
  int _proximoIdProduto = 0;

  void _adicionarProduto() {
    setState(() {
      _produtoIds.add(_proximoIdProduto);
      _proximoIdProduto++;
    });
  }

  void _removerProduto(int id) {
    setState(() => _produtoIds.remove(id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                onTap: _adicionarProduto,
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

          // Lista de produtos desta categoria, só aparece com a
          // categoria expandida.
          if (_expandida) ...[
            const SizedBox(height: 8),
            if (_produtoIds.isNotEmpty) ...[
              // Cabeçalho das colunas — só texto, sem interação, pra dar
              // contexto visual (igual ao protótipo: "Produto | Ativo |
              // Preços").
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    const SizedBox(width: 44),
                    Expanded(
                      child: Text('Produto',
                          style: theme.getTextStyle(
                              fontSize: 10, color: theme.secondaryTextColor)),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text('Ativo',
                          textAlign: TextAlign.center,
                          style: theme.getTextStyle(
                              fontSize: 10, color: theme.secondaryTextColor)),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text('Preços',
                          textAlign: TextAlign.center,
                          style: theme.getTextStyle(
                              fontSize: 10, color: theme.secondaryTextColor)),
                    ),
                    const SizedBox(width: 64),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              for (final id in _produtoIds) ...[
                ProdutoLojaRow(
                  key: ValueKey('produto_$id'),
                  theme: theme,
                  onExcluir: () => _removerProduto(id),
                ),
                const SizedBox(height: 6),
              ],
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'Nenhum item nesta categoria ainda.',
                  style: theme.getTextStyle(
                      fontSize: 11, color: theme.secondaryTextColor),
                ),
              ),
          ],
        ],
      ),
    );
  }
}