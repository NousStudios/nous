import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class ResultadoVozBusca {
  final String? texto;
  final String? mensagemErro;
  final bool cancelado;

  const ResultadoVozBusca({
    this.texto,
    this.mensagemErro,
    this.cancelado = false,
  });
}

/// Serviço multiplataforma de pesquisa por voz:
/// - Android: `RecognizerIntent` nativo (`pt-BR`) via `MethodChannel`.
/// - Windows: gravação local via `record` (WASAPI WAV 16kHz) + transcrição
///   100% offline em português via `whisper.cpp` (`ggml-tiny-q5_1.bin`).
class VozBuscaService {
  VozBuscaService._();

  static const MethodChannel _canalAndroid =
      MethodChannel('com.nous.app/instalador');

  static const String _urlBinarioWindows =
      'https://github.com/ggml-org/whisper.cpp/releases/download/b5907/whisper-bin-x64.zip';
  static const String _urlModeloPtBr =
      'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base-q5_1.bin';
  static const String _nomeArquivoModelo = 'ggml-base-q5_1.bin';
  static const String _promptContextoMapa =
      'Rua, Avenida, Praça, Shopping, Bairro, Centro, Restaurante, Lanchonete, Mercado, Farmácia, Pizzaria.';

  static AudioRecorder? _recorderWindows;
  static String? _caminhoWavAtual;
  static bool _canceladoManualmente = false;

  static Future<Directory> _pastaVozOffline() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}voz_offline');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<File?> _localizarExecutavelWhisper(Directory pasta) async {
    if (!pasta.existsSync()) return null;
    await for (final ent in pasta.list(recursive: true, followLinks: false)) {
      if (ent is File &&
          ent.path.toLowerCase().endsWith('${Platform.pathSeparator}whisper-cli.exe')) {
        return ent;
      }
    }
    return null;
  }

  static Future<File> _arquivoModelo(Directory pasta) async {
    return File('${pasta.path}${Platform.pathSeparator}$_nomeArquivoModelo');
  }

  /// Verifica se o motor offline (binário + modelo) já está disponível no Windows.
  static Future<bool> motorWindowsPronto() async {
    if (!Platform.isWindows) return true;
    final pasta = await _pastaVozOffline();
    final exe = await _localizarExecutavelWhisper(pasta);
    final modelo = await _arquivoModelo(pasta);
    return exe != null &&
        exe.existsSync() &&
        modelo.existsSync() &&
        modelo.lengthSync() > 1024 * 1024;
  }

  /// Baixa e prepara o motor offline `whisper.cpp` (~40 MB total) no Windows.
  static Future<String?> prepararMotorWindows({
    required void Function(double progresso, String etapa) onProgresso,
  }) async {
    try {
      final pasta = await _pastaVozOffline();
      var exe = await _localizarExecutavelWhisper(pasta);
      if (exe == null || !exe.existsSync()) {
        onProgresso(0.05, 'Baixando motor de voz offline (9 MB)...');
        final zipFile = File('${pasta.path}${Platform.pathSeparator}whisper.zip');
        await _baixarArquivo(
          _urlBinarioWindows,
          zipFile,
          onProgresso: (p) => onProgresso(0.05 + p * 0.25, 'Baixando motor de voz (9 MB)...'),
        );

        onProgresso(0.32, 'Extraindo motor de voz...');
        final proc = await Process.run(
          'powershell',
          [
            '-NoProfile',
            '-Command',
            'Expand-Archive -Path "${zipFile.path}" -DestinationPath "${pasta.path}" -Force',
          ],
        );
        try {
          if (zipFile.existsSync()) await zipFile.delete();
        } catch (_) {}

        exe = await _localizarExecutavelWhisper(pasta);
        if (proc.exitCode != 0 || exe == null) {
          return 'Não foi possível extrair o motor de voz offline.';
        }
      }

      final modelo = await _arquivoModelo(pasta);
      if (!modelo.existsSync() || modelo.lengthSync() < 20 * 1024 * 1024) {
        // Remove modelos anteriores (tiny/small) para não desperdiçar espaço
        await _apagarSeguro(
          '${pasta.path}${Platform.pathSeparator}ggml-tiny-q5_1.bin',
        );
        await _apagarSeguro(
          '${pasta.path}${Platform.pathSeparator}ggml-small-q5_1.bin',
        );
        onProgresso(0.35, 'Baixando modelo rápido em Português (~57 MB)...');
        final tempModelo = File('${modelo.path}.part');
        await _baixarArquivo(
          _urlModeloPtBr,
          tempModelo,
          onProgresso: (p) => onProgresso(
            0.35 + p * 0.63,
            'Baixando modelo Português (${(p * 100).round()}%)...',
          ),
        );
        if (modelo.existsSync()) await modelo.delete();
        await tempModelo.rename(modelo.path);
      }

      onProgresso(1.0, 'Pronto!');
      return null;
    } catch (e) {
      debugPrint('[VozBuscaService] Erro ao preparar motor offline: $e');
      return 'Falha ao baixar o motor de voz offline. Verifique sua internet.';
    }
  }

  static Future<void> _baixarArquivo(
    String url,
    File destino, {
    required void Function(double progresso) onProgresso,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await client.getUrl(Uri.parse(url));
      req.headers.set('User-Agent', 'NousSuperApp/1.1');
      final resp = await req.close();
      if (resp.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${resp.statusCode}', uri: Uri.parse(url));
      }
      final total = resp.contentLength;
      var baixado = 0;
      final sink = destino.openWrite();
      try {
        await for (final chunk in resp) {
          sink.add(chunk);
          baixado += chunk.length;
          if (total > 0) {
            onProgresso((baixado / total).clamp(0.0, 1.0));
          }
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
    } finally {
      client.close(force: true);
    }
  }

  /// Fluxo Android: abre o diálogo nativo do sistema e devolve o texto.
  static Future<ResultadoVozBusca> ouvirAndroid() async {
    try {
      final texto = await _canalAndroid.invokeMethod<String>('reconhecerVoz');
      final limpo = (texto ?? '').trim();
      return ResultadoVozBusca(texto: limpo.isNotEmpty ? limpo : null);
    } catch (e) {
      debugPrint('[VozBuscaService] Erro Android: $e');
      return const ResultadoVozBusca(
        mensagemErro: 'Não foi possível iniciar o microfone neste aparelho.',
      );
    }
  }

  /// Inicia a gravação em WAV 16kHz mono no Windows.
  static Future<String?> iniciarGravacaoWindows() async {
    _canceladoManualmente = false;
    try {
      _recorderWindows ??= AudioRecorder();
      final temPermissao = await _recorderWindows!.hasPermission();
      if (!temPermissao) {
        return 'Permissão de microfone negada no Windows.';
      }

      final pasta = await _pastaVozOffline();
      _caminhoWavAtual =
          '${pasta.path}${Platform.pathSeparator}busca_${DateTime.now().millisecondsSinceEpoch}.wav';

      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      );
      await _recorderWindows!.start(config, path: _caminhoWavAtual!);
      return null;
    } catch (e) {
      debugPrint('[VozBuscaService] Erro iniciar gravação Windows: $e');
      return 'Não foi possível acessar o microfone no Windows.';
    }
  }

  /// Para a gravação ativa no Windows e transcreve offline com `whisper-cli.exe`.
  static Future<ResultadoVozBusca> pararETranscreverWindows() async {
    final recorder = _recorderWindows;
    final caminhoWav = _caminhoWavAtual;
    _caminhoWavAtual = null;

    if (recorder == null || caminhoWav == null) {
      return const ResultadoVozBusca(cancelado: true);
    }

    try {
      final pathGravado = await recorder.stop();
      if (_canceladoManualmente) {
        await _apagarSeguro(caminhoWav);
        return const ResultadoVozBusca(cancelado: true);
      }

      final arquivoAudio = File(pathGravado ?? caminhoWav);
      if (!arquivoAudio.existsSync() || arquivoAudio.lengthSync() < 2000) {
        await _apagarSeguro(arquivoAudio.path);
        return const ResultadoVozBusca(
          mensagemErro: 'Áudio muito curto. Fale um pouco mais perto do microfone.',
        );
      }

      final pasta = await _pastaVozOffline();
      final exe = await _localizarExecutavelWhisper(pasta);
      final modelo = await _arquivoModelo(pasta);
      if (exe == null || !exe.existsSync() || !modelo.existsSync()) {
        await _apagarSeguro(arquivoAudio.path);
        return const ResultadoVozBusca(
          mensagemErro: 'Motor de voz offline não encontrado.',
        );
      }

      final threads = Platform.numberOfProcessors.clamp(2, 6);
      final proc = await Process.run(
        exe.path,
        [
          '-m',
          modelo.path,
          '-l',
          'pt',
          '-t',
          '$threads',
          '-bs',
          '1',
          '-bo',
          '1',
          '--prompt',
          _promptContextoMapa,
          '-nt',
          '-np',
          '-f',
          arquivoAudio.path,
        ],
        workingDirectory: exe.parent.path,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      ).timeout(const Duration(seconds: 30));

      await _apagarSeguro(arquivoAudio.path);

      if (_canceladoManualmente) {
        return const ResultadoVozBusca(cancelado: true);
      }

      if (proc.exitCode != 0) {
        debugPrint(
          '[VozBuscaService] whisper-cli falhou (${proc.exitCode}): ${proc.stderr}',
        );
        return const ResultadoVozBusca(
          mensagemErro: 'Falha ao executar o motor offline de transcrição.',
        );
      }

      final bruto = (proc.stdout?.toString() ?? '').trim();
      final limpo = _limparSaidaWhisper(bruto);

      if (limpo.isEmpty) {
        return const ResultadoVozBusca(
          mensagemErro: 'Não foi possível entender a fala. Tente novamente.',
        );
      }
      return ResultadoVozBusca(texto: limpo);
    } catch (e) {
      await _apagarSeguro(caminhoWav);
      debugPrint('[VozBuscaService] Erro transcrição offline: $e');
      return const ResultadoVozBusca(
        mensagemErro: 'Erro ao transcrever o áudio captado.',
      );
    }
  }

  static void cancelarEscutaAtiva() {
    _canceladoManualmente = true;
    final rec = _recorderWindows;
    final wav = _caminhoWavAtual;
    _caminhoWavAtual = null;
    if (rec != null) {
      unawaited(
        rec.stop().catchError((_) => null).whenComplete(() {
          if (wav != null) unawaited(_apagarSeguro(wav));
        }),
      );
    }
  }

  static String _limparSaidaWhisper(String texto) {
    var s = texto
        .replaceAll(RegExp(r'\[[^\]]*\]'), ' ')
        .replaceAll(RegExp(r'\([^)]*\)'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    // Remove pontuação final isolada típica de frases curtas de busca
    s = s.replaceAll(RegExp(r'[.!?]+$'), '').trim();
    return s;
  }

  static Future<void> _apagarSeguro(String? caminho) async {
    if (caminho == null) return;
    try {
      final f = File(caminho);
      if (f.existsSync()) await f.delete();
    } catch (_) {}
  }
}
