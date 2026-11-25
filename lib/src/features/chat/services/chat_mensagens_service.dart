import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_e2ee_service.dart';
import 'package:nous/src/features/chat/services/chat_media_service.dart';
import 'package:nous/src/features/chat/services/chat_processador_rede_service.dart';
import 'package:nous/src/features/chat/services/chat_repositorio_sqlite.dart';
import 'package:nous/src/features/chat/services/chat_sincronizacao_service.dart';
import 'package:nous/src/features/chat/services/helpers/chat_mensagem_persistencia_helper.dart';
import 'package:nous/src/features/chat/services/helpers/chat_mensagem_seguranca_helper.dart';

class ChatMensagensService {
  static Future<void> consolidarConversasDuplicadas() async {
    try {
      final db = await ChatRepositorioSqlite.obterDb();
      final rows = await db.query('conversas_chat');
      final Map<String, List<Map<String, dynamic>>> porInterlocutor = {};

      for (final r in rows) {
        final id = r['id'] as String;
        final ehGrupo = (r['eh_grupo'] as int? ?? 0) == 1;
        final ehLoja = (r['eh_loja'] as int? ?? 0) == 1;
        if (ehGrupo ||
            ehLoja ||
            id.startsWith('grupo_') ||
            id.startsWith('loja_')) {
          continue;
        }

        final match = RegExp(r'^user_(\d{11})_user_(\d{11})$').firstMatch(id);
        if (match != null) {
          final c1 = match.group(1)!;
          final c2 = match.group(2)!;
          final min = c1.compareTo(c2) <= 0 ? c1 : c2;
          final max = c1.compareTo(c2) <= 0 ? c2 : c1;
          final chaveCanonica = 'user_${min}_user_$max';
          porInterlocutor.putIfAbsent(chaveCanonica, () => []).add(r);
        }
      }

      for (final entry in porInterlocutor.entries) {
        final chaveCanonica = entry.key;
        final lista = entry.value;
        if (lista.length <= 1 && lista.first['id'] == chaveCanonica) continue;

        // O ID principal sempre deve ser o canônico user_{min}_user_{max}
        final principalId = chaveCanonica;
        final existePrincipal = lista.any((item) => item['id'] == principalId);

        if (!existePrincipal) {
          final primeiro = lista.first;
          final idAntigo = primeiro['id'] as String;
          await db.update(
            'conversas_chat',
            {'id': principalId},
            where: 'id = ?',
            whereArgs: [idAntigo],
          );
          await db.update(
            'mensagens_chat',
            {'conversa_id': principalId},
            where: 'conversa_id = ?',
            whereArgs: [idAntigo],
          );
        }

        for (final item in lista) {
          final dupId = item['id'] as String;
          if (dupId == principalId) continue;

          await db.update(
            'mensagens_chat',
            {'conversa_id': principalId},
            where: 'conversa_id = ?',
            whereArgs: [dupId],
          );

          await db.delete(
            'conversas_chat',
            where: 'id = ?',
            whereArgs: [dupId],
          );
        }
      }
    } catch (e) {
      debugPrint(
        '[ChatMensagensService] Erro ao consolidar conversas duplicadas: $e',
      );
    }
  }

  static Future<MensagemChat> enviarMensagemInstantanea(
    MensagemChat mensagem, {
    required VoidCallback aoNotificar,
  }) async {
    final db = await ChatRepositorioSqlite.obterDb();
    await ChatRepositorioSqlite.desmarcarConversaExcluida(mensagem.conversaId);

    mensagem = await ChatMensagemPersistenciaHelper.ajustarDataHoraEnvio(
      db,
      mensagem,
    );

    final mensagemPersistida =
        await ChatMensagemSegurancaHelper.cifrarEAssinarMensagem(mensagem);

    // Gera o resumo da última mensagem usando o texto claro original (nunca o envelope cifrado e2ee:v1:...)
    final resumo = ChatMediaService.gerarResumoMensagem(mensagem);

    await ChatMensagemPersistenciaHelper.persistirMensagemEAtualizarConversa(
      db,
      mensagemPersistida: mensagemPersistida,
      mensagemReferencia: mensagem,
      resumo: resumo,
      cpfParaMetadados: ChatRepositorioSqlite.normalizarCpf(mensagem.remetenteId),
      statusEnvio: 'pendente',
      lida: false,
      editada: false,
      usarRelogioRedeAoCriar: false,
    );

    aoNotificar();

    ChatMensagemPersistenciaHelper.despacharEnvioBackground(
      db,
      mensagemPersistida,
      aoNotificar: aoNotificar,
    );

    return mensagem.copyWith(statusEnvio: 'enviada');
  }

  static Future<bool> salvarMensagem(
    MensagemChat mensagem, {
    bool originadaDaRede = false,
    required Future<String> Function() obterCpfLogadoLocal,
    required VoidCallback aoNotificar,
  }) async {
    final db = await ChatRepositorioSqlite.obterDb();
    await ChatRepositorioSqlite.desmarcarConversaExcluida(mensagem.conversaId);
    final meuCpf = await obterCpfLogadoLocal();

    if (originadaDaRede) {
      final permitida =
          await ChatMensagemSegurancaHelper.validarOrigemEPermissaoRede(
        mensagem,
        meuCpf: meuCpf,
      );
      if (!permitida) return false;
    }

    final dedup =
        await ChatMensagemPersistenciaHelper.verificarDeduplicacaoEMesclar(
      db,
      mensagem,
    );
    if (dedup.ignorar) return false;
    mensagem = dedup.mensagem;

    mensagem = await ChatMensagemPersistenciaHelper.ajustarDataHoraSalva(
      db,
      mensagem,
      originadaDaRede: originadaDaRede,
      jaExiste: dedup.jaExiste,
    );

    final resumo = await ChatMensagemSegurancaHelper.gerarResumoSeguro(
      mensagem,
      meuCpf: meuCpf,
    );

    await ChatMensagemPersistenciaHelper.persistirMensagemEAtualizarConversa(
      db,
      mensagemPersistida: mensagem,
      mensagemReferencia: mensagem,
      resumo: resumo,
      cpfParaMetadados: meuCpf,
      statusEnvio: mensagem.statusEnvio,
      lida: mensagem.lida,
      editada: mensagem.editada,
      usarRelogioRedeAoCriar: true,
    );

    aoNotificar();
    return true;
  }

  static Future<void> processarMensagemRecebidaRede(
    Map<String, dynamic> payloadMensagem, {
    bool emitirAlertaSonoro = true,
    required String? idConversaAtiva,
    required Future<String> Function() obterCpfLogadoLocal,
    required Future<bool> Function(String conversaId) deveNotificarConversa,
    required VoidCallback aoNotificar,
  }) async {
    await ChatProcessadorRedeService.processarMensagemRecebidaRede(
      payloadMensagem,
      emitirAlertaSonoro: emitirAlertaSonoro,
      idConversaAtiva: idConversaAtiva,
      obterCpfLogadoLocal: obterCpfLogadoLocal,
      deveNotificarConversa: deveNotificarConversa,
      aoNotificar: aoNotificar,
      salvarMensagemCallback: salvarMensagem,
    );
  }

  static Future<void> editarMensagem(
    String id,
    String novoTexto, {
    required VoidCallback aoNotificar,
  }) async {
    final db = await ChatRepositorioSqlite.obterDb();
    final rows = await db.query(
      'mensagens_chat',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return;

    final r = rows.first;
    final textoAntigo = r['texto'] as String? ?? '';
    final msgTemp = MensagemChat(
      id: id,
      conversaId: r['conversa_id'] as String? ?? '',
      remetenteId: r['remetente_id'] as String? ?? '',
      remetenteNome: r['remetente_nome'] as String? ?? '',
      destinatarioId: r['destinatario_id'] as String? ?? '',
      texto: novoTexto.trim(),
      dataHora: DateTime.tryParse(r['data_hora'] as String? ?? '') ??
          DateTime.now(),
    );
    final msgCifrada = await ChatE2eeService.cifrarMensagemSeAplicavel(msgTemp);
    final textoFinal = msgCifrada.texto;

    final historicoRaw = r['historico_edicoes'] as String? ?? '[]';
    List<Map<String, dynamic>> historico = [];
    try {
      historico = (jsonDecode(historicoRaw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {}

    historico.add({
      'texto': textoAntigo,
      'dataHora': DateTime.now().toIso8601String(),
    });

    await db.update(
      'mensagens_chat',
      {
        'texto': textoFinal,
        'editada': 1,
        'historico_edicoes': jsonEncode(historico),
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    aoNotificar();

    ChatSincronizacaoService.despacharEventoRede({
      'tipo': 'mensagem_editada',
      'id': id,
      'conversaId': r['conversa_id'],
      'novoTexto': textoFinal,
      'historicoEdicoes': historico,
    });
  }

  static Future<bool> excluirMensagem(
    String id, {
    required VoidCallback aoNotificar,
  }) async {
    final db = await ChatRepositorioSqlite.obterDb();
    final rows = await db.query(
      'mensagens_chat',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return false;

    final dataHoraStr = rows.first['data_hora'] as String? ?? '';
    final dataHora = DateTime.tryParse(dataHoraStr) ?? DateTime.now();
    final diferencaSegundos = DateTime.now().difference(dataHora).inSeconds;

    if (diferencaSegundos > 60) {
      return false;
    }

    final conversaId = rows.first['conversa_id'] as String? ?? '';
    await db.delete('mensagens_chat', where: 'id = ?', whereArgs: [id]);

    aoNotificar();

    ChatSincronizacaoService.despacharEventoRede({
      'tipo': 'mensagem_excluida',
      'id': id,
      'conversaId': conversaId,
    });
    return true;
  }

  static Future<List<MensagemChat>> obterMensagensNaoLidasDaLoja(
    String lojaId, {
    String? idConversaAtiva,
  }) async {
    final db = await ChatRepositorioSqlite.obterDb();
    final idLimpo = lojaId.startsWith('loja_') ? lojaId.substring(5) : lojaId;
    final condicaoAtiva =
        (idConversaAtiva != null && idConversaAtiva.isNotEmpty)
            ? ' AND conversa_id != ?'
            : '';
    final rows = await db.query(
      'mensagens_chat',
      where:
          '(destinatario_id = ? OR destinatario_id = ? OR conversa_id LIKE ?) '
          'AND remetente_id NOT IN (?, ?) '
          'AND remetente_id NOT LIKE \'loja_%\' '
          'AND remetente_id != \'\' '
          'AND tipo NOT IN (\'mensagem_entregue\', \'mensagens_lidas\') '
          'AND conversa_id NOT IN (SELECT id FROM conversas_excluidas) '
          'AND lida = 0$condicaoAtiva',
      whereArgs: [
        idLimpo,
        'loja_$idLimpo',
        'loja_${idLimpo}_%',
        idLimpo,
        'loja_$idLimpo',
        if (idConversaAtiva != null && idConversaAtiva.isNotEmpty)
          idConversaAtiva,
      ],
      orderBy: 'data_hora DESC',
    );
    final msgs = ChatMensagemPersistenciaHelper.mapearLinhasNaoLidas(rows);
    return ChatE2eeService.decifrarListaMensagens(
      msgs,
      cpfVisualizador: idLimpo,
    );
  }

  static Future<List<MensagemChat>> obterMensagensNaoLidasDoUsuario(
    String cpf, {
    String? idConversaAtiva,
  }) async {
    final db = await ChatRepositorioSqlite.obterDb();
    final cpfNorm = ChatRepositorioSqlite.normalizarCpf(cpf);
    if (cpfNorm.isEmpty) return [];
    final condicaoAtiva =
        (idConversaAtiva != null && idConversaAtiva.isNotEmpty)
            ? ' AND conversa_id != ?'
            : '';
    final rows = await db.query(
      'mensagens_chat',
      where:
          '(destinatario_id = ? OR conversa_id LIKE ? OR '
          'conversa_id IN (SELECT id FROM conversas_chat WHERE id LIKE \'grupo_%\' AND participantes_json LIKE ?)) '
          'AND (conversa_id NOT LIKE \'loja_%\' OR remetente_id LIKE \'loja_%\') '
          'AND remetente_id NOT IN (?, ?, ?) '
          'AND remetente_id != \'\' '
          'AND tipo NOT IN (\'mensagem_entregue\', \'mensagens_lidas\') '
          'AND conversa_id NOT IN (SELECT id FROM conversas_excluidas) '
          'AND lida = 0$condicaoAtiva',
      whereArgs: [
        cpfNorm,
        '%$cpfNorm%',
        '%$cpfNorm%',
        cpf,
        cpfNorm,
        'user_$cpfNorm',
        if (idConversaAtiva != null && idConversaAtiva.isNotEmpty)
          idConversaAtiva,
      ],
      orderBy: 'data_hora DESC',
    );
    final msgs = ChatMensagemPersistenciaHelper.mapearLinhasNaoLidas(rows);
    return ChatE2eeService.decifrarListaMensagens(
      msgs,
      cpfVisualizador: cpfNorm,
    );
  }

  static Future<Map<String, ({String nome, String foto})>>
      obterInterlocutoresDoUsuario(String cpf) async {
    final db = await ChatRepositorioSqlite.obterDb();
    final cpfNorm = ChatRepositorioSqlite.normalizarCpf(cpf);
    if (cpfNorm.isEmpty) return {};

    final rows = await db.query(
      'mensagens_chat',
      columns: [
        'remetente_id',
        'remetente_nome',
        'remetente_foto',
        'destinatario_id',
      ],
      where: 'conversa_id LIKE ? AND remetente_id != ?',
      whereArgs: ['%$cpfNorm%', 'sistema'],
      orderBy: 'data_hora DESC',
    );

    final resultado = <String, ({String nome, String foto})>{};
    for (final r in rows) {
      final rem =
          ChatRepositorioSqlite.normalizarCpf(r['remetente_id'] as String? ?? '');
      final dest =
          ChatRepositorioSqlite.normalizarCpf(r['destinatario_id'] as String? ?? '');
      final outroCpf = rem == cpfNorm ? dest : rem;
      if (outroCpf.length == 11 &&
          outroCpf != cpfNorm &&
          !resultado.containsKey(outroCpf)) {
        final nome = rem != cpfNorm
            ? (r['remetente_nome'] as String? ?? '')
            : '';
        final foto = rem != cpfNorm
            ? (r['remetente_foto'] as String? ?? '')
            : '';
        resultado[outroCpf] = (nome: nome, foto: foto);
      }
    }
    return resultado;
  }
}
