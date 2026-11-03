import 'package:flutter/material.dart';
import 'package:nous/src/core/services/player_audio_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';

class CardMensagemAudio extends StatelessWidget {
  final MensagemChat msg;
  final AppTheme theme;
  final bool enviadaPorMim;

  const CardMensagemAudio({
    super.key,
    required this.msg,
    required this.theme,
    required this.enviadaPorMim,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DadosPlayerAudio>(
      valueListenable: PlayerAudioService.instancia.estadoNotifier,
      builder: (context, estado, _) {
        final ehEsteAudio = PlayerAudioService.instancia.ehMesmoAudio(
          msg.caminhoAnexo,
          estado.caminhoOriginal ?? estado.caminho,
        );

        final reproduzindo =
            ehEsteAudio && estado.estado == EstadoPlayerAudio.reproduzindo;
        final pausado =
            ehEsteAudio && estado.estado == EstadoPlayerAudio.pausado;

        final posicao = ehEsteAudio ? estado.posicao : Duration.zero;
        final duracao = ehEsteAudio && estado.duracaoEstimada > Duration.zero
            ? estado.duracaoEstimada
            : Duration.zero;

        String duracaoExibicao = '0:00';
        if (duracao > Duration.zero) {
          final m = duracao.inMinutes;
          final s = duracao.inSeconds % 60;
          duracaoExibicao = '$m:${s.toString().padLeft(2, '0')}';
        } else if (msg.texto.contains('(') && msg.texto.contains(')')) {
          duracaoExibicao = msg.texto
              .split('(')
              .last
              .replaceAll(')', '')
              .trim();
        }

        final posFormatada =
            '${posicao.inMinutes}:${(posicao.inSeconds % 60).toString().padLeft(2, '0')}';

        final maxMs = duracao.inMilliseconds > 0
            ? duracao.inMilliseconds.toDouble()
            : 1.0;
        final valMs = posicao.inMilliseconds.toDouble().clamp(0.0, maxMs);

        return Container(
          constraints: const BoxConstraints(maxWidth: 275),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: theme.cardBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.borderColor.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  if (reproduzindo) {
                    PlayerAudioService.instancia.pausar();
                  } else if (pausado) {
                    PlayerAudioService.instancia.retomar();
                  } else {
                    PlayerAudioService.instancia.tocar(msg.caminhoAnexo);
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: theme.buttonColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    reproduzindo
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: theme.buttonTextColor,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 10,
                        ),
                        activeTrackColor: theme.buttonColor,
                        inactiveTrackColor: theme.borderColor.withValues(
                          alpha: 0.6,
                        ),
                        thumbColor: theme.buttonColor,
                      ),
                      child: Slider(
                        value: valMs,
                        min: 0.0,
                        max: maxMs,
                        onChanged: duracao.inMilliseconds > 0
                            ? (val) {
                                PlayerAudioService.instancia.buscarPosicao(
                                  Duration(milliseconds: val.toInt()),
                                );
                              }
                            : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            ehEsteAudio && (reproduzindo || pausado)
                                ? posFormatada
                                : duracaoExibicao,
                            style: theme.getTextStyle(
                              fontSize: 10,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.mic_rounded,
                                size: 12,
                                color: enviadaPorMim
                                    ? const Color(0xFF34B7F1)
                                    : theme.buttonColor,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                duracaoExibicao,
                                style: theme.getTextStyle(
                                  fontSize: 10,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
