import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';

/// Cabeçalho do visualizador de Stories: barras de progresso segmentadas,
/// dados do autor, botão de pausa/retomada e botão de fechar.
class StoryTopoWidget extends StatelessWidget {
  final AppTheme theme;
  final StorySocial story;
  final int totalStories;
  final int indiceAtual;
  final AnimationController timerCtrl;
  final ImageProvider? providerAutor;
  final bool ocultarChrome;
  final bool pausadoManual;
  final VoidCallback onAlternarPausa;
  final VoidCallback onFechar;

  const StoryTopoWidget({
    super.key,
    required this.theme,
    required this.story,
    required this.totalStories,
    required this.indiceAtual,
    required this.timerCtrl,
    required this.providerAutor,
    required this.ocultarChrome,
    required this.pausadoManual,
    required this.onAlternarPausa,
    required this.onFechar,
  });

  String _formatarTempoStory(StorySocial s) {
    final diff = DateTime.now().difference(s.criadoEm);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    final l = s.criadoEm.toLocal();
    final d = l.day.toString().padLeft(2, '0');
    final m = l.month.toString().padLeft(2, '0');
    return '$d/$m/${l.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      left: 10,
      right: 10,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: ocultarChrome ? 0.0 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: List.generate(totalStories, (i) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: AnimatedBuilder(
                        animation: timerCtrl,
                        builder: (_, _) {
                          final double prog;
                          if (i < indiceAtual) {
                            prog = 1.0;
                          } else if (i == indiceAtual) {
                            prog = timerCtrl.value;
                          } else {
                            prog = 0.0;
                          }
                          return LinearProgressIndicator(
                            value: prog,
                            minHeight: 3,
                            backgroundColor:
                                theme.textColor.withValues(alpha: 0.30),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(theme.textColor),
                          );
                        },
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: theme.textColor.withValues(alpha: 0.24),
                  backgroundImage: providerAutor,
                  child: providerAutor == null
                      ? Icon(
                          Icons.person,
                          size: 18,
                          color: theme.textColor,
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.tituloDestaque.isNotEmpty
                            ? '${story.autorNome} • ${story.tituloDestaque}'
                            : (story.autorNome.isNotEmpty
                                  ? story.autorNome
                                  : 'Story Nous'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.getTextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                      if (story.storyOriginalId.isNotEmpty)
                        Text(
                          'Repostado de ${story.autorOriginalNome.isNotEmpty ? story.autorOriginalNome : "outro perfil"}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 10.5,
                            color: theme.textColor.withValues(alpha: 0.78),
                          ),
                        ),
                      Text(
                        _formatarTempoStory(story),
                        style: theme.getTextStyle(
                          fontSize: 11,
                          color: theme.textColor.withValues(alpha: 0.78),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: pausadoManual ? 'Retomar story' : 'Pausar story',
                  icon: Icon(
                    pausadoManual
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    color: theme.textColor,
                  ),
                  onPressed: onAlternarPausa,
                ),
                IconButton(
                  icon: Icon(Icons.close, color: theme.textColor),
                  onPressed: onFechar,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Rodapé exibido para o autor do Story: visualizações e ações de gestão.
class StoryRodapeAutorWidget extends StatelessWidget {
  final AppTheme theme;
  final StorySocial story;
  final bool ocultarChrome;
  final VoidCallback onMostrarVisualizadores;
  final VoidCallback onEncaminhar;
  final VoidCallback onAlternarDestaque;
  final VoidCallback onArquivar;
  final VoidCallback onExcluir;

  const StoryRodapeAutorWidget({
    super.key,
    required this.theme,
    required this.story,
    required this.ocultarChrome,
    required this.onMostrarVisualizadores,
    required this.onEncaminhar,
    required this.onAlternarDestaque,
    required this.onArquivar,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 10,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: ocultarChrome ? 0.0 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onMostrarVisualizadores,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.backgroundColor.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: FutureBuilder<List<UsuarioNous>>(
                        future: ContasNousService.carregarTodas(),
                        builder: (context, snap) {
                          final cpfs = story.visualizadoPorCpfs;
                          if (cpfs.isEmpty) {
                            return Row(
                              children: [
                                Icon(
                                  Icons.visibility_outlined,
                                  color: theme.textColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '0 visualizações',
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.getTextStyle(
                                      fontSize: 12,
                                      color:
                                          theme.textColor.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Icon(
                                Icons.visibility_outlined,
                                color: theme.textColor,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${cpfs.length} visualizações',
                                style: theme.getTextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Enviar no chat',
                      icon: Icon(
                        Icons.send_outlined,
                        color: theme.textColor,
                        size: 19,
                      ),
                      onPressed: onEncaminhar,
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: story.ehDestaquePermanente
                          ? 'Remover destaque'
                          : 'Destacar',
                      icon: Icon(
                        story.ehDestaquePermanente
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: theme.textColor,
                        size: 20,
                      ),
                      onPressed: onAlternarDestaque,
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Arquivar story',
                      icon: Icon(
                        Icons.archive_outlined,
                        color: theme.textColor,
                        size: 20,
                      ),
                      onPressed: onArquivar,
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Excluir story',
                      icon: Icon(
                        Icons.delete_outline,
                        color: theme.dangerColor,
                        size: 20,
                      ),
                      onPressed: onExcluir,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rodapé exibido para visitantes do Story: campo de resposta rápida,
/// reações com emoji, encaminhamento e repost.
class StoryRodapeRespostaWidget extends StatelessWidget {
  final AppTheme theme;
  final TextEditingController respostaCtrl;
  final FocusNode respostaFocus;
  final bool ocultarChrome;
  final ValueChanged<String> onEnviarResposta;
  final VoidCallback onEncaminhar;
  final VoidCallback onRepostar;

  const StoryRodapeRespostaWidget({
    super.key,
    required this.theme,
    required this.respostaCtrl,
    required this.respostaFocus,
    required this.ocultarChrome,
    required this.onEnviarResposta,
    required this.onEncaminhar,
    required this.onRepostar,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 10,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: ocultarChrome ? 0.0 : 1.0,
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: theme.backgroundColor.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.45),
                  ),
                ),
                child: TextField(
                  controller: respostaCtrl,
                  focusNode: respostaFocus,
                  style: theme.getTextStyle(
                    fontSize: 13,
                    color: theme.textColor,
                  ),
                  onSubmitted: onEnviarResposta,
                  decoration: InputDecoration(
                    hintText: 'Enviar mensagem...',
                    hintStyle: theme.getTextStyle(
                      fontSize: 12.5,
                      color: theme.secondaryTextColor.withValues(alpha: 0.70),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            for (final emoji in const ['❤️', '🔥', '👏'])
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => onEnviarResposta(emoji),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 6,
                  ),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            IconButton(
              tooltip: 'Enviar resposta',
              icon: Icon(
                Icons.send_rounded,
                color: theme.textColor,
                size: 20,
              ),
              onPressed: () => onEnviarResposta(respostaCtrl.text),
            ),
            IconButton(
              tooltip: 'Enviar no chat',
              icon: Icon(
                Icons.share_outlined,
                color: theme.textColor,
                size: 20,
              ),
              onPressed: onEncaminhar,
            ),
            IconButton(
              tooltip: 'Repostar no meu Story',
              icon: Icon(
                Icons.repeat_rounded,
                color: theme.textColor,
                size: 20,
              ),
              onPressed: onRepostar,
            ),
          ],
        ),
      ),
    );
  }
}
