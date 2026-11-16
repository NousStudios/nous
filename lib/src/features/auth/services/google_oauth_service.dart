import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nous/src/core/services/preferencias_soberanas_service.dart';

class ResultadoGoogleOAuth {
  final bool sucesso;
  final String? email;
  final String? nome;
  final String? fotoUrl;
  final String? erro;
  final bool clientIdAusente;

  const ResultadoGoogleOAuth({
    required this.sucesso,
    this.email,
    this.nome,
    this.fotoUrl,
    this.erro,
    this.clientIdAusente = false,
  });
}

/// Serviço soberano de autenticação Google OAuth 2.0 (PKCE + Loopback local)
/// sem dependência de Firebase ou Google Play Services.
class GoogleOAuthService {
  GoogleOAuthService._();

  static const String chavePrefClientId = 'nous_google_oauth_client_id';
  static const String chavePrefClientSecret = 'nous_google_oauth_client_secret';
  static const String _sementeChave = 'nous_soberania_oauth2_2026_v1';

  // Credenciais padrão cifradas com AES-GCM-256 (sem texto claro no repositório).
  static const String _clientIdCifradoPadrao =
      'v1:67npM5TNstXXlgrA:b+xGTCb9J0cVCMf0wCIZP/pQoK0O0u6NFVnz3/XrF5IocBlUttUBmew7aox1PJv53W50pefKiaAXUiIME47qUl6mmaySA9Ge:KCX/teMiLl36fKgKe/ygLw==';
  static const String _clientSecretCifradoPadrao =
      'v1:wTKCBvrDgrIbPVOT:AT40A9vMyv6oeCAfJNHSHcDhBOFz6efTid7bBpghCQbtUpY=:MF4uHHQRpcKFfkQ3g/oVeg==';

  static Future<SecretKey> _obterChaveAes() async {
    final hash = await Sha256().hash(utf8.encode(_sementeChave));
    return SecretKey(hash.bytes);
  }

  static Future<String> _criptografarValor(String valorLimpo) async {
    final limpo = valorLimpo.trim();
    if (limpo.isEmpty) return '';
    final aes = AesGcm.with256bits();
    final key = await _obterChaveAes();
    final box = await aes.encrypt(utf8.encode(limpo), secretKey: key);
    return 'v1:${base64Encode(box.nonce)}:${base64Encode(box.cipherText)}:${base64Encode(box.mac.bytes)}';
  }

  static Future<String> _descriptografarValor(String payload) async {
    final bruto = payload.trim();
    if (bruto.isEmpty) return '';
    if (!bruto.startsWith('v1:')) return bruto;
    final partes = bruto.split(':');
    if (partes.length != 4) return '';
    try {
      final nonce = base64Decode(partes[1]);
      final cipherText = base64Decode(partes[2]);
      final mac = Mac(base64Decode(partes[3]));
      final aes = AesGcm.with256bits();
      final key = await _obterChaveAes();
      final bytes = await aes.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: mac),
        secretKey: key,
      );
      return utf8.decode(bytes).trim();
    } catch (e) {
      debugPrint('[GoogleOAuthService] Falha ao descriptografar credencial: $e');
      return '';
    }
  }

  static Future<String> obterClientId() async {
    final salvo = await PreferenciasSoberanasService.obterTexto(chavePrefClientId);
    if (salvo != null && salvo.trim().isNotEmpty) {
      final decifrado = await _descriptografarValor(salvo);
      if (decifrado.isNotEmpty) return decifrado;
    }
    final listaLegada =
        await PreferenciasSoberanasService.obterLista(chavePrefClientId);
    if (listaLegada.isNotEmpty && listaLegada.first.trim().isNotEmpty) {
      return _descriptografarValor(listaLegada.first.trim());
    }
    return _descriptografarValor(_clientIdCifradoPadrao);
  }

  static Future<void> salvarClientId(String clientId) async {
    final cifrado = await _criptografarValor(clientId);
    await PreferenciasSoberanasService.salvarTexto(chavePrefClientId, cifrado);
  }

  static Future<String> obterClientSecret() async {
    final salvo =
        await PreferenciasSoberanasService.obterTexto(chavePrefClientSecret);
    if (salvo != null && salvo.trim().isNotEmpty) {
      final decifrado = await _descriptografarValor(salvo);
      if (decifrado.isNotEmpty) return decifrado;
    }
    return _descriptografarValor(_clientSecretCifradoPadrao);
  }

  static Future<void> salvarClientSecret(String clientSecret) async {
    final cifrado = await _criptografarValor(clientSecret);
    await PreferenciasSoberanasService.salvarTexto(
      chavePrefClientSecret,
      cifrado,
    );
  }

  static String _gerarStringAleatoria(int tamanho) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final rand = Random.secure();
    return List.generate(tamanho, (_) => chars[rand.nextInt(chars.length)])
        .join();
  }

  static Future<String> _gerarCodeChallenge(String verifier) async {
    final bytes = utf8.encode(verifier);
    final hash = await Sha256().hash(bytes);
    return base64UrlEncode(hash.bytes).replaceAll('=', '');
  }

  /// Abre a tela oficial de escolha de conta do Google no navegador e aguarda
  /// o retorno via servidor loopback local (RFC 8252).
  static Future<ResultadoGoogleOAuth> autenticarComGoogle({
    String? clientIdOverride,
    String? clientSecretOverride,
    String? loginHint,
  }) async {
    final clientId = (clientIdOverride?.trim().isNotEmpty == true)
        ? clientIdOverride!.trim()
        : await obterClientId();
    final clientSecret = (clientSecretOverride?.trim().isNotEmpty == true)
        ? clientSecretOverride!.trim()
        : await obterClientSecret();

    if (clientId.isEmpty) {
      return const ResultadoGoogleOAuth(
        sucesso: false,
        clientIdAusente: true,
        erro:
            'Google OAuth Client ID ainda não configurado. Cole o Client ID nas configurações ou informe seu e-mail manualmente.',
      );
    }

    HttpServer? server;
    try {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final redirectUri = 'http://127.0.0.1:${server.port}/callback';

      final codeVerifier = _gerarStringAleatoria(64);
      final codeChallenge = await _gerarCodeChallenge(codeVerifier);
      final state = _gerarStringAleatoria(32);

      final hint = loginHint?.trim() ?? '';
      final authUri = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': 'openid email profile',
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'state': state,
        'prompt': 'select_account',
        if (hint.isNotEmpty) 'login_hint': hint,
      });

      final modoAbertura = Platform.isAndroid
          ? LaunchMode.inAppBrowserView
          : LaunchMode.externalApplication;
      final abriu = await launchUrl(
        authUri,
        mode: modoAbertura,
      );
      if (!abriu) {
        await server.close(force: true);
        return const ResultadoGoogleOAuth(
          sucesso: false,
          erro: 'Não foi possível abrir o navegador para autenticar com o Google.',
        );
      }

      String? code;
      String? erroOAuth;

      await for (final request in server.timeout(const Duration(minutes: 3))) {
        if (request.uri.path != '/callback') {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          continue;
        }

        final params = request.uri.queryParameters;
        final stateRecebido = params['state'];
        erroOAuth = params['error'];
        code = params['code'];

        final ok = erroOAuth == null && code != null && stateRecebido == state;
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.html;
        request.response.write(_paginaRetornoHtml(sucesso: ok));
        await request.response.close();

        if (!ok && erroOAuth == null) {
          erroOAuth = 'Validação de segurança (state) falhou.';
        }
        break;
      }

      await server.close(force: true);
      server = null;

      if (erroOAuth != null || code == null) {
        return ResultadoGoogleOAuth(
          sucesso: false,
          erro: erroOAuth == 'access_denied'
              ? 'Autenticação cancelada pelo usuário.'
              : 'Falha na autenticação Google: ${erroOAuth ?? "código ausente"}',
        );
      }

      final accessToken = await _trocarCodePorToken(
        clientId: clientId,
        clientSecret: clientSecret,
        code: code,
        codeVerifier: codeVerifier,
        redirectUri: redirectUri,
      );

      if (accessToken == null || accessToken.isEmpty) {
        return const ResultadoGoogleOAuth(
          sucesso: false,
          erro: 'Não foi possível validar o token retornado pelo Google.',
        );
      }

      final userInfo = await _buscarUserInfo(accessToken);
      final email = userInfo?['email']?.toString().trim() ?? '';
      if (email.isEmpty) {
        return const ResultadoGoogleOAuth(
          sucesso: false,
          erro: 'O Google não retornou um endereço de e-mail válido.',
        );
      }

      return ResultadoGoogleOAuth(
        sucesso: true,
        email: email,
        nome: userInfo?['name']?.toString(),
        fotoUrl: userInfo?['picture']?.toString(),
      );
    } on TimeoutException {
      return const ResultadoGoogleOAuth(
        sucesso: false,
        erro: 'Tempo esgotado aguardando o retorno do navegador.',
      );
    } catch (e) {
      debugPrint('[GoogleOAuthService] Erro: $e');
      return ResultadoGoogleOAuth(
        sucesso: false,
        erro: 'Erro ao autenticar com o Google: $e',
      );
    } finally {
      try {
        await server?.close(force: true);
      } catch (_) {}
    }
  }

  static Future<String?> _trocarCodePorToken({
    required String clientId,
    required String clientSecret,
    required String code,
    required String codeVerifier,
    required String redirectUri,
  }) async {
    final client = HttpClient();
    try {
      final req = await client.postUrl(
        Uri.parse('https://oauth2.googleapis.com/token'),
      );
      req.headers.contentType = ContentType(
        'application',
        'x-www-form-urlencoded',
        charset: 'utf-8',
      );
      final params = <String, String>{
        'client_id': clientId,
        if (clientSecret.isNotEmpty) 'client_secret': clientSecret,
        'code': code,
        'code_verifier': codeVerifier,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
      };
      final body = Uri(queryParameters: params).query;
      req.write(body);

      final res = await req.close();
      final texto = await utf8.decodeStream(res);
      if (res.statusCode != HttpStatus.ok) {
        debugPrint('[GoogleOAuthService] Token HTTP ${res.statusCode}: $texto');
        return null;
      }
      final json = jsonDecode(texto) as Map<String, dynamic>;
      return json['access_token']?.toString();
    } finally {
      client.close(force: true);
    }
  }

  static Future<Map<String, dynamic>?> _buscarUserInfo(
    String accessToken,
  ) async {
    final client = HttpClient();
    try {
      final req = await client.getUrl(
        Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
      );
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
      final res = await req.close();
      final texto = await utf8.decodeStream(res);
      if (res.statusCode != HttpStatus.ok) {
        return null;
      }
      return jsonDecode(texto) as Map<String, dynamic>;
    } finally {
      client.close(force: true);
    }
  }

  static String _paginaRetornoHtml({required bool sucesso}) {
    final titulo = sucesso ? 'Autenticação concluída!' : 'Falha na autenticação';
    final msg = sucesso
        ? 'Sua conta Google foi verificada com sucesso. Você já pode fechar esta aba e voltar para o Nous.'
        : 'Não foi possível concluir o login. Volte ao Nous e tente novamente.';
    return '''
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8" />
  <title>Nous - $titulo</title>
  <style>
    body { font-family: sans-serif; background: #121212; color: #f5f5f5; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
    .card { background: #1e1e1e; border: 1px solid #333; border-radius: 16px; padding: 32px; max-width: 420px; text-align: center; }
    h2 { margin-top: 0; }
    p { color: #ccc; line-height: 1.5; }
  </style>
</head>
<body>
  <div class="card">
    <h2>$titulo</h2>
    <p>$msg</p>
  </div>
</body>
</html>
''';
  }
}
