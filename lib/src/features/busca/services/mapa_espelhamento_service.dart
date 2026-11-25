import 'dart:io';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:nous/src/core/services/navigator_key_service.dart';
import 'package:nous/src/features/busca/models/resultado_rota_mapa.dart';
import 'package:nous/src/features/busca/services/mapa_geo_service.dart';
import 'package:nous/src/features/busca/views/busca_mapa_view.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

class EstadoNavegacaoEspelhada {
  final String cpf;
  final bool ativo;
  final String emissorId;
  final LatLng? origem;
  final String origemLabel;
  final LatLng? destino;
  final String destinoLabel;
  final LatLng? atual;
  final double heading;
  final double distanciaMetros;
  final double duracaoSegundos;
  final List<LatLng> pontos;
  final int atualizadoEm;

  const EstadoNavegacaoEspelhada({
    required this.cpf,
    required this.ativo,
    required this.emissorId,
    this.origem,
    this.origemLabel = '',
    this.destino,
    this.destinoLabel = '',
    this.atual,
    this.heading = 0.0,
    this.distanciaMetros = 0.0,
    this.duracaoSegundos = 0.0,
    this.pontos = const [],
    required this.atualizadoEm,
  });

  ResultadoRotaMapa? toResultadoRota() {
    if (pontos.length < 2) return null;
    return ResultadoRotaMapa(
      pontos: pontos,
      distanciaMetros: distanciaMetros,
      duracaoSegundos: duracaoSegundos,
      origemLabel: origemLabel,
      destinoLabel: destinoLabel,
    );
  }

  Map<String, dynamic> toJson() => {
        'tipo': 'mapa_navegacao_sync',
        'cpf': cpf,
        'ativo': ativo,
        'emissorId': emissorId,
        if (origem != null) 'origemLat': origem!.latitude,
        if (origem != null) 'origemLng': origem!.longitude,
        'origemLabel': origemLabel,
        if (destino != null) 'destinoLat': destino!.latitude,
        if (destino != null) 'destinoLng': destino!.longitude,
        'destinoLabel': destinoLabel,
        if (atual != null) 'atualLat': atual!.latitude,
        if (atual != null) 'atualLng': atual!.longitude,
        'heading': heading,
        'distanciaMetros': distanciaMetros,
        'duracaoSegundos': duracaoSegundos,
        'pontos': pontos
            .map((p) => [p.latitude, p.longitude])
            .toList(growable: false),
        'atualizadoEm': atualizadoEm,
      };

  factory EstadoNavegacaoEspelhada.fromJson(Map<String, dynamic> json) {
    LatLng? lerPonto(String latKey, String lngKey) {
      final lat = (json[latKey] as num?)?.toDouble();
      final lng = (json[lngKey] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      return LatLng(lat, lng);
    }

    final ptsRaw = json['pontos'] as List<dynamic>? ?? const [];
    final pts = <LatLng>[];
    for (final item in ptsRaw) {
      if (item is List && item.length >= 2) {
        final lat = (item[0] as num?)?.toDouble();
        final lng = (item[1] as num?)?.toDouble();
        if (lat != null && lng != null) {
          pts.add(LatLng(lat, lng));
        }
      }
    }

    return EstadoNavegacaoEspelhada(
      cpf: (json['cpf'] ?? '').toString(),
      ativo: json['ativo'] == true,
      emissorId: (json['emissorId'] ?? '').toString(),
      origem: lerPonto('origemLat', 'origemLng'),
      origemLabel: (json['origemLabel'] ?? '').toString(),
      destino: lerPonto('destinoLat', 'destinoLng'),
      destinoLabel: (json['destinoLabel'] ?? '').toString(),
      atual: lerPonto('atualLat', 'atualLng'),
      heading: (json['heading'] as num?)?.toDouble() ?? 0.0,
      distanciaMetros: (json['distanciaMetros'] as num?)?.toDouble() ?? 0.0,
      duracaoSegundos: (json['duracaoSegundos'] as num?)?.toDouble() ?? 0.0,
      pontos: pts,
      atualizadoEm: (json['atualizadoEm'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Serviço singleton responsável por espelhar a navegação do mapa em tempo real
/// entre dispositivos autenticados com o mesmo CPF na rede local.
class MapaEspelhamentoService extends ChangeNotifier {
  MapaEspelhamentoService._();
  static final MapaEspelhamentoService instancia = MapaEspelhamentoService._();

  final String _emissorId =
      'dev_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  EstadoNavegacaoEspelhada? _estadoRemoto;
  EstadoNavegacaoEspelhada? get estadoRemoto => _estadoRemoto;

  LatLng? _ultimaPosicaoGpsRede;
  String _resumoGpsRede = '';
  LatLng? get ultimaPosicaoGpsRede => _ultimaPosicaoGpsRede;
  String get resumoGpsRede => _resumoGpsRede;

  static String _normCpf(String? cpf) =>
      (cpf ?? '').replaceAll(RegExp(r'\D'), '');

  void _despacharNaRede(Map<String, dynamic> payload) {
    final servidor = ServidorRedeLocal();
    if (servidor.ativo) {
      servidor.notificarTodos(payload);
    }
    final cliente = ClienteRedeLocal();
    if (cliente.conectado) {
      cliente.enviarEventoWs(payload);
    }
  }

  /// Compartilha a posição GPS precisa do celular na rede local com outros aparelhos do mesmo CPF.
  void publicarPosicaoGps({
    required String cpf,
    required LatLng posicao,
    String resumo = '',
  }) {
    final cpfNorm = _normCpf(cpf);
    if (cpfNorm.isEmpty) return;

    _despacharNaRede({
      'tipo': 'mapa_posicao_gps',
      'cpf': cpfNorm,
      'emissorId': _emissorId,
      'lat': posicao.latitude,
      'lng': posicao.longitude,
      'resumo': resumo,
      'atualizadoEm': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Se estiver rodando em celular (Android/iOS), lê o GPS real e envia para o computador na rede.
  Future<void> enviarPosicaoAtualSeMobile(String? cpf) async {
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    final cpfNorm = _normCpf(cpf);
    if (cpfNorm.isEmpty) return;
    try {
      final pos = await MapaGeoService.obterPosicaoAtual();
      if (pos == null) return;
      final resumo = await MapaGeoService.obterEnderecoResumo(pos);
      publicarPosicaoGps(cpf: cpfNorm, posicao: pos, resumo: resumo);
    } catch (_) {}
  }

  void publicarNavegacao({
    required String cpf,
    required bool ativo,
    LatLng? origem,
    String origemLabel = '',
    LatLng? destino,
    String destinoLabel = '',
    LatLng? atual,
    double heading = 0.0,
    ResultadoRotaMapa? rota,
  }) {
    final cpfNorm = _normCpf(cpf);
    if (cpfNorm.isEmpty) return;

    final payload = EstadoNavegacaoEspelhada(
      cpf: cpfNorm,
      ativo: ativo,
      emissorId: _emissorId,
      origem: origem,
      origemLabel: origemLabel,
      destino: destino,
      destinoLabel: destinoLabel,
      atual: atual,
      heading: heading,
      distanciaMetros: rota?.distanciaMetros ?? 0.0,
      duracaoSegundos: rota?.duracaoSegundos ?? 0.0,
      pontos: rota?.pontos ?? const [],
      atualizadoEm: DateTime.now().millisecondsSinceEpoch,
    ).toJson();

    _despacharNaRede(payload);
  }

  void receberEventoRede(Map<String, dynamic> dados, String? cpfLocal) {
    final cpfLocalNorm = _normCpf(cpfLocal);
    if (cpfLocalNorm.isEmpty) return;

    final tipo = dados['tipo'] as String?;
    if (tipo == 'mapa_posicao_gps') {
      final emissor = (dados['emissorId'] ?? '').toString();
      if (emissor == _emissorId) return;
      if (_normCpf(dados['cpf']?.toString()) != cpfLocalNorm) return;
      final lat = (dados['lat'] as num?)?.toDouble();
      final lng = (dados['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return;
      _ultimaPosicaoGpsRede = LatLng(lat, lng);
      _resumoGpsRede = (dados['resumo'] ?? '').toString();
      notifyListeners();
      return;
    }

    final recebido = EstadoNavegacaoEspelhada.fromJson(dados);
    if (recebido.emissorId == _emissorId) return;
    if (_normCpf(recebido.cpf) != cpfLocalNorm) return;
    if (recebido.atual != null) {
      _ultimaPosicaoGpsRede = recebido.atual;
    }

    final estavaAtivo = _estadoRemoto?.ativo == true;
    _estadoRemoto = recebido;
    notifyListeners();

    if (recebido.ativo && !estavaAtivo && !BuscaMapaView.telaAberta) {
      final nav = NavigatorKeyService.navigatorKey.currentState;
      if (nav != null) {
        nav.push(
          MaterialPageRoute(
            builder: (_) => const BuscaMapaView(),
          ),
        );
      }
    }
  }

  void limparEstadoRemoto() {
    _estadoRemoto = null;
  }
}
