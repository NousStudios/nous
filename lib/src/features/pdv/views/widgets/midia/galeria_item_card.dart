import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nous/src/core/services/metadados_audio_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/ajustar_imagem_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/galeria_estilo_container.dart';
import 'package:nous/src/features/pdv/views/widgets/midia/previa_visual_midia.dart';

/// Card de ação para selecionar e adicionar novos arquivos à galeria.
class GaleriaAdicionarCard extends StatelessWidget {
  final AppTheme theme;
  final VoidCallback onTap;

  const GaleriaAdicionarCard({
    super.key,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 126,
      height: 156,
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.6),
          style: BorderStyle.solid,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.backgroundColor.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 26,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Adicionar',
                style: theme.getTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Novo arquivo',
                style: theme.getTextStyle(
                  fontSize: 10,
                  color: theme.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card individual de item de mídia na galeria, com prévia, título e ações rápidas.
class GaleriaItemCard extends StatelessWidget {
  final AppTheme theme;
  final int index;
  final String caminho;
  final TipoAnexoLoja tipo;
  final IconData iconeFallback;
  final bool temDescricao;
  final VoidCallback onAbrir;
  final VoidCallback onConfirmarRemover;
  final void Function(int index, String novoCaminho)? onSubstituirItem;

  const GaleriaItemCard({
    super.key,
    required this.theme,
    required this.index,
    required this.caminho,
    required this.tipo,
    required this.iconeFallback,
    required this.temDescricao,
    required this.onAbrir,
    required this.onConfirmarRemover,
    this.onSubstituirItem,
  });

  String _extrairNomeArquivo() {
    final partes = caminho.replaceAll(r'\', '/').split('/');
    return partes.isNotEmpty ? partes.last : 'Arquivo';
  }

  String _obterTamanhoFormatado() {
    try {
      final resolvido =
          ImagemService.resolverCaminhoExistente(caminho) ?? caminho;
      final arq = File(resolvido);
      if (arq.existsSync()) {
        return ImagemService.formatarTamanhoBytes(arq.lengthSync());
      }
    } catch (_) {}
    return '';
  }

  Widget _buildBadgeCircular({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.backgroundColor.withValues(alpha: 0.45),
            blurRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nomeArquivo = _extrairNomeArquivo();
    final tamanhoTexto = _obterTamanhoFormatado();

    MetadadosAudio? metaAudio;
    if (tipo == TipoAnexoLoja.musicas ||
        tipo == TipoAnexoLoja.arquivosAudio) {
      metaAudio = MetadadosAudioService.extrair(caminho);
    }

    final tituloExibido = (metaAudio?.titulo?.trim().isNotEmpty == true)
        ? metaAudio!.titulo!
        : nomeArquivo;
    final subtituloExibido = (metaAudio?.artista?.trim().isNotEmpty == true)
        ? metaAudio!.artista!
        : (tamanhoTexto.isNotEmpty ? tamanhoTexto : '');

    return Container(
      width: 126,
      height: 156,
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.backgroundColor.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onAbrir,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Área Visual Superior
                    Expanded(
                      flex: 6,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(11),
                        ),
                        child: PreviaVisualMidia(
                          theme: theme,
                          caminho: caminho,
                          tipo: tipo,
                          iconeFallback: iconeFallback,
                          metaAudio: metaAudio,
                        ),
                      ),
                    ),

                    // Área Textual Inferior (Legível com fundo contrastante)
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        color: theme.backgroundColor.withValues(alpha: 0.4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              tituloExibido,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.getTextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                            if (subtituloExibido.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtituloExibido,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.getTextStyle(
                                  fontSize: 10,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Indicador de Descrição Existente
            if (temDescricao)
              Positioned(
                top: 6,
                left: 6,
                child: _buildBadgeCircular(
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 11,
                    color: theme.textColor,
                  ),
                ),
              ),

            // Botão Ajustar / Recortar (para fotos da galeria)
            if (tipo == TipoAnexoLoja.galeria && onSubstituirItem != null)
              Positioned(
                top: 6,
                left: 6,
                child: Tooltip(
                  message: 'Ajustar / Recortar imagem',
                  child: GestureDetector(
                    onTap: () async {
                      final novo = await AjustarImagemDialog.mostrar(
                        context,
                        theme: theme,
                        caminhoImagem: caminho,
                      );
                      if (novo != null) {
                        onSubstituirItem!(index, novo);
                      }
                    },
                    child: _buildBadgeCircular(
                      child: Icon(
                        Icons.crop,
                        size: 13,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                ),
              ),

            // Botão Excluir (X) com confirmação
            Positioned(
              top: 6,
              right: 6,
              child: Tooltip(
                message: 'Remover anexo',
                child: GestureDetector(
                  onTap: onConfirmarRemover,
                  child: _buildBadgeCircular(
                    child: Icon(
                      Icons.close,
                      size: 13,
                      color: theme.dangerColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
