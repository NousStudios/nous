import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';

class ItemLojaCard extends StatefulWidget {
  final AppTheme theme;
  final String nome;
  final String preco;
  final TipoItemLoja? tipo;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  final ValueChanged<String> onNomeAlterado;
  final ValueChanged<String> onPrecoAlterado;

  const ItemLojaCard({
    super.key,
    required this.theme,
    required this.nome,
    required this.preco,
    this.tipo,
    required this.onEditar,
    required this.onExcluir,
    required this.onNomeAlterado,
    required this.onPrecoAlterado,
  });

  @override
  State<ItemLojaCard> createState() => _ItemLojaCardState();
}

class _ItemLojaCardState extends State<ItemLojaCard> {
  late final TextEditingController _nomeController =
      TextEditingController(text: widget.nome);
  late final TextEditingController _precoController =
      TextEditingController(text: widget.preco);

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
    return Container(
      decoration: BoxDecoration(
        color: theme.borderColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.3)),
      ),
      child: Stack(
        children: [
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

    return Container(
      width: 112,
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
          TextField(
            controller: _nomeController,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: theme.getTextStyle(fontSize: 13, color: theme.textColor),
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
            onChanged: widget.onNomeAlterado,
          ),
          const SizedBox(height: 6),
          _buildPreco(theme),
        ],
      ),
    );
  }
}