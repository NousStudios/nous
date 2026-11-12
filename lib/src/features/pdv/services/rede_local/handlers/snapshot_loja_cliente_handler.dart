import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:nous/src/core/utils/json_isolate_utils.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

/// Resultado da obtenção e consolidação inicial do snapshot da loja do balcão.
class ResultadoSnapshotLoja {
  final bool sucesso;
  final String? erro;
  final Loja? lojaConsolidada;
  final Loja? lojaBrutaParaReconciliar;
  final List<String> imagensAusentes;
  final List<String> fotosUsuariosAusentes;
  final List<TerminalConectadoInfo>? presencas;

  const ResultadoSnapshotLoja({
    required this.sucesso,
    this.erro,
    this.lojaConsolidada,
    this.lojaBrutaParaReconciliar,
    this.imagensAusentes = const [],
    this.fotosUsuariosAusentes = const [],
    this.presencas,
  });

  factory ResultadoSnapshotLoja.falha(String erro) =>
      ResultadoSnapshotLoja(sucesso: false, erro: erro);
}

/// Especialista em obter e processar o snapshot inicial da Loja e presenças via HTTP REST.
class SnapshotLojaClienteHandler {
  static Future<ResultadoSnapshotLoja> obterEConsolidarSnapshot({
    required String ipServidor,
    required int portaServidor,
    required String cpfLogado,
    required String? nomeUsuario,
    required String? apelidoUsuario,
    required String nomeDispositivo,
    required PdvProvider pdvProvider,
    required Future<void> Function(Loja loja) vincularLojaSeNecessario,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    final uriLoja = Uri(
      scheme: 'http',
      host: ipServidor,
      port: portaServidor,
      path: '/api/loja',
      queryParameters: {
        if (cpfLogado.isNotEmpty) 'cpf': cpfLogado,
        if (nomeUsuario != null && nomeUsuario.isNotEmpty) 'nome': nomeUsuario,
        if (apelidoUsuario != null && apelidoUsuario.isNotEmpty) 'apelido': apelidoUsuario,
        'dispositivo': nomeDispositivo,
      },
    );

    final request = await client.getUrl(uriLoja).timeout(const Duration(seconds: 4));
    final response = await request.close().timeout(const Duration(seconds: 4));

    if (response.statusCode == HttpStatus.forbidden) {
      debugPrint('[SnapshotLojaClienteHandler] Conexão recusada pelo Administrador do Balcão.');
      return ResultadoSnapshotLoja.falha('Conexão recusada pelo Administrador do Balcão.');
    }

    if (response.statusCode != HttpStatus.ok) {
      debugPrint(
        '[SnapshotLojaClienteHandler] Falha ao obter dados da loja HTTP ${response.statusCode}',
      );
      return ResultadoSnapshotLoja.falha(
        'Falha ao obter dados da loja (HTTP ${response.statusCode}).',
      );
    }

    final body = await utf8.decodeStream(response);
    final dados = await decodificarJsonMapaSeguro(body);

    Loja? lojaBrutaParaReconciliar;
    Loja? lojaConsolidadaFinal;
    List<String> imagensAusentes = [];
    List<String> fotosUsuariosAusentes = [];
    List<TerminalConectadoInfo>? presencas;

    if (dados['sucesso'] == true) {
      if (dados['loja'] != null) {
        final lojaBruta = Loja.fromJson(dados['loja'] as Map<String, dynamic>);
        if (!LojasService.ehLojaHostFalsa(lojaBruta.id, lojaBruta.tags, lojaBruta.nome)) {
          lojaBrutaParaReconciliar = lojaBruta;
          imagensAusentes = (dados['imagensAusentes'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList();

          final lojaLocalExistente = pdvProvider.buscarPorId(lojaBruta.id) ??
              await LojasService.carregarLojaPorId(lojaBruta.id);

          final consolidada = LojasService.consolidarLojaComImagensLocais(
            lojaBruta,
            lojaLocalExistente,
            manterItensAusentes: true,
          );

          lojaConsolidadaFinal = consolidada;
          await pdvProvider.adicionarOuAtualizarLoja(consolidada);
          await vincularLojaSeNecessario(consolidada);

          final notificacoesDispensadas = (dados['notificacoesDispensadasLoja'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList();
          if (notificacoesDispensadas != null && notificacoesDispensadas.isNotEmpty) {
            NotificacoesProvider.instanciaAtiva?.dispensarNotificacoesLoja(
              consolidada.id,
              notificacoesDispensadas,
              originadoDaRede: true,
            );
          }

          if (dados['fotosUsuariosAusentes'] != null) {
            fotosUsuariosAusentes = (dados['fotosUsuariosAusentes'] as List<dynamic>)
                .map((e) => e.toString())
                .toList();
          }
        }
      }

      if (dados['lojaNousColetiva'] != null) {
        try {
          final lojaNousBruta =
              Loja.fromJson(dados['lojaNousColetiva'] as Map<String, dynamic>);
          final lojaNousAtual =
              pdvProvider.buscarPorId(PdvProvider.idLojaColetivaNous);
          if (lojaNousAtual != null) {
            final membrosCombinados = <String, MembroLoja>{};
            for (final m in lojaNousAtual.membros) {
              membrosCombinados[m.cpf.replaceAll(RegExp(r'\D'), '')] = m;
            }
            for (final m in lojaNousBruta.membros) {
              final cpfNorm = m.cpf.replaceAll(RegExp(r'\D'), '');
              membrosCombinados[cpfNorm] = m;
            }
            final mesclada = lojaNousAtual.copyWith(
              membros: membrosCombinados.values.toList(),
            );
            await pdvProvider.adicionarOuAtualizarLoja(mesclada);
          } else {
            await pdvProvider.adicionarOuAtualizarLoja(lojaNousBruta);
          }
        } catch (_) {}
      }

      if (dados['presencas'] != null) {
        final lista = dados['presencas'] as List<dynamic>? ?? [];
        presencas = lista
            .map((e) => TerminalConectadoInfo.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    return ResultadoSnapshotLoja(
      sucesso: true,
      lojaConsolidada: lojaConsolidadaFinal,
      lojaBrutaParaReconciliar: lojaBrutaParaReconciliar,
      imagensAusentes: imagensAusentes,
      fotosUsuariosAusentes: fotosUsuariosAusentes,
      presencas: presencas,
    );
  }
}
