import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

enum EstadoPlayerAudio { parado, reproduzindo, pausado }

class DadosPlayerAudio {
  final EstadoPlayerAudio estado;
  final String? caminho;
  final Duration posicao;
  final Duration duracaoEstimada;
  final double volume;
  final bool loop;

  const DadosPlayerAudio({
    this.estado = EstadoPlayerAudio.parado,
    this.caminho,
    this.posicao = Duration.zero,
    this.duracaoEstimada = Duration.zero,
    this.volume = 1.0,
    this.loop = false,
  });

  DadosPlayerAudio copyWith({
    EstadoPlayerAudio? estado,
    String? caminho,
    Duration? posicao,
    Duration? duracaoEstimada,
    double? volume,
    bool? loop,
  }) {
    return DadosPlayerAudio(
      estado: estado ?? this.estado,
      caminho: caminho ?? this.caminho,
      posicao: posicao ?? this.posicao,
      duracaoEstimada: duracaoEstimada ?? this.duracaoEstimada,
      volume: volume ?? this.volume,
      loop: loop ?? this.loop,
    );
  }
}

typedef _MciSendStringWNative = Uint32 Function(
    Pointer<Utf16> lpstrCommand,
    Pointer<Utf16> lpstrReturnString,
    Uint32 uReturnLength,
    IntPtr hwndCallback);
typedef _MciSendStringWDart = int Function(
    Pointer<Utf16> lpstrCommand,
    Pointer<Utf16> lpstrReturnString,
    int uReturnLength,
    int hwndCallback);

class PlayerAudioService {
  PlayerAudioService._();
  static final PlayerAudioService instancia = PlayerAudioService._();

  static const String _aliasPlayer = 'nous_internal_player';

  final ValueNotifier<DadosPlayerAudio> estadoNotifier =
      ValueNotifier<DadosPlayerAudio>(const DadosPlayerAudio());

  Timer? _timerPolling;
  DynamicLibrary? _winmm;
  _MciSendStringWDart? _mciSendString;

  DadosPlayerAudio get estadoAtual => estadoNotifier.value;

  _MciSendStringWDart? get _mci {
    if (!Platform.isWindows) return null;
    try {
      _winmm ??= DynamicLibrary.open('winmm.dll');
      _mciSendString ??=
          _winmm!.lookupFunction<_MciSendStringWNative, _MciSendStringWDart>(
              'mciSendStringW');
      return _mciSendString;
    } catch (_) {
      return null;
    }
  }

  int _enviarComandoMci(String comando,
      [Pointer<Utf16>? bufferRetorno, int tamanhoBuffer = 0]) {
    final mci = _mci;
    if (mci == null) return -1;
    final cmdUtf16 = comando.toNativeUtf16();
    final res = mci(cmdUtf16, bufferRetorno ?? nullptr, tamanhoBuffer, 0);
    calloc.free(cmdUtf16);
    return res;
  }

  String _obterStatusMci(String comando) {
    final mci = _mci;
    if (mci == null) return '';
    final buffer = calloc<Uint16>(128).cast<Utf16>();
    _enviarComandoMci(comando, buffer, 128);
    final str = buffer.toDartString().trim();
    calloc.free(buffer);
    return str;
  }

  Future<void> tocar(String caminho) async {
    final arquivo = File(caminho);
    if (!arquivo.existsSync()) return;

    await parar();

    final duracaoInicial = _estimarDuracao(arquivo);
    estadoNotifier.value = estadoAtual.copyWith(
      estado: EstadoPlayerAudio.reproduzindo,
      caminho: caminho,
      posicao: Duration.zero,
      duracaoEstimada: duracaoInicial,
    );

    if (Platform.isWindows && _mci != null) {
      final caminhoAbsoluto = arquivo.absolute.path.replaceAll('/', '\\');
      _enviarComandoMci('close $_aliasPlayer');

      var res = _enviarComandoMci(
          'open "$caminhoAbsoluto" type mpegvideo alias $_aliasPlayer');
      if (res != 0) {
        res = _enviarComandoMci('open "$caminhoAbsoluto" alias $_aliasPlayer');
      }

      if (res == 0) {
        _enviarComandoMci('set $_aliasPlayer time format milliseconds');

        final durStr = _obterStatusMci('status $_aliasPlayer length');
        final durMs = int.tryParse(durStr) ?? 0;
        final duracaoReal =
            durMs > 0 ? Duration(milliseconds: durMs) : duracaoInicial;

        _enviarComandoMci('play $_aliasPlayer');

        estadoNotifier.value = estadoAtual.copyWith(
          duracaoEstimada: duracaoReal,
        );

        _iniciarPollingMci(duracaoReal);
        return;
      }
    }

    _iniciarTimerFallback();
  }

  void _iniciarPollingMci(Duration duracao) {
    _timerPolling?.cancel();
    _timerPolling = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (estadoAtual.estado != EstadoPlayerAudio.reproduzindo) {
        timer.cancel();
        return;
      }

      final mode = _obterStatusMci('status $_aliasPlayer mode');
      if (mode.toLowerCase() == 'stopped') {
        if (estadoAtual.loop) {
          _enviarComandoMci('play $_aliasPlayer from 0');
          estadoNotifier.value = estadoAtual.copyWith(posicao: Duration.zero);
        } else {
          parar();
        }
        return;
      }

      final posStr = _obterStatusMci('status $_aliasPlayer position');
      final posMs = int.tryParse(posStr);
      if (posMs != null && posMs >= 0) {
        final novaPos = Duration(milliseconds: posMs);
        if (duracao.inMilliseconds > 0 && novaPos >= duracao) {
          if (estadoAtual.loop) {
            _enviarComandoMci('play $_aliasPlayer from 0');
            estadoNotifier.value = estadoAtual.copyWith(posicao: Duration.zero);
          } else {
            parar();
          }
        } else {
          estadoNotifier.value = estadoAtual.copyWith(posicao: novaPos);
        }
      }
    });
  }

  void _iniciarTimerFallback() {
    _timerPolling?.cancel();
    _timerPolling = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (estadoAtual.estado != EstadoPlayerAudio.reproduzindo) {
        timer.cancel();
        return;
      }
      final novaPos = estadoAtual.posicao + const Duration(seconds: 1);
      if (estadoAtual.duracaoEstimada.inSeconds > 0 &&
          novaPos >= estadoAtual.duracaoEstimada) {
        if (estadoAtual.loop) {
          estadoNotifier.value = estadoAtual.copyWith(posicao: Duration.zero);
        } else {
          parar();
        }
      } else {
        estadoNotifier.value = estadoAtual.copyWith(posicao: novaPos);
      }
    });
  }

  Future<void> pausar() async {
    if (estadoAtual.estado != EstadoPlayerAudio.reproduzindo) return;
    _timerPolling?.cancel();
    if (Platform.isWindows && _mci != null) {
      _enviarComandoMci('pause $_aliasPlayer');
    }
    estadoNotifier.value = estadoAtual.copyWith(
      estado: EstadoPlayerAudio.pausado,
    );
  }

  Future<void> retomar() async {
    if (estadoAtual.caminho == null) return;
    if (Platform.isWindows && _mci != null) {
      _enviarComandoMci('resume $_aliasPlayer');
      estadoNotifier.value = estadoAtual.copyWith(
        estado: EstadoPlayerAudio.reproduzindo,
      );
      _iniciarPollingMci(estadoAtual.duracaoEstimada);
    } else {
      await tocar(estadoAtual.caminho!);
    }
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
    _timerPolling?.cancel();
    if (Platform.isWindows && _mci != null) {
      _enviarComandoMci('stop $_aliasPlayer');
      _enviarComandoMci('close $_aliasPlayer');
    }
    estadoNotifier.value = estadoAtual.copyWith(
      estado: EstadoPlayerAudio.parado,
      posicao: Duration.zero,
    );
  }

  void alternarLoop() {
    estadoNotifier.value = estadoAtual.copyWith(loop: !estadoAtual.loop);
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
