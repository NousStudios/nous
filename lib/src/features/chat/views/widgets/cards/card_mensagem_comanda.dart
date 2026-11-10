import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';

class CardMensagemComanda extends StatelessWidget {
  final MensagemChat msg;
  final bool enviadaPorMim;
  final AppTheme theme;
  final VoidCallback onVerComanda;

  const CardMensagemComanda({
    super.key,
    required this.msg,
    required this.enviadaPorMim,
    required this.theme,
    required this.onVerComanda,
  });

  String _rotuloStatus(StatusPedido status) {
    switch (status) {
      case StatusPedido.novo:
        return 'AGUARDANDO ACEITE (NOVOS)';
      case StatusPedido.aceito:
        return 'EM PREPARO (ACEITO)';
      case StatusPedido.concluido:
        return 'CONCLUÍDO';
      case StatusPedido.cancelado:
        return 'CANCELADO';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdv = context.watch<PdvProvider?>();
    PedidoLoja? pedido;
    if (msg.dadosPedidoJson.isNotEmpty) {
      try {
        final mapa = jsonDecode(msg.dadosPedidoJson) as Map<String, dynamic>;
        pedido = PedidoLoja.fromJson(mapa);
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

    // Sincroniza em tempo real com o estado vivo do pedido na Loja
    if (pdv != null && msg.pedidoId.isNotEmpty) {
      final lojaViva = lojaIdAlvo.isNotEmpty ? pdv.buscarPorId(lojaIdAlvo) : null;
      if (lojaViva != null) {
        final pVivo = lojaViva.pedidosLoja
            .where((p) => p.id == msg.pedidoId)
            .firstOrNull;
        if (pVivo != null) {
          pedido = pVivo;
          lojaIdAlvo = lojaViva.id;
        }
      } else {
        for (final l in pdv.lojas) {
          final pVivo = l.pedidosLoja
              .where((p) => p.id == msg.pedidoId)
              .firstOrNull;
          if (pVivo != null) {
            pedido = pVivo;
            lojaIdAlvo = l.id;
            break;
          }
        }
      }
    }

    final numero = pedido != null
        ? pedido.numero.toString().padLeft(4, '0')
        : msg.pedidoId;
    final totalFormatado = pedido != null
        ? 'R\$ ${pedido.valor.toStringAsFixed(2)}'
        : (msg.texto.contains('R\$') ? msg.texto : 'Comanda');
    final statusNome = pedido != null
        ? _rotuloStatus(pedido.status)
        : 'COMANDA';

    final souMembroDaLoja =
        pdv != null &&
        lojaIdAlvo.isNotEmpty &&
        (pdv.lojasQueAdministro.any((l) => l.id == lojaIdAlvo) ||
            pdv.lojasQueParticipo.any((l) => l.id == lojaIdAlvo));

    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    color: theme.buttonColor,
                    size: 17,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'COMANDA',
                    style: theme.getTextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                ],
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: pedido?.status == StatusPedido.cancelado
                        ? theme.dangerColor.withValues(alpha: 0.15)
                        : theme.buttonColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: pedido?.status == StatusPedido.cancelado
                          ? theme.dangerColor.withValues(alpha: 0.5)
                          : theme.buttonColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    statusNome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.getTextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: pedido?.status == StatusPedido.cancelado
                          ? theme.dangerColor
                          : theme.buttonColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Pedido #$numero',
            style: theme.getTextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          if (pedido != null && pedido.clienteNome.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Cliente: ${pedido.clienteNome}',
              style: theme.getTextStyle(
                fontSize: 11,
                color: theme.secondaryTextColor,
              ),
            ),
          ],
          if (pedido != null && pedido.itens.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...pedido.itens
                .take(4)
                .map(
                  (it) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        Text(
                          '${it.quantidade}x ',
                          style: theme.getTextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            it.nomeExibicao,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.getTextStyle(
                              fontSize: 11,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            if (pedido.itens.length > 4)
              Text(
                '+ ${pedido.itens.length - 4} outros itens...',
                style: theme
                    .getTextStyle(fontSize: 10, color: theme.secondaryTextColor)
                    .copyWith(fontStyle: FontStyle.italic),
              ),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: theme.getTextStyle(
                  fontSize: 11,
                  color: theme.secondaryTextColor,
                ),
              ),
              Text(
                totalFormatado,
                style: theme.getTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (souMembroDaLoja &&
              pedido != null &&
              (pedido.status == StatusPedido.novo ||
                  pedido.status == StatusPedido.aceito)) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.textColor,
                  side: BorderSide(color: theme.buttonColor),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(
                  pedido.status == StatusPedido.novo
                      ? Icons.check_circle_outline_rounded
                      : Icons.task_alt_rounded,
                  size: 14,
                  color: theme.buttonColor,
                ),
                label: Text(
                  pedido.status == StatusPedido.novo
                      ? 'Aceitar Pedido (Em Preparo)'
                      : 'Marcar como Concluído',
                  style: theme.getTextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                onPressed: () {
                  final lojaAtual = pdv.buscarPorId(lojaIdAlvo);
                  if (lojaAtual == null || pedido == null) return;
                  final proximoStatus = pedido.status == StatusPedido.novo
                      ? StatusPedido.aceito
                      : StatusPedido.concluido;
                  final pedidoAtualizado = pedido.copyWith(
                    status: proximoStatus,
                  );
                  final novosPedidos = lojaAtual.pedidosLoja
                      .map((p) => p.id == pedido!.id ? pedidoAtualizado : p)
                      .toList();
                  pdv.atualizarListasLoja(lojaAtual.id, pedidos: novosPedidos);
                },
              ),
            ),
            const SizedBox(height: 6),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.buttonColor,
                foregroundColor: theme.buttonTextColor,
                padding: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.visibility_rounded, size: 14),
              label: const Text(
                'Ver Comanda Completa',
                style: TextStyle(fontSize: 11),
              ),
              onPressed: onVerComanda,
            ),
          ),
        ],
      ),
    );
  }
}
