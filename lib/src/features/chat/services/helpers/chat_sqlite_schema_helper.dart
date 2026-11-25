import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/features/chat/services/comunidade_chat_service.dart';

/// Helper responsável pela criação de tabelas, índices e migrações iniciais do chat no SQLite.
class ChatSqliteSchemaHelper {
  ChatSqliteSchemaHelper._();

  static Future<void> garantirTabelas(Database db) async {
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
        entregue INTEGER DEFAULT 0,
        favorita INTEGER DEFAULT 0,
        fixada INTEGER DEFAULT 0,
        reacoes_json TEXT DEFAULT '{}',
        assinatura TEXT DEFAULT '',
        resposta_a_id TEXT DEFAULT '',
        resposta_a_texto TEXT DEFAULT '',
        resposta_a_autor TEXT DEFAULT ''
      );
    ''');

    const alteracoesMensagens = [
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
      'ALTER TABLE mensagens_chat ADD COLUMN favorita INTEGER DEFAULT 0;',
      'ALTER TABLE mensagens_chat ADD COLUMN fixada INTEGER DEFAULT 0;',
      'ALTER TABLE mensagens_chat ADD COLUMN reacoes_json TEXT DEFAULT "{}";',
      'ALTER TABLE mensagens_chat ADD COLUMN assinatura TEXT DEFAULT "";',
      'ALTER TABLE mensagens_chat ADD COLUMN resposta_a_id TEXT DEFAULT "";',
      'ALTER TABLE mensagens_chat ADD COLUMN resposta_a_texto TEXT DEFAULT "";',
      'ALTER TABLE mensagens_chat ADD COLUMN resposta_a_autor TEXT DEFAULT "";',
    ];
    for (final sql in alteracoesMensagens) {
      try {
        await db.execute(sql);
      } catch (_) {}
    }

    try {
      await db.execute('''
        DELETE FROM mensagens_chat 
        WHERE tipo IN ('mensagem_entregue', 'mensagens_lidas')
           OR id = '' 
           OR remetente_id = ''
           OR conversa_id = ''
           OR (tipo = 'texto' AND TRIM(texto) = '' AND (caminho_anexo IS NULL OR caminho_anexo = '') AND (pedido_id IS NULL OR pedido_id = ''));
      ''');
    } catch (_) {}

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
        fixada INTEGER DEFAULT 0,
        silenciada INTEGER DEFAULT 0
      );
    ''');

    const alteracoesConversas = [
      'ALTER TABLE conversas_chat ADD COLUMN loja_id TEXT;',
      'ALTER TABLE conversas_chat ADD COLUMN atualizado_em TEXT;',
      'ALTER TABLE conversas_chat ADD COLUMN ultima_mensagem TEXT DEFAULT "";',
      'ALTER TABLE conversas_chat ADD COLUMN data_hora_ultima_mensagem TEXT;',
      'ALTER TABLE conversas_chat ADD COLUMN arquivada INTEGER DEFAULT 0;',
      'ALTER TABLE conversas_chat ADD COLUMN fixada INTEGER DEFAULT 0;',
      'ALTER TABLE conversas_chat ADD COLUMN nome_grupo TEXT DEFAULT "";',
      'ALTER TABLE conversas_chat ADD COLUMN titulo_conversa TEXT DEFAULT "";',
      'ALTER TABLE conversas_chat ADD COLUMN silenciada INTEGER DEFAULT 0;',
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

    const indices = [
      'CREATE INDEX IF NOT EXISTS idx_chat_conversa ON mensagens_chat (conversa_id);',
      'CREATE INDEX IF NOT EXISTS idx_chat_destinatario ON mensagens_chat (destinatario_id);',
      'CREATE INDEX IF NOT EXISTS idx_chat_conversa_data ON mensagens_chat (conversa_id, data_hora);',
      'CREATE INDEX IF NOT EXISTS idx_chat_status ON mensagens_chat (status_envio);',
      'CREATE INDEX IF NOT EXISTS idx_chat_lida ON mensagens_chat (conversa_id, lida);',
      'CREATE INDEX IF NOT EXISTS idx_conversas_loja ON conversas_chat (loja_id);',
      'CREATE INDEX IF NOT EXISTS idx_conversas_atualizado ON conversas_chat (atualizado_em);',
    ];
    for (final sql in indices) {
      try {
        await db.execute(sql);
      } catch (_) {}
    }
  }

  static Future<void> migrarHistoricoExistenteParaConversas(Database db) async {
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

      // Preserva conversas_excluidas entre reinicializações para não ressuscitar conversas apagadas.

      // Garante que toda conversa loja_<lojaId>_usuario_<cpf> tenha eh_loja = 1 e loja_id preenchido
      final lojaConvs = await db.query(
        'conversas_chat',
        where: 'id LIKE ?',
        whereArgs: ['loja_%_usuario_%'],
      );
      for (final lc in lojaConvs) {
        final cid = lc['id'] as String? ?? '';
        final idxUsr = cid.indexOf('_usuario_');
        if (idxUsr > 5) {
          final lIdExtraido = cid.substring(5, idxUsr);
          final ehLojaAtual = (lc['eh_loja'] as int? ?? 0) == 1;
          final lojaIdAtual = (lc['loja_id'] as String? ?? '').trim();
          if (!ehLojaAtual || lojaIdAtual.isEmpty) {
            await db.update(
              'conversas_chat',
              {
                'eh_loja': 1,
                'loja_id': lIdExtraido,
              },
              where: 'id = ?',
              whereArgs: [cid],
            );
          }
        }
      }

      await db.execute('''
        UPDATE conversas_chat
        SET titulo_conversa = ''
        WHERE LOWER(TRIM(titulo_conversa)) = LOWER(TRIM(titulo))
           OR LOWER(TRIM(titulo_conversa)) = LOWER(TRIM(nome_grupo));
      ''');

      // Autocura de IDs não-canônicos e saneamento de histórico P2P
      final userConvs = await db.query(
        'conversas_chat',
        where: 'id LIKE ?',
        whereArgs: ['user_%_user_%'],
      );
      for (final c in userConvs) {
        final id = c['id'] as String;
        final match = RegExp(r'^user_(\d{11})_user_(\d{11})$').firstMatch(id);
        if (match != null) {
          final c1 = match.group(1)!;
          final c2 = match.group(2)!;
          final min = c1.compareTo(c2) <= 0 ? c1 : c2;
          final max = c1.compareTo(c2) <= 0 ? c2 : c1;
          final idCanonico = 'user_${min}_user_$max';
          if (id != idCanonico) {
            await db.update(
              'mensagens_chat',
              {'conversa_id': idCanonico},
              where: 'conversa_id = ?',
              whereArgs: [id],
            );
            await db.delete(
              'conversas_chat',
              where: 'id = ?',
              whereArgs: [id],
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[ChatSqliteSchemaHelper] Erro na migração inicial: $e');
    }
  }
}
