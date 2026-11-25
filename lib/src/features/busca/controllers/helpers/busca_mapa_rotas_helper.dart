import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:nous/src/features/busca/controllers/busca_mapa_controller.dart';
import 'package:nous/src/features/busca/controllers/helpers/busca_mapa_coordenadas_helper.dart';
import 'package:nous/src/features/busca/controllers/helpers/busca_mapa_navegacao_helper.dart';
import 'package:nous/src/features/busca/controllers/helpers/busca_mapa_projetos_helper.dart';
import 'package:nous/src/features/busca/models/projeto_comunitario.dart';
import 'package:nous/src/features/busca/services/mapa_espelhamento_service.dart';
import 'package:nous/src/features/busca/services/mapa_geo_service.dart';

class BuscaMapaRotasHelper {
  const BuscaMapaRotasHelper._();

  static void _moverCameraSuave(
    BuscaMapaController c,
    LatLng destino,
    double zoom, {
    required bool Function() estaDisposto,
    double? rotacaoGraus,
  }) {
    if (estaDisposto()) return;
    BuscaMapaNavegacaoHelper.moverCamera(
      c.mapController,
      destino,
      zoom,
      onAnimarCamera: c.onAnimarCamera,
      rotacaoGraus: rotacaoGraus,
    );
  }

  static void _moverCameraNavegacao(
    BuscaMapaController c,
    LatLng alvo, {
    required bool Function() estaDisposto,
  }) {
    _moverCameraSuave(
      c,
      alvo,
      18.6,
      estaDisposto: estaDisposto,
      rotacaoGraus: c.mapaFixoAoNorte ? 0.0 : -c.rumoUsuarioGraus,
    );
  }

  static void _publicarEspelhamento(
    BuscaMapaController c, {
    required bool ativo,
  }) {
    BuscaMapaNavegacaoHelper.publicarEspelhamento(
      cpfAtivo: c.cpfAtivo,
      ativo: ativo,
      origem: c.origemRota,
      origemLabel: c.origemRotaLabel,
      destino: c.destinoRota,
      destinoLabel: c.destinoRotaLabel,
      posicaoUsuario: c.posicaoUsuario,
      heading: c.rumoUsuarioGraus,
      rota: c.rotaAtual,
    );
  }

  static void atualizarPosicaoTempoReal(
    BuscaMapaController c,
    LatLng pos, {
    double? headingGraus,
    required bool Function() estaDisposto,
    required VoidCallback notificar,
    required DateTime? ultimoRecalculoRota,
    required void Function(DateTime) onAtualizarUltimoRecalculo,
  }) {
    final anterior = c.posicaoUsuario;
    c.posicaoUsuario = pos;
    if (headingGraus != null && headingGraus >= 0) {
      c.rumoUsuarioGraus = headingGraus;
    } else if (anterior != null &&
        MapaGeoService.distanciaMetros(anterior, pos) > 3) {
      c.rumoUsuarioGraus =
          BuscaMapaCoordenadasHelper.calcularAzimuteGraus(anterior, pos);
    }

    if (c.navegandoAoVivo) {
      final rota = c.rotaAtual;
      if (rota != null) {
        final progresso = BuscaMapaNavegacaoHelper.calcularProgressoPasso(
          rota,
          pos,
          c.indicePassoAtual,
        );
        c.indicePassoAtual = progresso.indice;
        c.distanciaProximoPassoMetros = progresso.distanciaMetros;

        final desvio = BuscaMapaNavegacaoHelper.distanciaMinimaAteRota(
          pos,
          rota.pontos,
        );
        final agora = DateTime.now();
        final podeRecalcular = ultimoRecalculoRota == null ||
            agora.difference(ultimoRecalculoRota).inSeconds >= 10;
        if (desvio > 45.0 &&
            podeRecalcular &&
            !c.modoEspelhadoRemoto &&
            c.destinoRota != null) {
          onAtualizarUltimoRecalculo(agora);
          c.origemRota = pos;
          unawaited(
            tracarRotaPara(
              c,
              destino: c.destinoRota!,
              destinoLabel: c.destinoRotaLabel,
              manterNavegacaoAtiva: true,
              estaDisposto: estaDisposto,
              notificar: notificar,
            ),
          );
        }
      }
      if (c.seguirCameraNaNavegacao) {
        _moverCameraNavegacao(c, pos, estaDisposto: estaDisposto);
      }
      if (!c.modoEspelhadoRemoto) {
        _publicarEspelhamento(c, ativo: true);
      }
    }
    notificar();
  }

  static void alternarNavegacaoAoVivo(
    BuscaMapaController c, {
    required bool Function() estaDisposto,
    required VoidCallback notificar,
  }) {
    c.navegandoAoVivo = !c.navegandoAoVivo;
    c.modoEspelhadoRemoto = false;
    c.seguirCameraNaNavegacao = true;
    c.indicePassoAtual = 0;
    c.distanciaProximoPassoMetros = null;
    c.painelBuscaExpandido = false;
    if (c.navegandoAoVivo) {
      final pts = c.rotaAtual?.pontos ?? const [];
      if (pts.length >= 2) {
        c.rumoUsuarioGraus =
            BuscaMapaCoordenadasHelper.calcularAzimuteGraus(pts[0], pts[1]);
      }
      _moverCameraNavegacao(
        c,
        c.posicaoUsuario ?? (pts.isNotEmpty ? pts.first : c.centroReferencia),
        estaDisposto: estaDisposto,
      );
      _publicarEspelhamento(c, ativo: true);
    } else {
      _publicarEspelhamento(c, ativo: false);
      _moverCameraSuave(
        c,
        c.posicaoUsuario ?? c.centroReferencia,
        15.8,
        estaDisposto: estaDisposto,
        rotacaoGraus: 0.0,
      );
    }
    notificar();
  }

  static void aplicarEstadoEspelhado(
    BuscaMapaController c,
    EstadoNavegacaoEspelhada estado, {
    required bool Function() estaDisposto,
    required VoidCallback notificar,
  }) {
    if (estaDisposto()) return;
    if (estado.ativo) {
      final eraAtivo = c.navegandoAoVivo;
      c.modoEspelhadoRemoto = true;
      c.modoRota = true;
      c.navegandoAoVivo = true;
      c.painelBuscaExpandido = false;
      c.origemRota = estado.origem ?? c.origemRota;
      c.origemRotaLabel = estado.origemLabel;
      c.destinoRota = estado.destino ?? c.destinoRota;
      c.destinoRotaLabel = estado.destinoLabel;
      final rotaEspelhada = estado.toResultadoRota();
      if (rotaEspelhada != null) {
        c.rotaAtual = rotaEspelhada;
        if (!eraAtivo) c.onRotaCalculada?.call();
      }
      if (estado.atual != null) {
        c.posicaoUsuario = estado.atual;
      }
      c.rumoUsuarioGraus = estado.heading;
      _moverCameraNavegacao(
        c,
        c.posicaoUsuario ??
            (c.rotaAtual?.pontos.isNotEmpty == true
                ? c.rotaAtual!.pontos.first
                : c.centroReferencia),
        estaDisposto: estaDisposto,
      );
      notificar();
    } else if (c.modoEspelhadoRemoto) {
      fecharModoRota(c, notificar: notificar);
      _moverCameraSuave(
        c,
        c.posicaoUsuario ?? c.centroReferencia,
        15.8,
        estaDisposto: estaDisposto,
        rotacaoGraus: 0.0,
      );
    }
  }

  static void abrirModoRota(
    BuscaMapaController c, {
    required VoidCallback notificar,
  }) {
    c.modoRota = true;
    c.painelBuscaExpandido = false;
    c.origemRota ??= c.centroReferencia;
    c.origemRotaLabel =
        c.posicaoUsuario != null ? 'Seu local' : c.enderecoUsuarioResumo;
    notificar();
  }

  static void fecharModoRota(
    BuscaMapaController c, {
    required VoidCallback notificar,
  }) {
    final estavaNavegando = c.navegandoAoVivo && !c.modoEspelhadoRemoto;
    c.modoRota = false;
    c.navegandoAoVivo = false;
    c.modoEspelhadoRemoto = false;
    c.rotaAtual = null;
    c.destinoRota = null;
    c.destinoRotaLabel = '';
    if (estavaNavegando) {
      _publicarEspelhamento(c, ativo: false);
    }
    notificar();
  }

  static Future<void> tracarRotaPara(
    BuscaMapaController c, {
    required LatLng destino,
    required String destinoLabel,
    bool manterNavegacaoAtiva = false,
    required bool Function() estaDisposto,
    required VoidCallback notificar,
  }) async {
    c.modoRota = true;
    c.painelBuscaExpandido = false;
    c.limparSelecaoEntidade();
    final origem = c.origemRota ?? c.centroReferencia;
    c.origemRota = origem;
    c.destinoRota = destino;
    c.destinoRotaLabel = destinoLabel;
    c.calculandoRota = true;
    notificar();

    final rota = await MapaGeoService.calcularRota(
      origem: origem,
      destino: destino,
      origemLabel: c.origemRotaLabel,
      destinoLabel: destinoLabel,
    );
    if (estaDisposto()) return;
    c.rotaAtual = rota;
    c.indicePassoAtual = 0;
    c.distanciaProximoPassoMetros = null;
    c.calculandoRota = false;

    if (!manterNavegacaoAtiva) {
      BuscaMapaNavegacaoHelper.ajustarCameraParaRota(c.mapController, rota);
    } else if (!c.modoEspelhadoRemoto) {
      _publicarEspelhamento(c, ativo: true);
    }
    c.onRotaCalculada?.call();
    notificar();
  }

  static Future<void> inverterOrigemDestino(
    BuscaMapaController c, {
    required bool Function() estaDisposto,
    required VoidCallback notificar,
  }) async {
    if (c.origemRota == null || c.destinoRota == null) return;
    final tmpCoord = c.origemRota!;
    final tmpLabel = c.origemRotaLabel;
    c.origemRota = c.destinoRota;
    c.origemRotaLabel = c.destinoRotaLabel;
    await tracarRotaPara(
      c,
      destino: tmpCoord,
      destinoLabel: tmpLabel,
      estaDisposto: estaDisposto,
      notificar: notificar,
    );
  }

  static Future<void> criarProjeto(
    BuscaMapaController c,
    ProjetoComunitario projeto,
  ) async {
    c.projetos = await BuscaMapaProjetosHelper.criarProjeto(c.projetos, projeto);
    c.selecionarProjeto(projeto);
  }

  static Future<void> alternarApoioProjeto(
    BuscaMapaController c,
    ProjetoComunitario projeto,
    String cpfUsuario, {
    required VoidCallback notificar,
  }) async {
    final res = await BuscaMapaProjetosHelper.alternarApoio(
      c.projetos,
      projeto,
      cpfUsuario,
    );
    _aplicarAtualizacaoProjeto(c, res.lista, res.atualizado, notificar);
  }

  static Future<void> assumirProjeto(
    BuscaMapaController c,
    ProjetoComunitario projeto,
    String cpfUsuario,
    String nomeUsuario, {
    required VoidCallback notificar,
  }) async {
    final res = await BuscaMapaProjetosHelper.assumirProjeto(
      c.projetos,
      projeto,
      cpfUsuario,
      nomeUsuario,
    );
    _aplicarAtualizacaoProjeto(c, res.lista, res.atualizado, notificar);
  }

  static Future<void> concluirProjeto(
    BuscaMapaController c,
    ProjetoComunitario projeto, {
    required VoidCallback notificar,
  }) async {
    final res = await BuscaMapaProjetosHelper.concluirProjeto(
      c.projetos,
      projeto,
    );
    _aplicarAtualizacaoProjeto(c, res.lista, res.atualizado, notificar);
  }

  static void _aplicarAtualizacaoProjeto(
    BuscaMapaController c,
    List<ProjetoComunitario> novaLista,
    ProjetoComunitario atualizado,
    VoidCallback notificar,
  ) {
    c.projetos = novaLista;
    if (c.projetoSelecionado?.id == atualizado.id) {
      c.projetoSelecionado = atualizado;
    }
    notificar();
  }
}
