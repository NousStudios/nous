import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';

String _valorFormatado(double valor) =>
    'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

/// Painel para divisão de conta de mesa com múltiplos pagamentos parciais.
class PainelDividirPagamentoMesaWidget extends StatelessWidget {
  final AppTheme theme;
  final List<String> formasDePagamento;
  final List<PagamentoParcial> pagamentosParciais;
  final double totalPagoDividido;
  final double restantePagar;
  final String formaParcial;
  final ValueChanged<String> onFormaParcialAlterada;
  final TextEditingController valorParcialController;
  final VoidCallback onAdicionarPagamentoParcial;
  final void Function(int) onRemoverPagamentoParcial;

  const PainelDividirPagamentoMesaWidget({
    super.key,
    required this.theme,
    required this.formasDePagamento,
    required this.pagamentosParciais,
    required this.totalPagoDividido,
    required this.restantePagar,
    required this.formaParcial,
    required this.onFormaParcialAlterada,
    required this.valorParcialController,
    required this.onAdicionarPagamentoParcial,
    required this.onRemoverPagamentoParcial,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pago: ${_valorFormatado(totalPagoDividido)}',
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.textColor,
                ),
              ),
              Text(
                restantePagar > 0.005
                    ? 'Falta: ${_valorFormatado(restantePagar)}'
                    : 'Conta Quitada!',
                style: theme.getTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: restantePagar > 0.005
                      ? Colors.redAccent
                      : theme.textColor,
                ),
              ),
            ],
          ),
          if (pagamentosParciais.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (int i = 0; i < pagamentosParciais.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        size: 14, color: theme.textColor),
                    const SizedBox(width: 6),
                    Text(
                      pagamentosParciais[i].forma,
                      style: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.textColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _valorFormatado(pagamentosParciais[i].valor),
                      style: theme.getTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => onRemoverPagamentoParcial(i),
                      child: Icon(Icons.close,
                          size: 14, color: theme.secondaryTextColor),
                    ),
                  ],
                ),
              ),
          ],
          if (restantePagar > 0.005) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: theme.cardBackgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.6),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: formaParcial,
                        dropdownColor: theme.cardBackgroundColor,
                        isExpanded: true,
                        items: formasDePagamento.map((forma) {
                          return DropdownMenuItem<String>(
                            value: forma,
                            child: Text(
                              forma,
                              style: theme.getTextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                        onChanged: (nova) {
                          if (nova != null) {
                            onFormaParcialAlterada(nova);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: valorParcialController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
                    ],
                    style: theme.getTextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Valor',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.borderColor),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: Icon(Icons.add, size: 20, color: theme.textColor),
                  onPressed: onAdicionarPagamentoParcial,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
