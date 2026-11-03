import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/widgets/comanda_pedido.dart';
import 'package:nous/src/features/pdv/views/widgets/venda_registrada/barra_venda_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/venda_registrada/bloco_acoes_venda_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/venda_registrada/bloco_comentario_venda_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/venda_registrada/bloco_itens_venda_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/venda_registrada/bloco_resumo_venda_widget.dart';

const double _larguraBloco = 320;

/// Alias para manter compatibilidade com telas que utilizam BarraVenda
typedef BarraVenda = BarraVendaWidget;

/// Diálogo completo para visualização, impressão, exportação e gestão de uma venda registrada.
class VendaRegistradaDialog {
  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required String lojaId,
    required PedidoLoja pedido,
    required String autorCpf,
    required String autorNome,
    required String autorEmail,
    ValueChanged<DadosComentario>? onSalvarComentario,
    VoidCallback? onExcluir,
  }) {
    return showDialog<void>(
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
            constraints: const BoxConstraints(maxWidth: 500),
            child: _VendaConteudo(
              theme: theme,
              lojaId: lojaId,
              pedido: pedido,
              autorCpf: autorCpf,
              autorNome: autorNome,
              autorEmail: autorEmail,
              onSalvarComentario: onSalvarComentario,
              onExcluir: onExcluir,
            ),
          ),
        );
      },
    );
  }
}

class _VendaConteudo extends StatefulWidget {
  final AppTheme theme;
  final String lojaId;
  final PedidoLoja pedido;
  final String autorCpf;
  final String autorNome;
  final String autorEmail;
  final ValueChanged<DadosComentario>? onSalvarComentario;
  final VoidCallback? onExcluir;

  const _VendaConteudo({
    required this.theme,
    required this.lojaId,
    required this.pedido,
    required this.autorCpf,
    required this.autorNome,
    required this.autorEmail,
    this.onSalvarComentario,
    this.onExcluir,
  });

  @override
  State<_VendaConteudo> createState() => _VendaConteudoState();
}

class _VendaConteudoState extends State<_VendaConteudo> {
  late PedidoLoja _pedidoAtual;

  AppTheme get theme => widget.theme;
  PedidoLoja get pedido => _pedidoAtual;

  @override
  void initState() {
    super.initState();
    _pedidoAtual = widget.pedido;
  }

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

  @override
  Widget build(BuildContext context) {
    final config = _lerConfiguracoesDaLoja();
    final cliente = _buscarClienteDoPedido();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: theme.textColor),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  'Venda Registrada',
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
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                BlocoAcoesVendaWidget(
                  theme: theme,
                  lojaId: widget.lojaId,
                  pedido: pedido,
                  onExcluir: widget.onExcluir,
                ),
                const SizedBox(height: 12),
                ComandaPedido(
                  theme: theme,
                  pedido: pedido,
                  largura: _larguraBloco,
                  cliente: cliente,
                  camposClienteComanda: config.camposClienteComanda,
                ),
                const SizedBox(height: 12),
                BlocoResumoVendaWidget(
                  theme: theme,
                  lojaId: widget.lojaId,
                  pedido: pedido,
                  larguraBloco: _larguraBloco,
                  autorCpf: widget.autorCpf,
                  autorNome: widget.autorNome,
                  autorEmail: widget.autorEmail,
                  onPedidoAtualizado: (novo) {
                    setState(() => _pedidoAtual = novo);
                  },
                ),
                const SizedBox(height: 12),
                BlocoItensVendaWidget(
                  theme: theme,
                  pedido: pedido,
                  larguraBloco: _larguraBloco,
                ),
                const SizedBox(height: 12),
                BlocoComentarioVendaWidget(
                  theme: theme,
                  pedido: pedido,
                  larguraBloco: _larguraBloco,
                  autorCpf: widget.autorCpf,
                  autorNome: widget.autorNome,
                  autorEmail: widget.autorEmail,
                  onSalvarComentario: widget.onSalvarComentario,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}