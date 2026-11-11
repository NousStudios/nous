import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_autoatendimento_service.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/widgets/comanda_pedido.dart';

class CardMensagemComanda extends StatelessWidget {
  final MensagemChat msg;
  final bool enviadaPorMim;
  final bool modoLoja;
  final AppTheme theme;
  final VoidCallback onVerComanda;

  const CardMensagemComanda({
    super.key,
    required this.msg,
    required this.enviadaPorMim,
    this.modoLoja = false,
    required this.theme,
    required this.onVerComanda,
  });

  String _rotuloStatus(StatusPedido status, {bool recusadoPeloCliente = false}) {
    switch (status) {
      case StatusPedido.novo:
        return 'Aguardando aceite da loja (Novos)';
      case StatusPedido.aceito:
        return 'Em preparo (Aceito)';
      case StatusPedido.concluido:
        return 'Concluído';
      case StatusPedido.cancelado:
        return recusadoPeloCliente ? 'Recusado pelo cliente' : 'Cancelado';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdv = context.watch<PdvProvider?>();
    PedidoLoja? pedido;
    bool aguardandoAprovacao = false;
    bool recusadoPeloCliente = false;
    if (msg.dadosPedidoJson.isNotEmpty) {
      try {
        final mapa = jsonDecode(msg.dadosPedidoJson) as Map<String, dynamic>;
        pedido = PedidoLoja.fromJson(mapa);
        aguardandoAprovacao = mapa['aguardandoAprovacaoCliente'] == true;
        recusadoPeloCliente = mapa['recusadoPeloCliente'] == true;
      } catch (_) {}
    }

    String lojaIdAlvo = pedido?.lojaId ?? '';
    if (lojaIdAlvo.isEmpty &&
        msg.conversaId.startsWith('loja_') &&
        msg.conversaId.contains('_usuario_')) {
      lojaIdAlvo = msg.conversaId.substring(
        'loja_'.length,
        msg.conversaId.indexOf('_usuario_'),
      );
    }

    Loja? lojaViva;
    if (pdv != null && msg.pedidoId.isNotEmpty) {
      lojaViva = lojaIdAlvo.isNotEmpty ? pdv.buscarPorId(lojaIdAlvo) : null;
      if (lojaViva != null) {
        final pVivo = lojaViva.pedidosLoja
            .where((p) => p.id == msg.pedidoId)
            .firstOrNull;
        if (pVivo != null) {
          pedido = pVivo;
          lojaIdAlvo = lojaViva.id;
          aguardandoAprovacao = false;
        }
      } else {
        for (final l in pdv.lojas) {
          final pVivo = l.pedidosLoja
              .where((p) => p.id == msg.pedidoId)
              .firstOrNull;
          if (pVivo != null) {
            pedido = pVivo;
            lojaViva = l;
            lojaIdAlvo = l.id;
            aguardandoAprovacao = false;
            break;
          }
        }
      }
    }

    Cliente? clienteDaLoja;
    final idClientePed = pedido?.clienteId ?? '';
    if (lojaViva != null && idClientePed.isNotEmpty) {
      clienteDaLoja = lojaViva.clientesLoja
          .where((c) => c.id == idClientePed)
          .firstOrNull;
    }

    final String statusRodape;
    final bool ehCancelado = pedido?.status == StatusPedido.cancelado;
    if (aguardandoAprovacao) {
      statusRodape = modoLoja
          ? 'Aguardando aprovação do cliente para cair em "Novos"...'
          : 'Aguardando sua aprovação';
    } else if (pedido != null) {
      statusRodape = _rotuloStatus(
        pedido.status,
        recusadoPeloCliente: recusadoPeloCliente,
      );
    } else {
      statusRodape = '';
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título "Comanda" centralizado no topo
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  color: theme.buttonColor,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Comanda',
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ],
            ),
          ),

          // Renderiza a comanda idêntica à impressa pela loja
          if (pedido != null)
            GestureDetector(
              onTap: onVerComanda,
              child: ComandaPedido(
                theme: theme,
                pedido: pedido,
                largura: 300,
                mostrarTitulo: false,
                cliente: clienteDaLoja,
                camposClienteComanda:
                    lojaViva?.configuracoesImpressora.camposClienteComanda ??
                    kCamposClienteComandaPadrao,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                msg.texto,
                style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
              ),
            ),

          // Status da comanda sempre na parte inferior (ex.: Cancelado, Aguardando aprovação...)
          if (statusRodape.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: ehCancelado
                    ? theme.dangerColor.withValues(alpha: 0.14)
                    : theme.backgroundColor.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ehCancelado
                      ? theme.dangerColor.withValues(alpha: 0.5)
                      : theme.borderColor.withValues(alpha: 0.5),
                ),
              ),
              child: TextoRolante(
                texto: statusRodape,
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: ehCancelado ? theme.dangerColor : theme.secondaryTextColor,
                ),
              ),
            ),
          ],

          // Botões de deliberação do cliente quando aguardando aprovação
          if (aguardandoAprovacao && !modoLoja && pedido != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.buttonColor,
                  foregroundColor: theme.buttonTextColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: const Text(
                  'Aprovar Pedido',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  await ChatAutoatendimentoService.aprovarPedidoPeloCliente(
                    context: context,
                    msg: msg,
                    pedido: pedido!,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Pedido aprovado! Enviado com sucesso para a loja.',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.textColor,
                  side: BorderSide(color: theme.borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.edit_note_rounded, size: 15),
                label: const Text(
                  'Adicionar Observação',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                onPressed: () => _abrirDialogObservacao(context, pedido!),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.dangerColor,
                  side: BorderSide(
                    color: theme.dangerColor.withValues(alpha: 0.6),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(
                  Icons.cancel_outlined,
                  size: 15,
                  color: theme.dangerColor,
                ),
                label: Text(
                  'Recusar Pedido',
                  style: theme.getTextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.dangerColor,
                  ),
                ),
                onPressed: () => _confirmarRecusaPedido(context, pedido!),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmarRecusaPedido(
    BuildContext context,
    PedidoLoja pedido,
  ) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.borderColor),
        ),
        title: Text(
          'Recusar Pedido',
          textAlign: TextAlign.center,
          style: theme.getTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        content: Text(
          'Deseja recusar esta proposta de pedido enviada pela loja?',
          textAlign: TextAlign.center,
          style: theme.getTextStyle(
            fontSize: 13,
            color: theme.secondaryTextColor,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Voltar',
              style: theme.getTextStyle(color: theme.secondaryTextColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Recusar Pedido',
              style: theme.getTextStyle(
                color: theme.dangerColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmou == true && context.mounted) {
      await ChatAutoatendimentoService.recusarPedidoPeloCliente(
        context: context,
        msg: msg,
        pedido: pedido,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.cardBackgroundColor,
            content: Text(
              'Pedido recusado.',
              style: theme.getTextStyle(color: theme.textColor),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _abrirDialogObservacao(BuildContext context, PedidoLoja pedido) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Adicionar Observação ao Pedido',
            style: theme.getTextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            style: theme.getTextStyle(fontSize: 13, color: theme.textColor),
            decoration: InputDecoration(
              hintText: 'Ex.: Sem cebola, caprichar no gelo, ponto da carne...',
              hintStyle: theme.getTextStyle(
                fontSize: 12,
                color: theme.secondaryTextColor,
              ),
              filled: true,
              fillColor: theme.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.borderColor),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancelar',
                style: theme.getTextStyle(color: theme.secondaryTextColor),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.buttonColor,
                foregroundColor: theme.buttonTextColor,
              ),
              onPressed: () async {
                final obs = controller.text.trim();
                if (obs.isEmpty) return;
                Navigator.pop(ctx);
                await ChatAutoatendimentoService.modificarObservacaoComanda(
                  context: context,
                  msg: msg,
                  pedido: pedido,
                  novaObservacao: obs,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Observação adicionada à comanda!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Salvar Observação'),
            ),
          ],
        );
      },
    );
  }
}
