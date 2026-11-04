import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nous/src/core/services/relogio_rede_service.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/chat/services/chamada_webrtc_service.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/pdv/views/widgets/rede_local/dialog_autorizacao_terminal.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/dados_locais_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/manipulador_midia_servidor.dart';
import 'package:nous/src/features/pdv/services/rede_local/handlers/roteador_chat.dart';
import 'package:nous/src/features/pdv/services/rede_local/handlers/roteador_loja_pedidos.dart';
import 'package:nous/src/features/pdv/services/rede_local/handlers/roteador_usuarios.dart';
import 'package:nous/src/features/pdv/models/terminal_conectado_info.dart';
import 'package:nous/src/features/pdv/services/rede_local/handlers/servidor_ws_message_handler.dart';
export 'package:nous/src/features/pdv/models/terminal_conectado_info.dart';

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
        try {
          final ipRemoto = request.connectionInfo?.remoteAddress.address ?? '127.0.0.1';
          final ehLoopback = request.connectionInfo?.remoteAddress.isLoopback ?? false;
          final ehIpLocal = ipRemoto == '127.0.0.1' ||
              ipRemoto == '::1' ||
              (_ipServidor != null && ipRemoto == _ipServidor);

          if (ehLoopback || ehIpLocal) {
            debugPrint(
              '[ServidorRedeLocal] Rejeitando conexão WebSocket loopback da própria máquina ($ipRemoto).',
            );
            request.response.statusCode = HttpStatus.badRequest;
            await request.response.close();
            return;
          }

          final ws = await WebSocketTransformer.upgrade(request);
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
          final lojaParaEnvio = lojaAtiva;
          if (lojaParaEnvio != null) {
            final fotosUsuariosAusentes = <String>[];
            for (final m in lojaParaEnvio.membros) {
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
                'loja': lojaParaEnvio.toJson(),
                if (lojaNous != null) 'lojaNousColetiva': lojaNous.toJson(),
                'presencas':
                    obterTodasPresencas().map((p) => p.toJson()).toList(),
                'fotosUsuariosAusentes': fotosUsuariosAusentes,
              }),
            );
          } else {
            final lojaNous =
                _pdvProvider?.buscarPorId(PdvProvider.idLojaColetivaNous);
            ws.add(
              jsonEncode({
                'tipo': 'dados_iniciais',
                'loja': null,
                if (lojaNous != null) 'lojaNousColetiva': lojaNous.toJson(),
                'presencas':
                    obterTodasPresencas().map((p) => p.toJson()).toList(),
                'fotosUsuariosAusentes': <String>[],
              }),
            );
          }

          ws.listen(
            (msg) => _tratarMensagemWs(ws, msg),
            onDone: () {
              debugPrint('[ServidorRedeLocal] Conexão WebSocket onDone para terminal: ${terminal.ip} (${terminal.nome})');
              _clientesWs.remove(ws);
              _terminaisWs.remove(ws);
              _atualizarListasTerminais();
              notificarPresencas();
            },
            onError: (err) {
              debugPrint('[ServidorRedeLocal] Conexão WebSocket onError para terminal: ${terminal.ip} ($err)');
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
          final ehGrupo = chamadaJson['ehGrupo'] as bool? ?? false;
          final participantes = (chamadaJson['participantesIds'] as List<dynamic>?)
                  ?.map((e) => e.toString().replaceAll(RegExp(r'\D'), ''))
                  .toList() ??
              [];

          if (destId == meuCpf || (ehGrupo && participantes.contains(meuCpf)) || destId.isEmpty) {
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
        if (!ativo || _socketUdp == null) return;
        try {
          final ehFalsa = _lojaAtiva != null &&
              LojasService.ehLojaHostFalsa(_lojaAtiva!.id, _lojaAtiva!.tags, _lojaAtiva!.nome);
          final lojaValida = ehFalsa ? null : _lojaAtiva;
          final nomeHost = lojaValida?.nome ??
              (_authProvider?.contaAtual?.nomeExibicao.isNotEmpty == true
                  ? _authProvider!.contaAtual!.nomeExibicao
                  : (_authProvider?.contaAtual?.nome.isNotEmpty == true
                      ? _authProvider!.contaAtual!.nome
                      : 'Usuário Nous'));
          final pacote = jsonEncode({
            'assinatura': 'nous_loja_anuncio',
            'lojaId': lojaValida?.id ?? '',
            'lojaNome': nomeHost,
            'tipoHost': lojaValida != null ? 'loja' : 'usuario',
            'ip': _ipServidor,
            'porta': _porta,
          });
          final bytes = utf8.encode(pacote);
          final destinos = <String>{'255.255.255.255'};
          if (_ipServidor != null && _ipServidor!.contains('.')) {
            final partes = _ipServidor!.split('.');
            if (partes.length == 4) {
              destinos.add('${partes[0]}.${partes[1]}.${partes[2]}.255');
            }
          }
          for (final dest in destinos) {
            try {
              _socketUdp!.send(
                bytes,
                InternetAddress(dest),
                portaUdpAnuncio,
              );
            } catch (_) {}
          }
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

