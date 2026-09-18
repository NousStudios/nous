import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/produto_loja_row.dart';

// Um "card" de Grupo de Componentes dentro da aba Loja (grupos criados
// direto pelo botão "Novo Grupo de Componentes", diferente dos grupos
// que já existem dentro de Categoria > Produto > Grupo). É basicamente
// uma cópia do CategoriaLojaContainer — mesmo layout, mesma lógica de
// mostrar os Itens já vinculados a ele — mas com "Editar Grupo" e
// "Excluir Grupo" no menu "⋮" (a Categoria, por enquanto, só tem
// excluir).
class GrupoComponentesLojaContainer extends StatefulWidget {
  final AppTheme theme;
  final String nome;

  // Ids dos itens já escolhidos para este grupo (vem do modelo
  // GrupoComponentesLoja) e a lista completa de itens disponíveis na
  // Loja, pra poder mostrar o nome real de cada um.
  final List<String> itemIds;
  final List<ItemLoja> itensDisponiveis;

  // Chamado quando o usuário escolhe um item no seletor de "Adicionar
  // item". Quem decide guardar esse id no grupo (via copyWith) é a
  // tela que criou este card.
  final ValueChanged<String> onAdicionarItem;

  // Chamado quando o usuário exclui um item da lista do grupo (remove
  // só o vínculo, não apaga o Item da Loja).
  final ValueChanged<String> onRemoverItem;

  // NOVO em relação à Categoria: abre o popup de edição deste grupo.
  final VoidCallback onEditar;

  final VoidCallback onExcluir;

  const GrupoComponentesLojaContainer({
    super.key,
    required this.theme,
    required this.nome,
    required this.itemIds,
    required this.itensDisponiveis,
    required this.onAdicionarItem,
    required this.onRemoverItem,
    required this.onEditar,
    required this.onExcluir,
  });

  @override
  State<GrupoComponentesLojaContainer> createState() =>
      _GrupoComponentesLojaContainerState();
}

class _GrupoComponentesLojaContainerState
    extends State<GrupoComponentesLojaContainer> {
  bool _ativa = true;
  bool _expandida = false;

  // Abre um seletor com os itens da Loja que AINDA NÃO estão neste
  // grupo. Ao tocar em um, ele entra na lista via onAdicionarItem.
  void _abrirSeletorDeItem() {
    final theme = widget.theme;
    final disponiveis = widget.itensDisponiveis
        .where((item) => !widget.itemIds.contains(item.id))
        .toList();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Adicionar item',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: SizedBox(
            width: 280,
            child: disponiveis.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Nenhum item disponível. Crie um item primeiro pelo '
                      'botão "Novo Item".',
                      textAlign: TextAlign.center,
                      style: theme.getTextStyle(
                          fontSize: 13, color: theme.secondaryTextColor),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final item in disponiveis)
                          ListTile(
                            title: Text(item.nome, style: theme.getTextStyle()),
                            onTap: () {
                              widget.onAdicionarItem(item.id);
                              Navigator.of(dialogContext).pop();
                            },
                          ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
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
                  widget.nome,
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
                onTap: _abrirSeletorDeItem,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Adicionar item',
                        style: theme.getTextStyle(fontSize: 11)),
                    const SizedBox(width: 2),
                    Icon(Icons.add_circle_outline,
                        size: 14, color: theme.secondaryTextColor),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _expandida
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: theme.secondaryTextColor,
                ),
                onPressed: () => setState(() => _expandida = !_expandida),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: theme.secondaryTextColor),
                color: theme.cardBackgroundColor,
                onSelected: (valor) {
                  if (valor == 'editar') widget.onEditar();
                  if (valor == 'excluir') widget.onExcluir();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'editar',
                    child: Text('Editar Grupo', style: theme.getTextStyle()),
                  ),
                  PopupMenuItem(
                    value: 'excluir',
                    child: Text('Excluir Grupo', style: theme.getTextStyle()),
                  ),
                ],
              ),
            ],
          ),
          if (_expandida) ...[
            const SizedBox(height: 8),
            if (widget.itemIds.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    const SizedBox(width: 44),
                    Expanded(
                      child: Text('Produto',
                          style: theme.getTextStyle(
                              fontSize: 10,
                              color: theme.secondaryTextColor)),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text('Ativo',
                          textAlign: TextAlign.center,
                          style: theme.getTextStyle(
                              fontSize: 10,
                              color: theme.secondaryTextColor)),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text('Preços',
                          textAlign: TextAlign.center,
                          style: theme.getTextStyle(
                              fontSize: 10,
                              color: theme.secondaryTextColor)),
                    ),
                    const SizedBox(width: 64),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // Pra cada id guardado no grupo, busca o ItemLoja
              // correspondente na lista de disponíveis. Se por algum
              // motivo o item tiver sido excluído em outro lugar,
              // simplesmente pula essa linha em vez de quebrar o app.
              for (final id in widget.itemIds) ...[
                Builder(builder: (context) {
                  final item = widget.itensDisponiveis
                      .where((i) => i.id == id)
                      .firstOrNull;
                  if (item == null) return const SizedBox.shrink();

                  return Column(
                    children: [
                      ProdutoLojaRow(
                        key: ValueKey('produto_$id'),
                        theme: theme,
                        item: item,
                        onExcluir: () => widget.onRemoverItem(id),
                      ),
                      const SizedBox(height: 6),
                    ],
                  );
                }),
              ],
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'Nenhum item neste grupo ainda.',
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