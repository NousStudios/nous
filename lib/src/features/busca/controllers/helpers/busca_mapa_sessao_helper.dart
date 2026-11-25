import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:nous/src/features/busca/controllers/busca_mapa_controller.dart';
import 'package:nous/src/features/busca/controllers/helpers/busca_mapa_coordenadas_helper.dart';
import 'package:nous/src/features/busca/controllers/helpers/busca_mapa_historico_helper.dart';
import 'package:nous/src/features/busca/controllers/helpers/busca_mapa_navegacao_helper.dart';
import 'package:nous/src/features/busca/services/mapa_espelhamento_service.dart';
import 'package:nous/src/features/busca/services/mapa_geo_service.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';

class BuscaMapaSessaoHelper {
  const BuscaMapaSessaoHelper._();

  static Future<void> recarregarDados(
    BuscaMapaController c,
    PdvProvider pdv, {
    bool tentarCentralizar = false,
    Loja? lojaDestinoInicial,
    required Map<String, String> assinaturasEnderecos,
    required bool Function() estaDisposto,
    required VoidCallback notificar,
    required void Function(LatLng destino, double zoom) onMoverCamera,
  }) async {
    c.lojas = BuscaMapaCoordenadasHelper.coletarLojasDisponiveis(pdv);

    final dadosIniciais =
        await BuscaMapaNavegacaoHelper.carregarDadosIniciais();
    c.usuarios = dadosIniciais.usuarios;
    c.projetos = dadosIniciais.projetos;
    c.publicacoes = dadosIniciais.publicacoes;

    c.carregando = false;
    c.compartilharLocalizacaoTempoReal =
        await BuscaMapaHistoricoHelper.carregarCompartilharLocalizacao();
    c.exibirLocalUsuario =
        await BuscaMapaHistoricoHelper.carregarExibirLocalUsuario();
    c.historicoBusca = await BuscaMapaHistoricoHelper.carregarHistorico();

    final ultimaPos = await BuscaMapaHistoricoHelper.carregarUltimaPosicao();
    if (ultimaPos != null && c.posicaoUsuario == null) {
      c.posicaoUsuario = ultimaPos.coordenada;
      c.origemRota = ultimaPos.coordenada;
      c.origemRotaLabel = 'Seu local';
      if (ultimaPos.resumo.isNotEmpty) {
        c.enderecoUsuarioResumo = ultimaPos.resumo;
      }
      if (tentarCentralizar && !estaDisposto() && lojaDestinoInicial == null) {
        onMoverCamera(ultimaPos.coordenada, 15.2);
      }
    }
    notificar();

    final pos = await MapaGeoService.obterPosicaoAtual();
    final posEfetiva = pos ?? MapaEspelhamentoService.instancia.ultimaPosicaoGpsRede;
    if (posEfetiva != null) {
      final mudouMuito = c.posicaoUsuario == null ||
          MapaGeoService.distanciaMetros(c.posicaoUsuario!, posEfetiva) > 35;
      c.posicaoUsuario = posEfetiva;
      c.origemRota = posEfetiva;
      c.origemRotaLabel = 'Seu local';
      if (tentarCentralizar && mudouMuito && !estaDisposto()) {
        onMoverCamera(posEfetiva, 15.2);
      }
      final resumoGpsRede = MapaEspelhamentoService.instancia.resumoGpsRede;
      c.enderecoUsuarioResumo = (pos == null && resumoGpsRede.isNotEmpty)
          ? resumoGpsRede
          : await MapaGeoService.obterEnderecoResumo(posEfetiva);
      unawaited(
        BuscaMapaHistoricoHelper.salvarUltimaPosicao(
          posEfetiva,
          c.enderecoUsuarioResumo,
        ),
      );
      if (pos != null) {
        MapaEspelhamentoService.instancia.publicarPosicaoGps(
          cpf: c.cpfAtivo,
          posicao: pos,
          resumo: c.enderecoUsuarioResumo,
        );
      }
      notificar();
    }

    if (lojaDestinoInicial != null && !estaDisposto()) {
      if (c.origemRota != null) {
        await BuscaMapaCoordenadasHelper.resolverRotaLojaInicial(
          lojaDestinoInicial,
          referencia: c.centroReferencia,
          enderecoUsuarioResumo: c.enderecoUsuarioResumo,
          coordenadasLojas: c.coordenadasLojas,
          estaDisposto: estaDisposto,
          onTracarRota: c.tracarRotaPara,
          onFalhaRota: () {
            c.calculandoRota = false;
            notificar();
          },
        );
      } else {
        // Sem posição conhecida (offline e sem GPS): foca na loja e pede ponto de partida.
        final coordDest =
            await BuscaMapaCoordenadasHelper.resolverCoordenadaLojaInicial(
          lojaDestinoInicial,
          referencia: c.centroReferencia,
          enderecoUsuarioResumo: c.enderecoUsuarioResumo,
        );
        if (!estaDisposto()) {
          if (coordDest != null) {
            c.coordenadasLojas[lojaDestinoInicial.id] = coordDest;
            c.destinoRota = coordDest;
            onMoverCamera(coordDest, 16.0);
          }
          c.origemRotaLabel = 'Informe seu ponto de partida';
          c.calculandoRota = false;
          notificar();
        }
      }
    }

    await BuscaMapaCoordenadasHelper.resolverCoordenadasLojas(
      lojas: c.lojas,
      coordenadasLojas: c.coordenadasLojas,
      assinaturasEnderecos: assinaturasEnderecos,
      obterReferencia: () => c.centroReferencia,
      obterEnderecoUsuarioResumo: () => c.enderecoUsuarioResumo,
      estaDisposto: estaDisposto,
      temPosicaoUsuario: () => c.posicaoUsuario != null,
      moverSeSemGps:
          tentarCentralizar && posEfetiva == null && lojaDestinoInicial == null,
      onMoverCamera: onMoverCamera,
      onAtualizarResumo: (resumo) {
        c.enderecoUsuarioResumo = resumo;
        notificar();
      },
    );
    notificar();
  }
}
