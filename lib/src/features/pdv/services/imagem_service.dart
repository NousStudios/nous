import 'dart:io';
import 'package:nous/src/core/services/gerador_id.dart';

class ImagemService {
  ImagemService._();

  static const int limiteBytesMeioGiga = 500 * 1024 * 1024; // 500 MB (Meio giga)
  static const Set<String> extensoesImagem = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'};

  static Future<Directory> obterDiretorioBase() async {
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
    return dir;
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
}
