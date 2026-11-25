import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_stories.dart';

/// Aba visual de histórico de Stories da Central da Conta.
class AbaStoriesContaWidget extends StatelessWidget {
  final AppTheme theme;
  final UsuarioNous usuario;
  final List<StorySocial> historicoStories;

  const AbaStoriesContaWidget({
    super.key,
    required this.theme,
    required this.usuario,
    required this.historicoStories,
  });

  @override
  Widget build(BuildContext context) {
    if (historicoStories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: EstadoVazioContainer(
          theme: theme,
          mensagem: 'Seus stories publicados aparecerão arquivados aqui.',
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: historicoStories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.65,
      ),
      itemBuilder: (context, index) {
        final s = historicoStories[index];
        final dt = s.criadoEm.toLocal();
        final dataFmt =
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';

        return GestureDetector(
          onTap: () => DialogVisualizarStory.mostrar(
            context,
            theme: theme,
            story: s,
            stories: historicoStories,
            indiceInicial: index,
            ehAutor: true,
            usuarioLogado: usuario,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: s.ehDestaquePermanente
                    ? theme.buttonColor
                    : theme.borderColor.withValues(alpha: 0.45),
                width: s.ehDestaquePermanente ? 1.8 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (s.caminhoMidia.isNotEmpty)
                  FutureBuilder<String?>(
                    future: TimelineService.resolverCaminhoMidia(
                      s.caminhoMidia,
                    ),
                    builder: (_, snap) {
                      if (snap.data == null) return const SizedBox.shrink();
                      return Image.file(
                        File(snap.data!),
                        fit: BoxFit.cover,
                        cacheWidth: 360,
                      );
                    },
                  )
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        s.texto,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.getTextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.backgroundColor.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dataFmt,
                      style: theme.getTextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: InkWell(
                    onTap: () => TimelineService.alternarDestaqueStory(s),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.backgroundColor.withValues(alpha: 0.78),
                      ),
                      child: Icon(
                        s.ehDestaquePermanente
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 15,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
