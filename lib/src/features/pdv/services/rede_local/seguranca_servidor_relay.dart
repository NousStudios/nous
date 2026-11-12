import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Guarda de segurança, limitação de taxa (Rate Limiting) e blindagem contra DoS
/// para o Servidor Relay local do Nous quando exposto na rede ou via túnel seguro.
class SegurancaServidorRelay {
  SegurancaServidorRelay._();

  // Teto de tamanho seguro para payloads
  static const int limiteBytesHttpGeral = 2 * 1024 * 1024; // 2 MB
  static const int limiteBytesUploadMidia = 15 * 1024 * 1024; // 15 MB
  static const int limiteBytesMensagemWs = 2 * 1024 * 1024; // 2 MB

  // Parâmetros de Rate Limiting
  static const int maxRequisicoesPorJanelaHttp = 50; // max 50 reqs em 2s por IP
  static const int janelaHttpMs = 2000;
  static const int maxMensagensPorSegundoWs = 35; // max 35 msgs/s por WebSocket
  static const int tempoBloqueioMs = 15000; // 15s de cooldown para IP abusivo

  // Rastreamento em memória por IP
  static final Map<String, List<int>> _historicoHttpPorIp = {};
  static final Map<String, int> _bloqueiosHttpPorIp = {};
  static final Map<String, List<int>> _historicoWsPorIp = {};

  /// Aplica cabeçalhos defensivos do padrão Nous Sovereign Relay
  static void aplicarHeadersSeguranca(HttpResponse response) {
    try {
      response.headers.set('X-Content-Type-Options', 'nosniff');
      response.headers.set('X-Frame-Options', 'DENY');
      response.headers.set('X-XSS-Protection', '1; mode=block');
      response.headers.set('Server', 'Nous-Sovereign-Relay');
    } catch (_) {}
  }

  /// Extrai o IP de origem confiável considerando headers de proxy/túnel (ex: CF-Connecting-IP, X-Forwarded-For)
  static String extrairIpOrigem(HttpRequest request) {
    try {
      final cfIp = request.headers.value('cf-connecting-ip');
      if (cfIp != null && cfIp.trim().isNotEmpty) {
        return cfIp.trim();
      }
      final xForwarded = request.headers.value('x-forwarded-for');
      if (xForwarded != null && xForwarded.trim().isNotEmpty) {
        return xForwarded.split(',').first.trim();
      }
      return request.connectionInfo?.remoteAddress.address ?? '127.0.0.1';
    } catch (_) {
      return '127.0.0.1';
    }
  }

  /// Valida taxa de requisição e tamanho de payload HTTP.
  /// Retorna true se a requisição pode prosseguir; se for bloqueada, responde com 429 ou 413 e retorna false.
  static bool verificarRequisicaoHttpPermitida(HttpRequest request) {
    final ip = extrairIpOrigem(request);
    final agora = DateTime.now().millisecondsSinceEpoch;

    // 1. Verifica se o IP está em período de cooldown/bloqueio temporário
    final bloqueadoAte = _bloqueiosHttpPorIp[ip];
    if (bloqueadoAte != null) {
      if (agora < bloqueadoAte) {
        final restanteSegundos = ((bloqueadoAte - agora) / 1000).ceil();
        _responderErro(
          request,
          statusCode: HttpStatus.tooManyRequests,
          mensagem:
              'Controle de tráfego ativado. Tente novamente em $restanteSegundos segundos.',
        );
        return false;
      } else {
        _bloqueiosHttpPorIp.remove(ip);
      }
    }

    // 2. Teto de tamanho do Payload HTTP (Content-Length)
    final path = request.uri.path;
    final ehUploadMidia = path.contains('/upload_midia') || path.contains('/upload_arquivo');
    final limitePermitido = ehUploadMidia ? limiteBytesUploadMidia : limiteBytesHttpGeral;

    if (request.contentLength > limitePermitido) {
      debugPrint(
        '[SegurancaServidorRelay] Payload HTTP rejeitado ($ip): ${request.contentLength} bytes excede limite de $limitePermitido bytes.',
      );
      _responderErro(
        request,
        statusCode: HttpStatus.requestEntityTooLarge,
        mensagem: 'Tamanho da carga excede o limite soberano permitido.',
      );
      return false;
    }

    // 3. Rate limiting por janela deslizante
    final historico = _historicoHttpPorIp.putIfAbsent(ip, () => []);
    historico.removeWhere((timestamp) => agora - timestamp > janelaHttpMs);
    historico.add(agora);

    if (historico.length > maxRequisicoesPorJanelaHttp) {
      _bloqueiosHttpPorIp[ip] = agora + tempoBloqueioMs;
      debugPrint(
        '[SegurancaServidorRelay] IP $ip excedeu o limite de requisições HTTP (${historico.length} reqs em ${janelaHttpMs}ms). Cooldown de 15s ativado.',
      );
      _responderErro(
        request,
        statusCode: HttpStatus.tooManyRequests,
        mensagem:
            'Limite de requisições excedido. Tráfego temporariamente contido.',
      );
      return false;
    }

    // Limpeza periódica do mapa para evitar vazamento de memória
    if (_historicoHttpPorIp.length > 500) {
      _historicoHttpPorIp.removeWhere(
        (_, lista) => lista.isEmpty || (agora - lista.last > 30000),
      );
    }

    return true;
  }

  /// Valida taxa e tamanho de mensagens WebSocket recebidas
  static bool verificarMensagemWsPermitida(
    WebSocket? ws,
    String ipRemoto,
    dynamic msg,
  ) {
    final agora = DateTime.now().millisecondsSinceEpoch;

    // 1. Verificação de tamanho máximo do frame WebSocket
    if (msg is String) {
      if (msg.length > limiteBytesMensagemWs) {
        debugPrint(
          '[SegurancaServidorRelay] Mensagem WS descartada de $ipRemoto: tamanho em caracteres (${msg.length}) excede o teto.',
        );
        return false;
      }
    } else if (msg is List<int>) {
      if (msg.length > limiteBytesMensagemWs) {
        debugPrint(
          '[SegurancaServidorRelay] Pacote binário WS descartado de $ipRemoto: tamanho (${msg.length} bytes) excede o teto.',
        );
        return false;
      }
    }

    // 2. Rate Limiting de mensagens WebSocket por segundo
    final historico = _historicoWsPorIp.putIfAbsent(ipRemoto, () => []);
    historico.removeWhere((timestamp) => agora - timestamp > 1000);
    historico.add(agora);

    if (historico.length > maxMensagensPorSegundoWs) {
      debugPrint(
        '[SegurancaServidorRelay] Flood de mensagens WS detectado do IP $ipRemoto (${historico.length} msgs/s). Pacote descartado.',
      );
      return false;
    }

    // Limpeza periódica
    if (_historicoWsPorIp.length > 500) {
      _historicoWsPorIp.removeWhere(
        (_, lista) => lista.isEmpty || (agora - lista.last > 30000),
      );
    }

    return true;
  }

  /// Extensões estritamente proibidas para leitura ou download pelo servidor relay
  static const Set<String> _extensoesProibidas = {
    '.db',
    '.db-shm',
    '.db-wal',
    '.sqlite',
    '.sqlite3',
    '.key',
    '.pem',
    '.crt',
    '.env',
    '.p12',
    '.pfx',
    '.exe',
    '.bat',
    '.cmd',
    '.ps1',
    '.vbs',
    '.sh',
    '.bin',
    '.msi',
    '.dll',
    '.sys',
    '.ini',
    '.config',
  };

  /// Segmentos de caminhos de sistema proibidos
  static const List<String> _pastasSistemaProibidas = [
    '/windows/',
    '/system32/',
    '/syswow64/',
    '/program files/',
    '/program files (x86)/',
    '/etc/',
    '/usr/',
    '/var/',
    '/proc/',
    '/root/',
  ];

  /// Valida se um determinado caminho físico em disco pode ser servido com segurança (Sandbox).
  /// Bloqueia qualquer tentativa de Path Traversal, leitura de arquivos do sistema ou do banco SQLite `nous.db`.
  static bool validarCaminhoLeituraPermitido(
    String caminhoArquivo, {
    String? pastaBasePermitida,
  }) {
    if (caminhoArquivo.trim().isEmpty) return false;

    try {
      final normalizado = p.normalize(caminhoArquivo.trim());
      final canonico = p.canonicalize(normalizado);
      final canonicoLower = canonico.replaceAll(r'\', '/').toLowerCase();

      // 1. Proibição estrita de acesso ao banco SQLite ou arquivos de banco
      if (canonicoLower.endsWith('nous.db') ||
          canonicoLower.contains('nous.db-') ||
          canonicoLower.endsWith('.db') ||
          canonicoLower.endsWith('.sqlite')) {
        debugPrint('[SegurancaServidorRelay] Tentativa de acesso bloqueada ao banco de dados: $canonico');
        return false;
      }

      // 2. Proibição de extensões perigosas
      final ext = p.extension(canonicoLower);
      if (_extensoesProibidas.contains(ext)) {
        debugPrint('[SegurancaServidorRelay] Tentativa de acesso a extensão proibida ($ext): $canonico');
        return false;
      }

      // 3. Proibição de pastas de sistema do SO
      for (final pasta in _pastasSistemaProibidas) {
        if (canonicoLower.contains(pasta)) {
          debugPrint('[SegurancaServidorRelay] Tentativa de acesso a pasta de sistema ($pasta): $canonico');
          return false;
        }
      }

      // 4. Se uma pasta base foi exigida, garante confinamento estrito (Sandbox)
      if (pastaBasePermitida != null && pastaBasePermitida.trim().isNotEmpty) {
        final baseCanon = p.canonicalize(pastaBasePermitida.trim()).replaceAll(r'\', '/').toLowerCase();
        if (!canonicoLower.startsWith(baseCanon)) {
          debugPrint('[SegurancaServidorRelay] Violação de Sandbox (fora da pasta base $baseCanon): $canonicoLower');
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('[SegurancaServidorRelay] Erro ao validar caminho: $e');
      return false;
    }
  }

  /// Sanitiza o nome sugerido de um arquivo enviado por upload, arrancando qualquer
  /// caractere de diretório ou tentativa de Path Traversal (`..`, `/`, `\`).
  static String sanitizarNomeArquivo(String? nomeSugerido) {
    if (nomeSugerido == null || nomeSugerido.trim().isEmpty) {
      return '${DateTime.now().millisecondsSinceEpoch}_arquivo';
    }

    // Pega estritamente o nome base (impede ../../../)
    var base = p.basename(nomeSugerido.trim());
    // Remove caracteres nulos e perigosos
    base = base.replaceAll('\x00', '').replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    // Remove múltiplos pontos consecutivos para evitar extensões disfarçadas ou ..
    base = base.replaceAll(RegExp(r'\.{2,}'), '.');

    if (base.isEmpty || base == '.') {
      return '${DateTime.now().millisecondsSinceEpoch}_arquivo';
    }

    return base;
  }

  /// Sanitiza uma subpasta de armazenamento, permitindo apenas caracteres alfanuméricos seguros
  static String sanitizarSubpasta(String? subpasta) {
    if (subpasta == null || subpasta.trim().isEmpty) {
      return 'geral';
    }

    final limpa = subpasta.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '');
    return limpa.isNotEmpty ? limpa : 'geral';
  }

  /// Verifica se o IP informado é de rede local/privada (RFC 1918, RFC 4193, loopback)
  static bool ehIpPrivadoOuLoopback(String ip) {
    if (ip == '127.0.0.1' || ip == '::1' || ip == 'localhost') return true;
    if (ip.startsWith('192.168.') || ip.startsWith('10.')) return true;
    if (ip.startsWith('172.')) {
      final partes = ip.split('.');
      if (partes.length >= 2) {
        final segundoOcteto = int.tryParse(partes[1]);
        if (segundoOcteto != null && segundoOcteto >= 16 && segundoOcteto <= 31) {
          return true;
        }
      }
    }
    if (ip.startsWith('fe80:') || ip.startsWith('fc00:') || ip.startsWith('fd00:')) {
      return true;
    }
    return false;
  }

  static void _responderErro(
    HttpRequest request, {
    required int statusCode,
    required String mensagem,
  }) {
    try {
      request.response.statusCode = statusCode;
      request.response.headers.contentType = ContentType.json;
      aplicarHeadersSeguranca(request.response);
      request.response.write(
        jsonEncode({
          'sucesso': false,
          'seguranca': true,
          'status': statusCode,
          'mensagem': mensagem,
        }),
      );
      request.response.close();
    } catch (_) {}
  }
}
