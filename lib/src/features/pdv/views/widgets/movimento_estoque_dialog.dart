import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_switch.dart';
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
    void Function(ItemLoja itemAtualizado)? onItemAtualizado,
    void Function(ItemLoja item)? onEditarItemCompleto,
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
              onItemAtualizado: onItemAtualizado,
              onEditarItemCompleto: onEditarItemCompleto,
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
  final void Function(ItemLoja itemAtualizado)? onItemAtualizado;
  final void Function(ItemLoja item)? onEditarItemCompleto;

  const _MovimentoEstoqueConteudo({
    required this.theme,
    required this.itens,
    required this.fornecedores,
    required this.cpfAutor,
    required this.nomeAutor,
    this.itemInicial,
    this.tipoInicial,
    this.onItemAtualizado,
    this.onEditarItemCompleto,
  });

  @override
  State<_MovimentoEstoqueConteudo> createState() =>
      _MovimentoEstoqueConteudoState();
}

class _MovimentoEstoqueConteudoState
    extends State<_MovimentoEstoqueConteudo> {
  final _quantidadeController = TextEditingController();
  final _custoTotalController = TextEditingController();
  final _custoController = TextEditingController();
  final _motivoController = TextEditingController();
  final _precoVendaRapidoController = TextEditingController();
  final _codigoBarrasRapidoController = TextEditingController();

  bool _calculandoCusto = false;
  bool _atualizarCustoNoCadastro = true;
  bool _mostrarAjustesRapidos = false;
  UnidadeItemLoja _unidadeRapida = UnidadeItemLoja.un;

  ItemLoja? _item;
  Fornecedor? _fornecedor;
  TipoMovimentoEstoque _tipo = TipoMovimentoEstoque.entrada;
  CategoriaMovimentoEstoque _categoria = CategoriaMovimentoEstoque.compra;
  String? _aviso;

  AppTheme get theme => widget.theme;

  @override
  void initState() {
    super.initState();
    _item = widget.itemInicial != null
        ? widget.itens.firstWhere(
            (i) => i.id == widget.itemInicial!.id,
            orElse: () => widget.itemInicial!,
          )
        : null;
    if (_item != null) {
      _precoVendaRapidoController.text = _item!.preco;
      _codigoBarrasRapidoController.text = _item!.codigoBarras;
      _unidadeRapida = _item!.unidadeBase;
    }
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
    _custoTotalController.dispose();
    _custoController.dispose();
    _motivoController.dispose();
    _precoVendaRapidoController.dispose();
    _codigoBarrasRapidoController.dispose();
    super.dispose();
  }

  void _onCustoTotalMudou() {
    if (_calculandoCusto) return;
    _calculandoCusto = true;
    try {
      final qtd = _quantidadeParseada();
      final totalTexto = _custoTotalController.text
          .trim()
          .replaceAll('.', '')
          .replaceAll(',', '.');
      final total = double.tryParse(totalTexto);
      if (qtd != null && qtd > 0 && total != null && total >= 0) {
        final unitario = total / qtd;
        _custoController.text =
            unitario.toStringAsFixed(2).replaceAll('.', ',');
      }
    } finally {
      _calculandoCusto = false;
    }
  }

  void _onCustoUnitarioMudou() {
    if (_calculandoCusto) return;
    _calculandoCusto = true;
    try {
      final qtd = _quantidadeParseada();
      final unitarioTexto = _custoController.text
          .trim()
          .replaceAll('.', '')
          .replaceAll(',', '.');
      final unitario = double.tryParse(unitarioTexto);
      if (qtd != null && qtd > 0 && unitario != null && unitario >= 0) {
        final total = qtd * unitario;
        _custoTotalController.text =
            total.toStringAsFixed(2).replaceAll('.', ',');
      }
    } finally {
      _calculandoCusto = false;
    }
  }

  void _onQuantidadeMudou() {
    final totalTexto = _custoTotalController.text
        .trim()
        .replaceAll('.', '')
        .replaceAll(',', '.');
    final total = double.tryParse(totalTexto);
    if (total != null && total > 0) {
      _onCustoTotalMudou();
    } else {
      _onCustoUnitarioMudou();
    }
  }

  String _rotuloUnidade(ItemLoja item) {
    return _unidadeRapida.name;
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

    var itemModificado = item;
    if (_tipo == TipoMovimentoEstoque.entrada &&
        _atualizarCustoNoCadastro &&
        custo > 0) {
      itemModificado = itemModificado.copyWith(
        precoCusto: custo.toStringAsFixed(2).replaceAll('.', ','),
      );
    }
    final novoPrecoVenda = _precoVendaRapidoController.text.trim();
    if (novoPrecoVenda.isNotEmpty && novoPrecoVenda != item.preco) {
      itemModificado = itemModificado.copyWith(preco: novoPrecoVenda);
    }
    final novoCodigo = _codigoBarrasRapidoController.text.trim();
    if (novoCodigo != item.codigoBarras) {
      itemModificado = itemModificado.copyWith(codigoBarras: novoCodigo);
    }
    final dadosCadastraisAlterados =
        itemModificado.precoCusto != item.precoCusto ||
        itemModificado.preco != item.preco ||
        itemModificado.codigoBarras != item.codigoBarras ||
        itemModificado.unidadeBase != item.unidadeBase;
    if (dadosCadastraisAlterados) {
      widget.onItemAtualizado?.call(itemModificado);
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

  Widget _cardIntegracaoItem() {
    final item = _item;
    if (item == null) return const SizedBox.shrink();

    final ehEntrada = _tipo == TipoMovimentoEstoque.entrada;

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, size: 16, color: theme.textColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dados do Cadastro do Item',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
              if (widget.onEditarItemCompleto != null)
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onEditarItemCompleto!(item);
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.edit_note_rounded,
                            size: 15, color: theme.textColor),
                        const SizedBox(width: 4),
                        Text(
                          'Editar completo',
                          style: theme.getTextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Venda: R\$ ${item.preco.isEmpty ? "0,00" : item.preco}',
                  style: theme.getTextStyle(
                      fontSize: 11, color: theme.secondaryTextColor),
                ),
              ),
              Expanded(
                child: Text(
                  'Custo atual: R\$ ${item.precoCusto.isEmpty ? "0,00" : item.precoCusto}',
                  style: theme.getTextStyle(
                      fontSize: 11, color: theme.secondaryTextColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Código: ${item.codigoBarras.isEmpty ? "Sem código" : item.codigoBarras}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                      fontSize: 11, color: theme.secondaryTextColor),
                ),
              ),
              Expanded(
                child: Text(
                  'Mínimo: ${item.estoqueMinimo.isEmpty ? "0" : item.estoqueMinimo} ${_rotuloUnidade(item)}',
                  style: theme.getTextStyle(
                      fontSize: 11, color: theme.secondaryTextColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => setState(
                () => _mostrarAjustesRapidos = !_mostrarAjustesRapidos),
            borderRadius: BorderRadius.circular(6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _mostrarAjustesRapidos
                      ? Icons.keyboard_arrow_up
                      : Icons.tune,
                  size: 14,
                  color: theme.textColor,
                ),
                const SizedBox(width: 4),
                Text(
                  _mostrarAjustesRapidos
                      ? 'Ocultar ajustes rápidos'
                      : 'Ajustar preço de venda, código de barras ou unidade',
                  style: theme.getTextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
              ],
            ),
          ),
          if (_mostrarAjustesRapidos) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Novo Preço de Venda (R\$)',
                        style: theme.getTextStyle(
                            fontSize: 10, color: theme.secondaryTextColor),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _precoVendaRapidoController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        cursorColor: theme.textColor,
                        style: theme.getTextStyle(fontSize: 11),
                        decoration: _decoracaoCampo('Ex: 15,00'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Código de Barras / EAN',
                        style: theme.getTextStyle(
                            fontSize: 10, color: theme.secondaryTextColor),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _codigoBarrasRapidoController,
                        cursorColor: theme.textColor,
                        style: theme.getTextStyle(fontSize: 11),
                        decoration: _decoracaoCampo('Código'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unidade de Medida do Item',
                  style: theme.getTextStyle(
                      fontSize: 10, color: theme.secondaryTextColor),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    for (final u in UnidadeItemLoja.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () => setState(() => _unidadeRapida = u),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _unidadeRapida == u
                                  ? (theme.buttonColor != Colors.transparent
                                      ? theme.buttonColor
                                          .withValues(alpha: 0.8)
                                      : theme.borderColor
                                          .withValues(alpha: 0.35))
                                  : theme.backgroundColor
                                      .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _unidadeRapida == u
                                    ? theme.textColor
                                    : theme.borderColor
                                        .withValues(alpha: 0.5),
                                width: _unidadeRapida == u ? 1.4 : 1.0,
                              ),
                            ),
                            child: Text(
                              u == UnidadeItemLoja.un
                                  ? 'Unidade (un)'
                                  : u == UnidadeItemLoja.g
                                      ? 'Gramas (g)'
                                      : 'Mililitros (ml)',
                              style: theme.getTextStyle(
                                fontSize: 11,
                                fontWeight: _unidadeRapida == u
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _unidadeRapida == u
                                    ? theme.textColor
                                    : theme.secondaryTextColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
          if (ehEntrada) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                ThemedSwitch(
                  theme: theme,
                  value: _atualizarCustoNoCadastro,
                  onChanged: (v) =>
                      setState(() => _atualizarCustoNoCadastro = v),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Atualizar preço de custo no cadastro do item com esta compra',
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.textColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
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
      child: _BotaoHoverTipoEstoque(
        theme: theme,
        rotulo: rotulo,
        selecionado: selecionado,
        aoClicar: () => setState(() {
          _tipo = tipo;
          if (tipo == TipoMovimentoEstoque.saida) {
            _fornecedor = null;
            _categoria = CategoriaMovimentoEstoque.ajuste;
          } else {
            _categoria = CategoriaMovimentoEstoque.compra;
          }
          _aviso = null;
        }),
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
            if (valor != null) {
              _precoVendaRapidoController.text = valor.preco;
              _codigoBarrasRapidoController.text = valor.codigoBarras;
              _unidadeRapida = valor.unidadeBase;
            }
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
                _cardIntegracaoItem(),
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
                  onChanged: (_) {
                    _onQuantidadeMudou();
                    setState(() => _aviso = null);
                  },
                ),
                const SizedBox(height: 16),
                if (ehEntrada) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _tituloDoBloco('Custo da compra (R\$)'),
                            TextField(
                              controller: _custoTotalController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              cursorColor: theme.textColor,
                              style: theme.getTextStyle(fontSize: 12),
                              decoration:
                                  _decoracaoCampo('Ex: 100,00 (total)'),
                              onChanged: (_) {
                                _onCustoTotalMudou();
                                setState(() => _aviso = null);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _tituloDoBloco('Custo unitário (R\$)'),
                            TextField(
                              controller: _custoController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              cursorColor: theme.textColor,
                              style: theme.getTextStyle(fontSize: 12),
                              decoration:
                                  _decoracaoCampo('Ex: 0,50 / $unidade'),
                              onChanged: (_) {
                                _onCustoUnitarioMudou();
                                setState(() => _aviso = null);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ao informar o custo total da compra, o custo unitário por $unidade é calculado automaticamente.',
                    style: theme.getTextStyle(
                      fontSize: 10,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ] else ...[
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
                ],
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
                    style: ButtonStyle(
                      backgroundColor:
                          WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered)) {
                          return theme.borderColor.withValues(alpha: 0.18);
                        }
                        return theme.buttonColor != Colors.transparent
                            ? theme.buttonColor
                            : Colors.transparent;
                      }),
                      foregroundColor:
                          WidgetStateProperty.resolveWith((states) {
                        return theme.buttonColor != Colors.transparent
                            ? theme.buttonTextColor
                            : theme.textColor;
                      }),
                      side: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered)) {
                          return BorderSide(color: theme.textColor, width: 1.4);
                        }
                        return BorderSide(color: theme.borderColor, width: 1.0);
                      }),
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(vertical: 14),
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    onPressed: widget.itens.isEmpty ? null : _confirmar,
                    child: Text(
                      'Registrar',
                      style: theme.getTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.buttonColor != Colors.transparent
                            ? theme.buttonTextColor
                            : theme.textColor,
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

class _BotaoHoverTipoEstoque extends StatefulWidget {
  final AppTheme theme;
  final String rotulo;
  final bool selecionado;
  final VoidCallback aoClicar;

  const _BotaoHoverTipoEstoque({
    required this.theme,
    required this.rotulo,
    required this.selecionado,
    required this.aoClicar,
  });

  @override
  State<_BotaoHoverTipoEstoque> createState() => _BotaoHoverTipoEstoqueState();
}

class _BotaoHoverTipoEstoqueState extends State<_BotaoHoverTipoEstoque> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final ativo = widget.selecionado;
    final corAtiva = theme.buttonColor != Colors.transparent
        ? theme.buttonColor
        : theme.borderColor.withValues(alpha: 0.25);

    final corFundo = ativo
        ? (_hover ? corAtiva.withValues(alpha: 0.35) : corAtiva)
        : (_hover
            ? theme.borderColor.withValues(alpha: 0.12)
            : Colors.transparent);

    final corBorda = ativo
        ? theme.textColor
        : (_hover
            ? theme.borderColor
            : theme.borderColor.withValues(alpha: 0.6));

    final corTexto = ativo
        ? (theme.buttonColor != Colors.transparent
            ? theme.buttonTextColor
            : theme.textColor)
        : theme.textColor;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.aoClicar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: corFundo,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: corBorda,
              width: ativo ? 1.6 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              widget.rotulo,
              style: theme.getTextStyle(
                fontSize: 12,
                fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
                color: corTexto,
              ),
            ),
          ),
        ),
      ),
    );
  }
}