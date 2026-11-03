import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/comunidade_chat_service.dart';

/// Repositório soberano de persistência e consultas SQLite de Mensagens e Conversas
class ChatRepositorioSqlite {
  ChatRepositorioSqlite._();

  static bool _tabelasCriadas = false;

  static String normalizarCpf(String cpf) {
    return cpf.replaceAll(RegExp(r'\D'), '');
  }

  static String extrairOutroCpf(String convId, String meuCpf) {
    final meuNorm = normalizarCpf(meuCpf);
    final match = RegExp(r'^user_(\d{11})_user_(\d{11})$').firstMatch(convId);
    if (match != null) {
      final cpf1 = match.group(1)!;
      final cpf2 = match.group(2)!;
      if (meuNorm.isNotEmpty) {
        if (cpf1 == meuNorm) return cpf2;
        if (cpf2 == meuNorm) return cpf1;
      }
      return cpf1.isNotEmpty ? cpf1 : cpf2;
    }
    final matchLoja = RegExp(r'^loja_.*_usuario_(\d{11})$').firstMatch(convId);
    if (matchLoja != null) {
      return matchLoja.group(1)!;
    }
    return '';
  }

  static Future<Database> obterDb() async {
    final db = await BancoDadosService.db;
    if (!_tabelasCriadas) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS mensagens_chat (
          id TEXT PRIMARY KEY,
          conversa_id TEXT NOT NULL,
          remetente_id TEXT NOT NULL,
          remetente_nome TEXT NOT NULL,
          remetente_foto TEXT,
          destinatario_id TEXT NOT NULL,
          texto TEXT NOT NULL,
          data_hora TEXT NOT NULL,
          nome_atendente TEXT,
          cpf_atendente TEXT,
          lida INTEGER NOT NULL DEFAULT 0,
          tipo TEXT NOT NULL DEFAULT 'texto',
          caminho_anexo TEXT,
          nome_anexo TEXT,
          tamanho_anexo INTEGER DEFAULT 0,
          pedido_id TEXT,
          dados_pedido_json TEXT,
          editada INTEGER DEFAULT 0,
          historico_edicoes TEXT DEFAULT '[]',
          status_envio TEXT DEFAULT 'enviada',
          entregue INTEGER DEFAULT 0
        );
      ''');

      final alteracoesMensagens = [
        'ALTER TABLE mensagens_chat ADD COLUMN tipo TEXT DEFAULT "texto";',
        'ALTER TABLE mensagens_chat ADD COLUMN caminho_anexo TEXT;',
        'ALTER TABLE mensagens_chat ADD COLUMN nome_anexo TEXT;',
        'ALTER TABLE mensagens_chat ADD COLUMN tamanho_anexo INTEGER DEFAULT 0;',
        'ALTER TABLE mensagens_chat ADD COLUMN pedido_id TEXT;',
        'ALTER TABLE mensagens_chat ADD COLUMN dados_pedido_json TEXT;',
        'ALTER TABLE mensagens_chat ADD COLUMN editada INTEGER DEFAULT 0;',
        'ALTER TABLE mensagens_chat ADD COLUMN historico_edicoes TEXT DEFAULT "[]";',
        'ALTER TABLE mensagens_chat ADD COLUMN status_envio TEXT DEFAULT "enviada";',
        'ALTER TABLE mensagens_chat ADD COLUMN entregue INTEGER DEFAULT 0;',
      ];
      for (final sql in alteracoesMensagens) {
        try {
          await db.execute(sql);
        } catch (_) {}
      }

      await db.execute('''
        CREATE TABLE IF NOT EXISTS conversas_chat (
          id TEXT PRIMARY KEY,
          titulo TEXT NOT NULL,
          subtitulo TEXT,
          foto TEXT,
          identificador TEXT NOT NULL,
          eh_loja INTEGER NOT NULL DEFAULT 0,
          eh_grupo INTEGER NOT NULL DEFAULT 0,
          loja_id TEXT,
          participantes_json TEXT,
          criado_em TEXT NOT NULL,
          atualizado_em TEXT,
          ultima_mensagem TEXT DEFAULT '',
          data_hora_ultima_mensagem TEXT,
          arquivada INTEGER DEFAULT 0,
          fixada INTEGER DEFAULT 0
        );
      ''');

      final alteracoesConversas = [
        'ALTER TABLE conversas_chat ADD COLUMN loja_id TEXT;',
        'ALTER TABLE conversas_chat ADD COLUMN atualizado_em TEXT;',
        'ALTER TABLE conversas_chat ADD COLUMN ultima_mensagem TEXT DEFAULT "";',
        'ALTER TABLE conversas_chat ADD COLUMN data_hora_ultima_mensagem TEXT;',
        'ALTER TABLE conversas_chat ADD COLUMN arquivada INTEGER DEFAULT 0;',
        'ALTER TABLE conversas_chat ADD COLUMN fixada INTEGER DEFAULT 0;',
        'ALTER TABLE conversas_chat ADD COLUMN nome_grupo TEXT DEFAULT "";',
        'ALTER TABLE conversas_chat ADD COLUMN titulo_conversa TEXT DEFAULT "";',
      ];
      for (final sql in alteracoesConversas) {
        try {
          await db.execute(sql);
        } catch (_) {}
      }

      await db.execute('''
        CREATE TABLE IF NOT EXISTS conversas_excluidas (
          id TEXT PRIMARY KEY,
          excluida_em TEXT NOT NULL
        );
      ''');

      try {
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_chat_conversa ON mensagens_chat (conversa_id);',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_chat_destinatario ON mensagens_chat (destinatario_id);',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_chat_conversa_data ON mensagens_chat (conversa_id, data_hora);',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_chat_status ON mensagens_chat (status_envio);',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_chat_lida ON mensagens_chat (conversa_id, lida);',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_conversas_loja ON conversas_chat (loja_id);',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_conversas_atualizado ON conversas_chat (atualizado_em);',
        );
      } catch (_) {}

      _tabelasCriadas = true;
      unawaited(_migrarHistoricoExistenteParaConversas(db));
    }
    return db;
  }

  static Future<void> _migrarHistoricoExistenteParaConversas(Database db) async {
    try {
      await db.delete(
        'conversas_chat',
        where:
            '(eh_grupo = 0 OR eh_grupo IS NULL) AND (id LIKE ? OR id LIKE ? OR (eh_loja = 1 AND (loja_id = ? OR LOWER(titulo) = ?)))',
        whereArgs: [
          '%loja_nous_coletiva_usuario_%',
          '%loja_nous_usuario_%',
          ComunidadeChatService.idLojaColetivaNous,
          'nous',
        ],
      );

      await db.delete(
        'conversas_excluidas',
        where: 'id LIKE ?',
        whereArgs: ['user_%'],
      );

      await db.execute('''
        UPDATE conversas_chat
        SET titulo_conversa = ''
        WHERE LOWER(TRIM(titulo_conversa)) = LOWER(TRIM(titulo))
           OR LOWER(TRIM(titulo_conversa)) = LOWER(TRIM(nome_grupo));
      ''');
    } catch (e) {
      debugPrint('[ChatRepositorioSqlite] Erro na migração inicial: $e');
    }
  }

  static List<String> decodificarParticipantes(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return const [];
  }

  /// Carrega as mensagens de uma conversa com ordenação consistente e suporte a paginação
  static Future<List<MensagemChat>> carregarMensagens(
    String conversaId, {
    String? idVisualizador,
    int? limite,
    int? offset,
  }) async {
    final db = await obterDb();
    final rows = await db.query(
      'mensagens_chat',
      where: 'conversa_id = ?',
      whereArgs: [conversaId],
      orderBy: 'data_hora ASC, id ASC',
      limit: limite,
      offset: offset,
    );

    final listaMsgs = rows.map((r) {
      final remetente = r['remetente_id'] as String? ?? '';
      final enviadaPorMim =
          idVisualizador != null &&
          (remetente == idVisualizador ||
              (normalizarCpf(remetente).isNotEmpty &&
                  normalizarCpf(remetente) == normalizarCpf(idVisualizador)));
      final lida = (r['lida'] as int? ?? 0) == 1;
      final entregue = (r['entregue'] as int? ?? 0) == 1;
      final statusEnvio =
          r['status_envio'] as String? ??
          (lida ? 'lida' : (entregue ? 'entregue' : 'enviada'));

      return MensagemChat(
        id: r['id'] as String? ?? '',
        conversaId: r['conversa_id'] as String? ?? '',
        remetenteId: remetente,
        remetenteNome: r['remetente_nome'] as String? ?? '',
        remetenteFoto: r['remetente_foto'] as String? ?? '',
        destinatarioId: r['destinatario_id'] as String? ?? '',
        texto: r['texto'] as String? ?? '',
        dataHora:
            DateTime.tryParse(r['data_hora'] as String? ?? '') ??
            DateTime.now(),
        enviadaPorMim: enviadaPorMim,
        nomeAtendente: r['nome_atendente'] as String? ?? '',
        cpfAtendente: r['cpf_atendente'] as String? ?? '',
        lida: lida,
        tipo: r['tipo'] as String? ?? 'texto',
        caminhoAnexo: r['caminho_anexo'] as String? ?? '',
        nomeAnexo: r['nome_anexo'] as String? ?? '',
        tamanhoAnexo: r['tamanho_anexo'] as int? ?? 0,
        pedidoId: r['pedido_id'] as String? ?? '',
        dadosPedidoJson: r['dados_pedido_json'] as String? ?? '',
        editada: (r['editada'] as int? ?? 0) == 1,
        historicoEdicoes: () {
          final raw = r['historico_edicoes'] as String?;
          if (raw == null || raw.isEmpty || raw == '[]') {
            return const <Map<String, dynamic>>[];
          }
          try {
            return (jsonDecode(raw) as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          } catch (_) {
            return const <Map<String, dynamic>>[];
          }
        }(),
        statusEnvio: statusEnvio,
        entregue: entregue,
      );
    }).toList();

    return listaMsgs;
  }

  /// Marca mensagens como lidas de forma instantânea através de um único comando em lote (Batch Update)
  static Future<bool> marcarComoLidas(
    String conversaId,
    String idLeitor,
  ) async {
    final db = await obterDb();
    final leitorNorm = normalizarCpf(idLeitor);

    final alterados = await db.update(
      'mensagens_chat',
      {'lida': 1, 'status_envio': 'lida'},
      where:
          'conversa_id = ? AND lida = 0 AND remetente_id != ? AND remetente_id != ?',
      whereArgs: [conversaId, idLeitor, leitorNorm],
    );

    return alterados > 0;
  }

  static Future<bool> marcarMensagensDaLojaComoLidas(
    String lojaId,
    String idLeitor,
  ) async {
    final db = await obterDb();
    final leitorNorm = normalizarCpf(idLeitor);

    final alterados = await db.update(
      'mensagens_chat',
      {'lida': 1, 'status_envio': 'lida'},
      where:
          '(destinatario_id = ? OR conversa_id LIKE ?) AND remetente_id != ? AND remetente_id != ? AND lida = 0',
      whereArgs: [lojaId, 'loja_${lojaId}_%', idLeitor, leitorNorm],
    );

    return alterados > 0;
  }

  static Future<bool> temMensagensNaoLidasNaLoja(
    String lojaId,
    String? idConversaAtiva,
  ) async {
    final db = await obterDb();
    final condicaoAtiva =
        (idConversaAtiva != null && idConversaAtiva.isNotEmpty)
            ? ' AND conversa_id != ?'
            : '';
    final args = [
      lojaId,
      'loja_${lojaId}_%',
      lojaId,
      if (idConversaAtiva != null && idConversaAtiva.isNotEmpty) idConversaAtiva,
    ];
    final rows = await db.query(
      'mensagens_chat',
      columns: ['id'],
      where:
          '(destinatario_id = ? OR conversa_id LIKE ?) AND remetente_id != ? AND lida = 0$condicaoAtiva',
      whereArgs: args,
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  static Future<bool> temMensagensNaoLidasNoUsuario(
    String cpf,
    String? idConversaAtiva,
  ) async {
    final db = await obterDb();
    final cpfNorm = normalizarCpf(cpf);
    if (cpfNorm.isEmpty) return false;
    final condicaoAtiva =
        (idConversaAtiva != null && idConversaAtiva.isNotEmpty)
            ? ' AND conversa_id != ?'
            : '';
    final args = [
      cpfNorm,
      '%$cpfNorm%',
      'grupo_%',
      cpfNorm,
      if (idConversaAtiva != null && idConversaAtiva.isNotEmpty) idConversaAtiva,
    ];
    final rows = await db.query(
      'mensagens_chat',
      columns: ['id'],
      where:
          '(destinatario_id = ? OR conversa_id LIKE ? OR conversa_id LIKE ?) AND remetente_id != ? AND lida = 0$condicaoAtiva',
      whereArgs: args,
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  static Future<int> contarNaoLidasNaConversa(
    String conversaId,
    String idVisualizador,
  ) async {
    final db = await obterDb();
    final idVisNorm = normalizarCpf(idVisualizador);

    final res = await db.rawQuery(
      'SELECT COUNT(*) as total FROM mensagens_chat WHERE conversa_id = ? AND lida = 0 AND remetente_id != ? AND remetente_id != ?',
      [conversaId, idVisualizador, idVisNorm],
    );

    if (res.isNotEmpty && res.first['total'] != null) {
      return (res.first['total'] as num).toInt();
    }
    return 0;
  }

  static Future<List<String>> obterIdsConversasExcluidas() async {
    try {
      final db = await obterDb();
      final rows = await db.query('conversas_excluidas');
      final idsExcluidos = <String>[];
      for (final r in rows) {
        final id = r['id'] as String? ?? '';
        final excluidaEmStr = r['excluida_em'] as String?;
        if (id.isEmpty) continue;
        if (excluidaEmStr != null) {
          final resNovas = await db.rawQuery(
            'SELECT COUNT(*) as qtd FROM mensagens_chat WHERE conversa_id = ? AND data_hora > ?',
            [id, excluidaEmStr],
          );
          final countNovas =
              (resNovas.isNotEmpty && resNovas.first['qtd'] != null)
                  ? (resNovas.first['qtd'] as num).toInt()
                  : 0;
          if (countNovas > 0) {
            await db.delete(
              'conversas_excluidas',
              where: 'id = ?',
              whereArgs: [id],
            );
            continue;
          }
        }
        idsExcluidos.add(id);
      }
      return idsExcluidos;
    } catch (_) {
      return [];
    }
  }

  static Future<bool> isConversaExcluida(String conversaId) async {
    try {
      final db = await obterDb();
      final rows = await db.query(
        'conversas_excluidas',
        where: 'id = ?',
        whereArgs: [conversaId],
        limit: 1,
      );
      return rows.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<void> desmarcarConversaExcluida(String conversaId) async {
    try {
      final db = await obterDb();
      await db.delete(
        'conversas_excluidas',
        where: 'id = ?',
        whereArgs: [conversaId],
      );
    } catch (_) {}
  }

  static Future<void> excluirConversaLocal(String conversaId) async {
    final db = await obterDb();
    await db.insert('conversas_excluidas', {
      'id': conversaId,
      'excluida_em': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await db.delete(
      'mensagens_chat',
      where: 'conversa_id = ?',
      whereArgs: [conversaId],
    );
    await db.delete('conversas_chat', where: 'id = ?', whereArgs: [conversaId]);
  }
}
