/// Helper especialista em resolução e montagem de URLs de rede local e nuvem.
/// Suporta de forma transparente conexões locais (HTTP/WS com porta) e conexões
/// seguras de nuvem/Cloudflare (HTTPS/WSS via TLS com ou sem porta).
class ResolvedorUrlRede {
  ResolvedorUrlRede._();

  static const List<String> _tldsPublicos = [
    '.com',
    '.br',
    '.net',
    '.org',
    '.app',
    '.io',
    '.dev',
    '.cloud',
    '.site',
    '.online',
    '.trycloudflare.com',
  ];

  /// Identifica se um determinado host ou URL representa um domínio público de internet/nuvem.
  static bool ehHostNuvem(String hostOuUrl) {
    final limpo = hostOuUrl.trim().toLowerCase();
    if (limpo.startsWith('https://') || limpo.startsWith('wss://')) {
      return true;
    }
    // Remove protocolo e porta se houver para analisar o hostname
    String host = limpo;
    if (host.contains('://')) {
      host = host.split('://').last;
    }
    if (host.contains('/')) {
      host = host.split('/').first;
    }
    if (host.contains(':')) {
      host = host.split(':').first;
    }

    // Se for localhost ou IP numérico, não é domínio de nuvem
    if (host == 'localhost' ||
        host == '127.0.0.1' ||
        RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(host)) {
      return false;
    }

    return _tldsPublicos.any((tld) => host.endsWith(tld));
  }

  /// Monta a URI HTTP/HTTPS correta para uma rota específica.
  /// Se [hostOuIp] for um domínio seguro ou começar com https://, usa HTTPS.
  /// Se for um IP de rede local, usa HTTP com a [portaPadrao] especificada.
  static Uri montarUriHttp({
    String? hostOuIp,
    int? porta,
    String? path,
    String? caminho,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? parametros,
  }) {
    String limpo = hostOuIp?.trim() ?? '';
    if (limpo.isEmpty) {
      limpo = '127.0.0.1';
    }

    final rota = path ?? caminho ?? '/';
    final pathNormalizado = rota.startsWith('/') ? rota : '/$rota';
    final ehNuvem = ehHostNuvem(limpo);
    final params = queryParameters ?? parametros;

    if (limpo.startsWith('http://') || limpo.startsWith('https://')) {
      final uriBase = Uri.parse(limpo);
      final queryFinal = params?.map((k, v) => MapEntry(k, v.toString()));
      return Uri(
        scheme: uriBase.scheme,
        host: uriBase.host,
        port: uriBase.hasPort ? uriBase.port : null,
        path: pathNormalizado,
        queryParameters: queryFinal,
      );
    }

    // Remove porta embutida no host se houver
    String hostFinal = limpo;
    int? portaFinal = porta;
    bool portaVeioNoHost = false;
    if (hostFinal.contains(':') && !hostFinal.contains('://')) {
      final partes = hostFinal.split(':');
      hostFinal = partes[0];
      final portaEmbutida = int.tryParse(partes[1]);
      if (portaEmbutida != null) {
        portaFinal = portaEmbutida;
        portaVeioNoHost = true;
      }
    }

    final queryFinal = params?.map((k, v) => MapEntry(k, v.toString()));

    if (ehNuvem) {
      final portaEfetiva = portaVeioNoHost ? portaFinal : null;
      return Uri(
        scheme: 'https',
        host: hostFinal,
        port: (portaEfetiva != null && portaEfetiva != 80 && portaEfetiva != 443)
            ? portaEfetiva
            : null,
        path: pathNormalizado,
        queryParameters: queryFinal,
      );
    } else {
      return Uri(
        scheme: 'http',
        host: hostFinal,
        port: portaFinal ?? 8080,
        path: pathNormalizado,
        queryParameters: queryFinal,
      );
    }
  }

  /// Retorna a URL HTTP/HTTPS em formato String
  static String montarUrlHttp({
    String? hostOuIp,
    int? porta,
    String? path,
    String? caminho,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? parametros,
  }) {
    return montarUriHttp(
      hostOuIp: hostOuIp,
      porta: porta,
      path: path,
      caminho: caminho,
      queryParameters: queryParameters,
      parametros: parametros,
    ).toString();
  }

  /// Monta a URL WebSocket (ws:// ou wss://) para conexão bidirecional.
  static String montarUrlWs({
    String? hostOuIp,
    int? porta,
    String? path,
    String? caminho,
  }) {
    String limpo = hostOuIp?.trim() ?? '';
    if (limpo.isEmpty) {
      limpo = '127.0.0.1';
    }

    final rota = path ?? caminho ?? '/api/ws';
    final pathNormalizado = rota.startsWith('/') ? rota : '/$rota';
    final ehNuvem = ehHostNuvem(limpo);

    if (limpo.startsWith('ws://') || limpo.startsWith('wss://')) {
      final base = limpo.endsWith('/') ? limpo.substring(0, limpo.length - 1) : limpo;
      if (base.endsWith('/api/ws')) return base;
      return '$base$pathNormalizado';
    }

    if (limpo.startsWith('http://') || limpo.startsWith('https://')) {
      final uri = Uri.parse(limpo);
      final schemeWs = uri.scheme == 'https' ? 'wss' : 'ws';
      final portStr = uri.hasPort ? ':${uri.port}' : '';
      return '$schemeWs://${uri.host}$portStr$pathNormalizado';
    }

    String hostFinal = limpo;
    int? portaFinal = porta;
    bool portaVeioNoHost = false;
    if (hostFinal.contains(':') && !hostFinal.contains('://')) {
      final partes = hostFinal.split(':');
      hostFinal = partes[0];
      final pInt = int.tryParse(partes[1]);
      if (pInt != null) {
        portaFinal = pInt;
        portaVeioNoHost = true;
      }
    }

    if (ehNuvem) {
      final portaEfetiva = portaVeioNoHost ? portaFinal : null;
      final portStr = (portaEfetiva != null && portaEfetiva != 80 && portaEfetiva != 443)
          ? ':$portaEfetiva'
          : '';
      return 'wss://$hostFinal$portStr$pathNormalizado';
    } else {
      final pFinal = portaFinal ?? 8080;
      return 'ws://$hostFinal:$pFinal$pathNormalizado';
    }
  }
}
