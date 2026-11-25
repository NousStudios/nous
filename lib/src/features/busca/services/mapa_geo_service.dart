import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/features/busca/models/resultado_rota_mapa.dart';

class EnderecoGeocodificado {
  final String titulo;
  final String subtitulo;
  final LatLng coordenada;

  const EnderecoGeocodificado({
    required this.titulo,
    required this.subtitulo,
    required this.coordenada,
  });
}

/// Serviço soberano de geolocalização, geocodificação (Nominatim + cache SQLite)
/// e cálculo de rotas abertas (OSRM) para o mapa do Nous.
class MapaGeoService {
  MapaGeoService._();

  static const LatLng coordenadaPadraoBrasil = LatLng(-23.55052, -46.633308);
  static const Distance _distance = Distance();
  static bool _tabelaGarantida = false;

  static Future<Database> _db() async {
    final db = await BancoDadosService.db;
    if (!_tabelaGarantida) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS mapa_geocache (
          chave TEXT PRIMARY KEY,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          resumo TEXT NOT NULL DEFAULT '',
          atualizado_em TEXT NOT NULL
        );
      ''');
      _tabelaGarantida = true;
    }
    return db;
  }

  static double distanciaMetros(LatLng a, LatLng b) {
    return _distance.as(LengthUnit.Meter, a, b);
  }

  static String formatarDistancia(double metros) {
    if (metros >= 1000) {
      return '${(metros / 1000).toStringAsFixed(1)} km';
    }
    return '${metros.round()} m';
  }

  /// Obtém a posição GPS real do aparelho com tratamento seguro de permissões.
  static Future<LatLng?> obterPosicaoAtual() async {
    try {
      final servicoAtivo = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 3), onTimeout: () => false);
      if (!servicoAtivo) return null;

      var permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }
      if (permissao == LocationPermission.denied ||
          permissao == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 6),
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint('[MapaGeoService] GPS indisponível: $e');
      return null;
    }
  }

  /// Converte coordenada em resumo "Rua, Bairro, Cidade" (com cache local SQLite).
  static Future<String> obterEnderecoResumo(LatLng pos) async {
    final chave =
        'rev_${pos.latitude.toStringAsFixed(4)}_${pos.longitude.toStringAsFixed(4)}';
    try {
      final db = await _db();
      final rows = await db.query(
        'mapa_geocache',
        where: 'chave = ?',
        whereArgs: [chave],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final resumo = (rows.first['resumo'] as String? ?? '').trim();
        if (resumo.isNotEmpty) return resumo;
      }
    } catch (_) {}

    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': pos.latitude.toString(),
        'lon': pos.longitude.toString(),
        'accept-language': 'pt-BR',
      });
      final req = await client.getUrl(uri);
      req.headers.set('User-Agent', 'NousSuperApp/1.1');
      final resp = await req.close();
      if (resp.statusCode == HttpStatus.ok) {
        final body = await utf8.decodeStream(resp);
        final json = jsonDecode(body) as Map<String, dynamic>;
        final addr = json['address'] as Map<String, dynamic>? ?? const {};
        final rua = (addr['road'] ??
                addr['pedestrian'] ??
                addr['square'] ??
                addr['suburb'] ??
                '')
            .toString()
            .trim();
        final bairro = (addr['suburb'] ??
                addr['neighbourhood'] ??
                addr['city_district'] ??
                '')
            .toString()
            .trim();
        final cidade = (addr['city'] ??
                addr['town'] ??
                addr['village'] ??
                addr['municipality'] ??
                '')
            .toString()
            .trim();
        final partes = <String>[
          if (rua.isNotEmpty) rua,
          if (bairro.isNotEmpty && bairro != rua) bairro,
          if (cidade.isNotEmpty) cidade,
        ];
        final resumo = partes.isNotEmpty
            ? partes.join(', ')
            : (json['display_name']?.toString().split(',').take(3).join(',') ??
                'Localização atual');

        try {
          final db = await _db();
          await db.insert(
            'mapa_geocache',
            {
              'chave': chave,
              'latitude': pos.latitude,
              'longitude': pos.longitude,
              'resumo': resumo,
              'atualizado_em': DateTime.now().toIso8601String(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } catch (_) {}
        return resumo;
      }
    } catch (e) {
      debugPrint('[MapaGeoService] Erro reverse geocoding: $e');
    } finally {
      client?.close(force: true);
    }
    return 'Rua, Bairro, Cidade';
  }

  /// Geocodifica um endereço de loja/local com cache persistente em SQLite.
  static Future<LatLng?> geocodificarEndereco(
    String enderecoBruto, {
    LatLng? referencia,
    String? cidadeFallback,
  }) async {
    final limpo = enderecoBruto.trim();
    if (limpo.isEmpty) return null;
    final chave =
        'fwd2_${limpo.toLowerCase()}_${(cidadeFallback ?? '').toLowerCase()}';

    try {
      final db = await _db();
      final rows = await db.query(
        'mapa_geocache',
        where: 'chave = ?',
        whereArgs: [chave],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final lat = (rows.first['latitude'] as num?)?.toDouble();
        final lon = (rows.first['longitude'] as num?)?.toDouble();
        if (lat != null && lon != null) return LatLng(lat, lon);
      }
    } catch (_) {}

    final matchCepInicial = RegExp(r'\b(\d{5})-?(\d{3})\b').firstMatch(limpo);
    final dadosCep = matchCepInicial != null
        ? await _consultarAwesomeApiCep(
            '${matchCepInicial.group(1)}${matchCepInicial.group(2)}',
          )
        : null;

    final cidadeEfetiva = (cidadeFallback?.trim().isNotEmpty ?? false)
        ? cidadeFallback!.trim()
        : (dadosCep?.cidade.isNotEmpty ?? false ? dadosCep!.cidade : null);
    final refEfetiva = dadosCep?.coordenada ?? referencia;

    var consultaPrincipal = limpo;
    if (dadosCep != null &&
        dadosCep.bairro.isNotEmpty &&
        !limpo.toLowerCase().contains(dadosCep.bairro.toLowerCase())) {
      consultaPrincipal = '$limpo, ${dadosCep.bairro}';
    }

    final resultados = await buscarEnderecos(
      consultaPrincipal,
      limite: 3,
      referencia: refEfetiva,
      cidadeReferencia: cidadeEfetiva,
    );
    LatLng? coord =
        resultados.isNotEmpty ? resultados.first.coordenada : null;
    String tituloCache =
        resultados.isNotEmpty ? resultados.first.titulo : limpo;

    // Quando temos coordenada oficial do CEP (AwesomeAPI), evita cair em outro
    // bairro/trecho distante da mesma rua quando o OSM não tem número de porta.
    if (dadosCep?.coordenada != null) {
      final coordCep = dadosCep!.coordenada!;
      if (coord == null) {
        coord = coordCep;
        tituloCache = dadosCep.rua.isNotEmpty
            ? '${dadosCep.rua}, ${dadosCep.bairro}'
            : limpo;
      } else {
        final distParaCep = distanciaMetros(coord, coordCep);
        final textoRes =
            '${resultados.first.titulo} ${resultados.first.subtitulo}'
                .toLowerCase();
        final bateBairro = dadosCep.bairro.isNotEmpty &&
            textoRes.contains(dadosCep.bairro.toLowerCase());
        if (distParaCep > 500 && !bateBairro) {
          coord = coordCep;
          tituloCache = dadosCep.rua.isNotEmpty
              ? '${dadosCep.rua}, ${dadosCep.bairro}'
              : limpo;
        }
      }
    }

    // Fallback inteligente: remove número, traço de bairro ou usa CEP/cidade
    if (coord == null) {
      final matchCep = RegExp(r'\b(\d{5})-?(\d{3})\b').firstMatch(limpo);
      final semNumero = limpo
          .replaceAll(RegExp(r'\bcep\b[:\s]*', caseSensitive: false), '')
          .replaceAll(RegExp(r',\s*\d+[a-zA-Z]?\b'), '')
          .replaceAll(RegExp(r'\s+-\s+.*$'), '')
          .trim();
      final resSemNum = await buscarEnderecos(
        semNumero.isNotEmpty ? semNumero : limpo,
        limite: 1,
        referencia: refEfetiva,
        cidadeReferencia: cidadeEfetiva,
      );
      if (resSemNum.isNotEmpty) {
        coord = resSemNum.first.coordenada;
        tituloCache = resSemNum.first.titulo;
      } else if (matchCep != null) {
        final cepFormatado = '${matchCep.group(1)}-${matchCep.group(2)}';
        final resCep = await buscarPorCep(cepFormatado);
        if (resCep != null) {
          coord = resCep.coordenada;
          tituloCache = resCep.titulo;
        }
      } else {
        // Último fallback: tenta apenas o primeiro trecho antes da vírgula na cidade atual
        final primeiraParte = limpo.split(',').first.split(' - ').first.trim();
        if (primeiraParte.length >= 3) {
          final resParte = await buscarEnderecos(
            primeiraParte,
            limite: 1,
            referencia: refEfetiva,
            cidadeReferencia: cidadeEfetiva,
          );
          if (resParte.isNotEmpty) {
            coord = resParte.first.coordenada;
            tituloCache = resParte.first.titulo;
          }
        }
      }
    }

    if (coord == null) return null;

    try {
      final db = await _db();
      await db.insert(
        'mapa_geocache',
        {
          'chave': chave,
          'latitude': coord.latitude,
          'longitude': coord.longitude,
          'resumo': tituloCache,
          'atualizado_em': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}

    return coord;
  }

  static Future<
      ({
        LatLng? coordenada,
        String rua,
        String bairro,
        String cidade,
        String uf,
      })?> _consultarAwesomeApiCep(String cepDigitos) async {
    if (cepDigitos.length != 8) return null;
    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final uri = Uri.https('cep.awesomeapi.com.br', '/json/$cepDigitos');
      final req = await client.getUrl(uri);
      req.headers.set('User-Agent', 'NousSuperApp/1.1');
      final resp = await req.close().timeout(const Duration(seconds: 4));
      if (resp.statusCode != HttpStatus.ok) return null;
      final body = await utf8.decodeStream(resp);
      final map = jsonDecode(body);
      if (map is! Map<String, dynamic>) return null;
      final lat = double.tryParse(map['lat']?.toString() ?? '');
      final lon = double.tryParse(map['lng']?.toString() ?? '');
      final rua = (map['address'] as String? ?? '').trim();
      final bairro = (map['district'] as String? ?? '').trim();
      final cidade = (map['city'] as String? ?? '').trim();
      final uf = (map['state'] as String? ?? '').trim();
      return (
        coordenada: (lat != null && lon != null) ? LatLng(lat, lon) : null,
        rua: rua,
        bairro: bairro,
        cidade: cidade,
        uf: uf,
      );
    } catch (_) {
      return null;
    } finally {
      client?.close(force: true);
    }
  }

  static Future<EnderecoGeocodificado?> buscarPorCep(String cep) async {
    final cepDigitos = cep.replaceAll(RegExp(r'\D'), '');
    if (cepDigitos.length == 8) {
      final awesome = await _consultarAwesomeApiCep(cepDigitos);
      if (awesome?.coordenada != null) {
        final titulo = [awesome!.rua, awesome.bairro]
            .where((e) => e.isNotEmpty)
            .join(', ');
        final local = [awesome.cidade, awesome.uf]
            .where((e) => e.isNotEmpty)
            .join(' - ');
        return EnderecoGeocodificado(
          titulo: titulo.isNotEmpty ? titulo : cep,
          subtitulo: local.isNotEmpty ? '$local • $cep' : cep,
          coordenada: awesome.coordenada!,
        );
      }
    }

    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'postalcode': cep,
        'countrycodes': 'br',
        'format': 'jsonv2',
        'limit': '1',
        'accept-language': 'pt-BR',
      });
      final req = await client.getUrl(uri);
      req.headers.set('User-Agent', 'NousSuperApp/1.1');
      final resp = await req.close();
      if (resp.statusCode != HttpStatus.ok) return null;
      final body = await utf8.decodeStream(resp);
      final lista = jsonDecode(body) as List<dynamic>;
      if (lista.isEmpty) return null;
      final map = lista.first as Map<String, dynamic>;
      final lat = double.tryParse(map['lat']?.toString() ?? '');
      final lon = double.tryParse(map['lon']?.toString() ?? '');
      if (lat == null || lon == null) return null;
      return EnderecoGeocodificado(
        titulo: (map['display_name'] as String? ?? cep).split(',').take(2).join(', '),
        subtitulo: cep,
        coordenada: LatLng(lat, lon),
      );
    } catch (_) {
      return null;
    } finally {
      client?.close(force: true);
    }
  }

  /// Extrai provável cidade a partir de um resumo "Rua, Bairro, Cidade".
  static String? extrairCidadeDeResumo(String resumo) {
    final partes = resumo
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (partes.isEmpty) return null;
    final ultima = partes.last;
    if (ultima.toLowerCase() == 'cidade' ||
        ultima.toLowerCase() == 'localização atual') {
      return null;
    }
    return ultima;
  }

  /// Busca endereços e pontos de referência via Nominatim (OpenStreetMap),
  /// priorizando a cidade e proximidade geográfica do usuário.
  static Future<List<EnderecoGeocodificado>> buscarEnderecos(
    String consulta, {
    int limite = 8,
    LatLng? referencia,
    String? cidadeReferencia,
  }) async {
    final termo = consulta.trim();
    if (termo.length < 2) return const [];

    final cidade = cidadeReferencia?.trim();
    final temCidadeNoTermo = cidade != null &&
        cidade.isNotEmpty &&
        termo.toLowerCase().contains(cidade.toLowerCase());

    Future<List<EnderecoGeocodificado>> consultarNominatim(
      String q, {
      required bool usarViewbox,
    }) async {
      HttpClient? client;
      try {
        client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
        final params = <String, String>{
          'q': q,
          'format': 'jsonv2',
          'limit': '$limite',
          'countrycodes': 'br',
          'accept-language': 'pt-BR',
          'addressdetails': '1',
        };
        if (usarViewbox && referencia != null) {
          const delta = 0.45;
          final left = (referencia.longitude - delta).toStringAsFixed(5);
          final right = (referencia.longitude + delta).toStringAsFixed(5);
          final top = (referencia.latitude + delta).toStringAsFixed(5);
          final bottom = (referencia.latitude - delta).toStringAsFixed(5);
          params['viewbox'] = '$left,$top,$right,$bottom';
          params['bounded'] = '0';
        }
        final uri = Uri.https('nominatim.openstreetmap.org', '/search', params);
        final req = await client.getUrl(uri);
        req.headers.set('User-Agent', 'NousSuperApp/1.1');
        final resp = await req.close();
        if (resp.statusCode != HttpStatus.ok) return const [];

        final body = await utf8.decodeStream(resp);
        final lista = jsonDecode(body) as List<dynamic>;
        return lista.map((item) {
          final map = item as Map<String, dynamic>;
          final display = (map['display_name'] as String? ?? '').trim();
          final nome = (map['name'] as String? ?? '').trim();
          final partes = display.split(',').map((e) => e.trim()).toList();
          final tituloBase = partes.take(2).join(', ');
          final titulo = nome.isNotEmpty && !tituloBase.startsWith(nome)
              ? '$nome — $tituloBase'
              : (tituloBase.isNotEmpty ? tituloBase : display);
          final subtitulo = partes.skip(2).take(3).join(', ');
          final lat = double.tryParse(map['lat']?.toString() ?? '') ?? 0.0;
          final lon = double.tryParse(map['lon']?.toString() ?? '') ?? 0.0;
          return EnderecoGeocodificado(
            titulo: titulo,
            subtitulo: subtitulo,
            coordenada: LatLng(lat, lon),
          );
        }).toList();
      } catch (e) {
        debugPrint('[MapaGeoService] Erro buscarEnderecos: $e');
        return const [];
      } finally {
        client?.close(force: true);
      }
    }

    final combinados = <EnderecoGeocodificado>[];

    // 1. Busca fuzzy + POIs via Photon (OpenStreetMap/Komoot) tolerante a erros de digitação
    final photonLocais = await _consultarPhoton(
      cidade != null && cidade.isNotEmpty && !temCidadeNoTermo
          ? '$termo, $cidade'
          : termo,
      limite: limite,
      referencia: referencia,
    );
    combinados.addAll(photonLocais);

    if (combinados.length < 3 &&
        cidade != null &&
        cidade.isNotEmpty &&
        !temCidadeNoTermo) {
      final photonGeral = await _consultarPhoton(
        termo,
        limite: limite,
        referencia: referencia,
      );
      for (final item in photonGeral) {
        final jaExiste = combinados.any(
          (e) => distanciaMetros(e.coordenada, item.coordenada) < 40,
        );
        if (!jaExiste) combinados.add(item);
      }
    }

    // 2. Complementa com Nominatim para precisão por número de porta e CEP
    if (cidade != null && cidade.isNotEmpty && !temCidadeNoTermo) {
      final locais = await consultarNominatim(
        '$termo, $cidade',
        usarViewbox: true,
      );
      for (final item in locais) {
        final jaExiste = combinados.any(
          (e) => distanciaMetros(e.coordenada, item.coordenada) < 40,
        );
        if (!jaExiste) combinados.add(item);
      }
    }

    if (combinados.length < 4) {
      final gerais = await consultarNominatim(termo, usarViewbox: true);
      for (final item in gerais) {
        final jaExiste = combinados.any(
          (e) => distanciaMetros(e.coordenada, item.coordenada) < 40,
        );
        if (!jaExiste) combinados.add(item);
      }
    }

    if (referencia != null && combinados.length > 1) {
      final cidadeLow = cidade?.toLowerCase() ?? '';
      combinados.sort((a, b) {
        final aNaCidade = cidadeLow.isNotEmpty &&
            ('${a.titulo} ${a.subtitulo}').toLowerCase().contains(cidadeLow);
        final bNaCidade = cidadeLow.isNotEmpty &&
            ('${b.titulo} ${b.subtitulo}').toLowerCase().contains(cidadeLow);
        if (aNaCidade != bNaCidade) return aNaCidade ? -1 : 1;
        final da = distanciaMetros(referencia, a.coordenada);
        final db = distanciaMetros(referencia, b.coordenada);
        return da.compareTo(db);
      });
    }

    // Evita que buscas fuzzy externas devolvam endereços sem nenhuma relação
    // com o termo digitado/falado (ex.: buscar "Laricas" e vir ruas aleatórias).
    final tokens = termo
        .toLowerCase()
        .split(RegExp(r'[\s,.-]+'))
        .where((t) => t.length >= 3)
        .toList();
    final filtrados = tokens.isEmpty
        ? combinados
        : combinados.where((item) {
            final texto = '${item.titulo} ${item.subtitulo}'.toLowerCase();
            return tokens.any((t) => texto.contains(t));
          }).toList();

    return filtrados.take(limite).toList();
  }

  /// Consulta a API aberta Photon (base OpenStreetMap) com suporte a busca aproximada (fuzzy) e POIs.
  static Future<List<EnderecoGeocodificado>> _consultarPhoton(
    String q, {
    required int limite,
    LatLng? referencia,
  }) async {
    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
      final params = <String, String>{
        'q': q,
        'limit': '$limite',
        if (referencia != null) 'lat': referencia.latitude.toString(),
        if (referencia != null) 'lon': referencia.longitude.toString(),
      };
      final uri = Uri.https('photon.komoot.io', '/api', params);
      final req = await client.getUrl(uri);
      req.headers.set('User-Agent', 'NousSuperApp/1.1');
      final resp = await req.close();
      if (resp.statusCode != HttpStatus.ok) return const [];

      final body = await utf8.decodeStream(resp);
      final json = jsonDecode(body) as Map<String, dynamic>;
      final features = json['features'] as List<dynamic>? ?? const [];

      final lista = <EnderecoGeocodificado>[];
      for (final f in features) {
        final feat = f as Map<String, dynamic>;
        final geom = feat['geometry'] as Map<String, dynamic>? ?? const {};
        final coords = geom['coordinates'] as List<dynamic>? ?? const [];
        if (coords.length < 2) continue;
        final lon = (coords[0] as num).toDouble();
        final lat = (coords[1] as num).toDouble();

        final props = feat['properties'] as Map<String, dynamic>? ?? const {};
        final countryCode =
            (props['countrycode'] as String? ?? '').toUpperCase();
        if (countryCode.isNotEmpty && countryCode != 'BR') continue;

        final nome = (props['name'] as String? ?? '').trim();
        final rua = (props['street'] as String? ?? '').trim();
        final numCasa = (props['housenumber'] as String? ?? '').trim();
        final bairro = (props['district'] as String? ??
                props['locality'] as String? ??
                '')
            .trim();
        final cidade = (props['city'] as String? ?? '').trim();
        final estado = (props['state'] as String? ?? '').trim();

        final ruaNum = [rua, numCasa].where((e) => e.isNotEmpty).join(', ');
        final titulo = nome.isNotEmpty
            ? (ruaNum.isNotEmpty && !nome.contains(rua)
                ? '$nome — $ruaNum'
                : nome)
            : (ruaNum.isNotEmpty ? ruaNum : cidade);
        if (titulo.isEmpty) continue;

        final subtitulo = [bairro, cidade, estado]
            .where((e) => e.isNotEmpty)
            .join(', ');

        lista.add(
          EnderecoGeocodificado(
            titulo: titulo,
            subtitulo: subtitulo,
            coordenada: LatLng(lat, lon),
          ),
        );
      }
      return lista;
    } catch (e) {
      debugPrint('[MapaGeoService] Erro Photon: $e');
      return const [];
    } finally {
      client?.close(force: true);
    }
  }

  /// Calcula rota entre origem e destino usando OSRM aberto (com passos reais e fallback offline).
  static Future<ResultadoRotaMapa> calcularRota({
    required LatLng origem,
    required LatLng destino,
    required String origemLabel,
    required String destinoLabel,
  }) async {
    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
      final coords =
          '${origem.longitude},${origem.latitude};${destino.longitude},${destino.latitude}';
      final uri = Uri.https(
        'router.project-osrm.org',
        '/route/v1/driving/$coords',
        {
          'overview': 'full',
          'geometries': 'geojson',
          'steps': 'true',
        },
      );
      final req = await client.getUrl(uri);
      req.headers.set('User-Agent', 'NousSuperApp/1.1');
      final resp = await req.close();
      if (resp.statusCode == HttpStatus.ok) {
        final body = await utf8.decodeStream(resp);
        final json = jsonDecode(body) as Map<String, dynamic>;
        final routes = json['routes'] as List<dynamic>? ?? const [];
        if (routes.isNotEmpty) {
          final rota = routes.first as Map<String, dynamic>;
          final geom = rota['geometry'] as Map<String, dynamic>? ?? const {};
          final rawCoords = geom['coordinates'] as List<dynamic>? ?? const [];
          final pontos = rawCoords
              .map((c) {
                final par = c as List<dynamic>;
                return LatLng(
                  (par[1] as num).toDouble(),
                  (par[0] as num).toDouble(),
                );
              })
              .toList();

          final passos = <PassoRotaMapa>[];
          final legs = rota['legs'] as List<dynamic>? ?? const [];
          if (legs.isNotEmpty) {
            final rawSteps =
                (legs.first as Map<String, dynamic>)['steps'] as List<dynamic>? ??
                    const [];
            for (final st in rawSteps) {
              final step = st as Map<String, dynamic>;
              final nomeRua = (step['name'] as String? ?? '').trim();
              final dist = (step['distance'] as num?)?.toDouble() ?? 0.0;
              final manobra =
                  step['maneuver'] as Map<String, dynamic>? ?? const {};
              final tipo = (manobra['type'] as String? ?? '').trim();
              final mod = (manobra['modifier'] as String? ?? '').trim();
              final locRaw = manobra['location'] as List<dynamic>?;
              final coordManobra = (locRaw != null && locRaw.length >= 2)
                  ? LatLng(
                      (locRaw[1] as num).toDouble(),
                      (locRaw[0] as num).toDouble(),
                    )
                  : null;
              passos.add(
                PassoRotaMapa(
                  instrucao: _traduzirManobraOsrm(tipo, mod, nomeRua),
                  distanciaMetros: dist,
                  nomeRua: nomeRua,
                  coordenada: coordManobra,
                ),
              );
            }
          }

          if (pontos.length >= 2) {
            return ResultadoRotaMapa(
              pontos: pontos,
              distanciaMetros: (rota['distance'] as num?)?.toDouble() ??
                  distanciaMetros(origem, destino),
              duracaoSegundos: (rota['duration'] as num?)?.toDouble() ?? 60.0,
              origemLabel: origemLabel,
              destinoLabel: destinoLabel,
              passos: passos,
              ehRotaRealOnline: true,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[MapaGeoService] Erro OSRM: $e');
    } finally {
      client?.close(force: true);
    }

    final dist = distanciaMetros(origem, destino);
    return ResultadoRotaMapa(
      pontos: [origem, destino],
      distanciaMetros: dist,
      duracaoSegundos: (dist / 8.3).clamp(60.0, 36000.0),
      origemLabel: origemLabel,
      destinoLabel: destinoLabel,
      ehRotaRealOnline: false,
    );
  }

  static String _traduzirManobraOsrm(
    String tipo,
    String modificador,
    String rua,
  ) {
    final destinoRua = rua.isNotEmpty ? ' em $rua' : '';
    if (tipo == 'arrive') return 'Você chegou ao destino';
    if (tipo == 'depart') return 'Siga${rua.isNotEmpty ? ' pela $rua' : ''}';
    if (tipo == 'roundabout' || tipo == 'rotary') {
      return 'Na rotatória, pegue a saída$destinoRua';
    }
    switch (modificador) {
      case 'left':
        return 'Vire à esquerda$destinoRua';
      case 'slight left':
        return 'Mantenha-se à esquerda$destinoRua';
      case 'sharp left':
        return 'Vire acentuadamente à esquerda$destinoRua';
      case 'right':
        return 'Vire à direita$destinoRua';
      case 'slight right':
        return 'Mantenha-se à direita$destinoRua';
      case 'sharp right':
        return 'Vire acentuadamente à direita$destinoRua';
      case 'uturn':
        return 'Faça o retorno$destinoRua';
      default:
        return 'Siga em frente$destinoRua';
    }
  }
}
