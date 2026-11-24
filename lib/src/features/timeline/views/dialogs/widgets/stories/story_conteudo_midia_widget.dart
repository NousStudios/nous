import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/widgets/editor_story_view.dart';

/// Renderiza o conteúdo principal do Story (imagem, vídeo ou texto em tela cheia),
/// camadas de texto personalizadas, legenda sobreposta e setas laterais de navegação.
class StoryConteudoMidiaWidget extends StatelessWidget {
  final AppTheme theme;
  final StorySocial story;
  final bool ocultarChrome;
  final bool temRodapeResposta;
  final bool podeVoltar;
  final bool podeAvancar;
  final VoidCallback onVoltar;
  final VoidCallback onAvancar;
  final Future<void> Function(String handle) onTapMencao;

  const StoryConteudoMidiaWidget({
    super.key,
    required this.theme,
    required this.story,
    required this.ocultarChrome,
    required this.temRodapeResposta,
    required this.podeVoltar,
    required this.podeAvancar,
    required this.onVoltar,
    required this.onAvancar,
    required this.onTapMencao,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Mídia ou Fundo de Texto em Tela Cheia
        if (story.caminhoMidia.isNotEmpty)
          FutureBuilder<String?>(
            future: TimelineService.resolverCaminhoMidia(story.caminhoMidia),
            builder: (context, snap) {
              final path = snap.data;
              if (path == null) {
                if (snap.connectionState == ConnectionState.done) {
                  return Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: theme.secondaryTextColor.withValues(alpha: 0.6),
                      size: 48,
                    ),
                  );
                }
                return Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.textColor,
                  ),
                );
              }
              if (story.tipoMidia == 'video') {
                return Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.buttonColor,
                      foregroundColor: theme.buttonTextColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    icon: const Icon(
                      Icons.play_circle_fill_rounded,
                      size: 28,
                    ),
                    label: const Text('Reproduzir vídeo'),
                    onPressed: () async {
                      try {
                        await launchUrl(
                          Uri.file(path),
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (_) {}
                    },
                  ),
                );
              }
              return Image.file(
                File(path),
                fit: BoxFit.contain,
                cacheWidth: 1080,
                errorBuilder: (_, _, _) => Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: theme.secondaryTextColor.withValues(alpha: 0.6),
                    size: 48,
                  ),
                ),
              );
            },
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            alignment: Alignment.center,
            decoration: story.corFundoHex.isNotEmpty
                ? BoxDecoration(
                    color: Color(
                      int.tryParse(story.corFundoHex, radix: 16) ?? 0xFF18181B,
                    ),
                  )
                : BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.buttonColor.withValues(alpha: 0.85),
                        theme.cardBackgroundColor,
                      ],
                    ),
                  ),
            child: story.texto.isNotEmpty
                ? Text(
                    story.texto,
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  )
                : const SizedBox.shrink(),
          ),

        // 2. Camadas de texto personalizadas (arrastadas pelo editor)
        if (story.camadasTexto.isNotEmpty)
          LayoutBuilder(
            builder: (ctx, box) => Stack(
              children: [
                for (final camada in story.camadasTexto)
                  Positioned(
                    left: (camada.x * box.maxWidth - 110)
                        .clamp(8.0, box.maxWidth - 120),
                    top: (camada.y * box.maxHeight - 24)
                        .clamp(56.0, box.maxHeight - 120),
                    child: CamadaTextoStoryWidget(
                      camada: camada,
                      onTapMencao: onTapMencao,
                    ),
                  ),
              ],
            ),
          ),

        // 3. Legenda sobreposta quando há imagem + texto
        if (story.caminhoMidia.isNotEmpty && story.texto.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: temRodapeResposta ? 88 : 32,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: ocultarChrome ? 0.0 : 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.backgroundColor.withValues(alpha: 0.60),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  story.texto,
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 14,
                    color: theme.textColor,
                  ),
                ),
              ),
            ),
          ),

        // 4. Setas laterais discretas para navegar entre Stories
        if (podeVoltar)
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: ocultarChrome ? 0.0 : 1.0,
                child: InkWell(
                  onTap: onVoltar,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: theme.backgroundColor.withValues(alpha: 0.42),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      color: theme.textColor,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (podeAvancar)
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: ocultarChrome ? 0.0 : 1.0,
                child: InkWell(
                  onTap: onAvancar,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: theme.backgroundColor.withValues(alpha: 0.42),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: theme.textColor,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
