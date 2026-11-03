import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/venda_registrada_dialog.dart';

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

String _dataHora(DateTime d) =>
    '${_doisDigitos(d.day)}/${_doisDigitos(d.month)}/${d.year} '
    '${_doisDigitos(d.hour)}:${_doisDigitos(d.minute)}';

String _valor(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

String _numero(int n) => '#${n.toString().padLeft(4, '0')}';

/// Linha interativa em formato de pílula para exibição resumida da venda em listas.
class BarraVendaWidget extends StatefulWidget {
  final AppTheme theme;
  final String lojaId;
  final PedidoLoja pedido;
  final bool mostrarCliente;
  final String autorCpf;
  final String autorNome;
  final String autorEmail;
  final ValueChanged<DadosComentario>? onSalvarComentario;
  final VoidCallback? onExcluir;

  const BarraVendaWidget({
    super.key,
    required this.theme,
    required this.lojaId,
    required this.pedido,
    this.mostrarCliente = false,
    this.autorCpf = '',
    this.autorNome = '',
    this.autorEmail = '',
    this.onSalvarComentario,
    this.onExcluir,
  });

  @override
  State<BarraVendaWidget> createState() => _BarraVendaWidgetState();
}

class _BarraVendaWidgetState extends State<BarraVendaWidget> {
  bool _hover = false;

  AppTheme get theme => widget.theme;

  String get _detalhe {
    final pedido = widget.pedido;
    final pagamentos = pedido.todosPagamentos;
    final formas = pagamentos
        .map((p) => p.forma)
        .where((f) => f.isNotEmpty)
        .join(' + ');
    final temAPrazo = pagamentos.any((p) => p.forma == 'À Prazo');
    return [
      if (widget.mostrarCliente) pedido.clienteNome,
      _dataHora(pedido.dataHora),
      if (formas.isNotEmpty) formas,
      if (pedido.aPrazoEmAberto) 'em aberto',
      if (pedido.aPrazoEmAberto && pedido.valorPago > 0)
        'pago ${_valor(pedido.valorPago)}',
      if (temAPrazo && pedido.quitado) 'quitado',
    ].join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final pedido = widget.pedido;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => VendaRegistradaDialog.mostrar(
          context,
          theme: theme,
          lojaId: widget.lojaId,
          pedido: pedido,
          autorCpf: widget.autorCpf,
          autorNome: widget.autorNome,
          autorEmail: widget.autorEmail,
          onSalvarComentario: widget.onSalvarComentario,
          onExcluir: widget.onExcluir,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _hover
                ? theme.borderColor.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _hover ? theme.textColor : theme.borderColor,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextoRolante(
                      texto: '${_numero(pedido.numero)}  ${pedido.produtoNome}',
                      textAlign: TextAlign.start,
                      style: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TextoRolante(
                      texto: _detalhe,
                      textAlign: TextAlign.start,
                      style: theme.getTextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(_valor(pedido.valor),
                  style: theme.getTextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
