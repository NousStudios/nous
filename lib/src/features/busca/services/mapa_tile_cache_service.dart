import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:nous/src/core/services/rede_logger_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

/// TileProvider com cache persistente em disco para o OpenStreetMap.
/// Reduz latência, evita falhas de conexão repetidas e permite uso offline.
class NousCachedTileProvider extends TileProvider {
  NousCachedTileProvider({super.headers});

  static final HttpClient _httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 12);

  static Directory? _pastaCacheEmMemoria;

  static Future<Directory?> _obterPastaCache() async {
    if (_pastaCacheEmMemoria != null) return _pastaCacheEmMemoria;
    try {
      final base = await ImagemService.obterDiretorioBase();
      final dir = Directory(
        '${base.path}${Platform.pathSeparator}mapa_tiles_cache',
      );
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _pastaCacheEmMemoria = dir;
      return dir;
    } catch (_) {
      try {
        final dir = Directory(
          '${Directory.systemTemp.path}${Platform.pathSeparator}nous_mapa_tiles',
        );
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        _pastaCacheEmMemoria = dir;
        return dir;
      } catch (_) {
        return null;
      }
    }
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    final ua = headers['User-Agent'] ?? 'flutter_map (br.com.nous.app)';
    return _NousCachedTileImage(
      url: url,
      userAgent: ua,
      z: coordinates.z,
      x: coordinates.x,
      y: coordinates.y,
    );
  }
}

@immutable
class _NousCachedTileImage extends ImageProvider<_NousCachedTileImage> {
  final String url;
  final String userAgent;
  final int z;
  final int x;
  final int y;

  const _NousCachedTileImage({
    required this.url,
    required this.userAgent,
    required this.z,
    required this.x,
    required this.y,
  });

  @override
  Future<_NousCachedTileImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_NousCachedTileImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _NousCachedTileImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _carregarCodec(key, decode),
      scale: 1.0,
      debugLabel: url,
    );
  }

  Future<ui.Codec> _carregarCodec(
    _NousCachedTileImage key,
    ImageDecoderCallback decode,
  ) async {
    try {
      final dir = await NousCachedTileProvider._obterPastaCache();
      final arquivo = dir != null
          ? File(
              '${dir.path}${Platform.pathSeparator}${key.z}_${key.x}_${key.y}.png',
            )
          : null;

      if (arquivo != null && await arquivo.exists()) {
        try {
          final bytes = await arquivo.readAsBytes();
          if (bytes.isNotEmpty) {
            final stat = await arquivo.stat();
            final idade = DateTime.now().difference(stat.modified);
            if (idade.inDays >= 7) {
              unawaited(_baixarESalvar(key.url, key.userAgent, arquivo));
            }
            final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
            return await decode(buffer);
          }
        } catch (_) {}
      }

      var bytes = await _baixarESalvar(key.url, key.userAgent, arquivo);
      if (bytes == null || bytes.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
        bytes = await _baixarESalvar(key.url, key.userAgent, arquivo);
      }

      if (bytes != null && bytes.isNotEmpty) {
        final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
        return await decode(buffer);
      }
    } catch (_) {}

    scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(key));
    throw Exception('Falha ao carregar tile ${key.z}/${key.x}/${key.y}');
  }

  static Future<Uint8List?> _baixarESalvar(
    String url,
    String userAgent,
    File? destino,
  ) async {
    try {
      final req = await NousCachedTileProvider._httpClient
          .getUrl(Uri.parse(url))
          .timeout(const Duration(seconds: 12));
      req.headers.set('User-Agent', userAgent);
      final resp = await req.close().timeout(const Duration(seconds: 12));
      if (resp.statusCode != HttpStatus.ok) return null;
      final bytes = await consolidateHttpClientResponseBytes(resp);
      if (bytes.isEmpty) return null;
      if (destino != null) {
        try {
          await destino.writeAsBytes(bytes, flush: false);
        } catch (_) {}
      }
      return bytes;
    } catch (e) {
      RedeLoggerService.registrar(
        'MapaTileCache',
        'Falha ao baixar tile $url: $e',
        erro: true,
      );
      return null;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _NousCachedTileImage &&
        other.z == z &&
        other.x == x &&
        other.y == y &&
        other.url == url;
  }

  @override
  int get hashCode => Object.hash(url, z, x, y);
}
