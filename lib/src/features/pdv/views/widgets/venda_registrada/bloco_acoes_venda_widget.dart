import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/impressao_service.dart';

/// Bloco de botões de ação para a venda registrada: Imprimir, Compartilhar, Exportar PDF e Excluir.
class BlocoAcoesVendaWidget extends StatefulWidget {
  final AppTheme theme;
  final String lojaId;
  final PedidoLoja pedido;
  final VoidCallback? onExcluir;

  const BlocoAcoesVendaWidget({
    super.key,
    required this.theme,
    required this.lojaId,
    required this.pedido,
    this.onExcluir,
  });

  @override
  State<BlocoAcoesVendaWidget> createState() => _BlocoAcoesVendaWidgetState();
}

class _BlocoAcoesVendaWidgetState extends State<BlocoAcoesVendaWidget> {
  bool _imprimindo = false;
  bool _exportando = false;

  AppTheme get theme => widget.theme;

  BoxDecoration get _decoracaoDoBloco => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

  ConfiguracoesImpressora _lerConfiguracoesDaLoja() {
    final loja = context.read<PdvProvider>().buscarPorId(widget.lojaId);
    return loja?.configuracoesImpressora ?? const ConfiguracoesImpressora();
  }

  Cliente? _buscarClienteDoPedido() {
    final clienteId = widget.pedido.clienteId;
    if (clienteId == null || clienteId.isEmpty) return null;
    final loja = context.read<PdvProvider>().buscarPorId(widget.lojaId);
    if (loja == null) return null;
    for (final c in loja.clientesLoja) {
      if (c.id == clienteId) return c;
    }
    return null;
  }

  void _snack(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardBackgroundColor,
        content: Text(
          texto,
          style: theme.getTextStyle(color: theme.textColor),
        ),
      ),
    );
  }

  Future<void> _imprimir() async {
    if (_imprimindo) return;
    setState(() => _imprimindo = true);
    try {
      final config = _lerConfiguracoesDaLoja();
      await ImpressaoService.imprimirComanda(
        config: config,
        pedido: widget.pedido,
        cliente: _buscarClienteDoPedido(),
      );
      if (!mounted) return;
      _snack('Comanda enviada para a impressora.');
    } catch (e) {
      if (!mounted) return;
      _snack('Falha ao imprimir: $e');
    } finally {
      if (mounted) setState(() => _imprimindo = false);
    }
  }

  Future<void> _exportarPDF() async {
    if (_exportando) return;
    setState(() => _exportando = true);
    try {
      final config = _lerConfiguracoesDaLoja();
      final caminho = await ImpressaoService.exportarComandaPDF(
        pedido: widget.pedido,
        rodape: config.rodape,
        cliente: _buscarClienteDoPedido(),
        camposClienteComanda: config.camposClienteComanda,
      );
      if (!mounted) return;
      if (caminho == null) {
        _snack('Exportação cancelada.');
      } else {
        _snack('PDF salvo em: $caminho');
      }
    } catch (e) {
      if (!mounted) return;
      _snack('Falha ao exportar: $e');
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _confirmarExclusao() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Excluir Registro',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: Text(
            'Tem certeza que deseja excluir este registro? Essa ação não '
            'pode ser desfeita.',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(fontSize: 14),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancelar',
                style: theme.getTextStyle(color: theme.secondaryTextColor),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Excluir',
                style: theme.getTextStyle(color: theme.dangerColor),
              ),
            ),
          ],
        );
      },
    );

    if (confirmou != true) return;
    widget.onExcluir?.call();
    if (mounted) Navigator.of(context).pop();
  }

  Widget _botaoDeAcao(
    String rotulo, {
    bool destrutivo = false,
    bool carregando = false,
    VoidCallback? aoPressionar,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: destrutivo ? theme.dangerColor : theme.textColor,
        side: BorderSide(
          color: destrutivo ? theme.dangerColor : theme.borderColor,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: carregando
          ? null
          : (aoPressionar ?? () => _snack('$rotulo: em construção')),
      child: carregando
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.textColor,
              ),
            )
          : Text(rotulo, style: theme.getTextStyle(fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final acoes = <Widget>[
      _botaoDeAcao(
        'Imprimir',
        carregando: _imprimindo,
        aoPressionar: _imprimir,
      ),
      _botaoDeAcao('Compartilhar'),
      _botaoDeAcao(
        'Exportar como PDF',
        carregando: _exportando,
        aoPressionar: _exportarPDF,
      ),
      _botaoDeAcao(
        'Excluir Registro',
        destrutivo: true,
        aoPressionar: widget.onExcluir == null ? null : _confirmarExclusao,
      ),
    ];

    final comEspacos = <Widget>[];
    for (var i = 0; i < acoes.length; i++) {
      if (i > 0) comEspacos.add(const SizedBox(width: 8));
      comEspacos.add(acoes[i]);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: comEspacos,
              ),
            ),
          );
        },
      ),
    );
  }
}
