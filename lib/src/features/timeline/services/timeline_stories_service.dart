import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nous/src/core/services/gerador_id.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_midia_service.dart';
import 'package:nous/src/features/timeline/services/timeline_repositorio_sqlite.dart';
import 'package:nous/src/features/timeline/services/timeline_sync_service.dart';

/// Serviço especializado em Stories 24h, Destaques permanentes, visualizações,
/// enquetes e respostas diretas ao Chat.
class TimelineStoriesService {
  TimelineStoriesService._();

  static Future<StorySocial> criarStory({
    required String autorCpf,
    required String autorNome,
    String autorFoto = '',
    String tituloDestaque = '',
    String caminhoMidia = '',
    String tipoMidia = 'texto',
    String texto = '',
    bool ehDestaquePermanente = false,
    String perguntaEnquete = '',
    List<String> opcoesEnquete = const [],
    VoidCallback? onNotificar,
  }) async {
    final agora = DateTime.now();
    final story = StorySocial(
      id: 'story_${gerarIdUnico()}',
      autorCpf: TimelineRepositorioSqlite.normalizarCpf(autorCpf),
      autorNome: autorNome,
      autorFoto: autorFoto,
      tituloDestaque: tituloDestaque.trim(),
      caminhoMidia: caminhoMidia,
      tipoMidia: tipoMidia,
      texto: texto.trim(),
      ehDestaquePermanente: ehDestaquePermanente,
      criadoEm: agora,
      expiraEm:
          ehDestaquePermanente ? null : agora.add(const Duration(hours: 24)),
      perguntaEnquete: perguntaEnquete.trim(),
      opcoesEnquete: opcoesEnquete,
    );
    await TimelineRepositorioSqlite.salvarStory(story);
    onNotificar?.call();

    unawaited(() async {
      try {
        var caminhoFinal = caminhoMidia;
        if (caminhoFinal.isNotEmpty && ClienteRedeLocal().conectado) {
          final local = await TimelineMidiaService.resolverCaminhoMidia(
            caminhoFinal,
          );
          if (local != null) {
            final remoto = await ClienteRedeLocal().enviarUploadImagem(local);
            if (remoto.isNotEmpty) caminhoFinal = remoto;
          }
        }
        final storyFinal = story.copyWith(caminhoMidia: caminhoFinal);
        if (caminhoFinal != caminhoMidia) {
          await TimelineRepositorioSqlite.salvarStory(storyFinal);
        }
        TimelineSyncService.despacharEventoRede(
          'timeline_story',
          {'story': storyFinal.toJson()},
        );
      } catch (_) {}
    }());

    return story;
  }

  static Future<StorySocial> votarEnqueteStory(
    StorySocial story,
    String cpfEleitor,
    int indiceOpcao, {
    VoidCallback? onNotificar,
  }) async {
    final norm = TimelineRepositorioSqlite.normalizarCpf(cpfEleitor);
    if (norm.isEmpty) return story;
    final novosVotos = Map<String, int>.from(story.votosEnquete)
      ..[norm] = indiceOpcao;
    final atualizado = story.copyWith(
      votosEnquete: novosVotos,
      atualizadoEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarStory(atualizado);
    onNotificar?.call();
    TimelineSyncService.despacharEventoRede(
      'timeline_story',
      {'story': atualizado.toJson()},
    );
    return atualizado;
  }

  static Future<void> excluirStory(
    StorySocial story, {
    VoidCallback? onNotificar,
  }) async {
    final excluido = story.copyWith(
      excluido: true,
      atualizadoEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarStory(excluido);
    onNotificar?.call();
    TimelineSyncService.despacharEventoRede(
      'timeline_story',
      {'story': excluido.toJson()},
    );
  }

  static Future<List<StorySocial>> listarStoriesAtivos24h(String cpf) async {
    final ativos = await TimelineRepositorioSqlite.listarStoriesDoUsuario(cpf);
    final agora = DateTime.now();
    final recentes = ativos
        .where(
          (s) =>
              !s.excluido &&
              (agora.difference(s.criadoEm).inHours < 24 || s.estaAtivo),
        )
        .toList();
    recentes.sort((a, b) => a.criadoEm.compareTo(b.criadoEm));
    return recentes;
  }

  static Future<StorySocial> registrarVisualizacaoStory(
    StorySocial story,
    String cpfVisualizador, {
    VoidCallback? onNotificar,
  }) async {
    final norm = TimelineRepositorioSqlite.normalizarCpf(cpfVisualizador);
    final autorNorm = TimelineRepositorioSqlite.normalizarCpf(story.autorCpf);
    if (norm.isEmpty || norm == autorNorm) return story;
    final jaViu = story.visualizadoPorCpfs
        .map(TimelineRepositorioSqlite.normalizarCpf)
        .contains(norm);
    if (jaViu) return story;

    final atualizado = story.copyWith(
      visualizadoPorCpfs: [...story.visualizadoPorCpfs, norm],
      atualizadoEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarStory(atualizado);
    onNotificar?.call();
    TimelineSyncService.despacharEventoRede(
      'timeline_story',
      {'story': atualizado.toJson()},
    );
    return atualizado;
  }

  static Future<StorySocial> alternarDestaqueStory(
    StorySocial story, {
    String? tituloDestaque,
    VoidCallback? onNotificar,
  }) async {
    final novoDestaque = !story.ehDestaquePermanente;
    final atualizado = story.copyWith(
      ehDestaquePermanente: novoDestaque,
      tituloDestaque: tituloDestaque ?? story.tituloDestaque,
      expiraEm:
          novoDestaque ? null : story.criadoEm.add(const Duration(hours: 24)),
    );
    await TimelineRepositorioSqlite.salvarStory(atualizado);
    onNotificar?.call();
    TimelineSyncService.despacharEventoRede(
      'timeline_story',
      {'story': atualizado.toJson()},
    );
    return atualizado;
  }

  static Future<void> enviarRespostaStoryNoChat({
    required StorySocial story,
    required String meuCpf,
    required String meuNome,
    String minhaFoto = '',
    required String respostaTexto,
  }) async {
    final cpfAutor = TimelineRepositorioSqlite.normalizarCpf(story.autorCpf);
    final cpfRemetente = TimelineRepositorioSqlite.normalizarCpf(meuCpf);
    if (cpfAutor.isEmpty ||
        cpfRemetente.isEmpty ||
        respostaTexto.trim().isEmpty) {
      return;
    }
    final conversaId =
        ChatService.conversaIdEntreUsuarios(cpfRemetente, cpfAutor);
    final resumoStory = story.texto.isNotEmpty
        ? '"${story.texto}"'
        : (story.tituloDestaque.isNotEmpty
            ? story.tituloDestaque
            : 'Foto/Story');
    final msg = MensagemChat(
      id: 'msg_${gerarIdUnico()}',
      conversaId: conversaId,
      remetenteId: cpfRemetente,
      remetenteNome: meuNome,
      remetenteFoto: minhaFoto,
      destinatarioId: cpfAutor,
      texto:
          '✨ Respondeu ao seu story ($resumoStory):\n${respostaTexto.trim()}',
      dataHora: DateTime.now(),
      enviadaPorMim: true,
      lida: true,
      tipo: 'texto',
    );
    await ChatService.enviarMensagemInstantanea(msg);
  }
}
