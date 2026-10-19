import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class InfoAtualizacao {
  final String versao;
  final String nomeVersao;
  final String descricao;
  final String urlDownload;
  final DateTime? dataPublicacao;

  const InfoAtualizacao({
    required this.versao,
    required this.nomeVersao,
    required this.descricao,
    required this.urlDownload,
    this.dataPublicacao,
  });
}

class AtualizacaoService {
  static const String versaoAtual = '1.0.4';
  static const int buildAtual = 5;

  static final ValueNotifier<bool> temAtualizacao = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> verificando = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> baixando = ValueNotifier<bool>(false);
  static final ValueNotifier<double?> progressoDownload =
      ValueNotifier<double?>(null);
  static final ValueNotifier<InfoAtualizacao?> infoAtualizacao =
      ValueNotifier<InfoAtualizacao?>(null);
  static final ValueNotifier<DateTime?> ultimaVerificacao =
      ValueNotifier<DateTime?>(null);
  static final ValueNotifier<String?> mensagemStatus =
      ValueNotifier<String?>(null);

  /// Verifica se há atualizações disponíveis no repositório oficial do Nous.
  /// Operação segura, assíncrona e tolerante a falta de conexão com a internet.
  static Future<bool> verificarAtualizacao({bool silencioso = false}) async {
    if (verificando.value) return temAtualizacao.value;

    verificando.value = true;
    mensagemStatus.value = 'Verificando atualizações...';

    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 4);

      final uri = Uri.parse(
        'https://api.github.com/repos/NousStudios/nous/releases/latest',
      );
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'Nous-Desktop-App');
      request.headers.set('Accept', 'application/vnd.github.v3+json');

      final response = await request.close();
      if (response.statusCode == 200) {
        final corpo = await response.transform(utf8.decoder).join();
        final json = jsonDecode(corpo) as Map<String, dynamic>;

        final tagName = (json['tag_name'] as String? ?? '').replaceAll('v', '').trim();
        final nome = json['name'] as String? ?? 'Nova versão disponível';
        final corpoDesc = json['body'] as String? ?? '';
        final htmlUrl = json['html_url'] as String? ??
            'https://github.com/NousStudios/nous/releases';
        final dataStr = json['published_at'] as String?;
        final dataPub = dataStr != null ? DateTime.tryParse(dataStr) : null;

        if (tagName.isNotEmpty && versaoMaior(tagName, versaoAtual)) {
          final info = InfoAtualizacao(
            versao: tagName,
            nomeVersao: nome,
            descricao: corpoDesc,
            urlDownload: htmlUrl,
            dataPublicacao: dataPub,
          );
          infoAtualizacao.value = info;
          temAtualizacao.value = true;
          mensagemStatus.value = 'Nova versão v$tagName disponível para download!';
          ultimaVerificacao.value = DateTime.now();
          verificando.value = false;
          return true;
        } else {
          // Se já temos atualização identificada via Wi-Fi pelo balcão local, não apagamos
          final ehLocal = infoAtualizacao.value?.urlDownload.contains('/api/download_apk') ?? false;
          if (!ehLocal) {
            infoAtualizacao.value = null;
            temAtualizacao.value = false;
            mensagemStatus.value =
                'O Nous já está na versão mais recente (v$versaoAtual).';
          }
          ultimaVerificacao.value = DateTime.now();
          verificando.value = false;
          return false;
        }
      } else {
        // Se a release ainda não existe ou o repositório é privado
        final ehLocal = infoAtualizacao.value?.urlDownload.contains('/api/download_apk') ?? false;
        if (!ehLocal) {
          temAtualizacao.value = false;
          mensagemStatus.value =
              'O Nous está na versão v$versaoAtual (versão estável local).';
        }
        ultimaVerificacao.value = DateTime.now();
        verificando.value = false;
        return false;
      }
    } catch (_) {
      // Falha de rede ou timeout tratado silenciosamente
      final ehLocal = infoAtualizacao.value?.urlDownload.contains('/api/download_apk') ?? false;
      if (!ehLocal && !silencioso) {
        mensagemStatus.value =
            'Não foi possível conectar ao servidor de atualizações. Você pode continuar trabalhando normalmente offline.';
      }
      verificando.value = false;
      return false;
    }
  }

  /// Compara duas versões em formato semver (ex: 1.0.1 > 1.0.0)
  static bool versaoMaior(String remota, String local) {
    try {
      final partesRemota = remota.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final partesLocal = local.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (var i = 0; i < 3; i++) {
        final r = i < partesRemota.length ? partesRemota[i] : 0;
        final l = i < partesLocal.length ? partesLocal[i] : 0;
        if (r > l) return true;
        if (r < l) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Baixa o pacote de atualização in-app com cálculo de progresso
  /// e aciona a instalação nativa do sistema sem precisar sair do aplicativo.
  static Future<void> baixarEInstalarAtualizacao(String url) async {
    if (baixando.value) return;

    baixando.value = true;
    progressoDownload.value = 0.0;
    mensagemStatus.value = 'Iniciando download da atualização...';

    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
      final req = await client.getUrl(Uri.parse(url));
      final resp = await req.close();

      if (resp.statusCode != HttpStatus.ok) {
        throw Exception('Servidor retornou status HTTP ${resp.statusCode}');
      }

      final contentLength = resp.contentLength;
      final dirTemp = await getTemporaryDirectory();
      final extensao = Platform.isWindows ? 'exe' : 'apk';
      final arquivoDestino = File('${dirTemp.path}/nous_atualizacao.$extensao');

      if (arquivoDestino.existsSync()) {
        try {
          arquivoDestino.deleteSync();
        } catch (_) {}
      }

      final sink = arquivoDestino.openWrite();
      int baixados = 0;

      await for (final chunk in resp) {
        sink.add(chunk);
        baixados += chunk.length;
        if (contentLength > 0) {
          progressoDownload.value = (baixados / contentLength).clamp(0.0, 1.0);
        }
      }

      await sink.flush();
      await sink.close();

      progressoDownload.value = 1.0;
      mensagemStatus.value = 'Download concluído! Iniciando instalador...';

      if (Platform.isAndroid) {
        await const MethodChannel('com.nous.app/instalador').invokeMethod(
          'instalarApk',
          {'caminho': arquivoDestino.path},
        );
      } else if (Platform.isWindows) {
        Process.run(arquivoDestino.path, []);
      }
    } catch (e) {
      mensagemStatus.value = 'Erro ao baixar atualização: $e';
      debugPrint('[AtualizacaoService] Erro ao baixar e instalar: $e');
    } finally {
      baixando.value = false;
      progressoDownload.value = null;
    }
  }

  /// Abre a página de download no navegador padrão caso necessário como fallback
  static void abrirPaginaDownload(String url) {
    try {
      if (Platform.isWindows) {
        Process.run('cmd', ['/c', 'start', '', url]);
      } else if (Platform.isAndroid) {
        const MethodChannel('com.nous.app/instalador')
            .invokeMethod('abrirUrl', {'url': url});
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [url]);
      } else if (Platform.isMacOS) {
        Process.run('open', [url]);
      }
    } catch (_) {}
  }
}
