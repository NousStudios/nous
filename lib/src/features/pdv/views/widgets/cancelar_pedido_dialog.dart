import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';

class ResultadoCancelamentoPedido {
  final String motivo;
  final bool devolverEstoque;

  const ResultadoCancelamentoPedido({
    required this.motivo,
    required this.devolverEstoque,
  });
}

class CancelarPedidoDialog extends StatefulWidget {
  final AppTheme theme;
  final PedidoLoja pedido;

  const CancelarPedidoDialog({
    super.key,
    required this.theme,
    required this.pedido,
  });

  static Future<ResultadoCancelamentoPedido?> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required PedidoLoja pedido,
  }) {
    return showDialog<ResultadoCancelamentoPedido>(
      context: context,
      builder: (_) => CancelarPedidoDialog(
        theme: theme,
        pedido: pedido,
      ),
    );
  }

  @override
  State<CancelarPedidoDialog> createState() => _CancelarPedidoDialogState();
}

class _CancelarPedidoDialogState extends State<CancelarPedidoDialog> {
  final _motivoController = TextEditingController();
  bool _devolverEstoque = true;
  String _erro = '';

  AppTheme get theme => widget.theme;
  PedidoLoja get pedido => widget.pedido;

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  String _numeroPedido(int n) => '#${n.toString().padLeft(4, '0')}';

  String _valorFormatado(double valor) =>
      'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

  void _confirmar() {
    final motivo = _motivoController.text.trim();
    if (motivo.isEmpty) {
      setState(() => _erro = 'Informe o motivo do cancelamento.');
      return;
    }

    Navigator.of(context).pop(
      ResultadoCancelamentoPedido(
        motivo: motivo,
        devolverEstoque: _devolverEstoque,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final temItens = pedido.itens.isNotEmpty;

    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Cancelar Pedido ${_numeroPedido(pedido.numero)}',
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.backgroundColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.6),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cliente:',
                          style: theme.getTextStyle(
                            fontSize: 12,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                        Text(
                          pedido.clienteNome,
                          style: theme.getTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Valor Total:',
                          style: theme.getTextStyle(
                            fontSize: 12,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                        Text(
                          _valorFormatado(pedido.valor),
                          style: theme.getTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                      ],
                    ),
                    if (temItens) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Itens:',
                            style: theme.getTextStyle(
                              fontSize: 12,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                          Text(
                            '${pedido.itens.length} ${pedido.itens.length == 1 ? 'item' : 'itens'}',
                            style: theme.getTextStyle(
                              fontSize: 12,
                              color: theme.textColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ThemedTextField(
                theme: theme,
                controller: _motivoController,
                label: 'Motivo do cancelamento *',
                linhas: 2,
                obrigatorio: true,
              ),
              if (_erro.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  _erro,
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: Colors.redAccent,
                  ),
                ),
              ],
              if (temItens) ...[
                const SizedBox(height: 14),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () =>
                      setState(() => _devolverEstoque = !_devolverEstoque),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.backgroundColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _devolverEstoque,
                          activeColor: theme.buttonColor,
                          checkColor: theme.buttonTextColor,
                          side: BorderSide(color: theme.borderColor),
                          onChanged: (val) => setState(
                              () => _devolverEstoque = val ?? true),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Devolver produtos ao estoque',
                                style: theme.getTextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textColor,
                                ),
                              ),
                              Text(
                                'Recomporá a quantidade dos itens deste pedido no estoque.',
                                style: theme.getTextStyle(
                                  fontSize: 10,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.secondaryTextColor,
                      side: BorderSide(color: theme.borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Voltar', style: theme.getTextStyle()),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _confirmar,
                    child: Text(
                      'Confirmar Cancelamento',
                      style: theme.getTextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PedidoCanceladoDetalhesDialog extends StatelessWidget {
  final AppTheme theme;
  final PedidoLoja pedido;

  const PedidoCanceladoDetalhesDialog({
    super.key,
    required this.theme,
    required this.pedido,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required PedidoLoja pedido,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => PedidoCanceladoDetalhesDialog(
        theme: theme,
        pedido: pedido,
      ),
    );
  }

  String _numeroPedido(int n) => '#${n.toString().padLeft(4, '0')}';

  String _dataHora(DateTime d) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year} ${dois(d.hour)}:${dois(d.minute)}';
  }

  String _valorFormatado(double valor) =>
      'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pedido ${_numeroPedido(pedido.numero)} (Cancelado)',
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.backgroundColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.6),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cliente:',
                          style: theme.getTextStyle(
                            fontSize: 12,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                        Text(
                          pedido.clienteNome,
                          style: theme.getTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Valor:',
                          style: theme.getTextStyle(
                            fontSize: 12,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                        Text(
                          _valorFormatado(pedido.valor),
                          style: theme.getTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Data do pedido:',
                          style: theme.getTextStyle(
                            fontSize: 12,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                        Text(
                          _dataHora(pedido.dataHora),
                          style: theme.getTextStyle(
                            fontSize: 11,
                            color: theme.textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Motivo do Cancelamento:',
                      style: theme.getTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pedido.motivoCancelamento.isNotEmpty
                          ? pedido.motivoCancelamento
                          : 'Nenhum motivo especificado.',
                      style: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.textColor,
                      ),
                    ),
                    if (pedido.dataHoraCancelamento != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Cancelado em: ${_dataHora(pedido.dataHoraCancelamento!)}'
                        '${pedido.canceladoPorNome.isNotEmpty ? ' por ${pedido.canceladoPorNome}' : ''}',
                        style: theme.getTextStyle(
                          fontSize: 10,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      pedido.estoqueEstornado
                          ? 'Estoque: Produtos foram devolvidos ao estoque.'
                          : 'Estoque: Não houve devolução ao estoque.',
                      style: theme.getTextStyle(
                        fontSize: 10,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (pedido.itens.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Itens do Pedido:',
                  style: theme.getTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                for (final item in pedido.itens)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item.quantidade}x ${item.nomeItem}',
                          style: theme.getTextStyle(
                            fontSize: 12,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                        Text(
                          _valorFormatado(item.subtotal),
                          style: theme.getTextStyle(
                            fontSize: 12,
                            color: theme.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.textColor,
                    side: BorderSide(color: theme.borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Fechar', style: theme.getTextStyle()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

