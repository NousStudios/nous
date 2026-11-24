import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class GravadorAudioService {
  GravadorAudioService._();
  static final GravadorAudioService instancia = GravadorAudioService._();

  final AudioRecorder _recorder = AudioRecorder();
  Timer? _timer;
  String? _caminhoArquivoAtual;
  DateTime? _inicioTrechoAtual;
  Duration _duracaoAcumulada = Duration.zero;
  bool _cancelamentoPendente = false;
  Future<void> _filaOperacoes = Future.value();

  final ValueNotifier<bool> gravandoNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> pausadoNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<Duration> duracaoNotifier = ValueNotifier<Duration>(
    Duration.zero,
  );

  bool get estaGravando => gravandoNotifier.value;
  bool get estaPausado => pausadoNotifier.value;
  Duration get duracaoAtual => duracaoNotifier.value;

  Future<T> _enfileirar<T>(Future<T> Function() acao) {
    final completer = Completer<T>();
    _filaOperacoes = _filaOperacoes.then((_) async {
      try {
        completer.complete(await acao());
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  /// Inicia a gravação de voz após verificar permissão do microfone.
  Future<bool> iniciarGravacao() {
    _cancelamentoPendente = false;
    return _enfileirar(() async {
      try {
        if (_cancelamentoPendente) {
          _limparEstado();
          return false;
        }
        if (await _recorder.isRecording().timeout(
              const Duration(seconds: 2),
              onTimeout: () => false,
            )) {
          await _recorder.stop().timeout(
                const Duration(seconds: 2),
                onTimeout: () => null,
              );
        }

        final temPermissao = await _recorder.hasPermission().timeout(
              const Duration(seconds: 3),
              onTimeout: () => false,
            );
        if (!temPermissao || _cancelamentoPendente) {
          _limparEstado();
          return false;
        }

        final dir = await getApplicationDocumentsDirectory();
        final pastaAudios = Directory('${dir.path}/audios_chat');
        if (!pastaAudios.existsSync()) {
          await pastaAudios.create(recursive: true);
        }

        final nomeArquivo =
            'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        _caminhoArquivoAtual = '${pastaAudios.path}/$nomeArquivo';

        const config = RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        );

        await _recorder
            .start(config, path: _caminhoArquivoAtual!)
            .timeout(const Duration(seconds: 3));

        if (_cancelamentoPendente) {
          await _recorder.stop().timeout(
                const Duration(seconds: 2),
                onTimeout: () => null,
              );
          await _deletarArquivoSeguro(_caminhoArquivoAtual);
          _limparEstado();
          return false;
        }

        _duracaoAcumulada = Duration.zero;
        _inicioTrechoAtual = DateTime.now();
        duracaoNotifier.value = Duration.zero;
        pausadoNotifier.value = false;
        gravandoNotifier.value = true;
        _iniciarTimer();
        return true;
      } catch (e) {
        debugPrint('[GravadorAudioService] Erro ao iniciar gravação: $e');
        _limparEstado();
        return false;
      }
    });
  }

  void _iniciarTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!pausadoNotifier.value && _inicioTrechoAtual != null) {
        duracaoNotifier.value =
            _duracaoAcumulada + DateTime.now().difference(_inicioTrechoAtual!);
      }
    });
  }

  /// Pausa a gravação mantendo o arquivo e a duração acumulada.
  Future<void> pausarGravacao() {
    return _enfileirar(() async {
      if (!gravandoNotifier.value || pausadoNotifier.value) return;
      try {
        await _recorder.pause().timeout(const Duration(seconds: 2));
        if (_inicioTrechoAtual != null) {
          _duracaoAcumulada += DateTime.now().difference(_inicioTrechoAtual!);
          _inicioTrechoAtual = null;
        }
        duracaoNotifier.value = _duracaoAcumulada;
        pausadoNotifier.value = true;
      } catch (e) {
        debugPrint('[GravadorAudioService] Erro ao pausar gravação: $e');
      }
    });
  }

  /// Retoma a gravação pausada de onde parou.
  Future<void> retomarGravacao() {
    return _enfileirar(() async {
      if (!gravandoNotifier.value || !pausadoNotifier.value) return;
      try {
        await _recorder.resume().timeout(const Duration(seconds: 2));
        _inicioTrechoAtual = DateTime.now();
        pausadoNotifier.value = false;
      } catch (e) {
        debugPrint('[GravadorAudioService] Erro ao retomar gravação: $e');
      }
    });
  }

  /// Finaliza a gravação e retorna o caminho do arquivo e sua duração.
  Future<({String caminho, Duration duracao})?> finalizarGravacao() {
    return _enfileirar(() async {
      final caminhoSalvo = _caminhoArquivoAtual;
      final duracaoFinal = pausadoNotifier.value || _inicioTrechoAtual == null
          ? _duracaoAcumulada
          : (_duracaoAcumulada +
                DateTime.now().difference(_inicioTrechoAtual!));
      try {
        final gravando = await _recorder.isRecording().timeout(
              const Duration(seconds: 2),
              onTimeout: () => false,
            );
        final pausado = await _recorder.isPaused().timeout(
              const Duration(seconds: 2),
              onTimeout: () => false,
            );
        if (!gravando && !pausado) {
          _limparEstado();
          return null;
        }

        final caminho = await _recorder.stop().timeout(
              const Duration(seconds: 3),
              onTimeout: () => caminhoSalvo,
            );
        _limparEstado();

        final caminhoFinal = caminho ?? caminhoSalvo;
        if (caminhoFinal != null && File(caminhoFinal).existsSync()) {
          final tamanho = await File(caminhoFinal).length();
          if (tamanho > 800) {
            return (caminho: caminhoFinal, duracao: duracaoFinal);
          } else {
            await _deletarArquivoSeguro(caminhoFinal);
          }
        }
        return null;
      } catch (e) {
        debugPrint('[GravadorAudioService] Erro ao finalizar gravação: $e');
        _limparEstado();
        return null;
      }
    });
  }

  /// Cancela a gravação imediatamente sem travar a UI e exclui o arquivo temporário.
  Future<void> cancelarGravacao() {
    final precisaPararRecorder = estaGravando || estaPausado;
    final caminhoAlvo = _caminhoArquivoAtual;
    if (!precisaPararRecorder &&
        (caminhoAlvo == null || caminhoAlvo.isEmpty)) {
      return Future.value();
    }
    _cancelamentoPendente = true;
    _limparEstado();
    return _enfileirar(() async {
      try {
        if (precisaPararRecorder) {
          final gravando = await _recorder.isRecording().timeout(
                const Duration(seconds: 2),
                onTimeout: () => false,
              );
          final pausado = await _recorder.isPaused().timeout(
                const Duration(seconds: 2),
                onTimeout: () => false,
              );
          if (gravando || pausado) {
            await _recorder.stop().timeout(
                  const Duration(seconds: 2),
                  onTimeout: () => null,
                );
          }
        }
        await _deletarArquivoSeguro(caminhoAlvo);
      } catch (e) {
        debugPrint('[GravadorAudioService] Erro ao cancelar gravação: $e');
      } finally {
        _limparEstado();
      }
    });
  }

  Future<void> _deletarArquivoSeguro(String? caminho) async {
    if (caminho == null || caminho.isEmpty) return;
    try {
      final f = File(caminho);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (_) {}
  }

  void _limparEstado() {
    _timer?.cancel();
    _timer = null;
    _inicioTrechoAtual = null;
    _duracaoAcumulada = Duration.zero;
    _caminhoArquivoAtual = null;
    pausadoNotifier.value = false;
    gravandoNotifier.value = false;
    duracaoNotifier.value = Duration.zero;
  }

  void dispose() {
    _limparEstado();
    _recorder.dispose();
  }
}
