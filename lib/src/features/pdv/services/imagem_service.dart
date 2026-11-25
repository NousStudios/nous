import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:nous/src/core/services/gerador_id.dart';
import 'package:nous/src/features/pdv/services/helpers/imagem_caminhos_helper.dart';
import 'package:nous/src/features/pdv/services/helpers/imagem_limpeza_helper.dart';

class ImagemService {
  ImagemService._();

  static const int limiteBytesMeioGiga = 500 * 1024 * 1024; // 500 MB (Meio giga)
  static const Set<String> extensoesImagem = ImagemCaminhosHelper.extensoesImagem;

  /// Limpa o cache em memória de resolução de caminhos (todo ou para uma chave).
  static void invalidarCache([String? caminho]) =>
      ImagemCaminhosHelper.invalidarCache(caminho);

  /// Gera um nome de arquivo determinístico entre sessões e dispositivos
  /// usando hash FNV-1a 64-bit sobre UTF-8 (em vez de `String.hashCode`, que varia por execução).
  static String gerarNomeRemotoDeterministico(
    String chave,
    String extensao,
  ) =>
      ImagemCaminhosHelper.gerarNomeRemotoDeterministico(chave, extensao);

  static Future<void> inicializar() async {
    await obterDiretorioBase();
  }

  static Future<Directory> obterDiretorioBase() =>
      ImagemCaminhosHelper.obterDiretorioBase();

  /// Retorna todas as pastas possíveis onde imagens e anexos do aplicativo podem estar salvos
  /// (diretório atual oficial, diretórios legados do Windows e diretórios alternativos).
  static List<Directory> obterDiretoriosPossiveisSync() =>
      ImagemCaminhosHelper.obterDiretoriosPossiveisSync();

  /// Resolve o caminho físico real de uma imagem ou anexo, mesmo que tenha sido salvo
  /// em diretório legado, em outra máquina com caminho diferente ou restaurado de backup.
  static String? resolverCaminhoExistente(String? caminhoOriginal) =>
      ImagemCaminhosHelper.resolverCaminhoExistente(caminhoOriginal);

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

  /// Converte um caminho físico dentro da pasta base do Nous para um caminho
  /// relativo canônico portátil entre Android e Windows (ex.: `imagens/arq.jpg`).
  static String paraCaminhoRelativoCanonico(String caminho) =>
      ImagemCaminhosHelper.paraCaminhoRelativoCanonico(
        caminho,
        ehAsset: ehAsset(caminho),
      );

  /// Retorna um ImageProvider pronto para uso (AssetImage para assets, FileImage para arquivos), ou null se a foto não existir
  static ImageProvider? obterImageProvider(
    String? caminho, {
    int? cacheWidth,
  }) {
    if (ehAsset(caminho)) {
      return AssetImage(caminho!.trim());
    }
    final resolvido = resolverCaminhoExistente(caminho);
    if (resolvido == null) return null;
    final provider = FileImage(File(resolvido));
    if (cacheWidth != null && cacheWidth > 0) {
      return ResizeImage(provider, width: cacheWidth);
    }
    return provider;
  }

  /// Constrói um Widget de imagem com fallback automático e suporte unificado a assets e arquivos locais
  static Widget construirImagem(
    String? caminho, {
    double? width,
    double? height,
    BoxFit? fit,
    Widget? fallback,
    BorderRadius? borderRadius,
    int? cacheWidth,
  }) {
    Widget img;
    final cacheW = cacheWidth ??
        (width != null && width.isFinite && width > 0
            ? (width * 2).round().clamp(120, 1200)
            : null);
    if (ehAsset(caminho)) {
      img = Image.asset(
        caminho!.trim(),
        width: width,
        height: height,
        fit: fit,
        cacheWidth: cacheW,
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
          cacheWidth: cacheW,
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
  static Future<void> unificarDiretoriosImagens() =>
      ImagemCaminhosHelper.unificarDiretoriosImagens();

  static bool extensaoImagemValida(String caminho) {
    final partes = caminho.split('.');
    if (partes.length < 2) return false;
    final ext = partes.last.toLowerCase();
    return extensoesImagem.contains(ext);
  }

  /// Redimensiona e otimiza imagens grandes para evitar sobrecarga de memória (OOM)
  /// e lentidão de rede local, preservando nitidez máxima na exibição da UI.
  static Future<Uint8List> otimizarBytesImagem(
    Uint8List bytes, {
    int maxDimensao = 1200,
  }) async {
    if (bytes.lengthInBytes <= 250 * 1024) {
      return bytes;
    }
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();
      final img = frameInfo.image;
      final w = img.width;
      final h = img.height;
      img.dispose();

      final limiteDim = (bytes.lengthInBytes > 512 * 1024 && maxDimensao > 960)
          ? 960
          : maxDimensao;

      if (w <= limiteDim && h <= limiteDim) {
        return bytes;
      }

      int targetW = w;
      int targetH = h;
      if (w >= h) {
        targetW = limiteDim;
        targetH = (h * limiteDim / w).round().clamp(1, limiteDim);
      } else {
        targetH = limiteDim;
        targetW = (w * limiteDim / h).round().clamp(1, limiteDim);
      }

      final resizedCodec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: targetW,
        targetHeight: targetH,
      );
      final resizedFrame = await resizedCodec.getNextFrame();
      final byteData = await resizedFrame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      resizedFrame.image.dispose();
      if (byteData != null) {
        final resizedBytes = byteData.buffer.asUint8List();
        if (resizedBytes.lengthInBytes < bytes.lengthInBytes) {
          return resizedBytes;
        }
      }
    } catch (_) {
      // Em caso de falha de codec ou ambiente headless, fallback seguro
    }
    return bytes;
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

      if (extensoesImagem.contains(ext) && tamanho > 250 * 1024) {
        try {
          final bytes = await arquivoOriginal.readAsBytes();
          final otimizados = await otimizarBytesImagem(bytes);
          await destino.writeAsBytes(otimizados);
          return destino.path;
        } catch (_) {}
      }

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

      if (bytes.length > 250 * 1024 && extensoesImagem.contains(ext)) {
        try {
          final otimizados = await otimizarBytesImagem(Uint8List.fromList(bytes));
          await destino.writeAsBytes(otimizados);
          return destino.path;
        } catch (_) {}
      }

      await destino.writeAsBytes(bytes);
      return destino.path;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> salvarAnexoLocal(
    String caminhoOriginal,
    String categoria,
  ) async {
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

      final nomeBase = nomeSugerido != null && nomeSugerido.trim().isNotEmpty
          ? p.basename(nomeSugerido.trim())
          : '${gerarIdUnico()}_anexo';
      final destino = File('${pasta.path}/$nomeBase');

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

  /// Calcula o tamanho total somado de todas as pastas de mídias e anexos do aplicativo
  static Future<int> obterTamanhoTotalCacheBytes() =>
      ImagemLimpezaHelper.obterTamanhoTotalCacheBytes();

  /// Limpa arquivos temporários antigos e orfãos, garantindo respeito à cota máxima de disco
  static Future<int> limparArquivosTemporariosExpirados({
    Duration idadeMaxima = const Duration(days: 30),
    int limiteTotalBytes = limiteBytesMeioGiga,
  }) =>
      ImagemLimpezaHelper.limparArquivosTemporariosExpirados(
        idadeMaxima: idadeMaxima,
        limiteTotalBytes: limiteTotalBytes,
      );

  /// Remove com segurança arquivos `remota_*` órfãos (não referenciados em nenhuma tabela do SQLite
  /// e com mais de 24h desde a última modificação), evitando acúmulo de duplicatas no disco.
  static Future<int> limparMidiasRemotasOrfas() =>
      ImagemLimpezaHelper.limparMidiasRemotasOrfas();
}
