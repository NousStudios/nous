import 'dart:io';
import 'dart:typed_data';

class MetadadosAudio {
  final String? titulo;
  final String? artista;
  final String? album;
  final Uint8List? capaBytes;

  const MetadadosAudio({
    this.titulo,
    this.artista,
    this.album,
    this.capaBytes,
  });

  bool get temCapa => capaBytes != null && capaBytes!.isNotEmpty;
}

class MetadadosAudioService {
  MetadadosAudioService._();

  static final Map<String, MetadadosAudio> _cache = {};

  static MetadadosAudio extrair(String caminho) {
    if (_cache.containsKey(caminho)) {
      return _cache[caminho]!;
    }

    try {
      final file = File(caminho);
      if (!file.existsSync()) return const MetadadosAudio();

      // Lê os primeiros 1MB para localizar tags ID3v2 e frames APIC (imagens)
      final tamanhoLeitura = file.lengthSync().clamp(0, 1024 * 1024);
      final raf = file.openSync();
      final bytes = raf.readSync(tamanhoLeitura);
      raf.closeSync();

      if (bytes.length < 10) return const MetadadosAudio();

      // Verifica identificador "ID3"
      if (bytes[0] != 0x49 || bytes[1] != 0x44 || bytes[2] != 0x33) {
        // Fallback: procura imagem na mesma pasta (cover.jpg, folder.jpg ou mesmo nome)
        final capaPasta = _buscarCapaNaPasta(file);
        final meta = MetadadosAudio(capaBytes: capaPasta);
        _cache[caminho] = meta;
        return meta;
      }

      final versao = bytes[3];
      final tagSize = ((bytes[6] & 0x7F) << 21) |
          ((bytes[7] & 0x7F) << 14) |
          ((bytes[8] & 0x7F) << 7) |
          (bytes[9] & 0x7F);

      final totalLer = (tagSize + 10).clamp(0, bytes.length);
      int offset = 10;

      String? titulo;
      String? artista;
      String? album;
      Uint8List? capa;

      while (offset + 10 < totalLer) {
        final frameId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
        if (frameId.codeUnits.any((c) => c < 32 || c > 126)) break;

        int frameSize = 0;
        if (versao == 4) {
          frameSize = ((bytes[offset + 4] & 0x7F) << 21) |
              ((bytes[offset + 5] & 0x7F) << 14) |
              ((bytes[offset + 6] & 0x7F) << 7) |
              (bytes[offset + 7] & 0x7F);
        } else {
          frameSize = (bytes[offset + 4] << 24) |
              (bytes[offset + 5] << 16) |
              (bytes[offset + 6] << 8) |
              bytes[offset + 7];
        }

        if (frameSize <= 0 || offset + 10 + frameSize > bytes.length) break;

        final frameData = bytes.sublist(offset + 10, offset + 10 + frameSize);

        if (frameId == 'APIC' && capa == null) {
          // Busca o início de JPEG (FF D8 FF) ou PNG (89 50 4E 47)
          int imgStart = -1;
          for (int i = 0; i < frameData.length - 4; i++) {
            if (frameData[i] == 0xFF &&
                frameData[i + 1] == 0xD8 &&
                frameData[i + 2] == 0xFF) {
              imgStart = i;
              break;
            }
            if (frameData[i] == 0x89 &&
                frameData[i + 1] == 0x50 &&
                frameData[i + 2] == 0x4E &&
                frameData[i + 3] == 0x47) {
              imgStart = i;
              break;
            }
          }
          if (imgStart != -1) {
            capa = Uint8List.fromList(frameData.sublist(imgStart));
          }
        } else if (frameId == 'TIT2') {
          titulo = _decodificarTexto(frameData);
        } else if (frameId == 'TPE1') {
          artista = _decodificarTexto(frameData);
        } else if (frameId == 'TALB') {
          album = _decodificarTexto(frameData);
        }

        offset += 10 + frameSize;
      }

      capa ??= _buscarCapaNaPasta(file);

      final resultado = MetadadosAudio(
        titulo: titulo,
        artista: artista,
        album: album,
        capaBytes: capa,
      );
      _cache[caminho] = resultado;
      return resultado;
    } catch (_) {
      return const MetadadosAudio();
    }
  }

  static String _decodificarTexto(List<int> bytes) {
    if (bytes.length <= 1) return '';
    try {
      final encoding = bytes[0];
      final dados = bytes.sublist(1);
      if (encoding == 1 || encoding == 2) {
        // UTF-16
        final buffer = <int>[];
        for (int i = 0; i < dados.length - 1; i += 2) {
          final char = dados[i] | (dados[i + 1] << 8);
          if (char != 0) buffer.add(char);
        }
        return String.fromCharCodes(buffer).trim();
      }
      return String.fromCharCodes(dados.where((b) => b >= 32)).trim();
    } catch (_) {
      return '';
    }
  }

  static Uint8List? _buscarCapaNaPasta(File audioFile) {
    try {
      final dir = audioFile.parent;
      final nomeBase = audioFile.path.split(Platform.pathSeparator).last.split('.').first.toLowerCase();
      final imagens = dir.listSync().whereType<File>().where((f) {
        final p = f.path.toLowerCase();
        return p.endsWith('.jpg') || p.endsWith('.jpeg') || p.endsWith('.png') || p.endsWith('.webp');
      });

      // Procura primeiro com mesmo nome base
      for (final img in imagens) {
        final imgNome = img.path.split(Platform.pathSeparator).last.split('.').first.toLowerCase();
        if (imgNome == nomeBase || imgNome == 'cover' || imgNome == 'folder' || imgNome == 'album') {
          return img.readAsBytesSync();
        }
      }
    } catch (_) {}
    return null;
  }
}
