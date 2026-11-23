import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:nous/src/core/services/player_audio_service.dart';
import 'package:nous/src/core/widgets/player_video_nous_widget.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';

/// Controlador singleton do Player Universal do Nous.
/// Centraliza a fila de reprodução de músicas e vídeos da rede social,
/// sincronizando estado com `PlayerAudioService.instancia` e mantendo
/// persistência do mini-player entre telas.
class PlayerUniversalController extends ChangeNotifier {
  PlayerUniversalController._() {
    _audioService.estadoNotifier.addListener(_aoMudarEstadoAudio);
    _subComplete = _audioService.onPlayerComplete.listen((_) {
      if (!_repetir && atual != null && !_modoVideo) {
        proxima(automatico: true);
      }
    });
  }

  static final PlayerUniversalController instancia =
      PlayerUniversalController._();

  final PlayerAudioService _audioService = PlayerAudioService.instancia;
  StreamSubscription<void>? _subComplete;

  List<PublicacaoSocial> _fila = [];
  int _indiceAtual = -1;
  bool _aleatorio = false;
  bool _repetir = false;
  bool _modoVideo = false;
  bool _visivel = false;

  List<PublicacaoSocial> get fila => List.unmodifiable(_fila);
  int get indiceAtual => _indiceAtual;
  PublicacaoSocial? get atual =>
      (_indiceAtual >= 0 && _indiceAtual < _fila.length)
          ? _fila[_indiceAtual]
          : null;
  bool get aleatorio => _aleatorio;
  bool get repetir => _repetir;
  bool get modoVideo => _modoVideo;
  bool get visivel => _visivel && atual != null;

  DadosPlayerAudio get estadoAudio => _audioService.estadoAtual;
  bool get estaTocando =>
      !_modoVideo && estadoAudio.estado == EstadoPlayerAudio.reproduzindo;

  void _aoMudarEstadoAudio() {
    notifyListeners();
  }

  /// Verifica se uma publicação possui mídia de vídeo.
  static bool possuiVideo(PublicacaoSocial pub) {
    if (pub.tipo == TipoFeedSocial.videos) return true;
    return pub.midias.any(_ehMidiaVideo);
  }

  /// Verifica se uma publicação possui mídia de áudio.
  static bool possuiAudio(PublicacaoSocial pub) {
    if (pub.tipo == TipoFeedSocial.musicas) return true;
    return pub.midias.any(_ehMidiaAudio);
  }

  static bool _ehMidiaVideo(MidiaPublicacao m) {
    final mime = m.mimeTipo.toLowerCase();
    final path = m.caminhoRelativo.toLowerCase();
    return mime.startsWith('video/') ||
        path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.mkv') ||
        path.endsWith('.webm') ||
        path.endsWith('.avi');
  }

  static bool _ehMidiaAudio(MidiaPublicacao m) {
    final mime = m.mimeTipo.toLowerCase();
    final path = m.caminhoRelativo.toLowerCase();
    return mime.startsWith('audio/') ||
        path.endsWith('.mp3') ||
        path.endsWith('.wav') ||
        path.endsWith('.aac') ||
        path.endsWith('.m4a') ||
        path.endsWith('.ogg') ||
        path.endsWith('.flac');
  }

  /// Retorna o caminho da mídia principal (vídeo/áudio/pdf) da publicação.
  static String obterCaminhoMidiaPrincipal(
    PublicacaoSocial pub, {
    bool preferirVideo = false,
  }) {
    if (pub.midias.isEmpty) return '';
    if (preferirVideo) {
      final v = pub.midias.where(_ehMidiaVideo).firstOrNull;
      if (v != null) return v.caminhoRelativo;
    }
    final a = pub.midias.where(_ehMidiaAudio).firstOrNull;
    if (a != null) return a.caminhoRelativo;
    final v = pub.midias.where(_ehMidiaVideo).firstOrNull;
    if (v != null) return v.caminhoRelativo;
    return pub.midias.first.caminhoRelativo;
  }

  /// Título amigável para exibição no player e nas grades.
  static String obterTitulo(PublicacaoSocial pub) {
    final textoLimpo = pub.texto.trim();
    if (textoLimpo.isNotEmpty) {
      final primeiraLinha = textoLimpo.split('\n').first.trim();
      if (primeiraLinha.isNotEmpty) return primeiraLinha;
    }
    if (pub.midias.isNotEmpty) {
      final nome = pub.midias.first.nomeArquivo.trim();
      if (nome.isNotEmpty) {
        final ponto = nome.lastIndexOf('.');
        return ponto > 0 ? nome.substring(0, ponto) : nome;
      }
    }
    return pub.autorNome.isNotEmpty ? pub.autorNome : 'Mídia sem título';
  }

  /// Inicia ou seleciona uma publicação no Player Universal.
  Future<void> tocarPublicacao(
    PublicacaoSocial pub, {
    List<PublicacaoSocial>? novaFila,
    bool? iniciarComoVideo,
  }) async {
    if (novaFila != null && novaFila.isNotEmpty) {
      _fila = List<PublicacaoSocial>.from(novaFila);
    } else if (!_fila.any((p) => p.id == pub.id)) {
      _fila = [pub, ..._fila];
    }

    final idx = _fila.indexWhere((p) => p.id == pub.id);
    _indiceAtual = idx >= 0 ? idx : 0;
    _visivel = true;

    final deveSerVideo =
        iniciarComoVideo ?? (pub.tipo == TipoFeedSocial.videos && !possuiAudio(pub));
    _modoVideo = deveSerVideo && possuiVideo(pub);
    notifyListeners();

    await _reproduzirAtual();
  }

  Future<void> _reproduzirAtual() async {
    final pub = atual;
    if (pub == null) return;

    if (_modoVideo) {
      await _audioService.parar();
      return;
    }

    await PlayerVideoNousWidget.pausarTodos();
    final caminho = obterCaminhoMidiaPrincipal(pub);
    if (caminho.isNotEmpty) {
      await _audioService.tocar(caminho);
    }
  }

  Future<void> alternarPlayPause() async {
    final pub = atual;
    if (pub == null || _modoVideo) return;
    final caminho = obterCaminhoMidiaPrincipal(pub);
    if (caminho.isEmpty) return;
    await _audioService.alternarPlayPause(caminho);
  }

  Future<void> proxima({bool automatico = false}) async {
    if (_fila.isEmpty) return;
    if (_aleatorio && _fila.length > 1) {
      final rng = Random();
      var novo = rng.nextInt(_fila.length);
      if (novo == _indiceAtual) {
        novo = (_indiceAtual + 1) % _fila.length;
      }
      _indiceAtual = novo;
    } else {
      if (_indiceAtual + 1 < _fila.length) {
        _indiceAtual++;
      } else if (!automatico || _repetir) {
        _indiceAtual = 0;
      } else {
        return;
      }
    }
    final pub = atual;
    if (pub != null && !possuiVideo(pub)) {
      _modoVideo = false;
    }
    notifyListeners();
    await _reproduzirAtual();
  }

  Future<void> anterior() async {
    if (_fila.isEmpty) return;
    if (!_modoVideo && estadoAudio.posicao.inSeconds > 4) {
      await _audioService.buscarPosicao(Duration.zero);
      return;
    }
    if (_indiceAtual - 1 >= 0) {
      _indiceAtual--;
    } else {
      _indiceAtual = _fila.length - 1;
    }
    final pub = atual;
    if (pub != null && !possuiVideo(pub)) {
      _modoVideo = false;
    }
    notifyListeners();
    await _reproduzirAtual();
  }

  void alternarAleatorio() {
    _aleatorio = !_aleatorio;
    notifyListeners();
  }

  void alternarRepetir() {
    _repetir = !_repetir;
    if (_audioService.estadoAtual.loop != _repetir) {
      _audioService.alternarLoop();
    }
    notifyListeners();
  }

  Future<void> definirModoVideo(bool ehVideo) async {
    final pub = atual;
    if (pub == null) return;
    if (ehVideo && !possuiVideo(pub)) return;
    if (!ehVideo && !possuiAudio(pub)) return;
    if (_modoVideo == ehVideo) return;
    _modoVideo = ehVideo;
    notifyListeners();
    await _reproduzirAtual();
  }

  Future<void> buscarPosicao(Duration pos) async {
    if (_modoVideo) return;
    await _audioService.buscarPosicao(pos);
  }

  Future<void> fecharMiniPlayer() async {
    _visivel = false;
    await _audioService.parar();
    notifyListeners();
  }

  @override
  void dispose() {
    _subComplete?.cancel();
    _audioService.estadoNotifier.removeListener(_aoMudarEstadoAudio);
    super.dispose();
  }
}
