import 'package:flutter/foundation.dart';
import 'package:nous/src/core/services/gerador_id.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/models/salvos_denuncia_social.dart';
import 'package:nous/src/features/timeline/services/timeline_repositorio_sqlite.dart';
import 'package:nous/src/features/timeline/services/timeline_sync_service.dart';

/// Serviço especializado em conteúdos salvos, listas de salvos,
/// denúncias e abas/feed de descoberta.
class TimelineSalvosDenunciasService {
  TimelineSalvosDenunciasService._();

  static Future<ListaSalvosSocial> obterOuCriarListaPadraoSalvos(
    String cpf,
  ) async {
    final cpfNorm = TimelineRepositorioSqlite.normalizarCpf(cpf);
    final listas =
        await TimelineRepositorioSqlite.listarListasSalvosDoUsuario(cpfNorm);
    final padrao = listas
        .where((l) => l.visibilidade == VisibilidadeListaSalvos.publicaFeed)
        .firstOrNull;
    if (padrao != null) return padrao;

    final nova = ListaSalvosSocial(
      id: 'lista_padrao_$cpfNorm',
      donoCpf: cpfNorm,
      nome: 'Conteúdos Salvos',
      visibilidade: VisibilidadeListaSalvos.publicaFeed,
      criadaEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarListaSalvos(nova);
    TimelineSyncService.despacharEventoRede(
      'timeline_lista_salvos',
      {'lista': nova.toJson()},
    );
    return nova;
  }

  static Future<ListaSalvosSocial> criarListaSalvos({
    required String donoCpf,
    required String nome,
    required VisibilidadeListaSalvos visibilidade,
    List<String> colaboradoresCpfs = const [],
    VoidCallback? onNotificar,
  }) async {
    final lista = ListaSalvosSocial(
      id: 'lista_${gerarIdUnico()}',
      donoCpf: TimelineRepositorioSqlite.normalizarCpf(donoCpf),
      nome: nome.trim(),
      visibilidade: visibilidade,
      colaboradoresCpfs: colaboradoresCpfs
          .map(TimelineRepositorioSqlite.normalizarCpf)
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList(),
      criadaEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarListaSalvos(lista);
    onNotificar?.call();
    TimelineSyncService.despacharEventoRede(
      'timeline_lista_salvos',
      {'lista': lista.toJson()},
    );
    return lista;
  }

  static Future<List<ListaSalvosSocial>> listarListasSalvos(String cpf) =>
      TimelineRepositorioSqlite.listarListasSalvosDoUsuario(cpf);

  static Future<void> salvarPublicacaoEmLista({
    required String listaId,
    required String usuarioCpf,
    required String publicacaoId,
    VoidCallback? onNotificar,
  }) async {
    final cpfNorm = TimelineRepositorioSqlite.normalizarCpf(usuarioCpf);
    final item = ItemSalvoSocial(
      id: 'salvo_${listaId}_$publicacaoId',
      listaId: listaId,
      usuarioCpf: cpfNorm,
      publicacaoId: publicacaoId,
      salvoEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarItemSalvo(item);
    onNotificar?.call();
    TimelineSyncService.despacharEventoRede(
      'timeline_item_salvo',
      {'item': item.toJson()},
    );
  }

  static Future<List<PublicacaoSocial>> listarPublicacoesSalvas({
    required String donoPerfilCpf,
    required String visualizadorCpf,
  }) async {
    final donoNorm = TimelineRepositorioSqlite.normalizarCpf(donoPerfilCpf);
    final visNorm = TimelineRepositorioSqlite.normalizarCpf(visualizadorCpf);
    final listas =
        await TimelineRepositorioSqlite.listarListasSalvosDoUsuario(donoNorm);
    final publicacoes = <PublicacaoSocial>[];
    final idsVistos = <String>{};

    for (final lista in listas) {
      final ehDono =
          TimelineRepositorioSqlite.normalizarCpf(lista.donoCpf) == visNorm;
      final ehColab = lista.colaboradoresCpfs
          .any((c) => TimelineRepositorioSqlite.normalizarCpf(c) == visNorm);
      final podeVer = lista.visibilidade == VisibilidadeListaSalvos.publicaFeed ||
          ehDono ||
          (lista.visibilidade == VisibilidadeListaSalvos.colaboradores &&
              ehColab);
      if (!podeVer) continue;

      final itens =
          await TimelineRepositorioSqlite.listarItensSalvosPorLista(lista.id);
      for (final item in itens) {
        if (idsVistos.contains(item.publicacaoId)) continue;
        final pub = await TimelineRepositorioSqlite.buscarPublicacaoPorId(
          item.publicacaoId,
        );
        if (pub != null && !pub.excluida) {
          idsVistos.add(pub.id);
          publicacoes.add(pub);
        }
      }
    }
    return publicacoes;
  }

  static Future<List<PublicacaoSocial>> listarPublicacoesPorReacao({
    required String cpf,
    required TipoReacaoSocial tipo,
  }) async {
    final reacoes = await TimelineRepositorioSqlite.listarReacoesDoUsuario(cpf);
    final filtradas = reacoes.where((r) => r.tipo == tipo);
    final pubs = <PublicacaoSocial>[];
    final vistos = <String>{};
    for (final r in filtradas) {
      if (vistos.contains(r.publicacaoId)) continue;
      final pub =
          await TimelineRepositorioSqlite.buscarPublicacaoPorId(r.publicacaoId);
      if (pub != null && !pub.excluida) {
        vistos.add(pub.id);
        pubs.add(pub);
      }
    }
    return pubs;
  }

  static Future<DenunciaSocial> registrarDenuncia({
    required String denuncianteCpf,
    required String denuncianteNome,
    required String alvoCpf,
    required String alvoNome,
    String publicacaoId = '',
    required String motivo,
    VoidCallback? onNotificar,
  }) async {
    final denuncia = DenunciaSocial(
      id: 'den_${gerarIdUnico()}',
      denuncianteCpf: TimelineRepositorioSqlite.normalizarCpf(denuncianteCpf),
      denuncianteNome: denuncianteNome,
      alvoCpf: TimelineRepositorioSqlite.normalizarCpf(alvoCpf),
      alvoNome: alvoNome,
      publicacaoId: publicacaoId,
      motivo: motivo.trim(),
      criadaEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarDenuncia(denuncia);
    onNotificar?.call();
    TimelineSyncService.despacharEventoRede(
      'timeline_denuncia',
      {'denuncia': denuncia.toJson()},
    );
    return denuncia;
  }

  static Future<List<DenunciaSocial>> listarDenunciasDoUsuario(String cpf) =>
      TimelineRepositorioSqlite.listarDenunciasEnvolvendoUsuario(cpf);

  static List<Map<String, dynamic>> get abasDescobertaPadrao => [
        {
          'id': 'desc_rede_local',
          'titulo': 'Rede Local',
          'tags': <String>[],
          'ehPadrao': true,
        },
        {
          'id': 'desc_memes',
          'titulo': 'Memes',
          'tags': <String>['meme', 'memes', 'humor'],
          'ehPadrao': true,
        },
        {
          'id': 'desc_noticias',
          'titulo': 'Notícias',
          'tags': <String>['noticia', 'noticias', 'novidade', 'novidades'],
          'ehPadrao': true,
        },
        {
          'id': 'desc_comercio',
          'titulo': 'Comércio',
          'tags': <String>['promocao', 'cardapio', 'loja', 'comercio'],
          'ehPadrao': true,
        },
      ];

  static Future<List<Map<String, dynamic>>> obterAbasDescoberta(
    String cpf,
  ) async {
    if (cpf.trim().isEmpty) return abasDescobertaPadrao;
    final salvas = await TimelineRepositorioSqlite.carregarAbasDescoberta(cpf);
    if (salvas == null || salvas.isEmpty) return abasDescobertaPadrao;
    return salvas;
  }

  static Future<void> salvarAbasDescoberta(
    String cpf,
    List<Map<String, dynamic>> abas, {
    VoidCallback? onNotificar,
  }) async {
    if (cpf.trim().isEmpty) return;
    await TimelineRepositorioSqlite.salvarAbasDescoberta(cpf, abas);
    onNotificar?.call();
  }

  static Future<List<PublicacaoSocial>> listarPublicacoesDescoberta({
    List<String> tags = const [],
    List<String>? apenasAutoresCpfs,
    int limit = 30,
    int offset = 0,
  }) =>
      TimelineRepositorioSqlite.listarPublicacoesDescoberta(
        tags: tags,
        apenasAutoresCpfs: apenasAutoresCpfs,
        limit: limit,
        offset: offset,
      );
}
