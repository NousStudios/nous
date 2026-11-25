import 'dart:convert';
import 'dart:io';
import 'package:nous/src/core/services/rede_logger_service.dart';

class ResultadoCep {
  final String logradouro;
  final String cidade;
  final String uf;
  final String bairro;

  const ResultadoCep({
    required this.logradouro,
    required this.cidade,
    this.uf = '',
    this.bairro = '',
  });
}

/// Serviço leve e offline-safe para consulta de CEP brasileiro (ViaCEP com fallback BrasilAPI).
class CepService {
  CepService._();

  static final Map<String, ResultadoCep> _cache = {};

  static String normalizarDigitos(String cep) =>
      cep.replaceAll(RegExp(r'\D'), '');

  static Future<ResultadoCep?> buscar(String cep) async {
    final digitos = normalizarDigitos(cep);
    if (digitos.length != 8) return null;

    final emCache = _cache[digitos];
    if (emCache != null) return emCache;

    final viaCep = await _consultarViaCep(digitos);
    if (viaCep != null) {
      _cache[digitos] = viaCep;
      return viaCep;
    }

    final brasilApi = await _consultarBrasilApi(digitos);
    if (brasilApi != null) {
      _cache[digitos] = brasilApi;
      return brasilApi;
    }

    return null;
  }

  static Future<Map<String, dynamic>?> _getJson(String url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close().timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;
      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (e) {
      RedeLoggerService.registrar('CepService', 'Falha ao consultar $url: $e', erro: true);
      return null;
    } finally {
      client.close(force: true);
    }
  }

  static Future<ResultadoCep?> _consultarViaCep(String digitos) async {
    final json = await _getJson('https://viacep.com.br/ws/$digitos/json/');
    if (json == null || json['erro'] == true) return null;

    final logradouro = (json['logradouro'] ?? '').toString().trim();
    final cidade = (json['localidade'] ?? '').toString().trim();
    final uf = (json['uf'] ?? '').toString().trim();
    final bairro = (json['bairro'] ?? '').toString().trim();
    if (logradouro.isEmpty && cidade.isEmpty) return null;

    return ResultadoCep(
      logradouro: logradouro,
      cidade: cidade,
      uf: uf,
      bairro: bairro,
    );
  }

  static Future<ResultadoCep?> _consultarBrasilApi(String digitos) async {
    final json = await _getJson('https://brasilapi.com.br/api/cep/v1/$digitos');
    if (json == null) return null;

    final logradouro = (json['street'] ?? '').toString().trim();
    final cidade = (json['city'] ?? '').toString().trim();
    final uf = (json['state'] ?? '').toString().trim();
    final bairro = (json['neighborhood'] ?? '').toString().trim();
    if (logradouro.isEmpty && cidade.isEmpty) return null;

    return ResultadoCep(
      logradouro: logradouro,
      cidade: cidade,
      uf: uf,
      bairro: bairro,
    );
  }
}
