import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';

class DialogHistoricoEdicoes {
  static void mostrar(
    BuildContext context, {
    required AppTheme theme,
    required MensagemChat msg,
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
          title: Row(
            children: [
              Icon(Icons.history_rounded, color: theme.textColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Histórico de Edições',
                style: theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 380),
            child: msg.historicoEdicoes.isEmpty
                ? Center(
                    child: Text(
                      'Nenhuma versão anterior registrada.',
                      style: theme.getTextStyle(
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: msg.historicoEdicoes.length,
                    separatorBuilder: (context, index) => Divider(
                      color: theme.borderColor.withValues(alpha: 0.3),
                    ),
                    itemBuilder: (_, index) {
                      final item = msg.historicoEdicoes[index];
                      final textoAnterior =
                          item['textoAnterior']?.toString() ?? '';
                      final dataStr = item['dataHoraEdicao']?.toString() ?? '';
                      DateTime? dt = DateTime.tryParse(dataStr)?.toLocal();
                      final horaFormatada = dt != null
                          ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
                          : dataStr;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Versão ${index + 1} • $horaFormatada',
                            style: theme.getTextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            textoAnterior,
                            style: theme.getTextStyle(
                              fontSize: 13,
                              color: theme.textColor,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Fechar',
                style: theme.getTextStyle(color: theme.secondaryTextColor),
              ),
            ),
          ],
        );
      },
    );
  }
}
