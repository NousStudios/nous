import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nous/src/core/services/atualizacao_service.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/fornecedor.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pagamento_funcionario.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/referencia_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/dados_locais_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:path/path.dart' as p;

/// Informações de um servidor de loja anunciado na rede Wi-Fi local.
class DispositivoLojaInfo {
  final String lojaId;
  final String lojaNome;
  final String ip;
  final int porta;
  final DateTime vistoEm;

  const DispositivoLojaInfo({
    required this.lojaId,
    required this.lojaNome,
    required this.ip,
    required this.porta,
    required this.vistoEm,
  });

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
  bool _sincronizandoPerfisLojas = false;
  Timer? _timerDebounceEnvioLoja;
  final Map<String, String> _mapaUploadsRealizados = {};

  bool get conectado => _ws != null && estaConectado.value;
  String? get enderecoServidor =>
      _ipServidor != null && _portaServidor != null ? '$_ipServidor:$_portaServidor' : null;
  Loja? get lojaSincronizada => _lojaSincronizada;
  String get nomeDispositivo => _nomeDispositivo;

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

  /// Inicia escuta UDP para encontrar servidores de lojas transmitindo no Wi-Fi.
  Future<void> iniciarDescoberta() async {
    pararDescoberta();
    lojasEncontradas.value = [];

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
  }

  void pararDescoberta() {
    try {
      _socketDescoberta?.close();
    } catch (_) {}
    _socketDescoberta = null;
  }

  void _processarDatagramaDescoberta(Datagram datagram) {
    try {
      final texto = utf8.decode(datagram.data);
      final json = jsonDecode(texto) as Map<String, dynamic>;

      if (json['assinatura'] == 'nous_loja_anuncio') {
        final info = DispositivoLojaInfo(
          lojaId: json['lojaId'] as String,
          lojaNome: json['lojaNome'] as String,
          ip: json['ip'] as String,
          porta: json['porta'] as int,
          vistoEm: DateTime.now(),
        );

        final lista = List<DispositivoLojaInfo>.from(lojasEncontradas.value);
        final idx = lista.indexWhere(
          (d) => d.lojaId == info.lojaId && d.ip == info.ip && d.porta == info.porta,
        );

        if (idx != -1) {
          lista[idx] = info;
        } else {
          lista.add(info);
        }

        // Remove servidores que não respondem há mais de 10 segundos
        final agora = DateTime.now();
        lista.removeWhere((d) => agora.difference(d.vistoEm).inSeconds > 10);

        lojasEncontradas.value = lista;
      }
    } catch (_) {}
  }

  /// Conecta ao servidor no IP e porta especificados (manual ou descoberto).
  Future<bool> conectar({
    required String ip,
    required int porta,
    required PdvProvider pdv,
    AuthProvider? auth,
  }) async {
    await desconectar();

    _ipServidor = ip.trim();
    _portaServidor = porta;
    _pdvProvider = pdv;
    if (auth != null) _authProvider = auth;

    try {
      ultimoErro.value = null;
      await obterNomeDispositivo();

      final cpfLogado =
          _pdvProvider?.cpfAtual ?? _authProvider?.contaAtual?.cpf ?? _authProvider?.cpf ?? '';
      String? nomeUsuario;
      String? apelidoUsuario;
      if (cpfLogado.isNotEmpty) {
        final conta = await ContasNousService.buscarPorCpf(cpfLogado);
        nomeUsuario = conta?.nome ?? _authProvider?.contaAtual?.nome;
        apelidoUsuario = conta?.apelido ?? _authProvider?.contaAtual?.apelido;
      }

      // 1. Baixa o snapshot atualizado da Loja via REST, passando os dados de identidade para auto-associação
      // Timeout aumentado para 35 segundos para dar tempo ao operador balcão de autorizar a conexão
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 35);
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
      final request = await client.getUrl(uriLoja).timeout(const Duration(seconds: 35));
      final response = await request.close().timeout(const Duration(seconds: 35));

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
      final dados = jsonDecode(body) as Map<String, dynamic>;

      if (dados['sucesso'] == true && dados['loja'] != null) {
        final lojaBruta = Loja.fromJson(dados['loja'] as Map<String, dynamic>);
        final imagensAusentes = (dados['imagensAusentes'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();

        // Realiza reconciliação mútua: preenche lacunas do servidor e baixa novidades locais
        _lojaSincronizada = await _reconciliarLojaMutua(lojaBruta, imagensAusentes);

        // Atualiza a loja no provedor local e no SQLite para visualização completa com imagens
        await _pdvProvider!.adicionarOuAtualizarLoja(_lojaSincronizada!);
        await _vincularLojaSeNecessario(_lojaSincronizada!);

        if (dados['fotosUsuariosAusentes'] != null) {
          final ausentes = (dados['fotosUsuariosAusentes'] as List<dynamic>)
              .map((e) => e.toString())
              .toList();
          _curarFotosUsuariosAusentesNoServidor(ausentes);
        }
      }

      // 2. Conecta ao WebSocket para atualizações em tempo real
      final wsUrl = 'ws://$_ipServidor:$_portaServidor/api/ws';
      _ws = await WebSocket.connect(wsUrl).timeout(const Duration(seconds: 10));

      estaConectado.value = true;
      debugPrint('[ClienteRedeLocal] Conectado ao servidor via WebSocket em $wsUrl');

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

      _ws!.listen(
        _processarMensagemWs,
        onDone: _aoDesconectar,
        onError: (_) => _aoDesconectar(),
      );

      // Sincroniza a identidade da conta ativa (foto e dados do usuário) a partir do balcão
      sincronizarIdentidadeUsuario();

      // Reconcilia todas as contas conhecidas deste aparelho com o balcão (autocura mútua)
      _reconciliarTodasContasLocaisComServidor();

      // Sincroniza pan-dispositivo todas as lojas e referências associadas ao CPF deste cidadão
      sincronizarPerfisLojasComServidor();

      // Checa se o balcão possui uma versão/APK disponível para este aparelho
      verificarAtualizacaoLocal();

      return true;
    } catch (e) {
      debugPrint('[ClienteRedeLocal] Erro ao conectar ao servidor: $e');
      estaConectado.value = false;
      if (ultimoErro.value == null) {
        ultimoErro.value = 'Não foi possível conectar ao balcão.';
      }
      return false;
    }
  }

  Future<void> _processarMensagemWs(dynamic msg) async {
    try {
      final dados = jsonDecode(msg as String) as Map<String, dynamic>;
      final tipo = dados['tipo'];

      if (tipo == 'pong') {
        return;
      }

      if (tipo == 'dados_iniciais' || tipo == 'loja_atualizada') {
        if (dados['loja'] != null && _pdvProvider != null) {
          _aplicandoAtualizacaoRemota = true;
          try {
            final lojaBruta = Loja.fromJson(dados['loja'] as Map<String, dynamic>);
            final lojaNova = await _sincronizarImagensRemotas(lojaBruta);
            _lojaSincronizada = lojaNova;
            await _pdvProvider!.adicionarOuAtualizarLoja(lojaNova);
            await _vincularLojaSeNecessario(lojaNova);
          } finally {
            _aplicandoAtualizacaoRemota = false;
          }
        }
        if (dados['presencas'] != null) {
          final lista = dados['presencas'] as List<dynamic>? ?? [];
          presencasAtivas.value = lista
              .map((e) => TerminalConectadoInfo.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        if (dados['fotosUsuariosAusentes'] != null) {
          final ausentes = (dados['fotosUsuariosAusentes'] as List<dynamic>)
              .map((e) => e.toString())
              .toList();
          _curarFotosUsuariosAusentesNoServidor(ausentes);
        }
      } else if (tipo == 'presencas_atualizadas') {
        final lista = dados['presencas'] as List<dynamic>? ?? [];
        presencasAtivas.value = lista
            .map((e) => TerminalConectadoInfo.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (tipo == 'pedido_adicionado') {
        if (dados['pedido'] != null && _pdvProvider != null && _lojaSincronizada != null) {
          final pedido = PedidoLoja.fromJson(dados['pedido'] as Map<String, dynamic>);
          final lojaAtual = _pdvProvider!.buscarPorId(_lojaSincronizada!.id);
          if (lojaAtual != null) {
            final pedidos = List<PedidoLoja>.from(lojaAtual.pedidosLoja);
            if (!pedidos.any((p) => p.id == pedido.id)) {
              pedidos.insert(0, pedido);
              _pdvProvider!.atualizarListasLoja(lojaAtual.id, pedidos: pedidos);
            }
          }
        }
      } else if (tipo == 'estoque_atualizado') {
        if (dados['movimento'] != null && _pdvProvider != null && _lojaSincronizada != null) {
          final mov = MovimentoEstoque.fromJson(dados['movimento'] as Map<String, dynamic>);
          final lojaAtual = _pdvProvider!.buscarPorId(_lojaSincronizada!.id);
          if (lojaAtual != null) {
            final movs = List<MovimentoEstoque>.from(lojaAtual.movimentosEstoque);
            if (!movs.any((m) => m.id == mov.id)) {
              movs.insert(0, mov);
              _pdvProvider!.atualizarListasLoja(lojaAtual.id, movimentosEstoque: movs);
            }
          }
        }
      } else if (tipo == 'mesa_atualizada') {
        if (dados['mesa'] != null && _pdvProvider != null && _lojaSincronizada != null) {
          final mesa = MesaLoja.fromJson(dados['mesa'] as Map<String, dynamic>);
          final lojaAtual = _pdvProvider!.buscarPorId(_lojaSincronizada!.id);
          if (lojaAtual != null) {
            final mesas = List<MesaLoja>.from(lojaAtual.mesas);
            final idx = mesas.indexWhere((m) => m.id == mesa.id);
            if (idx != -1) {
              mesas[idx] = mesa;
            } else {
              mesas.add(mesa);
            }
            _pdvProvider!.atualizarListasLoja(lojaAtual.id, mesas: mesas);
          }
        }
      } else if (tipo == 'usuario_atualizado') {
        if (dados['usuario'] != null) {
          try {
            var usuarioRemoto = UsuarioNous.fromJson(
                dados['usuario'] as Map<String, dynamic>);
            if (usuarioRemoto.foto.isNotEmpty) {
              final novaFotoLocal =
                  await baixarImagemRemota(usuarioRemoto.foto);
              usuarioRemoto = usuarioRemoto.copyWith(foto: novaFotoLocal);
            }

            // Preserva foto local se tínhamos foto válida e o remoto veio sem foto
            final local =
                await ContasNousService.buscarPorCpf(usuarioRemoto.cpf);
            if (local != null &&
                local.foto.isNotEmpty &&
                ImagemService.existe(local.foto) &&
                (usuarioRemoto.foto.isEmpty ||
                    !ImagemService.existe(usuarioRemoto.foto))) {
              usuarioRemoto = usuarioRemoto.copyWith(foto: local.foto);
            }

            await ContasNousService.salvar(usuarioRemoto);
            _pdvProvider?.sincronizarFotoUsuarioEmClientes(
                usuarioRemoto.cpf, usuarioRemoto.foto);

            final cpfAtivo = _pdvProvider?.cpfAtual ??
                _authProvider?.contaAtual?.cpf ??
                _authProvider?.cpf;
            if (cpfAtivo != null &&
                cpfAtivo.replaceAll(RegExp(r'\D'), '') ==
                    usuarioRemoto.cpf.replaceAll(RegExp(r'\D'), '')) {
              await _authProvider?.recarregarConta();
            }
            debugPrint(
              '[ClienteRedeLocal] Identidade do usuário ${usuarioRemoto.cpf} (${usuarioRemoto.nome}) atualizada via WebSocket (Foto: ${usuarioRemoto.foto})',
            );
          } catch (e) {
            debugPrint(
                '[ClienteRedeLocal] Erro ao processar usuario_atualizado via WebSocket: $e');
          }
        }
      } else if (tipo == 'perfis_usuario_atualizados') {
        final cpfAtualizado =
            (dados['cpf'] as String? ?? '').replaceAll(RegExp(r'\D'), '');
        final cpfAtivo = (_pdvProvider?.cpfAtual ??
                _authProvider?.contaAtual?.cpf ??
                _authProvider?.cpf ??
                '')
            .replaceAll(RegExp(r'\D'), '');
        if (cpfAtualizado.isNotEmpty && cpfAtualizado == cpfAtivo) {
          debugPrint(
            '[ClienteRedeLocal] Perfis do usuário $cpfAtualizado atualizados via WebSocket. Sincronizando perfis...',
          );
          await sincronizarPerfisLojasComServidor();
        }
      }
    } catch (e) {
      debugPrint('[ClienteRedeLocal] Erro ao processar mensagem WebSocket: $e');
    }
  }

  void _aoDesconectar() {
    estaConectado.value = false;
    presencasAtivas.value = [];
    _ws = null;
    _timerPing?.cancel();

    // Agenda tentativa de reconexão se o usuário não desconectou explicitamente
    if (_ipServidor != null && _portaServidor != null) {
      _timerReconexao?.cancel();
      _timerReconexao = Timer(const Duration(seconds: 4), () {
        if (!conectado && _ipServidor != null && _portaServidor != null && _pdvProvider != null) {
          conectar(ip: _ipServidor!, porta: _portaServidor!, pdv: _pdvProvider!);
        }
      });
    }
  }

  /// Vincula a loja sincronizada aos perfis locais do usuário se ele for membro ou dono
  Future<void> _vincularLojaSeNecessario(Loja loja) async {
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

      if (ehMembro) {
        // 1. Salva a loja completa no cofre do dono original no banco SQLite local deste aparelho com proteção de imagens
        await LojasService.salvarLojaIndividual(loja);

        // 2. Garante a referência no cofre deste CPF participante
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

          // 3. Recarrega as lojas no PdvProvider apenas na primeira vinculação para aparecer em lojasQueParticipo
          await _pdvProvider!.entrarComCpf(cpf);
        }
      }
    }
  }

  /// Envia um novo pedido realizado no celular para o servidor central da loja
  Future<bool> enviarPedido(PedidoLoja pedido) async {
    if (_ipServidor == null || _portaServidor == null) return false;
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final request = await client.postUrl(
        Uri.parse('http://$_ipServidor:$_portaServidor/api/pedido'),
      );
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(pedido.toJson()));
      final response = await request.close();
      return response.statusCode == HttpStatus.ok;
    } catch (e) {
      debugPrint('[ClienteRedeLocal] Erro ao enviar pedido ao servidor: $e');
      return false;
    }
  }

  /// Envia uma movimentação de estoque realizada no celular para o servidor
  Future<bool> enviarMovimentoEstoque(MovimentoEstoque mov) async {
    if (_ipServidor == null || _portaServidor == null) return false;
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final request = await client.postUrl(
        Uri.parse('http://$_ipServidor:$_portaServidor/api/movimento_estoque'),
      );
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(mov.toJson()));
      final response = await request.close();
      return response.statusCode == HttpStatus.ok;
    } catch (e) {
      debugPrint('[ClienteRedeLocal] Erro ao enviar estoque ao servidor: $e');
      return false;
    }
  }

  /// Envia atualização de mesa para o servidor central
  Future<bool> enviarMesa(MesaLoja mesa) async {
    if (_ipServidor == null || _portaServidor == null) return false;
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final request = await client.postUrl(
        Uri.parse('http://$_ipServidor:$_portaServidor/api/mesa'),
      );
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(mesa.toJson()));
      final response = await request.close();
      return response.statusCode == HttpStatus.ok;
    } catch (e) {
      debugPrint('[ClienteRedeLocal] Erro ao enviar mesa ao servidor: $e');
      return false;
    }
  }

  Future<String> _enviarUploadImagemParaServidor(String caminhoLocal) async {
    if (_ipServidor == null || _portaServidor == null) return caminhoLocal;
    final limpo = caminhoLocal.trim();
    if (limpo.isEmpty) return '';

    for (final entry in _mapaUploadsRealizados.entries) {
      if (entry.value == limpo) {
        return entry.key;
      }
    }

    final resolvido =
        ImagemService.resolverCaminhoExistente(limpo) ?? limpo;
    final arquivo = File(resolvido);
    if (!arquivo.existsSync() || arquivo.lengthSync() == 0) return limpo;

    try {
      final nome = p.basename(limpo);
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
      final req = await client.postUrl(
        Uri.parse(
          'http://$_ipServidor:$_portaServidor/api/upload_imagem?nome=${Uri.encodeQueryComponent(nome)}',
        ),
      );
      req.headers.contentType = ContentType.binary;
      await req.addStream(arquivo.openRead());
      final resp = await req.close();
      if (resp.statusCode == HttpStatus.ok) {
        final body = await utf8.decoder.bind(resp).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final caminhoServidor = json['caminho'] as String?;
        if (caminhoServidor != null && caminhoServidor.isNotEmpty) {
          _mapaUploadsRealizados[caminhoServidor] = limpo;
          debugPrint(
            '[ClienteRedeLocal] Imagem enviada com sucesso ao servidor: $caminhoServidor',
          );
          return caminhoServidor;
        }
      }
    } catch (e) {
      debugPrint('[ClienteRedeLocal] Erro ao enviar imagem "$limpo" para o servidor: $e');
    }
    return limpo;
  }

  Future<String> _enviarUploadAnexoParaServidor(
    String caminhoLocal, {
    String subpasta = 'musicas',
  }) async {
    if (_ipServidor == null || _portaServidor == null) return caminhoLocal;
    final limpo = caminhoLocal.trim();
    if (limpo.isEmpty) return '';

    for (final entry in _mapaUploadsRealizados.entries) {
      if (entry.value == limpo) {
        return entry.key;
      }
    }

    final resolvido = ImagemService.resolverCaminhoExistente(limpo) ?? limpo;
    final arquivo = File(resolvido);
    if (!arquivo.existsSync() || arquivo.lengthSync() == 0) return limpo;

    try {
      final nome = p.basename(limpo);
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
      final req = await client.postUrl(
        Uri.parse(
          'http://$_ipServidor:$_portaServidor/api/upload_anexo?nome=${Uri.encodeQueryComponent(nome)}&pasta=${Uri.encodeQueryComponent(subpasta)}',
        ),
      );
      req.headers.contentType = ContentType.binary;
      await req.addStream(arquivo.openRead());
      final resp = await req.close();
      if (resp.statusCode == HttpStatus.ok) {
        final body = await utf8.decoder.bind(resp).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final caminhoServidor = json['caminho'] as String?;
        if (caminhoServidor != null && caminhoServidor.isNotEmpty) {
          _mapaUploadsRealizados[caminhoServidor] = limpo;
          debugPrint(
            '[ClienteRedeLocal] Anexo ($subpasta) enviado com sucesso ao servidor: $caminhoServidor',
          );
          return caminhoServidor;
        }
      }
    } catch (e) {
      debugPrint('[ClienteRedeLocal] Erro ao enviar anexo "$limpo" para o servidor: $e');
    }
    return limpo;
  }

  Future<String> _garantirUploadParaServidor(String caminhoLocal) async {
    return await _enviarUploadImagemParaServidor(caminhoLocal);
  }

  Future<bool> _enviarLojaCuradaParaServidor(Loja lojaCurada) async {
    if (_ipServidor == null || _portaServidor == null) return false;
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
      final request = await client.postUrl(
        Uri.parse('http://$_ipServidor:$_portaServidor/api/loja/atualizar'),
      );
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(lojaCurada.toJson()));
      final response = await request.close();
      final ok = response.statusCode == HttpStatus.ok;
      debugPrint(
        '[ClienteRedeLocal] Cura da loja enviada com sucesso ao servidor: $ok (HTTP ${response.statusCode})',
      );
      return ok;
    } catch (e) {
      debugPrint('[ClienteRedeLocal] Erro ao enviar cura da loja ao servidor: $e');
      return false;
    }
  }

  /// Envia a atualização completa da loja realizada neste terminal móvel para o servidor central (balcão)
  Future<bool> enviarLojaAtualizada(Loja loja, {bool imediato = false}) async {
    if (_ipServidor == null || _portaServidor == null || !conectado) return false;
    if (_aplicandoAtualizacaoRemota) return false;

    _timerDebounceEnvioLoja?.cancel();

    Future<bool> executarEnvio() async {
      try {
        Loja lojaParaEnvio = loja;

        if (lojaParaEnvio.logo.isNotEmpty) {
          final logoNoServidor = await _garantirUploadParaServidor(lojaParaEnvio.logo);
          if (logoNoServidor != lojaParaEnvio.logo) {
            lojaParaEnvio = lojaParaEnvio.copyWith(logo: logoNoServidor);
          }
        }

        final categoriasAjustadas = <CategoriaLoja>[];
        for (final cat in lojaParaEnvio.categoriasLoja) {
          if (cat.foto.isNotEmpty) {
            final fotoNoServidor = await _garantirUploadParaServidor(cat.foto);
            categoriasAjustadas.add(cat.copyWith(foto: fotoNoServidor));
          } else {
            categoriasAjustadas.add(cat);
          }
        }
        lojaParaEnvio = lojaParaEnvio.copyWith(categoriasLoja: categoriasAjustadas);

        final itensAjustados = <ItemLoja>[];
        for (final it in lojaParaEnvio.itensLoja) {
          final imgsAjustadas = <String>[];
          for (final img in it.imagens) {
            if (img.isNotEmpty) {
              imgsAjustadas.add(await _garantirUploadParaServidor(img));
            } else {
              imgsAjustadas.add(img);
            }
          }
          itensAjustados.add(it.copyWith(imagens: imgsAjustadas));
        }
        lojaParaEnvio = lojaParaEnvio.copyWith(itensLoja: itensAjustados);

        final clientesAjustados = <Cliente>[];
        for (final c in lojaParaEnvio.clientesLoja) {
          if (c.foto.isNotEmpty) {
            final fotoServidor = await _garantirUploadParaServidor(c.foto);
            clientesAjustados.add(c.copyWith(foto: fotoServidor));
          } else {
            clientesAjustados.add(c);
          }
        }
        lojaParaEnvio = lojaParaEnvio.copyWith(clientesLoja: clientesAjustados);

        final fornecedoresAjustados = <Fornecedor>[];
        for (final f in lojaParaEnvio.fornecedoresLoja) {
          if (f.foto.isNotEmpty) {
            final fotoServidor = await _garantirUploadParaServidor(f.foto);
            fornecedoresAjustados.add(f.copyWith(foto: fotoServidor));
          } else {
            fornecedoresAjustados.add(f);
          }
        }
        lojaParaEnvio = lojaParaEnvio.copyWith(fornecedoresLoja: fornecedoresAjustados);

        final galeriaAjustada = <String>[];
        for (final g in lojaParaEnvio.galeria) {
          if (g.isNotEmpty) {
            galeriaAjustada.add(await _garantirUploadParaServidor(g));
          } else {
            galeriaAjustada.add(g);
          }
        }
        lojaParaEnvio = lojaParaEnvio.copyWith(galeria: galeriaAjustada);

        final musicasAjustadas = <String>[];
        for (final m in lojaParaEnvio.musicas) {
          if (m.isNotEmpty) {
            musicasAjustadas.add(
              await _enviarUploadAnexoParaServidor(m, subpasta: 'musicas'),
            );
          } else {
            musicasAjustadas.add(m);
          }
        }
        lojaParaEnvio = lojaParaEnvio.copyWith(musicas: musicasAjustadas);

        final audiosAjustados = <String>[];
        for (final a in lojaParaEnvio.arquivosAudio) {
          if (a.isNotEmpty) {
            audiosAjustados.add(
              await _enviarUploadAnexoParaServidor(a, subpasta: 'arquivosAudio'),
            );
          } else {
            audiosAjustados.add(a);
          }
        }
        lojaParaEnvio = lojaParaEnvio.copyWith(arquivosAudio: audiosAjustados);

        final videosAjustados = <String>[];
        for (final v in lojaParaEnvio.videos) {
          if (v.isNotEmpty) {
            videosAjustados.add(
              await _enviarUploadAnexoParaServidor(v, subpasta: 'videos'),
            );
          } else {
            videosAjustados.add(v);
          }
        }
        lojaParaEnvio = lojaParaEnvio.copyWith(videos: videosAjustados);

        final arquivosAjustados = <String>[];
        for (final arq in lojaParaEnvio.arquivos) {
          if (arq.isNotEmpty) {
            arquivosAjustados.add(
              await _enviarUploadAnexoParaServidor(arq, subpasta: 'arquivos'),
            );
          } else {
            arquivosAjustados.add(arq);
          }
        }
        lojaParaEnvio = lojaParaEnvio.copyWith(arquivos: arquivosAjustados);

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

  /// Desconecta do servidor
  Future<void> desconectar() async {
    _timerReconexao?.cancel();
    _timerReconexao = null;
    _timerPing?.cancel();
    _timerPing = null;

    try {
      await _ws?.close();
    } catch (_) {}
    _ws = null;

    _ipServidor = null;
    _portaServidor = null;
    estaConectado.value = false;
    presencasAtivas.value = [];
  }

  /// Realiza a reconciliação mútua e bidirecional de dados e imagens entre o Servidor e este Cliente
  Future<Loja> _reconciliarLojaMutua(
    Loja lojaRemota,
    List<String> imagensAusentesNoServidor,
  ) async {
    // 1. Carrega o estado da loja gravado localmente neste dispositivo
    Loja? lojaLocal = _pdvProvider?.buscarPorId(lojaRemota.id);
    if (lojaLocal == null) {
      try {
        lojaLocal = await LojasService.carregarLojaPorId(lojaRemota.id);
      } catch (e) {
        debugPrint('[ClienteRedeLocal] Erro ao carregar loja local para reconciliação: $e');
      }
    }

    // Se este dispositivo nunca teve dados prévios desta loja, apenas baixa do servidor normalmente
    if (lojaLocal == null) {
      return await _sincronizarImagensRemotas(lojaRemota);
    }

    debugPrint(
      '[ClienteRedeLocal] Iniciando reconciliação mútua. Servidor reportou ${imagensAusentesNoServidor.length} lacunas de imagem.',
    );

    var houveCuraNoServidor = false;
    Loja lojaParaServidor = lojaRemota;

    // A. Logo da Loja
    final precisaLogoNoServidor = imagensAusentesNoServidor.contains('logo') ||
        lojaRemota.logo.trim().isEmpty;
    if (precisaLogoNoServidor && lojaLocal.logo.trim().isNotEmpty) {
      final logoLocalResolvida = ImagemService.resolverCaminhoExistente(lojaLocal.logo);
      if (logoLocalResolvida != null && File(logoLocalResolvida).existsSync()) {
        final logoNoServidor = await _enviarUploadImagemParaServidor(logoLocalResolvida);
        if (logoNoServidor.isNotEmpty && logoNoServidor != logoLocalResolvida) {
          lojaParaServidor = lojaParaServidor.copyWith(logo: logoNoServidor);
          houveCuraNoServidor = true;
          debugPrint('[ClienteRedeLocal] Logo restaurada no servidor: $logoNoServidor');
        }
      }
    }

    // B. Categorias da Loja
    final novasCategoriasServidor = <CategoriaLoja>[];
    for (final catRemota in lojaRemota.categoriasLoja) {
      final precisaFoto = imagensAusentesNoServidor.contains('categoria_${catRemota.id}') ||
          catRemota.foto.trim().isEmpty;
      if (precisaFoto) {
        CategoriaLoja? catLocal;
        for (final cl in lojaLocal.categoriasLoja) {
          if (cl.id == catRemota.id || cl.nome.trim().toLowerCase() == catRemota.nome.trim().toLowerCase()) {
            catLocal = cl;
            break;
          }
        }
        if (catLocal != null && catLocal.foto.trim().isNotEmpty) {
          final fotoLocalResolvida = ImagemService.resolverCaminhoExistente(catLocal.foto);
          if (fotoLocalResolvida != null && File(fotoLocalResolvida).existsSync()) {
            final fotoNoServidor = await _enviarUploadImagemParaServidor(fotoLocalResolvida);
            if (fotoNoServidor.isNotEmpty && fotoNoServidor != fotoLocalResolvida) {
              novasCategoriasServidor.add(catRemota.copyWith(foto: fotoNoServidor));
              houveCuraNoServidor = true;
              debugPrint('[ClienteRedeLocal] Foto da categoria "${catRemota.nome}" restaurada no servidor: $fotoNoServidor');
              continue;
            }
          }
        }
      }
      novasCategoriasServidor.add(catRemota);
    }

    for (final catLocal in lojaLocal.categoriasLoja) {
      final jaExiste = novasCategoriasServidor.any(
        (c) => c.id == catLocal.id || c.nome.trim().toLowerCase() == catLocal.nome.trim().toLowerCase(),
      );
      if (!jaExiste) {
        String fotoServidor = '';
        if (catLocal.foto.trim().isNotEmpty) {
          final fotoResolvida = ImagemService.resolverCaminhoExistente(catLocal.foto);
          if (fotoResolvida != null && File(fotoResolvida).existsSync()) {
            fotoServidor = await _enviarUploadImagemParaServidor(fotoResolvida);
          }
        }
        novasCategoriasServidor.add(catLocal.copyWith(foto: fotoServidor));
        houveCuraNoServidor = true;
        debugPrint('[ClienteRedeLocal] Categoria "${catLocal.nome}" restaurada no servidor');
      }
    }
    lojaParaServidor = lojaParaServidor.copyWith(categoriasLoja: novasCategoriasServidor);

    // C. Itens da Loja
    final novosItensServidor = <ItemLoja>[];
    for (final itemRemoto in lojaRemota.itensLoja) {
      final precisaImagens = imagensAusentesNoServidor.contains('item_${itemRemoto.id}') ||
          itemRemoto.imagens.isEmpty;
      if (precisaImagens) {
        ItemLoja? itemLocal;
        for (final il in lojaLocal.itensLoja) {
          if (il.id == itemRemoto.id || il.nome.trim().toLowerCase() == itemRemoto.nome.trim().toLowerCase()) {
            itemLocal = il;
            break;
          }
        }
        if (itemLocal != null && itemLocal.imagens.isNotEmpty) {
          final novasImagensNoServidor = <String>[];
          for (final img in itemLocal.imagens) {
            final imgResolvida = ImagemService.resolverCaminhoExistente(img);
            if (imgResolvida != null && File(imgResolvida).existsSync()) {
              final imgServidor = await _enviarUploadImagemParaServidor(imgResolvida);
              if (imgServidor.isNotEmpty && imgServidor != imgResolvida) {
                novasImagensNoServidor.add(imgServidor);
              }
            }
          }
          if (novasImagensNoServidor.isNotEmpty) {
            novosItensServidor.add(itemRemoto.copyWith(imagens: novasImagensNoServidor));
            houveCuraNoServidor = true;
            debugPrint('[ClienteRedeLocal] Imagens do produto "${itemRemoto.nome}" restauradas no servidor (${novasImagensNoServidor.length})');
            continue;
          }
        }
      }
      novosItensServidor.add(itemRemoto);
    }

    for (final itemLocal in lojaLocal.itensLoja) {
      final jaExiste = novosItensServidor.any(
        (i) => i.id == itemLocal.id || i.nome.trim().toLowerCase() == itemLocal.nome.trim().toLowerCase(),
      );
      if (!jaExiste) {
        final novasImagensServidor = <String>[];
        for (final img in itemLocal.imagens) {
          final imgResolvida = ImagemService.resolverCaminhoExistente(img);
          if (imgResolvida != null && File(imgResolvida).existsSync()) {
            final imgServidor = await _enviarUploadImagemParaServidor(imgResolvida);
            if (imgServidor.isNotEmpty && imgServidor != imgResolvida) {
              novasImagensServidor.add(imgServidor);
            }
          }
        }
        novosItensServidor.add(itemLocal.copyWith(imagens: novasImagensServidor));
        houveCuraNoServidor = true;
        debugPrint('[ClienteRedeLocal] Produto "${itemLocal.nome}" restaurado no servidor');
      }
    }
    lojaParaServidor = lojaParaServidor.copyWith(itensLoja: novosItensServidor);

    // D. Clientes da Loja
    final novosClientesServidor = <Cliente>[];
    for (final cliRemoto in lojaRemota.clientesLoja) {
      final precisaFoto = imagensAusentesNoServidor.contains('cliente_${cliRemoto.id}') ||
          cliRemoto.foto.trim().isEmpty;
      if (precisaFoto) {
        Cliente? cliLocal;
        for (final cl in lojaLocal.clientesLoja) {
          if (cl.id == cliRemoto.id || (cl.cnpj.isNotEmpty && cl.cnpj == cliRemoto.cnpj)) {
            cliLocal = cl;
            break;
          }
        }
        if (cliLocal != null && cliLocal.foto.trim().isNotEmpty) {
          final fotoResolvida = ImagemService.resolverCaminhoExistente(cliLocal.foto);
          if (fotoResolvida != null && File(fotoResolvida).existsSync()) {
            final fotoServidor = await _enviarUploadImagemParaServidor(fotoResolvida);
            if (fotoServidor.isNotEmpty && fotoServidor != fotoResolvida) {
              novosClientesServidor.add(cliRemoto.copyWith(foto: fotoServidor));
              houveCuraNoServidor = true;
              continue;
            }
          }
        }
      }
      novosClientesServidor.add(cliRemoto);
    }
    for (final cLocal in lojaLocal.clientesLoja) {
      if (!novosClientesServidor.any((c) => c.id == cLocal.id)) {
        novosClientesServidor.add(cLocal);
        houveCuraNoServidor = true;
      }
    }
    lojaParaServidor = lojaParaServidor.copyWith(clientesLoja: novosClientesServidor);

    // E. Fornecedores da Loja
    final novosFornecedoresServidor = <Fornecedor>[];
    for (final fornRemoto in lojaRemota.fornecedoresLoja) {
      final precisaFoto = imagensAusentesNoServidor.contains('fornecedor_${fornRemoto.id}') ||
          fornRemoto.foto.trim().isEmpty;
      if (precisaFoto) {
        Fornecedor? fornLocal;
        for (final fl in lojaLocal.fornecedoresLoja) {
          if (fl.id == fornRemoto.id || (fl.cnpj.isNotEmpty && fl.cnpj == fornRemoto.cnpj)) {
            fornLocal = fl;
            break;
          }
        }
        if (fornLocal != null && fornLocal.foto.trim().isNotEmpty) {
          final fotoResolvida = ImagemService.resolverCaminhoExistente(fornLocal.foto);
          if (fotoResolvida != null && File(fotoResolvida).existsSync()) {
            final fotoServidor = await _enviarUploadImagemParaServidor(fotoResolvida);
            if (fotoServidor.isNotEmpty && fotoServidor != fotoResolvida) {
              novosFornecedoresServidor.add(fornRemoto.copyWith(foto: fotoServidor));
              houveCuraNoServidor = true;
              continue;
            }
          }
        }
      }
      novosFornecedoresServidor.add(fornRemoto);
    }
    for (final fLocal in lojaLocal.fornecedoresLoja) {
      if (!novosFornecedoresServidor.any((f) => f.id == fLocal.id)) {
        novosFornecedoresServidor.add(fLocal);
        houveCuraNoServidor = true;
      }
    }
    lojaParaServidor = lojaParaServidor.copyWith(fornecedoresLoja: novosFornecedoresServidor);

    // F. Mesas
    final mesasMescladas = List<MesaLoja>.from(lojaParaServidor.mesas);
    for (final mLocal in lojaLocal.mesas) {
      if (!mesasMescladas.any((m) => m.id == mLocal.id)) {
        mesasMescladas.add(mLocal);
        houveCuraNoServidor = true;
      }
    }
    lojaParaServidor = lojaParaServidor.copyWith(mesas: mesasMescladas);

    // G. Histórico de Auditoria (Ações)
    final acoesMescladas = List<RegistroAcao>.from(lojaParaServidor.acoes);
    for (final aLocal in lojaLocal.acoes) {
      if (!acoesMescladas.any((a) => a.id == aLocal.id)) {
        acoesMescladas.add(aLocal);
        houveCuraNoServidor = true;
      }
    }
    lojaParaServidor = lojaParaServidor.copyWith(acoes: acoesMescladas);

    // H. Pedidos, Movimentos de Estoque e Pagamentos
    final pedidosMesclados = List<PedidoLoja>.from(lojaParaServidor.pedidosLoja);
    for (final pLocal in lojaLocal.pedidosLoja) {
      if (!pedidosMesclados.any((p) => p.id == pLocal.id)) {
        pedidosMesclados.add(pLocal);
        houveCuraNoServidor = true;
      }
    }
    final movimentosMesclados = List<MovimentoEstoque>.from(lojaParaServidor.movimentosEstoque);
    for (final mLocal in lojaLocal.movimentosEstoque) {
      if (!movimentosMesclados.any((m) => m.id == mLocal.id)) {
        movimentosMesclados.add(mLocal);
        houveCuraNoServidor = true;
      }
    }
    final pagamentosMesclados = List<PagamentoFuncionario>.from(lojaParaServidor.pagamentosFuncionarios);
    for (final pgLocal in lojaLocal.pagamentosFuncionarios) {
      if (!pagamentosMesclados.any((pg) => pg.id == pgLocal.id)) {
        pagamentosMesclados.add(pgLocal);
        houveCuraNoServidor = true;
      }
    }
    lojaParaServidor = lojaParaServidor.copyWith(
      pedidosLoja: pedidosMesclados,
      movimentosEstoque: movimentosMesclados,
      pagamentosFuncionarios: pagamentosMesclados,
    );

    // Se houve alguma cura ou restauração necessária no servidor, envia o estado curado ao balcão
    if (houveCuraNoServidor) {
      debugPrint('[ClienteRedeLocal] Enviando cura consolidada da loja ao servidor balcão...');
      await _enviarLojaCuradaParaServidor(lojaParaServidor);
    }

    // Finalmente, este cliente sincroniza e baixa todas as imagens do servidor para si mesmo
    return await _sincronizarImagensRemotas(lojaParaServidor);
  }

  /// Baixa imagens remotas do servidor que não existem no armazenamento local
  /// e regrava os caminhos locais atualizados para que fiquem 100% visíveis no celular.
  Future<Loja> _sincronizarImagensRemotas(Loja lojaRemota) async {
    if (_ipServidor == null || _portaServidor == null) return lojaRemota;

    try {
      final dirBase = await ImagemService.obterDiretorioBase();
      final pastaImagens = Directory('${dirBase.path}/imagens');
      if (!await pastaImagens.exists()) {
        await pastaImagens.create(recursive: true);
      }

      final clienteHttp = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final Map<String, String> mapaCaminhos = {};

      Future<String> resolverCaminhoImagem(String? caminhoRemoto) async {
        if (caminhoRemoto == null || caminhoRemoto.trim().isEmpty) return '';
        final caminhoLimpo = caminhoRemoto.trim();

        // Se o caminho já aponta para um arquivo existente localmente neste dispositivo, mantém
        if (File(caminhoLimpo).existsSync()) {
          return caminhoLimpo;
        }

        // Se esta imagem foi enviada deste dispositivo para o servidor, reaproveita o arquivo local original
        if (_mapaUploadsRealizados.containsKey(caminhoLimpo)) {
          final original = _mapaUploadsRealizados[caminhoLimpo]!;
          if (File(original).existsSync()) {
            return original;
          }
        }

        // Se já foi mapeado nesta execução em memória
        if (mapaCaminhos.containsKey(caminhoLimpo)) {
          return mapaCaminhos[caminhoLimpo]!;
        }

        final localExistente = ImagemService.resolverCaminhoExistente(caminhoLimpo);
        if (localExistente != null && File(localExistente).existsSync()) {
          mapaCaminhos[caminhoLimpo] = localExistente;
          return localExistente;
        }

        final ext = caminhoLimpo.split('.').last.toLowerCase();
        final extensaoFinal = ImagemService.extensoesImagem.contains(ext) ? ext : 'jpg';
        final nomeArquivoLocal = 'remota_${caminhoLimpo.hashCode.abs()}.$extensaoFinal';
        final arquivoLocal = File('${pastaImagens.path}/$nomeArquivoLocal');

        // Se a imagem já foi baixada anteriormente e está íntegra no disco, reutiliza instantaneamente
        if (arquivoLocal.existsSync() && arquivoLocal.lengthSync() > 0) {
          mapaCaminhos[caminhoLimpo] = arquivoLocal.path;
          return arquivoLocal.path;
        }

        try {
          final uri = Uri.parse(
            'http://$_ipServidor:$_portaServidor/api/imagem?caminho=${Uri.encodeQueryComponent(caminhoLimpo)}',
          );
          final req = await clienteHttp.getUrl(uri);
          final resp = await req.close();

          if (resp.statusCode == HttpStatus.ok) {
            final bytes = await resp.fold<List<int>>([], (acc, chunk) => acc..addAll(chunk));
            await arquivoLocal.writeAsBytes(bytes);

            if (await arquivoLocal.exists() && arquivoLocal.lengthSync() > 0) {
              mapaCaminhos[caminhoLimpo] = arquivoLocal.path;
              return arquivoLocal.path;
            }
          }
        } catch (e) {
          debugPrint('[ClienteRedeLocal] Erro ao baixar imagem "$caminhoLimpo": $e');
        }

        if (localExistente != null && File(localExistente).existsSync()) {
          return localExistente;
        }

        return caminhoLimpo;
      }

      // 1. Logo da loja
      String novaLogo = lojaRemota.logo;
      if (novaLogo.isNotEmpty) {
        novaLogo = await resolverCaminhoImagem(novaLogo);
      }

      // 2. Itens da loja
      final novosItens = <ItemLoja>[];
      for (final item in lojaRemota.itensLoja) {
        if (item.imagens.isNotEmpty) {
          final novasImgs = <String>[];
          for (final img in item.imagens) {
            novasImgs.add(await resolverCaminhoImagem(img));
          }
          novosItens.add(item.copyWith(imagens: novasImgs));
        } else {
          novosItens.add(item);
        }
      }

      // 3. Categorias da loja
      final novasCategorias = <CategoriaLoja>[];
      for (final cat in lojaRemota.categoriasLoja) {
        if (cat.foto.isNotEmpty) {
          final local = await resolverCaminhoImagem(cat.foto);
          novasCategorias.add(cat.copyWith(foto: local));
        } else {
          novasCategorias.add(cat);
        }
      }

      // 4. Clientes da loja
      final novosClientes = <Cliente>[];
      for (final cli in lojaRemota.clientesLoja) {
        if (cli.foto.isNotEmpty) {
          final local = await resolverCaminhoImagem(cli.foto);
          novosClientes.add(cli.copyWith(foto: local));
        } else {
          novosClientes.add(cli);
        }
      }

      // 5. Fornecedores da loja
      final novosFornecedores = <Fornecedor>[];
      for (final forn in lojaRemota.fornecedoresLoja) {
        if (forn.foto.isNotEmpty) {
          final local = await resolverCaminhoImagem(forn.foto);
          novosFornecedores.add(forn.copyWith(foto: local));
        } else {
          novosFornecedores.add(forn);
        }
      }

      // 6. Galeria da loja
      final novaGaleria = <String>[];
      for (final g in lojaRemota.galeria) {
        novaGaleria.add(await resolverCaminhoImagem(g));
      }

      // 7. Músicas da loja
      final novasMusicas = <String>[];
      for (final m in lojaRemota.musicas) {
        novasMusicas.add(await baixarAudioRemoto(m));
      }

      // 8. Arquivos de áudio da loja
      final novosAudios = <String>[];
      for (final a in lojaRemota.arquivosAudio) {
        novosAudios.add(await baixarAudioRemoto(a));
      }

      return lojaRemota.copyWith(
        logo: novaLogo,
        itensLoja: novosItens,
        categoriasLoja: novasCategorias,
        clientesLoja: novosClientes,
        fornecedoresLoja: novosFornecedores,
        galeria: novaGaleria,
        musicas: novasMusicas,
        arquivosAudio: novosAudios,
      );
    } catch (e) {
      debugPrint('[ClienteRedeLocal] Erro ao sincronizar imagens: $e');
      return lojaRemota;
    }
  }

  /// Sincroniza a Identidade do Usuário (dados cadastrais e foto) a partir do balcão (autocura mútua)
  Future<void> sincronizarIdentidadeUsuario({AuthProvider? auth}) async {
    final authInstancia = auth ?? _authProvider;
    final cpf = _pdvProvider?.cpfAtual ?? authInstancia?.contaAtual?.cpf ?? authInstancia?.cpf;
    if (cpf == null || cpf.isEmpty || _ipServidor == null || _portaServidor == null) return;

    try {
      final contaLocal = await ContasNousService.buscarPorCpf(cpf);
      final fotoLocalExiste = contaLocal != null &&
          ImagemService.resolverCaminhoExistente(contaLocal.foto) != null;

      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final uri = Uri.parse(
        'http://$_ipServidor:$_portaServidor/api/usuario?cpf=${Uri.encodeQueryComponent(cpf)}',
      );
      final req = await client.getUrl(uri);
      final resp = await req.close();

      if (resp.statusCode == HttpStatus.ok) {
        final body = await utf8.decodeStream(resp);
        final dados = jsonDecode(body) as Map<String, dynamic>;
        if (dados['sucesso'] == true && dados['usuario'] != null) {
          var usuarioRemoto =
              UsuarioNous.fromJson(dados['usuario'] as Map<String, dynamic>);

          final temFotoRemota = usuarioRemoto.foto.isNotEmpty;

          // Se a conta remota tem foto, baixa a foto e regrava o caminho local
          if (temFotoRemota) {
            final novaFotoLocal = await baixarImagemRemota(usuarioRemoto.foto);
            usuarioRemoto = usuarioRemoto.copyWith(foto: novaFotoLocal);
            await ContasNousService.salvar(usuarioRemoto);
            if (authInstancia != null) {
              await authInstancia.recarregarConta();
            }
            debugPrint(
              '[ClienteRedeLocal] Identidade do usuário sincronizada com sucesso para o CPF: $cpf (Foto: ${usuarioRemoto.foto})',
            );
          } else if (fotoLocalExiste) {
            // Servidor não tem foto, mas nós temos a foto física localmente!
            // Envia a foto local para o servidor para autocura mútua
            debugPrint(
              '[ClienteRedeLocal] Servidor sem foto para $cpf, enviando foto local para completar no balcão...',
            );
            await enviarUsuario(contaLocal);
          } else {
            if (contaLocal == null) {
              await ContasNousService.salvar(usuarioRemoto);
              if (authInstancia != null) {
                await authInstancia.recarregarConta();
              }
            }
          }
        }
      } else if (resp.statusCode == HttpStatus.notFound && contaLocal != null) {
        // Servidor não possui registro deste usuário: envia para o balcão
        await enviarUsuario(contaLocal);
      }
    } catch (e) {
      debugPrint('[ClienteRedeLocal] Erro ao sincronizar identidade do usuário: $e');
    }
  }

  /// Consulta o servidor balcão na rede Wi-Fi local para obter a ficha unificada da conta pelo CPF
  Future<UsuarioNous?> buscarUsuarioRemoto(String cpf) async {
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
    if (cpfLimpo.isEmpty) return null;

    String? ip = _ipServidor;
    int porta = _portaServidor ?? ServidorRedeLocal.portaPadraoHttp;

    // Se ainda não temos IP do servidor, tenta usar as lojas encontradas via UDP
    if (ip == null && lojasEncontradas.value.isNotEmpty) {
      ip = lojasEncontradas.value.first.ip;
      porta = lojasEncontradas.value.first.porta;
    }

    var iniciouDescobertaAqui = false;
    // Se ainda não descobriu, inicia escuta UDP rápida de 1.5 segundos
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

    if (ip == null) return null;

    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 3);
      final uri = Uri.parse(
        'http://$ip:$porta/api/usuario?cpf=${Uri.encodeQueryComponent(cpf)}',
      );
      final req = await client.getUrl(uri);
      final resp = await req.close();

      if (resp.statusCode == HttpStatus.ok) {
        final body = await utf8.decodeStream(resp);
        final dados = jsonDecode(body) as Map<String, dynamic>;
        if (dados['sucesso'] == true && dados['usuario'] != null) {
          var usuarioRemoto =
              UsuarioNous.fromJson(dados['usuario'] as Map<String, dynamic>);

          if (usuarioRemoto.foto.isNotEmpty) {
            final novaFotoLocal = await baixarImagemRemota(usuarioRemoto.foto);
            usuarioRemoto = usuarioRemoto.copyWith(foto: novaFotoLocal);
          } else {
            // Se o servidor retornou sem foto, mas nós já temos foto válida local, preserva!
            final local = await ContasNousService.buscarPorCpf(cpfLimpo);
            if (local != null &&
                local.foto.isNotEmpty &&
                ImagemService.existe(local.foto)) {
              usuarioRemoto = usuarioRemoto.copyWith(foto: local.foto);
            }
          }

          await ContasNousService.salvar(usuarioRemoto);
          debugPrint(
            '[ClienteRedeLocal] Ficha unificada do CPF $cpf recuperada do balcão ($ip:$porta) com sucesso!',
          );
          return usuarioRemoto;
        }
      }
    } catch (e) {
      debugPrint('[ClienteRedeLocal] Falha ao consultar usuário remoto: $e');
    }
    return null;
  }

  /// Verifica se o balcão possui atualizações do sistema ou APK disponível para download
  Future<void> verificarAtualizacaoLocal() async {
    if (_ipServidor == null || _portaServidor == null) return;

    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final uri = Uri.parse('http://$_ipServidor:$_portaServidor/api/versao');
      final req = await client.getUrl(uri);
      final resp = await req.close();

      if (resp.statusCode == HttpStatus.ok) {
        final body = await utf8.decodeStream(resp);
        final dados = jsonDecode(body) as Map<String, dynamic>;

        if (dados['sucesso'] == true && dados['temApk'] == true) {
          final versaoRemota = dados['versao'] as String? ?? AtualizacaoService.versaoAtual;
          final buildRemota = dados['build'] as int? ?? AtualizacaoService.buildAtual;

          final temNovaVersao = buildRemota > AtualizacaoService.buildAtual ||
              (buildRemota == AtualizacaoService.buildAtual &&
                  AtualizacaoService.versaoMaior(versaoRemota, AtualizacaoService.versaoAtual));

          if (temNovaVersao) {
            AtualizacaoService.infoAtualizacao.value = InfoAtualizacao(
              versao: versaoRemota,
              nomeVersao: 'Atualização do Balcão Wi-Fi (v$versaoRemota • Build $buildRemota)',
              descricao:
                  'Instalação da versão estável mais recente transmitida diretamente pelo Computador Balcão via Wi-Fi.',
              urlDownload: 'http://$_ipServidor:$_portaServidor/api/download_apk',
              dataPublicacao: DateTime.now(),
            );
            AtualizacaoService.temAtualizacao.value = true;
            AtualizacaoService.ultimaVerificacao.value = DateTime.now();
            AtualizacaoService.mensagemStatus.value =
                'Nova versão v$versaoRemota disponível para download no balcão!';
            debugPrint('[ClienteRedeLocal] Atualização disponível no balcão via Wi-Fi!');
          } else {
            AtualizacaoService.infoAtualizacao.value = null;
            AtualizacaoService.temAtualizacao.value = false;
            AtualizacaoService.ultimaVerificacao.value = DateTime.now();
            AtualizacaoService.mensagemStatus.value =
                'O Nous já está na versão mais recente (v${AtualizacaoService.versaoAtual}).';
            debugPrint('[ClienteRedeLocal] O aplicativo já está na mesma versão ou mais recente que o balcão.');
          }
        } else {
          AtualizacaoService.infoAtualizacao.value = null;
          AtualizacaoService.temAtualizacao.value = false;
        }
      }
    } catch (e) {
      debugPrint('[ClienteRedeLocal] Erro ao checar atualização local: $e');
    }
  }

  /// Baixa uma imagem remota individual do balcão e salva no armazenamento local
  Future<String> baixarImagemRemota(String caminhoRemoto) async {
    if (_ipServidor == null || _portaServidor == null) return caminhoRemoto;
    final caminhoLimpo = caminhoRemoto.trim();
    if (caminhoLimpo.isEmpty) return '';

    if (File(caminhoLimpo).existsSync()) {
      return caminhoLimpo;
    }

    try {
      final dirBase = await ImagemService.obterDiretorioBase();
      final pastaImagens = Directory('${dirBase.path}/imagens');
      if (!await pastaImagens.exists()) {
        await pastaImagens.create(recursive: true);
      }

      final ext = caminhoLimpo.split('.').last.toLowerCase();
      final extensaoFinal = ImagemService.extensoesImagem.contains(ext) ? ext : 'jpg';
      final nomeArquivoLocal = 'remota_${caminhoLimpo.hashCode.abs()}.$extensaoFinal';
      final arquivoLocal = File('${pastaImagens.path}/$nomeArquivoLocal');

      if (arquivoLocal.existsSync() && arquivoLocal.lengthSync() > 0) {
        return arquivoLocal.path;
      }

      final clienteHttp = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final uri = Uri.parse(
        'http://$_ipServidor:$_portaServidor/api/imagem?caminho=${Uri.encodeQueryComponent(caminhoLimpo)}',
      );
      final req = await clienteHttp.getUrl(uri);
      final resp = await req.close();

      if (resp.statusCode == HttpStatus.ok) {
        final bytes = await resp.fold<List<int>>([], (acc, chunk) => acc..addAll(chunk));
        await arquivoLocal.writeAsBytes(bytes);

        if (await arquivoLocal.exists() && arquivoLocal.lengthSync() > 0) {
          return arquivoLocal.path;
        }
      }
    } catch (e) {
      debugPrint('[ClienteRedeLocal] Erro ao baixar imagem remota: $e');
    }

    return caminhoLimpo;
  }

  /// Baixa um arquivo de áudio/música remoto do balcão e salva no armazenamento local
  Future<String> baixarAudioRemoto(String caminhoRemoto) async {
    if (_ipServidor == null || _portaServidor == null) return caminhoRemoto;
    final caminhoLimpo = caminhoRemoto.trim();
    if (caminhoLimpo.isEmpty) return '';

    final caminhoExistente = ImagemService.resolverCaminhoExistente(caminhoLimpo);
    if (caminhoExistente != null) {
      return caminhoExistente;
    }

    try {
      final dirBase = await ImagemService.obterDiretorioBase();
      final pastaAudios = Directory('${dirBase.path}/audios');
      if (!await pastaAudios.exists()) {
        await pastaAudios.create(recursive: true);
      }

      final ext = caminhoLimpo.split('.').last.toLowerCase();
      final extensaoFinal = (ext.isNotEmpty && ext.length <= 5) ? ext : 'mp3';
      final nomeArquivoLocal = 'remoto_audio_${caminhoLimpo.hashCode.abs()}.$extensaoFinal';
      final arquivoLocal = File('${pastaAudios.path}/$nomeArquivoLocal');

      if (arquivoLocal.existsSync() && arquivoLocal.lengthSync() > 0) {
        return arquivoLocal.path;
      }

      final clienteHttp = HttpClient()..connectionTimeout = const Duration(seconds: 15);
      final uri = Uri.parse(
        'http://$_ipServidor:$_portaServidor/api/audio?caminho=${Uri.encodeQueryComponent(caminhoLimpo)}',
      );
      final req = await clienteHttp.getUrl(uri);
      final resp = await req.close();

      if (resp.statusCode == HttpStatus.ok) {
        final sink = arquivoLocal.openWrite();
        await resp.pipe(sink);

        if (await arquivoLocal.exists() && arquivoLocal.lengthSync() > 0) {
          return arquivoLocal.path;
        } else {
          try {
            if (await arquivoLocal.exists()) await arquivoLocal.delete();
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('[ClienteRedeLocal] Erro ao baixar áudio remoto: $e');
    }

    return caminhoLimpo;
  }

  /// Envia a Identidade do Usuário (dados cadastrais, apelido e foto) atualizada para o servidor balcão
  Future<bool> enviarUsuario(UsuarioNous usuario) async {
    if (_ipServidor == null || _portaServidor == null) return false;
    try {
      var usuarioParaEnvio = usuario;

      // Se possui foto local no dispositivo, envia o arquivo físico primeiro para o servidor
      if (usuario.foto.isNotEmpty) {
        final fotoResolvida =
            ImagemService.resolverCaminhoExistente(usuario.foto);
        if (fotoResolvida != null) {
          final fotoNoServidor =
              await _enviarUploadImagemParaServidor(fotoResolvida);
          if (fotoNoServidor.isNotEmpty) {
            usuarioParaEnvio = usuario.copyWith(foto: fotoNoServidor);
          }
        }
      }

      final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
      final request = await client.postUrl(
        Uri.parse('http://$_ipServidor:$_portaServidor/api/usuario'),
      );
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(usuarioParaEnvio.toJson()));
      final response = await request.close();
      return response.statusCode == HttpStatus.ok;
    } catch (e) {
      debugPrint('[ClienteRedeLocal] Erro ao enviar usuário ao servidor: $e');
      return false;
    }
  }

  /// Obtém o caminho físico existente e válido de uma foto local para um CPF específico
  /// pesquisando em ContasLocais, Clientes da Loja ou DadosLocaisService
  Future<String?> _obterFotoLocalValidaPorCpf(String cpf) async {
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
    if (cpfLimpo.isEmpty) return null;

    // 1. Tenta no banco de contas local
    final conta = await ContasNousService.buscarPorCpf(cpfLimpo);
    if (conta != null && conta.foto.isNotEmpty) {
      final resolvida = ImagemService.resolverCaminhoExistente(conta.foto);
      if (resolvida != null) return resolvida;
    }

    // 2. Tenta nos clientes da loja
    final fotoCli = _pdvProvider?.buscarFotoClientePorCpf(cpfLimpo);
    if (fotoCli != null && fotoCli.isNotEmpty) {
      final resolvida = ImagemService.resolverCaminhoExistente(fotoCli);
      if (resolvida != null) return resolvida;
    }

    // 3. Tenta em DadosLocaisService
    try {
      final dadosAuto = await DadosLocaisService.buscarPorDocumento(cpfLimpo);
      if (dadosAuto != null && dadosAuto.foto.isNotEmpty) {
        final resolvida = ImagemService.resolverCaminhoExistente(dadosAuto.foto);
        if (resolvida != null) return resolvida;
      }
    } catch (_) {}

    return null;
  }

  /// Cura ativamente lacunas de fotos de membros/usuários reportadas pelo servidor balcão
  Future<void> _curarFotosUsuariosAusentesNoServidor(
      List<String> cpfsAusentes) async {
    if (_ipServidor == null || _portaServidor == null || cpfsAusentes.isEmpty) {
      return;
    }

    for (final cpfBruto in cpfsAusentes) {
      final cpfLimpo = cpfBruto.replaceAll(RegExp(r'\D'), '');
      if (cpfLimpo.isEmpty) continue;

      final fotoFisicaLocal = await _obterFotoLocalValidaPorCpf(cpfLimpo);
      if (fotoFisicaLocal != null) {
        debugPrint(
          '[ClienteRedeLocal] Autocura mútua: servidor balcão reportou ausência de foto física para CPF $cpfLimpo. Enviando foto local...',
        );
        var conta = await ContasNousService.buscarPorCpf(cpfLimpo);
        if (conta == null) {
          final dadosAuto =
              await DadosLocaisService.buscarPorDocumento(cpfLimpo);
          conta = UsuarioNous(
            cpf: cpfLimpo,
            nome: dadosAuto?.nome ?? 'Usuário',
            apelido: dadosAuto?.apelido ?? '',
            dataNascimento: dadosAuto?.dataNascimento ?? '',
            foto: fotoFisicaLocal,
          );
        } else {
          conta = conta.copyWith(foto: fotoFisicaLocal);
        }
        await enviarUsuario(conta);
      }
    }
  }

  /// Reconcilia todas as contas cadastradas neste dispositivo com o servidor balcão,
  /// garantindo que informações faltantes (especialmente fotos de perfil) sejam
  /// transferidas mutuamente entre o celular e o servidor (autocura mútua orgânica).
  Future<void> _reconciliarTodasContasLocaisComServidor() async {
    if (_ipServidor == null || _portaServidor == null) return;
    try {
      final cpfsAExaminar = <String>{};

      // 1. Todas as contas conhecidas no cofre local
      final contasLocais = await ContasNousService.carregarTodas();
      for (final c in contasLocais) {
        cpfsAExaminar.add(c.cpf);
      }

      // 2. Membros e clientes da loja sincronizada
      if (_lojaSincronizada != null) {
        for (final m in _lojaSincronizada!.membros) {
          if (m.cpf.isNotEmpty) cpfsAExaminar.add(m.cpf);
        }
        for (final cli in _lojaSincronizada!.clientesLoja) {
          final doc = cli.cnpj.replaceAll(RegExp(r'\D'), '');
          if (doc.length == 11) cpfsAExaminar.add(cli.cnpj);
        }
      }

      for (final cpfBruto in cpfsAExaminar) {
        final cpfLimpo = cpfBruto.replaceAll(RegExp(r'\D'), '');
        if (cpfLimpo.isEmpty) continue;

        final fotoFisicaLocal = await _obterFotoLocalValidaPorCpf(cpfLimpo);
        final temFotoLocal = fotoFisicaLocal != null;

        try {
          final client = HttpClient()
            ..connectionTimeout = const Duration(seconds: 3);
          final uri = Uri.parse(
            'http://$_ipServidor:$_portaServidor/api/usuario?cpf=${Uri.encodeQueryComponent(cpfLimpo)}',
          );
          final req = await client.getUrl(uri);
          final resp = await req.close();

          if (resp.statusCode == HttpStatus.ok) {
            final body = await utf8.decodeStream(resp);
            final dados = jsonDecode(body) as Map<String, dynamic>;
            if (dados['sucesso'] == true && dados['usuario'] != null) {
              var usuarioRemoto = UsuarioNous.fromJson(
                  dados['usuario'] as Map<String, dynamic>);
              final temFotoRemota = usuarioRemoto.foto.isNotEmpty;
              final contaLocal = await ContasNousService.buscarPorCpf(cpfLimpo);

              var contaMesclada = contaLocal != null
                  ? _mesclarUsuarios(contaLocal, usuarioRemoto)
                  : usuarioRemoto;

              if (!temFotoRemota && temFotoLocal) {
                debugPrint(
                  '[ClienteRedeLocal] Autocura mútua: enviando foto e dados locais de $cpfLimpo (${contaMesclada.nome}) para o servidor balcão...',
                );
                contaMesclada = contaMesclada.copyWith(foto: fotoFisicaLocal);
                await enviarUsuario(contaMesclada);
              } else if (temFotoRemota && !temFotoLocal) {
                debugPrint(
                  '[ClienteRedeLocal] Autocura mútua: baixando foto remota de $cpfLimpo (${usuarioRemoto.nome}) do balcão...',
                );
                final novaFotoLocal =
                    await baixarImagemRemota(usuarioRemoto.foto);
                contaMesclada = contaMesclada.copyWith(foto: novaFotoLocal);
                await ContasNousService.salvar(contaMesclada);
                _pdvProvider?.sincronizarFotoUsuarioEmClientes(
                    contaMesclada.cpf, contaMesclada.foto);
                if (_authProvider?.contaAtual?.cpf.replaceAll(RegExp(r'\D'), '') == cpfLimpo ||
                    _authProvider?.cpf.replaceAll(RegExp(r'\D'), '') == cpfLimpo) {
                  await _authProvider?.recarregarConta();
                }
              } else {
                await ContasNousService.salvar(contaMesclada);
                if (_authProvider?.contaAtual?.cpf.replaceAll(RegExp(r'\D'), '') == cpfLimpo ||
                    _authProvider?.cpf.replaceAll(RegExp(r'\D'), '') == cpfLimpo) {
                  await _authProvider?.recarregarConta();
                }
              }
            }
          } else if (resp.statusCode == HttpStatus.notFound) {
            final contaLocal = await ContasNousService.buscarPorCpf(cpfLimpo);
            if (contaLocal != null) {
              debugPrint(
                '[ClienteRedeLocal] Autocura mútua: servidor não conhece conta ${contaLocal.cpf} (${contaLocal.nome}). Enviando ao balcão...',
              );
              await enviarUsuario(contaLocal);
            }
          }
        } catch (e) {
          debugPrint(
            '[ClienteRedeLocal] Erro ao reconciliar conta $cpfLimpo com servidor: $e',
          );
        }
      }
    } catch (e) {
      debugPrint(
        '[ClienteRedeLocal] Erro na reconciliação universal de contas: $e',
      );
    }
  }

  /// Mescla duas fichas de usuário preservando dados preenchidos de ambas as pontas
  UsuarioNous _mesclarUsuarios(UsuarioNous local, UsuarioNous remoto) {
    return UsuarioNous(
      cpf: local.cpf.isNotEmpty ? local.cpf : remoto.cpf,
      nome: local.nome.isNotEmpty ? local.nome : remoto.nome,
      apelido: local.apelido.isNotEmpty ? local.apelido : remoto.apelido,
      dataNascimento: local.dataNascimento.isNotEmpty
          ? local.dataNascimento
          : remoto.dataNascimento,
      emails: {...local.emails, ...remoto.emails}.toList(),
      foto: local.foto.isNotEmpty && ImagemService.existe(local.foto)
          ? local.foto
          : remoto.foto,
      nomePai: local.nomePai.isNotEmpty ? local.nomePai : remoto.nomePai,
      nomeMae: local.nomeMae.isNotEmpty ? local.nomeMae : remoto.nomeMae,
      localNascimento: local.localNascimento.isNotEmpty
          ? local.localNascimento
          : remoto.localNascimento,
      tipoSanguineo: local.tipoSanguineo.isNotEmpty
          ? local.tipoSanguineo
          : remoto.tipoSanguineo,
      estadoCivil: local.estadoCivil.isNotEmpty
          ? local.estadoCivil
          : remoto.estadoCivil,
    );
  }

  /// Sincroniza pan-dispositivo todas as lojas e referências associadas ao CPF ativo
  /// entre este terminal e o servidor balcão, garantindo que perfis profissionais
  /// acessados no trabalho ou em outros dispositivos apareçam imediatamente neste aparelho.
  Future<void> sincronizarPerfisLojasComServidor() async {
    if (_ipServidor == null || _portaServidor == null) return;
    if (_sincronizandoPerfisLojas) return;
    final cpf = (_pdvProvider?.cpfAtual ?? _authProvider?.cpf ?? '')
        .replaceAll(RegExp(r'\D'), '');
    if (cpf.isEmpty) return;

    _sincronizandoPerfisLojas = true;
    try {
      final referenciasLocais = await LojasService.carregarReferencias(cpf);
      final lojasAEnviar = <Map<String, dynamic>>[];

      // Coleta lojas referenciadas conhecidas
      for (final ref in referenciasLocais) {
        final loja = await LojasService.carregarLojaPorId(ref.lojaId);
        if (loja != null) {
          lojasAEnviar.add(LojasService.sanitizarCaminhosImagens(loja).toJson());
        }
      }

      // Coleta lojas onde este CPF é dono
      final lojasProprias = await LojasService.carregar(cpf);
      for (final lp in lojasProprias) {
        if (!lojasAEnviar.any((m) => m['id'] == lp.id)) {
          lojasAEnviar.add(LojasService.sanitizarCaminhosImagens(lp).toJson());
        }
      }

      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 5);
      final uri = Uri.parse(
        'http://$_ipServidor:$_portaServidor/api/sincronizar_perfis_usuario',
      );
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;

      final payload = {
        'cpf': cpf,
        'referencias': referenciasLocais.map((r) => r.toJson()).toList(),
        'lojas': lojasAEnviar,
      };

      req.write(jsonEncode(payload));
      final resp = await req.close();

      if (resp.statusCode == HttpStatus.ok) {
        final body = await utf8.decodeStream(resp);
        final dados = jsonDecode(body) as Map<String, dynamic>;

        if (dados['sucesso'] == true) {
          final referenciasRecebidas =
              dados['referencias'] as List<dynamic>? ?? [];
          final lojasRecebidas = dados['lojas'] as List<dynamic>? ?? [];
          var houveAlteracao = false;

          // Salva lojas recebidas após baixar suas fotos (logo, itens, categorias)
          for (final lJson in lojasRecebidas) {
            try {
              final loja = Loja.fromJson(lJson as Map<String, dynamic>);
              final lojaComImagens = await _sincronizarImagensRemotas(loja);
              await LojasService.salvarLojaIndividual(lojaComImagens);
              houveAlteracao = true;
            } catch (_) {}
          }

          // Salva referências válidas recebidas
          for (final rJson in referenciasRecebidas) {
            try {
              final ref =
                  ReferenciaLoja.fromJson(rJson as Map<String, dynamic>);
              final jaTem = referenciasLocais.any((r) => r.lojaId == ref.lojaId);
              if (!jaTem) {
                await LojasService.adicionarReferencia(cpf, ref);
                houveAlteracao = true;
              }
            } catch (_) {}
          }

          // Limpa referências locais que o servidor balcão não possui mais (ex.: usuário saiu da loja)
          final idsValidosServidor = referenciasRecebidas
              .map((r) => (r as Map<String, dynamic>)['lojaId'] as String? ?? '')
              .where((id) => id.isNotEmpty)
              .toSet();
          for (final rLocal in referenciasLocais) {
            if (!idsValidosServidor.contains(rLocal.lojaId)) {
              await LojasService.removerReferencia(cpf, rLocal.lojaId);
              houveAlteracao = true;
            }
          }

          if (houveAlteracao) {
            debugPrint(
              '[ClienteRedeLocal] Sincronização Pan-Dispositivo: perfis de lojas sincronizados para o CPF $cpf. Recarregando PdvProvider...',
            );
            await _pdvProvider?.entrarComCpf(cpf);
          }
        }
      }
    } catch (e) {
      debugPrint('[ClienteRedeLocal] Erro ao sincronizar perfis de lojas com servidor: $e');
    } finally {
      _sincronizandoPerfisLojas = false;
    }
  }

  /// Notifica o servidor balcão que o membro saiu da loja para desvinculação imediata
  Future<void> notificarSaidaLoja(String lojaId, String cpf) async {
    if (_ipServidor == null || _portaServidor == null) return;
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final uri = Uri.parse('http://$_ipServidor:$_portaServidor/api/loja/sair');
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({'cpf': cpf, 'lojaId': lojaId}));
      final resp = await req.close();
      await resp.drain();
      debugPrint('[ClienteRedeLocal] Saída da loja $lojaId notificada ao balcão com sucesso.');
    } catch (e) {
      debugPrint('[ClienteRedeLocal] Erro ao notificar saída da loja ao balcão: $e');
    }
  }
}
