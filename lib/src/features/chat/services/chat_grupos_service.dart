import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_conversas_service.dart';
import 'package:nous/src/features/chat/services/chat_repositorio_sqlite.dart';
import 'package:nous/src/features/chat/services/chat_sincronizacao_service.dart';

class ChatGruposService {
  static Future<ConversaChat> criarGrupo({
    required String nome,
    required List<String> membrosCpfs,
    required String autorCpf,
    required String autorNome,
    String? lojaOrigemId,
    required Future<void> Function(MensagemChat msg) salvarMensagem,
    required Future<bool> Function(MensagemChat msg) despacharMensagemParaRede,
    required VoidCallback aoNotificar,
  }) async {
    final db = await ChatRepositorioSqlite.obterDb();
    final id = 'grupo_${DateTime.now().millisecondsSinceEpoch}';
    final participantes = {
      ...membrosCpfs.map(ChatRepositorioSqlite.normalizarCpf),
      ChatRepositorioSqlite.normalizarCpf(autorCpf),
    }.where((c) => c.isNotEmpty).toList();

    final conversa = ConversaChat(
      id: id,
      titulo: nome,
      nomeGrupo: nome,
      subtitulo: 'Grupo • $nome • ${participantes.length} participantes',
      identificador: id,
      ehLoja: false,
      ehGrupo: true,
      lojaId: lojaOrigemId,
      participantesIds: participantes,
      ultimaMensagem: 'Grupo criado por $autorNome',
      dataHoraUltimaMensagem: DateTime.now(),
    );

    await db.insert('conversas_chat', {
      'id': conversa.id,
      'titulo': conversa.titulo,
      'nome_grupo': nome,
      'subtitulo': conversa.subtitulo,
      'foto': conversa.foto,
      'identificador': conversa.identificador,
      'eh_loja': conversa.ehLoja ? 1 : 0,
      'eh_grupo': 1,
      'loja_id': lojaOrigemId ?? '',
      'participantes_json': jsonEncode(participantes),
      'criado_em': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    final msgSistema = MensagemChat(
      id: 'msg_sys_${DateTime.now().millisecondsSinceEpoch}',
      conversaId: id,
      remetenteId: 'sistema',
      remetenteNome: 'Sistema',
      destinatarioId: id,
      texto: '$autorNome criou o grupo "$nome".',
      dataHora: DateTime.now(),
      lida: true,
    );
    await salvarMensagem(msgSistema);
    await despacharMensagemParaRede(msgSistema);

    ChatSincronizacaoService.despacharEventoRede({
      'tipo': 'grupo_criado',
      'grupo': {
        'id': conversa.id,
        'titulo': conversa.titulo,
        'nome_grupo': nome,
        'nomeGrupo': nome,
        'subtitulo': conversa.subtitulo,
        'foto': conversa.foto,
        'identificador': conversa.identificador,
        'eh_loja': conversa.ehLoja ? 1 : 0,
        'eh_grupo': 1,
        'loja_id': lojaOrigemId ?? '',
        'participantes_json': jsonEncode(participantes),
        'criado_em': DateTime.now().toIso8601String(),
      },
    });

    aoNotificar();
    return conversa;
  }

  static Future<List<ConversaChat>> carregarGrupos({
    String? cpfParticipante,
    String? lojaId,
  }) async {
    final db = await ChatRepositorioSqlite.obterDb();
    final List<Map<String, dynamic>> rows;

    if (lojaId != null && lojaId.isNotEmpty) {
      rows = await db.query(
        'conversas_chat',
        where: 'eh_grupo = 1 AND loja_id = ?',
        whereArgs: [lojaId],
        orderBy: 'criado_em DESC',
      );
    } else {
      rows = await db.query(
        'conversas_chat',
        where: "eh_grupo = 1 AND (loja_id IS NULL OR loja_id = '')",
        orderBy: 'criado_em DESC',
      );
    }

    final excluidas = await ChatRepositorioSqlite.obterIdsConversasExcluidas();
    final titulosCustom = await ChatConversasService.obterTitulosCustomizados();
    final List<ConversaChat> resultado = [];
    final cpfNorm = cpfParticipante != null
        ? ChatRepositorioSqlite.normalizarCpf(cpfParticipante)
        : '';

    for (final r in rows) {
      final id = r['id'] as String;
      if (excluidas.contains(id)) continue;

      final jsonPart = r['participantes_json'] as String? ?? '[]';
      List<String> part = [];
      try {
        part = (jsonDecode(jsonPart) as List<dynamic>)
            .map((e) => e.toString())
            .toList();
      } catch (_) {}

      if ((lojaId == null || lojaId.isEmpty) &&
          cpfNorm.isNotEmpty &&
          !part.contains(cpfNorm)) {
        continue;
      }

      String ultimaMsg = 'Grupo criado';
      DateTime dataHoraUltima = DateTime.now();

      final ultimasMsgs = await db.query(
        'mensagens_chat',
        columns: ['texto', 'tipo', 'data_hora'],
        where: 'conversa_id = ?',
        whereArgs: [id],
        orderBy: 'data_hora DESC, id DESC',
        limit: 1,
      );

      if (ultimasMsgs.isNotEmpty) {
        final u = ultimasMsgs.first;
        ultimaMsg = u['texto'] as String? ?? ultimaMsg;
        dataHoraUltima =
            DateTime.tryParse(u['data_hora'] as String? ?? '') ?? dataHoraUltima;
      }

      final titDb = (r['titulo'] as String? ?? '').trim();
      final nGrupoDb = (r['nome_grupo'] as String? ?? '').trim();
      final nomeGrupoFinal = nGrupoDb.isNotEmpty
          ? nGrupoDb
          : (titDb.isNotEmpty &&
                    titDb != 'Conversa' &&
                    titDb != 'Nova Conversa' &&
                    titDb != 'Grupo'
                ? titDb
                : 'Grupo');

      final tituloConversa =
          titulosCustom[id] ??
          (nomeGrupoFinal.isNotEmpty ? nomeGrupoFinal : 'Grupo');

      resultado.add(
        ConversaChat(
          id: id,
          titulo: tituloConversa,
          nomeGrupo: nomeGrupoFinal,
          subtitulo: 'Grupo • $nomeGrupoFinal • ${part.length} participantes',
          foto: r['foto'] as String? ?? '',
          identificador: id,
          ehGrupo: true,
          lojaId: r['loja_id'] as String? ?? '',
          participantesIds: part,
          ultimaMensagem: ultimaMsg,
          dataHoraUltimaMensagem: dataHoraUltima,
          mensagens: const [],
        ),
      );
    }

    return resultado;
  }

  static Future<void> atualizarFotoGrupo(
    String grupoId,
    String caminhoFoto, {
    required VoidCallback aoNotificar,
  }) async {
    final db = await ChatRepositorioSqlite.obterDb();
    await db.update(
      'conversas_chat',
      {'foto': caminhoFoto},
      where: 'id = ?',
      whereArgs: [grupoId],
    );

    ChatSincronizacaoService.despacharEventoRede({
      'tipo': 'grupo_atualizado',
      'grupoId': grupoId,
      'foto': caminhoFoto,
    });

    aoNotificar();
  }
}
