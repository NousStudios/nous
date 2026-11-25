import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/busca/services/mapa_geo_service.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';

class BuscaMapaCoordenadasHelper {
  const BuscaMapaCoordenadasHelper._();

  /// Somente lojas físicas reais devidamente configuradas em Dados da Loja
  /// devem aparecer no mapa (exclui a loja coletiva Nous e cadastros incompletos).
  static bool lojaAptaParaMapa(Loja loja) {
    if (loja.id == PdvProvider.idLojaColetivaNous) return false;
    final nomeNorm = loja.nome.trim().toLowerCase();
    if (nomeNorm == 'nous') return false;
    final temEndereco = loja.endereco.trim().length >= 3;
    final temNumero = loja.numero.trim().isNotEmpty;
    final cepDigitos = loja.cep.replaceAll(RegExp(r'\D'), '');
    final temCidadeOuCep =
        loja.cidade.trim().isNotEmpty || cepDigitos.length == 8;
    return temEndereco && temNumero && temCidadeOuCep;
  }

  static double calcularAzimuteGraus(LatLng de, LatLng para) {
    final lat1 = de.latitude * math.pi / 180.0;
    final lat2 = para.latitude * math.pi / 180.0;
    final dLon = (para.longitude - de.longitude) * math.pi / 180.0;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final brng = math.atan2(y, x) * 180.0 / math.pi;
    return (brng + 360.0) % 360.0;
  }

  static List<Loja> coletarLojasDisponiveis(PdvProvider pdv) {
    final mapaLojas = <String, Loja>{};
    for (final l in pdv.lojas) {
      mapaLojas[l.id] = l;
    }
    final lojaRemota = ClienteRedeLocal().lojaSincronizada;
    if (lojaRemota != null) {
      mapaLojas.putIfAbsent(lojaRemota.id, () => lojaRemota);
    }
    return mapaLojas.values.toList();
  }

  static List<UsuarioNous> filtrarUsuariosValidos(List<UsuarioNous> contas) {
    return contas.where((u) {
      final cpfLimpo = u.cpf.replaceAll(RegExp(r'\D'), '');
      return cpfLimpo.length == 11 &&
          u.nome.trim().toLowerCase() != 'blackview' &&
          u.nome.trim().toLowerCase() != 'celular';
    }).toList();
  }

  static Future<LatLng?> resolverCoordenadaLojaInicial(
    Loja loja, {
    required LatLng referencia,
    required String enderecoUsuarioResumo,
  }) async {
    if (loja.latitude != null && loja.longitude != null) {
      return LatLng(loja.latitude!, loja.longitude!);
    }
    if (loja.endereco.trim().isEmpty && loja.cep.trim().isEmpty) {
      return null;
    }
    final cidadeRef =
        MapaGeoService.extrairCidadeDeResumo(enderecoUsuarioResumo);
    final consulta = [
      loja.endereco.trim(),
      loja.numero.trim(),
      loja.cidade.trim(),
      loja.cep.trim(),
    ].where((e) => e.isNotEmpty).join(', ');

    return MapaGeoService.geocodificarEndereco(
      consulta,
      referencia: referencia,
      cidadeFallback:
          loja.cidade.trim().isNotEmpty ? loja.cidade.trim() : cidadeRef,
    );
  }

  static Future<List<EnderecoGeocodificado>> buscarEnderecos(
    String texto, {
    required LatLng referencia,
    required String enderecoUsuarioResumo,
  }) {
    return MapaGeoService.buscarEnderecos(
      texto,
      referencia: referencia,
      cidadeReferencia:
          MapaGeoService.extrairCidadeDeResumo(enderecoUsuarioResumo),
    );
  }

  static Future<void> resolverRotaLojaInicial(
    Loja lojaDestinoInicial, {
    required LatLng referencia,
    required String enderecoUsuarioResumo,
    required Map<String, LatLng> coordenadasLojas,
    required bool Function() estaDisposto,
    required Future<void> Function({
      required LatLng destino,
      required String destinoLabel,
    }) onTracarRota,
    required VoidCallback onFalhaRota,
  }) async {
    final coordDest = await resolverCoordenadaLojaInicial(
      lojaDestinoInicial,
      referencia: referencia,
      enderecoUsuarioResumo: enderecoUsuarioResumo,
    );
    if (estaDisposto()) return;
    if (coordDest != null) {
      coordenadasLojas[lojaDestinoInicial.id] = coordDest;
      await onTracarRota(
        destino: coordDest,
        destinoLabel: lojaDestinoInicial.nome,
      );
    } else {
      onFalhaRota();
    }
  }

  static Future<void> resolverCoordenadasLojas({
    required List<Loja> lojas,
    required Map<String, LatLng> coordenadasLojas,
    required Map<String, String> assinaturasEnderecos,
    required LatLng Function() obterReferencia,
    required String Function() obterEnderecoUsuarioResumo,
    required bool Function() estaDisposto,
    required bool Function() temPosicaoUsuario,
    required bool moverSeSemGps,
    required void Function(LatLng destino, double zoom) onMoverCamera,
    required void Function(String resumo) onAtualizarResumo,
  }) async {
    bool algumaAtualizada = false;
    for (final loja in lojas) {
      if (!lojaAptaParaMapa(loja)) {
        coordenadasLojas.remove(loja.id);
        assinaturasEnderecos.remove(loja.id);
        continue;
      }
      if (loja.latitude != null && loja.longitude != null) {
        coordenadasLojas[loja.id] = LatLng(loja.latitude!, loja.longitude!);
        continue;
      }
      final end = loja.endereco.trim();
      final numStr = loja.numero.trim();
      final cidStr = loja.cidade.trim();
      final cepStr = loja.cep.trim();
      final assinatura = '$end|$numStr|$cidStr|$cepStr';
      if (assinaturasEnderecos[loja.id] == assinatura &&
          coordenadasLojas.containsKey(loja.id)) {
        continue;
      }
      assinaturasEnderecos[loja.id] = assinatura;
      coordenadasLojas.remove(loja.id);
      final consulta = [end, numStr, cidStr, cepStr]
          .where((e) => e.isNotEmpty)
          .join(', ');
      final coord = await MapaGeoService.geocodificarEndereco(
        consulta,
        referencia: obterReferencia(),
        cidadeFallback: cidStr.isNotEmpty
            ? cidStr
            : MapaGeoService.extrairCidadeDeResumo(obterEnderecoUsuarioResumo()),
      );
      if (coord != null) {
        coordenadasLojas[loja.id] = coord;
        algumaAtualizada = true;
      }
    }
    if ((moverSeSemGps || algumaAtualizada) &&
        coordenadasLojas.isNotEmpty &&
        !estaDisposto() &&
        !temPosicaoUsuario()) {
      final primeira = coordenadasLojas.values.first;
      onMoverCamera(primeira, 15.5);
      unawaited(
        MapaGeoService.obterEnderecoResumo(primeira).then((resumo) {
          if (!temPosicaoUsuario()) {
            onAtualizarResumo(resumo);
          }
        }),
      );
    }
  }
}
