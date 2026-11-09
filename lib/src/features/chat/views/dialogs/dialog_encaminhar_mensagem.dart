import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/resolvedor_foto_chat.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

class DialogEncaminharMensagem {
  static void mostrar(
    BuildContext context, {
    required AppTheme theme,
    required MensagemChat msg,
    required List<ConversaChat> conversasDisponiveis,
    required Future<void> Function(ConversaChat destino) onEncaminhar,
  }) {
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
            'Encaminhar para...',
            style: theme.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380, maxHeight: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _construirPreviaMensagem(msg, theme),
                Flexible(
                  child: conversasDisponiveis.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'Nenhum outro contato disponível.',
                              style: theme.getTextStyle(
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: conversasDisponiveis.length,
                          separatorBuilder: (context, index) => Divider(
                            color: theme.borderColor.withValues(alpha: 0.3),
                          ),
                          itemBuilder: (_, index) {
                            final c = conversasDisponiveis[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              leading: ResolvedorFotoChat.instancia.buildAvatar(
                                ctx,
                                theme: theme,
                                conversa: c,
                                raio: 18,
                              ),
                              title: Text(
                                c.titulo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.getTextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor,
                                ),
                              ),
                              subtitle: Text(
                                c.subtitulo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.getTextStyle(
                                  fontSize: 11,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                              onTap: () async {
                                Navigator.pop(ctx);
                                await onEncaminhar(c);
                              },
                            );
                          },
                        ),
                ),
              ],
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
          ],
        );
      },
    );
  }

  static Widget _construirPreviaMensagem(MensagemChat msg, AppTheme theme) {
    final bool temImagem = msg.tipo == 'imagem' &&
        msg.caminhoAnexo.isNotEmpty &&
        ImagemService.existe(msg.caminhoAnexo);

    final imgProvider = temImagem
        ? ImagemService.obterImageProvider(msg.caminhoAnexo)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          if (temImagem && imgProvider != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Image(
                  image: imgProvider,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.borderColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                msg.tipo == 'imagem'
                    ? Icons.photo_camera_rounded
                    : msg.tipo == 'arquivo'
                        ? Icons.attach_file_rounded
                        : msg.tipo == 'audio'
                            ? Icons.mic_rounded
                            : msg.tipo == 'comanda'
                                ? Icons.receipt_long_rounded
                                : Icons.format_quote_rounded,
                color: theme.textColor,
                size: 20,
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Encaminhando mensagem:',
                  style: theme.getTextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  msg.tipo == 'imagem' && msg.texto.trim().isEmpty
                      ? 'Foto'
                      : msg.tipo == 'audio'
                          ? 'Mensagem de voz'
                          : msg.texto.isNotEmpty
                              ? msg.texto
                              : (msg.nomeAnexo.isNotEmpty
                                  ? msg.nomeAnexo
                                  : 'Arquivo'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
