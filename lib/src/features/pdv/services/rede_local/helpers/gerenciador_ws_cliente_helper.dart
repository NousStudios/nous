import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nous/src/core/services/atualizacao_service.dart';
import 'package:nous/src/core/services/relogio_rede_service.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/pdv/models/dispositivo_loja_info.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/rede_local/helpers/gerenciador_dispositivo_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/helpers/resolvedor_url_rede.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

/// Dados resolvidos do usuário logado para identificação no balcão.
class DadosUsuarioConexao {
  final String cpf;
  final String? nome;
  final String? apelido;

  const DadosUsuarioConexao({
    required this.cpf,
    this.nome,
    this.apelido,
  });
}

/// Gerencia o ciclo de conexão WebSocket, heartbeat (ping), reconexão automática,
/// ciclo de vida do app e envio de mensagens de controle/identificação no cliente.
class GerenciadorWsClienteHelper {
  WebSocket? _ws;
  Timer? _timerPing;
  Timer? _timerReconexao;
  AppLifecycleListener? _lifecycleListener;
  bool _usuarioDesconectouManualmente = false;

  WebSocket? get socket => _ws;
  bool get usuarioDesconectouManualmente => _usuarioDesconectouManualmente;

  bool estaConectadoAtivo(ValueNotifier<bool> estaConectado) =>
      _ws != null && estaConectado.value;

  void marcarDesconexaoManual(bool manual) {
    _usuarioDesconectouManualmente = manual;
  }

  void cancelarTimerReconexao() {
    _timerReconexao?.cancel();
    _timerReconexao = null;
  }

  /// Registra escuta do ciclo de vida do Flutter para reconexão imediata quando o app volta à tela.
  void inicializarMonitoramentoCicloVida(Future<void> Function() onRetomada) {
    _lifecycleListener?.dispose();
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        debugPrint(
          '[ClienteRedeLocal] App retornou a primeiro plano (onResume). Verificando conexão com Balcão...',
        );
        onRetomada();
      },
    );
  }

  /// Verifica a integridade da conexão ao destravar o celular ou retomar o app.
  Future<void> verificarEAutoReconectarNaRetomada({
    required bool conectado,
    required bool conectando,
    required PdvProvider? pdv,
    required AuthProvider? auth,
    required Future<void> Function(PdvProvider, [AuthProvider?]) tentarAutoConectar,
    required Future<void> Function() desconectar,
  }) async {
    if (ServidorRedeLocal().ativo) return;
    if (_usuarioDesconectouManualmente) return;
    if (pdv == null) return;

    if (!conectado && !conectando) {
      debugPrint(
        '[ClienteRedeLocal] Retomada detectou terminal offline. Reconectando ao Balcão...',
      );
      await tentarAutoConectar(pdv, auth);
      return;
    }

    if (conectado && _ws != null) {
      try {
        _ws!.add(jsonEncode({'tipo': 'ping'}));
      } catch (e) {
        debugPrint(
          '[ClienteRedeLocal] Socket morto na retomada ($e). Reiniciando conexão...',
        );
        await desconectar();
        await tentarAutoConectar(pdv, auth);
      }
    }
  }

  /// Resolve CPF, nome e apelido do usuário ativo para envio na identificação ao balcão.
  Future<DadosUsuarioConexao> resolverDadosUsuarioLogado({
    required PdvProvider? pdvProvider,
    required AuthProvider? authProvider,
  }) async {
    String cpfLogado =
        pdvProvider?.cpfAtual ?? authProvider?.contaAtual?.cpf ?? authProvider?.cpf ?? '';
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
      nomeUsuario = conta?.nome ?? authProvider?.contaAtual?.nome;
      apelidoUsuario = conta?.apelido ?? authProvider?.contaAtual?.apelido;
    }

    return DadosUsuarioConexao(
      cpf: cpfLogado,
      nome: nomeUsuario,
      apelido: apelidoUsuario,
    );
  }

  /// Abre o WebSocket, envia identificação nominal, inicia heartbeat e escuta eventos.
  Future<void> conectarWebSocket({
    required String ipServidor,
    required int portaServidor,
    required String nomeDispositivo,
    required DadosUsuarioConexao usuario,
    required ValueNotifier<bool> estaConectado,
    required Future<void> Function(dynamic msg) onMensagem,
    required void Function() onDesconectar,
  }) async {
    final wsUrl = ResolvedorUrlRede.montarUrlWs(
      hostOuIp: ipServidor,
      porta: portaServidor,
      caminho: '/api/ws',
    );
    final wsTimeout = Duration(
      seconds: ResolvedorUrlRede.ehHostNuvem(ipServidor) ? 12 : 4,
    );
    _ws = await WebSocket.connect(wsUrl).timeout(wsTimeout);

    estaConectado.value = true;
    debugPrint('[ClienteRedeLocal] Conectado ao servidor via WebSocket em $wsUrl');

    await GerenciadorDispositivoLocal.salvarUltimoBalcao(ipServidor, portaServidor);
    if (ResolvedorUrlRede.ehHostNuvem(ipServidor)) {
      await GerenciadorDispositivoLocal.salvarServidorExterno(ipServidor);
    }

    _ws!.add(
      jsonEncode({
        'tipo': 'identificacao',
        'nomeDispositivo': nomeDispositivo,
        'cpf': usuario.cpf,
        'nomeUsuario': usuario.nome,
        'apelido': usuario.apelido,
        'versaoApp': AtualizacaoService.versaoAtual,
        'buildApp': AtualizacaoService.buildAtual,
      }),
    );

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
      onMensagem,
      onDone: () {
        debugPrint('[ClienteRedeLocal] WebSocket onDone recebido.');
        if (_ws == socketInstancia) {
          onDesconectar();
        } else {
          debugPrint(
            '[ClienteRedeLocal] onDone de conexão anterior/substituída descartado.',
          );
        }
      },
      onError: (err) {
        debugPrint('[ClienteRedeLocal] WebSocket onError recebido: $err');
        if (_ws == socketInstancia) {
          onDesconectar();
        }
      },
    );
  }

  /// Trata desconexão inesperada do WebSocket e agenda tentativa de reconexão automática.
  void tratarDesconexao({
    required ValueNotifier<bool> estaConectado,
    required ValueNotifier<List<TerminalConectadoInfo>> presencasAtivas,
    required String? ipServidor,
    required int? portaServidor,
    required bool Function() podeReconectar,
    required void Function() onReconectar,
  }) {
    debugPrint('[ClienteRedeLocal] _aoDesconectar invocado.');
    estaConectado.value = false;
    presencasAtivas.value = [];
    _ws = null;
    _timerPing?.cancel();
    RelogioRedeService.instancia.desmarcarSincronizado();

    if (!_usuarioDesconectouManualmente && ipServidor != null && portaServidor != null) {
      _timerReconexao?.cancel();
      _timerReconexao = Timer(const Duration(seconds: 4), () {
        if (podeReconectar()) {
          debugPrint(
            '[ClienteRedeLocal] Reconectando automaticamente ao balcão ($ipServidor:$portaServidor)...',
          );
          onReconectar();
        }
      });
    }
  }

  /// Encerra timers e fecha o WebSocket ativo.
  Future<void> fecharConexao({bool manual = false}) async {
    if (manual) {
      _usuarioDesconectouManualmente = true;
    }
    _timerReconexao?.cancel();
    _timerReconexao = null;
    _timerPing?.cancel();
    _timerPing = null;

    final wsAntigo = _ws;
    _ws = null;
    try {
      await wsAntigo?.close();
    } catch (_) {}
  }

  /// Tenta reconectar automaticamente usando descoberta local, último balcão ou servidor remoto.
  Future<void> tentarAutoConectar({
    required PdvProvider pdv,
    required AuthProvider? auth,
    required bool Function() conectado,
    required bool Function() conectando,
    required List<DispositivoLojaInfo> Function() obterLojasEncontradas,
    required Future<void> Function() iniciarDescoberta,
    required Future<bool> Function({
      required String ip,
      required int porta,
      required PdvProvider pdv,
      AuthProvider? auth,
    }) conectar,
  }) async {
    if (ServidorRedeLocal().ativo) return;
    if (conectado() || conectando()) return;

    await iniciarDescoberta();

    // 1. Prioridade máxima: servidores descobertos no Wi-Fi local (menor latência)
    final lojas = obterLojasEncontradas();
    if (!conectado() && !conectando() && lojas.isNotEmpty) {
      final primeiro = lojas.first;
      final ok = await conectar(
        ip: primeiro.ip,
        porta: primeiro.porta,
        pdv: pdv,
        auth: auth,
      );
      if (ok) return;
    }

    // 2. Tenta o último balcão salvo (LAN ou nuvem)
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

    // 3. Fallback remoto (HTTPS/WSS) para acesso fora do Wi-Fi local
    if (!conectado() && !conectando()) {
      final servidorRemoto = await GerenciadorDispositivoLocal.obterServidorExterno();
      if (servidorRemoto != null && servidorRemoto.isNotEmpty) {
        await conectar(
          ip: servidorRemoto,
          porta: 443,
          pdv: pdv,
          auth: auth,
        );
      }
    }
  }

  /// Atualiza ativamente a identificação do terminal móvel no balcão.
  Future<void> atualizarIdentidadeUsuario({
    required bool conectado,
    required String nomeDispositivo,
    required PdvProvider? pdvProvider,
    required AuthProvider? authProvider,
    String? cpf,
    String? nome,
    String? apelido,
    String? foto,
  }) async {
    final cpfFinal = cpf ??
        pdvProvider?.cpfAtual ??
        authProvider?.contaAtual?.cpf ??
        authProvider?.cpf ??
        '';
    String? nomeFinal = nome ?? authProvider?.contaAtual?.nome;
    String? apelidoFinal = apelido ?? authProvider?.contaAtual?.apelido;
    String? fotoFinal = foto ?? authProvider?.contaAtual?.foto;

    if (cpfFinal.isNotEmpty && (nomeFinal == null || nomeFinal.isEmpty)) {
      final conta = await ContasNousService.buscarPorCpf(cpfFinal);
      nomeFinal = conta?.nome;
      apelidoFinal = conta?.apelido;
      fotoFinal = conta?.foto;
    }

    if (_ws != null && conectado) {
      try {
        _ws!.add(
          jsonEncode({
            'tipo': 'identificacao',
            'nomeDispositivo': nomeDispositivo,
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

  /// Notifica o servidor do balcão que o usuário deslogou deste terminal.
  void notificarLogout({
    required bool estaConectado,
    required String nomeDispositivo,
  }) {
    if (_ws != null && estaConectado) {
      try {
        _ws!.add(
          jsonEncode({
            'tipo': 'logout',
            'nomeDispositivo': nomeDispositivo,
          }),
        );
        debugPrint('[ClienteRedeLocal] Notificação de logout enviada ao balcão.');
      } catch (_) {}
    }
  }

  /// Envia payload genérico JSON pelo WebSocket ativo para o servidor balcão.
  void enviarMensagemRaw({
    required bool estaConectado,
    required Map<String, dynamic> payload,
  }) {
    if (_ws != null && estaConectado) {
      try {
        _ws!.add(jsonEncode(payload));
      } catch (e) {
        debugPrint('[ClienteRedeLocal] Erro ao enviar mensagem raw via WebSocket: $e');
      }
    }
  }
}
