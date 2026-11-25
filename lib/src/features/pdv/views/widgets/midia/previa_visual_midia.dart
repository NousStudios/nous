import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nous/src/core/services/metadados_audio_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/galeria_estilo_container.dart';

/// Renderiza a prévia visual de um item da galeria de acordo com o tipo de mídia.
class PreviaVisualMidia extends StatelessWidget {
  final AppTheme theme;
  final String caminho;
  final TipoAnexoLoja tipo;
  final IconData iconeFallback;
  final MetadadosAudio? metaAudio;

  const PreviaVisualMidia({
    super.key,
    required this.theme,
    required this.caminho,
    required this.tipo,
    required this.iconeFallback,
    this.metaAudio,
  });

  String _extrairExtensao() {
    try {
      final partes = caminho.split('.');
      if (partes.length > 1) {
        return partes.last.toUpperCase();
      }
    } catch (_) {}
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final ehImagem = tipo == TipoAnexoLoja.galeria ||
        ImagemService.extensaoImagemValida(caminho);
    final ext = _extrairExtensao();

    if (ehImagem) {
      final resolvido =
          ImagemService.resolverCaminhoExistente(caminho) ?? caminho;
      return Image.file(
        File(resolvido),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => Center(
          child: Icon(
            iconeFallback,
            size: 32,
            color: theme.secondaryTextColor,
          ),
        ),
      );
    }

    if (tipo == TipoAnexoLoja.musicas ||
        tipo == TipoAnexoLoja.arquivosAudio) {
      if (metaAudio?.temCapa == true) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(
              metaAudio!.capaBytes!,
              fit: BoxFit.cover,
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: theme.backgroundColor.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.graphic_eq_rounded,
                  size: 13,
                  color: theme.textColor,
                ),
              ),
            ),
          ],
        );
      }

      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.buttonColor.withValues(alpha: 0.25),
              theme.backgroundColor.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.music_note_rounded,
                size: 36,
                color: theme.buttonColor,
              ),
              if (ext.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: theme.backgroundColor.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    ext,
                    style: theme.getTextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (tipo == TipoAnexoLoja.videos) {
      return Container(
        color: theme.backgroundColor.withValues(alpha: 0.65),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.smart_display_rounded,
                size: 36,
                color: theme.buttonColor,
              ),
              if (ext.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: theme.cardBackgroundColor.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    ext,
                    style: theme.getTextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Documentos / Arquivos em Geral
    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.5),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconeFallback,
              size: 36,
              color: theme.textColor,
            ),
            if (ext.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.cardBackgroundColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  ext,
                  style: theme.getTextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
