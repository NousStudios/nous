import 'dart:async';
import 'dart:convert';

import 'package:nous/src/core/services/gerador_id.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Gerenciador dedicado aos tópicos e salas comunitárias da Comunidade Nous
class ComunidadeChatService {
  static const String idLojaColetivaNous = PdvProvider.idLojaColetivaNous;
  static const String idTopicoGeral = 'loja_nous_coletiva_topico_geral';

  /// Retorna todos os tópicos de conversa da Comunidade Nous que o usuário participa (Geral é padrão)
  static Future<List<ConversaChat>> obterTopicosComunidadeNous({
    String? cpfUsuario,
  }) async {
    final db = await ChatService.obterDb();
    final excluidas = await ChatService.obterIdsConversasExcluidas();

    final rows = await db.query(
      'conversas_chat',
      where: 'loja_id = ? OR id = ? OR id LIKE ?',
      whereArgs: [
        idLojaColetivaNous,
        idTopicoGeral,
        'loja_nous_coletiva_topico_%',
      ],
      orderBy: 'criado_em ASC',
    );

    final resultado = <ConversaChat>[];
    final cpfNorm = cpfUsuario != null && cpfUsuario.isNotEmpty
        ? ChatService.normalizarCpf(cpfUsuario)
        : null;

    for (final r in rows) {
      final convId = r['id'] as String;
      if (excluidas.contains(convId)) continue;

      final participantes = ChatService.decodificarParticipantes(
        r['participantes_json'] as String?,
      );
      final criador = r['identificador'] as String? ?? 'todos';

      if (convId != idTopicoGeral && cpfNorm != null) {
        final participa =
            participantes.contains('todos') ||
            participantes.any((p) => ChatService.normalizarCpf(p) == cpfNorm) ||
            ChatService.normalizarCpf(criador) == cpfNorm;
        if (!participa) continue;
      }

      final msgs = await ChatService.carregarMensagens(convId);
      resultado.add(
        ConversaChat(
          id: convId,
          titulo: r['titulo'] as String? ?? 'Tópico',
          subtitulo: r['subtitulo'] as String? ?? 'Tópico da Comunidade Nous',
          foto: r['foto'] as String? ?? '',
          identificador: criador,
          ehLoja: true,
          ehGrupo: true,
          lojaId: idLojaColetivaNous,
          participantesIds: participantes,
          ultimaMensagem: msgs.isNotEmpty
              ? ChatService.gerarResumoMensagem(msgs.last)
              : (r['ultima_mensagem'] as String? ?? ''),
          dataHoraUltimaMensagem: msgs.isNotEmpty
              ? msgs.last.dataHora
              : (DateTime.tryParse(
                      r['data_hora_ultima_mensagem'] as String? ?? '',
                    ) ??
                    DateTime.now()),
          mensagens: msgs,
          fixada: (r['fixada'] as int? ?? 0) == 1,
          arquivada: (r['arquivada'] as int? ?? 0) == 1,
          atualizadaEm: DateTime.tryParse(r['atualizado_em'] as String? ?? ''),
        ),
      );
    }

    if (resultado.isEmpty || !resultado.any((c) => c.id == idTopicoGeral)) {
      final topicoGeral = await criarOuObterTopicoComunidadeNous(
        idTopicoGeral,
        'Geral',
      );
      if (!resultado.any((c) => c.id == idTopicoGeral)) {
        resultado.insert(0, topicoGeral);
      }
    }

    return resultado;
  }

  /// Retorna todas as salas comunitárias criadas para busca e exploração
  static Future<List<ConversaChat>> obterTodasSalasComunitarias() async {
    final db = await ChatService.obterDb();
    final excluidas = await ChatService.obterIdsConversasExcluidas();
    final rows = await db.query(
      'conversas_chat',
      where:
          'loja_id = ? OR id = ? OR id LIKE ? OR (eh_loja = 1 AND eh_grupo = 1)',
      whereArgs: [
        idLojaColetivaNous,
        idTopicoGeral,
        'loja_nous_coletiva_topico_%',
      ],
      orderBy: 'criado_em ASC',
    );

    final resultado = <ConversaChat>[];
    for (final r in rows) {
      final convId = r['id'] as String;
      if (excluidas.contains(convId)) continue;
      final msgs = await ChatService.carregarMensagens(convId);
      resultado.add(
        ConversaChat(
          id: convId,
          titulo: r['titulo'] as String? ?? 'Tópico',
          subtitulo: r['subtitulo'] as String? ?? 'Tópico da Comunidade Nous',
          foto: r['foto'] as String? ?? '',
          identificador: r['identificador'] as String? ?? 'todos',
          ehLoja: true,
          ehGrupo: true,
          lojaId: idLojaColetivaNous,
          participantesIds: ChatService.decodificarParticipantes(
            r['participantes_json'] as String?,
          ),
          ultimaMensagem: msgs.isNotEmpty
              ? ChatService.gerarResumoMensagem(msgs.last)
              : (r['ultima_mensagem'] as String? ?? ''),
          dataHoraUltimaMensagem: msgs.isNotEmpty
              ? msgs.last.dataHora
              : (DateTime.tryParse(
                      r['data_hora_ultima_mensagem'] as String? ?? '',
                    ) ??
                    DateTime.now()),
          mensagens: msgs,
          fixada: (r['fixada'] as int? ?? 0) == 1,
          arquivada: (r['arquivada'] as int? ?? 0) == 1,
          atualizadaEm: DateTime.tryParse(r['atualizado_em'] as String? ?? ''),
        ),
      );
    }
    return resultado;
  }

  /// Cria ou recupera um tópico paralelo da Comunidade Nous
  static Future<ConversaChat> criarOuObterTopicoComunidadeNous(
    String topicoIdOuTitulo, [
    String? nomeTopico,
    String? criadorCpf,
  ]) async {
    final topicoId = nomeTopico != null
        ? topicoIdOuTitulo
        : 'loja_nous_coletiva_topico_${gerarIdUnico()}';
    final nomeFinal = (nomeTopico ?? topicoIdOuTitulo).trim();
    final criadorFinal = criadorCpf != null && criadorCpf.isNotEmpty
        ? ChatService.normalizarCpf(criadorCpf)
        : 'todos';

    final db = await ChatService.obterDb();
    final rows = await db.query(
      'conversas_chat',
      where: 'id = ?',
      whereArgs: [topicoId],
      limit: 1,
    );

    if (rows.isNotEmpty) {
      final r = rows.first;
      final msgs = await ChatService.carregarMensagens(topicoId);
      final participantes = ChatService.decodificarParticipantes(
        r['participantes_json'] as String?,
      );

      if (criadorFinal != 'todos' && !participantes.contains(criadorFinal)) {
        participantes.add(criadorFinal);
        await db.update(
          'conversas_chat',
          {'participantes_json': jsonEncode(participantes)},
          where: 'id = ?',
          whereArgs: [topicoId],
        );
      }

      var tituloSala = (r['titulo'] as String? ?? '').trim();
      if (tituloSala.isEmpty ||
          tituloSala == 'Sistema' ||
          tituloSala == 'Sala' ||
          tituloSala == 'Conversa' ||
          tituloSala == 'Sala Comunitária' ||
          (nomeTopico != null &&
              nomeTopico.trim().isNotEmpty &&
              tituloSala != nomeFinal)) {
        tituloSala = nomeFinal;
        await db.update(
          'conversas_chat',
          {'titulo': nomeFinal},
          where: 'id = ?',
          whereArgs: [topicoId],
        );
      }

      var idSala = (r['identificador'] as String? ?? '').trim();
      if ((idSala == 'todos' || idSala.isEmpty) && criadorFinal != 'todos') {
        idSala = criadorFinal;
      }

      await db.update(
        'conversas_chat',
        {
          'loja_id': idLojaColetivaNous,
          'eh_loja': 1,
          'eh_grupo': 1,
          if (idSala.isNotEmpty) 'identificador': idSala,
        },
        where: 'id = ?',
        whereArgs: [topicoId],
      );

      return ConversaChat(
        id: r['id'] as String,
        titulo: tituloSala,
        subtitulo: r['subtitulo'] as String? ?? 'Tópico da Comunidade Nous',
        foto: r['foto'] as String? ?? '',
        identificador: idSala.isNotEmpty ? idSala : criadorFinal,
        ehLoja: true,
        ehGrupo: true,
        lojaId: idLojaColetivaNous,
        participantesIds: participantes,
        ultimaMensagem: msgs.isNotEmpty
              ? ChatService.gerarResumoMensagem(msgs.last)
              : (r['ultima_mensagem'] as String? ?? ''),
        dataHoraUltimaMensagem: msgs.isNotEmpty
            ? msgs.last.dataHora
            : DateTime.now(),
        mensagens: msgs,
      );
    }

    final agora = DateTime.now();
    final participantesIniciais =
        criadorFinal != 'todos' ? [criadorFinal] : ['todos'];

    final topico = ConversaChat(
      id: topicoId,
      titulo: nomeFinal,
      subtitulo: 'Tópico da Comunidade Nous',
      identificador: criadorFinal,
      ehLoja: true,
      ehGrupo: true,
      lojaId: idLojaColetivaNous,
      participantesIds: participantesIniciais,
      dataHoraUltimaMensagem: agora,
      atualizadaEm: agora,
    );

    await db.insert('conversas_chat', {
      'id': topicoId,
      'titulo': nomeFinal,
      'subtitulo': 'Tópico da Comunidade Nous',
      'foto': '',
      'identificador': criadorFinal,
      'eh_loja': 1,
      'eh_grupo': 1,
      'loja_id': idLojaColetivaNous,
      'participantes_json': jsonEncode(participantesIniciais),
      'criado_em': agora.toIso8601String(),
      'atualizado_em': agora.toIso8601String(),
      'ultima_mensagem': '',
      'data_hora_ultima_mensagem': agora.toIso8601String(),
      'arquivada': 0,
      'fixada': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    ChatService.notificarAlteracao();
    ChatService.despacharConversaAtualizada(topico);
    return topico;
  }

  /// Entra em uma sala comunitária da Loja Nous
  static Future<void> entrarTopicoComunidade({
    required String topicoId,
    required String cpf,
    required String nomeUsuario,
  }) async {
    final db = await ChatService.obterDb();
    final rows = await db.query(
      'conversas_chat',
      where: 'id = ?',
      whereArgs: [topicoId],
      limit: 1,
    );
    if (rows.isEmpty) return;

    final r = rows.first;
    final participantes = ChatService.decodificarParticipantes(
      r['participantes_json'] as String?,
    );
    final cpfNorm = ChatService.normalizarCpf(cpf);
    if (!participantes.contains(cpfNorm)) {
      participantes.add(cpfNorm);
      await db.update(
        'conversas_chat',
        {'participantes_json': jsonEncode(participantes)},
        where: 'id = ?',
        whereArgs: [topicoId],
      );
    }

    final msgSistema = MensagemChat(
      id:
          'sis_entra_${DateTime.now().millisecondsSinceEpoch}_${gerarIdUnico()}',
      conversaId: topicoId,
      remetenteId: 'sistema',
      remetenteNome: 'Sistema',
      destinatarioId: 'todos',
      texto: '$nomeUsuario entrou na sala',
      dataHora: DateTime.now(),
      statusEnvio: 'entregue',
      entregue: true,
    );
    await ChatService.salvarMensagem(msgSistema);

    final convAtualizada =
        (await ChatService.obterTodasConversas(cpfUsuario: cpf)).firstWhere(
      (c) => c.id == topicoId,
      orElse: () => ConversaChat(
        id: topicoId,
        titulo: r['titulo'] as String? ?? 'Sala',
        subtitulo: 'Tópico da Comunidade Nous',
        identificador: r['identificador'] as String? ?? 'todos',
        ehLoja: true,
        ehGrupo: true,
        participantesIds: participantes,
        dataHoraUltimaMensagem: DateTime.now(),
      ),
    );
    ChatService.despacharConversaAtualizada(convAtualizada);
    ChatService.notificarAlteracao();
  }

  /// Sai de uma sala comunitária da Loja Nous
  static Future<void> sairTopicoComunidade({
    required String topicoId,
    required String cpf,
    required String nomeUsuario,
  }) async {
    final db = await ChatService.obterDb();
    final rows = await db.query(
      'conversas_chat',
      where: 'id = ?',
      whereArgs: [topicoId],
      limit: 1,
    );
    if (rows.isEmpty) return;

    final r = rows.first;
    final participantes = ChatService.decodificarParticipantes(
      r['participantes_json'] as String?,
    );
    final cpfNorm = ChatService.normalizarCpf(cpf);
    participantes.remove(cpfNorm);
    participantes.remove('todos');

    await db.update(
      'conversas_chat',
      {'participantes_json': jsonEncode(participantes)},
      where: 'id = ?',
      whereArgs: [topicoId],
    );

    final msgSistema = MensagemChat(
      id: 'sis_sai_${DateTime.now().millisecondsSinceEpoch}_${gerarIdUnico()}',
      conversaId: topicoId,
      remetenteId: 'sistema',
      remetenteNome: 'Sistema',
      destinatarioId: 'todos',
      texto: '$nomeUsuario saiu da sala',
      dataHora: DateTime.now(),
      statusEnvio: 'entregue',
      entregue: true,
    );
    await ChatService.salvarMensagem(msgSistema);

    final convAtualizada =
        (await ChatService.obterTodasConversas(cpfUsuario: cpf)).firstWhere(
      (c) => c.id == topicoId,
      orElse: () => ConversaChat(
        id: topicoId,
        titulo: r['titulo'] as String? ?? 'Sala',
        subtitulo: 'Tópico da Comunidade Nous',
        identificador: r['identificador'] as String? ?? 'todos',
        ehLoja: true,
        ehGrupo: true,
        participantesIds: participantes,
        dataHoraUltimaMensagem: DateTime.now(),
      ),
    );
    ChatService.despacharConversaAtualizada(convAtualizada);
    ChatService.notificarAlteracao();
  }

  /// Renomeia um tópico paralelo da Comunidade Nous
  static Future<void> renomearTopicoComunidadeNous(
    String topicoId,
    String novoNome,
  ) async {
    await ChatService.renomearConversa(topicoId, novoNome);
  }
}
