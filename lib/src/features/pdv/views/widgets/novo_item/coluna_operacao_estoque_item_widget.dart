import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_switch.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/novo_item/botoes_hover_item_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/novo_item/estoque_custo_item_widget.dart';

/// Coluna de operações fiscais, estoque, custos, consumo e delivery do item.
class ColunaOperacaoEstoqueItemWidget extends StatelessWidget {
  final AppTheme theme;
  final bool editando;
  final double? saldoEstoqueAtual;
  final TextEditingController codigoBarrasController;
  final UnidadeItemLoja unidadeBase;
  final ValueChanged<UnidadeItemLoja> onUnidadeAlterada;
  final TextEditingController consumoController;
  final TextEditingController estoqueAtualController;
  final TextEditingController estoqueMinimoController;
  final TextEditingController custoTotalCompraController;
  final TextEditingController quantidadeCompraController;
  final TextEditingController precoCustoController;
  final String? calculoTexto;
  final String? margemTexto;
  final VoidCallback? onAbrirMovimentoDetalhado;
  final String Function(double) formatarNumero;
  final bool possuiDelivery;
  final ValueChanged<bool> onDeliveryAlterado;
  final TextEditingController freteGratisAteController;
  final TextEditingController valorPorKmController;

  const ColunaOperacaoEstoqueItemWidget({
    super.key,
    required this.theme,
    required this.editando,
    required this.saldoEstoqueAtual,
    required this.codigoBarrasController,
    required this.unidadeBase,
    required this.onUnidadeAlterada,
    required this.consumoController,
    required this.estoqueAtualController,
    required this.estoqueMinimoController,
    required this.custoTotalCompraController,
    required this.quantidadeCompraController,
    required this.precoCustoController,
    required this.calculoTexto,
    required this.margemTexto,
    this.onAbrirMovimentoDetalhado,
    required this.formatarNumero,
    required this.possuiDelivery,
    required this.onDeliveryAlterado,
    required this.freteGratisAteController,
    required this.valorPorKmController,
  });

  String _rotuloUnidade() {
    switch (unidadeBase) {
      case UnidadeItemLoja.un:
        return 'un';
      case UnidadeItemLoja.g:
        return 'g';
      case UnidadeItemLoja.ml:
        return 'ml';
    }
  }

  Widget _botaoUnidade(String rotulo, UnidadeItemLoja valor) {
    final selecionado = unidadeBase == valor;
    return Expanded(
      child: BotaoHoverUnidade(
        theme: theme,
        rotulo: rotulo,
        selecionado: selecionado,
        aoClicar: () => onUnidadeAlterada(valor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ThemedTextField(
          theme: theme,
          controller: codigoBarrasController,
          label: 'Código de barras / EAN (opcional)',
        ),
        const SizedBox(height: 14),
        Text(
          'Unidade de medida',
          textAlign: TextAlign.center,
          style: theme.getTextStyle(
            fontSize: 13,
            color: theme.secondaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _botaoUnidade('Unidade', UnidadeItemLoja.un),
            const SizedBox(width: 8),
            _botaoUnidade('Grama', UnidadeItemLoja.g),
            const SizedBox(width: 8),
            _botaoUnidade('Mililitro', UnidadeItemLoja.ml),
          ],
        ),
        const SizedBox(height: 14),
        ThemedTextField(
          theme: theme,
          controller: consumoController,
          label: 'Consumo por venda (${_rotuloUnidade()})',
          tipoDeTeclado: TextInputType.number,
        ),
        const SizedBox(height: 14),
        EstoqueCustoItemWidget(
          theme: theme,
          editando: editando,
          saldoEstoqueAtual: saldoEstoqueAtual,
          rotuloUnidade: _rotuloUnidade(),
          estoqueAtualController: estoqueAtualController,
          estoqueMinimoController: estoqueMinimoController,
          custoTotalCompraController: custoTotalCompraController,
          quantidadeCompraController: quantidadeCompraController,
          precoCustoController: precoCustoController,
          calculoTexto: calculoTexto,
          margemTexto: margemTexto,
          onAbrirMovimentoDetalhado: onAbrirMovimentoDetalhado,
          formatarNumero: formatarNumero,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                'O Produto possui delivery',
                style: theme.getTextStyle(fontSize: 13),
              ),
            ),
            ThemedSwitch(
              theme: theme,
              value: possuiDelivery,
              onChanged: onDeliveryAlterado,
            ),
          ],
        ),
        if (possuiDelivery) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ThemedTextField(
                  theme: theme,
                  controller: freteGratisAteController,
                  label: 'Frete Grátis até',
                  tipoDeTeclado: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ThemedTextField(
                  theme: theme,
                  controller: valorPorKmController,
                  label: 'R\$ por Km',
                  tipoDeTeclado: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
