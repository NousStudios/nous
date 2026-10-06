import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';

String _valorFormatado(double valor) =>
    'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

const List<String> _formasDePagamento = [
  'Dinheiro',
  'Pix',
  'Cartão de Crédito',
  'Cartão de Débito',
  'Fiado / A Prazo',
];

class ResultadoFechamentoMesa {
  final String formaPagamento;
  final bool baixarEstoque;

  const ResultadoFechamentoMesa({
    required this.formaPagamento,
    required this.baixarEstoque,
  });
}

class FecharContaMesaDialog extends StatefulWidget {
  final AppTheme theme;
  final MesaLoja mesa;

  const FecharContaMesaDialog({
    super.key,
    required this.theme,
    required this.mesa,
  });

  static Future<ResultadoFechamentoMesa?> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required MesaLoja mesa,
  }) {
    return showDialog<ResultadoFechamentoMesa>(
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
            constraints: const BoxConstraints(maxWidth: 440),
            child: FecharContaMesaDialog(
              theme: theme,
              mesa: mesa,
            ),
          ),
        );
      },
    );
  }

  @override
  State<FecharContaMesaDialog> createState() => _FecharContaMesaDialogState();
}

class _FecharContaMesaDialogState extends State<FecharContaMesaDialog> {
  String _formaPagamento = 'Dinheiro';
  bool _baixarEstoque = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: widget.theme.textColor),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  'Fechar Mesa ${widget.mesa.numero}',
                  textAlign: TextAlign.center,
                  style: widget.theme.getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.theme.textColor,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 16),
          // Totalizador
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.theme.backgroundColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.theme.borderColor.withValues(alpha: 0.6),
              ),
            ),
            child: Column(
              children: [
                if (widget.mesa.clienteNome.isNotEmpty) ...[
                  Text(
                    'Cliente: ${widget.mesa.clienteNome}',
                    style: widget.theme.getTextStyle(
                      fontSize: 13,
                      color: widget.theme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  'Total a Pagar',
                  style: widget.theme.getTextStyle(
                    fontSize: 13,
                    color: widget.theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _valorFormatado(widget.mesa.totalAcumulado),
                  style: widget.theme.getTextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: widget.theme.textColor,
                  ),
                ),
                Text(
                  '${widget.mesa.quantidadeItensTotal} ${widget.mesa.quantidadeItensTotal == 1 ? "item consumido" : "itens consumidos"}',
                  style: widget.theme.getTextStyle(
                    fontSize: 11,
                    color: widget.theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Forma de Pagamento
          Text(
            'Forma de Pagamento:',
            style: widget.theme.getTextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: widget.theme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: widget.theme.backgroundColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.theme.borderColor.withValues(alpha: 0.6),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _formaPagamento,
                dropdownColor: widget.theme.cardBackgroundColor,
                isExpanded: true,
                items: _formasDePagamento.map((forma) {
                  return DropdownMenuItem<String>(
                    value: forma,
                    child: Text(
                      forma,
                      style: widget.theme.getTextStyle(
                        fontSize: 14,
                        color: widget.theme.textColor,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (nova) {
                  if (nova != null) setState(() => _formaPagamento = nova);
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Switch de baixa de estoque
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _baixarEstoque = !_baixarEstoque),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: widget.theme.backgroundColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: widget.theme.borderColor.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Baixar produtos do estoque',
                          style: widget.theme.getTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: widget.theme.textColor,
                          ),
                        ),
                        Text(
                          'Registra saída automática no controle de estoque',
                          style: widget.theme.getTextStyle(
                            fontSize: 10,
                            color: widget.theme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _baixarEstoque,
                    onChanged: (v) => setState(() => _baixarEstoque = v),
                    activeThumbColor: widget.theme.textColor,
                    activeTrackColor:
                        widget.theme.borderColor.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: widget.theme.buttonColor,
              foregroundColor: widget.theme.buttonTextColor,
              side: BorderSide(color: widget.theme.borderColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop(
                ResultadoFechamentoMesa(
                  formaPagamento: _formaPagamento,
                  baixarEstoque: _baixarEstoque,
                ),
              );
            },
            child: Text(
              'Concluir Venda e Liberar Mesa',
              style: widget.theme.getTextStyle(
                fontSize: 14,
                color: widget.theme.buttonTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
