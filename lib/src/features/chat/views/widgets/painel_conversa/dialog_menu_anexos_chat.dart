import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Modal para escolha do tipo de anexo ao chat (Câmera, Imagem, Documento, Comanda).
class DialogMenuAnexosChat {
  static Future<void> mostrar({
    required BuildContext context,
    required AppTheme theme,
    required VoidCallback onCapturarFotoCamera,
    required VoidCallback onAnexarFoto,
    required VoidCallback onAnexarArquivo,
    required VoidCallback onCompartilharComanda,
  }) async {
    await showDialog(
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
              Icon(Icons.attachment_rounded, color: theme.textColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Anexar ao Chat',
                style: theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.buttonColor.withValues(alpha: 0.15),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: theme.buttonColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Câmera (Tirar Foto)',
                    style: theme.getTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                  subtitle: Text(
                    'Capturar foto instantaneamente',
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onCapturarFotoCamera();
                  },
                ),
                Divider(color: theme.borderColor.withValues(alpha: 0.3)),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.buttonColor.withValues(alpha: 0.15),
                    child: Icon(
                      Icons.image_rounded,
                      color: theme.buttonColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Foto / Imagem',
                    style: theme.getTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                  subtitle: Text(
                    'Fotos de produtos, comprovantes ou galeria',
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onAnexarFoto();
                  },
                ),
                Divider(color: theme.borderColor.withValues(alpha: 0.3)),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.buttonColor.withValues(alpha: 0.15),
                    child: Icon(
                      Icons.insert_drive_file_rounded,
                      color: theme.buttonColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Documento / Arquivo',
                    style: theme.getTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                  subtitle: Text(
                    'PDFs, relatórios e arquivos em geral',
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onAnexarArquivo();
                  },
                ),
                Divider(color: theme.borderColor.withValues(alpha: 0.3)),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.buttonColor.withValues(alpha: 0.15),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: theme.buttonColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Comanda de Pedido',
                    style: theme.getTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                  subtitle: Text(
                    'Compartilhar comanda com itens e total',
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onCompartilharComanda();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
