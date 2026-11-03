import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/resolvedor_foto_chat.dart';

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
            constraints: const BoxConstraints(maxWidth: 380, maxHeight: 400),
            child: conversasDisponiveis.isEmpty
                ? Center(
                    child: Text(
                      'Nenhum outro contato disponível.',
                      style: theme.getTextStyle(
                        color: theme.secondaryTextColor,
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
                        leading: ResolvedorFotoChat.instancia.buildAvatar(
                          ctx,
                          theme: theme,
                          conversa: c,
                          raio: 16,
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
}
