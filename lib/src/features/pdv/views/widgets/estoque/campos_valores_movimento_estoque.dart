import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Campos numéricos e de observação (quantidade, custos e motivo)
/// para o diálogo de movimento de estoque.
class CamposValoresMovimentoEstoque extends StatelessWidget {
  final AppTheme theme;
  final String unidade;
  final bool ehEntrada;
  final TextEditingController quantidadeController;
  final TextEditingController custoTotalController;
  final TextEditingController custoUnitarioController;
  final TextEditingController motivoController;
  final VoidCallback onQuantidadeMudou;
  final VoidCallback onCustoTotalMudou;
  final VoidCallback onCustoUnitarioMudou;

  const CamposValoresMovimentoEstoque({
    super.key,
    required this.theme,
    required this.unidade,
    required this.ehEntrada,
    required this.quantidadeController,
    required this.custoTotalController,
    required this.custoUnitarioController,
    required this.motivoController,
    required this.onQuantidadeMudou,
    required this.onCustoTotalMudou,
    required this.onCustoUnitarioMudou,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _tituloDoBloco('Quantidade ($unidade)'),
        TextField(
          controller: quantidadeController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          cursorColor: theme.textColor,
          style: theme.getTextStyle(fontSize: 12),
          decoration: _decoracaoCampo(
            unidade == 'un' ? 'Ex: 10' : 'Ex: 30,5',
          ),
          onChanged: (_) => onQuantidadeMudou(),
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
                      controller: custoTotalController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      cursorColor: theme.textColor,
                      style: theme.getTextStyle(fontSize: 12),
                      decoration: _decoracaoCampo('Ex: 100,00 (total)'),
                      onChanged: (_) => onCustoTotalMudou(),
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
                      controller: custoUnitarioController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      cursorColor: theme.textColor,
                      style: theme.getTextStyle(fontSize: 12),
                      decoration: _decoracaoCampo('Ex: 0,50 / $unidade'),
                      onChanged: (_) => onCustoUnitarioMudou(),
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
            controller: custoUnitarioController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            cursorColor: theme.textColor,
            style: theme.getTextStyle(fontSize: 12),
            decoration: _decoracaoCampo('Ex: 5,00 (opcional)'),
            onChanged: (_) => onCustoUnitarioMudou(),
          ),
        ],
        const SizedBox(height: 16),
        _tituloDoBloco('Motivo (opcional)'),
        TextField(
          controller: motivoController,
          maxLines: 3,
          cursorColor: theme.textColor,
          style: theme.getTextStyle(fontSize: 12),
          decoration: _decoracaoCampo('Ex: compra do fornecedor'),
        ),
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
}
