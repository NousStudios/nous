import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:nous/src/core/services/metadados_audio_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';

enum EstadoPlayerAudio { parado, reproduzindo, pausado }

class DadosPlayerAudio {
  final EstadoPlayerAudio estado;
  final String? caminho;
  final Duration posicao;
  final Duration duracaoEstimada;
  final double volume;
  final bool loop;
  final MetadadosAudio? metadados;

  const DadosPlayerAudio({
    this.estado = EstadoPlayerAudio.parado,
    this.caminho,
    this.posicao = Duration.zero,
    this.duracaoEstimada = Duration.zero,
    this.volume = 1.0,
    this.loop = false,
    this.metadados,
  });

  DadosPlayerAudio copyWith({
    EstadoPlayerAudio? estado,
    String? caminho,
    Duration? posicao,
    Duration? duracaoEstimada,
    double? volume,
    bool? loop,
    MetadadosAudio? metadados,
  }) {
    return DadosPlayerAudio(
      estado: estado ?? this.estado,
      caminho: caminho ?? this.caminho,
      posicao: posicao ?? this.posicao,
      duracaoEstimada: duracaoEstimada ?? this.duracaoEstimada,
      volume: volume ?? this.volume,
      loop: loop ?? this.loop,
      metadados: metadados ?? this.metadados,
    );
  }
}

class PlayerAudioService {
  PlayerAudioService._() {
    _inicializarListeners();
  }

  static final PlayerAudioService instancia = PlayerAudioService._();

  final AudioPlayer _player = AudioPlayer();

  final ValueNotifier<DadosPlayerAudio> estadoNotifier =
      ValueNotifier<DadosPlayerAudio>(const DadosPlayerAudio());

  DadosPlayerAudio get estadoAtual => estadoNotifier.value;

  Stream<void> get onPlayerComplete => _player.onPlayerComplete;

  void _inicializarListeners() {
    _player.onPositionChanged.listen((pos) {
      if (estadoAtual.estado == EstadoPlayerAudio.reproduzindo) {
        estadoNotifier.value = estadoAtual.copyWith(posicao: pos);
      }
    });

    _player.onDurationChanged.listen((dur) {
      if (dur > Duration.zero) {
        estadoNotifier.value = estadoAtual.copyWith(duracaoEstimada: dur);
      }
    });

    _player.onPlayerStateChanged.listen((state) {
      switch (state) {
        case PlayerState.playing:
          if (estadoAtual.estado != EstadoPlayerAudio.reproduzindo) {
            estadoNotifier.value =
                estadoAtual.copyWith(estado: EstadoPlayerAudio.reproduzindo);
          }
          break;
        case PlayerState.paused:
          if (estadoAtual.estado != EstadoPlayerAudio.pausado) {
            estadoNotifier.value =
                estadoAtual.copyWith(estado: EstadoPlayerAudio.pausado);
          }
          break;
        case PlayerState.stopped:
        case PlayerState.completed:
          if (estadoAtual.loop) {
            _player.seek(Duration.zero);
            _player.resume();
          } else {
            estadoNotifier.value = estadoAtual.copyWith(
              estado: EstadoPlayerAudio.parado,
              posicao: Duration.zero,
            );
          }
          break;
        case PlayerState.disposed:
          break;
      }
    });

    _player.onPlayerComplete.listen((_) {
      if (estadoAtual.loop) {
        _player.seek(Duration.zero);
        _player.resume();
      } else {
        estadoNotifier.value = estadoAtual.copyWith(
          estado: EstadoPlayerAudio.parado,
          posicao: Duration.zero,
        );
      }
    });
  }

  Future<void> tocar(String caminho) async {
    var caminhoFinal = caminho;
    var arquivo = File(caminhoFinal);
    if (!arquivo.existsSync()) {
      if (ClienteRedeLocal().conectado) {
        caminhoFinal = await ClienteRedeLocal().baixarAudioRemoto(caminho);
        arquivo = File(caminhoFinal);
      }
    }
    if (!arquivo.existsSync()) return;

    final metadados = MetadadosAudioService.extrair(caminhoFinal);

    estadoNotifier.value = estadoAtual.copyWith(
      caminho: caminhoFinal,
      posicao: Duration.zero,
      duracaoEstimada: _estimarDuracao(arquivo),
      metadados: metadados,
      estado: EstadoPlayerAudio.reproduzindo,
    );

    try {
      await _player.stop();
      await _player.setReleaseMode(
        estadoAtual.loop ? ReleaseMode.loop : ReleaseMode.release,
      );
      await _player.setVolume(estadoAtual.volume);
      await _player.play(DeviceFileSource(caminhoFinal));
    } catch (_) {
      // Fallback seguro caso ocorra erro no driver nativo
    }
  }

  Future<void> pausar() async {
    try {
      await _player.pause();
    } catch (_) {}
    estadoNotifier.value = estadoAtual.copyWith(
      estado: EstadoPlayerAudio.pausado,
    );
  }

  Future<void> retomar() async {
    if (estadoAtual.caminho == null) return;
    try {
      await _player.resume();
    } catch (_) {
      await tocar(estadoAtual.caminho!);
    }
    estadoNotifier.value = estadoAtual.copyWith(
      estado: EstadoPlayerAudio.reproduzindo,
    );
  }

  Future<void> alternarPlayPause(String caminho) async {
    if (estadoAtual.caminho == caminho &&
        estadoAtual.estado == EstadoPlayerAudio.reproduzindo) {
      await pausar();
    } else if (estadoAtual.caminho == caminho &&
        estadoAtual.estado == EstadoPlayerAudio.pausado) {
      await retomar();
    } else {
      await tocar(caminho);
    }
  }

  Future<void> parar() async {
    try {
      await _player.stop();
    } catch (_) {}
    estadoNotifier.value = estadoAtual.copyWith(
      estado: EstadoPlayerAudio.parado,
      posicao: Duration.zero,
    );
  }

  Future<void> buscarPosicao(Duration posicao) async {
    try {
      await _player.seek(posicao);
    } catch (_) {}
    estadoNotifier.value = estadoAtual.copyWith(posicao: posicao);
  }

  Future<void> avancarSegundos(int segundos) async {
    final novaPos = estadoAtual.posicao + Duration(seconds: segundos);
    final limite = estadoAtual.duracaoEstimada;
    final posFinal = (limite > Duration.zero && novaPos > limite)
        ? limite
        : novaPos;
    await buscarPosicao(posFinal);
  }

  Future<void> retrocederSegundos(int segundos) async {
    final novaPos = estadoAtual.posicao - Duration(seconds: segundos);
    final posFinal = novaPos < Duration.zero ? Duration.zero : novaPos;
    await buscarPosicao(posFinal);
  }

  Future<void> definirVolume(double volume) async {
    final vol = volume.clamp(0.0, 1.0);
    try {
      await _player.setVolume(vol);
    } catch (_) {}
    estadoNotifier.value = estadoAtual.copyWith(volume: vol);
  }

  void alternarLoop() {
    final novoLoop = !estadoAtual.loop;
    estadoNotifier.value = estadoAtual.copyWith(loop: novoLoop);
    try {
      _player.setReleaseMode(
        novoLoop ? ReleaseMode.loop : ReleaseMode.release,
      );
    } catch (_) {}
  }

  Duration _estimarDuracao(File file) {
    try {
      final tamanhoBytes = file.lengthSync();
      final segundosEstimados = (tamanhoBytes / 16000).clamp(5, 7200).round();
      return Duration(seconds: segundosEstimados);
    } catch (_) {
      return const Duration(minutes: 3);
    }
  }
}
