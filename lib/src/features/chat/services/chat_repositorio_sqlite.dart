import 'dart:async';
import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_outbox_e_recibos_service.dart';
import 'package:nous/src/features/chat/services/helpers/chat_sqlite_mensagem_mapper.dart';
import 'package:nous/src/features/chat/services/helpers/chat_sqlite_schema_helper.dart';
import 'package:nous/src/features/chat/services/helpers/chat_sqlite_tombstones_helper.dart';

/// Repositório soberano de persistência e consultas SQLite de Mensagens e Conversas
class ChatRepositorioSqlite {
  ChatRepositorioSqlite._();

  static bool _tabelasCriadas = false;
  static Future<void>? _inicializacaoEmVoo;

  static String normalizarCpf(String cpf) {
    return ChatSqliteMensagemMapper.normalizarCpf(cpf);
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
    if (_tabelasCriadas) return db;
    _inicializacaoEmVoo ??= _garantirTabelas(db).whenComplete(() {
      _inicializacaoEmVoo = null;
    });
    await _inicializacaoEmVoo;
    return db;
  }

  static Future<void> _garantirTabelas(Database db) async {
    if (_tabelasCriadas) return;
    await ChatSqliteSchemaHelper.garantirTabelas(db);
    _tabelasCriadas = true;
    unawaited(ChatSqliteSchemaHelper.migrarHistoricoExistenteParaConversas(db));
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
    final matchUser =
        RegExp(r'^user_(\d{11})_user_(\d{11})$').firstMatch(conversaId);
    final List<Map<String, dynamic>> rows;
    if (matchUser != null) {
      final c1 = matchUser.group(1)!;
      final c2 = matchUser.group(2)!;
      final idInverso = 'user_${c2}_user_$c1';
      rows = await db.query(
        'mensagens_chat',
        where: 'conversa_id = ? OR conversa_id = ?',
        whereArgs: [conversaId, idInverso],
        orderBy: 'data_hora ASC, id ASC',
        limit: limite,
        offset: offset,
      );
    } else {
      rows = await db.query(
        'mensagens_chat',
        where: 'conversa_id = ?',
        whereArgs: [conversaId],
        orderBy: 'data_hora ASC, id ASC',
        limit: limite,
        offset: offset,
      );
    }

    return rows
        .map(
          (r) => ChatSqliteMensagemMapper.mapearRowParaMensagem(
            r,
            conversaId,
            idVisualizador,
          ),
        )
        .toList();
  }

  /// Marca mensagens como lidas de forma instantânea através de um único comando em lote (Batch Update)
  static Future<bool> marcarComoLidas(
    String conversaId,
    String idLeitor,
  ) async {
    final db = await obterDb();
    final leitorEhLoja = ChatSqliteMensagemMapper.ehVisualizadorLoja(
      conversaId,
      idLeitor,
    );

    if (leitorEhLoja) {
      final idLimpo =
          idLeitor.startsWith('loja_') ? idLeitor.substring(5) : idLeitor;
      final alterados = await db.update(
        'mensagens_chat',
        {'lida': 1, 'entregue': 1, 'status_envio': 'lida'},
        where:
            'conversa_id = ? AND lida = 0 AND remetente_id NOT IN (?, ?) AND remetente_id NOT LIKE \'loja_%\'',
        whereArgs: [conversaId, idLimpo, 'loja_$idLimpo'],
      );
      if (alterados > 0) {
        await ChatOutboxERecibosService.registrarLeituraConversa(
          conversaId,
          idLeitor,
        );
      }
      return alterados > 0;
    }

    final leitorNorm = normalizarCpf(idLeitor);
    final filtroLoja = conversaId.startsWith('loja_')
        ? ' AND remetente_id LIKE \'loja_%\''
        : '';
    final alterados = await db.update(
      'mensagens_chat',
      {'lida': 1, 'entregue': 1, 'status_envio': 'lida'},
      where:
          'conversa_id = ? AND lida = 0 AND remetente_id NOT IN (?, ?, ?)$filtroLoja',
      whereArgs: [conversaId, idLeitor, leitorNorm, 'user_$leitorNorm'],
    );
    if (alterados > 0) {
      await ChatOutboxERecibosService.registrarLeituraConversa(
        conversaId,
        idLeitor,
      );
    }

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
          '(destinatario_id = ? OR conversa_id LIKE ?) AND remetente_id NOT IN (?, ?, ?, ?) AND lida = 0',
      whereArgs: [
        lojaId,
        'loja_${lojaId}_%',
        idLeitor,
        leitorNorm,
        'user_$leitorNorm',
        lojaId,
      ],
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
      'loja_$lojaId',
      if (idConversaAtiva != null && idConversaAtiva.isNotEmpty) idConversaAtiva,
    ];
    final rows = await db.query(
      'mensagens_chat',
      columns: ['id'],
      where:
          '(destinatario_id = ? OR conversa_id LIKE ?) AND remetente_id NOT IN (?, ?) AND remetente_id != \'\' AND tipo NOT IN (\'mensagem_entregue\', \'mensagens_lidas\') AND lida = 0$condicaoAtiva',
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
      cpf,
      cpfNorm,
      'user_$cpfNorm',
      if (idConversaAtiva != null && idConversaAtiva.isNotEmpty) idConversaAtiva,
    ];
    final rows = await db.query(
      'mensagens_chat',
      columns: ['id'],
      where:
          '(destinatario_id = ? OR conversa_id LIKE ? OR conversa_id LIKE ?) AND remetente_id NOT IN (?, ?, ?) AND remetente_id != \'\' AND tipo NOT IN (\'mensagem_entregue\', \'mensagens_lidas\') AND lida = 0$condicaoAtiva',
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
    final visEhLoja = ChatSqliteMensagemMapper.ehVisualizadorLoja(
      conversaId,
      idVisualizador,
    );

    final List<Map<String, Object?>> res;
    if (visEhLoja) {
      final idLimpo = idVisualizador.startsWith('loja_')
          ? idVisualizador.substring(5)
          : idVisualizador;
      res = await db.rawQuery(
        'SELECT COUNT(*) as total FROM mensagens_chat WHERE conversa_id = ? AND lida = 0 AND remetente_id NOT IN (?, ?)',
        [conversaId, idLimpo, 'loja_$idLimpo'],
      );
    } else {
      final idVisNorm = normalizarCpf(idVisualizador);
      res = await db.rawQuery(
        'SELECT COUNT(*) as total FROM mensagens_chat WHERE conversa_id = ? AND lida = 0 AND remetente_id NOT IN (?, ?, ?)',
        [conversaId, idVisualizador, idVisNorm, 'user_$idVisNorm'],
      );
    }

    if (res.isNotEmpty && res.first['total'] != null) {
      return (res.first['total'] as num).toInt();
    }
    return 0;
  }

  static Future<List<String>> obterIdsConversasExcluidas() async {
    try {
      final db = await obterDb();
      return await ChatSqliteTombstonesHelper.obterIdsConversasExcluidas(db);
    } catch (_) {
      return [];
    }
  }

  static Future<bool> isConversaExcluida(String conversaId) async {
    try {
      final db = await obterDb();
      return await ChatSqliteTombstonesHelper.isConversaExcluida(db, conversaId);
    } catch (_) {
      return false;
    }
  }

  static Future<void> desmarcarConversaExcluida(String conversaId) async {
    try {
      final db = await obterDb();
      await ChatSqliteTombstonesHelper.desmarcarConversaExcluida(
        db,
        conversaId,
      );
    } catch (_) {}
  }

  static Future<void> excluirConversaLocal(String conversaId) async {
    final db = await obterDb();
    await ChatSqliteTombstonesHelper.excluirConversaLocal(db, conversaId);
  }

  /// Alterna o status de favorita de uma mensagem
  static Future<bool> alternarFavoritaMensagem(String id) async {
    try {
      final db = await obterDb();
      final rows = await db.query(
        'mensagens_chat',
        columns: ['favorita'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return false;
      final atual = (rows.first['favorita'] as int? ?? 0) == 1;
      final novoValor = atual ? 0 : 1;
      await db.update(
        'mensagens_chat',
        {'favorita': novoValor},
        where: 'id = ?',
        whereArgs: [id],
      );
      return novoValor == 1;
    } catch (_) {
      return false;
    }
  }

  /// Alterna o status de fixada de uma mensagem
  static Future<bool> alternarFixarMensagem(String id, {bool? fixar}) async {
    try {
      final db = await obterDb();
      final rows = await db.query(
        'mensagens_chat',
        columns: ['fixada'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return false;
      final atual = (rows.first['fixada'] as int? ?? 0) == 1;
      final novoValor = (fixar ?? !atual) ? 1 : 0;
      await db.update(
        'mensagens_chat',
        {'fixada': novoValor},
        where: 'id = ?',
        whereArgs: [id],
      );
      return novoValor == 1;
    } catch (_) {
      return false;
    }
  }

  /// Adiciona, atualiza ou remove a reação de um autor em uma mensagem
  static Future<Map<String, String>> reagirMensagem(
    String id,
    String autorId,
    String emoji,
  ) async {
    try {
      final db = await obterDb();
      final rows = await db.query(
        'mensagens_chat',
        columns: ['reacoes_json'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return const {};
      final raw = rows.first['reacoes_json'] as String? ?? '{}';
      final mapa = <String, String>{};
      try {
        final dec = jsonDecode(raw);
        if (dec is Map) {
          dec.forEach((k, v) {
            mapa[k.toString()] = v.toString();
          });
        }
      } catch (_) {}

      final chave = autorId.trim();
      if (chave.isEmpty) return mapa;
      if (emoji.isEmpty || mapa[chave] == emoji) {
        mapa.remove(chave);
      } else {
        mapa[chave] = emoji;
      }

      await db.update(
        'mensagens_chat',
        {'reacoes_json': jsonEncode(mapa)},
        where: 'id = ?',
        whereArgs: [id],
      );
      return mapa;
    } catch (_) {
      return const {};
    }
  }

  /// Alterna o status de silenciada de uma conversa
  static Future<bool> alternarSilenciarConversa(String conversaId) async {
    try {
      final db = await obterDb();
      return await ChatSqliteTombstonesHelper.alternarSilenciarConversa(
        db,
        conversaId,
      );
    } catch (_) {
      return false;
    }
  }

  /// Autocura de integridade temporal: normaliza mensagens que ficaram com horários
  /// no futuro devido a divergências de timezone (ex: UTC não convertido).
  static Future<void> curarTimestampsAnomalosDoPassado() =>
      ChatOutboxERecibosService.curarTimestampsAnomalosDoPassado();
}
