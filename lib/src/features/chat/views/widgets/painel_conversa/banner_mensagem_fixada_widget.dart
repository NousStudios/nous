import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';

/// Banner exibido no topo da conversa quando há mensagens fixadas.
class BannerMensagemFixadaWidget extends StatelessWidget {
  final List<MensagemChat> fixadas;
  final AppTheme theme;
  final void Function(MensagemChat) onDesafixar;

  const BannerMensagemFixadaWidget({
    super.key,
    required this.fixadas,
    required this.theme,
    required this.onDesafixar,
  });

  @override
  Widget build(BuildContext context) {
    if (fixadas.isEmpty) return const SizedBox.shrink();

    final ultFixada = fixadas.last;
    final txtExibicao = ultFixada.texto.trim().isNotEmpty
        ? ultFixada.texto.trim()
        : (ultFixada.nomeAnexo.trim().isNotEmpty
            ? ultFixada.nomeAnexo.trim()
            : (ultFixada.tipo == 'comanda'
                ? 'Comanda de Pedido'
                : 'Mensagem Fixada'));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: theme.borderColor.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.push_pin_rounded,
            size: 15,
            color: theme.buttonColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Mensagem Fixada${fixadas.length > 1 ? ' (${fixadas.length})' : ''}',
                  style: theme.getTextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: theme.buttonColor,
                  ),
                ),
                Text(
                  txtExibicao,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 11.5,
                    color: theme.textColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              size: 16,
              color: theme.secondaryTextColor,
            ),
            tooltip: 'Desafixar',
            onPressed: () => onDesafixar(ultFixada),
          ),
        ],
      ),
    );
  }
}
