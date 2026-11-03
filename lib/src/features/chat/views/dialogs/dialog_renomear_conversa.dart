import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';

class DialogRenomearConversa {
  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required ConversaChat conversa,
    required Map<String, String> titulosCustomizados,
    required Future<void> Function(String novoTitulo) onSalvar,
  }) async {
    final tituloAtual = conversa.tituloConversa.isNotEmpty
        ? conversa.tituloConversa
        : (titulosCustomizados[conversa.id] ?? '');

    final controller = TextEditingController(text: tituloAtual);

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            conversa.ehGrupo
                ? 'Renomear Grupo'
                : 'Definir Título da Conversa',
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
                  conversa.ehGrupo
                      ? 'Defina o novo nome para este grupo.'
                      : 'Defina um assunto ou título para esta conversa (ex: Reunião, Projeto, etc.). O nome do contato não será alterado.',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: theme.getTextStyle(
                    fontSize: 13,
                    color: theme.textColor,
                  ),
                  decoration: InputDecoration(
                    hintText: conversa.ehGrupo
                        ? 'Nome do grupo'
                        : 'Ex: Projeto Nous, Almoço de domingo...',
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
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
                final novo = controller.text.trim();
                Navigator.pop(ctx);
                await onSalvar(novo);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }
}
