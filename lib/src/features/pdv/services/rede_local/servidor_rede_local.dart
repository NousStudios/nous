import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nous/src/core/services/relogio_rede_service.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/chat/services/chamada_webrtc_service.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/pdv/views/widgets/rede_local/dialog_autorizacao_terminal.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/helpers/anunciador_udp_servidor.dart';
import 'package:nous/src/features/pdv/services/rede_local/helpers/consolidador_conta_terminal.dart';
import 'package:nous/src/features/pdv/services/rede_local/handlers/servidor_ws_upgrade_handler.dart';
import 'package:nous/src/features/pdv/services/rede_local/manipulador_midia_servidor.dart';
import 'package:nous/src/features/pdv/services/rede_local/handlers/roteador_chat.dart';
import 'package:nous/src/features/pdv/services/rede_local/handlers/roteador_loja_pedidos.dart';
import 'package:nous/src/features/pdv/services/rede_local/handlers/roteador_usuarios.dart';
import 'package:nous/src/features/pdv/models/terminal_conectado_info.dart';
import 'package:nous/src/features/pdv/services/rede_local/handlers/servidor_ws_message_handler.dart';
import 'package:nous/src/features/pdv/services/rede_local/seguranca_servidor_relay.dart';
export 'package:nous/src/features/pdv/models/terminal_conectado_info.dart';

/// Gerencia o Servidor da Loja em rede local Wi-Fi.
/// Permite que celulares e outros computadores operem como terminais móveis simultâneos.
class ServidorRedeLocal {
  static final ServidorRedeLocal _instancia = ServidorRedeLocal._interno();
  factory ServidorRedeLocal() => _instancia;
  ServidorRedeLocal._interno();

  static const int portaUdpAnuncio = AnunciadorUdpServidor.portaUdpAnuncio;
  static const int portaPadraoHttp = 8080;

  HttpServer? _servidorHttp;
  final AnunciadorUdpServidor _anunciadorUdp = AnunciadorUdpServidor();
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

  /// Notifica e atualiza a presença do operador do balcão na rede local
  void atualizarOperadorBalcao([UsuarioNous? conta]) {
    _atualizarListasTerminais();
    if (ativo) {
      notificarPresencas();
    }
  }

  final ValueNotifier<bool> estaAtivo = ValueNotifier<bool>(false);
  final ValueNotifier<int> totalConectados = ValueNotifier<int>(0);
  final ValueNotifier<List<TerminalConectadoInfo>> terminaisConectados =
      ValueNotifier<List<TerminalConectadoInfo>>([]);
  final Map<String, TerminalConectadoInfo> _historicoTerminais = {};
  final ValueNotifier<List<TerminalConectadoInfo>> terminaisHistorico =
      ValueNotifier<List<TerminalConectadoInfo>>([]);

  void _atualizarListasTerminais() {
    totalConectados.value = _clientesWs.length;
    final ativas = obterTodasPresencas();
    terminaisConectados.value = ativas;
    for (final t in ativas) {
      if (t.ip.isNotEmpty && t.id != 'balcao_servidor_local') {
        _historicoTerminais[t.ip] = t;
      }
    }
    terminaisHistorico.value = _historicoTerminais.values.toList();
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
  set lojaAtiva(Loja? l) => _lojaAtiva = l;
  PdvProvider? get pdvProvider => _pdvProvider;
  AuthProvider? get authProvider => _authProvider;
  Map<String, ResultadoAutorizacaoConexao> get decisoesTerminais =>
      _decisoesTerminais;
  Set<String> get terminaisAutorizados => _terminaisAutorizados;

  Future<ResultadoAutorizacaoConexao> solicitarAutorizacaoTerminal({
    required String ip,
    required String nomeDispositivo,
    String? nomeUsuario,
    String? cpf,
    required bool jaEhMembro,
  }) {
    return _solicitarAutorizacaoTerminal(
      ip: ip,
      nomeDispositivo: nomeDispositivo,
      nomeUsuario: nomeUsuario,
      cpf: cpf,
      jaEhMembro: jaEhMembro,
    );
  }

  void consolidarContaTerminal(TerminalConectadoInfo terminal) {
    _consolidarContaTerminal(terminal);
  }

  /// Descobre o melhor IP IPv4 local na rede Wi-Fi/Ethernet da máquina.
  static Future<String?> obterIpLocal() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      // Prioriza redes privadas reais (192.168.x.x, 10.x.x.x, 172.16-31.x.x),
      // descartando adaptadores virtuais de máquinas virtuais, WSL, Docker, Hyper-V
      for (final interface in interfaces) {
        final nome = interface.name.toLowerCase();
        if (nome.contains('virtual') ||
            nome.contains('wsl') ||
            nome.contains('docker') ||
            nome.contains('vethernet') ||
            nome.contains('hyper-v') ||
            nome.contains('vmware') ||
            nome.contains('vbox')) {
          continue;
        }
        for (final addr in interface.addresses) {
          if (!addr.isLoopback &&
              (addr.address.startsWith('192.168.') ||
                  addr.address.startsWith('10.') ||
                  addr.address.startsWith('172.'))) {
            return addr.address;
          }
        }
      }

      // Fallback para qualquer IPv4 não-loopback em interface não virtual
      for (final interface in interfaces) {
        final nome = interface.name.toLowerCase();
        if (nome.contains('virtual') ||
            nome.contains('wsl') ||
            nome.contains('docker') ||
            nome.contains('vethernet') ||
            nome.contains('hyper-v')) {
          continue;
        }
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }

      // Último recurso: qualquer endereço não loopback
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

  /// Retorna todos os endereços de broadcast IPv4 calculados para as interfaces ativas
  static Future<Set<String>> obterEnderecosBroadcastLocais([String? ipConhecido]) {
    return AnunciadorUdpServidor.obterEnderecosBroadcastLocais(ipConhecido);
  }

  /// Inicia o servidor HTTP, WebSocket e o anúncio UDP na rede local.
  Future<bool> iniciar({
    Loja? loja,
    required PdvProvider pdv,
    AuthProvider? auth,
    int portaInicial = portaPadraoHttp,
  }) async {
    if (loja != null && LojasService.ehLojaHostFalsa(loja.id, loja.tags, loja.nome)) {
      loja = null;
    }
    if (ativo) {
      if (_lojaAtiva?.id == loja?.id) {
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
    RelogioRedeService.instancia.definirComoServidorMestre();
    _terminaisAutorizados.clear();
    estaAtivo.value = true;
    _atualizarListasTerminais();
    final rotuloHost = _lojaAtiva != null
        ? 'Loja "${_lojaAtiva!.nome}"'
        : 'Usuário Nous (${_authProvider?.contaAtual?.nomeExibicao.isNotEmpty == true ? _authProvider!.contaAtual!.nomeExibicao : (_authProvider?.contaAtual?.nome.isNotEmpty == true ? _authProvider!.contaAtual!.nome : 'Usuário Nous')})';
    debugPrint(
      '[ServidorRedeLocal] Servidor $rotuloHost iniciado em http://$_ipServidor:$_porta',
    );

    // Escuta requisições HTTP e WebSockets
    _servidorHttp!.listen(_processarRequisicao, onError: (e) {
      debugPrint('[ServidorRedeLocal] Erro no servidor: $e');
    });

    // Inicia anúncio UDP para descoberta automática no Wi-Fi
    _anunciadorUdp.iniciar(
      obterIpServidor: () => _ipServidor,
      obterPorta: () => _porta,
      obterLojaAtiva: () => lojaAtiva,
      obterNomeHost: () {
        final ehFalsa = _lojaAtiva != null &&
            LojasService.ehLojaHostFalsa(_lojaAtiva!.id, _lojaAtiva!.tags, _lojaAtiva!.nome);
        final lojaValida = ehFalsa ? null : _lojaAtiva;
        return lojaValida?.nome ??
            (_authProvider?.contaAtual?.nomeExibicao.isNotEmpty == true
                ? _authProvider!.contaAtual!.nomeExibicao
                : (_authProvider?.contaAtual?.nome.isNotEmpty == true
                    ? _authProvider!.contaAtual!.nome
                    : 'Usuário Nous'));
      },
      servidorAtivo: () => ativo,
    );

    // Drena qualquer mensagem que estava na fila de saída local
    ChatService.drenarFilaDeSaida();

    return true;
  }

  /// Para o servidor e encerra conexões
  Future<void> parar() async {
    _anunciadorUdp.parar();

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
    // Aplica cabeçalhos defensivos do Nous Sovereign Relay
    SegurancaServidorRelay.aplicarHeadersSeguranca(request.response);

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

    // Rate limiting, teto de payload e proteção contra DoS/floods
    if (!SegurancaServidorRelay.verificarRequisicaoHttpPermitida(request)) {
      return;
    }

    final path = request.uri.path;

    // Sincronização de relógio e tempo soberano da rede local (Uníssono)
    if (path == '/api/relogio' && request.method == 'GET') {
      final agora = DateTime.now();
      _responderJson(request, {
        'sucesso': true,
        'tempoServidor': agora.toIso8601String(),
        'timestampMs': agora.millisecondsSinceEpoch,
      });
      return;
    }

    // 1. WebSocket para comunicação bidirecional em tempo real
    if (path == '/api/ws') {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        await ServidorWsUpgradeHandler.processarUpgrade(
          request: request,
          ipServidor: _ipServidor,
          clientesWs: _clientesWs,
          terminaisWs: _terminaisWs,
          obterLojaAtiva: () => lojaAtiva,
          pdvProvider: _pdvProvider,
          obterTodasPresencas: obterTodasPresencas,
          atualizarListasTerminais: _atualizarListasTerminais,
          notificarPresencas: notificarPresencas,
          onMensagem: _tratarMensagemWs,
        );
        return;
      }
    }

    // 2. Mídias, uploads binários, áudio e APKs
    if (await ManipuladorMidiaServidor.atenderRequisicaoMidia(
      request,
      pdvProvider: _pdvProvider,
    )) {
      return;
    }

    // 3. Status do servidor
    if (path == '/api/status' && request.method == 'GET') {
      final ehFalsa = _lojaAtiva != null &&
          LojasService.ehLojaHostFalsa(_lojaAtiva!.id, _lojaAtiva!.tags, _lojaAtiva!.nome);
      final lojaValida = ehFalsa ? null : _lojaAtiva;
      final nomeHost = lojaValida?.nome ??
          (_authProvider?.contaAtual?.nomeExibicao.isNotEmpty == true
              ? _authProvider!.contaAtual!.nomeExibicao
              : (_authProvider?.contaAtual?.nome.isNotEmpty == true
                  ? _authProvider!.contaAtual!.nome
                  : 'Usuário Nous'));
      _responderJson(request, {
        'sucesso': true,
        'tipoHost': lojaValida != null ? 'loja' : 'usuario',
        'lojaId': lojaValida?.id,
        'lojaNome': nomeHost,
        'servidor': 'Nous Local Server',
        'versao': '1.0.0',
        'conectados': _clientesWs.length,
      });
      return;
    }

    // 4. Roteamento de Loja, Pedidos, Estoque e Mesas
    if (await RoteadorLojaPedidos.atender(request, servidor: this)) {
      return;
    }

    // 5. Roteamento de Usuários, Identidades e Perfis
    if (await RoteadorUsuarios.atender(request, servidor: this)) {
      return;
    }

    // 6. Roteamento de Mensageria e Chat
    if (await RoteadorChat.atender(request, servidor: this)) {
      return;
    }

    // Rota não encontrada
    _responderJson(
      request,
      {'sucesso': false, 'mensagem': 'Rota não encontrada: $path'},
      statusCode: HttpStatus.notFound,
    );
  }

  Future<void> _tratarMensagemWs(WebSocket ws, dynamic msg) async {
    final terminal = _terminaisWs[ws];
    final ipRemoto = terminal?.ip ?? '127.0.0.1';

    // Rate Limiting e limite de tamanho da mensagem WS
    if (!SegurancaServidorRelay.verificarMensagemWsPermitida(ws, ipRemoto, msg)) {
      return;
    }

    final ctx = ServidorWsContext(
      terminaisWs: _terminaisWs,
      clientesWs: _clientesWs,
      pdvProvider: _pdvProvider,
      authProvider: _authProvider,
      obterLojaAtiva: () => _lojaAtiva,
      atualizarListasTerminais: _atualizarListasTerminais,
      notificarPresencas: notificarPresencas,
      consolidarContaTerminal: _consolidarContaTerminal,
      processarSinalChamadaLocal: _processarSinalChamadaLocal,
    );
    await ServidorWsMessageHandler.processarMensagem(ws, msg, ctx);
  }

  void _processarSinalChamadaLocal(Map<String, dynamic> dados) {
    try {
      final tipo = dados['tipo'] as String?;
      final meuCpf = (_authProvider?.cpf ?? _pdvProvider?.cpfAtual ?? '').replaceAll(RegExp(r'\D'), '');

      if (tipo == 'chamada_iniciar') {
        final chamadaJson = dados['chamada'] as Map<String, dynamic>?;
        final sdp = dados['sdp'] as Map<String, dynamic>?;
        if (chamadaJson != null && sdp != null) {
          final destId = (chamadaJson['destinatarioId'] as String? ?? '').replaceAll(RegExp(r'\D'), '');
          final participantes = (chamadaJson['participantesIds'] as List<dynamic>?)
                  ?.map((e) => e.toString().replaceAll(RegExp(r'\D'), ''))
                  .toList() ??
              [];
          final idLojaAtiva = _lojaAtiva != null
              ? PdvProvider.normalizarIdLoja(_lojaAtiva!.id)
              : '';
          final destEhLojaLocal = destId.isNotEmpty &&
              ((idLojaAtiva.isNotEmpty && idLojaAtiva == destId) ||
                  (_pdvProvider?.lojas.any(
                        (l) =>
                            PdvProvider.normalizarIdLoja(l.id) == destId &&
                            (ChatService.normalizarCpf(l.cpfDonoOriginal) ==
                                    meuCpf ||
                                l.membros.any(
                                  (m) =>
                                      ChatService.normalizarCpf(m.cpf) ==
                                      meuCpf,
                                )),
                      ) ??
                      false));

          if (destId == meuCpf ||
              destEhLojaLocal ||
              participantes.contains(meuCpf) ||
              destId.isEmpty) {
            ChamadaWebRtcService.instancia.receberConvite(chamadaJson, sdp);
          }
        }
      } else if (tipo == 'chamada_aceita') {
        final sdp = dados['sdp'] as Map<String, dynamic>?;
        if (sdp != null) {
          ChamadaWebRtcService.instancia.receberRespostaAceita(sdp);
        }
      } else if (tipo == 'chamada_candidato_ice') {
        final candidate = dados['candidate'] as Map<String, dynamic>?;
        if (candidate != null) {
          ChamadaWebRtcService.instancia.receberCandidatoIce(candidate);
        }
      } else if (tipo == 'chamada_rejeitada' || tipo == 'chamada_encerrada') {
        ChamadaWebRtcService.instancia.encerrarChamada(notificarRede: false);
      }
    } catch (e) {
      debugPrint('[ServidorRedeLocal] Erro ao processar sinal de chamada: $e');
    }
  }

  /// Retorna todos os dispositivos ativos conectados à loja, incluindo o balcão se ativo.
  List<TerminalConectadoInfo> obterTodasPresencas() {
    final lista = <TerminalConectadoInfo>[];
    if (ativo) {
      final hostNome = Platform.localHostname;
      final usuarioLogado = _authProvider?.contaAtual;
      final cpfPdv = _pdvProvider?.cpfAtual ?? '';
      final cpfBalcao = (usuarioLogado != null && usuarioLogado.cpf.trim().isNotEmpty)
          ? usuarioLogado.cpf.trim()
          : (cpfPdv.trim().isNotEmpty
              ? cpfPdv.trim()
              : (_lojaAtiva?.cpfDonoOriginal ?? ''));
      final nomeBalcao = (usuarioLogado != null && usuarioLogado.nome.trim().isNotEmpty)
          ? usuarioLogado.nome.trim()
          : (_lojaAtiva != null ? 'Operador Balcão' : 'Usuário Host');

      lista.add(
        TerminalConectadoInfo(
          id: 'balcao_servidor_local',
          nome: hostNome.isNotEmpty
              ? (_lojaAtiva != null ? 'Computador Balcão ($hostNome)' : 'Host Usuário ($hostNome)')
              : (_lojaAtiva != null ? 'Computador Balcão (Local)' : 'Host Usuário (Local)'),
          ip: _ipServidor ?? '127.0.0.1',
          conectadoEm: _dataHoraInicio ?? DateTime.now(),
          cpf: cpfBalcao,
          nomeUsuario: nomeBalcao,
          apelido: usuarioLogado?.apelido,
          tipoConexao: 'membro',
        ),
      );
    }
    // Filtra e desduplica terminais remotos (ignora loopbacks e IPs locais da própria máquina)
    final mapaTerminaisRemotos = <String, TerminalConectadoInfo>{};
    for (final term in _terminaisWs.values) {
      final ip = term.ip.trim();
      final ehLoopback = ip == '127.0.0.1' ||
          ip == '::1' ||
          (_ipServidor != null && ip == _ipServidor);
      if (ehLoopback) continue;

      final cpfLimpo =
          term.cpf != null ? ChatService.normalizarCpf(term.cpf!) : '';
      final chave = cpfLimpo.isNotEmpty ? cpfLimpo : ip;
      mapaTerminaisRemotos[chave] = term;
    }

    lista.addAll(mapaTerminaisRemotos.values);
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



  /// Consolida e unifica a ficha de Identidade do Usuário no banco de contas local do balcão
  void _consolidarContaTerminal(TerminalConectadoInfo terminal) {
    ConsolidadorContaTerminal.consolidar(
      terminal: terminal,
      historicoTerminais: _historicoTerminais,
      terminaisHistorico: terminaisHistorico,
    );
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
    }
    notificarTodos({
      'tipo': 'loja_atualizada',
      'loja': loja.toJson(),
    });
    debugPrint(
      '[ServidorRedeLocal] Transmitida atualização da loja "${loja.nome}" para ${_clientesWs.length} terminais',
    );
  }



  void _responderJson(
    HttpRequest request,
    Map<String, dynamic> json, {
    int statusCode = HttpStatus.ok,
  }) => responderJson(request, json, statusCode: statusCode);

  static void responderJson(
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
  }) {
    return DialogAutorizacaoTerminal.exibir(
      ip: ip,
      nomeDispositivo: nomeDispositivo,
      nomeUsuario: nomeUsuario,
      cpf: cpf,
      jaEhMembro: jaEhMembro,
    );
  }
}

