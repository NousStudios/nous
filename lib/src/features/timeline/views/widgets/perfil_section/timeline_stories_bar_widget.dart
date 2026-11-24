import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_stories.dart';
import 'package:nous/src/features/timeline/views/widgets/camera_criacao_view.dart';

/// Barra horizontal de stories e destaques do perfil público.
class TimelineStoriesBarWidget extends StatelessWidget {
  final AppTheme theme;
  final List<StorySocial> stories;
  final UsuarioNous contaPerfil;
  final UsuarioNous? usuarioLogado;
  final bool ehProprioUsuario;

  const TimelineStoriesBarWidget({
    super.key,
    required this.theme,
    required this.stories,
    required this.contaPerfil,
    required this.usuarioLogado,
    required this.ehProprioUsuario,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ehProprioUsuario)
              Padding(
                padding: EdgeInsets.only(right: stories.isNotEmpty ? 10 : 0),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (camCtx) => CameraCriacaoView(
                        theme: theme,
                        autor: contaPerfil,
                        ativa: true,
                        onVoltarPerfil: () => Navigator.of(camCtx).pop(),
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.cardBackgroundColor,
                          border: Border.all(
                            color: theme.borderColor.withValues(alpha: 0.7),
                            width: 1.4,
                          ),
                        ),
                        child: Icon(
                          Icons.add,
                          size: 22,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '+ Story',
                        style: theme.getTextStyle(
                          fontSize: 10,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            for (int idxStory = 0; idxStory < stories.length; idxStory++)
              Padding(
                padding: EdgeInsets.only(
                  right: idxStory < stories.length - 1 ? 10 : 0,
                ),
                child: GestureDetector(
                  onTap: () => DialogVisualizarStory.mostrar(
                    context,
                    theme: theme,
                    story: stories[idxStory],
                    stories: stories,
                    indiceInicial: idxStory,
                    ehAutor: ehProprioUsuario,
                    usuarioLogado: usuarioLogado,
                  ),
                  child: SizedBox(
                    width: 62,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.cardBackgroundColor,
                            border: Border.all(
                              color: theme.borderColor,
                              width: 2,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: stories[idxStory].caminhoMidia.isNotEmpty
                              ? FutureBuilder<String?>(
                                  future: TimelineService.resolverCaminhoMidia(
                                    stories[idxStory].caminhoMidia,
                                  ),
                                  builder: (_, snap) {
                                    if (snap.data == null) {
                                      return Icon(
                                        Icons.auto_awesome,
                                        size: 20,
                                        color: theme.textColor,
                                      );
                                    }
                                    return Image.file(
                                      File(snap.data!),
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                              : Icon(
                                  Icons.text_fields_rounded,
                                  size: 20,
                                  color: theme.textColor,
                                ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          stories[idxStory].tituloDestaque.isNotEmpty
                              ? stories[idxStory].tituloDestaque
                              : 'Story',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 10,
                            color: theme.textColor,
                          ),
                        ),
                      ],
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
