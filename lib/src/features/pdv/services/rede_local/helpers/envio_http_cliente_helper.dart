import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nous/src/core/services/relogio_rede_service.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/pdv/models/dispositivo_loja_info.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/rede_local/helpers/delta_loja_helper.dart';
import 'package:nous/src/features/pdv/services/rede_local/helpers/resolvedor_url_rede.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/sincronizador_usuarios_rede.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';

/// Encapsula despachos HTTP pontuais, debounce de atualização de loja,
/// reconciliação de pedidos e consultas auxiliares do cliente na rede local.
class EnvioHttpClienteHelper {
  Timer? _timerDebounceEnvioLoja;

  void cancelarDebounceEnvioLoja() {
    _timerDebounceEnvioLoja?.cancel();
    _timerDebounceEnvioLoja = null;
  }

  /// Envia a atualização completa da loja realizada neste terminal para o servidor balcão.
  Future<bool> enviarLojaAtualizada({
    required Loja loja,
    required String? ipServidor,
    required int? portaServidor,
    required bool conectado,
    required bool aplicandoAtualizacaoRemota,
    required PdvProvider? pdvProvider,
    required Future<Loja> Function(Loja) prepararLojaComUploads,
    bool imediato = false,
  }) async {
    if (ipServidor == null || portaServidor == null || !conectado) return false;
    if (aplicandoAtualizacaoRemota) return false;

    _timerDebounceEnvioLoja?.cancel();

    Future<bool> executarEnvio() async {
      try {
        final lojaParaEnvio = await prepararLojaComUploads(
          DeltaLojaHelper.compactarParaRede(loja),
        );

        final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
        final request = await client.postUrl(
          ResolvedorUrlRede.montarUriHttp(
            hostOuIp: ipServidor,
            porta: portaServidor,
            caminho: '/api/loja/atualizar',
          ),
        );
        request.headers.contentType = ContentType.json;
        final cpfRem = (pdvProvider?.cpfAtual ?? '').replaceAll(RegExp(r'\D'), '');
        if (cpfRem.isNotEmpty) {
          request.headers.set('x-cpf-remetente', cpfRem);
        }
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

  /// Consulta no servidor balcão o status atualizado de pedidos locais ausentes no snapshot.
  Future<List<PedidoLoja>> reconciliarPedidosNoServidor({
    required String? ipServidor,
    required int? portaServidor,
    required String lojaId,
    required List<String> ids,
  }) async {
    if (ipServidor == null || portaServidor == null || ids.isEmpty) {
      return const [];
    }
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 4);
      final uri = ResolvedorUrlRede.montarUriHttp(
        hostOuIp: ipServidor,
        porta: portaServidor,
        path: '/api/pedidos/reconciliar',
      );
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({'lojaId': lojaId, 'ids': ids}));
      final resp = await req.close().timeout(const Duration(seconds: 5));
      if (resp.statusCode == HttpStatus.ok) {
        final body = await utf8.decodeStream(resp);
        final json = jsonDecode(body) as Map<String, dynamic>;
        final lista = json['pedidos'] as List<dynamic>? ?? const [];
        return lista
            .whereType<Map<String, dynamic>>()
            .map(PedidoLoja.fromJson)
            .toList();
      }
    } catch (e) {
      debugPrint(
        '[ClienteRedeLocal] Erro ao reconciliar pedidos no servidor: $e',
      );
    }
    return const [];
  }

  /// Consulta o servidor balcão na rede Wi-Fi local para obter a ficha unificada da conta pelo CPF.
  Future<UsuarioNous?> buscarUsuarioRemoto({
    required String cpf,
    required String? ipServidor,
    required int? portaServidor,
    required List<DispositivoLojaInfo> lojasEncontradas,
    required Future<void> Function() iniciarDescoberta,
    required void Function() pararDescoberta,
    required SincronizadorUsuariosRede sincronizador,
    required AuthProvider? authProvider,
    required PdvProvider? pdvProvider,
  }) async {
    String? ip = ipServidor;
    int porta = portaServidor ?? ServidorRedeLocal.portaPadraoHttp;

    if (ip == null && lojasEncontradas.isNotEmpty) {
      ip = lojasEncontradas.first.ip;
      porta = lojasEncontradas.first.porta;
    }

    var iniciouDescobertaAqui = false;
    if (ip == null) {
      iniciouDescobertaAqui = true;
      await iniciarDescoberta();
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (lojasEncontradas.isNotEmpty) {
        ip = lojasEncontradas.first.ip;
        porta = lojasEncontradas.first.porta;
      }
    }

    if (iniciouDescobertaAqui) {
      pararDescoberta();
    }

    return sincronizador.buscarUsuarioRemoto(
      ipServidor: ip,
      portaServidor: porta,
      cpf: cpf,
      authProvider: authProvider,
      pdvProvider: pdvProvider,
    );
  }

  /// Atualiza cache local de conta e clientes quando uma foto de usuário é baixada do balcão.
  Future<void> onFotoUsuarioBaixada({
    required String cpfLimpo,
    required String pathFinal,
    required AuthProvider? authProvider,
    required PdvProvider? pdvProvider,
  }) async {
    try {
      final c = await ContasNousService.buscarPorCpf(cpfLimpo);
      if (c != null) {
        final atualizada = c.copyWith(foto: pathFinal);
        await ContasNousService.salvar(atualizada);
        authProvider?.atualizarContaNoCache(atualizada);
        pdvProvider?.sincronizarFotoUsuarioEmClientes(cpfLimpo, pathFinal);
      }
    } catch (_) {}
  }

  /// Sincroniza bidirecionalmente a Timeline Social com o servidor balcão.
  Future<bool> sincronizarTimelineComServidor({
    required String? ipServidor,
    required int? portaServidor,
    required List<DispositivoLojaInfo> lojasEncontradas,
  }) async {
    final ip = ipServidor ??
        (lojasEncontradas.isNotEmpty ? lojasEncontradas.first.ip : null);
    final porta = portaServidor ??
        (lojasEncontradas.isNotEmpty ? lojasEncontradas.first.porta : null);
    if (ip != null && porta != null) {
      return TimelineService.sincronizarComServidorHttp(ip: ip, porta: porta);
    }
    return false;
  }

  /// Sincroniza o relógio deste dispositivo com o balcão da rede local sob demanda.
  Future<bool> sincronizarRelogio({
    required String? ipServidor,
    required int? portaServidor,
    required List<DispositivoLojaInfo> lojasEncontradas,
  }) async {
    final ip = ipServidor ??
        (lojasEncontradas.isNotEmpty ? lojasEncontradas.first.ip : null);
    final porta = portaServidor ??
        (lojasEncontradas.isNotEmpty ? lojasEncontradas.first.porta : null);
    if (ip != null && porta != null) {
      return await RelogioRedeService.instancia.sincronizarComServidor(
        ip: ip,
        porta: porta,
      );
    }
    return false;
  }
}
