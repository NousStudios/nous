import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

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
  static const String versaoAtual = '1.0.0';
  static const int buildAtual = 1;

  static final ValueNotifier<bool> temAtualizacao = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> verificando = ValueNotifier<bool>(false);
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

        if (tagName.isNotEmpty && _versaoMaior(tagName, versaoAtual)) {
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
          infoAtualizacao.value = null;
          temAtualizacao.value = false;
          mensagemStatus.value =
              'O Nous já está na versão mais recente (v$versaoAtual).';
          ultimaVerificacao.value = DateTime.now();
          verificando.value = false;
          return false;
        }
      } else {
        // Se a release ainda não existe ou o repositório é privado
        temAtualizacao.value = false;
        mensagemStatus.value =
            'O Nous está na versão v$versaoAtual (versão estável local).';
        ultimaVerificacao.value = DateTime.now();
        verificando.value = false;
        return false;
      }
    } catch (_) {
      // Falha de rede ou timeout tratado silenciosamente
      if (!silencioso) {
        mensagemStatus.value =
            'Não foi possível conectar ao servidor de atualizações. Você pode continuar trabalhando normalmente offline.';
      }
      verificando.value = false;
      return false;
    }
  }

  /// Compara duas versões em formato semver (ex: 1.0.1 > 1.0.0)
  static bool _versaoMaior(String remota, String local) {
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

  /// Abre a página de download no navegador padrão do sistema operacional
  static void abrirPaginaDownload(String url) {
    try {
      if (Platform.isWindows) {
        Process.run('cmd', ['/c', 'start', '', url]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [url]);
      } else if (Platform.isMacOS) {
        Process.run('open', [url]);
      }
    } catch (_) {}
  }
}
