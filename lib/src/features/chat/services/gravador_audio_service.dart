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
  DateTime? _inicioGravacao;

  final ValueNotifier<bool> gravandoNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<Duration> duracaoNotifier =
      ValueNotifier<Duration>(Duration.zero);

  bool get estaGravando => gravandoNotifier.value;
  Duration get duracaoAtual => duracaoNotifier.value;

  /// Inicia a gravação de voz após verificar permissão do microfone
  Future<bool> iniciarGravacao() async {
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }

      final temPermissao = await _recorder.hasPermission();
      if (!temPermissao) {
        debugPrint('[GravadorAudioService] Permissão de microfone negada.');
        return false;
      }

      final dir = await getApplicationDocumentsDirectory();
      final pastaAudios = Directory('${dir.path}/audios_chat');
      if (!pastaAudios.existsSync()) {
        pastaAudios.createSync(recursive: true);
      }

      final nomeArquivo = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _caminhoArquivoAtual = '${pastaAudios.path}/$nomeArquivo';

      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );

      await _recorder.start(config, path: _caminhoArquivoAtual!);
      _inicioGravacao = DateTime.now();
      duracaoNotifier.value = Duration.zero;
      gravandoNotifier.value = true;

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (_inicioGravacao != null) {
          duracaoNotifier.value =
              DateTime.now().difference(_inicioGravacao!);
        }
      });

      return true;
    } catch (e) {
      debugPrint('[GravadorAudioService] Erro ao iniciar gravação: $e');
      _limparEstado();
      return false;
    }
  }

  /// Finaliza a gravação e retorna o caminho do arquivo e sua duração
  Future<({String caminho, Duration duracao})?> finalizarGravacao() async {
    try {
      if (!await _recorder.isRecording()) {
        _limparEstado();
        return null;
      }

      final caminho = await _recorder.stop();
      final duracao = duracaoNotifier.value;
      _limparEstado();

      final caminhoFinal = caminho ?? _caminhoArquivoAtual;
      if (caminhoFinal != null && File(caminhoFinal).existsSync()) {
        final tamanho = await File(caminhoFinal).length();
        if (tamanho > 800) {
          return (caminho: caminhoFinal, duracao: duracao);
        } else {
          try {
            File(caminhoFinal).deleteSync();
          } catch (_) {}
        }
      }
      return null;
    } catch (e) {
      debugPrint('[GravadorAudioService] Erro ao finalizar gravação: $e');
      _limparEstado();
      return null;
    }
  }

  /// Cancela a gravação e exclui o arquivo temporário
  Future<void> cancelarGravacao() async {
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
      if (_caminhoArquivoAtual != null &&
          File(_caminhoArquivoAtual!).existsSync()) {
        try {
          File(_caminhoArquivoAtual!).deleteSync();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[GravadorAudioService] Erro ao cancelar gravação: $e');
    } finally {
      _limparEstado();
    }
  }

  void _limparEstado() {
    _timer?.cancel();
    _timer = null;
    _inicioGravacao = null;
    _caminhoArquivoAtual = null;
    gravandoNotifier.value = false;
    duracaoNotifier.value = Duration.zero;
  }

  void dispose() {
    _limparEstado();
    _recorder.dispose();
  }
}
