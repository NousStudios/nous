import 'package:flutter/foundation.dart';
import 'package:nous/src/core/services/gerador_id.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/helpers/timeline_publicacao_midia_helper.dart';
import 'package:nous/src/features/timeline/services/timeline_repositorio_sqlite.dart';
import 'package:nous/src/features/timeline/services/timeline_sync_service.dart';

/// Helper responsável por listagem, filtragem, paginação, ordenação de feeds
/// e configuração de timelines visíveis e feeds personalizados.
class TimelinePublicacaoFeedHelper {
  TimelinePublicacaoFeedHelper._();

  static const List<TipoFeedSocial> timelinesPadrao = [
    TipoFeedSocial.fotos,
    TipoFeedSocial.videos,
    TipoFeedSocial.interacoes,
  ];

  static Future<List<PublicacaoSocial>> listarFeedDoUsuario({
    required String cpf,
    required TipoFeedSocial tipo,
    int limit = 60,
    int offset = 0,
  }) async {
    var lista = await TimelineRepositorioSqlite.listarPublicacoesDoUsuario(
      cpf: cpf,
      tipo: tipo == TipoFeedSocial.documentos ? null : tipo,
      limit: tipo == TipoFeedSocial.documentos ? (limit * 3) : limit,
      offset: offset,
    );
    lista = lista
        .where((p) => TimelinePublicacaoMidiaHelper.publicacaoPertenceAoFeed(p, tipo))
        .toList();
    if (tipo == TipoFeedSocial.republicacoes && lista.isNotEmpty) {
      final originaisIds = lista
          .map((p) => p.publicacaoOriginalId)
          .where((id) => id.isNotEmpty)
          .toList();
      if (originaisIds.isNotEmpty) {
        final mapaAtivas =
            await TimelineRepositorioSqlite.buscarPublicacoesPorIds(
          originaisIds,
        );
        lista = lista
            .where(
              (p) =>
                  p.publicacaoOriginalId.isEmpty ||
                  mapaAtivas.containsKey(p.publicacaoOriginalId),
            )
            .toList();
      }
    }
    lista.sort((a, b) {
      if (a.fixada != b.fixada) return a.fixada ? -1 : 1;
      if (a.ordemManual != b.ordemManual) {
        if (a.ordemManual == 0) return -1;
        if (b.ordemManual == 0) return 1;
        return a.ordemManual.compareTo(b.ordemManual);
      }
      return b.criadaEm.compareTo(a.criadaEm);
    });
    return lista;
  }

  static Future<void> reordenarPublicacaoNaLista({
    required List<PublicacaoSocial> listaAtual,
    required int indiceAtual,
    required int novoIndice,
    VoidCallback? onNotificar,
  }) async {
    if (indiceAtual < 0 ||
        indiceAtual >= listaAtual.length ||
        novoIndice < 0 ||
        novoIndice >= listaAtual.length ||
        indiceAtual == novoIndice) {
      return;
    }
    final reordenada = List<PublicacaoSocial>.from(listaAtual);
    final movida = reordenada.removeAt(indiceAtual);
    reordenada.insert(novoIndice, movida);

    final agora = DateTime.now();
    for (int i = 0; i < reordenada.length; i++) {
      final p = reordenada[i];
      final novaOrdem = i + 1;
      if (p.ordemManual != novaOrdem) {
        final atualizada = p.copyWith(
          ordemManual: novaOrdem,
          atualizadaEm: agora,
        );
        await TimelineRepositorioSqlite.salvarPublicacao(atualizada);
        TimelineSyncService.despacharEventoRede(
          'timeline_publicacao',
          {'publicacao': atualizada.toJson()},
        );
      }
    }
    onNotificar?.call();
  }

  static Future<List<PublicacaoSocial>> listarTodosPostsContabilizados(
    String cpf,
  ) async {
    final todas = await TimelineRepositorioSqlite.listarPublicacoesDoUsuario(
      cpf: cpf,
      tipo: null,
      limit: 300,
      offset: 0,
    );
    return todas
        .where((p) => p.tipo != TipoFeedSocial.republicacoes)
        .toList();
  }

  static Future<FeedPersonalizado> adicionarFeedPersonalizado({
    required String donoCpf,
    required String titulo,
    required OrigemFeedExterno origem,
    String urlOuIdentificador = '',
    VoidCallback? onNotificar,
  }) async {
    final feed = FeedPersonalizado(
      id: 'feed_${gerarIdUnico()}',
      donoCpf: TimelineRepositorioSqlite.normalizarCpf(donoCpf),
      titulo: titulo.trim(),
      origem: origem,
      urlOuIdentificador: urlOuIdentificador.trim(),
      criadoEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarFeedPersonalizado(feed);
    onNotificar?.call();
    return feed;
  }

  static Future<List<TipoFeedSocial>> obterTimelinesVisiveis(String cpf) async {
    final salvo = await TimelineRepositorioSqlite.carregarTimelinesVisiveis(cpf);
    if (salvo == null) return List<TipoFeedSocial>.from(timelinesPadrao);
    return salvo
        .map(
          (nome) => TipoFeedSocial.values.firstWhere(
            (e) => e.name == nome,
            orElse: () => TipoFeedSocial.fotos,
          ),
        )
        .toSet()
        .toList();
  }

  static Future<void> ativarTimelineAutomaticamente(
    String cpf,
    TipoFeedSocial tipo, {
    VoidCallback? onNotificar,
  }) async {
    final salvo = await TimelineRepositorioSqlite.carregarTimelinesVisiveis(cpf);
    final lista = salvo != null
        ? await obterTimelinesVisiveis(cpf)
        : List<TipoFeedSocial>.from(timelinesPadrao);
    if (!lista.contains(tipo)) {
      lista.add(tipo);
      await salvarTimelinesVisiveis(cpf, lista, onNotificar: onNotificar);
    }
  }

  static Future<void> salvarTimelinesVisiveis(
    String cpf,
    List<TipoFeedSocial> tipos, {
    VoidCallback? onNotificar,
  }) async {
    final nomes = tipos.map((e) => e.name).toSet().toList();
    await TimelineRepositorioSqlite.salvarTimelinesVisiveis(cpf, nomes);
    onNotificar?.call();
    TimelineSyncService.despacharEventoRede('timeline_config', {
      'cpf': TimelineRepositorioSqlite.normalizarCpf(cpf),
      'tipos': nomes,
    });
  }
}
