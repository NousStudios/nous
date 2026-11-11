import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nous/src/core/services/relogio_rede_service.dart';
import 'package:nous/src/core/utils/json_isolate_utils.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chamada_webrtc_service.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/referencia_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/reconciliador_loja_rede.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/sincronizador_usuarios_rede.dart';
import 'package:nous/src/features/pdv/services/rede_local/transferencia_arquivos_rede.dart';
import 'package:nous/src/features/pdv/services/rede_local/despachante_cliente_rede.dart';
import 'package:nous/src/features/pdv/services/rede_local/handlers/cliente_ws_message_handler.dart';

/// Informações de um servidor de loja anunciado na rede Wi-Fi local.
class DispositivoLojaInfo {
  final String lojaId;
  final String lojaNome;
  final String ip;
  final int porta;
  final DateTime vistoEm;
  final String tipoHost;

  const DispositivoLojaInfo({
    required this.lojaId,
    required this.lojaNome,
    required this.ip,
    required this.porta,
    required this.vistoEm,
    this.tipoHost = 'loja',
  });

  bool get ehUsuario => tipoHost == 'usuario' || lojaId.isEmpty;
  String get enderecoCompleto => '$ip:$porta';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DispositivoLojaInfo &&
          runtimeType == other.runtimeType &&
          lojaId == other.lojaId &&
          ip == other.ip &&
          porta == other.porta;

  @override
  int get hashCode => lojaId.hashCode ^ ip.hashCode ^ porta.hashCode;
}

/// Gerencia o Cliente que conecta o celular ao servidor do balcão na rede Wi-Fi.
class ClienteRedeLocal {
  static final ClienteRedeLocal _instancia = ClienteRedeLocal._interno();
  factory ClienteRedeLocal() => _instancia;
  ClienteRedeLocal._interno();

  RawDatagramSocket? _socketDescoberta;
  WebSocket? _ws;
  Timer? _timerPing;
  Timer? _timerReconexao;

  String? _ipServidor;
  int? _portaServidor;
  PdvProvider? _pdvProvider;
  AuthProvider? _authProvider;
  Loja? _lojaSincronizada;

  String _nomeDispositivo = 'Celular';
  bool _nomeCarregado = false;

  final ValueNotifier<bool> estaConectado = ValueNotifier<bool>(false);
  final ValueNotifier<String?> ultimoErro = ValueNotifier<String?>(null);
  final ValueNotifier<List<DispositivoLojaInfo>> lojasEncontradas =
      ValueNotifier<List<DispositivoLojaInfo>>([]);
  final ValueNotifier<List<TerminalConectadoInfo>> presencasAtivas =
      ValueNotifier<List<TerminalConectadoInfo>>([]);

  bool _aplicandoAtualizacaoRemota = false;
  bool get aplicandoAtualizacaoRemota => _aplicandoAtualizacaoRemota;
  final TransferenciaArquivosRede _transferencia = TransferenciaArquivosRede();
  late final ReconciliadorLojaRede _reconciliador =
      ReconciliadorLojaRede(transferencia: _transferencia);
  late final SincronizadorUsuariosRede _sincronizador = SincronizadorUsuariosRede(
    transferencia: _transferencia,
    reconciliador: _reconciliador,
  );
  final DespachanteClienteRede _despachante = const DespachanteClienteRede();

  Timer? _timerDebounceEnvioLoja;
  AppLifecycleListener? _lifecycleListener;

  /// Registra escuta do ciclo de vida do Flutter para reconexão imediata quando o app volta à tela no Android/iOS
  void inicializarMonitoramentoCicloVida() {
    _lifecycleListener?.dispose();
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        debugPrint('[ClienteRedeLocal] App retornou a primeiro plano (onResume). Verificando conexão com Balcão...');
        verificarEAutoReconectarNaRetomada();
      },
    );
  }

  /// Verifica a integridade da conexão ao destravar o celular ou retomar o app.
  Future<void> verificarEAutoReconectarNaRetomada() async {
    if (ServidorRedeLocal().ativo) return;
    if (_usuarioDesconectouManualmente) return;
    final pdv = _pdvProvider;
    if (pdv == null) return;

    if (!conectado && !_conectando) {
      debugPrint('[ClienteRedeLocal] Retomada detectou terminal offline. Reconectando ao Balcão...');
      await tentarAutoConectarSeDisponivel(pdv, _authProvider);
      return;
    }

    if (conectado && _ws != null) {
      try {
        _ws!.add(jsonEncode({'tipo': 'ping'}));
      } catch (e) {
        debugPrint('[ClienteRedeLocal] Socket morto na retomada ($e). Reiniciando conexão...');
        await desconectar();
        await tentarAutoConectarSeDisponivel(pdv, _authProvider);
      }
    }
  }

  bool _conectando = false;
  bool get conectando => _conectando;
  bool _usuarioDesconectouManualmente = false;

  bool get conectado => _ws != null && estaConectado.value;
  String? get ipServidor => _ipServidor;
  int? get portaServidor => _portaServidor;
  String? get enderecoServidor =>
      _ipServidor != null && _portaServidor != null ? '$_ipServidor:$_portaServidor' : null;
  Loja? get lojaSincronizada => _lojaSincronizada;
  String get nomeDispositivo => _nomeDispositivo;

  void vincularAuthProvider(AuthProvider auth) {
    _authProvider = auth;
  }

  /// Atualiza ativamente a identificação do terminal móvel no balcão quando o usuário faz login ou troca de conta
  Future<void> atualizarIdentidadeUsuario({
    String? cpf,
    String? nome,
    String? apelido,
    String? foto,
  }) async {
    final cpfFinal = cpf ??
        _pdvProvider?.cpfAtual ??
        _authProvider?.contaAtual?.cpf ??
        _authProvider?.cpf ??
        '';
    String? nomeFinal = nome ?? _authProvider?.contaAtual?.nome;
    String? apelidoFinal = apelido ?? _authProvider?.contaAtual?.apelido;
    String? fotoFinal = foto ?? _authProvider?.contaAtual?.foto;

    if (cpfFinal.isNotEmpty && (nomeFinal == null || nomeFinal.isEmpty)) {
      final conta = await ContasNousService.buscarPorCpf(cpfFinal);
      nomeFinal = conta?.nome;
      apelidoFinal = conta?.apelido;
      fotoFinal = conta?.foto;
    }

    if (_ws != null && estaConectado.value) {
      try {
        _ws!.add(
          jsonEncode({
            'tipo': 'identificacao',
            'nomeDispositivo': _nomeDispositivo,
            'cpf': cpfFinal,
            'nomeUsuario': nomeFinal,
            'apelido': apelidoFinal,
            if (fotoFinal != null && fotoFinal.isNotEmpty) 'foto': fotoFinal,
          }),
        );
        debugPrint(
          '[ClienteRedeLocal] Identidade do usuário atualizada com sucesso no balcão via WebSocket: CPF $cpfFinal ($nomeFinal)',
        );
      } catch (e) {
        debugPrint('[ClienteRedeLocal] Erro ao enviar identificação atualizada ao balcão: $e');
      }
    }
  }

  /// Notifica o servidor do balcão que o usuário deslogou deste terminal
  void notificarLogout() {
    if (_ws != null && estaConectado.value) {
      try {
        _ws!.add(
          jsonEncode({
            'tipo': 'logout',
            'nomeDispositivo': _nomeDispositivo,
          }),
        );
        debugPrint('[ClienteRedeLocal] Notificação de logout enviada ao balcão.');
      } catch (_) {}
    }
  }

  Future<String> obterNomeDispositivo() async {
    if (_nomeCarregado) return _nomeDispositivo;
    try {
      final prefs = await SharedPreferences.getInstance();
      final salvo = prefs.getString('terminal_nome_dispositivo');
      if (salvo != null && salvo.trim().isNotEmpty) {
        _nomeDispositivo = salvo.trim();
      } else {
        _nomeDispositivo = Platform.isAndroid ? 'Celular' : 'Terminal Móvel';
      }
      _nomeCarregado = true;
    } catch (_) {}
    return _nomeDispositivo;
  }

  Future<void> salvarNomeDispositivo(String novoNome) async {
    final nomeLimpo = novoNome.trim();
    if (nomeLimpo.isEmpty) return;
    _nomeDispositivo = nomeLimpo;
    _nomeCarregado = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('terminal_nome_dispositivo', _nomeDispositivo);
    } catch (_) {}

    if (_ws != null && estaConectado.value) {
      try {
        final cpfLogado = _pdvProvider?.cpfAtual;
        String? nomeUsuario;
        if (cpfLogado != null && cpfLogado.isNotEmpty) {
          final conta = await ContasNousService.buscarPorCpf(cpfLogado);
          nomeUsuario = conta?.nome;
        }
        _ws!.add(jsonEncode({
          'tipo': 'identificacao',
          'nomeDispositivo': _nomeDispositivo,
          'cpf': cpfLogado,
          'nomeUsuario': nomeUsuario,
        }));
      } catch (_) {}
    }
  }

  bool _varreduraAtiva = false;
  int _idVarredura = 0;

  /// Inicia escuta UDP para encontrar servidores de lojas transmitindo no Wi-Fi
  /// acompanhada de radar ativo HTTP pela sub-rede local.
  Future<void> iniciarDescoberta({PdvProvider? pdv, AuthProvider? auth}) async {
    if (pdv != null) _pdvProvider = pdv;
    if (auth != null) _authProvider = auth;
    pararDescoberta();
    lojasEncontradas.value = [];

    // 1. Escuta passiva UDP porta 45454
    try {
      _socketDescoberta = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        ServidorRedeLocal.portaUdpAnuncio,
        reuseAddress: true,
      );

      _socketDescoberta!.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socketDescoberta?.receive();
          if (datagram != null) {
            _processarDatagramaDescoberta(datagram);
          }
        }
      });
    } catch (e) {
      debugPrint('[ClienteRedeLocal] Erro ao iniciar escuta UDP: $e');
    }

    // 2. Radar ativo HTTP pela sub-rede (imune a filtros UDP e sono do Wi-Fi)
    unawaited(_iniciarVarreduraAtivaHttp());
  }

  void pararDescoberta() {
    _varreduraAtiva = false;
    _idVarredura++;
    try {
      _socketDescoberta?.close();
    } catch (_) {}
    _socketDescoberta = null;
  }

  void _processarDatagramaDescoberta(Datagram datagram) {
    if (ServidorRedeLocal().ativo) return;
    try {
      final texto = utf8.decode(datagram.data);
      final json = jsonDecode(texto) as Map<String, dynamic>;

      if (json['assinatura'] == 'nous_loja_anuncio') {
        final lojaIdStr = (json['lojaId'] as String?) ?? '';
        final tipoHost = json['tipoHost'] as String? ?? (lojaIdStr.isNotEmpty ? 'loja' : 'usuario');
        final info = DispositivoLojaInfo(
          lojaId: lojaIdStr,
          lojaNome: (json['lojaNome'] as String?) ?? 'Usuário Nous',
          ip: json['ip'] as String,
          porta: json['porta'] as int,
          vistoEm: DateTime.now(),
          tipoHost: tipoHost,
        );
        _adicionarOuAtualizarServidorDescoberto(info);
      }
    } catch (_) {}
  }

  void _adicionarOuAtualizarServidorDescoberto(DispositivoLojaInfo info) {
    if (ServidorRedeLocal().ativo) return;
    final lista = List<DispositivoLojaInfo>.from(lojasEncontradas.value);
    final idx = lista.indexWhere(
      (d) => d.lojaId == info.lojaId && d.ip == info.ip && d.porta == info.porta,
    );

    if (idx != -1) {
      lista[idx] = info;
    } else {
      lista.add(info);
    }

    // Remove servidores que não respondem há mais de 15 segundos
    final agora = DateTime.now();
    lista.removeWhere((d) => agora.difference(d.vistoEm).inSeconds > 15);

    lojasEncontradas.value = lista;

    // Auto-conecta se ainda desconectado e não estiver em tentativa de conexão
    if (!conectado && !_conectando && _pdvProvider != null) {
      conectar(ip: info.ip, porta: info.porta, pdv: _pdvProvider!, auth: _authProvider);
    }
  }

  Future<void> _iniciarVarreduraAtivaHttp() async {
    if (ServidorRedeLocal().ativo) return;
    final idAtual = ++_idVarredura;
    _varreduraAtiva = true;

    // 1. Testa primeiro o último IP salvo imediatamente (se existir)
    try {
      final prefs = await SharedPreferences.getInstance();
      final ultimoIp = prefs.getString('nous_ultimo_ip_balcao');
      final ultimaPorta =
          prefs.getInt('nous_ultima_porta_balcao') ?? ServidorRedeLocal.portaPadraoHttp;
      if (ultimoIp != null && ultimoIp.isNotEmpty) {
        final achou = await _testarIpServidorHttp(ultimoIp, ultimaPorta);
        if (achou || !_varreduraAtiva || idAtual != _idVarredura || conectado) return;
      }
    } catch (_) {}

    // 2. Descobre os prefixos de sub-rede das interfaces do aparelho
    final prefixos = <String>{};
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final iface in interfaces) {
        final nome = iface.name.toLowerCase();
        if (nome.contains('virtual') || nome.contains('wsl') || nome.contains('docker')) {
          continue;
        }
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && addr.address.contains('.')) {
            final partes = addr.address.split('.');
            if (partes.length == 4) {
              prefixos.add('${partes[0]}.${partes[1]}.${partes[2]}.');
            }
          }
        }
      }
    } catch (_) {}

    if (prefixos.isEmpty) {
      prefixos.addAll(['192.168.0.', '192.168.1.']);
    }

    // 3. Hosts organizados com prioridade para faixas habituais de roteadores e servidores
    final hostsPrioritarios = <int>[
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 20, 25, 30, 50,
      100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 115, 120, 130, 140, 150,
    ];
    final todosHosts = <int>[
      ...hostsPrioritarios,
      for (int i = 1; i <= 254; i++)
        if (!hostsPrioritarios.contains(i)) i,
    ];

    for (final prefixo in prefixos) {
      if (!_varreduraAtiva || idAtual != _idVarredura || conectado) break;

      // Executa em lotes paralelos de 25 IPs para varredura rápida e sem sobrecarga
      const tamanhoLote = 25;
      for (int i = 0; i < todosHosts.length; i += tamanhoLote) {
        if (!_varreduraAtiva || idAtual != _idVarredura || conectado) break;
        final fim = (i + tamanhoLote < todosHosts.length) ? i + tamanhoLote : todosHosts.length;
        final lote = todosHosts.sublist(i, fim);

        final futuros = lote.map((host) {
          final ip = '$prefixo$host';
          return _testarIpServidorHttp(ip, ServidorRedeLocal.portaPadraoHttp);
        });

        final resultados = await Future.wait(futuros);
        if (resultados.any((r) => r == true)) {
          // Servidor balcão encontrado e processado com sucesso!
          break;
        }
      }
    }
  }

  Future<bool> _testarIpServidorHttp(String ip, int porta) async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 500);
      final uri = Uri.parse('http://$ip:$porta/api/status');
      final req = await client.getUrl(uri).timeout(const Duration(milliseconds: 500));
      final resp = await req.close().timeout(const Duration(milliseconds: 500));
      if (resp.statusCode == HttpStatus.ok) {
        final body = await utf8.decodeStream(resp);
        final json = jsonDecode(body) as Map<String, dynamic>;
        if (json['sucesso'] == true && json['servidor'] == 'Nous Local Server') {
          final lojaIdStr = (json['lojaId'] as String?) ?? '';
          final tipoHost = json['tipoHost'] as String? ?? (lojaIdStr.isNotEmpty ? 'loja' : 'usuario');
          final info = DispositivoLojaInfo(
            lojaId: lojaIdStr,
            lojaNome: (json['lojaNome'] as String?) ?? 'Usuário Nous',
            ip: ip,
            porta: porta,
            vistoEm: DateTime.now(),
            tipoHost: tipoHost,
          );
          _adicionarOuAtualizarServidorDescoberto(info);
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  /// Inicia escuta contínua e tenta reconectar automaticamente ao servidor balcão
  Future<void> tentarAutoConectarSeDisponivel(PdvProvider pdv, [AuthProvider? auth]) async {
    if (ServidorRedeLocal().ativo) return;
    _pdvProvider = pdv;
    if (auth != null) _authProvider = auth;
    if (conectado || _conectando) return;

    await iniciarDescoberta();

    // 1. Tenta o último IP conhecido salvo
    try {
      final prefs = await SharedPreferences.getInstance();
      final ultimoIp = prefs.getString('nous_ultimo_ip_balcao');
      final ultimaPorta = prefs.getInt('nous_ultima_porta_balcao') ?? ServidorRedeLocal.portaPadraoHttp;
      if (ultimoIp != null && ultimoIp.isNotEmpty) {
        final ok = await conectar(ip: ultimoIp, porta: ultimaPorta, pdv: pdv, auth: auth);
        if (ok) return;
      }
    } catch (_) {}

    // 2. Se já encontrou servidores via UDP, conecta no primeiro disponível
    if (!conectado && !_conectando && lojasEncontradas.value.isNotEmpty) {
      final primeiro = lojasEncontradas.value.first;
      await conectar(ip: primeiro.ip, porta: primeiro.porta, pdv: pdv, auth: auth);
    }
  }

  /// Conecta ao servidor no IP e porta especificados (manual ou descoberto).
  Future<bool> conectar({
    required String ip,
    required int porta,
    required PdvProvider pdv,
    AuthProvider? auth,
    bool forcar = false,
  }) async {
    if (ServidorRedeLocal().ativo) {
      debugPrint('[ClienteRedeLocal] Esta máquina já é o Servidor Balcão ativo. Conexão cliente ignorada.');
      return false;
    }
    final ipAlvo = ip.trim();
    if (conectado && _ipServidor == ipAlvo && _portaServidor == porta && !forcar) {
      debugPrint('[ClienteRedeLocal] Conexão já ativa em $ipAlvo:$porta.');
      return true;
    }
    if (_conectando && !forcar) {
      debugPrint('[ClienteRedeLocal] Conexão já em andamento para $ipAlvo:$porta. Ignorando chamada concorrente.');
      return false;
    }

    _conectando = true;
    _usuarioDesconectouManualmente = false;
    _timerReconexao?.cancel();
    _timerReconexao = null;
    await desconectar(manual: false);

    _ipServidor = ipAlvo;
    _portaServidor = porta;
    _pdvProvider = pdv;
    if (auth != null) _authProvider = auth;

    try {
      ultimoErro.value = null;
      await obterNomeDispositivo();

      String cpfLogado =
          _pdvProvider?.cpfAtual ?? _authProvider?.contaAtual?.cpf ?? _authProvider?.cpf ?? '';
      if (cpfLogado.isEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          cpfLogado = prefs.getString('ultimo_cpf_login') ?? '';
        } catch (_) {}
      }
      cpfLogado = ChatService.normalizarCpf(cpfLogado);

      String? nomeUsuario;
      String? apelidoUsuario;
      if (cpfLogado.isNotEmpty) {
        final conta = await ContasNousService.buscarPorCpf(cpfLogado);
        nomeUsuario = conta?.nome ?? _authProvider?.contaAtual?.nome;
        apelidoUsuario = conta?.apelido ?? _authProvider?.contaAtual?.apelido;
      }

      // 1. Baixa o snapshot atualizado da Loja via REST, passando os dados de identidade para auto-associação
      // Timeout de conexão ágil na LAN (3s) para falhar rápido se o IP for inválido
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
      final uriLoja = Uri(
        scheme: 'http',
        host: _ipServidor,
        port: _portaServidor,
        path: '/api/loja',
        queryParameters: {
          if (cpfLogado.isNotEmpty) 'cpf': cpfLogado,
          if (nomeUsuario != null && nomeUsuario.isNotEmpty) 'nome': nomeUsuario,
          if (apelidoUsuario != null && apelidoUsuario.isNotEmpty) 'apelido': apelidoUsuario,
          'dispositivo': _nomeDispositivo,
        },
      );
      final request = await client.getUrl(uriLoja).timeout(const Duration(seconds: 4));
      final response = await request.close().timeout(const Duration(seconds: 4));

      if (response.statusCode == HttpStatus.forbidden) {
        debugPrint('[ClienteRedeLocal] Conexão recusada pelo Administrador do Balcão.');
        ultimoErro.value = 'Conexão recusada pelo Administrador do Balcão.';
        return false;
      }

      if (response.statusCode != HttpStatus.ok) {
        debugPrint('[ClienteRedeLocal] Falha ao obter dados da loja HTTP ${response.statusCode}');
        ultimoErro.value = 'Falha ao obter dados da loja (HTTP ${response.statusCode}).';
        return false;
      }

      final body = await utf8.decodeStream(response);
      final dados = await decodificarJsonMapaSeguro(body);

      Loja? lojaBrutaParaReconciliar;
      List<String> imagensAusentesParaReconciliar = [];
      List<String> fotosUsuariosAusentesParaReconciliar = [];

      if (dados['sucesso'] == true) {
        if (dados['loja'] != null) {
          final lojaBruta = Loja.fromJson(dados['loja'] as Map<String, dynamic>);
          if (!LojasService.ehLojaHostFalsa(lojaBruta.id, lojaBruta.tags, lojaBruta.nome)) {
            lojaBrutaParaReconciliar = lojaBruta;
            imagensAusentesParaReconciliar = (dados['imagensAusentes'] as List<dynamic>? ?? [])
                .map((e) => e.toString())
                .toList();

            // Consolidação leve imediata para disponibilidade instantânea da loja e pedidos
            final lojaLocalExistente = _pdvProvider!.buscarPorId(lojaBruta.id) ??
                await LojasService.carregarLojaPorId(lojaBruta.id);

            final lojaConsolidada = LojasService.consolidarLojaComImagensLocais(
              lojaBruta,
              lojaLocalExistente,
              manterItensAusentes: true,
            );

            _lojaSincronizada = lojaConsolidada;
            await _pdvProvider!.adicionarOuAtualizarLoja(lojaConsolidada);
            await _vincularLojaSeNecessario(lojaConsolidada);

            final notificacoesDispensadas = (dados['notificacoesDispensadasLoja'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList();
            if (notificacoesDispensadas != null && notificacoesDispensadas.isNotEmpty) {
              NotificacoesProvider.instanciaAtiva?.dispensarNotificacoesLoja(
                lojaConsolidada.id,
                notificacoesDispensadas,
                originadoDaRede: true,
              );
            }

            if (dados['fotosUsuariosAusentes'] != null) {
              fotosUsuariosAusentesParaReconciliar = (dados['fotosUsuariosAusentes'] as List<dynamic>)
                  .map((e) => e.toString())
                  .toList();
            }
          } else {
            _lojaSincronizada = null;
          }
        } else {
          _lojaSincronizada = null;
        }

        if (dados['lojaNousColetiva'] != null && _pdvProvider != null) {
          try {
            final lojaNousBruta =
                Loja.fromJson(dados['lojaNousColetiva'] as Map<String, dynamic>);
            final lojaNousAtual =
                _pdvProvider!.buscarPorId(PdvProvider.idLojaColetivaNous);
            if (lojaNousAtual != null) {
              final membrosCombinados = <String, MembroLoja>{};
              for (final m in lojaNousAtual.membros) {
                membrosCombinados[m.cpf.replaceAll(RegExp(r'\D'), '')] = m;
              }
              for (final m in lojaNousBruta.membros) {
                final cpfNorm = m.cpf.replaceAll(RegExp(r'\D'), '');
                membrosCombinados[cpfNorm] = m;
              }
              final mesclada = lojaNousAtual.copyWith(
                membros: membrosCombinados.values.toList(),
              );
              await _pdvProvider!.adicionarOuAtualizarLoja(mesclada);
            } else {
              await _pdvProvider!.adicionarOuAtualizarLoja(lojaNousBruta);
            }
          } catch (_) {}
        }

        if (dados['presencas'] != null) {
          final lista = dados['presencas'] as List<dynamic>? ?? [];
          presencasAtivas.value = lista
              .map((e) => TerminalConectadoInfo.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      } else {
        _lojaSincronizada = null;
      }

      // 2. Conecta ao WebSocket para atualizações em tempo real
      final wsUrl = 'ws://$_ipServidor:$_portaServidor/api/ws';
      _ws = await WebSocket.connect(wsUrl).timeout(const Duration(seconds: 4));

      estaConectado.value = true;
      debugPrint('[ClienteRedeLocal] Conectado ao servidor via WebSocket em $wsUrl');

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('nous_ultimo_ip_balcao', _ipServidor!);
        await prefs.setInt('nous_ultima_porta_balcao', _portaServidor!);
      } catch (_) {}

      // Envia identificação nominal do dispositivo e dados do usuário para o balcão
      _ws!.add(
        jsonEncode({
          'tipo': 'identificacao',
          'nomeDispositivo': _nomeDispositivo,
          'cpf': cpfLogado,
          'nomeUsuario': nomeUsuario,
          'apelido': apelidoUsuario,
        }),
      );

      // Heartbeat ping/pong para manter conexão viva
      _timerPing?.cancel();
      _timerPing = Timer.periodic(const Duration(seconds: 5), (_) {
        if (_ws != null && estaConectado.value) {
          try {
            _ws!.add(jsonEncode({'tipo': 'ping'}));
          } catch (_) {}
        }
      });

      final socketInstancia = _ws;
      _ws!.listen(
        _processarMensagemWs,
        onDone: () {
          debugPrint('[ClienteRedeLocal] WebSocket onDone recebido.');
          if (_ws == socketInstancia) {
            _aoDesconectar();
          } else {
            debugPrint('[ClienteRedeLocal] onDone de conexão anterior/substituída descartado.');
          }
        },
        onError: (err) {
          debugPrint('[ClienteRedeLocal] WebSocket onError recebido: $err');
          if (_ws == socketInstancia) {
            _aoDesconectar();
          }
        },
      );

      // Orquestração sequencial e resiliente em background pós-conexão para evitar gargalos no socket e banco SQLite
      unawaited(() async {
        try {
          // Checagem prioritária imediata de nova versão no balcão (em paralelo, sem esperar nada)
          unawaited(verificarAtualizacaoLocal());

          // 0. Sincroniza o relógio em uníssono com o balcão antes de qualquer operação
          await RelogioRedeService.instancia.sincronizarComServidor(
            ip: _ipServidor!,
            porta: _portaServidor!,
          );
          if (lojaBrutaParaReconciliar != null) {
            try {
              final lojaReconciliada = await _reconciliarLojaMutua(
                lojaBrutaParaReconciliar,
                imagensAusentesParaReconciliar,
              );
              _lojaSincronizada = lojaReconciliada;
              await _pdvProvider!.adicionarOuAtualizarLoja(lojaReconciliada);
              if (fotosUsuariosAusentesParaReconciliar.isNotEmpty) {
                _curarFotosUsuariosAusentesNoServidor(
                  fotosUsuariosAusentesParaReconciliar,
                );
              }
            } catch (e) {
              debugPrint('[ClienteRedeLocal] Reconciliação mútua assíncrona de mídia: $e');
            }
          }
          await sincronizarIdentidadeUsuario();
          await reconciliarContasComServidor();
          await sincronizarPerfisLojasComServidor();
          await ChatService.sincronizarMensagensComBalcao(
            ipServidor: _ipServidor!,
            portaServidor: _portaServidor!,
            cpfUsuario: cpfLogado,
            lojaId: _lojaSincronizada?.id,
          );
          if (_lojaSincronizada?.id != PdvProvider.idLojaColetivaNous) {
            await ChatService.sincronizarMensagensComBalcao(
              ipServidor: _ipServidor!,
              portaServidor: _portaServidor!,
              lojaId: PdvProvider.idLojaColetivaNous,
            );
          }
          await ChatService.drenarFilaDeSaida();
          verificarAtualizacaoLocal();
        } catch (e) {
          debugPrint('[ClienteRedeLocal] Erro na sincronização pós-conexão: $e');
        }
      }());

      return true;
    } catch (e) {
      debugPrint('[ClienteRedeLocal] Erro ao conectar ao servidor: $e');
      estaConectado.value = false;
      if (ultimoErro.value == null) {
        ultimoErro.value = 'Não foi possível conectar ao balcão.';
      }
      return false;
    } finally {
      _conectando = false;
    }
  }

  Future<void> _processarMensagemWs(dynamic msg) async {
    final ctx = ClienteWsContext(
      pdvProvider: _pdvProvider,
      authProvider: _authProvider,
      presencasAtivas: presencasAtivas,
      obterLojaSincronizada: () => _lojaSincronizada,
      definirLojaSincronizada: (l) => _lojaSincronizada = l,
      definirAplicandoAtualizacaoRemota: (v) => _aplicandoAtualizacaoRemota = v,
      sincronizarImagensRemotas: _sincronizarImagensRemotas,
      vincularLojaSeNecessario: _vincularLojaSeNecessario,
      enviarLojaCuradaParaServidor: _enviarLojaCuradaParaServidor,
      curarFotosUsuariosAusentesNoServidor: _curarFotosUsuariosAusentesNoServidor,
      sincronizarPerfisLojasComServidor: sincronizarPerfisLojasComServidor,
      processarSinalChamada: _processarSinalChamada,
      baixarImagemRemota: baixarImagemRemota,
    );
    await ClienteWsMessageHandler.processarMensagem(msg, ctx);
  }

  void _processarSinalChamada(Map<String, dynamic> dados) {
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
          final destEhLojaLocal = destId.isNotEmpty &&
              (_pdvProvider?.lojas.any(
                    (l) =>
                        PdvProvider.normalizarIdLoja(l.id) == destId &&
                        (ChatService.normalizarCpf(l.cpfDonoOriginal) ==
                                meuCpf ||
                            l.membros.any(
                              (m) =>
                                  ChatService.normalizarCpf(m.cpf) == meuCpf,
                            )),
                  ) ??
                  false);

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
      debugPrint('[ClienteRedeLocal] Erro ao processar sinal de chamada: $e');
    }
  }

  void _aoDesconectar() {
    debugPrint('[ClienteRedeLocal] _aoDesconectar invocado.');
    estaConectado.value = false;
    presencasAtivas.value = [];
    _ws = null;
    _timerPing?.cancel();
    RelogioRedeService.instancia.desmarcarSincronizado();

    // Agenda tentativa de reconexão apenas se o usuário não desconectou explicitamente
    if (!_usuarioDesconectouManualmente && _ipServidor != null && _portaServidor != null) {
      _timerReconexao?.cancel();
      _timerReconexao = Timer(const Duration(seconds: 4), () {
        if (!conectado && !_conectando && _ipServidor != null && _portaServidor != null && _pdvProvider != null) {
          debugPrint('[ClienteRedeLocal] Reconectando automaticamente ao balcão ($_ipServidor:$_portaServidor)...');
          conectar(ip: _ipServidor!, porta: _portaServidor!, pdv: _pdvProvider!, auth: _authProvider);
        }
      });
    }
  }

  /// Vincula a loja sincronizada aos perfis locais do usuário se ele for membro ou dono
  Future<void> _vincularLojaSeNecessario(Loja loja) async {
    if (LojasService.ehLojaHostFalsa(loja.id, loja.tags, loja.nome)) return;
    final cpf = _pdvProvider?.cpfAtual ?? _authProvider?.contaAtual?.cpf ?? _authProvider?.cpf;
    if (cpf != null && cpf.isNotEmpty && _pdvProvider != null) {
      final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
      final ehDono =
          loja.cpfDonoOriginal.replaceAll(RegExp(r'\D'), '') == cpfLimpo;
      final ehMembro = loja.membros.any(
        (m) => m.cpf.replaceAll(RegExp(r'\D'), '') == cpfLimpo,
      );

      if (ehDono) {
        // O dono nunca deve ter ReferenciaLoja para sua própria loja (já reside em minhasLojas).
        await LojasService.removerReferencia(cpf, loja.id);
        return;
      }

      // Se o usuário logado NÃO é membro da equipe nem dono, NUNCA vincula aos seus perfis!
      if (!ehMembro) {
        debugPrint(
          '[ClienteRedeLocal] Usuário $cpfLimpo não é membro nem dono da loja "${loja.nome}". Não vinculando aos perfis profissionais.',
        );
        return;
      }

      // Salva a loja completa no banco SQLite local deste aparelho com proteção de imagens
      await LojasService.salvarLojaIndividual(loja);

      // Garante a referência no cofre deste CPF participante para que a loja apareça em lojasQueParticipo
      final refs = await LojasService.carregarReferencias(cpf);
      final jaTem = refs.any((r) => r.lojaId == loja.id);
      if (!jaTem) {
        await LojasService.adicionarReferencia(
          cpf,
          ReferenciaLoja(
            lojaId: loja.id,
            cpfDonoOriginal: loja.cpfDonoOriginal,
          ),
        );

        // Recarrega as lojas no PdvProvider apenas na primeira vinculação para aparecer em lojasQueParticipo
        await _pdvProvider!.entrarComCpf(cpf);
      }
    }
  }

  /// Envia mensagem de chat em tempo real via WebSocket para o servidor (com fallback REST)
  Future<bool> enviarMensagemChat(
    MensagemChat msg, {
    Map<String, dynamic>? payloadCustomizado,
  }) async {
    MensagemChat msgParaEnvio = msg;

    // Se contiver anexo local (imagem, áudio ou arquivo), garante envio do arquivo
    if (msg.caminhoAnexo.isNotEmpty) {
      final resolvida = ImagemService.resolverCaminhoExistente(msg.caminhoAnexo);
      if (resolvida != null) {
        final jaTemBase64 = payloadCustomizado != null && payloadCustomizado['anexoBytesBase64'] != null;
        if (!jaTemBase64) {
          final String anexoNoServidor;
          if (msg.tipo == 'imagem') {
            anexoNoServidor = await _enviarUploadImagemParaServidor(resolvida);
          } else {
            anexoNoServidor = await _transferencia.enviarUploadAnexoParaServidor(
              ipServidor: _ipServidor,
              portaServidor: _portaServidor,
              caminhoLocal: resolvida,
              subpasta: msg.tipo == 'audio' ? 'audios' : 'anexos',
            );
          }
          if (anexoNoServidor.isNotEmpty) {
            msgParaEnvio = msgParaEnvio.copyWith(caminhoAnexo: anexoNoServidor);
          }
        } else {
          // Já temos o binário Base64 na carga útil (anexo leve <= 64KB); despacha upload bruto em paralelo sem bloquear tempo real
          if (msg.tipo == 'imagem') {
            unawaited(_enviarUploadImagemParaServidor(resolvida));
          } else {
            unawaited(_transferencia.enviarUploadAnexoParaServidor(
              ipServidor: _ipServidor,
              portaServidor: _portaServidor,
              caminhoLocal: resolvida,
              subpasta: msg.tipo == 'audio' ? 'audios' : 'anexos',
            ));
          }
        }
      }
    }

    final dadosEnvio = payloadCustomizado != null
        ? Map<String, dynamic>.from(payloadCustomizado)
        : msgParaEnvio.toJson();
    if (msgParaEnvio.caminhoAnexo != msg.caminhoAnexo) {
      dadosEnvio['caminhoAnexo'] = msgParaEnvio.caminhoAnexo;
    }

    // 1. Envia via WebSocket em tempo real se conectado
    if (_ws != null && estaConectado.value) {
      try {
        _ws!.add(
          jsonEncode({
            'tipo': 'mensagem_chat',
            'mensagem': dadosEnvio,
          }),
        );
        return true;
      } catch (e) {
        debugPrint('[ClienteRedeLocal] Erro ao enviar mensagem via WS, tentando REST: $e');
      }
    }

    // 2. Fallback imediato para REST HTTP POST /api/chat/mensagem
    String? ip = _ipServidor;
    int porta = _portaServidor ?? ServidorRedeLocal.portaPadraoHttp;
    if (ip == null && lojasEncontradas.value.isNotEmpty) {
      ip = lojasEncontradas.value.first.ip;
      porta = lojasEncontradas.value.first.porta;
    }
    if (ip == null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        ip = prefs.getString('nous_ultimo_ip_balcao');
        porta = prefs.getInt('nous_ultima_porta_balcao') ?? ServidorRedeLocal.portaPadraoHttp;
      } catch (_) {}
    }

    if (ip != null) {
      try {
        final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
        final uri = Uri.parse('http://$ip:$porta/api/chat/mensagem');
        final req = await client.postUrl(uri);
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode(dadosEnvio));
        final resp = await req.close();
        if (resp.statusCode == HttpStatus.ok) {
          return true;
        }
      } catch (e) {
        debugPrint('[ClienteRedeLocal] Erro ao enviar mensagem de chat via REST: $e');
      }
    }
    return false;
  }

  /// Envia um evento de controle ou confirmação via WebSocket (ex: mensagem_entregue, mensagem_lida)
  void enviarEventoWs(Map<String, dynamic> payload) {
    if (_ws != null && estaConectado.value) {
      try {
        _ws!.add(jsonEncode(payload));
      } catch (e) {
        debugPrint('[ClienteRedeLocal] Erro ao enviar evento WS: $e');
      }
    }
  }

  /// Envia um pedido (novo ou atualizado) realizado no celular para o servidor central da loja
  Future<bool> enviarPedido(PedidoLoja pedido) async {
    // 1. Tenta WebSocket primeiro para reflexo instantâneo em tempo real
    if (_ws != null && estaConectado.value) {
      try {
        _ws!.add(
          jsonEncode({
            'tipo': 'pedido_atualizado',
            'pedido': pedido.toJson(),
          }),
        );
      } catch (_) {}
    }

    return _despachante.enviarPedido(
      ipServidor: _ipServidor,
      portaServidor: _portaServidor,
      pedido: pedido,
    );
  }

  /// Envia uma movimentação de estoque realizada no celular para o servidor
  Future<bool> enviarMovimentoEstoque(
    MovimentoEstoque mov, {
    String? lojaId,
  }) =>
      _despachante.enviarMovimentoEstoque(
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
        mov: mov,
        lojaId: lojaId ?? _lojaSincronizada?.id,
      );

  /// Envia atualização de mesa para o servidor central
  Future<bool> enviarMesa(
    MesaLoja mesa, {
    String? lojaId,
  }) =>
      _despachante.enviarMesa(
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
        mesa: mesa,
        lojaId: lojaId ?? _lojaSincronizada?.id,
      );

  Future<String> _enviarUploadImagemParaServidor(String caminhoLocal) {
    return _transferencia.enviarUploadImagemParaServidor(
      ipServidor: _ipServidor,
      portaServidor: _portaServidor,
      caminhoLocal: caminhoLocal,
    );
  }


  Future<bool> _enviarLojaCuradaParaServidor(Loja lojaCurada) {
    return _reconciliador.enviarLojaCuradaParaServidor(
      ipServidor: _ipServidor,
      portaServidor: _portaServidor,
      lojaCurada: lojaCurada,
    );
  }

  Future<Loja> _prepararLojaComUploadsParaServidor(Loja loja) {
    return _reconciliador.prepararLojaComUploadsParaServidor(
      ipServidor: _ipServidor,
      portaServidor: _portaServidor,
      loja: loja,
    );
  }

  /// Envia a atualização completa da loja realizada neste terminal móvel para o servidor central (balcão)
  Future<bool> enviarLojaAtualizada(Loja loja, {bool imediato = false}) async {
    if (_ipServidor == null || _portaServidor == null || !conectado) return false;
    if (_aplicandoAtualizacaoRemota) return false;

    _timerDebounceEnvioLoja?.cancel();

    Future<bool> executarEnvio() async {
      try {
        final lojaParaEnvio = await _prepararLojaComUploadsParaServidor(loja);

        final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
        final request = await client.postUrl(
          Uri.parse('http://$_ipServidor:$_portaServidor/api/loja/atualizar'),
        );
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(lojaParaEnvio.toJson()));
        final response = await request.close();
        final ok = response.statusCode == HttpStatus.ok;
        debugPrint(
          '[ClienteRedeLocal] Sincronização da loja "${loja.nome}" enviada ao balcão: '
          '${ok ? "Sucesso" : "Falha (${response.statusCode})"}',
        );
        return ok;
      } catch (e) {
        debugPrint('[ClienteRedeLocal] Erro ao enviar atualização da loja ao servidor: $e');
        return false;
      }
    }

    if (imediato) {
      return await executarEnvio();
    }

    final completer = Completer<bool>();
    _timerDebounceEnvioLoja = Timer(const Duration(milliseconds: 150), () async {
      final res = await executarEnvio();
      if (!completer.isCompleted) completer.complete(res);
    });
    return completer.future;
  }

  /// Desconecta do servidor e encerra todas as conexões e sessões pendentes
  Future<void> desconectar({bool manual = false}) async {
    if (manual) {
      _usuarioDesconectouManualmente = true;
    }
    _timerReconexao?.cancel();
    _timerReconexao = null;
    _timerPing?.cancel();
    _timerPing = null;
    _timerDebounceEnvioLoja?.cancel();
    _timerDebounceEnvioLoja = null;

    final wsAntigo = _ws;
    _ws = null;
    try {
      await wsAntigo?.close();
    } catch (_) {}

    _ipServidor = null;
    _portaServidor = null;
    _lojaSincronizada = null;
    estaConectado.value = false;
    presencasAtivas.value = [];
    pararDescoberta();
  }

  /// Realiza a reconciliação mútua e bidirecional de dados e imagens entre o Servidor e este Cliente
  Future<Loja> _reconciliarLojaMutua(
    Loja lojaRemota,
    List<String> imagensAusentesNoServidor,
  ) {
    return _reconciliador.reconciliarLojaMutua(
      ipServidor: _ipServidor,
      portaServidor: _portaServidor,
      lojaRemota: lojaRemota,
      imagensAusentesNoServidor: imagensAusentesNoServidor,
      pdvProvider: _pdvProvider,
      lojaSincronizada: _lojaSincronizada,
    );
  }

  /// Baixa imagens remotas do servidor que não existem no armazenamento local
  /// e regrava os caminhos locais atualizados para que fiquem 100% visíveis no celular.
  Future<Loja> _sincronizarImagensRemotas(Loja lojaRemota) {
    return _reconciliador.sincronizarImagensRemotas(
      ipServidor: _ipServidor,
      portaServidor: _portaServidor,
      lojaRemota: lojaRemota,
      pdvProvider: _pdvProvider,
      lojaSincronizada: _lojaSincronizada,
    );
  }

  /// Sincroniza a Identidade do Usuário (dados cadastrais e foto) a partir do balcão (autocura mútua)
  Future<void> sincronizarIdentidadeUsuario({AuthProvider? auth}) {
    return _sincronizador.sincronizarIdentidadeUsuario(
      ipServidor: _ipServidor,
      portaServidor: _portaServidor,
      auth: auth ?? _authProvider,
      pdvProvider: _pdvProvider,
    );
  }

  /// Consulta o servidor balcão na rede Wi-Fi local para obter a ficha unificada da conta pelo CPF
  Future<UsuarioNous?> buscarUsuarioRemoto(String cpf) async {
    String? ip = _ipServidor;
    int porta = _portaServidor ?? ServidorRedeLocal.portaPadraoHttp;

    if (ip == null && lojasEncontradas.value.isNotEmpty) {
      ip = lojasEncontradas.value.first.ip;
      porta = lojasEncontradas.value.first.porta;
    }

    var iniciouDescobertaAqui = false;
    if (ip == null) {
      iniciouDescobertaAqui = true;
      await iniciarDescoberta();
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (lojasEncontradas.value.isNotEmpty) {
        ip = lojasEncontradas.value.first.ip;
        porta = lojasEncontradas.value.first.porta;
      }
    }

    if (iniciouDescobertaAqui) {
      pararDescoberta();
    }

    return _sincronizador.buscarUsuarioRemoto(
      ipServidor: ip,
      portaServidor: porta,
      cpf: cpf,
      authProvider: _authProvider,
      pdvProvider: _pdvProvider,
    );
  }

  /// Verifica se o balcão possui atualizações do sistema ou APK disponível para download
  Future<void> verificarAtualizacaoLocal() =>
      _despachante.verificarAtualizacaoLocal(
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
      );


  /// Baixa uma imagem remota individual do balcão e salva no armazenamento local
  Future<String> baixarImagemRemota(String caminhoRemoto, {String? cpf}) {
    return _transferencia.baixarImagemRemota(
      caminhoRemoto: caminhoRemoto,
      ipServidor: _ipServidor,
      portaServidor: _portaServidor,
      cpf: cpf,
      onFotoUsuarioBaixada: (cpfLimpo, pathFinal) async {
        try {
          final c = await ContasNousService.buscarPorCpf(cpfLimpo);
          if (c != null) {
            final atualizada = c.copyWith(foto: pathFinal);
            await ContasNousService.salvar(atualizada);
            _authProvider?.atualizarContaNoCache(atualizada);
            _pdvProvider?.sincronizarFotoUsuarioEmClientes(cpfLimpo, pathFinal);
          }
        } catch (_) {}
      },
    );
  }

  /// Baixa um arquivo de áudio/música remoto do balcão e salva no armazenamento local
  Future<String> baixarAudioRemoto(String caminhoRemoto) {
    return _transferencia.baixarAudioRemoto(
      caminhoRemoto: caminhoRemoto,
      ipServidor: _ipServidor,
      portaServidor: _portaServidor,
    );
  }

  /// Envia a Identidade do Usuário (dados cadastrais, apelido e foto) atualizada para o servidor balcão
  Future<bool> enviarUsuario(UsuarioNous usuario) {
    return _sincronizador.enviarUsuario(
      ipServidor: _ipServidor,
      portaServidor: _portaServidor,
      usuario: usuario,
    );
  }

  Future<void> _curarFotosUsuariosAusentesNoServidor(List<String> cpfsAusentes) {
    return _sincronizador.curarFotosUsuariosAusentesNoServidor(
      ipServidor: _ipServidor,
      portaServidor: _portaServidor,
      cpfsAusentes: cpfsAusentes,
      pdvProvider: _pdvProvider,
    );
  }

  /// Método público para forçar a sincronização e reconciliação mútua de contas e usuários com o balcão
  Future<void> reconciliarContasComServidor() =>
      _sincronizador.reconciliarTodasContasLocaisComServidor(
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
        authProvider: _authProvider,
        pdvProvider: _pdvProvider,
      );

  /// Sincroniza pan-dispositivo todas as lojas e referências associadas ao CPF ativo
  Future<void> sincronizarPerfisLojasComServidor() {
    return _sincronizador.sincronizarPerfisLojasComServidor(
      ipServidor: _ipServidor,
      portaServidor: _portaServidor,
      authProvider: _authProvider,
      pdvProvider: _pdvProvider,
      lojaSincronizada: _lojaSincronizada,
    );
  }

  /// Notifica o servidor balcão que o membro saiu da loja para desvinculação imediata
  Future<void> notificarSaidaLoja(String lojaId, String cpf) =>
      _despachante.notificarSaidaLoja(
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
        lojaId: lojaId,
        cpf: cpf,
      );


  /// Envia payload genérico JSON pelo WebSocket ativo para o servidor balcão
  void enviarMensagemRaw(Map<String, dynamic> payload) {
    if (_ws != null && estaConectado.value) {
      try {
        _ws!.add(jsonEncode(payload));
      } catch (e) {
        debugPrint('[ClienteRedeLocal] Erro ao enviar mensagem raw via WebSocket: $e');
      }
    }
  }

  /// Sincroniza o relógio deste dispositivo com o balcão da rede local sob demanda
  Future<bool> sincronizarRelogio() async {
    String? ip = _ipServidor;
    int? porta = _portaServidor;
    if (ip == null && lojasEncontradas.value.isNotEmpty) {
      ip = lojasEncontradas.value.first.ip;
      porta = lojasEncontradas.value.first.porta;
    }
    if (ip != null && porta != null) {
      return await RelogioRedeService.instancia.sincronizarComServidor(
        ip: ip,
        porta: porta,
      );
    }
    return false;
  }
}
