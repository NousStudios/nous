import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nous/src/core/services/player_audio_service.dart';
import 'package:nous/src/core/services/metadados_audio_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

class ReprodutorAudioWidget extends StatefulWidget {
  final AppTheme theme;
  final String caminho;
  final String? tituloPadrao;
  final String? subtituloPadrao;
  final VoidCallback? onFechar;
  final VoidCallback? onAnterior;
  final VoidCallback? onProximo;

  const ReprodutorAudioWidget({
    super.key,
    required this.theme,
    required this.caminho,
    this.tituloPadrao,
    this.subtituloPadrao,
    this.onFechar,
    this.onAnterior,
    this.onProximo,
  });

  @override
  State<ReprodutorAudioWidget> createState() => _ReprodutorAudioWidgetState();
}

class _ReprodutorAudioWidgetState extends State<ReprodutorAudioWidget> {
  MetadadosAudio? _metadados;
  double _volumeAnterior = 1.0;
  StreamSubscription<void>? _completeSub;

  @override
  void initState() {
    super.initState();
    _carregarMetadados();
    _completeSub = PlayerAudioService.instancia.onPlayerComplete.listen((_) {
      if (mounted && widget.onProximo != null && !PlayerAudioService.instancia.estadoAtual.loop) {
        widget.onProximo!();
      }
    });
  }

  @override
  void dispose() {
    _completeSub?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ReprodutorAudioWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.caminho != widget.caminho) {
      _carregarMetadados();
    }
  }

  void _carregarMetadados() {
    final meta = MetadadosAudioService.extrair(widget.caminho);
    setState(() {
      _metadados = meta;
    });
  }

  String _formatarTempo(Duration duration) {
    final minutos = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final segundos =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      final horas = duration.inHours.toString().padLeft(2, '0');
      return '$horas:$minutos:$segundos';
    }
    return '$minutos:$segundos';
  }

  String _extrairNomeArquivo(String caminho) {
    try {
      final nome = caminho.split(RegExp(r'[\\/]')).last;
      final partes = nome.split('.');
      if (partes.length > 1) partes.removeLast();
      return partes.join('.');
    } catch (_) {
      return 'Áudio';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final playerService = PlayerAudioService.instancia;

    return ValueListenableBuilder<DadosPlayerAudio>(
      valueListenable: playerService.estadoNotifier,
      builder: (context, estado, child) {
        final ehEsteArquivo = estado.caminho == widget.caminho;
        final tocando =
            ehEsteArquivo && estado.estado == EstadoPlayerAudio.reproduzindo;
        final pausado =
            ehEsteArquivo && estado.estado == EstadoPlayerAudio.pausado;

        final duracaoTotal = (ehEsteArquivo &&
                estado.duracaoEstimada > Duration.zero)
            ? estado.duracaoEstimada
            : const Duration(seconds: 1);
        final posicaoAtual = (ehEsteArquivo && estado.posicao <= duracaoTotal)
            ? estado.posicao
            : Duration.zero;

        final valorProgresso =
            (posicaoAtual.inMilliseconds / duracaoTotal.inMilliseconds)
                .clamp(0.0, 1.0);

        final tituloExibicao = (_metadados?.titulo != null &&
                _metadados!.titulo!.trim().isNotEmpty)
            ? _metadados!.titulo!
            : (widget.tituloPadrao?.isNotEmpty == true
                ? widget.tituloPadrao!
                : _extrairNomeArquivo(widget.caminho));

        final subtituloExibicao = (_metadados?.artista != null &&
                _metadados!.artista!.trim().isNotEmpty)
            ? _metadados!.artista!
            : (widget.subtituloPadrao?.isNotEmpty == true
                ? widget.subtituloPadrao!
                : (_metadados?.album?.isNotEmpty == true
                    ? _metadados!.album!
                    : 'Áudio Soberano'));

        final temCapa = _metadados?.temCapa == true;

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: tocando
                    ? theme.buttonColor.withValues(alpha: 0.8)
                    : theme.borderColor.withValues(alpha: 0.6),
                width: tocando ? 1.6 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Imagem de fundo translúcida imersiva (se existir arte incorporada)
                if (temCapa)
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.14,
                      child: Image.memory(
                        _metadados!.capaBytes!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                // Conteúdo principal do player
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Linha de Capa e Identificação da Música
                      Row(
                        children: [
                          // Miniatura da Capa com Bordas Arredondadas
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color:
                                  theme.backgroundColor.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.borderColor.withValues(alpha: 0.4),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: temCapa
                                ? Image.memory(
                                    _metadados!.capaBytes!,
                                    fit: BoxFit.cover,
                                  )
                                : Icon(
                                    tocando
                                        ? Icons.graphic_eq_rounded
                                        : Icons.music_note_rounded,
                                    size: 32,
                                    color: tocando
                                        ? theme.buttonColor
                                        : theme.secondaryTextColor,
                                  ),
                          ),
                          const SizedBox(width: 14),
                          // Título e Artista
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (tocando) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        margin: const EdgeInsets.only(right: 6),
                                        decoration: BoxDecoration(
                                          color: theme.buttonColor
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'TOCANDO',
                                          style: theme.getTextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: theme.buttonColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                    Expanded(
                                      child: Text(
                                        tituloExibicao,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.getTextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: theme.textColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  subtituloExibicao,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.getTextStyle(
                                    fontSize: 12,
                                    color: theme.secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Botão de Loop / Repetir
                          IconButton(
                            tooltip: estado.loop
                                ? 'Repetição Ativada'
                                : 'Repetir Música',
                            icon: Icon(
                              Icons.repeat_rounded,
                              size: 20,
                              color: estado.loop
                                  ? theme.buttonColor
                                  : theme.secondaryTextColor
                                      .withValues(alpha: 0.6),
                            ),
                            onPressed: () => playerService.alternarLoop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Barra de Progresso Interativa (Seek Slider)
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 12,
                          ),
                          activeTrackColor: theme.buttonColor,
                          inactiveTrackColor:
                              theme.borderColor.withValues(alpha: 0.35),
                          thumbColor: theme.buttonColor,
                          overlayColor:
                              theme.buttonColor.withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          value: valorProgresso,
                          onChanged: (novoValor) {
                            if (!ehEsteArquivo) return;
                            final novoMs =
                                (novoValor * duracaoTotal.inMilliseconds)
                                    .round();
                            playerService
                                .buscarPosicao(Duration(milliseconds: novoMs));
                          },
                        ),
                      ),

                      // Contadores de Tempo
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatarTempo(posicaoAtual),
                              style: theme.getTextStyle(
                                fontSize: 11,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                            Text(
                              _formatarTempo(duracaoTotal),
                              style: theme.getTextStyle(
                                fontSize: 11,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Controles Principais e Controle de Volume
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Controle de Volume Deslizante
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                iconSize: 18,
                                tooltip: estado.volume > 0
                                    ? 'Silenciar'
                                    : 'Restaurar Volume',
                                icon: Icon(
                                  estado.volume == 0
                                      ? Icons.volume_off_rounded
                                      : (estado.volume < 0.5
                                          ? Icons.volume_down_rounded
                                          : Icons.volume_up_rounded),
                                  color: theme.secondaryTextColor,
                                ),
                                onPressed: () {
                                  if (estado.volume > 0) {
                                    _volumeAnterior = estado.volume;
                                    playerService.definirVolume(0.0);
                                  } else {
                                    playerService.definirVolume(_volumeAnterior > 0
                                        ? _volumeAnterior
                                        : 1.0);
                                  }
                                },
                              ),
                              SizedBox(
                                width: 75,
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 3,
                                    thumbShape:
                                        const RoundSliderThumbShape(
                                      enabledThumbRadius: 4,
                                    ),
                                    overlayShape:
                                        const RoundSliderOverlayShape(
                                      overlayRadius: 8,
                                    ),
                                    activeTrackColor: theme.textColor,
                                    inactiveTrackColor: theme.borderColor
                                        .withValues(alpha: 0.3),
                                    thumbColor: theme.textColor,
                                  ),
                                  child: Slider(
                                    value: estado.volume,
                                    onChanged: (vol) =>
                                        playerService.definirVolume(vol),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Controles Centrais: Anterior, -10s, Play/Pause, +10s, Próxima, Stop
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Faixa anterior',
                                icon: Icon(
                                  Icons.skip_previous_rounded,
                                  size: 22,
                                  color: widget.onAnterior != null
                                      ? theme.textColor
                                      : theme.secondaryTextColor
                                          .withValues(alpha: 0.3),
                                ),
                                onPressed: widget.onAnterior,
                              ),
                              IconButton(
                                tooltip: 'Voltar 10s',
                                icon: Icon(
                                  Icons.replay_10_rounded,
                                  size: 19,
                                  color: theme.textColor,
                                ),
                                onPressed: () =>
                                    playerService.retrocederSegundos(10),
                              ),
                              const SizedBox(width: 2),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.buttonColor,
                                  foregroundColor: theme.buttonTextColor,
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(12),
                                  elevation: 2,
                                ),
                                onPressed: () => playerService
                                    .alternarPlayPause(widget.caminho),
                                child: Icon(
                                  tocando
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 26,
                                  color: theme.buttonTextColor,
                                ),
                              ),
                              const SizedBox(width: 2),
                              IconButton(
                                tooltip: 'Avançar 10s',
                                icon: Icon(
                                  Icons.forward_10_rounded,
                                  size: 19,
                                  color: theme.textColor,
                                ),
                                onPressed: () =>
                                    playerService.avancarSegundos(10),
                              ),
                              IconButton(
                                tooltip: 'Próxima faixa',
                                icon: Icon(
                                  Icons.skip_next_rounded,
                                  size: 22,
                                  color: widget.onProximo != null
                                      ? theme.textColor
                                      : theme.secondaryTextColor
                                          .withValues(alpha: 0.3),
                                ),
                                onPressed: widget.onProximo,
                              ),
                              if (tocando || pausado) ...[
                                const SizedBox(width: 2),
                                IconButton(
                                  tooltip: 'Parar',
                                  icon: Icon(
                                    Icons.stop_rounded,
                                    size: 20,
                                    color: theme.secondaryTextColor,
                                  ),
                                  onPressed: () => playerService.parar(),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
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
