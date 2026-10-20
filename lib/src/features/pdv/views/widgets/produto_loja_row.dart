import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/core/widgets/themed_switch.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

class ProdutoLojaRow extends StatefulWidget {
  final AppTheme theme;
  final ItemLoja item;
  final VoidCallback onExcluir;
  final VoidCallback onEditar;
  final ValueChanged<String> onNomeAlterado;
  final ValueChanged<String> onPrecoAlterado;
  final bool podeEditar;

  const ProdutoLojaRow({
    super.key,
    required this.theme,
    required this.item,
    required this.onExcluir,
    required this.onEditar,
    required this.onNomeAlterado,
    required this.onPrecoAlterado,
    this.podeEditar = true,
  });

  @override
  State<ProdutoLojaRow> createState() => _ProdutoLojaRowState();
}

class _ProdutoLojaRowState extends State<ProdutoLojaRow> {
  bool _ativo = true;
  bool _expandido = false;
  bool _editandoNome = false;

  late final TextEditingController _nomeController =
      TextEditingController(text: widget.item.nome);
  late final FocusNode _nomeFocusNode = FocusNode();
  late final TextEditingController _precoController =
      TextEditingController(text: widget.item.preco);

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
  void didUpdateWidget(covariant ProdutoLojaRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.item.nome != oldWidget.item.nome &&
        widget.item.nome != _nomeController.text) {
      _nomeController.text = widget.item.nome;
    }
    if (widget.item.preco != oldWidget.item.preco &&
        widget.item.preco != _precoController.text) {
      _precoController.text = widget.item.preco;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _nomeFocusNode.dispose();
    _precoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final podeEditar = widget.podeEditar;

    return Container(
      padding: const EdgeInsets.only(left: 6, right: 2, top: 6, bottom: 6),
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
                      color: theme.borderColor.withValues(alpha: 0.6),
                    ),
                  ),
                  child: () {
                    final fotoResolvida =
                        ImagemService.resolverCaminhoExistente(
                            widget.item.imagens.firstOrNull ?? '');
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
              const SizedBox(width: 4),
              Expanded(
                child: _editandoNome
                    ? TextField(
                        focusNode: _nomeFocusNode,
                        controller: _nomeController,
                        textAlign: TextAlign.start,
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
                        onChanged: widget.onNomeAlterado,
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
                              horizontal: 2, vertical: 4),
                          child: TextoRolante(
                            texto: widget.item.nome.trim().isEmpty
                                ? 'Sem nome'
                                : widget.item.nome,
                            textAlign: TextAlign.start,
                            style: theme.getTextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: widget.item.nome.trim().isEmpty
                                  ? theme.secondaryTextColor
                                      .withValues(alpha: 0.5)
                                  : theme.textColor,
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'R\$ ',
                      style: theme.getTextStyle(
                        fontSize: 10,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                    IntrinsicWidth(
                      child: TextField(
                        controller: _precoController,
                        readOnly: !podeEditar,
                        onTap: podeEditar ? null : _avisarSemPermissao,
                        textAlign: TextAlign.start,
                        keyboardType: TextInputType.number,
                        style: theme.getTextStyle(
                          fontSize: 10,
                          color: theme.secondaryTextColor,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          hintText: '0,00',
                        ),
                        onChanged: widget.onPrecoAlterado,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 3),
              SizedBox(
                width: 28,
                height: 16,
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: ThemedSwitch(
                    theme: theme,
                    value: _ativo,
                    onChanged: podeEditar
                        ? (valor) => setState(() => _ativo = valor)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Tooltip(
                message: _expandido ? 'Recolher' : 'Expandir',
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () => setState(() => _expandido = !_expandido),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: Icon(
                      _expandido
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              PopupMenuButton<String>(
                tooltip: 'Mais opções',
                padding: EdgeInsets.zero,
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
                    child: Text('Editar Item', style: theme.getTextStyle()),
                  ),
                  PopupMenuItem(
                    value: 'excluir',
                    child: Text(
                      'Excluir Produto',
                      style: theme.getTextStyle(color: theme.dangerColor),
                    ),
                  ),
                ],
                child: SizedBox(
                  width: 20,
                  height: 22,
                  child: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
          if (_expandido) ...[
            if (widget.item.descricao.isNotEmpty ||
                widget.item.variantes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.item.descricao.isNotEmpty)
                      Text(
                        widget.item.descricao,
                        style: theme.getTextStyle(
                          fontSize: 11,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    if (widget.item.variantes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: widget.item.variantes.map((v) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.borderColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: theme.borderColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '${v.nome}: R\$ ${v.preco}',
                              style: theme.getTextStyle(
                                fontSize: 10,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'Nenhuma variante ou descrição para este item.',
                  style: theme.getTextStyle(
                    fontSize: 11,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}