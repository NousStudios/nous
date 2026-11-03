import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';

class DialogEditarMensagem {
  static void mostrar(
    BuildContext context, {
    required AppTheme theme,
    required MensagemChat msg,
    required Future<void> Function(String novoTexto) onSalvar,
  }) {
    final controller = TextEditingController(text: msg.texto);

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
            'Editar Mensagem',
            style: theme.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'A mensagem exibirá o rótulo (editada) para manter a transparência da conversa.',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  minLines: 1,
                  autofocus: true,
                  style: theme.getTextStyle(
                    fontSize: 13,
                    color: theme.textColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Digite o novo conteúdo...',
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
                    contentPadding: const EdgeInsets.all(12),
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.buttonColor,
                foregroundColor: theme.buttonTextColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final novoTexto = controller.text.trim();
                if (novoTexto.isNotEmpty && novoTexto != msg.texto) {
                  Navigator.pop(ctx);
                  await onSalvar(novoTexto);
                } else {
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }
}
