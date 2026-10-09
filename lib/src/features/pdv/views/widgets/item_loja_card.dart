import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';

class ItemLojaCard extends StatefulWidget {
  final AppTheme theme;
  final String nome;
  final String preco;
  final TipoItemLoja? tipo;
  final String? imagemUrl;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;
  final ValueChanged<String> onNomeAlterado;
  final ValueChanged<String> onPrecoAlterado;
  final bool podeEditar;

  const ItemLojaCard({
    super.key,
    required this.theme,
    required this.nome,
    required this.preco,
    this.tipo,
    this.imagemUrl,
    required this.onEditar,
    required this.onExcluir,
    required this.onNomeAlterado,
    required this.onPrecoAlterado,
    this.podeEditar = true,
  });

  @override
  State<ItemLojaCard> createState() => _ItemLojaCardState();
}

class _ItemLojaCardState extends State<ItemLojaCard> {
  late final TextEditingController _nomeController =
      TextEditingController(text: widget.nome);
  late final TextEditingController _precoController =
      TextEditingController(text: widget.preco);
  late final FocusNode _nomeFocusNode = FocusNode();
  bool _editandoNome = false;

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
  void initState() {
    super.initState();
    _nomeFocusNode.addListener(() {
      if (!_nomeFocusNode.hasFocus && mounted) {
        setState(() => _editandoNome = false);
      }
    });
  }

  @override
  void didUpdateWidget(covariant ItemLojaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.nome != oldWidget.nome && widget.nome != _nomeController.text) {
      _nomeController.text = widget.nome;
    }
    if (widget.preco != oldWidget.preco &&
        widget.preco != _precoController.text) {
      _precoController.text = widget.preco;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _precoController.dispose();
    _nomeFocusNode.dispose();
    super.dispose();
  }

  String _rotuloDoTipo() {
    switch (widget.tipo) {
      case TipoItemLoja.produto:
        return 'Produto';
      case TipoItemLoja.servico:
        return 'Serviço';
      case null:
        return '';
    }
  }

  IconData _iconeDoTipo() {
    return widget.tipo == TipoItemLoja.servico
        ? Icons.handyman_outlined
        : Icons.inventory_2_outlined;
  }

  Widget _buildEtiquetaTipo(AppTheme theme, String rotuloTipo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: theme.borderColor.withValues(alpha: 0.5)),
          ),
          child: Text(
            rotuloTipo,
            maxLines: 1,
            style: theme.getTextStyle(
              fontSize: 9,
              color: theme.secondaryTextColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAreaImagem(AppTheme theme) {
    final temImagem = widget.imagemUrl != null &&
        widget.imagemUrl!.isNotEmpty &&
        File(widget.imagemUrl!).existsSync();

    return Container(
      decoration: BoxDecoration(
        color: theme.borderColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.3)),
      ),
      child: Stack(
        children: [
          if (temImagem)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(widget.imagemUrl!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(_iconeDoTipo(),
                        size: 30, color: theme.secondaryTextColor),
                  ),
                ),
              ),
            )
          else
            Center(
              child: Icon(_iconeDoTipo(),
                  size: 30, color: theme.secondaryTextColor),
            ),
          Positioned(
            top: 0,
            right: 0,
            child: SizedBox(
              width: 28,
              height: 28,
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                iconSize: 16,
                icon: Icon(Icons.more_vert, color: theme.secondaryTextColor),
                color: theme.cardBackgroundColor,
                onSelected: (valor) {
                  if (!widget.podeEditar) {
                    _avisarSemPermissao();
                    return;
                  }
                  if (valor == 'editar') widget.onEditar();
                  if (valor == 'excluir') widget.onExcluir();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'editar',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined,
                            size: 16, color: theme.secondaryTextColor),
                        const SizedBox(width: 8),
                        Text('Editar Item', style: theme.getTextStyle()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'excluir',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: 16, color: theme.secondaryTextColor),
                        const SizedBox(width: 8),
                        Text('Excluir Item', style: theme.getTextStyle()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreco(AppTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Text(
            'R\$',
            style: theme.getTextStyle(
              fontSize: 10,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: _precoController,
              readOnly: !widget.podeEditar,
              onTap: widget.podeEditar ? null : _avisarSemPermissao,
              maxLines: 1,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                hintText: '00,00',
                hintStyle: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor.withValues(alpha: 0.5),
                ),
              ),
              onChanged: widget.onPrecoAlterado,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final rotuloTipo = _rotuloDoTipo();
    final double escala = theme.fontScale > 1.0 ? theme.fontScale : 1.0;
    final double larguraCard =
        (112 * (1.0 + (escala - 1.0) * 0.35)).clamp(112.0, 145.0);
    final double alturaNome = (22 * escala).clamp(22.0, 34.0);

    return Container(
      width: larguraCard,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (rotuloTipo.isNotEmpty) _buildEtiquetaTipo(theme, rotuloTipo),
          Expanded(child: _buildAreaImagem(theme)),
          const SizedBox(height: 6),
          _editandoNome
              ? SizedBox(
                  height: alturaNome,
                  child: TextField(
                    controller: _nomeController,
                    focusNode: _nomeFocusNode,
                    readOnly: !widget.podeEditar,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: theme.getTextStyle(
                        fontSize: 13, color: theme.textColor),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: 'Sem nome',
                      hintStyle: theme.getTextStyle(
                        fontSize: 13,
                        color: theme.secondaryTextColor.withValues(alpha: 0.5),
                      ),
                    ),
                    onSubmitted: (_) {
                      if (mounted) setState(() => _editandoNome = false);
                    },
                    onChanged: widget.onNomeAlterado,
                  ),
                )
              : InkWell(
                  onTap: widget.podeEditar
                      ? () {
                          setState(() => _editandoNome = true);
                          _nomeFocusNode.requestFocus();
                        }
                      : _avisarSemPermissao,
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: alturaNome,
                    width: double.infinity,
                    child: TextoRolante(
                      texto: widget.nome.trim().isEmpty
                          ? 'Sem nome'
                          : widget.nome,
                      textAlign: TextAlign.center,
                      style: theme.getTextStyle(
                        fontSize: 13,
                        color: widget.nome.trim().isEmpty
                            ? theme.secondaryTextColor.withValues(alpha: 0.5)
                            : theme.textColor,
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 6),
          _buildPreco(theme),
        ],
      ),
    );
  }
}