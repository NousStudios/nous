import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/timeline/services/timeline_midia_service.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';

class _EstadoCompartilhadoVideo {
  Duration posicao = Duration.zero;
  bool estavaTocando = false;
  final List<_PlayerVideoNousWidgetState> pilhaInstancias = [];
}

/// Módulo de Player de Vídeo interno do Nous (base do Player Universal).
/// Reproduz vídeos localmente (ou via streaming HTTP) no Windows e Android,
/// com continuidade de posição entre Feed e Janela de Comentários, e controle
/// vertical de volume no hover.
class PlayerVideoNousWidget extends StatefulWidget {
  final AppTheme theme;
  final String caminhoVideo;
  final String caminhoCapa;
  final double aspectRatio;
  final bool autoPlay;
  final String titulo;
  final VoidCallback? onIniciarReproducao;

  const PlayerVideoNousWidget({
    super.key,
    required this.theme,
    required this.caminhoVideo,
    this.caminhoCapa = '',
    this.aspectRatio = 16 / 9,
    this.autoPlay = false,
    this.titulo = '',
    this.onIniciarReproducao,
  });

  /// Pausa todas as instâncias ativas de vídeo (ex.: ao abrir seletores de arquivo).
  static Future<void> pausarTodos() async {
    for (final estado in _PlayerVideoNousWidgetState._estadosGlobais.values) {
      for (final inst in estado.pilhaInstancias) {
        if (inst._playerAtivo && inst._player != null && inst._tocando) {
          try {
            await inst._player!.pause();
          } catch (_) {}
        }
      }
    }
  }

  /// Retorna (ou gera em cache) a miniatura do primeiro frame de um vídeo local
  /// para exibição em grades/galerias quando não houver capa explícita salva.
  static Future<Uint8List?> obterOuGerarCapaVideo(
    String caminhoRelativoOuAbsoluto,
  ) async {
    if (caminhoRelativoOuAbsoluto.isEmpty) return null;
    final chaveDisco = 'video_$caminhoRelativoOuAbsoluto';
    final emDisco = await TimelineMidiaService.lerThumbnailDisco(chaveDisco);
    if (emDisco != null) return emDisco;

    final caminho =
        TimelineService.resolverCaminhoMidiaSync(caminhoRelativoOuAbsoluto) ??
        await TimelineService.resolverCaminhoMidia(caminhoRelativoOuAbsoluto);
    if (caminho == null || caminho.isEmpty) return null;
    final existente = _PlayerVideoNousWidgetState._cacheCapasFallback[caminho];
    if (existente != null) return existente;
    if (_PlayerVideoNousWidgetState._capturandoCapaFallback.contains(caminho)) {
      return null;
    }
    if (!File(caminho).existsSync()) return null;

    _PlayerVideoNousWidgetState._capturandoCapaFallback.add(caminho);
    Player? temp;
    try {
      try {
        MediaKit.ensureInitialized();
      } catch (_) {}
      temp = Player();
      VideoController(temp);
      await temp.setVolume(0);
      await temp.open(Media(caminho), play: true).timeout(
            const Duration(seconds: 4),
          );
      await temp.stream.width
          .firstWhere((w) => w != null && w > 0)
          .timeout(const Duration(seconds: 3));
      await Future.delayed(const Duration(milliseconds: 220));
      await temp.pause();
      final bytes = await temp
          .screenshot(format: 'image/jpeg')
          .timeout(const Duration(seconds: 3));
      if (bytes != null && bytes.isNotEmpty) {
        _PlayerVideoNousWidgetState._cacheCapasFallback[caminho] = bytes;
        await TimelineMidiaService.salvarThumbnailDisco(chaveDisco, bytes);
        return bytes;
      }
    } catch (_) {
    } finally {
      _PlayerVideoNousWidgetState._capturandoCapaFallback.remove(caminho);
      try {
        await temp?.dispose();
      } catch (_) {}
    }
    return null;
  }

  @override
  State<PlayerVideoNousWidget> createState() => _PlayerVideoNousWidgetState();
}

class _PlayerVideoNousWidgetState extends State<PlayerVideoNousWidget> {
  static final Map<String, _EstadoCompartilhadoVideo> _estadosGlobais = {};
  static final Map<String, Uint8List> _cacheCapasFallback = {};
  static final Set<String> _capturandoCapaFallback = {};

  Player? _player;
  VideoController? _videoController;
  bool _playerAtivo = false;
  bool _tocando = false;
  double _volume = 100.0;
  double _ultimoVolumeAtivo = 100.0;
  bool _mostrarControles = true;
  bool _mostrarControleVolume = false;
  bool _arrastandoSlider = false;
  double _valorSliderArraste = 0.0;
  bool _avancando2x = false;
  bool _voltando2x = false;
  bool _estavaTocandoAntesRetrocesso = false;
  bool _buscandoRetrocesso = false;
  Duration _alvoRetrocesso = Duration.zero;
  Timer? _timerRetrocesso;
  Duration _posicao = Duration.zero;
  Duration _duracao = Duration.zero;
  final List<StreamSubscription<dynamic>> _subs = [];
  String? _capaResolvida;

  String get _chaveVideo => widget.caminhoVideo.trim();

  @override
  void initState() {
    super.initState();
    _resolverCapa();
    final estado = _estadosGlobais.putIfAbsent(
      _chaveVideo,
      () => _EstadoCompartilhadoVideo(),
    );
    estado.pilhaInstancias.add(this);

    if (widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _iniciarPlayer(retomarDoCompartilhado: true);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant PlayerVideoNousWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.caminhoCapa != widget.caminhoCapa) {
      _resolverCapa();
    }
    if (oldWidget.caminhoVideo != widget.caminhoVideo) {
      _estadosGlobais[oldWidget.caminhoVideo.trim()]?.pilhaInstancias.remove(
        this,
      );
      _estadosGlobais
          .putIfAbsent(_chaveVideo, () => _EstadoCompartilhadoVideo())
          .pilhaInstancias
          .add(this);
      if (_playerAtivo) {
        _player?.open(Media(widget.caminhoVideo));
      }
    }
  }

  Future<void> _resolverCapa() async {
    if (widget.caminhoCapa.isEmpty) {
      if (mounted) setState(() => _capaResolvida = null);
      unawaited(_garantirCapaFallback());
      return;
    }
    final sync = TimelineService.resolverCaminhoMidiaSync(widget.caminhoCapa);
    if (sync != null) {
      if (mounted) setState(() => _capaResolvida = sync);
      return;
    }
    final asyncPath =
        await TimelineService.resolverCaminhoMidia(widget.caminhoCapa);
    if (mounted) setState(() => _capaResolvida = asyncPath);
    if (asyncPath == null) {
      unawaited(_garantirCapaFallback());
    }
  }

  Future<void> _garantirCapaFallback() async {
    final caminho = widget.caminhoVideo;
    if (caminho.isEmpty ||
        _cacheCapasFallback.containsKey(caminho) ||
        _capturandoCapaFallback.contains(caminho)) {
      return;
    }
    if (!File(caminho).existsSync()) return;
    _capturandoCapaFallback.add(caminho);
    Player? temp;
    try {
      try {
        MediaKit.ensureInitialized();
      } catch (_) {}
      temp = Player();
      VideoController(temp);
      await temp.setVolume(0);
      await temp.open(Media(caminho), play: true).timeout(
            const Duration(seconds: 4),
          );
      await temp.stream.width
          .firstWhere((w) => w != null && w > 0)
          .timeout(const Duration(seconds: 3));
      await Future.delayed(const Duration(milliseconds: 220));
      await temp.pause();
      final bytes = await temp
          .screenshot(format: 'image/jpeg')
          .timeout(const Duration(seconds: 3));
      if (bytes != null && bytes.isNotEmpty) {
        _cacheCapasFallback[caminho] = bytes;
        if (mounted) setState(() {});
      }
    } catch (_) {
    } finally {
      _capturandoCapaFallback.remove(caminho);
      try {
        await temp?.dispose();
      } catch (_) {}
    }
  }

  Future<void> _pausarInstanciasAnteriores() async {
    final estado = _estadosGlobais[_chaveVideo];
    if (estado == null) return;
    for (final inst in estado.pilhaInstancias) {
      if (inst != this && inst._playerAtivo && inst._player != null) {
        estado.posicao = inst._posicao;
        estado.estavaTocando = inst._tocando;
        if (inst._tocando) {
          await inst._player!.pause();
        }
      }
    }
  }

  Future<void> _retomarSincronizado(Duration pos, bool tocar) async {
    if (!mounted) return;
    if (!_playerAtivo) {
      if (pos > Duration.zero || tocar) {
        await _iniciarPlayer(
          posicaoInicial: pos,
          tocarAoAbrir: tocar,
        );
      }
      return;
    }
    if (_player != null) {
      await _player!.seek(pos);
      if (mounted) setState(() => _posicao = pos);
      if (tocar) {
        await _player!.play();
      } else {
        await _player!.pause();
      }
    }
  }

  Future<void> _iniciarPlayer({
    bool retomarDoCompartilhado = false,
    Duration? posicaoInicial,
    bool? tocarAoAbrir,
  }) async {
    if (_playerAtivo) return;
    try {
      await _pausarInstanciasAnteriores();

      final estado = _estadosGlobais[_chaveVideo];
      final posAlvo =
          posicaoInicial ??
          (retomarDoCompartilhado ? (estado?.posicao ?? Duration.zero) : Duration.zero);
      final deveTocar =
          tocarAoAbrir ?? (retomarDoCompartilhado ? true : true);

      try {
        MediaKit.ensureInitialized();
      } catch (_) {}

      final player = Player();
      final controller = VideoController(player);

      _subs.add(
        player.stream.playing.listen((v) {
          if (mounted) setState(() => _tocando = v);
          final est = _estadosGlobais[_chaveVideo];
          if (est != null && est.pilhaInstancias.lastOrNull == this) {
            est.estavaTocando = v;
          }
        }),
      );
      _subs.add(
        player.stream.position.listen((v) {
          if (mounted && !_arrastandoSlider) {
            setState(() => _posicao = v);
          }
          final est = _estadosGlobais[_chaveVideo];
          if (est != null && est.pilhaInstancias.lastOrNull == this) {
            est.posicao = v;
          }
        }),
      );
      _subs.add(
        player.stream.duration.listen((v) {
          if (mounted) setState(() => _duracao = v);
        }),
      );
      _subs.add(
        player.stream.completed.listen((fim) {
          if (fim && mounted) {
            setState(() => _mostrarControles = true);
          }
        }),
      );

      setState(() {
        _player = player;
        _videoController = controller;
        _playerAtivo = true;
      });
      widget.onIniciarReproducao?.call();

      await player.open(Media(widget.caminhoVideo), play: deveTocar);
      if (posAlvo > Duration.zero) {
        try {
          await player.stream.duration
              .firstWhere((d) => d > Duration.zero)
              .timeout(const Duration(seconds: 2));
        } catch (_) {}
        await player.seek(posAlvo);
        if (mounted) setState(() => _posicao = posAlvo);
      }
    } catch (e) {
      debugPrint('[PlayerVideoNousWidget] Erro ao iniciar vídeo: $e');
    }
  }

  @override
  void dispose() {
    final estado = _estadosGlobais[_chaveVideo];
    final eraTopo = estado != null && estado.pilhaInstancias.lastOrNull == this;
    final posFinal = _posicao;
    final estavaTocandoFinal = _tocando;
    estado?.pilhaInstancias.remove(this);

    if (eraTopo && estado.pilhaInstancias.isNotEmpty && _playerAtivo) {
      estado.posicao = posFinal;
      estado.estavaTocando = estavaTocandoFinal;
      final anterior = estado.pilhaInstancias.last;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        anterior._retomarSincronizado(posFinal, estavaTocandoFinal);
      });
    }

    if (estado != null && estado.pilhaInstancias.isEmpty) {
      _estadosGlobais.remove(_chaveVideo);
    }

    _timerRetrocesso?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    _player?.dispose();
    super.dispose();
  }

  void _iniciarAvanco2x() {
    if (!_playerAtivo || _player == null) return;
    _player!.setRate(2.0);
    if (!_tocando) _player!.play();
    setState(() => _avancando2x = true);
  }

  void _pararAvanco2x() {
    if (!_avancando2x) return;
    _player?.setRate(1.0);
    if (mounted) setState(() => _avancando2x = false);
  }

  void _iniciarRetrocesso2x() {
    if (!_playerAtivo || _player == null) return;
    _timerRetrocesso?.cancel();
    _estavaTocandoAntesRetrocesso = _tocando;
    _alvoRetrocesso = _posicao;
    _buscandoRetrocesso = false;
    _player!.pause();
    setState(() => _voltando2x = true);
    _timerRetrocesso = Timer.periodic(const Duration(milliseconds: 220), (_) async {
      if (!mounted || _player == null || !_voltando2x || _buscandoRetrocesso) {
        return;
      }
      _buscandoRetrocesso = true;
      try {
        final limiteMax = _duracao.inMilliseconds > 0
            ? _duracao.inMilliseconds
            : _alvoRetrocesso.inMilliseconds;
        final novoMs = (_alvoRetrocesso.inMilliseconds - 440).clamp(0, limiteMax);
        final alvo = Duration(milliseconds: novoMs);
        _alvoRetrocesso = alvo;
        if (mounted) setState(() => _posicao = alvo);
        await _player!.seek(alvo);
      } catch (_) {
      } finally {
        _buscandoRetrocesso = false;
      }
    });
  }

  void _pararRetrocesso2x() {
    _timerRetrocesso?.cancel();
    _timerRetrocesso = null;
    _buscandoRetrocesso = false;
    if (!_voltando2x) return;
    if (_estavaTocandoAntesRetrocesso) {
      _player?.play();
    }
    if (mounted) setState(() => _voltando2x = false);
  }

  String _fmt(Duration d) {
    final total = d.inSeconds;
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _aplicarVolume(double novoVol) {
    final v = novoVol.clamp(0.0, 100.0);
    if (v > 0) _ultimoVolumeAtivo = v;
    _player?.setVolume(v);
    setState(() => _volume = v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final maxMs = _duracao.inMilliseconds > 0
        ? _duracao.inMilliseconds.toDouble()
        : 1.0;
    final posMs = _arrastandoSlider
        ? _valorSliderArraste.clamp(0.0, maxMs)
        : _posicao.inMilliseconds.toDouble().clamp(0.0, maxMs);
    final posicaoExibida = _arrastandoSlider
        ? Duration(milliseconds: posMs.round())
        : _posicao;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth,
              maxHeight: constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : double.infinity,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: widget.aspectRatio,
                child: Container(
          color: theme.backgroundColor.withValues(alpha: 0.75),
          child: !_playerAtivo || _videoController == null
              ? GestureDetector(
                  onTap: () => _iniciarPlayer(),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_capaResolvida != null &&
                          File(_capaResolvida!).existsSync())
                        Image.file(
                          File(_capaResolvida!),
                          fit: BoxFit.cover,
                          cacheWidth: 1080,
                        )
                      else if (_cacheCapasFallback[widget.caminhoVideo] != null)
                        Image.memory(
                          _cacheCapasFallback[widget.caminhoVideo]!,
                          fit: BoxFit.cover,
                          cacheWidth: 1080,
                        )
                      else
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.videocam_outlined,
                              size: 40,
                              color: theme.secondaryTextColor,
                            ),
                            if (widget.titulo.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  widget.titulo,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.getTextStyle(
                                    fontSize: 12,
                                    color: theme.secondaryTextColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      Center(
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: theme.cardBackgroundColor
                                .withValues(alpha: 0.80),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.textColor.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            size: 32,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : GestureDetector(
                  onTap: () {
                    if (_mostrarControleVolume) {
                      setState(() => _mostrarControleVolume = false);
                      return;
                    }
                    _player?.playOrPause();
                    setState(() => _mostrarControles = true);
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Video(
                        controller: _videoController!,
                        controls: NoVideoControls,
                      ),
                      // Quadrantes superiores: segurar esquerda volta 2x, direita avança 2x
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 72,
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onLongPressStart: (_) =>
                                    _iniciarRetrocesso2x(),
                                onLongPressEnd: (_) => _pararRetrocesso2x(),
                                onLongPressCancel: _pararRetrocesso2x,
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onLongPressStart: (_) => _iniciarAvanco2x(),
                                onLongPressEnd: (_) => _pararAvanco2x(),
                                onLongPressCancel: _pararAvanco2x,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_voltando2x || _avancando2x)
                        Positioned(
                          top: 12,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: theme.cardBackgroundColor
                                    .withValues(alpha: 0.88),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _voltando2x ? '<< 2x' : '2x >>',
                                style: theme.getTextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_mostrarControles)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  theme.cardBackgroundColor
                                      .withValues(alpha: 0.92),
                                ],
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 4.0,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 7.0,
                                    ),
                                    overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 14,
                                    ),
                                  ),
                                  child: Slider(
                                    value: posMs,
                                    min: 0.0,
                                    max: maxMs,
                                    activeColor: theme.textColor,
                                    inactiveColor: theme.borderColor
                                        .withValues(alpha: 0.45),
                                    onChangeStart: (v) {
                                      setState(() {
                                        _arrastandoSlider = true;
                                        _valorSliderArraste = v;
                                      });
                                    },
                                    onChanged: (v) {
                                      setState(() {
                                        _valorSliderArraste = v;
                                      });
                                    },
                                    onChangeEnd: (v) async {
                                      final alvo = Duration(
                                        milliseconds: v.round(),
                                      );
                                      await _player?.seek(alvo);
                                      if (mounted) {
                                        setState(() {
                                          _posicao = alvo;
                                          _arrastandoSlider = false;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                Row(
                                  children: [
                                    InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: () => _player?.playOrPause(),
                                      child: Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Icon(
                                          _tocando
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          size: 22,
                                          color: theme.textColor,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${_fmt(posicaoExibida)} / ${_fmt(_duracao)}',
                                      style: theme.getTextStyle(
                                        fontSize: 11.5,
                                        color: theme.textColor,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    MouseRegion(
                                      onEnter: (_) => setState(
                                        () => _mostrarControleVolume = true,
                                      ),
                                      onExit: (_) => setState(
                                        () => _mostrarControleVolume = false,
                                      ),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(14),
                                        onTap: () => setState(
                                          () => _mostrarControleVolume =
                                              !_mostrarControleVolume,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(6),
                                          child: Icon(
                                            _volume <= 0
                                                ? Icons.volume_off_rounded
                                                : Icons.volume_up_rounded,
                                            size: 20,
                                            color: theme.textColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_mostrarControles && _mostrarControleVolume)
                        Positioned(
                          right: 6,
                          bottom: 42,
                          child: MouseRegion(
                            onEnter: (_) => setState(
                              () => _mostrarControleVolume = true,
                            ),
                            onExit: (_) => setState(
                              () => _mostrarControleVolume = false,
                            ),
                            child: Container(
                              width: 40,
                              height: 152,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.cardBackgroundColor
                                    .withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: theme.borderColor
                                      .withValues(alpha: 0.55),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: RotatedBox(
                                      quarterTurns: 3,
                                      child: SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 3.5,
                                          thumbShape:
                                              const RoundSliderThumbShape(
                                            enabledThumbRadius: 7.0,
                                          ),
                                          overlayShape:
                                              const RoundSliderOverlayShape(
                                            overlayRadius: 14,
                                          ),
                                        ),
                                        child: Slider(
                                          value: _volume,
                                          min: 0.0,
                                          max: 100.0,
                                          activeColor: theme.textColor,
                                          inactiveColor: theme.borderColor
                                              .withValues(alpha: 0.45),
                                          onChanged: _aplicarVolume,
                                        ),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      if (_volume > 0) {
                                        _aplicarVolume(0.0);
                                      } else {
                                        _aplicarVolume(
                                          _ultimoVolumeAtivo > 0
                                              ? _ultimoVolumeAtivo
                                              : 100.0,
                                        );
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        _volume <= 0
                                            ? Icons.volume_off_rounded
                                            : Icons.volume_up_rounded,
                                        size: 16,
                                        color: theme.textColor,
                                      ),
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
              ),
            ),
          ),
        ),
      );
      },
    );
  }
}
