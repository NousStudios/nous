import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';

class CardMensagemArquivo extends StatelessWidget {
  final MensagemChat msg;
  final bool enviadaPorMim;
  final AppTheme theme;
  final VoidCallback onAbrir;

  const CardMensagemArquivo({
    super.key,
    required this.msg,
    required this.enviadaPorMim,
    required this.theme,
    required this.onAbrir,
  });

  String _formatarTamanho(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final ehPdf = msg.nomeAnexo.toLowerCase().endsWith('.pdf');
    final icone = ehPdf
        ? Icons.picture_as_pdf_rounded
        : Icons.insert_drive_file_rounded;

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.buttonColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icone, color: theme.buttonColor, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg.nomeAnexo.isNotEmpty
                      ? msg.nomeAnexo
                      : 'Arquivo anexo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatarTamanho(msg.tamanhoAnexo),
                  style: theme.getTextStyle(
                    fontSize: 10,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: theme.textColor,
            ),
            tooltip: 'Abrir arquivo',
            onPressed: onAbrir,
          ),
        ],
      ),
    );
  }
}
