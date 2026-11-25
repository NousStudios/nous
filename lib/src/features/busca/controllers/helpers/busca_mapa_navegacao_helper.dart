import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/busca/controllers/helpers/busca_mapa_coordenadas_helper.dart';
import 'package:nous/src/features/busca/models/projeto_comunitario.dart';
import 'package:nous/src/features/busca/models/resultado_rota_mapa.dart';
import 'package:nous/src/features/busca/services/mapa_espelhamento_service.dart';
import 'package:nous/src/features/busca/services/mapa_geo_service.dart';
import 'package:nous/src/features/busca/services/projetos_comunitarios_service.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';

class DadosIniciaisMapa {
  final List<UsuarioNous> usuarios;
  final List<ProjetoComunitario> projetos;
  final List<PublicacaoSocial> publicacoes;

  const DadosIniciaisMapa({
    required this.usuarios,
    required this.projetos,
    required this.publicacoes,
  });
}

class BuscaMapaNavegacaoHelper {
  const BuscaMapaNavegacaoHelper._();

  static Future<DadosIniciaisMapa> carregarDadosIniciais() async {
    final results = await Future.wait<dynamic>([
      ContasNousService.carregarTodas(),
      ProjetosComunitariosService.listarTodos(),
      TimelineService.listarPublicacoesDescoberta(limit: 80),
    ]);

    return DadosIniciaisMapa(
      usuarios: BuscaMapaCoordenadasHelper.filtrarUsuariosValidos(
        results[0] as List<UsuarioNous>,
      ),
      projetos: results[1] as List<ProjetoComunitario>,
      publicacoes: results[2] as List<PublicacaoSocial>,
    );
  }

  static EstadoNavegacaoEspelhada? obterEspelhoAtivo() {
    final espelho = MapaEspelhamentoService.instancia.estadoRemoto;
    if (espelho != null && espelho.ativo) return espelho;
    return null;
  }

  static void publicarEspelhamento({
    required String cpfAtivo,
    required bool ativo,
    required LatLng? origem,
    required String origemLabel,
    required LatLng? destino,
    required String destinoLabel,
    required LatLng? posicaoUsuario,
    required double heading,
    required ResultadoRotaMapa? rota,
  }) {
    if (cpfAtivo.trim().isEmpty) return;
    MapaEspelhamentoService.instancia.publicarNavegacao(
      cpf: cpfAtivo,
      ativo: ativo,
      origem: origem,
      origemLabel: origemLabel,
      destino: destino,
      destinoLabel: destinoLabel,
      atual: posicaoUsuario ?? origem,
      heading: heading,
      rota: rota,
    );
  }

  static void moverCamera(
    MapController mapController,
    LatLng destino,
    double zoom, {
    void Function(LatLng destino, double zoom, {double? rotacaoGraus})?
        onAnimarCamera,
    double? rotacaoGraus,
  }) {
    if (onAnimarCamera != null) {
      onAnimarCamera(destino, zoom, rotacaoGraus: rotacaoGraus);
      return;
    }
    try {
      if (rotacaoGraus != null) {
        mapController.moveAndRotate(destino, zoom, rotacaoGraus);
      } else {
        mapController.move(destino, zoom);
      }
    } catch (_) {}
  }

  static void ajustarCameraParaRota(
    MapController mapController,
    ResultadoRotaMapa rota,
  ) {
    try {
      final bounds = LatLngBounds.fromPoints(rota.pontos);
      mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(54, 190, 54, 150),
        ),
      );
    } catch (_) {}
  }

  static ({int indice, double distanciaMetros}) calcularProgressoPasso(
    ResultadoRotaMapa rota,
    LatLng posAtual,
    int indiceAtual,
  ) {
    final passos = rota.passos;
    if (passos.isEmpty) {
      return (indice: 0, distanciaMetros: rota.distanciaMetros);
    }
    var idx = indiceAtual.clamp(0, passos.length - 1);
    while (idx < passos.length - 1) {
      final coord = passos[idx].coordenada;
      if (coord == null) break;
      final dist = MapaGeoService.distanciaMetros(posAtual, coord);
      if (dist <= 24.0) {
        idx++;
      } else {
        break;
      }
    }
    final coordAlvo = passos[idx].coordenada;
    final distManobra = coordAlvo != null
        ? MapaGeoService.distanciaMetros(posAtual, coordAlvo)
        : passos[idx].distanciaMetros;
    return (indice: idx, distanciaMetros: distManobra);
  }

  static double distanciaMinimaAteRota(LatLng pos, List<LatLng> pontos) {
    if (pontos.isEmpty) return 0.0;
    var menor = double.infinity;
    final passo = pontos.length > 120 ? 2 : 1;
    for (var i = 0; i < pontos.length; i += passo) {
      final d = MapaGeoService.distanciaMetros(pos, pontos[i]);
      if (d < menor) menor = d;
    }
    return menor.isFinite ? menor : 0.0;
  }
}
