import 'dart:async';
import 'dart:io';
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

class PlayerAudioService {
  PlayerAudioService._();
  static final PlayerAudioService instancia = PlayerAudioService._();

  final ValueNotifier<DadosPlayerAudio> estadoNotifier =
      ValueNotifier<DadosPlayerAudio>(const DadosPlayerAudio());

  Process? _processoAtivo;
  Timer? _timerProgresso;

  DadosPlayerAudio get estadoAtual => estadoNotifier.value;

  Future<void> tocar(String caminho) async {
    final arquivo = File(caminho);
    if (!arquivo.existsSync()) return;

    await parar();

    estadoNotifier.value = estadoAtual.copyWith(
      estado: EstadoPlayerAudio.reproduzindo,
      caminho: caminho,
      posicao: Duration.zero,
      duracaoEstimada: _estimarDuracao(arquivo),
    );

    if (Platform.isWindows) {
      final caminhoFormatado = caminho.replaceAll("'", "''");
      try {
        _processoAtivo = await Process.start(
          'powershell',
          [
            '-NoProfile',
            '-NonInteractive',
            '-Command',
            "Add-Type -AssemblyName presentationCore; "
                "\$player = New-Object System.Windows.Media.MediaPlayer; "
                "\$player.Open([System.Uri]'$caminhoFormatado'); "
                "\$player.Volume = ${estadoAtual.volume}; "
                "\$player.Play(); "
                "while (\$true) { "
                "  Start-Sleep -Milliseconds 500; "
                "  if (\$player.NaturalDuration.HasTimeSpan) { "
                "    \$dur = \$player.NaturalDuration.TimeSpan.TotalSeconds; "
                "    \$pos = \$player.Position.TotalSeconds; "
                "    Write-Output \"PROGRESS:\$pos:\$dur\"; "
                "    if (\$pos -ge \$dur -and \$dur -gt 0) { break; } "
                "  } "
                "} "
                "\$player.Stop();",
          ],
        );

        _processoAtivo?.stdout
            .transform(const SystemEncoding().decoder)
            .listen((linha) {
          final partes = linha.trim().split(':');
          if (partes.length == 3 && partes[0] == 'PROGRESS') {
            final posSegundos = double.tryParse(partes[1]) ?? 0;
            final durSegundos = double.tryParse(partes[2]) ?? 0;
            if (estadoAtual.estado == EstadoPlayerAudio.reproduzindo) {
              estadoNotifier.value = estadoAtual.copyWith(
                posicao: Duration(milliseconds: (posSegundos * 1000).round()),
                duracaoEstimada: durSegundos > 0
                    ? Duration(milliseconds: (durSegundos * 1000).round())
                    : estadoAtual.duracaoEstimada,
              );
            }
          }
        });

        _processoAtivo?.exitCode.then((_) {
          if (estadoAtual.estado == EstadoPlayerAudio.reproduzindo) {
            parar();
          }
        });
      } catch (_) {
        _iniciarTimerFallback();
      }
    } else {
      _iniciarTimerFallback();
    }
  }

  void _iniciarTimerFallback() {
    _timerProgresso?.cancel();
    _timerProgresso = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (estadoAtual.estado != EstadoPlayerAudio.reproduzindo) {
        timer.cancel();
        return;
      }
      final novaPos = estadoAtual.posicao + const Duration(seconds: 1);
      if (estadoAtual.duracaoEstimada.inSeconds > 0 &&
          novaPos >= estadoAtual.duracaoEstimada) {
        parar();
      } else {
        estadoNotifier.value = estadoAtual.copyWith(posicao: novaPos);
      }
    });
  }

  Future<void> pausar() async {
    if (estadoAtual.estado != EstadoPlayerAudio.reproduzindo) return;
    _finalizarProcesso();
    _timerProgresso?.cancel();
    estadoNotifier.value = estadoAtual.copyWith(
      estado: EstadoPlayerAudio.pausado,
    );
  }

  Future<void> retomar() async {
    if (estadoAtual.caminho == null) return;
    final posAtual = estadoAtual.posicao;
    await tocar(estadoAtual.caminho!);
    estadoNotifier.value = estadoAtual.copyWith(
      posicao: posAtual,
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
    _finalizarProcesso();
    _timerProgresso?.cancel();
    estadoNotifier.value = estadoAtual.copyWith(
      estado: EstadoPlayerAudio.parado,
      posicao: Duration.zero,
    );
  }

  void alternarLoop() {
    estadoNotifier.value = estadoAtual.copyWith(loop: !estadoAtual.loop);
  }

  void _finalizarProcesso() {
    try {
      _processoAtivo?.kill();
    } catch (_) {}
    _processoAtivo = null;
  }

  Duration _estimarDuracao(File file) {
    try {
      final tamanhoBytes = file.lengthSync();
      // Estimativa média para áudio MP3 128kbps (16 KB/s)
      final segundosEstimados = (tamanhoBytes / 16000).clamp(5, 7200).round();
      return Duration(seconds: segundosEstimados);
    } catch (_) {
      return const Duration(minutes: 3);
    }
  }
}
