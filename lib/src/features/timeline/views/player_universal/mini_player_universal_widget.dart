import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/timeline/controllers/player_universal_controller.dart';
import 'package:nous/src/features/timeline/views/player_universal/capa_midia_universal_widget.dart';
import 'package:nous/src/features/timeline/views/player_universal/player_universal_expandido_view.dart';

/// Mini-player persistente exibido acima da `FloatingBottomNavBar`
/// sempre que há uma música ou vídeo ativo no `PlayerUniversalController`.
class MiniPlayerUniversalWidget extends StatelessWidget {
  final AppTheme theme;

  const MiniPlayerUniversalWidget({
    super.key,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = PlayerUniversalController.instancia;
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        final pub = ctrl.atual;
        if (!ctrl.visivel || pub == null) {
          return const SizedBox.shrink();
        }

        final titulo = PlayerUniversalController.obterTitulo(pub);
        final autor = pub.autorNome.isNotEmpty ? pub.autorNome : 'Autor';
        final duracao = ctrl.estadoAudio.duracaoEstimada;
        final pos = ctrl.estadoAudio.posicao;
        final progresso = (duracao.inMilliseconds > 0 && !ctrl.modoVideo)
            ? (pos.inMilliseconds / duracao.inMilliseconds).clamp(0.0, 1.0)
            : 0.0;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => PlayerUniversalExpandidoView.mostrar(
                context,
                theme: theme,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardBackgroundColor.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.7),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          CapaMidiaUniversalWidget(
                            theme: theme,
                            publicacao: pub,
                            largura: 42,
                            altura: 42,
                            borderRadius: 8,
                            tamanhoIcone: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  titulo,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  autor,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.secondaryTextColor,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!ctrl.modoVideo)
                            IconButton(
                              tooltip:
                                  ctrl.estaTocando ? 'Pausar' : 'Reproduzir',
                              onPressed: ctrl.alternarPlayPause,
                              icon: Icon(
                                ctrl.estaTocando
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: theme.textColor,
                                size: 26,
                              ),
                            )
                          else
                            IconButton(
                              tooltip: 'Expandir vídeo',
                              onPressed: () =>
                                  PlayerUniversalExpandidoView.mostrar(
                                context,
                                theme: theme,
                              ),
                              icon: Icon(
                                Icons.open_in_full_rounded,
                                color: theme.textColor,
                                size: 20,
                              ),
                            ),
                          IconButton(
                            tooltip: 'Fechar player',
                            onPressed: ctrl.fecharMiniPlayer,
                            icon: Icon(
                              Icons.close_rounded,
                              color: theme.secondaryTextColor,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!ctrl.modoVideo)
                      LinearProgressIndicator(
                        value: progresso,
                        minHeight: 2,
                        backgroundColor:
                            theme.borderColor.withValues(alpha: 0.25),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.textColor,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
