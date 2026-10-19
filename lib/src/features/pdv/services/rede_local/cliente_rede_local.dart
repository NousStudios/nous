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
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/referencia_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

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
  Timer? _timerDebounceEnvioLoja;

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
        _lojaSincronizada = await _sincronizarImagensRemotas(lojaBruta);

        // Atualiza a loja no provedor local e no SQLite para visualização completa com imagens
        await _pdvProvider!.adicionarOuAtualizarLoja(_lojaSincronizada!);
        await _vincularLojaSeNecessario(_lojaSincronizada!);
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
        // 1. Salva a loja completa no cofre do dono original no banco SQLite local deste aparelho
        final cofreDono = await LojasService.carregar(loja.cpfDonoOriginal);
        final idx = cofreDono.indexWhere((l) => l.id == loja.id);
        if (idx != -1) {
          cofreDono[idx] = loja;
        } else {
          cofreDono.add(loja);
        }
        await LojasService.salvar(loja.cpfDonoOriginal, cofreDono);

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

  /// Envia a atualização completa da loja realizada neste terminal móvel para o servidor central (balcão)
  Future<bool> enviarLojaAtualizada(Loja loja, {bool imediato = false}) async {
    if (_ipServidor == null || _portaServidor == null || !conectado) return false;
    if (_aplicandoAtualizacaoRemota) return false;

    _timerDebounceEnvioLoja?.cancel();

    Future<bool> executarEnvio() async {
      try {
        final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
        final request = await client.postUrl(
          Uri.parse('http://$_ipServidor:$_portaServidor/api/loja/atualizar'),
        );
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(loja.toJson()));
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

        // Se o caminho já aponta para um arquivo existente localmente neste celular, mantém
        if (File(caminhoLimpo).existsSync()) {
          return caminhoLimpo;
        }

        // Se já foi mapeado nesta execução em memória
        if (mapaCaminhos.containsKey(caminhoLimpo)) {
          return mapaCaminhos[caminhoLimpo]!;
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

  /// Sincroniza a Identidade do Usuário (dados cadastrais e foto) a partir do balcão
  Future<void> sincronizarIdentidadeUsuario({AuthProvider? auth}) async {
    final authInstancia = auth ?? _authProvider;
    final cpf = _pdvProvider?.cpfAtual ?? authInstancia?.contaAtual?.cpf ?? authInstancia?.cpf;
    if (cpf == null || cpf.isEmpty || _ipServidor == null || _portaServidor == null) return;

    try {
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

          // Se a conta remota tem foto, baixa a foto e regrava o caminho local
          if (usuarioRemoto.foto.isNotEmpty) {
            final novaFotoLocal = await baixarImagemRemota(usuarioRemoto.foto);
            usuarioRemoto = usuarioRemoto.copyWith(foto: novaFotoLocal);
          }

          // Salva no banco SQLite local do aparelho
          await ContasNousService.salvar(usuarioRemoto);
          if (authInstancia != null) {
            await authInstancia.recarregarConta();
          }
          debugPrint(
            '[ClienteRedeLocal] Identidade do usuário sincronizada com sucesso para o CPF: $cpf (Foto: ${usuarioRemoto.foto})',
          );
        }
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

    if (File(caminhoLimpo).existsSync()) {
      return caminhoLimpo;
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

      final clienteHttp = HttpClient()..connectionTimeout = const Duration(seconds: 8);
      final uri = Uri.parse(
        'http://$_ipServidor:$_portaServidor/api/audio?caminho=${Uri.encodeQueryComponent(caminhoLimpo)}',
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
      debugPrint('[ClienteRedeLocal] Erro ao baixar áudio remoto: $e');
    }

    return caminhoLimpo;
  }

  /// Envia a Identidade do Usuário (dados cadastrais, apelido e foto) atualizada para o servidor balcão
  Future<bool> enviarUsuario(UsuarioNous usuario) async {
    if (_ipServidor == null || _portaServidor == null) return false;
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final request = await client.postUrl(
        Uri.parse('http://$_ipServidor:$_portaServidor/api/usuario'),
      );
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(usuario.toJson()));
      final response = await request.close();
      return response.statusCode == HttpStatus.ok;
    } catch (e) {
      debugPrint('[ClienteRedeLocal] Erro ao enviar usuário ao servidor: $e');
      return false;
    }
  }
}
