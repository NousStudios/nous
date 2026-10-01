import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';

class MovimentoEstoqueDialog {
  static Future<MovimentoEstoque?> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required List<ItemLoja> itens,
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
  final String cpfAutor;
  final String nomeAutor;
  final ItemLoja? itemInicial;
  final TipoMovimentoEstoque? tipoInicial;

  const _MovimentoEstoqueConteudo({
    required this.theme,
    required this.itens,
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
  TipoMovimentoEstoque _tipo = TipoMovimentoEstoque.entrada;
  String? _aviso;

  AppTheme get theme => widget.theme;

  @override
  void initState() {
    super.initState();
    _item = widget.itemInicial;
    if (widget.tipoInicial != null) {
      _tipo = widget.tipoInicial!;
    }
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    _custoController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  void _confirmar() {
    final item = _item;
    if (item == null) {
      setState(() => _aviso = 'Selecione o item.');
      return;
    }

    final quantidade = int.tryParse(_quantidadeController.text.trim());
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

  @override
  Widget build(BuildContext context) {
    final item = _item;

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
                if (widget.itens.isEmpty)
                  Text(
                    'Nenhum item cadastrado ainda.',
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.secondaryTextColor,
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.borderColor),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
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
                  ),
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
                _tituloDoBloco('Quantidade'),
                TextField(
                  controller: _quantidadeController,
                  keyboardType: TextInputType.number,
                  cursorColor: theme.textColor,
                  style: theme.getTextStyle(fontSize: 12),
                  decoration: _decoracaoCampo('Ex: 10'),
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
                    onPressed:
                        widget.itens.isEmpty ? null : _confirmar,
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