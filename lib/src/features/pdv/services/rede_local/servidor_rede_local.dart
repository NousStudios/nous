import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nous/src/core/services/atualizacao_service.dart';
import 'package:nous/src/core/services/som_service.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';

/// Informações de um terminal móvel conectado ao balcão
class TerminalConectadoInfo {
  final String id;
  String nome;
  final String ip;
  final DateTime conectadoEm;
  String? cpf;
  String? nomeUsuario;

  TerminalConectadoInfo({
    required this.id,
    required this.nome,
    required this.ip,
    required this.conectadoEm,
    this.cpf,
    this.nomeUsuario,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'ip': ip,
        'conectadoEm': conectadoEm.toIso8601String(),
        'cpf': cpf,
        'nomeUsuario': nomeUsuario,
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

  String? _ipServidor;
  int _porta = portaPadraoHttp;
  Loja? _lojaAtiva;
  PdvProvider? _pdvProvider;

  final ValueNotifier<bool> estaAtivo = ValueNotifier<bool>(false);
  final ValueNotifier<int> totalConectados = ValueNotifier<int>(0);
  final ValueNotifier<List<TerminalConectadoInfo>> terminaisConectados =
      ValueNotifier<List<TerminalConectadoInfo>>([]);

  bool get ativo => _servidorHttp != null;
  String? get ipServidor => _ipServidor;
  int get porta => _porta;
  Loja? get lojaAtiva => _lojaAtiva;

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
    int portaInicial = portaPadraoHttp,
  }) async {
    if (ativo) {
      if (_lojaAtiva?.id == loja.id) {
        _lojaAtiva = loja;
        _pdvProvider = pdv;
        return true;
      }
      await parar();
    }

    _lojaAtiva = loja;
    _pdvProvider = pdv;
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

    estaAtivo.value = true;
    totalConectados.value = 0;
    debugPrint(
      '[ServidorRedeLocal] Loja "${loja.nome}" iniciada em http://$_ipServidor:$_porta',
    );

    // Escuta requisições HTTP e WebSockets
    _servidorHttp!.listen(_processarRequisicao, onError: (e) {
      debugPrint('[ServidorRedeLocal] Erro no servidor: $e');
    });

    // Inicia anúncio UDP para descoberta automática no Wi-Fi
    _iniciarAnuncioUdp();

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
          totalConectados.value = _clientesWs.length;
          terminaisConectados.value = _terminaisWs.values.toList();

          debugPrint(
            '[ServidorRedeLocal] Novo terminal conectado: $ipRemoto. Total: ${_clientesWs.length}',
          );

          // Envia dados iniciais da loja e lista de presenças ativas
          if (_lojaAtiva != null) {
            ws.add(
              jsonEncode({
                'tipo': 'dados_iniciais',
                'loja': _lojaAtiva!.toJson(),
                'presencas': obterTodasPresencas().map((p) => p.toJson()).toList(),
              }),
            );
          }

          ws.listen(
            (msg) => _tratarMensagemWs(ws, msg),
            onDone: () {
              _clientesWs.remove(ws);
              _terminaisWs.remove(ws);
              totalConectados.value = _clientesWs.length;
              terminaisConectados.value = _terminaisWs.values.toList();
              notificarPresencas();
            },
            onError: (_) {
              _clientesWs.remove(ws);
              _terminaisWs.remove(ws);
              totalConectados.value = _clientesWs.length;
              terminaisConectados.value = _terminaisWs.values.toList();
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

      final arquivo = File(caminho.trim());
      if (!await arquivo.exists()) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }

      try {
        final ext = caminho.split('.').last.toLowerCase();
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
      if (_lojaAtiva == null) {
        _responderJson(
          request,
          {'sucesso': false, 'mensagem': 'Nenhuma loja ativa'},
          statusCode: HttpStatus.notFound,
        );
        return;
      }
      _responderJson(request, {
        'sucesso': true,
        'loja': _lojaAtiva!.toJson(),
      });
      return;
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
            final existe = pedidos.any((p) => p.id == pedido.id);
            if (!existe) {
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

      final conta = await ContasNousService.buscarPorCpf(cpfParam.trim());
      if (conta == null) {
        _responderJson(
          request,
          {'sucesso': false, 'mensagem': 'Usuário não encontrado'},
          statusCode: HttpStatus.notFound,
        );
        return;
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
        final usuario = UsuarioNous.fromJson(dados);
        await ContasNousService.salvar(usuario);
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

    // 9. Informações de versão e atualização na rede local
    if (path == '/api/versao' && request.method == 'GET') {
      final arquivoApk = File('dist/Nous_Android_v1.0.0_Versao_Teste.apk');
      final temApk = arquivoApk.existsSync();
      final tamanho = temApk ? arquivoApk.lengthSync() : 0;

      _responderJson(request, {
        'sucesso': true,
        'versao': AtualizacaoService.versaoAtual,
        'build': AtualizacaoService.buildAtual,
        'temApk': temApk,
        'tamanhoBytes': tamanho,
        'nomeArquivo': 'Nous_Android_v1.0.0_Versao_Teste.apk',
      });
      return;
    }

    // 10. Download direto do APK pela rede Wi-Fi local
    if (path == '/api/download_apk' && request.method == 'GET') {
      final arquivoApk = File('dist/Nous_Android_v1.0.0_Versao_Teste.apk');
      if (!arquivoApk.existsSync()) {
        _responderJson(
          request,
          {'sucesso': false, 'mensagem': 'Arquivo APK não encontrado em dist/'},
          statusCode: HttpStatus.notFound,
        );
        return;
      }

      request.response.headers.contentType =
          ContentType('application', 'vnd.android.package-archive');
      request.response.headers.set(
        'Content-Disposition',
        'attachment; filename="Nous_Android_v1.0.0_Versao_Teste.apk"',
      );
      request.response.headers.contentLength = arquivoApk.lengthSync();
      await request.response.addStream(arquivoApk.openRead());
      await request.response.close();
      return;
    }

    // Rota não encontrada
    _responderJson(
      request,
      {'sucesso': false, 'mensagem': 'Rota não encontrada: $path'},
      statusCode: HttpStatus.notFound,
    );
  }

  void _tratarMensagemWs(WebSocket ws, dynamic msg) {
    try {
      final dados = jsonDecode(msg as String) as Map<String, dynamic>;
      final tipo = dados['tipo'];

      if (tipo == 'ping') {
        ws.add(jsonEncode({'tipo': 'pong', 'timestamp': DateTime.now().millisecondsSinceEpoch}));
      } else if (tipo == 'identificacao') {
        final nome = dados['nomeDispositivo'] as String?;
        final cpf = dados['cpf'] as String?;
        final nomeUsuario = dados['nomeUsuario'] as String?;
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
          terminaisConectados.value = _terminaisWs.values.toList();
          debugPrint(
            '[ServidorRedeLocal] Terminal identificado: "${terminal.nome}" (CPF: ${terminal.cpf}, Nome: ${terminal.nomeUsuario}, IP: ${terminal.ip})',
          );

          // Verifica se o CPF ainda não é membro da loja e garante sua inclusão
          _garantirMembroConectado(terminal);

          // Notifica todos com a lista de presenças atualizada
          notificarPresencas();
        }
      }
    } catch (_) {}
  }

  /// Retorna todos os dispositivos ativos conectados à loja, incluindo o balcão se ativo.
  List<TerminalConectadoInfo> obterTodasPresencas() {
    final lista = <TerminalConectadoInfo>[];
    if (ativo && _lojaAtiva != null) {
      lista.add(
        TerminalConectadoInfo(
          id: 'balcao_servidor_local',
          nome: 'Computador Balcão (Local)',
          ip: _ipServidor ?? '127.0.0.1',
          conectadoEm: DateTime.now(),
          cpf: _lojaAtiva!.cpfDonoOriginal,
          nomeUsuario: 'Dono Balcão',
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
  void _garantirMembroConectado(TerminalConectadoInfo terminal) async {
    final cpfLimpo = terminal.cpf?.replaceAll(RegExp(r'\D'), '');
    if (cpfLimpo == null || cpfLimpo.isEmpty || _lojaAtiva == null || _pdvProvider == null) {
      return;
    }

    final lojaAtual = _pdvProvider!.buscarPorId(_lojaAtiva!.id) ?? _lojaAtiva!;
    final cpfDonoLimpo = lojaAtual.cpfDonoOriginal.replaceAll(RegExp(r'\D'), '');
    if (cpfLimpo == cpfDonoLimpo) {
      // É o dono acessando por outro dispositivo (ex.: celular do dono)
      return;
    }

    final jaEhMembro = lojaAtual.membros.any(
      (m) => m.cpf.replaceAll(RegExp(r'\D'), '') == cpfLimpo,
    );

    if (!jaEhMembro) {
      debugPrint('[ServidorRedeLocal] Auto-associando membro na loja via Wi-Fi: CPF $cpfLimpo (${terminal.nome})');
      final novoMembro = MembroLoja(
        cpf: terminal.cpf!,
        nome: (terminal.nomeUsuario != null && terminal.nomeUsuario!.trim().isNotEmpty)
            ? terminal.nomeUsuario!.trim()
            : terminal.nome,
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
}
