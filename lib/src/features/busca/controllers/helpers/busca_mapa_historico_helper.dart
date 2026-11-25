import 'dart:convert';

import 'package:latlong2/latlong.dart';
import 'package:nous/src/core/services/preferencias_soberanas_service.dart';
import 'package:nous/src/features/busca/controllers/helpers/busca_mapa_modelos.dart';

class UltimaPosicaoSalva {
  final LatLng coordenada;
  final String resumo;

  const UltimaPosicaoSalva({required this.coordenada, required this.resumo});
}

class BuscaMapaHistoricoHelper {
  const BuscaMapaHistoricoHelper._();

  static const String _chaveHistorico = 'mapa_historico_busca';
  static const String _chaveCompartilharLoc = 'mapa_compartilhar_localizacao';
  static const String _chaveExibirLocal = 'mapa_exibir_local_usuario';
  static const String _chaveUltimaPosicao = 'mapa_ultima_posicao';

  static Future<List<ItemHistoricoBuscaMapa>> carregarHistorico() async {
    try {
      final raw = await PreferenciasSoberanasService.obterTexto(_chaveHistorico);
      if (raw == null || raw.trim().isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map(
            (e) => ItemHistoricoBuscaMapa.fromJson(e as Map<String, dynamic>),
          )
          .where((e) => e.titulo.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<ItemHistoricoBuscaMapa>> registrarItem(
    List<ItemHistoricoBuscaMapa> atual,
    ItemHistoricoBuscaMapa item,
  ) async {
    final tituloLimpo = item.titulo.trim();
    if (tituloLimpo.isEmpty) return atual;
    final novaLista = List<ItemHistoricoBuscaMapa>.from(atual)
      ..removeWhere((e) => e.titulo.toLowerCase() == tituloLimpo.toLowerCase())
      ..insert(0, item);
    final limitada =
        novaLista.length > 10 ? novaLista.take(10).toList() : novaLista;
    await _salvarHistorico(limitada);
    return limitada;
  }

  static Future<List<ItemHistoricoBuscaMapa>> removerPorTitulo(
    List<ItemHistoricoBuscaMapa> atual,
    String titulo,
  ) async {
    final novaLista = List<ItemHistoricoBuscaMapa>.from(atual)
      ..removeWhere((e) => e.titulo == titulo);
    await _salvarHistorico(novaLista);
    return novaLista;
  }

  static Future<void> limparHistorico() async {
    await PreferenciasSoberanasService.salvarTexto(_chaveHistorico, '[]');
  }

  static Future<void> _salvarHistorico(
    List<ItemHistoricoBuscaMapa> itens,
  ) async {
    await PreferenciasSoberanasService.salvarTexto(
      _chaveHistorico,
      jsonEncode(itens.map((e) => e.toJson()).toList()),
    );
  }

  static Future<bool> carregarCompartilharLocalizacao() async {
    final prefComp = await PreferenciasSoberanasService.obterTexto(
      _chaveCompartilharLoc,
    );
    return prefComp == '1';
  }

  static Future<void> salvarCompartilharLocalizacao(bool valor) async {
    await PreferenciasSoberanasService.salvarTexto(
      _chaveCompartilharLoc,
      valor ? '1' : '0',
    );
  }

  static Future<bool> carregarExibirLocalUsuario() async {
    final pref = await PreferenciasSoberanasService.obterTexto(
      _chaveExibirLocal,
    );
    if (pref == null) return true;
    return pref == '1';
  }

  static Future<void> salvarExibirLocalUsuario(bool valor) async {
    await PreferenciasSoberanasService.salvarTexto(
      _chaveExibirLocal,
      valor ? '1' : '0',
    );
  }

  static Future<UltimaPosicaoSalva?> carregarUltimaPosicao() async {
    try {
      final raw =
          await PreferenciasSoberanasService.obterTexto(_chaveUltimaPosicao);
      if (raw == null || raw.trim().isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final lat = (map['lat'] as num?)?.toDouble();
      final lng = (map['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      final resumo = (map['resumo'] as String? ?? '').trim();
      return UltimaPosicaoSalva(
        coordenada: LatLng(lat, lng),
        resumo: resumo,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> salvarUltimaPosicao(LatLng pos, String resumo) async {
    await PreferenciasSoberanasService.salvarTexto(
      _chaveUltimaPosicao,
      jsonEncode({
        'lat': pos.latitude,
        'lng': pos.longitude,
        'resumo': resumo,
      }),
    );
  }
}
