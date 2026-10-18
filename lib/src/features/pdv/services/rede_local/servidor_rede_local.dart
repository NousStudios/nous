import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nous/src/core/services/atualizacao_service.dart';
import 'package:nous/src/core/services/navigator_key_service.dart';
import 'package:nous/src/core/services/som_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/dados_locais_service.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';

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
  final Set<String> _terminaisAutorizados = {};
  DateTime? _dataHoraInicio;

  String? _ipServidor;
  int _porta = portaPadraoHttp;
  Loja? _lojaAtiva;
  PdvProvider? _pdvProvider;

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
      final ipRemoto = request.connectionInfo?.remoteAddress.address ?? '127.0.0.1';
      final cpfParam = request.uri.queryParameters['cpf'];
      final nomeParam = request.uri.queryParameters['nome'];
      final dispositivoParam = request.uri.queryParameters['dispositivo'];

      final ehLocal = request.connectionInfo?.remoteAddress.isLoopback ?? false;
      final chaveTerminal = (cpfParam != null && cpfParam.trim().isNotEmpty)
          ? '${ipRemoto}_${cpfParam.replaceAll(RegExp(r'\D'), '')}'
          : '${ipRemoto}_${dispositivoParam?.trim() ?? ''}';

      if (!ehLocal && !_terminaisAutorizados.contains(chaveTerminal)) {
        final autorizou = await _solicitarAutorizacaoTerminal(
          ip: ipRemoto,
          nomeDispositivo: (dispositivoParam != null && dispositivoParam.trim().isNotEmpty)
              ? dispositivoParam.trim()
              : 'Terminal Móvel',
          nomeUsuario: nomeParam,
          cpf: cpfParam,
        );

        if (!autorizou) {
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

        _terminaisAutorizados.add(chaveTerminal);
      }

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
        );
        _garantirMembroConectado(terminalTemp);
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
      _responderJson(request, {
        'sucesso': true,
        'loja': lojaRetorno.toJson(),
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

          // 3. Consolidar dados da loja:
          // Aceita modificações feitas no terminal móvel (membros, cargos, produtos, categorias, mesas, clientes, fornecedores, etc.)
          // e preserva a autoridade de pedidos e estoque do balcão.
          final lojaConsolidada = lojaAtual.copyWith(
            nome: lojaRemota.nome,
            cnpj: lojaRemota.cnpj,
            telefone: lojaRemota.telefone,
            endereco: lojaRemota.endereco,
            numero: lojaRemota.numero,
            email: lojaRemota.email,
            redesSociais: lojaRemota.redesSociais,
            categorias: lojaRemota.categorias,
            tags: lojaRemota.tags,
            logo: lojaRemota.logo.isNotEmpty ? lojaRemota.logo : lojaAtual.logo,
            membros: lojaRemota.membros,
            cargosPersonalizados: lojaRemota.cargosPersonalizados,
            permissoesCargosNativos: lojaRemota.permissoesCargosNativos,
            categoriasLoja: lojaRemota.categoriasLoja,
            itensLoja: lojaRemota.itensLoja,
            gruposComponentesLoja: lojaRemota.gruposComponentesLoja,
            clientesLoja: lojaRemota.clientesLoja,
            fornecedoresLoja: lojaRemota.fornecedoresLoja,
            mesas: lojaRemota.mesas,
            acoes: acoesMescladas,
            configuracoesImpressora: lojaRemota.configuracoesImpressora,
            tempoConclusaoMinutos: lojaRemota.tempoConclusaoMinutos,
            sonsAlertas: lojaRemota.sonsAlertas,
            atalhosTeclado: lojaRemota.atalhosTeclado,
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
      final arquivoApk = _obterArquivoApk();
      final temApk = arquivoApk != null && arquivoApk.existsSync() && arquivoApk.lengthSync() > 0;
      final tamanho = temApk ? arquivoApk.lengthSync() : 0;

      _responderJson(request, {
        'sucesso': true,
        'versao': AtualizacaoService.versaoAtual,
        'build': AtualizacaoService.buildAtual,
        'temApk': temApk,
        'tamanhoBytes': tamanho,
        'nomeArquivo': 'Nous_Android_v${AtualizacaoService.versaoAtual}.apk',
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
          _atualizarListasTerminais();
          debugPrint(
            '[ServidorRedeLocal] Terminal identificado: "${terminal.nome}" (CPF: ${terminal.cpf}, Nome: ${terminal.nomeUsuario}, IP: ${terminal.ip})',
          );

          // Verifica se o CPF ainda não é membro da loja e garante sua inclusão
          _garantirMembroConectado(terminal);

          // Unifica e consolida a Identidade do Usuário no banco de contas local do balcão
          _consolidarContaTerminal(terminal);

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
      final hostNome = Platform.localHostname;
      lista.add(
        TerminalConectadoInfo(
          id: 'balcao_servidor_local',
          nome: hostNome.isNotEmpty ? 'Computador Balcão ($hostNome)' : 'Computador Balcão (Local)',
          ip: _ipServidor ?? '127.0.0.1',
          conectadoEm: _dataHoraInicio ?? DateTime.now(),
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
      String nomeFinal = (terminal.nomeUsuario != null && terminal.nomeUsuario!.trim().isNotEmpty)
          ? terminal.nomeUsuario!.trim()
          : '';
      if (nomeFinal.isEmpty) {
        final conta = await ContasNousService.buscarPorCpf(terminal.cpf!);
        if (conta != null && conta.nome.trim().isNotEmpty) {
          nomeFinal = conta.nome.trim();
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
    }
  }

  /// Consolida e unifica a ficha de Identidade do Usuário no banco de contas local do balcão
  void _consolidarContaTerminal(TerminalConectadoInfo terminal) async {
    final cpfLimpo = terminal.cpf?.replaceAll(RegExp(r'\D'), '');
    if (cpfLimpo == null || cpfLimpo.isEmpty) return;

    try {
      final contaExistente =
          await ContasNousService.buscarPorCpf(terminal.cpf!);
      final nome = (terminal.nomeUsuario != null &&
              terminal.nomeUsuario!.trim().isNotEmpty)
          ? terminal.nomeUsuario!.trim()
          : (terminal.nome.isNotEmpty ? terminal.nome : 'Usuário Nous');

      if (contaExistente == null) {
        final dadosAuto =
            await DadosLocaisService.buscarPorDocumento(terminal.cpf!);
        final novaConta = UsuarioNous(
          cpf: terminal.cpf!,
          nome: (dadosAuto != null && dadosAuto.nome.isNotEmpty)
              ? dadosAuto.nome
              : nome,
          dataNascimento: dadosAuto?.dataNascimento ?? '',
          foto: dadosAuto?.foto ?? '',
        );
        await ContasNousService.salvar(novaConta);
        debugPrint(
          '[ServidorRedeLocal] Ficha de conta unificada no balcão para CPF $cpfLimpo (${novaConta.nome})',
        );
      } else if (contaExistente.nome.isEmpty && nome.isNotEmpty) {
        final atualizada = contaExistente.copyWith(nome: nome);
        await ContasNousService.salvar(atualizada);
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

  /// Localiza o arquivo binário do APK Android no armazenamento local do computador balcão
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
        '$pastaExe/dist/Nous_Android_v1.0.0_Versao_Teste.apk',
        '$pastaExe/Nous_Android_v1.0.0_Versao_Teste.apk',
        'dist/Nous_Android_v1.0.0_Versao_Teste.apk',
        '${Directory.current.path}/dist/Nous_Android_v1.0.0_Versao_Teste.apk',
        'D:/Nous/nous/dist/Nous_Android_v1.0.0_Versao_Teste.apk',
      ];

      for (final c in caminhos) {
        final f = File(c);
        if (f.existsSync() && f.lengthSync() > 0) {
          return f;
        }
      }

      // Fallback dinâmico: busca qualquer arquivo .apk nas pastas dist
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
              .where((f) => f.path.toLowerCase().endsWith('.apk') && f.lengthSync() > 0)
              .toList();
          if (apks.isNotEmpty) {
            final comVersao = apks.where((f) => f.path.contains(versao)).firstOrNull;
            return comVersao ?? apks.first;
          }
        }
      }
    } catch (_) {}
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
  Future<bool> _solicitarAutorizacaoTerminal({
    required String ip,
    required String nomeDispositivo,
    String? nomeUsuario,
    String? cpf,
  }) async {
    final context = NavigatorKeyService.currentContext;
    if (context == null || !context.mounted) {
      return true;
    }

    SomService.tocarBipPadrao();

    final completer = Completer<bool>();
    var respondido = false;

    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        final theme = ThemeController.currentTheme.value;
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
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Um novo terminal móvel está solicitando sincronização com esta loja na rede Wi-Fi:',
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
                    ],
                  ),
                ),
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
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                if (!respondido) {
                  respondido = true;
                  Navigator.of(dialogCtx).pop(false);
                  if (!completer.isCompleted) completer.complete(false);
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
                  Navigator.of(dialogCtx).pop(true);
                  if (!completer.isCompleted) completer.complete(true);
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

    // Timeout de segurança de 30 segundos para não prender a conexão caso o operador esteja ausente
    Future.delayed(const Duration(seconds: 30), () {
      if (!respondido) {
        respondido = true;
        if (context.mounted) {
          try {
            Navigator.of(context, rootNavigator: true).pop(false);
          } catch (_) {}
        }
        if (!completer.isCompleted) {
          completer.complete(false);
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
