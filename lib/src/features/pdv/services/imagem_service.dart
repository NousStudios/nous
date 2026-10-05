import 'dart:io';
import 'package:nous/src/core/services/gerador_id.dart';

class ImagemService {
  ImagemService._();

  static const int limiteBytes = 5 * 1024 * 1024; // 5 MB
  static const Set<String> extensoesPermitidas = {'jpg', 'jpeg', 'png', 'webp'};

  static Future<Directory> obterDiretorioImagens() async {
    String caminhoBase;
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData != null && appData.isNotEmpty) {
        caminhoBase = '$appData/Nous/imagens';
      } else {
        caminhoBase = '${Directory.current.path}/.nous_data/imagens';
      }
    } else {
      final home = Platform.environment['HOME'] ?? Directory.current.path;
      caminhoBase = '$home/.nous/imagens';
    }

    final dir = Directory(caminhoBase);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static bool extensaoValida(String caminho) {
    final partes = caminho.split('.');
    if (partes.length < 2) return false;
    final ext = partes.last.toLowerCase();
    return extensoesPermitidas.contains(ext);
  }

  static Future<String?> salvarImagemLocal(String caminhoOriginal) async {
    try {
      final arquivoOriginal = File(caminhoOriginal);
      if (!await arquivoOriginal.exists()) return null;

      final tamanho = await arquivoOriginal.length();
      if (tamanho > limiteBytes) return null;

      if (!extensaoValida(caminhoOriginal)) return null;

      final ext = caminhoOriginal.split('.').last.toLowerCase();
      final pasta = await obterDiretorioImagens();
      final novoNome = 'img_${gerarIdUnico()}.$ext';
      final destino = File('${pasta.path}/$novoNome');

      await arquivoOriginal.copy(destino.path);
      return destino.path;
    } catch (_) {
      return null;
    }
  }
}
