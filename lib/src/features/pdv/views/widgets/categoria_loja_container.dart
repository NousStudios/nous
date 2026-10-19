import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/core/widgets/themed_switch.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/produto_loja_row.dart';

class CategoriaLojaContainer extends StatefulWidget {
  final AppTheme theme;
  final String nome;
  final String preco;
  final String foto;

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

  final bool podeEditar;

  const CategoriaLojaContainer({
    super.key,
    required this.theme,
    required this.nome,
    required this.preco,
    this.foto = '',
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
    this.podeEditar = true,
  });

  @override
  State<CategoriaLojaContainer> createState() =>
      _CategoriaLojaContainerState();
}

class _CategoriaLojaContainerState extends State<CategoriaLojaContainer> {
  bool _ativa = true;
  bool _editandoNome = false;

  late final TextEditingController _nomeController =
      TextEditingController(text: widget.nome);
  late final FocusNode _nomeFocusNode = FocusNode();

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
  void didUpdateWidget(covariant CategoriaLojaContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.nome != oldWidget.nome && widget.nome != _nomeController.text) {
      _nomeController.text = widget.nome;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _nomeFocusNode.dispose();
    super.dispose();
  }

  void _abrirSeletorDeItem() {
    if (!widget.podeEditar) {
      _avisarSemPermissao();
      return;
    }

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
    final podeEditar = widget.podeEditar;

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
              InkWell(
                onTap: podeEditar ? widget.onEditar : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.6)),
                  ),
                  child: () {
                    final fotoResolvida =
                        ImagemService.resolverCaminhoExistente(widget.foto);
                    return (fotoResolvida != null)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Image.file(
                              File(fotoResolvida),
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                Icons.broken_image_outlined,
                                size: 16,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.image_outlined,
                            size: 16,
                            color: theme.secondaryTextColor,
                          );
                  }(),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _editandoNome
                    ? TextField(
                        focusNode: _nomeFocusNode,
                        controller: _nomeController,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: theme.getTextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) {
                          if (mounted) setState(() => _editandoNome = false);
                        },
                        onEditingComplete: () {
                          if (mounted) setState(() => _editandoNome = false);
                        },
                        onChanged: (valor) =>
                            widget.onNomeAlterado?.call(valor),
                      )
                    : InkWell(
                        onTap: podeEditar
                            ? () {
                                setState(() => _editandoNome = true);
                                _nomeFocusNode.requestFocus();
                              }
                            : _avisarSemPermissao,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 4),
                          child: TextoRolante(
                            texto: widget.nome.trim().isEmpty
                                ? 'Sem nome'
                                : widget.nome,
                            textAlign: TextAlign.center,
                            style: theme.getTextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: widget.nome.trim().isEmpty
                                  ? theme.secondaryTextColor
                                      .withValues(alpha: 0.5)
                                  : theme.textColor,
                            ),
                          ),
                        ),
                      ),
              ),
              if (widget.preco.isNotEmpty) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
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
              const SizedBox(width: 4),
              SizedBox(
                width: 30,
                height: 18,
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: ThemedSwitch(
                    theme: theme,
                    value: _ativa,
                    onChanged: podeEditar
                        ? (valor) => setState(() => _ativa = valor)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                iconSize: 18,
                tooltip: 'Adicionar item',
                icon: Icon(Icons.add_circle_outline,
                    color: theme.secondaryTextColor),
                onPressed: _abrirSeletorDeItem,
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                iconSize: 18,
                icon: Icon(
                  widget.expandida
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: theme.secondaryTextColor,
                ),
                onPressed: widget.aoAlternarExpansao,
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                iconSize: 18,
                icon: Icon(Icons.more_vert, color: theme.secondaryTextColor),
                color: theme.cardBackgroundColor,
                onSelected: (valor) {
                  if (!podeEditar) {
                    _avisarSemPermissao();
                    return;
                  }
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
                        style: theme.getTextStyle(color: theme.dangerColor)),
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
                        podeEditar: podeEditar,
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