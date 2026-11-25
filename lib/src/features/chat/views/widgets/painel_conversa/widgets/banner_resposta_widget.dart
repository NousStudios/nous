import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';

/// Banner exibido acima da barra de envio indicando a mensagem sendo respondida.
class BannerRespostaWidget extends StatelessWidget {
  final AppTheme theme;
  final MensagemChat mensagemRespondendo;
  final VoidCallback? onCancelarResposta;

  const BannerRespostaWidget({
    super.key,
    required this.theme,
    required this.mensagemRespondendo,
    this.onCancelarResposta,
  });

  @override
  Widget build(BuildContext context) {
    final resp = mensagemRespondendo;
    final autor = resp.remetenteNome.isNotEmpty
        ? resp.remetenteNome
        : (resp.enviadaPorMim ? 'Você' : 'Contato');
    final preview = resp.texto.trim().isNotEmpty
        ? resp.texto.trim()
        : (resp.tipo == 'audio'
              ? 'Áudio'
              : (resp.tipo == 'imagem'
                    ? 'Foto'
                    : (resp.nomeAnexo.isNotEmpty ? resp.nomeAnexo : 'Mídia')));

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        border: Border(
          top: BorderSide(color: theme.borderColor.withValues(alpha: 0.45)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 34,
            decoration: BoxDecoration(
              color: theme.textColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  autor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.textColor,
                  ),
                ),
                Text(
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 11.5,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: theme.secondaryTextColor,
            ),
            tooltip: 'Cancelar resposta',
            onPressed: onCancelarResposta,
          ),
        ],
      ),
    );
  }
}
