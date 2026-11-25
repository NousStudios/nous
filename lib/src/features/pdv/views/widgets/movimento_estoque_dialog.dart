import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/fornecedor.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/views/widgets/estoque/campos_valores_movimento_estoque.dart';
import 'package:nous/src/features/pdv/views/widgets/estoque/card_ajustes_rapidos_item_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/estoque/seletores_movimento_estoque.dart';

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
    if (_unidadeRapida != item.unidadeBase) {
      itemModificado = itemModificado.copyWith(unidadeBase: _unidadeRapida);
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

    return CardAjustesRapidosItemDialog(
      theme: theme,
      item: item,
      ehEntrada: _tipo == TipoMovimentoEstoque.entrada,
      mostrarAjustesRapidos: _mostrarAjustesRapidos,
      onAlternarMostrarAjustesRapidos: () =>
          setState(() => _mostrarAjustesRapidos = !_mostrarAjustesRapidos),
      precoVendaController: _precoVendaRapidoController,
      codigoBarrasController: _codigoBarrasRapidoController,
      unidadeRapida: _unidadeRapida,
      onAlterarUnidade: (u) => setState(() => _unidadeRapida = u),
      atualizarCustoNoCadastro: _atualizarCustoNoCadastro,
      onAlternarAtualizarCustoNoCadastro: (v) =>
          setState(() => _atualizarCustoNoCadastro = v),
      onEditarItemCompleto: widget.onEditarItemCompleto != null
          ? () {
              Navigator.of(context).pop();
              widget.onEditarItemCompleto!(item);
            }
          : null,
    );
  }

  void _onItemAlterado(ItemLoja? valor) {
    setState(() {
      _item = valor;
      _aviso = null;
      if (valor != null) {
        _precoVendaRapidoController.text = valor.preco;
        _codigoBarrasRapidoController.text = valor.codigoBarras;
        _unidadeRapida = valor.unidadeBase;
      }
    });
  }

  void _onTipoAlterado(TipoMovimentoEstoque tipo) {
    setState(() {
      _tipo = tipo;
      if (tipo == TipoMovimentoEstoque.saida) {
        _fornecedor = null;
        _categoria = CategoriaMovimentoEstoque.ajuste;
      } else {
        _categoria = CategoriaMovimentoEstoque.compra;
      }
      _aviso = null;
    });
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
                SeletoresMovimentoEstoque(
                  theme: theme,
                  itens: widget.itens,
                  itemSelecionado: _item,
                  onItemAlterado: _onItemAlterado,
                  cardAjustesRapidos: _cardIntegracaoItem(),
                  tipoSelecionado: _tipo,
                  onTipoAlterado: _onTipoAlterado,
                  categoriaSelecionada: _categoria,
                  onCategoriaAlterada: (valor) => setState(() {
                    _categoria = valor;
                    _aviso = null;
                  }),
                  fornecedores: widget.fornecedores,
                  fornecedorSelecionado: _fornecedor,
                  onFornecedorAlterado: (valor) => setState(() {
                    _fornecedor = valor;
                    _aviso = null;
                  }),
                ),
                const SizedBox(height: 16),
                CamposValoresMovimentoEstoque(
                  theme: theme,
                  unidade: unidade,
                  ehEntrada: ehEntrada,
                  quantidadeController: _quantidadeController,
                  custoTotalController: _custoTotalController,
                  custoUnitarioController: _custoController,
                  motivoController: _motivoController,
                  onQuantidadeMudou: () {
                    _onQuantidadeMudou();
                    setState(() => _aviso = null);
                  },
                  onCustoTotalMudou: () {
                    _onCustoTotalMudou();
                    setState(() => _aviso = null);
                  },
                  onCustoUnitarioMudou: () {
                    if (ehEntrada) _onCustoUnitarioMudou();
                    setState(() => _aviso = null);
                  },
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