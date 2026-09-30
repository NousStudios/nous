import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/services/impressao_service.dart';
import 'package:nous/src/features/pdv/views/widgets/comanda_pedido.dart';

class VendaConcluidaDialog {
  static Future<bool> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required PedidoLoja pedido,
    required ConfiguracoesImpressora configuracoesImpressora,
  }) async {
    final resultado = await showDialog<bool>(
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
            constraints: const BoxConstraints(maxWidth: 500),
            child: _VendaConcluidaConteudo(
              theme: theme,
              pedido: pedido,
              configuracoesImpressora: configuracoesImpressora,
            ),
          ),
        );
      },
    );
    return resultado ?? false;
  }
}

class _VendaConcluidaConteudo extends StatefulWidget {
  final AppTheme theme;
  final PedidoLoja pedido;
  final ConfiguracoesImpressora configuracoesImpressora;

  const _VendaConcluidaConteudo({
    required this.theme,
    required this.pedido,
    required this.configuracoesImpressora,
  });

  @override
  State<_VendaConcluidaConteudo> createState() =>
      _VendaConcluidaConteudoState();
}

class _VendaConcluidaConteudoState extends State<_VendaConcluidaConteudo> {
  bool _imprimindo = false;

  AppTheme get theme => widget.theme;
  PedidoLoja get pedido => widget.pedido;

  Future<void> _imprimir() async {
    if (_imprimindo) return;

    setState(() => _imprimindo = true);
    try {
      await ImpressaoService.imprimirComanda(
        config: widget.configuracoesImpressora,
        pedido: pedido,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: theme.cardBackgroundColor,
          content: Text(
            'Comanda enviada para a impressora.',
            style: theme.getTextStyle(color: theme.textColor),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: theme.cardBackgroundColor,
          content: Text(
            'Falha ao imprimir: $e',
            style: theme.getTextStyle(color: theme.textColor),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _imprimindo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Venda concluída',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Pedido #${pedido.numero.toString().padLeft(4, '0')}',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 14,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'R\$ ${pedido.valor.toStringAsFixed(2).replaceAll('.', ',')}',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 14,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: ComandaPedido(
                theme: theme,
                pedido: pedido,
                mostrarTitulo: false,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
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
                  onPressed: _imprimindo ? null : _imprimir,
                  child: _imprimindo
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.textColor,
                          ),
                        )
                      : Text(
                          'Imprimir',
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
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Concluído',
                    style: theme.getTextStyle(
                      fontSize: 13,
                      color: theme.buttonTextColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}