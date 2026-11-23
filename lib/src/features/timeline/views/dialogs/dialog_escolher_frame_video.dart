import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Diálogo para o usuário navegar pelos frames de um vídeo e capturar
/// exatamente a imagem que deseja usar como capa da publicação.
class DialogEscolherFrameVideo extends StatefulWidget {
  final AppTheme theme;
  final String caminhoVideo;
  final double aspectRatio;

  const DialogEscolherFrameVideo({
    super.key,
    required this.theme,
    required this.caminhoVideo,
    this.aspectRatio = 16 / 9,
  });

  static Future<Uint8List?> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required String caminhoVideo,
    double aspectRatio = 16 / 9,
  }) {
    return showDialog<Uint8List>(
      context: context,
      builder: (_) => DialogEscolherFrameVideo(
        theme: theme,
        caminhoVideo: caminhoVideo,
        aspectRatio: aspectRatio,
      ),
    );
  }

  @override
  State<DialogEscolherFrameVideo> createState() =>
      _DialogEscolherFrameVideoState();
}

class _DialogEscolherFrameVideoState extends State<DialogEscolherFrameVideo> {
  Player? _player;
  VideoController? _videoController;
  Duration _duracao = Duration.zero;
  Duration _posicao = Duration.zero;
  bool _carregando = true;
  bool _capturando = false;
  bool _arrastando = false;
  double _valorArraste = 0.0;
  final List<StreamSubscription<dynamic>> _subs = [];

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    try {
      try {
        MediaKit.ensureInitialized();
      } catch (_) {}
      final player = Player();
      final controller = VideoController(player);
      _subs.add(
        player.stream.duration.listen((d) {
          if (mounted) setState(() => _duracao = d);
        }),
      );
      _subs.add(
        player.stream.position.listen((p) {
          if (mounted && !_arrastando) setState(() => _posicao = p);
        }),
      );
      if (mounted) {
        setState(() {
          _player = player;
          _videoController = controller;
        });
      }
      await player.setVolume(0);
      await player.open(Media(widget.caminhoVideo), play: true);
      try {
        await player.stream.width
            .firstWhere((w) => w != null && w > 0)
            .timeout(const Duration(seconds: 3));
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 220));
      await player.pause();
      if (mounted) setState(() => _carregando = false);
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player?.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final t = d.inSeconds;
    final m = (t ~/ 60).toString().padLeft(2, '0');
    final s = (t % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _capturarFrame() async {
    if (_capturando || _player == null) return;
    setState(() => _capturando = true);
    try {
      final bytes = await _player!
          .screenshot(format: 'image/jpeg')
          .timeout(const Duration(seconds: 3));
      if (mounted) {
        Navigator.of(context).pop(bytes);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _capturando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final maxMs =
        _duracao.inMilliseconds > 0 ? _duracao.inMilliseconds.toDouble() : 1.0;
    final posMs = (_arrastando ? _valorArraste : _posicao.inMilliseconds.toDouble())
        .clamp(0.0, maxMs);

    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(
                      'Escolher Frame de Capa',
                      style: theme.getTextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.close_rounded,
                        color: theme.secondaryTextColor,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Flexible(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 340),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: widget.aspectRatio,
                        child: Container(
                          color: theme.backgroundColor,
                          child: _videoController == null
                              ? Center(
                                  child: CircularProgressIndicator(
                                    color: theme.buttonColor,
                                  ),
                                )
                              : Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Video(
                                      controller: _videoController!,
                                      controls: NoVideoControls,
                                    ),
                                    if (_carregando)
                                      Center(
                                        child: CircularProgressIndicator(
                                          color: theme.buttonColor,
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 7,
                  ),
                ),
                child: Slider(
                  value: posMs,
                  min: 0,
                  max: maxMs,
                  activeColor: theme.buttonColor,
                  inactiveColor: theme.borderColor.withValues(alpha: 0.4),
                  onChangeStart: (v) {
                    setState(() {
                      _arrastando = true;
                      _valorArraste = v;
                    });
                  },
                  onChanged: (v) {
                    setState(() => _valorArraste = v);
                  },
                  onChangeEnd: (v) async {
                    final alvo = Duration(milliseconds: v.round());
                    await _player?.seek(alvo);
                    await Future.delayed(const Duration(milliseconds: 120));
                    if (mounted) {
                      setState(() {
                        _posicao = alvo;
                        _arrastando = false;
                      });
                    }
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Deslize a barra para escolher o frame',
                    style: theme.getTextStyle(
                      fontSize: 11.5,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  Text(
                    '${_fmt(Duration(milliseconds: posMs.round()))} / ${_fmt(_duracao)}',
                    style: theme.getTextStyle(
                      fontSize: 11.5,
                      color: theme.textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.buttonColor,
                  foregroundColor: theme.buttonTextColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: (_carregando || _capturando) ? null : _capturarFrame,
                icon: _capturando
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.buttonTextColor,
                        ),
                      )
                    : const Icon(Icons.camera_alt_outlined, size: 18),
                label: Text(
                  _capturando ? 'Capturando...' : 'Usar este frame como capa',
                  style: theme.getTextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: theme.buttonTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
