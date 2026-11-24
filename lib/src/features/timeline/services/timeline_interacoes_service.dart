import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nous/src/core/services/gerador_id.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/notificacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/models/salvos_denuncia_social.dart';
import 'package:nous/src/features/timeline/services/timeline_repositorio_sqlite.dart';
import 'package:nous/src/features/timeline/services/timeline_sync_service.dart';

/// Serviço especializado em interações sociais: reações, comentários, menções,
/// notificações sociais, republicações, envio no chat e histórico de interações.
class TimelineInteracoesService {
  TimelineInteracoesService._();

  static Future<void> alternarReacao({
    required String publicacaoId,
    required String usuarioCpf,
    required String usuarioNome,
    String usuarioFoto = '',
    required TipoReacaoSocial tipo,
    VoidCallback? onNotificar,
  }) async {
    final cpfNorm = TimelineRepositorioSqlite.normalizarCpf(usuarioCpf);
    if (cpfNorm.isEmpty) return;

    final atuais =
        await TimelineRepositorioSqlite.listarReacoesDaPublicacao(publicacaoId);
    final existente = atuais
        .where(
          (r) => TimelineRepositorioSqlite.normalizarCpf(r.usuarioCpf) == cpfNorm,
        )
        .firstOrNull;

    if (existente != null && existente.tipo == tipo) {
      await TimelineRepositorioSqlite.removerReacao(
        publicacaoId: publicacaoId,
        usuarioCpf: cpfNorm,
      );
      onNotificar?.call();
      TimelineSyncService.despacharEventoRede('timeline_reacao_removida', {
        'publicacaoId': publicacaoId,
        'usuarioCpf': cpfNorm,
      });
      return;
    }

    final reacao = ReacaoSocial(
      id: 'reacao_${publicacaoId}_$cpfNorm',
      publicacaoId: publicacaoId,
      usuarioCpf: cpfNorm,
      usuarioNome: usuarioNome,
      usuarioFoto: usuarioFoto,
      tipo: tipo,
      criadaEm: DateTime.now(),
    );

    await TimelineRepositorioSqlite.salvarReacao(reacao);
    onNotificar?.call();
    TimelineSyncService.despacharEventoRede(
      'timeline_reacao',
      {'reacao': reacao.toJson()},
    );
    if (tipo == TipoReacaoSocial.like || tipo == TipoReacaoSocial.deslike) {
      unawaited(() async {
        final pub =
            await TimelineRepositorioSqlite.buscarPublicacaoPorId(publicacaoId);
        if (pub != null) {
          final ehLike = tipo == TipoReacaoSocial.like;
          await emitirNotificacaoSocial(
            destinatarioCpf: pub.autorCpf,
            autorCpf: cpfNorm,
            autorNome: usuarioNome,
            autorFoto: usuarioFoto,
            tipo: ehLike
                ? TipoNotificacaoSocial.curtida
                : TipoNotificacaoSocial.deslike,
            publicacaoId: publicacaoId,
            resumo: ehLike
                ? '$usuarioNome curtiu sua publicação.'
                : '$usuarioNome deu deslike na sua publicação.',
          );
        }
      }());
    }
  }

  static Future<List<ReacaoSocial>> listarReacoes(String publicacaoId) =>
      TimelineRepositorioSqlite.listarReacoesDaPublicacao(publicacaoId);

  static Future<ComentarioSocial> adicionarComentario({
    required String publicacaoId,
    required String autorCpf,
    required String autorNome,
    String autorFoto = '',
    required String texto,
    String respostaDeId = '',
    VoidCallback? onNotificar,
  }) async {
    final comentario = ComentarioSocial(
      id: 'com_${gerarIdUnico()}',
      publicacaoId: publicacaoId,
      autorCpf: TimelineRepositorioSqlite.normalizarCpf(autorCpf),
      autorNome: autorNome,
      autorFoto: autorFoto,
      texto: texto.trim(),
      respostaDeId: respostaDeId,
      criadaEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarComentario(comentario);
    onNotificar?.call();
    TimelineSyncService.despacharEventoRede(
      'timeline_comentario',
      {'comentario': comentario.toJson()},
    );
    unawaited(() async {
      final pub =
          await TimelineRepositorioSqlite.buscarPublicacaoPorId(publicacaoId);
      if (pub != null) {
        await emitirNotificacaoSocial(
          destinatarioCpf: pub.autorCpf,
          autorCpf: autorCpf,
          autorNome: autorNome,
          autorFoto: autorFoto,
          tipo: TipoNotificacaoSocial.comentario,
          publicacaoId: publicacaoId,
          resumo: '$autorNome comentou: "${comentario.texto}"',
        );
      }
      if (respostaDeId.isNotEmpty) {
        final todosComentarios =
            await TimelineRepositorioSqlite.listarComentariosDaPublicacao(
          publicacaoId,
        );
        final pai = todosComentarios
            .where((c) => c.id == respostaDeId)
            .firstOrNull;
        if (pai != null && pai.autorCpf != pub?.autorCpf) {
          await emitirNotificacaoSocial(
            destinatarioCpf: pai.autorCpf,
            autorCpf: autorCpf,
            autorNome: autorNome,
            autorFoto: autorFoto,
            tipo: TipoNotificacaoSocial.comentario,
            publicacaoId: publicacaoId,
            resumo: '$autorNome respondeu seu comentário: "${comentario.texto}"',
          );
        }
      }
      await processarMencoesTexto(
        texto: comentario.texto,
        autorCpf: autorCpf,
        autorNome: autorNome,
        autorFoto: autorFoto,
        publicacaoId: publicacaoId,
      );
    }());
    return comentario;
  }

  static Future<void> emitirNotificacaoSocial({
    required String destinatarioCpf,
    required String autorCpf,
    required String autorNome,
    String autorFoto = '',
    required TipoNotificacaoSocial tipo,
    String publicacaoId = '',
    required String resumo,
  }) async {
    final dest = TimelineRepositorioSqlite.normalizarCpf(destinatarioCpf);
    final autor = TimelineRepositorioSqlite.normalizarCpf(autorCpf);
    if (dest.isEmpty || autor.isEmpty || dest == autor) return;
    final notif = NotificacaoSocial(
      id: 'nsoc_${gerarIdUnico()}',
      destinatarioCpf: dest,
      autorCpf: autor,
      autorNome: autorNome,
      autorFoto: autorFoto,
      tipo: tipo,
      publicacaoId: publicacaoId,
      resumo: resumo,
      criadaEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarNotificacaoSocial(notif);
    TimelineSyncService.despacharEventoRede(
      'timeline_notificacao',
      {'notificacao': notif.toJson(), 'usuarioCpf': autor},
    );
  }

  static Future<void> processarMencoesTexto({
    required String texto,
    required String autorCpf,
    required String autorNome,
    required String autorFoto,
    required String publicacaoId,
  }) async {
    final mencoes = PublicacaoSocial.extrairMencoes(texto);
    if (mencoes.isEmpty) return;
    final contas = await ContasNousService.carregarTodas();
    for (final handle in mencoes) {
      final alvo = contas.where((u) {
        final un = u.nomeDeUsuario.replaceAll('@', '').trim().toLowerCase();
        return un == handle;
      }).firstOrNull;
      if (alvo != null) {
        await emitirNotificacaoSocial(
          destinatarioCpf: alvo.cpf,
          autorCpf: autorCpf,
          autorNome: autorNome,
          autorFoto: autorFoto,
          tipo: TipoNotificacaoSocial.mencao,
          publicacaoId: publicacaoId,
          resumo: '$autorNome mencionou você em uma publicação.',
        );
      }
    }
  }

  static Future<List<ComentarioSocial>> listarComentarios(String publicacaoId) =>
      TimelineRepositorioSqlite.listarComentariosDaPublicacao(publicacaoId);

  static Future<ComentarioSocial> alternarFixarComentario(
    ComentarioSocial comentario, {
    VoidCallback? onNotificar,
  }) async {
    final atualizado = comentario.copyWith(
      fixado: !comentario.fixado,
      atualizadaEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarComentario(atualizado);
    onNotificar?.call();
    TimelineSyncService.despacharEventoRede(
      'timeline_comentario',
      {'comentario': atualizado.toJson()},
    );
    return atualizado;
  }

  static Future<void> excluirComentario(
    ComentarioSocial comentario, {
    VoidCallback? onNotificar,
  }) async {
    final excluido = comentario.copyWith(
      excluido: true,
      atualizadaEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarComentario(excluido);
    onNotificar?.call();
    TimelineSyncService.despacharEventoRede(
      'timeline_comentario',
      {'comentario': excluido.toJson()},
    );
  }

  static Future<ComentarioSocial> alternarReacaoComentario({
    required ComentarioSocial comentario,
    required String usuarioCpf,
    required bool ehLike,
    VoidCallback? onNotificar,
  }) async {
    final cpfNorm = TimelineRepositorioSqlite.normalizarCpf(usuarioCpf);
    if (cpfNorm.isEmpty) return comentario;

    final likes = comentario.curtidasCpfs
        .map(TimelineRepositorioSqlite.normalizarCpf)
        .where((c) => c.isNotEmpty)
        .toList();
    final deslikes = comentario.descurtidasCpfs
        .map(TimelineRepositorioSqlite.normalizarCpf)
        .where((c) => c.isNotEmpty)
        .toList();

    if (ehLike) {
      if (likes.contains(cpfNorm)) {
        likes.remove(cpfNorm);
      } else {
        likes.add(cpfNorm);
        deslikes.remove(cpfNorm);
      }
    } else {
      if (deslikes.contains(cpfNorm)) {
        deslikes.remove(cpfNorm);
      } else {
        deslikes.add(cpfNorm);
        likes.remove(cpfNorm);
      }
    }

    final atualizado = comentario.copyWith(
      curtidasCpfs: likes,
      descurtidasCpfs: deslikes,
      atualizadaEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarComentario(atualizado);
    onNotificar?.call();
    TimelineSyncService.despacharEventoRede(
      'timeline_comentario',
      {'comentario': atualizado.toJson()},
    );
    return atualizado;
  }

  static Future<PublicacaoSocial> republicar({
    required PublicacaoSocial original,
    required String meuCpf,
    required String meuNome,
    String minhaFoto = '',
    String? comentarioCitacao,
    VoidCallback? onNotificar,
  }) async {
    final cpfNorm = TimelineRepositorioSqlite.normalizarCpf(meuCpf);
    final agora = DateTime.now();
    final citacao = (comentarioCitacao ?? '').trim();
    final ehCitacao = citacao.isNotEmpty;
    final repostId = ehCitacao
        ? 'quote_${original.id}_${cpfNorm}_${agora.millisecondsSinceEpoch}'
        : 'repost_${original.id}_$cpfNorm';

    final repost = ehCitacao
        ? PublicacaoSocial(
            id: repostId,
            autorCpf: cpfNorm,
            autorNome: meuNome,
            autorFoto: minhaFoto,
            tipo: TipoFeedSocial.republicacoes,
            texto: citacao,
            publicacaoOriginalId: original.id,
            tags: PublicacaoSocial.extrairTags(citacao),
            criadaEm: agora,
            atualizadaEm: agora,
          )
        : original.copyWith(
            id: repostId,
            autorCpf: cpfNorm,
            autorNome: meuNome,
            autorFoto: minhaFoto,
            coautoresCpfs: const [],
            tipo: TipoFeedSocial.republicacoes,
            publicacaoOriginalId: original.id,
            criadaEm: agora,
            atualizadaEm: agora,
            excluida: false,
          );

    await TimelineRepositorioSqlite.salvarPublicacao(repost);
    onNotificar?.call();
    TimelineSyncService.despacharEventoRede(
      'timeline_publicacao',
      {'publicacao': repost.toJson()},
    );
    if (ehCitacao) {
      unawaited(
        processarMencoesTexto(
          texto: citacao,
          autorCpf: meuCpf,
          autorNome: meuNome,
          autorFoto: minhaFoto,
          publicacaoId: repost.id,
        ),
      );
    }
    unawaited(
      emitirNotificacaoSocial(
        destinatarioCpf: original.autorCpf,
        autorCpf: meuCpf,
        autorNome: meuNome,
        autorFoto: minhaFoto,
        tipo: TipoNotificacaoSocial.republicacao,
        publicacaoId: ehCitacao ? repost.id : original.id,
        resumo: ehCitacao
            ? '$meuNome citou sua publicação: "$citacao"'
            : '$meuNome republicou sua publicação.',
      ),
    );
    return repost;
  }

  static Future<void> enviarPublicacaoNoChat({
    required PublicacaoSocial pub,
    required String conversaId,
    required String meuCpf,
    required String meuNome,
    String minhaFoto = '',
    String destinatarioId = '',
  }) async {
    final resumoTexto = pub.texto.isNotEmpty
        ? pub.texto
        : 'Publicação (${pub.tipo.name}) de ${pub.autorNome}';
    final msg = MensagemChat(
      id: 'msg_${gerarIdUnico()}',
      conversaId: conversaId,
      remetenteId: meuCpf,
      remetenteNome: meuNome,
      remetenteFoto: minhaFoto,
      destinatarioId: destinatarioId,
      texto: '📌 Publicação compartilhada de ${pub.autorNome}:\n$resumoTexto',
      dataHora: DateTime.now(),
      enviadaPorMim: true,
      lida: true,
      tipo: 'texto',
    );
    await ChatService.enviarMensagemInstantanea(msg);
  }

  static String _rotuloFeed(TipoFeedSocial tipo) {
    switch (tipo) {
      case TipoFeedSocial.fotos:
        return 'Fotos';
      case TipoFeedSocial.videos:
        return 'Vídeos';
      case TipoFeedSocial.documentos:
        return 'Documentos';
      case TipoFeedSocial.livros:
        return 'Livros';
      case TipoFeedSocial.musicas:
        return 'Músicas';
      case TipoFeedSocial.escritos:
        return 'Escritos';
      case TipoFeedSocial.republicacoes:
        return 'Republicações';
      case TipoFeedSocial.interacoes:
        return 'Interações';
      case TipoFeedSocial.salvos:
        return 'Salvos';
      case TipoFeedSocial.likes:
        return 'Likes';
      case TipoFeedSocial.deslikes:
        return 'Deslikes';
      case TipoFeedSocial.denuncias:
        return 'Denúncias';
    }
  }

  static Future<List<RegistroInteracaoUsuario>> listarInteracoesDoUsuario(
    String cpf,
  ) async {
    final cpfNorm = TimelineRepositorioSqlite.normalizarCpf(cpf);
    final reacoes = await TimelineRepositorioSqlite.listarReacoesDoUsuario(cpf);
    final comentarios =
        await TimelineRepositorioSqlite.listarComentariosDoUsuario(cpf);
    final reposts = (await TimelineRepositorioSqlite.listarPublicacoesDoUsuario(
      cpf: cpf,
      tipo: TipoFeedSocial.republicacoes,
    ))
        .where(
          (p) => TimelineRepositorioSqlite.normalizarCpf(p.autorCpf) == cpfNorm,
        )
        .toList();
    final todasPubsRelacionadas =
        await TimelineRepositorioSqlite.listarPublicacoesDoUsuario(
      cpf: cpf,
      incluirExcluidas: true,
    );
    final propriasPubs = todasPubsRelacionadas
        .where(
          (p) =>
              TimelineRepositorioSqlite.normalizarCpf(p.autorCpf) == cpfNorm &&
              p.tipo != TipoFeedSocial.republicacoes &&
              p.publicacaoOriginalId.isEmpty,
        )
        .toList();
    final marcacoesAceitas = todasPubsRelacionadas
        .where(
          (p) =>
              !p.excluida &&
              TimelineRepositorioSqlite.normalizarCpf(p.autorCpf) != cpfNorm &&
              p.coautoresCpfs.any(
                (c) => TimelineRepositorioSqlite.normalizarCpf(c) == cpfNorm,
              ),
        )
        .toList();
    String nomeDono = 'Usuário';
    try {
      final contaDono = await ContasNousService.buscarPorCpf(cpfNorm);
      if (contaDono?.nomeExibicao.trim().isNotEmpty == true) {
        nomeDono = contaDono!.nomeExibicao.trim();
      }
    } catch (_) {}
    final itensSalvosBrutos =
        await TimelineRepositorioSqlite.listarItensSalvosDoUsuario(cpf);
    final listasUsuario =
        await TimelineRepositorioSqlite.listarListasSalvosDoUsuario(cpf);
    final listasPublicasIds = listasUsuario
        .where((l) => l.visibilidade == VisibilidadeListaSalvos.publicaFeed)
        .map((l) => l.id)
        .toSet();
    final itensSalvos = itensSalvosBrutos
        .where((s) => !s.excluida && listasPublicasIds.contains(s.listaId))
        .toList();

    // Resolve em lote as publicações alvo para exibir autor, feed e trecho (sem N+1)
    final idsUnicos = <String>{
      ...reacoes.map((r) => r.publicacaoId),
      ...comentarios.map((c) => c.publicacaoId),
      ...reposts.map(
        (p) => p.publicacaoOriginalId.isNotEmpty ? p.publicacaoOriginalId : p.id,
      ),
      ...itensSalvos.map((s) => s.publicacaoId),
    }..removeWhere((id) => id.trim().isEmpty);

    final mapaPubs = await TimelineRepositorioSqlite.buscarPublicacoesPorIds(
      idsUnicos.toList(),
    );
    for (final p in propriasPubs) {
      mapaPubs[p.id] = p;
    }

    RegistroInteracaoUsuario criar({
      required String id,
      required String tipoAcao,
      required String pubId,
      required String resumo,
      required DateTime dataHora,
      String alvoCpfFallback = '',
      String alvoNomeFallback = '',
    }) {
      final pub = mapaPubs[pubId];
      return RegistroInteracaoUsuario(
        id: id,
        tipoAcao: tipoAcao,
        publicacaoId: pubId,
        resumo: resumo,
        dataHora: dataHora,
        alvoCpf: pub?.autorCpf ?? alvoCpfFallback,
        alvoNome: pub?.autorNome.isNotEmpty == true
            ? pub!.autorNome
            : alvoNomeFallback,
        alvoFoto: pub?.autorFoto ?? '',
        tipoFeed: pub != null ? _rotuloFeed(pub.tipo) : '',
        trechoPost: pub?.texto ?? '',
        publicacao: pub,
      );
    }

    String alvoPub(String pubId) {
      final pub = mapaPubs[pubId];
      if (pub == null) return 'na publicação';
      if (TimelineRepositorioSqlite.normalizarCpf(pub.autorCpf) == cpfNorm) {
        return 'na própria publicação';
      }
      final nomeAlvo = pub.autorNome.trim().isNotEmpty
          ? pub.autorNome.trim()
          : 'outro usuário';
      return 'na publicação de $nomeAlvo';
    }

    final itens = <RegistroInteracaoUsuario>[
      ...reacoes
          .where((r) => mapaPubs.containsKey(r.publicacaoId))
          .map(
            (r) => criar(
              id: r.id,
              tipoAcao: r.tipo.name,
              pubId: r.publicacaoId,
              resumo: r.tipo == TipoReacaoSocial.like
                  ? 'Curtiu ${alvoPub(r.publicacaoId)}'
                  : 'Deu deslike ${alvoPub(r.publicacaoId)}',
              dataHora: r.criadaEm,
            ),
          ),
      ...comentarios
          .where((c) => mapaPubs.containsKey(c.publicacaoId))
          .map(
            (c) => criar(
              id: c.id,
              tipoAcao: c.excluido ? 'comentario_excluido' : 'comentario',
              pubId: c.publicacaoId,
              resumo: c.excluido
                  ? (c.respostaDeId.isNotEmpty
                      ? 'Excluiu resposta ${alvoPub(c.publicacaoId)}: "${c.texto}"'
                      : 'Excluiu comentário ${alvoPub(c.publicacaoId)}: "${c.texto}"')
                  : (c.respostaDeId.isNotEmpty
                      ? 'Respondeu em um comentário ${alvoPub(c.publicacaoId)}: "${c.texto}"'
                      : 'Comentou ${alvoPub(c.publicacaoId)}: "${c.texto}"'),
              dataHora: c.criadaEm,
            ),
          ),
      ...reposts
          .where((p) {
            final alvoId = p.publicacaoOriginalId.isNotEmpty
                ? p.publicacaoOriginalId
                : p.id;
            return mapaPubs.containsKey(alvoId);
          })
          .map(
            (p) {
              final alvoId = p.publicacaoOriginalId.isNotEmpty
                  ? p.publicacaoOriginalId
                  : p.id;
              return criar(
                id: p.id,
                tipoAcao: 'republicacao',
                pubId: alvoId,
                resumo: p.texto.isNotEmpty
                    ? 'Republicou ${alvoPub(alvoId)}: "${p.texto}"'
                    : 'Republicou ${alvoPub(alvoId)}',
                dataHora: p.criadaEm,
              );
            },
          ),
      ...itensSalvos
          .where((s) => mapaPubs.containsKey(s.publicacaoId))
          .map(
            (s) => criar(
              id: s.id,
              tipoAcao: 'salvo',
              pubId: s.publicacaoId,
              resumo: 'Salvou ${alvoPub(s.publicacaoId)} na coleção pública',
              dataHora: s.salvoEm,
            ),
          ),
      ...propriasPubs.map(
        (p) => criar(
          id: 'pub_${p.id}',
          tipoAcao: 'publicacao',
          pubId: p.id,
          resumo: p.texto.isNotEmpty
              ? 'Publicou (${_rotuloFeed(p.tipo)}): "${p.texto}"'
              : 'Publicou ${_rotuloFeed(p.tipo).toLowerCase()} no perfil',
          dataHora: p.criadaEm,
        ),
      ),
      ...propriasPubs.where((p) => p.excluida).map(
        (p) => criar(
          id: 'pub_exc_${p.id}',
          tipoAcao: 'publicacao_excluida',
          pubId: p.id,
          resumo: p.texto.isNotEmpty
              ? 'Excluiu a publicação (${_rotuloFeed(p.tipo)}): "${p.texto}"'
              : 'Excluiu uma publicação (${_rotuloFeed(p.tipo).toLowerCase()})',
          dataHora: p.atualizadaEm,
        ),
      ),
      ...marcacoesAceitas.map(
        (p) {
          final autorMarca = p.autorNome.trim().isNotEmpty
              ? p.autorNome.trim()
              : 'outro usuário';
          return criar(
            id: 'marc_${p.id}',
            tipoAcao: 'marcacao',
            pubId: p.id,
            resumo: p.texto.isNotEmpty
                ? '$nomeDono foi marcado(a) em ${_rotuloFeed(p.tipo).toLowerCase()} por $autorMarca: "${p.texto}"'
                : '$nomeDono foi marcado(a) em ${_rotuloFeed(p.tipo).toLowerCase()} por $autorMarca',
            dataHora: p.criadaEm,
          );
        },
      ),
    ];

    itens.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return itens;
  }
}
