import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Helper responsável pela resolução de diretórios, cache de caminhos,
/// geração de nomes determinísticos e unificação de pastas de mídia.
class ImagemCaminhosHelper {
  ImagemCaminhosHelper._();

  static const Set<String> extensoesImagem = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'gif',
    'bmp',
  };

  static Directory? _diretorioBaseCache;
  static final Map<String, String?> _cacheResolucaoCaminhos = {};

  /// Limpa o cache em memória de resolução de caminhos (todo ou para uma chave).
  static void invalidarCache([String? caminho]) {
    if (caminho == null) {
      _cacheResolucaoCaminhos.clear();
    } else {
      _cacheResolucaoCaminhos.remove(caminho.trim());
    }
  }

  /// Gera um nome de arquivo determinístico entre sessões e dispositivos
  /// usando hash FNV-1a 64-bit sobre UTF-8.
  static String gerarNomeRemotoDeterministico(
    String chave,
    String extensao,
  ) {
    final extLimpa = extensao.replaceAll('.', '').toLowerCase();
    final extensaoFinal =
        extensoesImagem.contains(extLimpa) ? extLimpa : 'jpg';
    final bytes = utf8.encode(chave.replaceAll('\\', '/').trim());
    var hash = 0xcbf29ce484222325;
    const prime = 0x100000001b3;
    for (final b in bytes) {
      hash ^= b;
      hash = (hash * prime) & 0x7fffffffffffffff;
    }
    return 'remota_${hash.toRadixString(16).padLeft(15, '0')}.$extensaoFinal';
  }

  /// Retorna o diretório base oficial do aplicativo para armazenamento de mídias.
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

  /// Retorna todas as pastas possíveis onde imagens e anexos podem estar salvos.
  static List<Directory> obterDiretoriosPossiveisSync() {
    final dirs = <Directory>[];

    void adicionarComSubpastas(String base) {
      dirs.add(Directory('$base/imagens'));
      dirs.add(Directory('$base/audios'));
      dirs.add(Directory('$base/timeline_midias'));
      dirs.add(Directory('$base/anexos/timeline_midias'));
      dirs.add(Directory('$base/anexos/musicas'));
      dirs.add(Directory('$base/anexos/arquivosAudio'));
      dirs.add(Directory('$base/anexos/galeria'));
      dirs.add(Directory('$base/anexos/videos'));
      dirs.add(Directory('$base/anexos/arquivos'));
    }

    if (_diretorioBaseCache != null) {
      adicionarComSubpastas(_diretorioBaseCache!.path);
    }

    if (Platform.isAndroid) {
      adicionarComSubpastas('/data/user/0/com.nous.app/files/Nous');
      adicionarComSubpastas('/data/user/0/com.example.nous/files/Nous');
      adicionarComSubpastas('/data/data/com.nous.app/files/Nous');
      adicionarComSubpastas('/data/data/com.example.nous/files/Nous');
      adicionarComSubpastas('/data/user/0/com.example.nous/app_flutter/Nous');
      adicionarComSubpastas('/data/user/0/com.nous.app/app_flutter/Nous');
      adicionarComSubpastas('/data/data/com.example.nous/app_flutter/Nous');
      adicionarComSubpastas('/storage/emulated/0/Download/Nous_Imagens');
    }

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

  /// Resolve o caminho físico real de uma imagem ou anexo em diretórios atuais ou legados.
  static String? resolverCaminhoExistente(String? caminhoOriginal) {
    if (caminhoOriginal == null || caminhoOriginal.trim().isEmpty) return null;
    final limpo = caminhoOriginal.trim();

    if (_cacheResolucaoCaminhos.containsKey(limpo)) {
      final emCache = _cacheResolucaoCaminhos[limpo];
      if (emCache != null && File(emCache).existsSync()) {
        return emCache;
      }
      _cacheResolucaoCaminhos.remove(limpo);
    }

    String? resolvido;

    try {
      final arqExato = File(limpo);
      if (arqExato.existsSync() && arqExato.lengthSync() > 0) {
        resolvido = arqExato.path;
      }
    } catch (_) {}

    if (resolvido == null) {
      try {
        final normalizado = p.normalize(limpo);
        final arqNorm = File(normalizado);
        if (arqNorm.existsSync() && arqNorm.lengthSync() > 0) {
          resolvido = arqNorm.path;
        }
      } catch (_) {}
    }

    if (resolvido == null) {
      final limpoFormatado = limpo.replaceAll('\\', '/');
      final nomeArquivo = p.basename(limpoFormatado);
      if (nomeArquivo.isNotEmpty) {
        final ext = p.extension(limpoFormatado).replaceAll('.', '').toLowerCase();
        final extFinal = ext.isNotEmpty ? ext : 'jpg';
        final candidatosNomes = [
          nomeArquivo,
          gerarNomeRemotoDeterministico(limpo, extFinal),
          gerarNomeRemotoDeterministico(limpoFormatado, extFinal),
          'remota_${limpo.hashCode.abs()}.$extFinal',
          'remota_${limpoFormatado.hashCode.abs()}.$extFinal',
          'remota_${nomeArquivo.hashCode.abs()}.$extFinal',
        ];

        final possiveis = obterDiretoriosPossiveisSync();
        for (final dir in possiveis) {
          try {
            if (!dir.existsSync()) continue;
            for (final n in candidatosNomes) {
              final candidato = File(p.join(dir.path, n));
              if (candidato.existsSync() && candidato.lengthSync() > 0) {
                resolvido = candidato.path;
                break;
              }
            }
            if (resolvido != null) break;
          } catch (_) {}
        }
      }
    }

    if (resolvido != null) {
      if (_cacheResolucaoCaminhos.length > 500) {
        _cacheResolucaoCaminhos.clear();
      }
      _cacheResolucaoCaminhos[limpo] = resolvido;
    }
    return resolvido;
  }

  /// Converte um caminho físico dentro da pasta base do Nous para um caminho
  /// relativo canônico portátil entre Android e Windows (ex.: `imagens/arq.jpg`).
  static String paraCaminhoRelativoCanonico(
    String caminho, {
    required bool ehAsset,
  }) {
    final norm = caminho.replaceAll('\\', '/').trim();
    if (norm.isEmpty || ehAsset) return norm;
    for (final marcador in const [
      '/Nous/imagens/',
      '/Nous/timeline_midias/',
      '/Nous/audios/',
      '/Nous/anexos/',
    ]) {
      final idx = norm.indexOf(marcador);
      if (idx != -1) {
        return norm.substring(idx + '/Nous/'.length);
      }
    }
    return norm;
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
}
