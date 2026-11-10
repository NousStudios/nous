import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';

class DialogMenuMensagem {
  static void mostrar(
    BuildContext context, {
    required AppTheme theme,
    required MensagemChat msg,
    required VoidCallback onEditar,
    required VoidCallback onEncaminhar,
    required VoidCallback onAlternarFavorita,
    required VoidCallback onVerHistorico,
    required VoidCallback onExcluir,
  }) {
    final agora = DateTime.now();
    final dataEnvio = msg.dataHora;
    final diferencaSegundos = agora.difference(dataEnvio).inSeconds;
    final podeExcluir = msg.enviadaPorMim && diferencaSegundos <= 60;
    final podeEditar = msg.enviadaPorMim && msg.tipo == 'texto';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Copiar texto
                if (msg.texto.isNotEmpty)
                  ListTile(
                    leading: Icon(
                      Icons.copy_rounded,
                      color: theme.textColor,
                      size: 20,
                    ),
                    title: Text(
                      'Copiar texto',
                      style: theme.getTextStyle(
                        fontSize: 13,
                        color: theme.textColor,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      Clipboard.setData(ClipboardData(text: msg.texto));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Mensagem copiada para a área de transferência.',
                          ),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),

                // 2. Editar mensagem
                if (podeEditar)
                  ListTile(
                    leading: Icon(
                      Icons.edit_outlined,
                      color: theme.textColor,
                      size: 20,
                    ),
                    title: Text(
                      'Editar mensagem',
                      style: theme.getTextStyle(
                        fontSize: 13,
                        color: theme.textColor,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      onEditar();
                    },
                  ),

                // 3. Encaminhar mensagem
                ListTile(
                  leading: Icon(
                    Icons.forward_rounded,
                    color: theme.textColor,
                    size: 20,
                  ),
                  title: Text(
                    'Encaminhar',
                    style: theme.getTextStyle(
                      fontSize: 13,
                      color: theme.textColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onEncaminhar();
                  },
                ),

                // 4. Favoritar / Desfavoritar mensagem
                ListTile(
                  leading: Icon(
                    msg.favorita
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: msg.favorita
                        ? const Color(0xFFFFB300)
                        : theme.textColor,
                    size: 20,
                  ),
                  title: Text(
                    msg.favorita
                        ? 'Desfavoritar mensagem'
                        : 'Favoritar mensagem',
                    style: theme.getTextStyle(
                      fontSize: 13,
                      color: theme.textColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onAlternarFavorita();
                  },
                ),

                // 5. Histórico de Edições
                if (msg.editada)
                  ListTile(
                    leading: Icon(
                      Icons.history_rounded,
                      color: theme.textColor,
                      size: 20,
                    ),
                    title: Text(
                      'Histórico de edições',
                      style: theme.getTextStyle(
                        fontSize: 13,
                        color: theme.textColor,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      onVerHistorico();
                    },
                  ),

                // 5. Excluir mensagem (limite de 60s)
                if (podeExcluir) ...[
                  Divider(color: theme.borderColor.withValues(alpha: 0.3)),
                  ListTile(
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      color: theme.dangerColor,
                      size: 20,
                    ),
                    title: Text(
                      'Excluir para todos (${60 - diferencaSegundos}s restantes)',
                      style: theme.getTextStyle(
                        fontSize: 13,
                        color: theme.dangerColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      onExcluir();
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
