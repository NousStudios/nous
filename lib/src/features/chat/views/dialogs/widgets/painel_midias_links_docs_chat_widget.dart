import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

class PainelMidiasLinksDocsChatWidget extends StatelessWidget {
  final AppTheme theme;
  final ConversaChat conversa;
  final void Function(String caminho) onVisualizarFotoAmpliada;
  final void Function(String caminho) onAbrirArquivo;

  const PainelMidiasLinksDocsChatWidget({
    super.key,
    required this.theme,
    required this.conversa,
    required this.onVisualizarFotoAmpliada,
    required this.onAbrirArquivo,
  });

  static String _formatarTamanho(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final midias = conversa.mensagens
        .where(
          (m) =>
              m.tipo == 'imagem' &&
              m.caminhoAnexo.trim().isNotEmpty,
        )
        .toList();
    final docs = conversa.mensagens
        .where(
          (m) =>
              m.tipo == 'arquivo' &&
              m.caminhoAnexo.trim().isNotEmpty,
        )
        .toList();
    final links = conversa.mensagens
        .where(
          (m) =>
              m.tipo == 'texto' &&
              (m.texto.contains('http://') ||
                  m.texto.contains('https://') ||
                  m.texto.contains('www.')),
        )
        .toList();
    final totalItens = midias.length + docs.length + links.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 18,
                color: theme.textColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Mídias, Links e Docs',
                style: theme.getTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              if (totalItens > 0) ...[
                const Spacer(),
                Text(
                  '$totalItens',
                  style: theme.getTextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (totalItens == 0)
            Text(
              'Nenhuma mídia ou documento compartilhado nesta conversa.',
              style: theme.getTextStyle(
                fontSize: 11,
                color: theme.secondaryTextColor,
              ),
            )
          else ...[
            // Fotos
            if (midias.isNotEmpty) ...[
              Text(
                'Fotos (${midias.length})',
                style: theme.getTextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: midias.map((m) {
                  final resolvido =
                      ImagemService.resolverCaminhoExistente(
                        m.caminhoAnexo,
                      );
                  final existe =
                      resolvido != null &&
                      File(resolvido).existsSync();

                  return InkWell(
                    onTap: existe
                        ? () => onVisualizarFotoAmpliada(resolvido)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: theme.cardBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.borderColor.withValues(alpha: 0.6),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: existe
                            ? Image.file(
                                File(resolvido),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                  Icons.broken_image_outlined,
                                  size: 24,
                                  color: theme.secondaryTextColor,
                                ),
                              )
                            : Icon(
                                Icons.image_outlined,
                                size: 24,
                                color: theme.secondaryTextColor,
                              ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
            ],

            // Documentos
            if (docs.isNotEmpty) ...[
              Text(
                'Documentos (${docs.length})',
                style: theme.getTextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 6),
              Column(
                children: docs.map((d) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.cardBackgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.insert_drive_file_outlined,
                          size: 20,
                          color: theme.textColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.nomeAnexo.isNotEmpty
                                    ? d.nomeAnexo
                                    : 'Arquivo',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.getTextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textColor,
                                ),
                              ),
                              if (d.tamanhoAnexo > 0)
                                Text(
                                  _formatarTamanho(d.tamanhoAnexo),
                                  style: theme.getTextStyle(
                                    fontSize: 10,
                                    color: theme.secondaryTextColor,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.open_in_new_rounded,
                            size: 16,
                            color: theme.textColor,
                          ),
                          tooltip: 'Abrir',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => onAbrirArquivo(d.caminhoAnexo),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 6),
            ],

            // Links
            if (links.isNotEmpty) ...[
              Text(
                'Links (${links.length})',
                style: theme.getTextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 6),
              Column(
                children: links.map((l) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.cardBackgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.link,
                          size: 18,
                          color: theme.buttonColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SelectableText(
                            l.texto,
                            style: theme.getTextStyle(
                              fontSize: 11,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
