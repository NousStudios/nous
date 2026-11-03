import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';

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

  @override
  Widget build(BuildContext context) {
    PedidoLoja? pedido;
    if (msg.dadosPedidoJson.isNotEmpty) {
      try {
        final mapa = jsonDecode(msg.dadosPedidoJson) as Map<String, dynamic>;
        pedido = PedidoLoja.fromJson(mapa);
      } catch (_) {}
    }

    final numero = pedido != null
        ? pedido.numero.toString().padLeft(4, '0')
        : msg.pedidoId;
    final totalFormatado = pedido != null
        ? 'R\$ ${pedido.valor.toStringAsFixed(2)}'
        : (msg.texto.contains('R\$') ? msg.texto : 'Comanda');
    final statusNome = pedido != null
        ? pedido.status.name.toUpperCase()
        : 'COMANDA';

    return Container(
      constraints: const BoxConstraints(maxWidth: 290),
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
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    color: theme.buttonColor,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'COMANDA',
                    style: theme.getTextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.buttonColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: theme.buttonColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  statusNome,
                  style: theme.getTextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: theme.buttonColor,
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
                .take(3)
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
            if (pedido.itens.length > 3)
              Text(
                '+ ${pedido.itens.length - 3} outros itens...',
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
