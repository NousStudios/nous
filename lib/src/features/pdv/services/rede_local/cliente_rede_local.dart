import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nous/src/core/services/relogio_rede_service.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/rede_local/reconciliador_loja_rede.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/sincronizador_usuarios_rede.dart';
import 'package:nous/src/features/pdv/services/rede_local/transferencia_arquivos_rede.dart';
import 'package:nous/src/features/pdv/services/rede_local/despachante_cliente_rede.dart';
import 'package:nous/src/features/pdv/models/dispositivo_loja_info.dart';
import 'package:nous/src/features/pdv/services/rede_local/descoberta_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/helpers/gerenciador_dispositivo_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/helpers/resolvedor_url_rede.dart';
import 'package:nous/src/features/pdv/services/rede_local/handlers/cliente_pos_conexao_orquestrador.dart';
import 'package:nous/src/features/pdv/services/rede_local/handlers/cliente_ws_message_handler.dart';
import 'package:nous/src/features/pdv/services/rede_local/handlers/snapshot_loja_cliente_handler.dart';

export 'package:nous/src/features/pdv/models/dispositivo_loja_info.dart';

/// Gerencia o Cliente que conecta o celular ao servidor do balcão na rede Wi-Fi.
class ClienteRedeLocal {
  static final ClienteRedeLocal _instancia = ClienteRedeLocal._interno();
  factory ClienteRedeLocal() => _instancia;
  ClienteRedeLocal._interno();

  WebSocket? _ws;
  Timer? _timerPing;
  Timer? _timerReconexao;

  String? _ipServidor;
  int? _portaServidor;
  PdvProvider? _pdvProvider;
  AuthProvider? _authProvider;
  Loja? _lojaSincronizada;

  final GerenciadorDispositivoLocal _dispLocal = GerenciadorDispositivoLocal();
  String get _nomeDispositivo => _dispLocal.nomeDispositivo;

  final ValueNotifier<bool> estaConectado = ValueNotifier<bool>(false);
  final ValueNotifier<String?> ultimoErro = ValueNotifier<String?>(null);
  final ValueNotifier<List<DispositivoLojaInfo>> lojasEncontradas =
      ValueNotifier<List<DispositivoLojaInfo>>([]);
  final ValueNotifier<List<TerminalConectadoInfo>> presencasAtivas =
      ValueNotifier<List<TerminalConectadoInfo>>([]);

  late final DescobertaRedeLocal _descoberta = DescobertaRedeLocal(
    lojasEncontradas: lojasEncontradas,
    onServidorDescoberto: (info) {
      if (!conectado && !_conectando && _pdvProvider != null) {
        conectar(ip: info.ip, porta: info.porta, pdv: _pdvProvider!, auth: _authProvider);
      }
    },
  );

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

  /// Permite definir o IP/porta do servidor balcão para despachos REST sem WS ativo
  void configurarServidorManual(String ip, int porta) {
    _ipServidor = ip.trim();
    _portaServidor = porta;
  }
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

  Future<String> obterNomeDispositivo() => _dispLocal.obterNomeDispositivo();

  Future<void> salvarNomeDispositivo(String novoNome) =>
      _dispLocal.salvarNomeDispositivo(
        novoNome,
        ws: _ws,
        estaConectado: estaConectado.value,
        cpfLogado: _pdvProvider?.cpfAtual,
      );

  /// Inicia escuta UDP para encontrar servidores de lojas transmitindo no Wi-Fi
  /// acompanhada de radar ativo HTTP pela sub-rede local.
  Future<void> iniciarDescoberta({PdvProvider? pdv, AuthProvider? auth}) async {
    if (pdv != null) _pdvProvider = pdv;
    if (auth != null) _authProvider = auth;
    await _descoberta.iniciarDescoberta();
  }

  void pararDescoberta() {
    _descoberta.pararDescoberta();
  }

  /// Inicia escuta contínua e tenta reconectar automaticamente ao servidor balcão
  Future<void> tentarAutoConectarSeDisponivel(PdvProvider pdv, [AuthProvider? auth]) async {
    if (ServidorRedeLocal().ativo) return;
    _pdvProvider = pdv;
    if (auth != null) _authProvider = auth;
    if (conectado || _conectando) return;

    await iniciarDescoberta();

    // 1. Tenta o último IP conhecido salvo
    final ultimo = await GerenciadorDispositivoLocal.obterUltimoBalcao();
    if (ultimo.ip != null && ultimo.ip!.isNotEmpty) {
      final ok = await conectar(
        ip: ultimo.ip!,
        porta: ultimo.porta ?? ServidorRedeLocal.portaPadraoHttp,
        pdv: pdv,
        auth: auth,
      );
      if (ok) return;
    }

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

      // 1. Baixa e consolida o snapshot atualizado da Loja via REST
      final resultadoSnapshot = await SnapshotLojaClienteHandler.obterEConsolidarSnapshot(
        ipServidor: _ipServidor!,
        portaServidor: _portaServidor!,
        cpfLogado: cpfLogado,
        nomeUsuario: nomeUsuario,
        apelidoUsuario: apelidoUsuario,
        nomeDispositivo: _nomeDispositivo,
        pdvProvider: _pdvProvider!,
        vincularLojaSeNecessario: _vincularLojaSeNecessario,
      );

      if (!resultadoSnapshot.sucesso) {
        ultimoErro.value = resultadoSnapshot.erro;
        return false;
      }

      _lojaSincronizada = resultadoSnapshot.lojaConsolidada;
      final lojaBrutaParaReconciliar = resultadoSnapshot.lojaBrutaParaReconciliar;
      final imagensAusentesParaReconciliar = resultadoSnapshot.imagensAusentes;
      final fotosUsuariosAusentesParaReconciliar = resultadoSnapshot.fotosUsuariosAusentes;
      if (resultadoSnapshot.presencas != null) {
        presencasAtivas.value = resultadoSnapshot.presencas!;
      }

      // 2. Conecta ao WebSocket para atualizações em tempo real
      final wsUrl = ResolvedorUrlRede.montarUrlWs(
        hostOuIp: _ipServidor,
        porta: _portaServidor,
        caminho: '/api/ws',
      );
      _ws = await WebSocket.connect(wsUrl).timeout(const Duration(seconds: 4));

      estaConectado.value = true;
      debugPrint('[ClienteRedeLocal] Conectado ao servidor via WebSocket em $wsUrl');

      await GerenciadorDispositivoLocal.salvarUltimoBalcao(_ipServidor!, _portaServidor!);

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

      // Orquestração sequencial e resiliente em background pós-conexão
      unawaited(ClientePosConexaoOrquestrador.executar(
        ipServidor: _ipServidor!,
        portaServidor: _portaServidor!,
        cpfLogado: cpfLogado,
        lojaBrutaParaReconciliar: lojaBrutaParaReconciliar,
        imagensAusentesParaReconciliar: imagensAusentesParaReconciliar,
        fotosUsuariosAusentesParaReconciliar: fotosUsuariosAusentesParaReconciliar,
        pdvProvider: _pdvProvider,
        reconciliarLojaMutua: _reconciliarLojaMutua,
        onLojaSincronizada: (l) => _lojaSincronizada = l,
        curarFotosUsuariosAusentesNoServidor: _curarFotosUsuariosAusentesNoServidor,
        verificarAtualizacaoLocal: verificarAtualizacaoLocal,
        sincronizarIdentidadeUsuario: sincronizarIdentidadeUsuario,
        reconciliarContasComServidor: reconciliarContasComServidor,
        sincronizarPerfisLojasComServidor: sincronizarPerfisLojasComServidor,
        idLojaSincronizada: _lojaSincronizada?.id,
      ));

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
    final meuCpf = (_authProvider?.cpf ?? _pdvProvider?.cpfAtual ?? '').replaceAll(RegExp(r'\D'), '');
    ClienteWsMessageHandler.processarSinalChamada(
      dados: dados,
      meuCpf: meuCpf,
      lojasLocal: _pdvProvider?.lojas,
    );
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
  Future<void> _vincularLojaSeNecessario(Loja loja) =>
      ClientePosConexaoOrquestrador.vincularLojaSeNecessario(
        loja: loja,
        cpfLogado: _pdvProvider?.cpfAtual ?? _authProvider?.contaAtual?.cpf ?? _authProvider?.cpf,
        pdvProvider: _pdvProvider,
      );

  /// Envia mensagem de chat em tempo real via WebSocket para o servidor (com fallback REST)
  Future<bool> enviarMensagemChat(
    MensagemChat msg, {
    Map<String, dynamic>? payloadCustomizado,
  }) =>
      _despachante.enviarMensagemChat(
        ws: _ws,
        estaConectado: estaConectado.value,
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
        lojasEncontradas: lojasEncontradas.value,
        msg: msg,
        payloadCustomizado: payloadCustomizado,
        uploadImagem: _enviarUploadImagemParaServidor,
        uploadAnexo: (caminho, subpasta) => _transferencia.enviarUploadAnexoParaServidor(
          ipServidor: _ipServidor,
          portaServidor: _portaServidor,
          caminhoLocal: caminho,
          subpasta: subpasta,
        ),
      );

  /// Envia um evento de controle ou confirmação via WebSocket (ex: mensagem_entregue, mensagem_lida)
  void enviarEventoWs(Map<String, dynamic> payload) => enviarMensagemRaw(payload);

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
          ResolvedorUrlRede.montarUriHttp(
            hostOuIp: _ipServidor,
            porta: _portaServidor,
            caminho: '/api/loja/atualizar',
          ),
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
  Future<String> baixarImagemRemota(String caminhoRemoto, {String? cpf}) =>
      _transferencia.baixarImagemRemota(
        caminhoRemoto: caminhoRemoto,
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
        cpf: cpf,
        onFotoUsuarioBaixada: _onFotoUsuarioBaixada,
      );

  Future<void> _onFotoUsuarioBaixada(String cpfLimpo, String pathFinal) async {
    try {
      final c = await ContasNousService.buscarPorCpf(cpfLimpo);
      if (c != null) {
        final atualizada = c.copyWith(foto: pathFinal);
        await ContasNousService.salvar(atualizada);
        _authProvider?.atualizarContaNoCache(atualizada);
        _pdvProvider?.sincronizarFotoUsuarioEmClientes(cpfLimpo, pathFinal);
      }
    } catch (_) {}
  }

  /// Baixa um arquivo de áudio/música remoto do balcão e salva no armazenamento local
  Future<String> baixarAudioRemoto(String caminhoRemoto) =>
      _transferencia.baixarAudioRemoto(
        caminhoRemoto: caminhoRemoto,
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
      );

  /// Envia a Identidade do Usuário (dados cadastrais, apelido e foto) atualizada para o servidor balcão
  Future<bool> enviarUsuario(UsuarioNous usuario) =>
      _sincronizador.enviarUsuario(
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
        usuario: usuario,
      );

  Future<void> _curarFotosUsuariosAusentesNoServidor(List<String> cpfsAusentes) =>
      _sincronizador.curarFotosUsuariosAusentesNoServidor(
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
        cpfsAusentes: cpfsAusentes,
        pdvProvider: _pdvProvider,
      );

  /// Método público para forçar a sincronização e reconciliação mútua de contas e usuários com o balcão
  Future<void> reconciliarContasComServidor() =>
      _sincronizador.reconciliarTodasContasLocaisComServidor(
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
        authProvider: _authProvider,
        pdvProvider: _pdvProvider,
      );

  /// Sincroniza pan-dispositivo todas as lojas e referências associadas ao CPF ativo
  Future<void> sincronizarPerfisLojasComServidor() =>
      _sincronizador.sincronizarPerfisLojasComServidor(
        ipServidor: _ipServidor,
        portaServidor: _portaServidor,
        authProvider: _authProvider,
        pdvProvider: _pdvProvider,
        lojaSincronizada: _lojaSincronizada,
      );

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
    final ip = _ipServidor ?? (lojasEncontradas.value.isNotEmpty ? lojasEncontradas.value.first.ip : null);
    final porta = _portaServidor ?? (lojasEncontradas.value.isNotEmpty ? lojasEncontradas.value.first.porta : null);
    if (ip != null && porta != null) {
      return await RelogioRedeService.instancia.sincronizarComServidor(ip: ip, porta: porta);
    }
    return false;
  }
}
