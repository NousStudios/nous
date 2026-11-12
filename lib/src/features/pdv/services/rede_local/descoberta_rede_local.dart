import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nous/src/features/pdv/models/dispositivo_loja_info.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

/// Especialista em escuta passiva UDP e radar HTTP ativo para descoberta de balcões e nós Nous na rede local.
class DescobertaRedeLocal {
  RawDatagramSocket? _socketDescoberta;
  bool _varreduraAtiva = false;
  int _idVarredura = 0;

  final ValueNotifier<List<DispositivoLojaInfo>> lojasEncontradas;
  final void Function(DispositivoLojaInfo info) onServidorDescoberto;

  DescobertaRedeLocal({
    required this.lojasEncontradas,
    required this.onServidorDescoberto,
  });

  /// Inicia escuta UDP para encontrar servidores de lojas transmitindo no Wi-Fi
  /// acompanhada de radar ativo HTTP pela sub-rede local.
  Future<void> iniciarDescoberta() async {
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
      debugPrint('[DescobertaRedeLocal] Erro ao iniciar escuta UDP: $e');
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
        final tipoHost = json['tipoHost'] as String? ??
            (lojaIdStr.isNotEmpty ? 'loja' : 'usuario');
        final info = DispositivoLojaInfo(
          lojaId: lojaIdStr,
          lojaNome: (json['lojaNome'] as String?) ?? 'Usuário Nous',
          ip: json['ip'] as String,
          porta: json['porta'] as int,
          vistoEm: DateTime.now(),
          tipoHost: tipoHost,
        );
        adicionarOuAtualizarServidor(info);
      }
    } catch (_) {}
  }

  void adicionarOuAtualizarServidor(DispositivoLojaInfo info) {
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
    onServidorDescoberto(info);
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
        if (achou || !_varreduraAtiva || idAtual != _idVarredura) return;
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
      if (!_varreduraAtiva || idAtual != _idVarredura) break;

      const tamanhoLote = 25;
      for (int i = 0; i < todosHosts.length; i += tamanhoLote) {
        if (!_varreduraAtiva || idAtual != _idVarredura) break;
        final fim = (i + tamanhoLote < todosHosts.length) ? i + tamanhoLote : todosHosts.length;
        final lote = todosHosts.sublist(i, fim);

        final futuros = lote.map((host) {
          final ip = '$prefixo$host';
          return _testarIpServidorHttp(ip, ServidorRedeLocal.portaPadraoHttp);
        });

        final resultados = await Future.wait(futuros);
        if (resultados.any((r) => r == true)) {
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
          adicionarOuAtualizarServidor(info);
          return true;
        }
      }
    } catch (_) {}
    return false;
  }
}
