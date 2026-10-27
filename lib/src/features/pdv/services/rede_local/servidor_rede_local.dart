import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nous/src/core/services/atualizacao_service.dart';
import 'package:nous/src/core/services/changelog_service.dart';
import 'package:nous/src/core/services/navigator_key_service.dart';
import 'package:nous/src/core/services/som_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/referencia_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/dados_locais_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';

enum ResultadoAutorizacaoConexao {
  recusado,
  autorizadoMembro,
  autorizadoCliente,
}

/// Informações de um terminal móvel conectado ao balcão
class TerminalConectadoInfo {
  final String id;
  String nome;
  final String ip;
  final DateTime conectadoEm;
  String? cpf;
  String? nomeUsuario;
  String? apelido;
  String? tipoConexao;

  TerminalConectadoInfo({
    required this.id,
    required this.nome,
    required this.ip,
    required this.conectadoEm,
    this.cpf,
    this.nomeUsuario,
    this.apelido,
    this.tipoConexao = 'membro',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'ip': ip,
        'conectadoEm': conectadoEm.toIso8601String(),
        'cpf': cpf,
        'nomeUsuario': nomeUsuario,
        'apelido': apelido,
        'tipoConexao': tipoConexao,
      };

  factory TerminalConectadoInfo.fromJson(Map<String, dynamic> json) {
    return TerminalConectadoInfo(
      id: json['id'] as String? ?? '',
      nome: json['nome'] as String? ?? 'Terminal',
      ip: json['ip'] as String? ?? '',
      conectadoEm: DateTime.tryParse(json['conectadoEm'] as String? ?? '') ??
          DateTime.now(),
      cpf: json['cpf'] as String?,
      nomeUsuario: json['nomeUsuario'] as String?,
      apelido: json['apelido'] as String?,
      tipoConexao: json['tipoConexao'] as String? ?? 'membro',
    );
  }
}

/// Gerencia o Servidor da Loja em rede local Wi-Fi.
/// Permite que celulares e outros computadores operem como terminais móveis simultâneos.
class ServidorRedeLocal {
  static final ServidorRedeLocal _instancia = ServidorRedeLocal._interno();
  factory ServidorRedeLocal() => _instancia;
  ServidorRedeLocal._interno();

  static const int portaUdpAnuncio = 45454;
  static const int portaPadraoHttp = 8080;

  HttpServer? _servidorHttp;
  RawDatagramSocket? _socketUdp;
  Timer? _timerUdp;
  final List<WebSocket> _clientesWs = [];
  final Map<WebSocket, TerminalConectadoInfo> _terminaisWs = {};
  final Set<String> _terminaisAutorizados = {};
  final Map<String, ResultadoAutorizacaoConexao> _decisoesTerminais = {};
  DateTime? _dataHoraInicio;

  String? _ipServidor;
  int _porta = portaPadraoHttp;
  Loja? _lojaAtiva;
  PdvProvider? _pdvProvider;
  AuthProvider? _authProvider;

  void vincularAuthProvider(AuthProvider auth) {
    _authProvider = auth;
  }

  final ValueNotifier<bool> estaAtivo = ValueNotifier<bool>(false);
  final ValueNotifier<int> totalConectados = ValueNotifier<int>(0);
  final ValueNotifier<List<TerminalConectadoInfo>> terminaisConectados =
      ValueNotifier<List<TerminalConectadoInfo>>([]);

  void _atualizarListasTerminais() {
    totalConectados.value = _clientesWs.length;
    terminaisConectados.value = obterTodasPresencas();
  }

  bool get ativo => _servidorHttp != null;
  String? get ipServidor => _ipServidor;
  int get porta => _porta;
  Loja? get lojaAtiva {
    if (_lojaAtiva != null && _pdvProvider != null) {
      final atual = _pdvProvider!.buscarPorId(_lojaAtiva!.id);
      if (atual != null) {
        _lojaAtiva = atual;
      }
    }
    return _lojaAtiva;
  }

  /// Descobre o melhor IP IPv4 local na rede Wi-Fi/Ethernet da máquina.
  static Future<String?> obterIpLocal() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      // Prioriza redes privadas típicas (192.168.x.x, 10.x.x.x, 172.16-31.x.x)
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback &&
              (addr.address.startsWith('192.168.') ||
                  addr.address.startsWith('10.') ||
                  addr.address.startsWith('172.'))) {
            return addr.address;
          }
        }
      }

      // Fallback para qualquer IPv4 não-loopback
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (e) {
      debugPrint('[ServidorRedeLocal] Erro ao obter IP local: $e');
    }
    return null;
  }

  /// Inicia o servidor HTTP, WebSocket e o anúncio UDP na rede local.
  Future<bool> iniciar({
    required Loja loja,
    required PdvProvider pdv,
    AuthProvider? auth,
    int portaInicial = portaPadraoHttp,
  }) async {
    if (ativo) {
      if (_lojaAtiva?.id == loja.id) {
        _lojaAtiva = loja;
        _pdvProvider = pdv;
        if (auth != null) _authProvider = auth;
        return true;
      }
      await parar();
    }

    _lojaAtiva = loja;
    _pdvProvider = pdv;
    if (auth != null) _authProvider = auth;
    _ipServidor = await obterIpLocal() ?? '0.0.0.0';

    // Tenta alocar a porta inicial ou próximas caso ocupada
    var portaTentativa = portaInicial;
    while (portaTentativa < portaInicial + 20) {
      try {
        _servidorHttp = await HttpServer.bind(
          InternetAddress.anyIPv4,
          portaTentativa,
          shared: true,
        );
        _porta = portaTentativa;
        break;
      } catch (_) {
        portaTentativa++;
      }
    }

    if (_servidorHttp == null) {
      debugPrint('[ServidorRedeLocal] Não foi possível abrir porta HTTP.');
      return false;
    }

    _dataHoraInicio = DateTime.now();
    _terminaisAutorizados.clear();
    estaAtivo.value = true;
    _atualizarListasTerminais();
    debugPrint(
      '[ServidorRedeLocal] Loja "${loja.nome}" iniciada em http://$_ipServidor:$_porta',
    );

    // Escuta requisições HTTP e WebSockets
    _servidorHttp!.listen(_processarRequisicao, onError: (e) {
      debugPrint('[ServidorRedeLocal] Erro no servidor: $e');
    });

    // Inicia anúncio UDP para descoberta automática no Wi-Fi
    _iniciarAnuncioUdp();

    // Drena qualquer mensagem que estava na fila de saída local
    ChatService.drenarFilaDeSaida();

    return true;
  }

  /// Para o servidor e encerra conexões
  Future<void> parar() async {
    _timerUdp?.cancel();
    _timerUdp = null;

    try {
      _socketUdp?.close();
    } catch (_) {}
    _socketUdp = null;

    for (final ws in List<WebSocket>.from(_clientesWs)) {
      try {
        await ws.close();
      } catch (_) {}
    }
    _clientesWs.clear();
    _terminaisWs.clear();
    _terminaisAutorizados.clear();
    _dataHoraInicio = null;

    try {
      await _servidorHttp?.close(force: true);
    } catch (_) {}
    _servidorHttp = null;

    estaAtivo.value = false;
    totalConectados.value = 0;
    terminaisConectados.value = [];
    debugPrint('[ServidorRedeLocal] Servidor encerrado.');
  }

  /// Processa requisições REST e upgrades para WebSocket
  Future<void> _processarRequisicao(HttpRequest request) async {
    // Permite CORS para terminais locais
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add(
      'Access-Control-Allow-Methods',
      'GET, POST, OPTIONS',
    );
    request.response.headers.add(
      'Access-Control-Allow-Headers',
      'Content-Type, Authorization',
    );

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    final path = request.uri.path;

    // 1. WebSocket para comunicação bidirecional em tempo real
    if (path == '/api/ws') {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        try {
          final ws = await WebSocketTransformer.upgrade(request);
          final ipRemoto = request.connectionInfo?.remoteAddress.address ?? '127.0.0.1';
          final terminal = TerminalConectadoInfo(
            id: 'term_${DateTime.now().millisecondsSinceEpoch}',
            nome: 'Terminal ($ipRemoto)',
            ip: ipRemoto,
            conectadoEm: DateTime.now(),
          );

          _clientesWs.add(ws);
          _terminaisWs[ws] = terminal;
          _atualizarListasTerminais();

          debugPrint(
            '[ServidorRedeLocal] Novo terminal conectado: $ipRemoto. Total: ${_clientesWs.length}',
          );

          // Envia dados iniciais da loja e lista de presenças ativas
          if (_lojaAtiva != null) {
            final fotosUsuariosAusentes = <String>[];
            for (final m in _lojaAtiva!.membros) {
              final cpfLimpo = m.cpf.replaceAll(RegExp(r'\D'), '');
              if (cpfLimpo.isNotEmpty) {
                final contaMembro =
                    await ContasNousService.buscarPorCpf(cpfLimpo);
                final temFotoFisica = contaMembro != null &&
                    contaMembro.foto.trim().isNotEmpty &&
                    ImagemService.resolverCaminhoExistente(contaMembro.foto) !=
                        null;
                if (!temFotoFisica) {
                  fotosUsuariosAusentes.add(cpfLimpo);
                }
              }
            }

            final lojaNous =
                _pdvProvider?.buscarPorId(PdvProvider.idLojaColetivaNous);

            ws.add(
              jsonEncode({
                'tipo': 'dados_iniciais',
                'loja': _lojaAtiva!.toJson(),
                if (lojaNous != null) 'lojaNousColetiva': lojaNous.toJson(),
                'presencas':
                    obterTodasPresencas().map((p) => p.toJson()).toList(),
                'fotosUsuariosAusentes': fotosUsuariosAusentes,
              }),
            );
          }

          ws.listen(
            (msg) => _tratarMensagemWs(ws, msg),
            onDone: () {
              _clientesWs.remove(ws);
              _terminaisWs.remove(ws);
              _atualizarListasTerminais();
              notificarPresencas();
            },
            onError: (_) {
              _clientesWs.remove(ws);
              _terminaisWs.remove(ws);
              _atualizarListasTerminais();
              notificarPresencas();
            },
          );
        } catch (e) {
          debugPrint('[ServidorRedeLocal] Erro no upgrade WebSocket: $e');
        }
        return;
      }
    }

    // 2. Servir imagens binárias salvas localmente na máquina
    if (path == '/api/imagem' && request.method == 'GET') {
      final caminho = request.uri.queryParameters['caminho'];
      if (caminho == null || caminho.trim().isEmpty) {
        request.response.statusCode = HttpStatus.badRequest;
        await request.response.close();
        return;
      }

      final caminhoResolvido = ImagemService.resolverCaminhoExistente(caminho.trim());
      if (caminhoResolvido == null) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }

      final arquivo = File(caminhoResolvido);

      try {
        final ext = caminhoResolvido.split('.').last.toLowerCase();
        ContentType tipoConteudo;
        switch (ext) {
          case 'png':
            tipoConteudo = ContentType('image', 'png');
            break;
          case 'webp':
            tipoConteudo = ContentType('image', 'webp');
            break;
          case 'gif':
            tipoConteudo = ContentType('image', 'gif');
            break;
          case 'jpg':
          case 'jpeg':
          default:
            tipoConteudo = ContentType('image', 'jpeg');
            break;
        }

        request.response.headers.contentType = tipoConteudo;
        await request.response.addStream(arquivo.openRead());
        await request.response.close();
        return;
      } catch (e) {
        debugPrint('[ServidorRedeLocal] Erro ao servir imagem: $e');
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
        return;
      }
    }

    // 2.1 Receber upload de novas imagens enviadas por terminais móveis
    if (path == '/api/upload_imagem' && request.method == 'POST') {
      try {
        final nomeOriginal = request.uri.queryParameters['nome'];
        final bytes = await request.fold<List<int>>([], (acc, chunk) => acc..addAll(chunk));
        if (bytes.isEmpty) {
          request.response.statusCode = HttpStatus.badRequest;
          await request.response.close();
          return;
        }

        final ext = nomeOriginal?.split('.').last.toLowerCase() ?? 'jpg';
        final salvo = await ImagemService.salvarBytesImagemLocal(
          bytes,
          extensaoOriginal: ext,
          nomeSugerido: nomeOriginal,
        );

        if (salvo != null) {
          request.response.statusCode = HttpStatus.ok;
          request.response.headers.contentType = ContentType.json;
          request.response.write(jsonEncode({'caminho': salvo}));
          await request.response.close();
          return;
        } else {
          request.response.statusCode = HttpStatus.internalServerError;
          await request.response.close();
          return;
        }
      } catch (e) {
        debugPrint('[ServidorRedeLocal] Erro ao receber upload de imagem: $e');
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
        return;
      }
    }

    // 2.2 Receber upload de novos anexos/áudios enviados por terminais móveis
    if (path == '/api/upload_anexo' && request.method == 'POST') {
      try {
        final nomeOriginal = request.uri.queryParameters['nome'];
        final subpasta = request.uri.queryParameters['pasta'] ?? 'musicas';
        final bytes = await request.fold<List<int>>([], (acc, chunk) => acc..addAll(chunk));
        if (bytes.isEmpty) {
          request.response.statusCode = HttpStatus.badRequest;
          await request.response.close();
          return;
        }

        final salvo = await ImagemService.salvarBytesAnexoLocal(
          bytes,
          categoria: subpasta,
          nomeSugerido: nomeOriginal,
        );

        if (salvo != null) {
          request.response.statusCode = HttpStatus.ok;
          request.response.headers.contentType = ContentType.json;
          request.response.write(jsonEncode({'caminho': salvo}));
          await request.response.close();
          return;
        } else {
          request.response.statusCode = HttpStatus.internalServerError;
          await request.response.close();
          return;
        }
      } catch (e) {
        debugPrint('[ServidorRedeLocal] Erro ao receber upload de anexo: $e');
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
        return;
      }
    }

    // 2.3 Servir arquivos de áudio/música pela rede local
    if (path == '/api/audio' && request.method == 'GET') {
      final caminho = request.uri.queryParameters['caminho'];
      if (caminho == null || caminho.trim().isEmpty) {
        request.response.statusCode = HttpStatus.badRequest;
        await request.response.close();
        return;
      }

      final caminhoResolvido = ImagemService.resolverCaminhoExistente(caminho.trim());
      if (caminhoResolvido == null) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }

      final arquivo = File(caminhoResolvido);

      try {
        final ext = caminhoResolvido.split('.').last.toLowerCase();
        ContentType tipoConteudo;
        switch (ext) {
          case 'mp3':
            tipoConteudo = ContentType('audio', 'mpeg');
            break;
          case 'wav':
            tipoConteudo = ContentType('audio', 'wav');
            break;
          case 'ogg':
            tipoConteudo = ContentType('audio', 'ogg');
            break;
          case 'aac':
          case 'm4a':
            tipoConteudo = ContentType('audio', 'aac');
            break;
          case 'flac':
            tipoConteudo = ContentType('audio', 'flac');
            break;
          default:
            tipoConteudo = ContentType('audio', 'mpeg');
            break;
        }

        request.response.headers.contentType = tipoConteudo;
        request.response.headers.set('Accept-Ranges', 'bytes');
        request.response.headers.contentLength = await arquivo.length();
        await request.response.addStream(arquivo.openRead());
        await request.response.close();
        return;
      } catch (e) {
        debugPrint('[ServidorRedeLocal] Erro ao servir áudio: $e');
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
        return;
      }
    }

    // 3. Status do servidor
    if (path == '/api/status' && request.method == 'GET') {
      _responderJson(request, {
        'sucesso': true,
        'lojaId': _lojaAtiva?.id,
        'lojaNome': _lojaAtiva?.nome,
        'servidor': 'Nous Local Server',
        'versao': '1.0.0',
        'conectados': _clientesWs.length,
      });
      return;
    }

    // 3. Obter dados completos da loja
    if (path == '/api/loja' && request.method == 'GET') {
      final ipRemoto = request.connectionInfo?.remoteAddress.address ?? '127.0.0.1';
      final cpfParam = request.uri.queryParameters['cpf'];
      final nomeParam = request.uri.queryParameters['nome'];
      final apelidoParam = request.uri.queryParameters['apelido'];
      final dispositivoParam = request.uri.queryParameters['dispositivo'];

      final ehLocal = request.connectionInfo?.remoteAddress.isLoopback ?? false;
      final cpfParamLimpo =
          (cpfParam != null) ? ChatService.normalizarCpf(cpfParam) : '';
      final ehDono = _lojaAtiva != null &&
          cpfParamLimpo.isNotEmpty &&
          ChatService.normalizarCpf(_lojaAtiva!.cpfDonoOriginal) == cpfParamLimpo;
      final jaEhMembro = _lojaAtiva != null &&
          cpfParamLimpo.isNotEmpty &&
          _lojaAtiva!.membros.any((m) =>
              ChatService.normalizarCpf(m.cpf) == cpfParamLimpo);

      final chaveTerminal = (cpfParamLimpo.isNotEmpty)
          ? '${ipRemoto}_$cpfParamLimpo'
          : '${ipRemoto}_${dispositivoParam?.trim() ?? ''}';

      ResultadoAutorizacaoConexao? decisao = _decisoesTerminais[chaveTerminal];

      // Sempre exige aprovação no balcão caso o terminal ainda não esteja autorizado nesta sessão
      if (!ehLocal && !_terminaisAutorizados.contains(chaveTerminal)) {
        final resultado = await _solicitarAutorizacaoTerminal(
          ip: ipRemoto,
          nomeDispositivo: (dispositivoParam != null && dispositivoParam.trim().isNotEmpty)
              ? dispositivoParam.trim()
              : 'Terminal Móvel',
          nomeUsuario: (apelidoParam != null && apelidoParam.trim().isNotEmpty)
              ? '$nomeParam ($apelidoParam)'
              : nomeParam,
          cpf: cpfParam,
          jaEhMembro: jaEhMembro || ehDono,
        );

        if (resultado == ResultadoAutorizacaoConexao.recusado) {
          debugPrint(
            '[ServidorRedeLocal] Conexão recusada pelo administrador para terminal $chaveTerminal ($ipRemoto)',
          );
          _responderJson(
            request,
            {'sucesso': false, 'mensagem': 'Conexão recusada pelo Administrador do Balcão.'},
            statusCode: HttpStatus.forbidden,
          );
          return;
        }

        decisao = resultado;
        _decisoesTerminais[chaveTerminal] = resultado;
        _terminaisAutorizados.add(chaveTerminal);
      }

      final ehCliente = decisao == ResultadoAutorizacaoConexao.autorizadoCliente;

      if (cpfParam != null && cpfParam.trim().isNotEmpty && _lojaAtiva != null && _pdvProvider != null) {
        final terminalTemp = TerminalConectadoInfo(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          nome: (dispositivoParam != null && dispositivoParam.trim().isNotEmpty)
              ? dispositivoParam.trim()
              : 'Terminal Móvel',
          ip: ipRemoto,
          conectadoEm: DateTime.now(),
          cpf: cpfParam.trim(),
          nomeUsuario: nomeParam?.trim(),
          apelido: apelidoParam?.trim(),
          tipoConexao: ehCliente ? 'cliente' : 'membro',
        );

        if (ehCliente) {
          await _garantirClienteConectado(terminalTemp);
        } else {
          await _garantirMembroConectado(terminalTemp);
        }
        _consolidarContaTerminal(terminalTemp);
      }

      final lojaRetorno = lojaAtiva;
      if (lojaRetorno == null) {
        _responderJson(
          request,
          {'sucesso': false, 'mensagem': 'Nenhuma loja ativa'},
          statusCode: HttpStatus.notFound,
        );
        return;
      }

      // Inspeciona o disco local deste servidor e lista lacunas para autocura remota
      final imagensAusentes = <String>[];
      if (lojaRetorno.logo.trim().isEmpty || !ImagemService.existe(lojaRetorno.logo)) {
        imagensAusentes.add('logo');
      }
      for (final cat in lojaRetorno.categoriasLoja) {
        if (cat.foto.trim().isEmpty || !ImagemService.existe(cat.foto)) {
          imagensAusentes.add('categoria_${cat.id}');
        }
      }
      for (final item in lojaRetorno.itensLoja) {
        if (item.imagens.isEmpty) {
          imagensAusentes.add('item_${item.id}');
        } else {
          var temAlgumaValida = false;
          for (final img in item.imagens) {
            if (ImagemService.existe(img)) {
              temAlgumaValida = true;
              break;
            }
          }
          if (!temAlgumaValida) {
            imagensAusentes.add('item_${item.id}');
          }
        }
      }
      for (final cli in lojaRetorno.clientesLoja) {
        if (cli.foto.trim().isEmpty || !ImagemService.existe(cli.foto)) {
          imagensAusentes.add('cliente_${cli.id}');
        }
      }
      for (final forn in lojaRetorno.fornecedoresLoja) {
        if (forn.foto.trim().isEmpty || !ImagemService.existe(forn.foto)) {
          imagensAusentes.add('fornecedor_${forn.id}');
        }
      }

      // Inspeciona fotos ausentes de membros e usuários da loja no servidor
      final fotosUsuariosAusentes = <String>[];
      for (final m in lojaRetorno.membros) {
        final cpfLimpo = m.cpf.replaceAll(RegExp(r'\D'), '');
        if (cpfLimpo.isNotEmpty) {
          final contaMembro = await ContasNousService.buscarPorCpf(cpfLimpo);
          final temFotoFisica = contaMembro != null &&
              contaMembro.foto.trim().isNotEmpty &&
              ImagemService.resolverCaminhoExistente(contaMembro.foto) != null;
          if (!temFotoFisica) {
            fotosUsuariosAusentes.add(cpfLimpo);
          }
        }
      }

      _responderJson(request, {
        'sucesso': true,
        'loja': lojaRetorno.toJson(),
        'papelConexao': ehCliente ? 'cliente' : 'membro',
        'imagensAusentes': imagensAusentes,
        'fotosUsuariosAusentes': fotosUsuariosAusentes,
      });
      return;
    }

    // 3.1 Receber atualização completa da loja vinda de um terminal móvel (membros, catálogo, mesas, etc.)
    if (path == '/api/loja/atualizar' && request.method == 'POST') {
      try {
        final body = await utf8.decodeStream(request);
        final dados = jsonDecode(body) as Map<String, dynamic>;
        final lojaRemota = Loja.fromJson(dados);

        if (_pdvProvider != null && _lojaAtiva != null && _lojaAtiva!.id == lojaRemota.id) {
          final lojaAtual = _pdvProvider!.buscarPorId(_lojaAtiva!.id) ?? _lojaAtiva!;

          // 1. Detectar membros que foram removidos pelo celular e limpar suas referências no SQLite do balcão
          for (final m in lojaAtual.membros) {
            final aindaExiste = lojaRemota.membros.any((rm) => rm.cpf == m.cpf);
            if (!aindaExiste) {
              await LojasService.removerReferencia(m.cpf, lojaAtual.id);
              debugPrint(
                '[ServidorRedeLocal] Membro ${m.nome} (${m.cpf}) removido via sincronização do terminal móvel',
              );
            }
          }

          // 2. Mesclar histórico de auditoria (ações) sem duplicar
          final acoesMescladas = List<RegistroAcao>.from(lojaAtual.acoes);
          for (final acao in lojaRemota.acoes) {
            if (!acoesMescladas.any((a) => a.id == acao.id)) {
              acoesMescladas.add(acao);
            }
          }

          // 3. Consolidar dados da loja com proteção absoluta de imagens e integridade
          final lojaConsolidada = LojasService.consolidarLojaComImagensLocais(
            lojaRemota.copyWith(acoes: acoesMescladas),
            lojaAtual,
            manterItensAusentes: false,
          );

          _lojaAtiva = lojaConsolidada;
          await _pdvProvider!.adicionarOuAtualizarLoja(lojaConsolidada);

          // Transmite a loja consolidada para todos os outros terminais conectados via WebSocket
          notificarTodos({
            'tipo': 'loja_atualizada',
            'loja': lojaConsolidada.toJson(),
          });
        }

        _responderJson(request, {'sucesso': true});
        return;
      } catch (e) {
        _responderJson(
          request,
          {'sucesso': false, 'erro': e.toString()},
          statusCode: HttpStatus.badRequest,
        );
        return;
      }
    }

    // 4. Receber novo pedido do celular
    if (path == '/api/pedido' && request.method == 'POST') {
      try {
        final body = await utf8.decodeStream(request);
        final dados = jsonDecode(body) as Map<String, dynamic>;
        final pedido = PedidoLoja.fromJson(dados);

        if (_pdvProvider != null && _lojaAtiva != null) {
          final lojaAtual = _pdvProvider!.buscarPorId(_lojaAtiva!.id);
          if (lojaAtual != null) {
            final pedidos = List<PedidoLoja>.from(lojaAtual.pedidosLoja);
            final idx = pedidos.indexWhere((p) => p.id == pedido.id);
            if (idx != -1) {
              pedidos[idx] = pedido;
              _pdvProvider!.atualizarListasLoja(
                lojaAtual.id,
                pedidos: pedidos,
              );

              // Notifica todos os terminais conectados sobre a atualização do pedido
              notificarTodos({
                'tipo': 'pedido_atualizado',
                'pedido': pedido.toJson(),
              });
            } else {
              pedidos.insert(0, pedido);
              _pdvProvider!.atualizarListasLoja(
                lojaAtual.id,
                pedidos: pedidos,
              );

              // Toca o som de alerta de novo pedido no balcão
              SomService.tocarEvento(
                SomService.eventoNovoPedido,
                loja: lojaAtual,
              );

              // Notifica todos os terminais conectados
              notificarTodos({
                'tipo': 'pedido_adicionado',
                'pedido': pedido.toJson(),
              });
            }
          }
        }

        _responderJson(request, {
          'sucesso': true,
          'pedidoId': pedido.id,
          'numero': pedido.numero,
        });
        return;
      } catch (e) {
        _responderJson(
          request,
          {'sucesso': false, 'erro': e.toString()},
          statusCode: HttpStatus.badRequest,
        );
        return;
      }
    }

    // 5. Receber movimentação de estoque
    if (path == '/api/movimento_estoque' && request.method == 'POST') {
      try {
        final body = await utf8.decodeStream(request);
        final dados = jsonDecode(body) as Map<String, dynamic>;
        final mov = MovimentoEstoque.fromJson(dados);

        if (_pdvProvider != null && _lojaAtiva != null) {
          final lojaAtual = _pdvProvider!.buscarPorId(_lojaAtiva!.id);
          if (lojaAtual != null) {
            final movs = List<MovimentoEstoque>.from(lojaAtual.movimentosEstoque);
            movs.insert(0, mov);
            _pdvProvider!.atualizarListasLoja(
              lojaAtual.id,
              movimentosEstoque: movs,
            );
            notificarTodos({
              'tipo': 'estoque_atualizado',
              'movimento': mov.toJson(),
            });
          }
        }

        _responderJson(request, {'sucesso': true, 'movimentoId': mov.id});
        return;
      } catch (e) {
        _responderJson(
          request,
          {'sucesso': false, 'erro': e.toString()},
          statusCode: HttpStatus.badRequest,
        );
        return;
      }
    }

    // 6. Atualizar mesa
    if (path == '/api/mesa' && request.method == 'POST') {
      try {
        final body = await utf8.decodeStream(request);
        final dados = jsonDecode(body) as Map<String, dynamic>;
        final mesa = MesaLoja.fromJson(dados);

        if (_pdvProvider != null && _lojaAtiva != null) {
          final lojaAtual = _pdvProvider!.buscarPorId(_lojaAtiva!.id);
          if (lojaAtual != null) {
            final mesas = List<MesaLoja>.from(lojaAtual.mesas);
            final idx = mesas.indexWhere((m) => m.id == mesa.id);
            if (idx != -1) {
              mesas[idx] = mesa;
            } else {
              mesas.add(mesa);
            }
            _pdvProvider!.atualizarListasLoja(lojaAtual.id, mesas: mesas);
            notificarTodos({
              'tipo': 'mesa_atualizada',
              'mesa': mesa.toJson(),
            });
          }
        }

        _responderJson(request, {'sucesso': true, 'mesaId': mesa.id});
        return;
      } catch (e) {
        _responderJson(
          request,
          {'sucesso': false, 'erro': e.toString()},
          statusCode: HttpStatus.badRequest,
        );
        return;
      }
    }

    // 7. Obter dados cadastrais da Identidade do Usuário por CPF
    if (path == '/api/usuario' && request.method == 'GET') {
      final cpfParam = request.uri.queryParameters['cpf'];
      if (cpfParam == null || cpfParam.trim().isEmpty) {
        _responderJson(
          request,
          {'sucesso': false, 'mensagem': 'CPF não informado'},
          statusCode: HttpStatus.badRequest,
        );
        return;
      }

      var conta = await ContasNousService.buscarPorCpf(cpfParam.trim());
      if (conta == null) {
        // Tenta consolidar a partir de DadosLocaisService ou membros da loja
        final dadosAuto =
            await DadosLocaisService.buscarPorDocumento(cpfParam.trim());
        if (dadosAuto != null && dadosAuto.nome.trim().isNotEmpty) {
          conta = UsuarioNous(
            cpf: cpfParam.trim(),
            nome: dadosAuto.nome.trim(),
            dataNascimento: dadosAuto.dataNascimento,
            foto: dadosAuto.foto,
          );
          await ContasNousService.salvar(conta);
          debugPrint(
            '[ServidorRedeLocal] Conta unificada e salva no balcão a partir de dados locais para CPF $cpfParam (${conta.nome})',
          );
        } else if (_lojaAtiva != null) {
          final digitos = cpfParam.replaceAll(RegExp(r'\D'), '');
          final membro = _lojaAtiva!.membros
              .where(
                (m) => m.cpf.replaceAll(RegExp(r'\D'), '') == digitos,
              )
              .firstOrNull;
          if (membro != null && membro.nome.trim().isNotEmpty) {
            conta = UsuarioNous(
              cpf: cpfParam.trim(),
              nome: membro.nome.trim(),
              dataNascimento: '',
            );
            await ContasNousService.salvar(conta);
          }
        }
      }

      if (conta == null) {
        _responderJson(
          request,
          {'sucesso': false, 'mensagem': 'Usuário não encontrado'},
          statusCode: HttpStatus.notFound,
        );
        return;
      }

      // Validação física soberana: se a foto salva não existe no disco deste servidor,
      // reporta foto vazia para que a rede saiba que esta foto precisa ser curada!
      if (conta.foto.isNotEmpty) {
        final resolvida = ImagemService.resolverCaminhoExistente(conta.foto);
        if (resolvida == null) {
          conta = conta.copyWith(foto: '');
          await ContasNousService.salvar(conta);
        } else if (resolvida != conta.foto) {
          conta = conta.copyWith(foto: resolvida);
          await ContasNousService.salvar(conta);
        }
      }

      _responderJson(request, {
        'sucesso': true,
        'usuario': conta.toJson(),
      });
      return;
    }

    // 8. Salvar ou atualizar Identidade do Usuário
    if (path == '/api/usuario' && request.method == 'POST') {
      try {
        final body = await utf8.decodeStream(request);
        final dados = jsonDecode(body) as Map<String, dynamic>;
        var usuario = UsuarioNous.fromJson(dados);

        // Se veio com foto, resolve no disco local do servidor
        if (usuario.foto.isNotEmpty) {
          final fotoResolvida =
              ImagemService.resolverCaminhoExistente(usuario.foto);
          if (fotoResolvida != null) {
            usuario = usuario.copyWith(foto: fotoResolvida);
          }
        }

        // Se o usuário já existe no servidor com foto física válida, e o payload veio sem foto ou com foto inválida, preserva a foto existente!
        final contaExistente =
            await ContasNousService.buscarPorCpf(usuario.cpf);
        if (contaExistente != null &&
            contaExistente.foto.isNotEmpty &&
            ImagemService.existe(contaExistente.foto) &&
            (usuario.foto.isEmpty || !ImagemService.existe(usuario.foto))) {
          usuario = usuario.copyWith(foto: contaExistente.foto);
        }

        await ContasNousService.salvar(usuario);

        // Sincroniza foto em clientes da loja com esse CPF
        if (usuario.foto.isNotEmpty && ImagemService.existe(usuario.foto)) {
          _pdvProvider?.sincronizarFotoUsuarioEmClientes(
              usuario.cpf, usuario.foto);
        }

        // Atualiza cache de identidades e notifica o AuthProvider e PdvProvider
        _authProvider?.atualizarContaNoCache(usuario);
        _pdvProvider?.notificarMudanca();

        // Se a conta ativa no servidor for esse CPF, recarrega a conta ativa
        if (_authProvider != null &&
            (_authProvider!.contaAtual?.cpf == usuario.cpf ||
                _authProvider!.cpf == usuario.cpf)) {
          await _authProvider!.recarregarConta();
        }

        // Notifica todos os terminais conectados sobre a identidade atualizada do usuário
        notificarTodos({
          'tipo': 'usuario_atualizado',
          'usuario': usuario.toJson(),
        });

        _responderJson(
            request, {'sucesso': true, 'usuario': usuario.toJson()});
        return;
      } catch (e) {
        _responderJson(
          request,
          {'sucesso': false, 'erro': e.toString()},
          statusCode: HttpStatus.badRequest,
        );
        return;
      }
    }

    // 8.1 Sincronização em massa de perfis/contas de usuários na rede local
    if (path == '/api/usuarios' && request.method == 'GET') {
      final contas = await ContasNousService.carregarTodas();
      final contasValidas = contas.where((c) {
        final cpfLimpo = c.cpf.replaceAll(RegExp(r'\D'), '');
        return cpfLimpo.length == 11 && c.nome.toLowerCase() != 'blackview';
      }).toList();

      _responderJson(request, {
        'sucesso': true,
        'usuarios': contasValidas.map((c) => c.toJson()).toList(),
      });
      return;
    }

    if (path == '/api/usuarios' && request.method == 'POST') {
      try {
        final body = await utf8.decodeStream(request);
        final dados = jsonDecode(body) as Map<String, dynamic>;
        final lista = (dados['usuarios'] as List<dynamic>?) ?? [];
        for (final item in lista) {
          if (item is Map<String, dynamic>) {
            final u = UsuarioNous.fromJson(item);
            final cpfLimpo = u.cpf.replaceAll(RegExp(r'\D'), '');
            if (cpfLimpo.length == 11 && u.nome.toLowerCase() != 'blackview') {
              final existente = await ContasNousService.buscarPorCpf(u.cpf);
              if (existente == null) {
                await ContasNousService.salvar(u);
              } else {
                final mesclada = existente.copyWith(
                  nome: (existente.nome.isEmpty ||
                          existente.nome.toLowerCase() == 'blackview')
                      ? u.nome
                      : existente.nome,
                  nomeDeUsuario: existente.nomeDeUsuario.isEmpty
                      ? u.nomeDeUsuario
                      : existente.nomeDeUsuario,
                  apelido:
                      existente.apelido.isEmpty ? u.apelido : existente.apelido,
                  foto: existente.foto.isEmpty ? u.foto : existente.foto,
                  emails: {...existente.emails, ...u.emails}.toList(),
                );
                await ContasNousService.salvar(mesclada);
              }
            }
          }
        }
        _responderJson(request, {'sucesso': true});
        return;
      } catch (e) {
        _responderJson(
          request,
          {'sucesso': false, 'erro': e.toString()},
          statusCode: HttpStatus.badRequest,
        );
        return;
      }
    }

    // 8.1 Sincronização Pan-Dispositivo de Perfis e Lojas por CPF (Ontologia do Cidadão)
    if (path == '/api/sincronizar_perfis_usuario' && request.method == 'POST') {
      try {
        final body = await utf8.decodeStream(request);
        final dados = jsonDecode(body) as Map<String, dynamic>;
        final cpf = (dados['cpf'] as String? ?? '').replaceAll(RegExp(r'\D'), '');

        if (cpf.isNotEmpty) {
          final referenciasRecebidas =
              dados['referencias'] as List<dynamic>? ?? [];
          final lojasRecebidas = dados['lojas'] as List<dynamic>? ?? [];

          // 1. Salva ou atualiza os snapshots das lojas recebidas nos devidos cofres
          for (final lJson in lojasRecebidas) {
            try {
              final loja = Loja.fromJson(lJson as Map<String, dynamic>);
              final lojaExistente = await LojasService.carregarLojaPorId(loja.id);
              final lojaConsolidada = LojasService.consolidarLojaComImagensLocais(loja, lojaExistente);
              await LojasService.salvarLojaIndividual(lojaConsolidada);
            } catch (e) {
              debugPrint('[ServidorRedeLocal] Erro ao salvar loja recebida: $e');
            }
          }

          // 2. Salva as referências recebidas para esse CPF
          for (final rJson in referenciasRecebidas) {
            try {
              final ref =
                  ReferenciaLoja.fromJson(rJson as Map<String, dynamic>);
              await LojasService.adicionarReferencia(cpf, ref);
            } catch (e) {
              debugPrint(
                  '[ServidorRedeLocal] Erro ao salvar referência recebida: $e');
            }
          }

          // 3. Recarrega o PdvProvider do servidor para refletir instantaneamente novas lojas e logos
          final cpfServidor =
              _authProvider?.cpf.replaceAll(RegExp(r'\D'), '') ?? '';
          if (cpfServidor == cpf) {
            await _pdvProvider?.entrarComCpf(cpf);
          } else if (cpfServidor.isNotEmpty) {
            await _pdvProvider?.entrarComCpf(cpfServidor);
          }

          // 4. Coleta apenas as referências válidas e lojas do servidor associadas a esse CPF para devolver ao cliente
          final referenciasLocais =
              await LojasService.carregarReferencias(cpf);
          final referenciasValidas = <ReferenciaLoja>[];
          final lojasDoServidor = <Map<String, dynamic>>[];
          for (final r in referenciasLocais) {
            final l = await LojasService.carregarLojaPorId(r.lojaId);
            if (l != null) {
              final cpfDonoDigitos = l.cpfDonoOriginal.replaceAll(RegExp(r'\D'), '');
              final ehMembro = l.membros.any((m) =>
                  m.cpf.replaceAll(RegExp(r'\D'), '') == cpf);
              if (ehMembro || cpfDonoDigitos == cpf) {
                referenciasValidas.add(r);
                lojasDoServidor.add(LojasService.sanitizarCaminhosImagens(l).toJson());
              } else {
                // O usuário não é mais membro nem dono desta loja: remove referência órfã
                await LojasService.removerReferencia(cpf, r.lojaId);
              }
            } else {
              await LojasService.removerReferencia(cpf, r.lojaId);
            }
          }
          final lojasProprias = await LojasService.carregar(cpf);
          for (final lp in lojasProprias) {
            if (!lojasDoServidor.any((m) => m['id'] == lp.id)) {
              lojasDoServidor.add(LojasService.sanitizarCaminhosImagens(lp).toJson());
            }
          }

          _responderJson(request, {
            'sucesso': true,
            'referencias': referenciasValidas.map((r) => r.toJson()).toList(),
            'lojas': lojasDoServidor,
          });
          return;
        }

        _responderJson(request, {'sucesso': false, 'erro': 'CPF vazio'},
            statusCode: HttpStatus.badRequest);
        return;
      } catch (e) {
        debugPrint(
            '[ServidorRedeLocal] Erro em /api/sincronizar_perfis_usuario: $e');
        _responderJson(request, {'sucesso': false, 'erro': e.toString()},
            statusCode: HttpStatus.internalServerError);
        return;
      }
    }

    // 8.1 Sair de uma loja via rede local
    if (path == '/api/loja/sair' && request.method == 'POST') {
      try {
        final body = await utf8.decodeStream(request);
        final dados = jsonDecode(body) as Map<String, dynamic>;
        final cpf = (dados['cpf'] as String? ?? '').replaceAll(RegExp(r'\D'), '');
        final lojaId = dados['lojaId'] as String? ?? '';

        if (cpf.isNotEmpty && lojaId.isNotEmpty) {
          final loja = await LojasService.carregarLojaPorId(lojaId);
          if (loja != null) {
            final novosMembros = loja.membros.where(
              (m) => m.cpf.replaceAll(RegExp(r'\D'), '') != cpf,
            ).toList();
            final lojaAtualizada = loja.copyWith(membros: novosMembros);
            await LojasService.salvarLojaIndividual(lojaAtualizada);
            await LojasService.removerReferencia(cpf, lojaId);

            if (_lojaAtiva?.id == lojaId) {
              _lojaAtiva = lojaAtualizada;
            }
            if (_pdvProvider != null) {
              await _pdvProvider!.adicionarOuAtualizarLoja(lojaAtualizada);
            }

            notificarLojaAtualizada(lojaAtualizada);
          }
          _responderJson(request, {'sucesso': true});
          return;
        }

        _responderJson(request, {'sucesso': false, 'erro': 'Dados incompletos'},
            statusCode: HttpStatus.badRequest);
        return;
      } catch (e) {
        _responderJson(request, {'sucesso': false, 'erro': e.toString()},
            statusCode: HttpStatus.internalServerError);
        return;
      }
    }

    // 9. Informações de versão e atualização na rede local
    if (path == '/api/versao' && request.method == 'GET') {
      final arquivoApk = _obterArquivoApk();
      final temApk = arquivoApk != null && arquivoApk.existsSync() && arquivoApk.lengthSync() > 0;
      final tamanho = temApk ? arquivoApk.lengthSync() : 0;
      final novidade = ChangelogService.obterUltimaVersao(AtualizacaoService.versaoAtual);

      _responderJson(request, {
        'sucesso': true,
        'versao': AtualizacaoService.versaoAtual,
        'build': AtualizacaoService.buildAtual,
        'temApk': temApk,
        'tamanhoBytes': tamanho,
        'nomeArquivo': 'Nous_Android_v${AtualizacaoService.versaoAtual}.apk',
        'alteracoes': novidade?.alteracoes ?? <String>[],
      });
      return;
    }

    // 10. Download direto do APK pela rede Wi-Fi local
    if (path == '/api/download_apk' && request.method == 'GET') {
      final arquivoApk = _obterArquivoApk();
      if (arquivoApk == null || !arquivoApk.existsSync()) {
        _responderJson(
          request,
          {'sucesso': false, 'mensagem': 'Arquivo APK não encontrado em dist/'},
          statusCode: HttpStatus.notFound,
        );
        return;
      }

      try {
        request.response.headers.contentType =
            ContentType('application', 'vnd.android.package-archive');
        request.response.headers.set(
          'Content-Disposition',
          'attachment; filename="Nous_Android_v${AtualizacaoService.versaoAtual}.apk"',
        );
        request.response.headers.contentLength = arquivoApk.lengthSync();
        await request.response.addStream(arquivoApk.openRead());
        await request.response.close();
        debugPrint('[ServidorRedeLocal] APK transmitido com sucesso via Wi-Fi!');
        return;
      } catch (e) {
        debugPrint('[ServidorRedeLocal] Erro ao servir APK: $e');
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
        return;
      }
    }

    // 11. Envio de mensagem de chat via REST (fallback e redundância)
    if (path == '/api/chat/mensagem' && request.method == 'POST') {
      try {
        final body = await utf8.decodeStream(request);
        final dados = jsonDecode(body) as Map<String, dynamic>;
        final msgJson = dados['mensagem'] as Map<String, dynamic>? ?? dados;
        await ChatService.processarMensagemRecebidaDaRede(msgJson,
            emitirAlertaSonoro: false);
        notificarTodos({'tipo': 'mensagem_chat', 'mensagem': msgJson});
        _responderJson(request, {'sucesso': true});
        return;
      } catch (e) {
        _responderJson(request, {'sucesso': false, 'erro': e.toString()},
            statusCode: HttpStatus.internalServerError);
        return;
      }
    }

    // 12. Sincronização de mensagens de chat pela rede Wi-Fi
    if (path == '/api/chat/mensagens' && request.method == 'GET') {
      try {
        final cpf = request.uri.queryParameters['cpf'];
        final lojaId = request.uri.queryParameters['lojaId'];
        final mensagens = await ChatService.obterMensagensParaSincronizacao(
          cpf: cpf,
          lojaId: lojaId,
        );
        _responderJson(request, {'sucesso': true, 'mensagens': mensagens});
        return;
      } catch (e) {
        _responderJson(request, {'sucesso': false, 'erro': e.toString()},
            statusCode: HttpStatus.internalServerError);
        return;
      }
    }

    // 13. Sincronização de conversas e grupos pela rede Wi-Fi (GET)
    if (path == '/api/chat/conversas' && request.method == 'GET') {
      try {
        final cpf = request.uri.queryParameters['cpf'];
        final lojaId = request.uri.queryParameters['lojaId'];
        final conversas = await ChatService.obterConversasParaSincronizacao(
          cpf: cpf,
          lojaId: lojaId,
        );
        _responderJson(request, {'sucesso': true, 'conversas': conversas});
        return;
      } catch (e) {
        _responderJson(request, {'sucesso': false, 'erro': e.toString()},
            statusCode: HttpStatus.internalServerError);
        return;
      }
    }

    // 14. Sincronização bidirecional enviada pelo cliente terminal móvel (POST)
    if (path == '/api/chat/conversas/sync' && request.method == 'POST') {
      try {
        final body = await utf8.decodeStream(request);
        final dados = jsonDecode(body) as Map<String, dynamic>;
        if (dados['conversas'] is List) {
          for (final c in dados['conversas'] as List<dynamic>) {
            if (c is Map<String, dynamic>) {
              await ChatService.salvarConversaLocal(c);
            }
          }
        }
        if (dados['mensagens'] is List) {
          for (final m in dados['mensagens'] as List<dynamic>) {
            if (m is Map<String, dynamic>) {
              final msg = MensagemChat.fromJson(m);
              await ChatService.salvarMensagem(msg, originadaDaRede: true);
            }
          }
        }
        _responderJson(request, {'sucesso': true});
        return;
      } catch (e) {
        _responderJson(request, {'sucesso': false, 'erro': e.toString()},
            statusCode: HttpStatus.internalServerError);
        return;
      }
    }

    // Rota não encontrada
    _responderJson(
      request,
      {'sucesso': false, 'mensagem': 'Rota não encontrada: $path'},
      statusCode: HttpStatus.notFound,
    );
  }

  Future<void> _tratarMensagemWs(WebSocket ws, dynamic msg) async {
    try {
      final dados = jsonDecode(msg as String) as Map<String, dynamic>;
      final tipo = dados['tipo'];

      if (tipo == 'ping') {
        ws.add(jsonEncode({'tipo': 'pong', 'timestamp': DateTime.now().millisecondsSinceEpoch}));
      } else if (tipo == 'identificacao') {
        final nome = dados['nomeDispositivo'] as String?;
        final cpf = dados['cpf'] as String?;
        final nomeUsuario = dados['nomeUsuario'] as String?;
        final apelido = dados['apelido'] as String?;
        final foto = dados['foto'] as String?;
        final terminal = _terminaisWs[ws];
        if (terminal != null) {
          if (nome != null && nome.trim().isNotEmpty) {
            terminal.nome = nome.trim();
          }
          if (cpf != null && cpf.trim().isNotEmpty) {
            terminal.cpf = cpf.trim();
          }
          if (nomeUsuario != null && nomeUsuario.trim().isNotEmpty) {
            terminal.nomeUsuario = nomeUsuario.trim();
          }
          if (apelido != null && apelido.trim().isNotEmpty) {
            terminal.apelido = apelido.trim();
          }
          _atualizarListasTerminais();
          debugPrint(
            '[ServidorRedeLocal] Terminal identificado: "${terminal.nome}" (CPF: ${terminal.cpf}, Nome: ${terminal.nomeUsuario}, Apelido: ${terminal.apelido}, IP: ${terminal.ip})',
          );

          // Verifica se o CPF ainda não é membro da loja e garante sua inclusão
          await _garantirMembroConectado(terminal);

          // Unifica e consolida a Identidade do Usuário no banco de contas local do balcão
          _consolidarContaTerminal(terminal);

          if (cpf != null && cpf.trim().isNotEmpty && foto != null && foto.trim().isNotEmpty) {
            final fotoResolvida = ImagemService.resolverCaminhoExistente(foto);
            if (fotoResolvida != null) {
              final c = await ContasNousService.buscarPorCpf(cpf.trim());
              if (c != null && (c.foto.isEmpty || !ImagemService.existe(c.foto))) {
                await ContasNousService.salvar(c.copyWith(foto: fotoResolvida));
              }
            }
          }

          // Notifica todos com a lista de presenças atualizada
          notificarPresencas();
        }
      } else if (tipo == 'mensagem_chat') {
        if (dados['mensagem'] != null) {
          final msgJson = dados['mensagem'] as Map<String, dynamic>;
          final msg = MensagemChat.fromJson(msgJson);
          await ChatService.processarMensagemRecebidaDaRede(msgJson,
              emitirAlertaSonoro: false);

          // Se a mensagem vier com foto do remetente e a conta no servidor estiver sem foto, cura a foto
          final cpfRemetente = ChatService.normalizarCpf(msg.remetenteId);
          if (cpfRemetente.length == 11 && msg.remetenteFoto.isNotEmpty) {
            final fotoResolvida = ImagemService.resolverCaminhoExistente(msg.remetenteFoto);
            if (fotoResolvida != null) {
              final c = await ContasNousService.buscarPorCpf(cpfRemetente);
              if (c != null && (c.foto.isEmpty || !ImagemService.existe(c.foto))) {
                await ContasNousService.salvar(c.copyWith(foto: fotoResolvida));
              }
            }
          }

          // Retransmite para todos os outros terminais conectados via WebSocket
          final payload = jsonEncode({'tipo': 'mensagem_chat', 'mensagem': msgJson});
          for (final cliente in List<WebSocket>.from(_clientesWs)) {
            if (cliente != ws) {
              try {
                cliente.add(payload);
              } catch (_) {}
            }
          }
        }
      } else if (tipo == 'mensagem_entregue' || tipo == 'mensagens_lidas') {
        await ChatService.processarMensagemRecebidaDaRede(dados, emitirAlertaSonoro: false);
        final payload = jsonEncode(dados);
        for (final cliente in List<WebSocket>.from(_clientesWs)) {
          if (cliente != ws) {
            try {
              cliente.add(payload);
            } catch (_) {}
          }
        }
      } else if (tipo == 'usuario_atualizado') {
        if (dados['usuario'] != null) {
          try {
            final usuario = UsuarioNous.fromJson(dados['usuario'] as Map<String, dynamic>);
            await ContasNousService.salvar(usuario);
            _authProvider?.atualizarContaNoCache(usuario);
            _pdvProvider?.notificarMudanca();

            final payload = jsonEncode({'tipo': 'usuario_atualizado', 'usuario': usuario.toJson()});
            for (final cliente in List<WebSocket>.from(_clientesWs)) {
              if (cliente != ws) {
                try {
                  cliente.add(payload);
                } catch (_) {}
              }
            }
          } catch (e) {
            debugPrint('[ServidorRedeLocal] Erro ao processar usuario_atualizado via WS: $e');
          }
        }
      } else if (tipo == 'pedido_atualizado') {
        if (dados['pedido'] != null && _pdvProvider != null && _lojaAtiva != null) {
          final pedido = PedidoLoja.fromJson(dados['pedido'] as Map<String, dynamic>);
          final lojaAtual = _pdvProvider!.buscarPorId(_lojaAtiva!.id);
          if (lojaAtual != null) {
            final pedidos = List<PedidoLoja>.from(lojaAtual.pedidosLoja);
            final idx = pedidos.indexWhere((p) => p.id == pedido.id);
            if (idx != -1) {
              pedidos[idx] = pedido;
            } else {
              pedidos.insert(0, pedido);
            }
            _pdvProvider!.atualizarListasLoja(lojaAtual.id, pedidos: pedidos);

            // Retransmite para todos os outros clientes
            final payload = jsonEncode({'tipo': 'pedido_atualizado', 'pedido': pedido.toJson()});
            for (final cliente in List<WebSocket>.from(_clientesWs)) {
              if (cliente != ws) {
                try {
                  cliente.add(payload);
                } catch (_) {}
              }
            }
          }
        }
      } else if (tipo == 'loja_excluida') {
        final lojaId = dados['lojaId'] as String?;
        if (lojaId != null && _pdvProvider != null) {
          await _pdvProvider!.excluirLoja(lojaId, originadaDaRede: true);
          final payload = jsonEncode({'tipo': 'loja_excluida', 'lojaId': lojaId});
          for (final cliente in List<WebSocket>.from(_clientesWs)) {
            if (cliente != ws) {
              try {
                cliente.add(payload);
              } catch (_) {}
            }
          }
        }
      }
    } catch (_) {}
  }

  /// Retorna todos os dispositivos ativos conectados à loja, incluindo o balcão se ativo.
  List<TerminalConectadoInfo> obterTodasPresencas() {
    final lista = <TerminalConectadoInfo>[];
    if (ativo && _lojaAtiva != null) {
      final hostNome = Platform.localHostname;
      final usuarioLogado = _authProvider?.contaAtual;
      final cpfPdv = _pdvProvider?.cpfAtual ?? '';
      final cpfBalcao = (usuarioLogado != null && usuarioLogado.cpf.trim().isNotEmpty)
          ? usuarioLogado.cpf.trim()
          : (cpfPdv.trim().isNotEmpty
              ? cpfPdv.trim()
              : _lojaAtiva!.cpfDonoOriginal);
      final nomeBalcao = (usuarioLogado != null && usuarioLogado.nome.trim().isNotEmpty)
          ? usuarioLogado.nome.trim()
          : 'Operador Balcão';

      lista.add(
        TerminalConectadoInfo(
          id: 'balcao_servidor_local',
          nome: hostNome.isNotEmpty ? 'Computador Balcão ($hostNome)' : 'Computador Balcão (Local)',
          ip: _ipServidor ?? '127.0.0.1',
          conectadoEm: _dataHoraInicio ?? DateTime.now(),
          cpf: cpfBalcao,
          nomeUsuario: nomeBalcao,
          tipoConexao: 'membro',
        ),
      );
    }
    lista.addAll(_terminaisWs.values);
    return lista;
  }

  /// Notifica todos os terminais com a lista de presenças ativas em tempo real
  void notificarPresencas() {
    final presencas = obterTodasPresencas();
    notificarTodos({
      'tipo': 'presencas_atualizadas',
      'presencas': presencas.map((p) => p.toJson()).toList(),
    });
  }

  /// Adiciona automaticamente um novo usuário como membro da loja ao conectar pela primeira vez no Wi-Fi
  Future<Loja?> _garantirMembroConectado(TerminalConectadoInfo terminal) async {
    final cpfLimpo = terminal.cpf?.replaceAll(RegExp(r'\D'), '');
    if (cpfLimpo == null || cpfLimpo.isEmpty || _lojaAtiva == null || _pdvProvider == null) {
      return _lojaAtiva;
    }

    final lojaAtual = _pdvProvider!.buscarPorId(_lojaAtiva!.id) ?? _lojaAtiva!;
    final cpfDonoLimpo = lojaAtual.cpfDonoOriginal.replaceAll(RegExp(r'\D'), '');
    if (cpfLimpo == cpfDonoLimpo) {
      // É o dono acessando por outro dispositivo (ex.: celular do dono)
      return lojaAtual;
    }

    final jaEhMembro = lojaAtual.membros.any(
      (m) => m.cpf.replaceAll(RegExp(r'\D'), '') == cpfLimpo,
    );

    if (!jaEhMembro) {
      debugPrint('[ServidorRedeLocal] Auto-associando membro na loja via Wi-Fi: CPF $cpfLimpo (${terminal.nome})');
      String nomeFinal = (terminal.apelido != null && terminal.apelido!.trim().isNotEmpty)
          ? terminal.apelido!.trim()
          : ((terminal.nomeUsuario != null && terminal.nomeUsuario!.trim().isNotEmpty)
              ? terminal.nomeUsuario!.trim()
              : '');
      if (nomeFinal.isEmpty) {
        final conta = await ContasNousService.buscarPorCpf(terminal.cpf!);
        if (conta != null) {
          nomeFinal = conta.apelido.trim().isNotEmpty
              ? conta.apelido.trim()
              : conta.nome.trim();
        }
      }
      if (nomeFinal.isEmpty) {
        final dadosAuto = await DadosLocaisService.buscarPorDocumento(terminal.cpf!);
        if (dadosAuto != null && dadosAuto.nome.trim().isNotEmpty) {
          nomeFinal = dadosAuto.nome.trim();
        }
      }
      if (nomeFinal.isEmpty) {
        nomeFinal = terminal.nome.isNotEmpty ? terminal.nome : 'Funcionário';
      }

      final novoMembro = MembroLoja(
        cpf: terminal.cpf!,
        nome: nomeFinal,
        papel: PapelMembro.funcionario,
        desde: DateTime.now(),
      );

      final novosMembros = List<MembroLoja>.from(lojaAtual.membros)..add(novoMembro);
      final lojaAtualizada = lojaAtual.copyWith(membros: novosMembros);
      _lojaAtiva = lojaAtualizada;
      await _pdvProvider!.adicionarOuAtualizarLoja(lojaAtualizada);

      // Notifica todos os terminais com os dados completos da loja atualizada
      notificarTodos({
        'tipo': 'loja_atualizada',
        'loja': lojaAtualizada.toJson(),
      });
      return lojaAtualizada;
    }
    return lojaAtual;
  }

  /// Registra ou atualiza um usuário como cliente da loja ao conectar via Wi-Fi como Cliente
  Future<Loja?> _garantirClienteConectado(TerminalConectadoInfo terminal) async {
    final cpfLimpo = terminal.cpf?.replaceAll(RegExp(r'\D'), '');
    if (cpfLimpo == null || cpfLimpo.isEmpty || _lojaAtiva == null || _pdvProvider == null) {
      return _lojaAtiva;
    }

    final lojaAtual = _pdvProvider!.buscarPorId(_lojaAtiva!.id) ?? _lojaAtiva!;
    final jaEhCliente = lojaAtual.clientesLoja.any(
      (c) => c.cnpj.replaceAll(RegExp(r'\D'), '') == cpfLimpo,
    );

    if (!jaEhCliente) {
      String nomeFinal = (terminal.nomeUsuario != null && terminal.nomeUsuario!.trim().isNotEmpty)
          ? terminal.nomeUsuario!.trim()
          : ((terminal.apelido != null && terminal.apelido!.trim().isNotEmpty)
              ? terminal.apelido!.trim()
              : 'Cliente');

      String fotoCliente = '';
      final conta = await ContasNousService.buscarPorCpf(terminal.cpf!);
      if (conta != null) {
        if (conta.nome.trim().isNotEmpty) nomeFinal = conta.nome.trim();
        fotoCliente = conta.foto;
      }

      final novoCliente = Cliente(
        id: 'cli_${DateTime.now().millisecondsSinceEpoch}',
        nome: nomeFinal,
        cnpj: terminal.cpf!,
        foto: fotoCliente,
      );

      final novosClientes = List<Cliente>.from(lojaAtual.clientesLoja)..add(novoCliente);
      final lojaAtualizada = lojaAtual.copyWith(clientesLoja: novosClientes);
      _lojaAtiva = lojaAtualizada;
      await _pdvProvider!.adicionarOuAtualizarLoja(lojaAtualizada);

      notificarTodos({
        'tipo': 'loja_atualizada',
        'loja': lojaAtualizada.toJson(),
      });
      return lojaAtualizada;
    }
    return lojaAtual;
  }

  /// Consolida e unifica a ficha de Identidade do Usuário no banco de contas local do balcão
  void _consolidarContaTerminal(TerminalConectadoInfo terminal) async {
    final cpfLimpo = terminal.cpf?.replaceAll(RegExp(r'\D'), '');
    if (cpfLimpo == null || cpfLimpo.isEmpty) return;

    try {
      final contaExistente =
          await ContasNousService.buscarPorCpf(terminal.cpf!);
      final dadosAuto =
          await DadosLocaisService.buscarPorDocumento(terminal.cpf!);

      String nome = (terminal.nomeUsuario != null &&
              terminal.nomeUsuario!.trim().isNotEmpty)
          ? terminal.nomeUsuario!.trim()
          : '';
      // Hardware NUNCA é identidade do cidadão: ignora nomes de aparelhos
      if (nome.isEmpty ||
          nome.toLowerCase() == 'blackview' ||
          nome.toLowerCase() == 'celular') {
        nome = (dadosAuto != null && dadosAuto.nome.trim().isNotEmpty)
            ? dadosAuto.nome.trim()
            : 'Usuário Nous';
      }

      final apelido = (terminal.apelido != null &&
              terminal.apelido!.trim().isNotEmpty &&
              terminal.apelido!.toLowerCase() != 'blackview')
          ? terminal.apelido!.trim()
          : '';

      if (contaExistente == null) {
        final novaConta = UsuarioNous(
          cpf: terminal.cpf!,
          nome: nome,
          apelido: apelido.isNotEmpty
              ? apelido
              : (dadosAuto?.apelido ?? (dadosAuto?.nome ?? nome)),
          dataNascimento: dadosAuto?.dataNascimento ?? '',
          foto: dadosAuto?.foto ?? '',
        );
        await ContasNousService.salvar(novaConta);
        debugPrint(
          '[ServidorRedeLocal] Ficha de conta unificada no balcão para CPF $cpfLimpo (${novaConta.nome})',
        );
      } else {
        var atualizada = contaExistente;
        // Corrige se a conta no banco estava com nome espúrio de aparelho
        if (contaExistente.nome.isEmpty ||
            contaExistente.nome.toLowerCase() == 'blackview') {
          atualizada = atualizada.copyWith(nome: nome);
        }
        if (apelido.isNotEmpty &&
            contaExistente.apelido != apelido &&
            contaExistente.apelido.toLowerCase() != 'blackview') {
          atualizada = atualizada.copyWith(apelido: apelido);
        }
        if (contaExistente.foto.isEmpty &&
            dadosAuto != null &&
            dadosAuto.foto.isNotEmpty &&
            ImagemService.existe(dadosAuto.foto)) {
          atualizada = atualizada.copyWith(foto: dadosAuto.foto);
        }
        if (atualizada != contaExistente) {
          await ContasNousService.salvar(atualizada);
        }
      }
    } catch (e) {
      debugPrint('[ServidorRedeLocal] Erro ao consolidar conta de terminal: $e');
    }
  }

  /// Envia mensagem para todos os terminais conectados
  void notificarTodos(Map<String, dynamic> dados) {
    final payload = jsonEncode(dados);
    for (final ws in List<WebSocket>.from(_clientesWs)) {
      try {
        ws.add(payload);
      } catch (_) {}
    }
  }

  /// Notifica todos os terminais conectados que a loja foi alterada
  void notificarLojaAtualizada(Loja loja) {
    if (!ativo) return;
    if (_lojaAtiva == null || _lojaAtiva!.id == loja.id) {
      _lojaAtiva = loja;
      notificarTodos({
        'tipo': 'loja_atualizada',
        'loja': loja.toJson(),
      });
      debugPrint(
        '[ServidorRedeLocal] Transmitida atualização da loja "${loja.nome}" para ${_clientesWs.length} terminais',
      );
    }
  }

  /// Dispara anúncio UDP contínuo (broadcast) na rede local para descoberta automática
  void _iniciarAnuncioUdp() async {
    try {
      _socketUdp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _socketUdp!.broadcastEnabled = true;

      _timerUdp?.cancel();
      _timerUdp = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!ativo || _lojaAtiva == null || _socketUdp == null) return;
        try {
          final pacote = jsonEncode({
            'assinatura': 'nous_loja_anuncio',
            'lojaId': _lojaAtiva!.id,
            'lojaNome': _lojaAtiva!.nome,
            'ip': _ipServidor,
            'porta': _porta,
          });
          final bytes = utf8.encode(pacote);
          _socketUdp!.send(
            bytes,
            InternetAddress('255.255.255.255'),
            portaUdpAnuncio,
          );
        } catch (_) {}
      });
    } catch (e) {
      debugPrint('[ServidorRedeLocal] Erro ao iniciar broadcast UDP: $e');
    }
  }

  /// Localiza o arquivo binário do APK Android correspondente à versão atual no armazenamento local do computador balcão
  File? _obterArquivoApk() {
    try {
      final pastaExe = File(Platform.resolvedExecutable).parent.path;
      final versao = AtualizacaoService.versaoAtual;
      final caminhos = [
        '$pastaExe/dist/Nous_Android_v${versao}_Versao_Teste.apk',
        '$pastaExe/Nous_Android_v${versao}_Versao_Teste.apk',
        'dist/Nous_Android_v${versao}_Versao_Teste.apk',
        '${Directory.current.path}/dist/Nous_Android_v${versao}_Versao_Teste.apk',
        'D:/Nous/nous/dist/Nous_Android_v${versao}_Versao_Teste.apk',
      ];

      for (final c in caminhos) {
        final f = File(c);
        if (f.existsSync() && f.lengthSync() > 0) {
          return f;
        }
      }

      // Busca dinâmica nas pastas dist estritamente por arquivos com a versão atual
      final pastas = [
        Directory('$pastaExe/dist'),
        Directory(pastaExe),
        Directory('dist'),
        Directory('${Directory.current.path}/dist'),
        Directory('D:/Nous/nous/dist'),
      ];
      for (final pasta in pastas) {
        if (pasta.existsSync()) {
          final apks = pasta
              .listSync()
              .whereType<File>()
              .where((f) =>
                  f.path.toLowerCase().endsWith('.apk') &&
                  f.lengthSync() > 0 &&
                  f.path.contains('v$versao'))
              .toList();
          if (apks.isNotEmpty) {
            return apks.first;
          }
        }
      }

      // Fallback seguro: se não encontrou com a string exata 'v$versao', seleciona o APK mais recente da pasta dist
      for (final pasta in pastas) {
        if (pasta.existsSync()) {
          final apks = pasta
              .listSync()
              .whereType<File>()
              .where((f) =>
                  f.path.toLowerCase().endsWith('.apk') &&
                  f.lengthSync() > 0)
              .toList();
          if (apks.isNotEmpty) {
            apks.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
            return apks.first;
          }
        }
      }

      debugPrint(
        '[ServidorRedeLocal] Nenhum APK encontrado para distribuição.',
      );
    } catch (e) {
      debugPrint('[ServidorRedeLocal] Erro ao buscar APK: $e');
    }
    return null;
  }

  void _responderJson(
    HttpRequest request,
    Map<String, dynamic> json, {
    int statusCode = HttpStatus.ok,
  }) {
    request.response
      ..statusCode = statusCode
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(json));
    request.response.close();
  }

  /// Exibe um diálogo na tela do computador balcão solicitando permissão para novo terminal conectar.
  Future<ResultadoAutorizacaoConexao> _solicitarAutorizacaoTerminal({
    required String ip,
    required String nomeDispositivo,
    String? nomeUsuario,
    String? cpf,
    required bool jaEhMembro,
  }) async {
    final context = NavigatorKeyService.currentContext;
    if (context == null || !context.mounted) {
      return jaEhMembro
          ? ResultadoAutorizacaoConexao.autorizadoMembro
          : ResultadoAutorizacaoConexao.autorizadoCliente;
    }

    SomService.tocarBipPadrao();

    final completer = Completer<ResultadoAutorizacaoConexao>();
    var respondido = false;
    String tipoAcesso = 'cliente';

    showDialog<ResultadoAutorizacaoConexao>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        final theme = ThemeController.currentTheme.value;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.cardBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: BorderSide(color: theme.borderColor),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.security_rounded, color: theme.textColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Solicitação de Acesso',
                    style: theme.getTextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Um terminal móvel está solicitando sincronização com esta loja na rede Wi-Fi:',
                        textAlign: TextAlign.center,
                        style: theme.getTextStyle(fontSize: 13, color: theme.textColor),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.backgroundColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: theme.borderColor.withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _itemInfoDialog(theme, 'Aparelho:', nomeDispositivo, Icons.smartphone_rounded),
                            if (nomeUsuario != null && nomeUsuario.trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              _itemInfoDialog(theme, 'Usuário:', nomeUsuario.trim(), Icons.person_rounded),
                            ],
                            if (cpf != null && cpf.trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              _itemInfoDialog(theme, 'CPF:', cpf.trim(), Icons.badge_outlined),
                            ],
                            const SizedBox(height: 6),
                            _itemInfoDialog(theme, 'Endereço IP:', ip, Icons.wifi_rounded),
                            if (jaEhMembro) ...[
                              const SizedBox(height: 6),
                              _itemInfoDialog(theme, 'Vínculo:', 'Já cadastrado na equipe da loja', Icons.verified_user_outlined),
                            ],
                          ],
                        ),
                      ),
                      if (!jaEhMembro) ...[
                        const SizedBox(height: 14),
                        Text(
                          'Como este usuário entrará na loja?',
                          style: theme.getTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Opção Cliente
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => setDialogState(() => tipoAcesso = 'cliente'),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: tipoAcesso == 'cliente'
                                  ? theme.borderColor.withValues(alpha: 0.25)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: tipoAcesso == 'cliente'
                                    ? theme.textColor
                                    : theme.borderColor.withValues(alpha: 0.4),
                                width: tipoAcesso == 'cliente' ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  tipoAcesso == 'cliente'
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  size: 18,
                                  color: theme.textColor,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Cliente da Loja',
                                        style: theme.getTextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: theme.textColor,
                                        ),
                                      ),
                                      Text(
                                        'Poderá consultar cardápio e fazer pedidos futuros. Sem gerência.',
                                        style: theme.getTextStyle(
                                          fontSize: 11,
                                          color: theme.secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Opção Membro da Loja
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => setDialogState(() => tipoAcesso = 'membro'),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: tipoAcesso == 'membro'
                                  ? theme.borderColor.withValues(alpha: 0.25)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: tipoAcesso == 'membro'
                                    ? theme.textColor
                                    : theme.borderColor.withValues(alpha: 0.4),
                                width: tipoAcesso == 'membro' ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  tipoAcesso == 'membro'
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  size: 18,
                                  color: theme.textColor,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Novo Membro da Loja',
                                        style: theme.getTextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: theme.textColor,
                                        ),
                                      ),
                                      Text(
                                        'Adiciona à equipe de trabalhadores com acesso operacional.',
                                        style: theme.getTextStyle(
                                          fontSize: 11,
                                          color: theme.secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Text(
                        'Você autoriza que este aparelho se conecte e sincronize com a loja?',
                        textAlign: TextAlign.center,
                        style: theme.getTextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: () {
                    if (!respondido) {
                      respondido = true;
                      Navigator.of(dialogCtx).pop(ResultadoAutorizacaoConexao.recusado);
                      if (!completer.isCompleted) {
                        completer.complete(ResultadoAutorizacaoConexao.recusado);
                      }
                    }
                  },
                  child: Text(
                    'Recusar',
                    style: theme.getTextStyle(
                      color: theme.dangerColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.buttonColor,
                    foregroundColor: theme.buttonTextColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (!respondido) {
                      respondido = true;
                      final resultado = jaEhMembro || tipoAcesso == 'membro'
                          ? ResultadoAutorizacaoConexao.autorizadoMembro
                          : ResultadoAutorizacaoConexao.autorizadoCliente;
                      Navigator.of(dialogCtx).pop(resultado);
                      if (!completer.isCompleted) completer.complete(resultado);
                    }
                  },
                  child: Text(
                    'Autorizar',
                    style: theme.getTextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.buttonTextColor,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    // Timeout de segurança de 45 segundos para não prender a conexão caso o operador esteja ausente
    Future.delayed(const Duration(seconds: 45), () {
      if (!respondido) {
        respondido = true;
        if (context.mounted) {
          try {
            Navigator.of(context, rootNavigator: true).pop(ResultadoAutorizacaoConexao.recusado);
          } catch (_) {}
        }
        if (!completer.isCompleted) {
          completer.complete(ResultadoAutorizacaoConexao.recusado);
        }
      }
    });

    return completer.future;
  }

  static Widget _itemInfoDialog(AppTheme theme, String rotulo, String valor, IconData icone) {
    return Row(
      children: [
        Icon(icone, size: 16, color: theme.secondaryTextColor),
        const SizedBox(width: 6),
        Text(
          rotulo,
          style: theme.getTextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.secondaryTextColor,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            valor,
            overflow: TextOverflow.ellipsis,
            style: theme.getTextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
        ),
      ],
    );
  }
}
