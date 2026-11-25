import 'package:flutter/material.dart';
import 'package:nous/src/core/services/player_audio_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Barra de pré-escuta para ouvir, descartar ou enviar um áudio recém-gravado.
class BarraPreEscutaAudioWidget extends StatelessWidget {
  final AppTheme theme;
  final String caminho;
  final String duracaoTexto;
  final VoidCallback onDescartar;
  final VoidCallback onEnviar;

  const BarraPreEscutaAudioWidget({
    super.key,
    required this.theme,
    required this.caminho,
    required this.duracaoTexto,
    required this.onDescartar,
    required this.onEnviar,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DadosPlayerAudio>(
      valueListenable: PlayerAudioService.instancia.estadoNotifier,
      builder: (context, dados, _) {
        final ehEste = PlayerAudioService.instancia.ehMesmoAudio(
              caminho,
              dados.caminho,
            ) ||
            PlayerAudioService.instancia.ehMesmoAudio(
              caminho,
              dados.caminhoOriginal,
            );
        final tocando =
            ehEste && dados.estado == EstadoPlayerAudio.reproduzindo;
        final totalMs = dados.duracaoEstimada.inMilliseconds;
        final posMs = ehEste ? dados.posicao.inMilliseconds : 0;
        final progresso = (ehEste && totalMs > 0)
            ? (posMs / totalMs).clamp(0.0, 1.0)
            : 0.0;

        return Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: theme.dangerColor,
                size: 24,
              ),
              tooltip: 'Descartar áudio',
              onPressed: onDescartar,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: theme.backgroundColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32),
                      tooltip: tocando ? 'Pausar' : 'Ouvir áudio',
                      onPressed: () => PlayerAudioService.instancia
                          .alternarPlayPause(caminho),
                      icon: Icon(
                        tocando
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: theme.textColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progresso,
                          minHeight: 4,
                          backgroundColor:
                              theme.borderColor.withValues(alpha: 0.35),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.textColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      duracaoTexto,
                      style: theme.getTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onEnviar,
              borderRadius: BorderRadius.circular(21),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.buttonColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send_rounded,
                  size: 18,
                  color: theme.buttonTextColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
