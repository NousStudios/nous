import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nous/src/core/services/atualizacao_service.dart';
import 'package:nous/src/core/services/changelog_service.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/seguranca_servidor_relay.dart';

/// Manipula uploads, downloads e streaming de arquivos de mídia (imagens, áudios e APK)
/// requisitados pelos terminais móveis ao servidor da rede local.
class ManipuladorMidiaServidor {
  /// Atende requisições de mídia HTTP (/api/imagem, /api/upload_imagem, /api/upload_anexo, /api/audio, /api/versao, /api/download_apk).
  /// Retorna `true` se a rota correspondia a mídia e foi atendida; `false` se não era rota de mídia.
  static Future<bool> atenderRequisicaoMidia(
    HttpRequest request, {
    PdvProvider? pdvProvider,
  }) async {
    final path = request.uri.path;
    final method = request.method;

    // 1. Servir imagens binárias salvas localmente na máquina
    if (path == '/api/imagem' && method == 'GET') {
      await _atenderImagem(request, pdvProvider);
      return true;
    }

    // 2. Receber upload de novas imagens enviadas por terminais móveis
    if (path == '/api/upload_imagem' && method == 'POST') {
      await _atenderUploadImagem(request);
      return true;
    }

    // 3. Receber upload de novos anexos/áudios enviados por terminais móveis
    if (path == '/api/upload_anexo' && method == 'POST') {
      await _atenderUploadAnexo(request);
      return true;
    }

    // 4. Servir arquivos de áudio/música pela rede local (streaming)
    if (path == '/api/audio' && method == 'GET') {
      await _atenderAudio(request);
      return true;
    }

    // 5. Informações de versão e atualização na rede local
    if (path == '/api/versao' && method == 'GET') {
      await _atenderVersao(request);
      return true;
    }

    // 6. Download direto do APK pela rede Wi-Fi local
    if (path == '/api/download_apk' && method == 'GET') {
      await _atenderDownloadApk(request);
      return true;
    }

    return false;
  }

  static Future<void> _atenderImagem(
    HttpRequest request,
    PdvProvider? pdvProvider,
  ) async {
    final caminho = request.uri.queryParameters['caminho'];
    final cpf = request.uri.queryParameters['cpf'];
    final itemId = request.uri.queryParameters['item_id'];
    final categoriaId = request.uri.queryParameters['categoria_id'];

    String? caminhoResolvido;
    if (caminho != null && caminho.trim().isNotEmpty) {
      caminhoResolvido = ImagemService.resolverCaminhoExistente(caminho.trim());
    }

    // Fallback 1: Buscar por item_id no catálogo das lojas do PDV
    if (caminhoResolvido == null && itemId != null && itemId.trim().isNotEmpty && pdvProvider != null) {
      final idBusca = itemId.trim();
      for (final loja in pdvProvider.lojas) {
        final item = loja.itensLoja.where((i) => i.id == idBusca).firstOrNull;
        if (item != null && item.imagens.isNotEmpty) {
          for (final img in item.imagens) {
            final res = ImagemService.resolverCaminhoExistente(img);
            if (res != null) {
              caminhoResolvido = res;
              break;
            }
          }
        }
        if (caminhoResolvido != null) break;
      }
    }

    // Fallback 2: Buscar por categoria_id no catálogo das lojas do PDV
    if (caminhoResolvido == null && categoriaId != null && categoriaId.trim().isNotEmpty && pdvProvider != null) {
      final idBusca = categoriaId.trim();
      for (final loja in pdvProvider.lojas) {
        final cat = loja.categoriasLoja.where((c) => c.id == idBusca).firstOrNull;
        if (cat != null && cat.foto.isNotEmpty) {
          caminhoResolvido = ImagemService.resolverCaminhoExistente(cat.foto);
          if (caminhoResolvido != null) break;
        }
      }
    }

    // Fallback 3: Buscar por CPF de cliente/conta
    if (caminhoResolvido == null && cpf != null && cpf.trim().isNotEmpty) {
      final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
      try {
        final conta = await ContasNousService.buscarPorCpf(cpfLimpo);
        if (conta != null && conta.foto.isNotEmpty) {
          caminhoResolvido = ImagemService.resolverCaminhoExistente(conta.foto);
        }
      } catch (_) {}
      if (caminhoResolvido == null && pdvProvider != null) {
        final fotoCli = pdvProvider.buscarFotoClientePorCpf(cpfLimpo);
        if (fotoCli != null && fotoCli.isNotEmpty) {
          caminhoResolvido = ImagemService.resolverCaminhoExistente(fotoCli);
        }
      }
    }

    // Fallback 4: Resolução por nome puro de arquivo (independente de separadores de caminho ou SO)
    if (caminhoResolvido == null && caminho != null && caminho.trim().isNotEmpty) {
      final apenasNome = caminho.trim().replaceAll('\\', '/').split('/').last;
      if (apenasNome.isNotEmpty && apenasNome != caminho.trim()) {
        caminhoResolvido = ImagemService.resolverCaminhoExistente(apenasNome);
      }
    }

    if (caminhoResolvido == null) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    // Validação estrita de Sandbox e proteção contra Path Traversal
    if (!SegurancaServidorRelay.validarCaminhoLeituraPermitido(caminhoResolvido)) {
      debugPrint('[ManipuladorMidiaServidor] Acesso bloqueado por segurança (Path Traversal/Fora do Sandbox): $caminhoResolvido');
      request.response.statusCode = HttpStatus.forbidden;
      await request.response.close();
      return;
    }

    final arquivo = File(caminhoResolvido);
    if (!arquivo.existsSync() || arquivo.lengthSync() == 0) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    try {
      final ext = caminhoResolvido.split('.').last.toLowerCase();
      ContentType tipoConteudo;
      switch (ext) {
        case 'png':
          tipoConteudo = ContentType('image', 'png');
          break;
        case 'webp':
          tipoConteudo = ContentType('image', 'webp');
          break;
        case 'gif':
          tipoConteudo = ContentType('image', 'gif');
          break;
        case 'jpg':
        case 'jpeg':
        default:
          tipoConteudo = ContentType('image', 'jpeg');
          break;
      }

      request.response.headers.contentType = tipoConteudo;
      await request.response.addStream(arquivo.openRead());
      await request.response.close();
    } catch (e) {
      debugPrint('[ManipuladorMidiaServidor] Erro ao servir imagem: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
    }
  }

  static Future<void> _atenderUploadImagem(HttpRequest request) async {
    try {
      final nomeBruto = request.uri.queryParameters['nome'];
      final nomeOriginal = SegurancaServidorRelay.sanitizarNomeArquivo(nomeBruto);
      final bytes = await request.fold<List<int>>([], (acc, chunk) => acc..addAll(chunk));
      if (bytes.isEmpty) {
        request.response.statusCode = HttpStatus.badRequest;
        await request.response.close();
        return;
      }

      final ext = nomeOriginal.split('.').last.toLowerCase();
      final salvo = await ImagemService.salvarBytesImagemLocal(
        bytes,
        extensaoOriginal: ext.isNotEmpty ? ext : 'jpg',
        nomeSugerido: nomeOriginal,
      );

      if (salvo != null) {
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'caminho': salvo}));
        await request.response.close();
      } else {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      }
    } catch (e) {
      debugPrint('[ManipuladorMidiaServidor] Erro ao receber upload de imagem: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
    }
  }

  static Future<void> _atenderUploadAnexo(HttpRequest request) async {
    try {
      final nomeBruto = request.uri.queryParameters['nome'];
      final pastaBruta = request.uri.queryParameters['pasta'] ?? 'musicas';
      final nomeOriginal = SegurancaServidorRelay.sanitizarNomeArquivo(nomeBruto);
      final subpasta = SegurancaServidorRelay.sanitizarSubpasta(pastaBruta);
      final bytes = await request.fold<List<int>>([], (acc, chunk) => acc..addAll(chunk));
      if (bytes.isEmpty) {
        request.response.statusCode = HttpStatus.badRequest;
        await request.response.close();
        return;
      }

      final salvo = await ImagemService.salvarBytesAnexoLocal(
        bytes,
        categoria: subpasta,
        nomeSugerido: nomeOriginal,
      );

      if (salvo != null) {
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'caminho': salvo}));
        await request.response.close();
      } else {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      }
    } catch (e) {
      debugPrint('[ManipuladorMidiaServidor] Erro ao receber upload de anexo: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
    }
  }

  static Future<void> _atenderAudio(HttpRequest request) async {
    final caminho = request.uri.queryParameters['caminho'];
    if (caminho == null || caminho.trim().isEmpty) {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }

    final caminhoResolvido = ImagemService.resolverCaminhoExistente(caminho.trim());
    if (caminhoResolvido == null) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    // Validação estrita de Sandbox e proteção contra Path Traversal
    if (!SegurancaServidorRelay.validarCaminhoLeituraPermitido(caminhoResolvido)) {
      debugPrint('[ManipuladorMidiaServidor] Acesso bloqueado por segurança (Path Traversal/Fora do Sandbox): $caminhoResolvido');
      request.response.statusCode = HttpStatus.forbidden;
      await request.response.close();
      return;
    }

    final arquivo = File(caminhoResolvido);

    try {
      final ext = caminhoResolvido.split('.').last.toLowerCase();
      ContentType tipoConteudo;
      switch (ext) {
        case 'mp3':
          tipoConteudo = ContentType('audio', 'mpeg');
          break;
        case 'wav':
          tipoConteudo = ContentType('audio', 'wav');
          break;
        case 'ogg':
          tipoConteudo = ContentType('audio', 'ogg');
          break;
        case 'aac':
        case 'm4a':
          tipoConteudo = ContentType('audio', 'aac');
          break;
        case 'flac':
          tipoConteudo = ContentType('audio', 'flac');
          break;
        default:
          tipoConteudo = ContentType('audio', 'mpeg');
          break;
      }

      request.response.headers.contentType = tipoConteudo;
      request.response.headers.set('Accept-Ranges', 'bytes');
      request.response.headers.contentLength = await arquivo.length();
      await request.response.addStream(arquivo.openRead());
      await request.response.close();
    } catch (e) {
      debugPrint('[ManipuladorMidiaServidor] Erro ao servir áudio: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
    }
  }

  static Future<void> _atenderVersao(HttpRequest request) async {
    final arquivoApk = obterArquivoApk();
    final temApk = arquivoApk != null && arquivoApk.existsSync() && arquivoApk.lengthSync() > 0;
    final tamanho = temApk ? arquivoApk.lengthSync() : 0;
    final novidade = ChangelogService.obterUltimaVersao(AtualizacaoService.versaoAtual) ??
        ChangelogService.obterUltimaVersao();

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({
        'sucesso': true,
        'versao': AtualizacaoService.versaoAtual,
        'build': AtualizacaoService.buildAtual,
        'temApk': temApk,
        'tamanhoBytes': tamanho,
        'nomeArquivo': 'Nous_Android_v${AtualizacaoService.versaoAtual}.apk',
        'alteracoes': novidade?.alteracoes ?? <String>[],
      }));
    await request.response.close();
  }

  static Future<void> _atenderDownloadApk(HttpRequest request) async {
    final arquivoApk = obterArquivoApk();
    if (arquivoApk == null || !arquivoApk.existsSync()) {
      request.response
        ..statusCode = HttpStatus.notFound
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'sucesso': false,
          'mensagem': 'Arquivo APK não encontrado em dist/',
        }));
      await request.response.close();
      return;
    }

    try {
      request.response.headers.contentType =
          ContentType('application', 'vnd.android.package-archive');
      request.response.headers.set(
        'Content-Disposition',
        'attachment; filename="Nous_Android_v${AtualizacaoService.versaoAtual}.apk"',
      );
      request.response.headers.contentLength = arquivoApk.lengthSync();
      await request.response.addStream(arquivoApk.openRead());
      await request.response.close();
      debugPrint('[ManipuladorMidiaServidor] APK transmitido com sucesso via Wi-Fi!');
    } catch (e) {
      debugPrint('[ManipuladorMidiaServidor] Erro ao servir APK: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
    }
  }

  /// Localiza o arquivo binário do APK Android correspondente à versão atual no armazenamento local do computador balcão
  static File? obterArquivoApk() {
    try {
      final pastaExe = File(Platform.resolvedExecutable).parent.path;
      final versao = AtualizacaoService.versaoAtual;
      final caminhos = [
        '$pastaExe/dist/Nous_Android_v${versao}_Versao_Teste.apk',
        '$pastaExe/Nous_Android_v${versao}_Versao_Teste.apk',
        'dist/Nous_Android_v${versao}_Versao_Teste.apk',
        '${Directory.current.path}/dist/Nous_Android_v${versao}_Versao_Teste.apk',
        'D:/Nous/nous/dist/Nous_Android_v${versao}_Versao_Teste.apk',
      ];

      for (final c in caminhos) {
        final f = File(c);
        if (f.existsSync() && f.lengthSync() > 0) {
          return f;
        }
      }

      // Busca dinâmica nas pastas dist estritamente por arquivos com a versão atual
      final pastas = [
        Directory('$pastaExe/dist'),
        Directory(pastaExe),
        Directory('dist'),
        Directory('${Directory.current.path}/dist'),
        Directory('D:/Nous/nous/dist'),
      ];
      for (final pasta in pastas) {
        if (pasta.existsSync()) {
          final apks = pasta
              .listSync()
              .whereType<File>()
              .where((f) =>
                  f.path.toLowerCase().endsWith('.apk') &&
                  f.lengthSync() > 0 &&
                  f.path.contains('v$versao'))
              .toList();
          if (apks.isNotEmpty) {
            return apks.first;
          }
        }
      }

      // Fallback seguro: se não encontrou com a string exata 'v$versao', seleciona o APK mais recente da pasta dist
      for (final pasta in pastas) {
        if (pasta.existsSync()) {
          final apks = pasta
              .listSync()
              .whereType<File>()
              .where((f) =>
                  f.path.toLowerCase().endsWith('.apk') &&
                  f.lengthSync() > 0)
              .toList();
          if (apks.isNotEmpty) {
            apks.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
            return apks.first;
          }
        }
      }

      debugPrint(
        '[ManipuladorMidiaServidor] Nenhum APK encontrado para distribuição.',
      );
    } catch (e) {
      debugPrint('[ManipuladorMidiaServidor] Erro ao buscar APK: $e');
    }
    return null;
  }
}
