import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

String _dataHora(DateTime d) =>
    '${_doisDigitos(d.day)}/${_doisDigitos(d.month)}/${d.year} '
    '${_doisDigitos(d.hour)}:${_doisDigitos(d.minute)}';

String _valor(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

String _numero(int n) => '#${n.toString().padLeft(4, '0')}';

/// Bloco informativo do resumo financeiro e quitação a prazo da venda.
class BlocoResumoVendaWidget extends StatelessWidget {
  final AppTheme theme;
  final String lojaId;
  final PedidoLoja pedido;
  final double larguraBloco;
  final String autorCpf;
  final String autorNome;
  final String autorEmail;
  final ValueChanged<PedidoLoja> onPedidoAtualizado;

  const BlocoResumoVendaWidget({
    super.key,
    required this.theme,
    required this.lojaId,
    required this.pedido,
    required this.larguraBloco,
    required this.autorCpf,
    required this.autorNome,
    required this.autorEmail,
    required this.onPedidoAtualizado,
  });

  BoxDecoration get _decoracaoDoBloco => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

  Widget _tituloDoBloco(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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

  Widget _linha(String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo, style: theme.getTextStyle(fontSize: 12)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
            ),
          ),
        ],
      ),
    );
  }

  String get _situacao {
    switch (pedido.status) {
      case StatusPedido.novo:
        return 'Novo';
      case StatusPedido.aceito:
        return 'Aceito';
      case StatusPedido.concluido:
        return 'Concluído';
      case StatusPedido.cancelado:
        return 'Cancelado';
    }
  }

  Future<void> _confirmarQuitacaoPrazo(BuildContext context) async {
    final restante = pedido.valorRestante;
    String formaEscolhida = 'Dinheiro';
    const formas = [
      'Dinheiro',
      'Pix',
      'Cartão de Débito',
      'Cartão de Crédito',
      'Outro',
    ];

    final resultado = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: theme.cardBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.borderColor),
              ),
              title: Text(
                'Quitar Venda à Prazo',
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Confirmar o recebimento do saldo restante deste pedido?',
                      textAlign: TextAlign.center,
                      style: theme.getTextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
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
                                'Valor a quitar:',
                                style: theme.getTextStyle(
                                  fontSize: 12,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                              Text(
                                _valor(restante),
                                style: theme.getTextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Forma recebida:',
                                style: theme.getTextStyle(
                                  fontSize: 12,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: formaEscolhida,
                                  dropdownColor: theme.cardBackgroundColor,
                                  items: formas.map((f) {
                                    return DropdownMenuItem(
                                      value: f,
                                      child: Text(
                                        f,
                                        style: theme.getTextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (novo) {
                                    if (novo != null) {
                                      setModalState(() => formaEscolhida = novo);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(null),
                  child: Text(
                    'Cancelar',
                    style: theme.getTextStyle(color: theme.secondaryTextColor),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.buttonColor,
                    foregroundColor: theme.buttonTextColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(formaEscolhida),
                  child: Text(
                    'Confirmar Quitação',
                    style: theme.getTextStyle(
                      color: theme.buttonTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (resultado == null || !context.mounted) return;

    context.read<PdvProvider>().quitarPedidoLoja(
          lojaId,
          pedido.id,
          formaRecebimento: resultado,
          autorCpf: autorCpf,
          autorNome: autorNome,
          autorEmail: autorEmail,
        );

    final atualizado = pedido.copyWith(
      quitado: true,
      valorPago: pedido.valor,
    );
    onPedidoAtualizado(atualizado);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardBackgroundColor,
        content: Text(
          'Pedido #${pedido.numero} quitado com sucesso!',
          style: theme.getTextStyle(color: theme.textColor),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pagamentos = pedido.todosPagamentos;
    final temAPrazo = pedido.temAPrazo;
    final pago = pedido.quitado ? pedido.valor : pedido.valorPago;
    final restante = pedido.quitado ? 0.0 : pedido.valorRestante;

    return Center(
      child: Container(
        width: larguraBloco,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: _decoracaoDoBloco,
        child: Column(
          children: [
            _tituloDoBloco('Resumo'),
            _linha('Pedido', _numero(pedido.numero)),
            _linha('Data', _dataHora(pedido.dataHora)),
            _linha('Cliente', pedido.clienteNome),
            _linha('Produtos', pedido.produtoNome),
            if (pagamentos.isEmpty)
              _linha('Forma de pagamento', 'Não informada')
            else
              for (final p in pagamentos)
                _linha('Forma de pagamento', '${p.forma} (${_valor(p.valor)})'),
            _linha('Situação', _situacao),
            if (pedido.frete > 0) _linha('Frete', _valor(pedido.frete)),
            if (pedido.desconto > 0)
              _linha('Desconto', '-${_valor(pedido.desconto)}'),
            if (pedido.acrescimo > 0)
              _linha('Acréscimo', _valor(pedido.acrescimo)),
            _linha('Valor total', _valor(pedido.valor)),
            if (pedido.troco > 0) ...[
              _linha('Valor recebido', _valor(pedido.valorRecebido)),
              _linha('Troco', _valor(pedido.troco)),
            ],
            if (temAPrazo) ...[
              _linha('Pagamento à prazo',
                  pedido.quitado ? 'Quitado' : 'Em aberto'),
              _linha('Já pago', _valor(pago)),
              _linha('Restante', _valor(restante)),
              if (pedido.aPrazoEmAberto) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor:
                            theme.buttonColor != Colors.transparent
                                ? theme.buttonColor
                                : theme.borderColor.withValues(alpha: 0.2),
                        foregroundColor:
                            theme.buttonColor != Colors.transparent
                                ? theme.buttonTextColor
                                : theme.textColor,
                        side: BorderSide(
                          color: theme.textColor,
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _confirmarQuitacaoPrazo(context),
                      icon: Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: theme.buttonColor != Colors.transparent
                            ? theme.buttonTextColor
                            : theme.textColor,
                      ),
                      label: Text(
                        'Quitar Pagamento à Prazo',
                        style: theme.getTextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.buttonColor != Colors.transparent
                              ? theme.buttonTextColor
                              : theme.textColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
