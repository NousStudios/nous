import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';

/// Gerencia o anúncio periódico UDP (broadcast) na rede local
/// para que outros terminais descubram o servidor da loja/usuário automaticamente.
class AnunciadorUdpServidor {
  static const int portaUdpAnuncio = 45454;

  RawDatagramSocket? _socketUdp;
  Timer? _timerUdp;

  bool get ativo => _socketUdp != null;

  /// Retorna todos os endereços de broadcast IPv4 calculados para as interfaces ativas
  static Future<Set<String>> obterEnderecosBroadcastLocais([String? ipConhecido]) async {
    final destinos = <String>{'255.255.255.255'};
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.address.contains('.')) {
            final partes = addr.address.split('.');
            if (partes.length == 4) {
              destinos.add('${partes[0]}.${partes[1]}.${partes[2]}.255');
            }
          }
        }
      }
    } catch (_) {}

    if (ipConhecido != null && ipConhecido.contains('.')) {
      final partes = ipConhecido.split('.');
      if (partes.length == 4) {
        destinos.add('${partes[0]}.${partes[1]}.${partes[2]}.255');
      }
    }
    return destinos;
  }

  /// Inicia o broadcast UDP contínuo a cada 3 segundos
  Future<void> iniciar({
    required String? Function() obterIpServidor,
    required int Function() obterPorta,
    required Loja? Function() obterLojaAtiva,
    required String Function() obterNomeHost,
    required bool Function() servidorAtivo,
  }) async {
    parar();

    try {
      _socketUdp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _socketUdp!.broadcastEnabled = true;

      Set<String> destinosEmCache = {'255.255.255.255'};
      var ciclosAtualizacaoDestinos = 0;

      _timerUdp = Timer.periodic(const Duration(seconds: 3), (_) async {
        if (!servidorAtivo() || _socketUdp == null) return;
        try {
          final ipServidor = obterIpServidor();
          // Atualiza lista de broadcasts a cada 15s (5 ciclos de 3s)
          if (ciclosAtualizacaoDestinos++ % 5 == 0) {
            destinosEmCache = await obterEnderecosBroadcastLocais(ipServidor);
          }

          final lojaAtiva = obterLojaAtiva();
          final ehFalsa = lojaAtiva != null &&
              LojasService.ehLojaHostFalsa(lojaAtiva.id, lojaAtiva.tags, lojaAtiva.nome);
          final lojaValida = ehFalsa ? null : lojaAtiva;
          final nomeHost = obterNomeHost();

          final pacote = jsonEncode({
            'assinatura': 'nous_loja_anuncio',
            'lojaId': lojaValida?.id ?? '',
            'lojaNome': nomeHost,
            'tipoHost': lojaValida != null ? 'loja' : 'usuario',
            'ip': ipServidor,
            'porta': obterPorta(),
          });
          final bytes = utf8.encode(pacote);

          for (final dest in destinosEmCache) {
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
      debugPrint('[AnunciadorUdpServidor] Erro ao iniciar broadcast UDP: $e');
    }
  }

  /// Encerra socket e timer UDP
  void parar() {
    _timerUdp?.cancel();
    _timerUdp = null;

    try {
      _socketUdp?.close();
    } catch (_) {}
    _socketUdp = null;
  }
}
