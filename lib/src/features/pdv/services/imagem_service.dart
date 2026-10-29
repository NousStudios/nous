import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:nous/src/core/services/gerador_id.dart';

class ImagemService {
  ImagemService._();

  static const int limiteBytesMeioGiga = 500 * 1024 * 1024; // 500 MB (Meio giga)
  static const Set<String> extensoesImagem = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'};

  static Directory? _diretorioBaseCache;

  static Future<void> inicializar() async {
    await obterDiretorioBase();
  }

  static Future<Directory> obterDiretorioBase() async {
    if (_diretorioBaseCache != null && await _diretorioBaseCache!.exists()) {
      return _diretorioBaseCache!;
    }
    try {
      final dirSuporte = await getApplicationSupportDirectory();
      final pasta = Directory('${dirSuporte.path}/Nous');
      if (!await pasta.exists()) {
        await pasta.create(recursive: true);
      }
      _diretorioBaseCache = pasta;
      return pasta;
    } catch (_) {
      String caminhoBase;
      if (Platform.isWindows) {
        final appData = Platform.environment['APPDATA'];
        if (appData != null && appData.isNotEmpty) {
          caminhoBase = '$appData/Nous';
        } else {
          caminhoBase = '${Directory.current.path}/.nous_data';
        }
      } else {
        final home = Platform.environment['HOME'] ?? Directory.current.path;
        caminhoBase = '$home/.nous';
      }

      final dir = Directory(caminhoBase);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _diretorioBaseCache = dir;
      return dir;
    }
  }

  /// Retorna todas as pastas possíveis onde imagens e anexos do aplicativo podem estar salvos
  /// (diretório atual oficial, diretórios legados do Windows e diretórios alternativos).
  static List<Directory> obterDiretoriosPossiveisSync() {
    final dirs = <Directory>[];

    void adicionarComSubpastas(String base) {
      dirs.add(Directory('$base/imagens'));
      dirs.add(Directory('$base/audios'));
      dirs.add(Directory('$base/anexos/musicas'));
      dirs.add(Directory('$base/anexos/arquivosAudio'));
      dirs.add(Directory('$base/anexos/galeria'));
      dirs.add(Directory('$base/anexos/videos'));
      dirs.add(Directory('$base/anexos/arquivos'));
    }

    if (_diretorioBaseCache != null) {
      adicionarComSubpastas(_diretorioBaseCache!.path);
    }

    // 1. Diretórios padrão do Android
    if (Platform.isAndroid) {
      adicionarComSubpastas('/data/user/0/com.example.nous/app_flutter/Nous');
      adicionarComSubpastas('/data/user/0/com.nous.app/app_flutter/Nous');
      adicionarComSubpastas('/data/data/com.example.nous/app_flutter/Nous');
      adicionarComSubpastas('/storage/emulated/0/Download/Nous_Imagens');
    }

    // 2. Tenta diretórios padrão do ambiente no Windows
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData != null && appData.isNotEmpty) {
        adicionarComSubpastas('$appData/com.example/nous/Nous');
        adicionarComSubpastas('$appData/com.nous.app/Nous');
        adicionarComSubpastas('$appData/Nous');
      }
      final localAppData = Platform.environment['LOCALAPPDATA'];
      if (localAppData != null && localAppData.isNotEmpty) {
        adicionarComSubpastas('$localAppData/com.example/nous/Nous');
        adicionarComSubpastas('$localAppData/Nous');
      }
    } else {
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        adicionarComSubpastas('$home/.nous');
      }
    }

    adicionarComSubpastas('${Directory.current.path}/.nous_data');
    return dirs;
  }

  /// Resolve o caminho físico real de uma imagem ou anexo, mesmo que tenha sido salvo
  /// em diretório legado, em outra máquina com caminho diferente ou restaurado de backup.
  static String? resolverCaminhoExistente(String? caminhoOriginal) {
    if (caminhoOriginal == null || caminhoOriginal.trim().isEmpty) return null;
    final limpo = caminhoOriginal.trim();

    // 1. Verifica no caminho exato fornecido
    try {
      final arqExato = File(limpo);
      if (arqExato.existsSync() && arqExato.lengthSync() > 0) {
        return arqExato.path;
      }
    } catch (_) {}

    // 2. Normaliza separadores e tenta novamente
    try {
      final normalizado = p.normalize(limpo);
      final arqNorm = File(normalizado);
      if (arqNorm.existsSync() && arqNorm.lengthSync() > 0) {
        return arqNorm.path;
      }
    } catch (_) {}

    // 3. Procura pelo nome do arquivo ou hash em todas as pastas possíveis de dados
    final nomeArquivo = p.basename(limpo);
    if (nomeArquivo.isEmpty) return null;

    final ext = p.extension(limpo).replaceAll('.', '').toLowerCase();
    final extFinal = ext.isNotEmpty ? ext : 'jpg';
    final candidatosNomes = [
      nomeArquivo,
      'remota_${limpo.hashCode.abs()}.$extFinal',
      'remota_${nomeArquivo.hashCode.abs()}.$extFinal',
    ];

    final possiveis = obterDiretoriosPossiveisSync();
    for (final dir in possiveis) {
      try {
        if (!dir.existsSync()) continue;
        for (final n in candidatosNomes) {
          final candidato = File(p.join(dir.path, n));
          if (candidato.existsSync() && candidato.lengthSync() > 0) {
            return candidato.path;
          }
        }
      } catch (_) {}
    }

    return null;
  }

  /// Retorna true se o caminho se refere a um asset embutido no aplicativo (ex.: assets/images/logo.png)
  static bool ehAsset(String? caminho) {
    if (caminho == null) return false;
    final c = caminho.trim();
    return c.startsWith('assets/') || c.startsWith('asset/');
  }

  /// Retorna true se a imagem ou anexo existe fisicamente em disco ou é um asset embutido
  static bool existe(String? caminho) {
    if (ehAsset(caminho)) return true;
    return resolverCaminhoExistente(caminho) != null;
  }

  /// Retorna o File real caso a imagem exista fisicamente em disco (retorna null para assets)
  static File? obterArquivo(String? caminho) {
    if (ehAsset(caminho)) return null;
    final resolvido = resolverCaminhoExistente(caminho);
    return resolvido != null ? File(resolvido) : null;
  }

  /// Retorna um ImageProvider pronto para uso (AssetImage para assets, FileImage para arquivos), ou null se a foto não existir
  static ImageProvider? obterImageProvider(String? caminho) {
    if (ehAsset(caminho)) {
      return AssetImage(caminho!.trim());
    }
    final resolvido = resolverCaminhoExistente(caminho);
    return resolvido != null ? FileImage(File(resolvido)) : null;
  }

  /// Constrói um Widget de imagem com fallback automático e suporte unificado a assets e arquivos locais
  static Widget construirImagem(
    String? caminho, {
    double? width,
    double? height,
    BoxFit? fit,
    Widget? fallback,
    BorderRadius? borderRadius,
  }) {
    Widget img;
    if (ehAsset(caminho)) {
      img = Image.asset(
        caminho!.trim(),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => fallback ?? const SizedBox.shrink(),
      );
    } else {
      final resolvido = resolverCaminhoExistente(caminho);
      if (resolvido != null) {
        img = Image.file(
          File(resolvido),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => fallback ?? const SizedBox.shrink(),
        );
      } else {
        return fallback ?? const SizedBox.shrink();
      }
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius, child: img);
    }
    return img;
  }

  /// Consolida e unifica todas as imagens de pastas legadas para a pasta oficial atual.
  static Future<void> unificarDiretoriosImagens() async {
    try {
      final base = await obterDiretorioBase();
      final pastaOficial = Directory('${base.path}/imagens');
      if (!await pastaOficial.exists()) {
        await pastaOficial.create(recursive: true);
      }

      final caminhoOficialNorm = p.normalize(pastaOficial.path).toLowerCase();
      final diretoriosLegados = obterDiretoriosPossiveisSync();

      for (final dir in diretoriosLegados) {
        try {
          if (!await dir.exists()) continue;
          final caminhoDirNorm = p.normalize(dir.path).toLowerCase();
          if (caminhoDirNorm == caminhoOficialNorm) continue;

          await for (final entidade in dir.list()) {
            if (entidade is File) {
              final nome = p.basename(entidade.path);
              final destino = File(p.join(pastaOficial.path, nome));
              if (!await destino.exists() || await destino.length() == 0) {
                await entidade.copy(destino.path);
              }
            }
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  static bool extensaoImagemValida(String caminho) {
    final partes = caminho.split('.');
    if (partes.length < 2) return false;
    final ext = partes.last.toLowerCase();
    return extensoesImagem.contains(ext);
  }

  static Future<String?> salvarImagemLocal(String caminhoOriginal) async {
    try {
      final arquivoOriginal = File(caminhoOriginal);
      if (!await arquivoOriginal.exists()) return null;

      final tamanho = await arquivoOriginal.length();
      if (tamanho > limiteBytesMeioGiga) return null;

      if (!extensaoImagemValida(caminhoOriginal)) return null;

      final ext = caminhoOriginal.split('.').last.toLowerCase();
      final base = await obterDiretorioBase();
      final pasta = Directory('${base.path}/imagens');
      if (!await pasta.exists()) {
        await pasta.create(recursive: true);
      }

      final novoNome = 'img_${gerarIdUnico()}.$ext';
      final destino = File('${pasta.path}/$novoNome');

      await arquivoOriginal.copy(destino.path);
      return destino.path;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> salvarBytesImagemLocal(
    List<int> bytes, {
    String extensaoOriginal = 'jpg',
    String? nomeSugerido,
  }) async {
    try {
      if (bytes.isEmpty || bytes.length > limiteBytesMeioGiga) return null;
      final ext = extensoesImagem.contains(extensaoOriginal.toLowerCase())
          ? extensaoOriginal.toLowerCase()
          : 'jpg';

      final base = await obterDiretorioBase();
      final pasta = Directory('${base.path}/imagens');
      if (!await pasta.exists()) {
        await pasta.create(recursive: true);
      }

      final nomeFinal = nomeSugerido != null && nomeSugerido.trim().isNotEmpty
          ? nomeSugerido.trim()
          : 'img_${gerarIdUnico()}.$ext';
      final destino = File('${pasta.path}/$nomeFinal');

      await destino.writeAsBytes(bytes);
      return destino.path;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> salvarAnexoLocal(String caminhoOriginal, String categoria) async {
    try {
      final arquivoOriginal = File(caminhoOriginal);
      if (!await arquivoOriginal.exists()) return null;

      final tamanho = await arquivoOriginal.length();
      if (tamanho > limiteBytesMeioGiga) return null;

      final base = await obterDiretorioBase();
      final pasta = Directory('${base.path}/anexos/$categoria');
      if (!await pasta.exists()) {
        await pasta.create(recursive: true);
      }

      final nomeSanitizado = arquivoOriginal.uri.pathSegments.isNotEmpty
          ? arquivoOriginal.uri.pathSegments.last
          : 'arquivo';
      final novoNome = '${gerarIdUnico()}_$nomeSanitizado';
      final destino = File('${pasta.path}/$novoNome');

      await arquivoOriginal.copy(destino.path);
      return destino.path;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> salvarBytesAnexoLocal(
    List<int> bytes, {
    required String categoria,
    String? nomeSugerido,
  }) async {
    try {
      if (bytes.isEmpty || bytes.length > limiteBytesMeioGiga) return null;
      final base = await obterDiretorioBase();
      final pasta = Directory('${base.path}/anexos/$categoria');
      if (!await pasta.exists()) {
        await pasta.create(recursive: true);
      }

      final nomeFinal = nomeSugerido != null && nomeSugerido.trim().isNotEmpty
          ? nomeSugerido.trim()
          : '${gerarIdUnico()}_anexo';
      final destino = File('${pasta.path}/$nomeFinal');

      await destino.writeAsBytes(bytes);
      return destino.path;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> abrirNoSistema(String caminho) async {
    try {
      final arquivo = File(caminho);
      if (!await arquivo.exists()) return false;

      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', caminho]);
        return true;
      } else if (Platform.isMacOS) {
        await Process.run('open', [caminho]);
        return true;
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [caminho]);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static String formatarTamanhoBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
