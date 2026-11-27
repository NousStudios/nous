import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/services/changelog_service.dart';
import 'package:nous/src/core/services/helpers/atualizador_windows_helper.dart';
import 'package:nous/src/core/services/navigator_key_service.dart';
import 'package:nous/src/core/services/sessao_retorno_service.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

class InfoAtualizacao {
  final String versao;
  final String nomeVersao;
  final String descricao;
  final String urlDownload;
  final DateTime? dataPublicacao;
  final List<String> alteracoes;

  const InfoAtualizacao({
    required this.versao,
    required this.nomeVersao,
    required this.descricao,
    required this.urlDownload,
    this.dataPublicacao,
    this.alteracoes = const [],
  });
}

class AtualizacaoService {
  static String versaoAtual = '1.1.56';
  static int buildAtual = 158;

  /// Inicializa a identificação da versão do aplicativo.
  /// No Android, consulta dinamicamente a versão real instalada no sistema operacional via MethodChannel.
  static Future<void> inicializar() async {
    try {
      await ChangelogService.inicializar();
    } catch (_) {}

    if (Platform.isAndroid) {
      try {
        final dados = await const MethodChannel('com.nous.app/instalador')
            .invokeMethod<Map<dynamic, dynamic>>('obterVersaoApp');
        if (dados != null) {
          final v = dados['versao'] as String?;
          final b = dados['build'] as int?;
          if (v != null && v.isNotEmpty) {
            versaoAtual = v.replaceAll('v', '').trim();
          }
          if (b != null && b > 0) {
            buildAtual = b;
          }
          debugPrint(
            '[AtualizacaoService] Versão nativa Android identificada: v$versaoAtual (Build $buildAtual)',
          );
        }
      } catch (e) {
        debugPrint('[AtualizacaoService] Não foi possível obter versão nativa: $e');
      }
    }
  }

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
        ..connectionTimeout = const Duration(seconds: 10);

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
        final urlDownload = _extrairUrlDownloadRelease(json, htmlUrl);
        final dataStr = json['published_at'] as String?;
        final dataPub = dataStr != null ? DateTime.tryParse(dataStr) : null;

        if (tagName.isNotEmpty && versaoMaior(tagName, versaoAtual)) {
          final novidade = ChangelogService.obterUltimaVersao(tagName);
          final alteracoes = (novidade != null && novidade.alteracoes.isNotEmpty)
              ? novidade.alteracoes
              : <String>[];

          final info = InfoAtualizacao(
            versao: tagName,
            nomeVersao: nome,
            descricao: corpoDesc,
            urlDownload: urlDownload,
            dataPublicacao: dataPub,
            alteracoes: alteracoes,
          );
          infoAtualizacao.value = info;
          temAtualizacao.value = true;
          mensagemStatus.value = 'Nova versão v$tagName disponível para download!';
          ultimaVerificacao.value = DateTime.now();
          verificando.value = false;
          return true;
        } else {
          // Se já temos atualização identificada via Wi-Fi local, não apagamos
          if (!_temAtualizacaoLocal) {
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
        if (!_temAtualizacaoLocal) {
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
      if (!_temAtualizacaoLocal && !silencioso) {
        mensagemStatus.value =
            'Não foi possível conectar ao servidor de atualizações. Você pode continuar trabalhando normalmente offline.';
      }
      verificando.value = false;
      return false;
    }
  }

  static bool get _temAtualizacaoLocal {
    final url = infoAtualizacao.value?.urlDownload ?? '';
    return url.contains('/api/download_apk') ||
        url.contains('/api/download_exe') ||
        url.contains('/api/download_zip');
  }

  /// Seleciona o pacote ideal (.zip transparente ou .exe/.apk tradicional) na release do GitHub.
  static String _extrairUrlDownloadRelease(
    Map<String, dynamic> json,
    String fallbackUrl,
  ) {
    final assets = json['assets'];
    if (assets is! List) return fallbackUrl;

    if (Platform.isWindows) {
      // Prioridade 1 no Windows: pacote .zip para atualização transparente sem instalador
      for (final item in assets) {
        if (item is! Map) continue;
        final nome = (item['name'] as String? ?? '').toLowerCase();
        final downloadUrl = item['browser_download_url'] as String? ?? '';
        if (nome.endsWith('.zip') && downloadUrl.isNotEmpty) {
          return downloadUrl;
        }
      }
      // Prioridade 2 no Windows: instalador executável .exe como fallback
      for (final item in assets) {
        if (item is! Map) continue;
        final nome = (item['name'] as String? ?? '').toLowerCase();
        final downloadUrl = item['browser_download_url'] as String? ?? '';
        if (nome.endsWith('.exe') && downloadUrl.isNotEmpty) {
          return downloadUrl;
        }
      }
    } else {
      // Android: busca arquivo .apk
      for (final item in assets) {
        if (item is! Map) continue;
        final nome = (item['name'] as String? ?? '').toLowerCase();
        final downloadUrl = item['browser_download_url'] as String? ?? '';
        if (nome.endsWith('.apk') && downloadUrl.isNotEmpty) {
          return downloadUrl;
        }
      }
    }
    return fallbackUrl;
  }

  /// Tenta salvar o estado e tela do operador antes de reiniciar o aplicativo para atualização
  static Future<void> _salvarEstadoSessaoAtualSePossivel() async {
    try {
      final context = NavigatorKeyService.navigatorKey.currentContext;
      if (context != null) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final pdv = Provider.of<PdvProvider>(context, listen: false);
        final lojaId = ServidorRedeLocal().lojaAtiva?.id ??
            (pdv.lojas.length == 1 ? pdv.lojas.first.id : null);
        final sessao = SessaoRetorno(
          cpf: auth.cpf,
          modoVisitante: auth.modoVisitante,
          lojaId: lojaId,
        );
        await SessaoRetornoService.salvarSessao(sessao);
      }
    } catch (e) {
      debugPrint('[AtualizacaoService] Não foi possível salvar sessão transitória: $e');
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

    final urlLower = url.toLowerCase();
    final ehDownloadDireto = urlLower.contains('/api/download_') ||
        urlLower.endsWith('.apk') ||
        urlLower.endsWith('.exe') ||
        urlLower.endsWith('.zip');
    if (!ehDownloadDireto) {
      abrirPaginaDownload(url);
      return;
    }

    baixando.value = true;
    progressoDownload.value = 0.0;
    mensagemStatus.value = 'Iniciando download da atualização...';

    try {
      final dirTemp = await getTemporaryDirectory();
      final String extensao;
      if (urlLower.endsWith('.zip') || urlLower.contains('/api/download_zip')) {
        extensao = 'zip';
      } else if (Platform.isWindows) {
        extensao = 'exe';
      } else {
        extensao = 'apk';
      }

      final arquivoDestino = File('${dirTemp.path}/nous_atualizacao.$extensao');
      final arquivoParcial = File('${arquivoDestino.path}.part');

      Object? ultimoErro;
      bool downloadConcluido = false;
      const maxTentativas = 3;

      for (var tentativa = 1; tentativa <= maxTentativas; tentativa++) {
        HttpClient? client;
        IOSink? sink;
        try {
          if (tentativa > 1) {
            progressoDownload.value = 0.0;
            mensagemStatus.value =
                'Reconectando para concluir download ($tentativa/$maxTentativas)...';
            await Future<void>.delayed(Duration(milliseconds: 600 * tentativa));
          }

          client = HttpClient()
            ..connectionTimeout = const Duration(seconds: 12)
            ..idleTimeout = const Duration(seconds: 30);
          final req = await client.getUrl(Uri.parse(url));
          req.headers.set(
            HttpHeaders.userAgentHeader,
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 NousApp/$versaoAtual',
          );
          req.headers.set(HttpHeaders.acceptHeader, '*/*');
          req.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');

          final resp = await req.close();

          if (resp.statusCode == HttpStatus.tooManyRequests) {
            final retryHeader = resp.headers.value('retry-after');
            final esperaSegundos =
                int.tryParse(retryHeader ?? '') ?? (tentativa * 2 + 1);

            if (tentativa < maxTentativas) {
              mensagemStatus.value =
                  'Servidor com alto tráfego (HTTP 429). Aguardando ${esperaSegundos}s para tentar novamente...';
              await Future<void>.delayed(Duration(seconds: esperaSegundos));
              continue;
            } else {
              if (!url.contains('/api/download_apk') &&
                  !url.contains('/api/download_exe')) {
                mensagemStatus.value =
                    'Limite de requisições atingido (HTTP 429). Abrindo download no navegador...';
                abrirPaginaDownload(url);
                return;
              } else {
                throw Exception(
                  'O balcão local está ocupado com muitas requisições no momento. Aguarde alguns instantes e tente novamente.',
                );
              }
            }
          }

          if (resp.statusCode != HttpStatus.ok) {
            if (resp.statusCode == HttpStatus.notFound) {
              throw Exception(
                'Instalador não encontrado no servidor de atualização (HTTP 404).',
              );
            } else if (resp.statusCode == HttpStatus.forbidden) {
              throw Exception(
                'Acesso ao arquivo de atualização restrito pelo servidor (HTTP 403).',
              );
            } else {
              throw Exception('Servidor retornou status HTTP ${resp.statusCode}');
            }
          }

          final contentLength = resp.contentLength;
          if (arquivoParcial.existsSync()) {
            try {
              arquivoParcial.deleteSync();
            } catch (_) {}
          }

          sink = arquivoParcial.openWrite();
          int baixados = 0;

          await for (final chunk in resp) {
            sink.add(chunk);
            baixados += chunk.length;
            if (contentLength > 0) {
              progressoDownload.value =
                  (baixados / contentLength).clamp(0.0, 1.0);
            }
          }

          await sink.flush();
          await sink.close();
          sink = null;

          if (baixados <= 0 ||
              (contentLength > 0 && baixados != contentLength)) {
            throw Exception(
              'Download incompleto ($baixados de $contentLength bytes).',
            );
          }

          if (arquivoDestino.existsSync()) {
            try {
              arquivoDestino.deleteSync();
            } catch (_) {}
          }
          await arquivoParcial.rename(arquivoDestino.path);
          downloadConcluido = true;
          break;
        } catch (e) {
          ultimoErro = e;
          try {
            await sink?.close();
          } catch (_) {}
          if (arquivoParcial.existsSync()) {
            try {
              arquivoParcial.deleteSync();
            } catch (_) {}
          }
        } finally {
          client?.close(force: true);
        }
      }

      if (!downloadConcluido) {
        throw ultimoErro ?? Exception('Falha ao baixar arquivo de atualização.');
      }

      progressoDownload.value = 1.0;

      if (Platform.isAndroid) {
        mensagemStatus.value = 'Download concluído! Iniciando instalador...';
        await const MethodChannel('com.nous.app/instalador').invokeMethod(
          'instalarApk',
          {'caminho': arquivoDestino.path},
        );
      } else if (Platform.isWindows) {
        if (extensao == 'zip') {
          mensagemStatus.value = 'Instalando atualização e reiniciando o Nous...';
          await _salvarEstadoSessaoAtualSePossivel();
          final dirStaging = '${dirTemp.path}/nous_update_staging';
          final extraiu = await AtualizadorWindowsHelper.extrairPacoteZip(
            caminhoZip: arquivoDestino.path,
            pastaDestino: dirStaging,
          );
          if (!extraiu) {
            throw Exception('Não foi possível descompactar o pacote de atualização.');
          }
          await AtualizadorWindowsHelper.aplicarAtualizacaoEReiniciar(
            pastaStaging: dirStaging,
            caminhoZip: arquivoDestino.path,
          );
        } else {
          // Fallback tradicional caso a fonte disponha apenas do executável .exe
          mensagemStatus.value = 'Download concluído! Iniciando instalador...';
          Process.run(arquivoDestino.path, []);
        }
      }
    } on PlatformException catch (e) {
      final detalhe = e.message ?? 'Código ${e.code}';
      mensagemStatus.value = 'Erro ao iniciar instalador no aparelho ($detalhe).';
      debugPrint('[AtualizacaoService] Erro nativo ao instalar: ${e.message}');
    } catch (e) {
      final msgLimpa = e.toString().replaceFirst('Exception: ', '').trim();
      mensagemStatus.value = 'Erro ao baixar atualização: $msgLimpa';
      debugPrint('[AtualizacaoService] Erro ao baixar e instalar: $msgLimpa');
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
