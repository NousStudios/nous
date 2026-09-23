import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/produto_loja_row.dart';

class CategoriaLojaContainer extends StatefulWidget {
  final AppTheme theme;
  final String nome;
  final String preco;

  final List<String> itemIds;
  final List<ItemLoja> itensDisponiveis;

  final bool expandida;
  final VoidCallback aoAlternarExpansao;

  final ValueChanged<String> onAdicionarItem;
  final ValueChanged<String> onRemoverItem;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  final ValueChanged<String>? onNomeAlterado;

  final void Function(String itemId, String novoNome) onEditarNomeItem;
  final void Function(String itemId, String novoPreco) onEditarPrecoItem;

  final void Function(ItemLoja item) onEditarItem;

  const CategoriaLojaContainer({
    super.key,
    required this.theme,
    required this.nome,
    required this.preco,
    required this.itemIds,
    required this.itensDisponiveis,
    required this.expandida,
    required this.aoAlternarExpansao,
    required this.onAdicionarItem,
    required this.onRemoverItem,
    required this.onEditar,
    required this.onExcluir,
    required this.onEditarNomeItem,
    required this.onEditarPrecoItem,
    required this.onEditarItem,
    this.onNomeAlterado,
  });

  @override
  State<CategoriaLojaContainer> createState() =>
      _CategoriaLojaContainerState();
}

class _CategoriaLojaContainerState extends State<CategoriaLojaContainer> {
  bool _ativa = true;

  late final TextEditingController _nomeController =
      TextEditingController(text: widget.nome);

  @override
  void didUpdateWidget(covariant CategoriaLojaContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.nome != oldWidget.nome && widget.nome != _nomeController.text) {
      _nomeController.text = widget.nome;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

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
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.6)),
                ),
                child: Icon(Icons.image_outlined,
                    size: 16, color: theme.secondaryTextColor),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _nomeController,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: theme.getTextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                  onChanged: (valor) => widget.onNomeAlterado?.call(valor),
                ),
              ),
              if (widget.preco.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    'R\$ ${widget.preco}',
                    style: theme.getTextStyle(
                      fontSize: 10,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ),
              ],
              SizedBox(
                width: 32,
                height: 20,
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: Switch(
                    value: _ativa,
                    activeThumbColor: theme.buttonColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (valor) => setState(() => _ativa = valor),
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 18,
                tooltip: 'Adicionar item',
                icon: Icon(Icons.add_circle_outline,
                    color: theme.secondaryTextColor),
                onPressed: _abrirSeletorDeItem,
              ),
              const SizedBox(width: 2),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 18,
                icon: Icon(
                  widget.expandida
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: theme.secondaryTextColor,
                ),
                onPressed: widget.aoAlternarExpansao,
              ),
              const SizedBox(width: 2),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                iconSize: 18,
                icon: Icon(Icons.more_vert, color: theme.secondaryTextColor),
                color: theme.cardBackgroundColor,
                onSelected: (valor) {
                  if (valor == 'editar') widget.onEditar();
                  if (valor == 'excluir') widget.onExcluir();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'editar',
                    child: Text('Editar Categoria', style: theme.getTextStyle()),
                  ),
                  PopupMenuItem(
                    value: 'excluir',
                    child: Text('Excluir Categoria',
                        style: theme.getTextStyle()),
                  ),
                ],
              ),
            ],
          ),
          if (widget.expandida) ...[
            const SizedBox(height: 8),
            if (widget.itemIds.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    const SizedBox(width: 40),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Produtos',
                          style: theme.getTextStyle(
                              fontSize: 10,
                              color: theme.secondaryTextColor),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 56,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Ativo',
                          style: theme.getTextStyle(
                              fontSize: 10,
                              color: theme.secondaryTextColor),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 56,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Preços',
                          style: theme.getTextStyle(
                              fontSize: 10,
                              color: theme.secondaryTextColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 60),
                  ],
                ),
              ),
              const SizedBox(height: 6),
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
                        onEditar: () => widget.onEditarItem(item),
                        onNomeAlterado: (novoNome) =>
                            widget.onEditarNomeItem(id, novoNome),
                        onPrecoAlterado: (novoPreco) =>
                            widget.onEditarPrecoItem(id, novoPreco),
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