import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/fornecedor.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';

class MovimentoEstoqueDialog {
  static Future<MovimentoEstoque?> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required List<ItemLoja> itens,
    List<Fornecedor> fornecedores = const [],
    required String cpfAutor,
    required String nomeAutor,
    ItemLoja? itemInicial,
    TipoMovimentoEstoque? tipoInicial,
  }) {
    return showDialog<MovimentoEstoque>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: theme.cardBackgroundColor,
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: _MovimentoEstoqueConteudo(
              theme: theme,
              itens: itens,
              fornecedores: fornecedores,
              cpfAutor: cpfAutor,
              nomeAutor: nomeAutor,
              itemInicial: itemInicial,
              tipoInicial: tipoInicial,
            ),
          ),
        );
      },
    );
  }
}

class _MovimentoEstoqueConteudo extends StatefulWidget {
  final AppTheme theme;
  final List<ItemLoja> itens;
  final List<Fornecedor> fornecedores;
  final String cpfAutor;
  final String nomeAutor;
  final ItemLoja? itemInicial;
  final TipoMovimentoEstoque? tipoInicial;

  const _MovimentoEstoqueConteudo({
    required this.theme,
    required this.itens,
    required this.fornecedores,
    required this.cpfAutor,
    required this.nomeAutor,
    this.itemInicial,
    this.tipoInicial,
  });

  @override
  State<_MovimentoEstoqueConteudo> createState() =>
      _MovimentoEstoqueConteudoState();
}

class _MovimentoEstoqueConteudoState
    extends State<_MovimentoEstoqueConteudo> {
  final _quantidadeController = TextEditingController();
  final _custoController = TextEditingController();
  final _motivoController = TextEditingController();

  ItemLoja? _item;
  Fornecedor? _fornecedor;
  TipoMovimentoEstoque _tipo = TipoMovimentoEstoque.entrada;
  CategoriaMovimentoEstoque _categoria = CategoriaMovimentoEstoque.compra;
  String? _aviso;

  AppTheme get theme => widget.theme;

  @override
  void initState() {
    super.initState();
    _item = widget.itemInicial;
    if (widget.tipoInicial != null) {
      _tipo = widget.tipoInicial!;
      _categoria = _tipo == TipoMovimentoEstoque.entrada
          ? CategoriaMovimentoEstoque.compra
          : CategoriaMovimentoEstoque.ajuste;
    }
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    _custoController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  String _rotuloUnidade(ItemLoja item) {
    switch (item.unidadeBase) {
      case UnidadeItemLoja.un:
        return 'un';
      case UnidadeItemLoja.g:
        return 'g';
      case UnidadeItemLoja.ml:
        return 'ml';
    }
  }

  double? _quantidadeParseada() {
    final texto =
        _quantidadeController.text.trim().replaceAll(',', '.');
    return double.tryParse(texto);
  }

  void _confirmar() {
    final item = _item;
    if (item == null) {
      setState(() => _aviso = 'Selecione o item.');
      return;
    }

    final quantidade = _quantidadeParseada();
    if (quantidade == null || quantidade <= 0) {
      setState(() => _aviso = 'Informe uma quantidade válida.');
      return;
    }

    final custoTexto =
        _custoController.text.trim().replaceAll('.', '').replaceAll(',', '.');
    final custo = custoTexto.isEmpty ? 0.0 : double.tryParse(custoTexto);
    if (custo == null || custo < 0) {
      setState(() => _aviso = 'Custo unitário inválido.');
      return;
    }

    final movimento = MovimentoEstoque.novo(
      itemId: item.id,
      tipo: _tipo,
      quantidade: quantidade,
      custoUnitario: custo,
      motivo: _motivoController.text.trim(),
      cpfAutor: widget.cpfAutor,
      nomeAutor: widget.nomeAutor,
      fornecedorId: _tipo == TipoMovimentoEstoque.entrada
          ? (_fornecedor?.id ?? '')
          : '',
      fornecedorNome: _tipo == TipoMovimentoEstoque.entrada
          ? (_fornecedor?.nome ?? '')
          : '',
      categoria: _categoria,
    );

    Navigator.of(context).pop(movimento);
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

  InputDecoration _decoracaoCampo(String dica) {
    OutlineInputBorder borda(Color cor) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cor),
        );
    return InputDecoration(
      hintText: dica,
      hintStyle:
          theme.getTextStyle(fontSize: 12, color: theme.secondaryTextColor),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: borda(theme.borderColor),
      focusedBorder: borda(theme.textColor),
    );
  }

  Widget _botaoTipo(String rotulo, TipoMovimentoEstoque tipo) {
    final selecionado = _tipo == tipo;
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor:
              selecionado ? theme.buttonColor : Colors.transparent,
          foregroundColor:
              selecionado ? theme.buttonTextColor : theme.textColor,
          side: BorderSide(color: theme.borderColor),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () => setState(() {
          _tipo = tipo;
          if (tipo == TipoMovimentoEstoque.saida) {
            _fornecedor = null;
            _categoria = CategoriaMovimentoEstoque.ajuste;
          } else {
            _categoria = CategoriaMovimentoEstoque.compra;
          }
          _aviso = null;
        }),
        child: Text(
          rotulo,
          style: theme.getTextStyle(
            fontSize: 12,
            color: selecionado ? theme.buttonTextColor : theme.textColor,
          ),
        ),
      ),
    );
  }

  Widget _dropdownItem() {
    final item = _item;
    if (widget.itens.isEmpty) {
      return Text(
        'Nenhum item cadastrado ainda.',
        textAlign: TextAlign.center,
        style: theme.getTextStyle(
          fontSize: 12,
          color: theme.secondaryTextColor,
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ItemLoja>(
          value: item,
          isExpanded: true,
          dropdownColor: theme.cardBackgroundColor,
          hint: Text(
            'Selecione o item',
            style: theme.getTextStyle(
              fontSize: 12,
              color: theme.secondaryTextColor,
            ),
          ),
          items: widget.itens
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
          onChanged: (valor) => setState(() {
            _item = valor;
            _aviso = null;
          }),
        ),
      ),
    );
  }

  Widget _dropdownFornecedor() {
    if (widget.fornecedores.isEmpty) {
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Fornecedor?>(
          value: _fornecedor,
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
            ...widget.fornecedores.map(
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
          onChanged: (valor) => setState(() {
            _fornecedor = valor;
            _aviso = null;
          }),
        ),
      ),
    );
  }

  Widget _dropdownCategoria() {
    final opcoes = <CategoriaMovimentoEstoque, String>{
      CategoriaMovimentoEstoque.compra: 'Compra',
      CategoriaMovimentoEstoque.venda: 'Venda',
      CategoriaMovimentoEstoque.producao: 'Produção',
      CategoriaMovimentoEstoque.perda: 'Perda',
      CategoriaMovimentoEstoque.ajuste: 'Ajuste',
    };
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CategoriaMovimentoEstoque>(
          value: _categoria,
          isExpanded: true,
          dropdownColor: theme.cardBackgroundColor,
          items: opcoes.entries
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
            if (valor == null) return;
            setState(() {
              _categoria = valor;
              _aviso = null;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ehEntrada = _tipo == TipoMovimentoEstoque.entrada;
    final item = _item;
    final unidade = item == null ? 'un' : _rotuloUnidade(item);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: theme.textColor),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  'Movimento de Estoque',
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _tituloDoBloco('Item'),
                _dropdownItem(),
                const SizedBox(height: 16),
                _tituloDoBloco('Tipo'),
                Row(
                  children: [
                    _botaoTipo('Entrada', TipoMovimentoEstoque.entrada),
                    const SizedBox(width: 8),
                    _botaoTipo('Saída', TipoMovimentoEstoque.saida),
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
                const SizedBox(height: 16),
                _tituloDoBloco('Quantidade ($unidade)'),
                TextField(
                  controller: _quantidadeController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  cursorColor: theme.textColor,
                  style: theme.getTextStyle(fontSize: 12),
                  decoration: _decoracaoCampo(
                    unidade == 'un' ? 'Ex: 10' : 'Ex: 30,5',
                  ),
                  onChanged: (_) => setState(() => _aviso = null),
                ),
                const SizedBox(height: 16),
                _tituloDoBloco('Custo unitário (R\$)'),
                TextField(
                  controller: _custoController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  cursorColor: theme.textColor,
                  style: theme.getTextStyle(fontSize: 12),
                  decoration: _decoracaoCampo('Ex: 5,00 (opcional)'),
                  onChanged: (_) => setState(() => _aviso = null),
                ),
                const SizedBox(height: 16),
                _tituloDoBloco('Motivo (opcional)'),
                TextField(
                  controller: _motivoController,
                  maxLines: 3,
                  cursorColor: theme.textColor,
                  style: theme.getTextStyle(fontSize: 12),
                  decoration: _decoracaoCampo('Ex: compra do fornecedor'),
                ),
                if (_aviso != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _aviso!,
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(fontSize: 12),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: theme.buttonColor,
                      foregroundColor: theme.buttonTextColor,
                      side: BorderSide(color: theme.borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: widget.itens.isEmpty ? null : _confirmar,
                    child: Text(
                      'Registrar',
                      style: theme.getTextStyle(
                        fontSize: 14,
                        color: theme.buttonTextColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}