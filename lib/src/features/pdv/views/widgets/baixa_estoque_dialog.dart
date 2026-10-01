import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';

class BaixaEstoqueDialog {
  static Future<List<MovimentoEstoque>?> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required List<ItemLoja> itensDisponiveis,
    required PedidoLoja pedido,
    required String cpfAutor,
    required String nomeAutor,
  }) {
    final sugestoes = _calcularSugestoes(
      itensDisponiveis: itensDisponiveis,
      pedido: pedido,
    );

    if (sugestoes.isEmpty) {
      return Future.value(const <MovimentoEstoque>[]);
    }

    return showDialog<List<MovimentoEstoque>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: theme.cardBackgroundColor,
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 640),
            child: _BaixaEstoqueConteudo(
              theme: theme,
              sugestoes: sugestoes,
              cpfAutor: cpfAutor,
              nomeAutor: nomeAutor,
            ),
          ),
        );
      },
    );
  }

  static List<_SugestaoBaixa> _calcularSugestoes({
    required List<ItemLoja> itensDisponiveis,
    required PedidoLoja pedido,
  }) {
    final agregado = <String, double>{};

    for (final itemVendido in pedido.itens) {
      final itemPrincipal = _buscarItem(itensDisponiveis, itemVendido.itemId);
      if (itemPrincipal != null) {
        final consumo = itemPrincipal.consumoPorVenda <= 0
            ? 1.0
            : itemPrincipal.consumoPorVenda;
        agregado[itemPrincipal.id] =
            (agregado[itemPrincipal.id] ?? 0) +
                (consumo * itemVendido.quantidade);
      }

      for (final acomp in itemVendido.acompanhamentos) {
        final itemAcomp = _buscarItem(itensDisponiveis, acomp.itemId);
        if (itemAcomp == null) continue;
        final consumo =
            itemAcomp.consumoPorVenda <= 0 ? 1.0 : itemAcomp.consumoPorVenda;
        final quantidadeTotal =
            acomp.quantidadePorUnidade * itemVendido.quantidade;
        agregado[itemAcomp.id] =
            (agregado[itemAcomp.id] ?? 0) + (consumo * quantidadeTotal);
      }
    }

    final sugestoes = <_SugestaoBaixa>[];
    for (final entrada in agregado.entries) {
      final item = _buscarItem(itensDisponiveis, entrada.key);
      if (item == null) continue;
      sugestoes.add(_SugestaoBaixa(
        item: item,
        quantidadeSugerida: entrada.value,
      ));
    }
    sugestoes.sort(
      (a, b) => a.item.nome.toLowerCase().compareTo(b.item.nome.toLowerCase()),
    );
    return sugestoes;
  }

  static ItemLoja? _buscarItem(List<ItemLoja> itens, String id) {
    for (final i in itens) {
      if (i.id == id) return i;
    }
    return null;
  }
}

class _SugestaoBaixa {
  final ItemLoja item;
  final double quantidadeSugerida;

  _SugestaoBaixa({
    required this.item,
    required this.quantidadeSugerida,
  });
}

class _LinhaBaixa {
  final ItemLoja item;
  final TextEditingController quantidadeController;
  final TextEditingController custoController;
  bool ativa = true;

  _LinhaBaixa({
    required this.item,
    required this.quantidadeController,
    required this.custoController,
  });

  void dispose() {
    quantidadeController.dispose();
    custoController.dispose();
  }
}

class _BaixaEstoqueConteudo extends StatefulWidget {
  final AppTheme theme;
  final List<_SugestaoBaixa> sugestoes;
  final String cpfAutor;
  final String nomeAutor;

  const _BaixaEstoqueConteudo({
    required this.theme,
    required this.sugestoes,
    required this.cpfAutor,
    required this.nomeAutor,
  });

  @override
  State<_BaixaEstoqueConteudo> createState() => _BaixaEstoqueConteudoState();
}

class _BaixaEstoqueConteudoState extends State<_BaixaEstoqueConteudo> {
  late final List<_LinhaBaixa> _linhas;

  AppTheme get theme => widget.theme;

  @override
  void initState() {
    super.initState();
    _linhas = widget.sugestoes
        .map((s) => _LinhaBaixa(
              item: s.item,
              quantidadeController: TextEditingController(
                text: _formatarNumero(s.quantidadeSugerida),
              ),
              custoController: TextEditingController(text: '0,00'),
            ))
        .toList();
  }

  @override
  void dispose() {
    for (final l in _linhas) {
      l.dispose();
    }
    super.dispose();
  }

  String _formatarNumero(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2).replaceAll('.', ',');
  }

  String _rotuloUnidade(UnidadeItemLoja u) {
    switch (u) {
      case UnidadeItemLoja.un:
        return 'un';
      case UnidadeItemLoja.g:
        return 'g';
      case UnidadeItemLoja.ml:
        return 'ml';
    }
  }

  double _parseNumero(String texto) {
    final limpo = texto.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(limpo) ?? 0;
  }

  void _cancelar() {
    Navigator.of(context).pop(null);
  }

  void _aplicar() {
    final movimentos = <MovimentoEstoque>[];
    for (final linha in _linhas) {
      if (!linha.ativa) continue;
      final quantidade = _parseNumero(linha.quantidadeController.text);
      if (quantidade <= 0) continue;
      final custo = _parseNumero(linha.custoController.text);
      movimentos.add(MovimentoEstoque.novo(
        itemId: linha.item.id,
        tipo: TipoMovimentoEstoque.saida,
        quantidade: quantidade,
        custoUnitario: custo < 0 ? 0 : custo,
        motivo: 'Baixa automática por venda',
        cpfAutor: widget.cpfAutor,
        nomeAutor: widget.nomeAutor,
        categoria: CategoriaMovimentoEstoque.venda,
      ));
    }
    Navigator.of(context).pop(movimentos);
  }

  Widget _linhaBaixa(_LinhaBaixa linha) {
    final item = linha.item;
    final unidade = _rotuloUnidade(item.unidadeBase);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: linha.ativa
                ? theme.borderColor
                : theme.borderColor.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 26,
                  height: 26,
                  child: Checkbox(
                    value: linha.ativa,
                    activeColor: theme.buttonColor,
                    checkColor: theme.buttonTextColor,
                    side: BorderSide(color: theme.borderColor),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (v) =>
                        setState(() => linha.ativa = v ?? false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.nome.isEmpty ? 'Item sem nome' : item.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: linha.ativa
                          ? theme.textColor
                          : theme.secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: linha.quantidadeController,
                    enabled: linha.ativa,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    cursorColor: theme.textColor,
                    style: theme.getTextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      labelText: 'Quantidade ($unidade)',
                      labelStyle: theme.getTextStyle(
                        fontSize: 11,
                        color: theme.secondaryTextColor,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.textColor),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: linha.custoController,
                    enabled: linha.ativa,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    cursorColor: theme.textColor,
                    style: theme.getTextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      labelText: 'Custo unitário (R\$)',
                      labelStyle: theme.getTextStyle(
                        fontSize: 11,
                        color: theme.secondaryTextColor,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.textColor),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ativos =
        _linhas.where((l) => l.ativa).length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.close, color: theme.textColor),
                onPressed: _cancelar,
              ),
              Expanded(
                child: Text(
                  'Baixa de estoque',
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.backgroundColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Text(
                    'O sistema calculou a baixa de cada item com base no '
                    'consumo por venda configurado. Confira, ajuste o que '
                    'não se aplica e desmarque o que não saiu do estoque. '
                    'A vida real manda.',
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                for (final linha in _linhas) _linhaBaixa(linha),
                const SizedBox(height: 8),
                Text(
                  ativos == 0
                      ? 'Nenhum item será baixado.'
                      : '$ativos ${ativos == 1 ? 'item será baixado' : 'itens serão baixados'}.',
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 11,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.textColor,
                    side: BorderSide(color: theme.borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _cancelar,
                  child: Text(
                    'Não baixar agora',
                    style: theme.getTextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
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
                  onPressed: _aplicar,
                  child: Text(
                    'Aplicar e continuar',
                    style: theme.getTextStyle(
                      fontSize: 13,
                      color: theme.buttonTextColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}