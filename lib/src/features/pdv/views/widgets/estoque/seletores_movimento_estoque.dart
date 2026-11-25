import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/fornecedor.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/views/widgets/estoque/botao_hover_tipo_estoque.dart';

/// Seletores de item, tipo (entrada/saída), categoria e fornecedor
/// para o diálogo de movimento de estoque.
class SeletoresMovimentoEstoque extends StatelessWidget {
  final AppTheme theme;
  final List<ItemLoja> itens;
  final ItemLoja? itemSelecionado;
  final ValueChanged<ItemLoja?> onItemAlterado;
  final Widget? cardAjustesRapidos;
  final TipoMovimentoEstoque tipoSelecionado;
  final ValueChanged<TipoMovimentoEstoque> onTipoAlterado;
  final CategoriaMovimentoEstoque categoriaSelecionada;
  final ValueChanged<CategoriaMovimentoEstoque> onCategoriaAlterada;
  final List<Fornecedor> fornecedores;
  final Fornecedor? fornecedorSelecionado;
  final ValueChanged<Fornecedor?> onFornecedorAlterado;

  const SeletoresMovimentoEstoque({
    super.key,
    required this.theme,
    required this.itens,
    required this.itemSelecionado,
    required this.onItemAlterado,
    this.cardAjustesRapidos,
    required this.tipoSelecionado,
    required this.onTipoAlterado,
    required this.categoriaSelecionada,
    required this.onCategoriaAlterada,
    required this.fornecedores,
    required this.fornecedorSelecionado,
    required this.onFornecedorAlterado,
  });

  static const Map<CategoriaMovimentoEstoque, String> _rotulosCategoria = {
    CategoriaMovimentoEstoque.compra: 'Compra',
    CategoriaMovimentoEstoque.venda: 'Venda',
    CategoriaMovimentoEstoque.producao: 'Produção',
    CategoriaMovimentoEstoque.perda: 'Perda',
    CategoriaMovimentoEstoque.ajuste: 'Ajuste',
  };

  @override
  Widget build(BuildContext context) {
    final ehEntrada = tipoSelecionado == TipoMovimentoEstoque.entrada;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _tituloDoBloco('Item'),
        _dropdownItem(),
        ?cardAjustesRapidos,
        const SizedBox(height: 16),
        _tituloDoBloco('Tipo'),
        Row(
          children: [
            Expanded(
              child: BotaoHoverTipoEstoque(
                theme: theme,
                rotulo: 'Entrada',
                selecionado: tipoSelecionado == TipoMovimentoEstoque.entrada,
                aoClicar: () => onTipoAlterado(TipoMovimentoEstoque.entrada),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: BotaoHoverTipoEstoque(
                theme: theme,
                rotulo: 'Saída',
                selecionado: tipoSelecionado == TipoMovimentoEstoque.saida,
                aoClicar: () => onTipoAlterado(TipoMovimentoEstoque.saida),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _tituloDoBloco('Categoria'),
        _dropdownCategoria(),
        if (ehEntrada) ...[
          const SizedBox(height: 16),
          _tituloDoBloco('Fornecedor (opcional)'),
          _dropdownFornecedor(),
        ],
      ],
    );
  }

  Widget _tituloDoBloco(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: theme.getTextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: theme.textColor,
        ),
      ),
    );
  }

  Widget _molduraDropdown({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonHideUnderline(child: child),
    );
  }

  Widget _dropdownItem() {
    if (itens.isEmpty) {
      return Text(
        'Nenhum item cadastrado ainda.',
        textAlign: TextAlign.center,
        style: theme.getTextStyle(
          fontSize: 12,
          color: theme.secondaryTextColor,
        ),
      );
    }
    return _molduraDropdown(
      child: DropdownButton<ItemLoja>(
        value: itemSelecionado,
        isExpanded: true,
        dropdownColor: theme.cardBackgroundColor,
        hint: Text(
          'Selecione o item',
          style: theme.getTextStyle(
            fontSize: 12,
            color: theme.secondaryTextColor,
          ),
        ),
        items: itens
            .map(
              (i) => DropdownMenuItem<ItemLoja>(
                value: i,
                child: Text(
                  i.nome.isEmpty ? 'Item sem nome' : i.nome,
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.textColor,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: onItemAlterado,
      ),
    );
  }

  Widget _dropdownCategoria() {
    return _molduraDropdown(
      child: DropdownButton<CategoriaMovimentoEstoque>(
        value: categoriaSelecionada,
        isExpanded: true,
        dropdownColor: theme.cardBackgroundColor,
        items: _rotulosCategoria.entries
            .map(
              (e) => DropdownMenuItem<CategoriaMovimentoEstoque>(
                value: e.key,
                child: Text(
                  e.value,
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.textColor,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: (valor) {
          if (valor != null) onCategoriaAlterada(valor);
        },
      ),
    );
  }

  Widget _dropdownFornecedor() {
    if (fornecedores.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          'Nenhum fornecedor cadastrado ainda. Abra "Fornecedores" no '
          'Estoque para cadastrar.',
          textAlign: TextAlign.center,
          style: theme.getTextStyle(
            fontSize: 11,
            color: theme.secondaryTextColor,
          ),
        ),
      );
    }
    return _molduraDropdown(
      child: DropdownButton<Fornecedor?>(
        value: fornecedorSelecionado,
        isExpanded: true,
        dropdownColor: theme.cardBackgroundColor,
        hint: Text(
          'Sem fornecedor',
          style: theme.getTextStyle(
            fontSize: 12,
            color: theme.secondaryTextColor,
          ),
        ),
        items: [
          DropdownMenuItem<Fornecedor?>(
            value: null,
            child: Text(
              'Sem fornecedor',
              style: theme.getTextStyle(
                fontSize: 12,
                color: theme.secondaryTextColor,
              ),
            ),
          ),
          ...fornecedores.map(
            (f) => DropdownMenuItem<Fornecedor?>(
              value: f,
              child: Text(
                f.nome.isEmpty ? 'Fornecedor sem nome' : f.nome,
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.textColor,
                ),
              ),
            ),
          ),
        ],
        onChanged: onFornecedorAlterado,
      ),
    );
  }
}
