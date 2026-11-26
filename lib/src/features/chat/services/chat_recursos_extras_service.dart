import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/features/chat/models/comunidade_usuario.dart';
import 'package:nous/src/features/chat/models/filtro_chat_personalizado.dart';
import 'package:nous/src/features/chat/models/lista_transmissao.dart';
import 'package:nous/src/features/chat/models/registro_chamada.dart';
import 'package:nous/src/features/chat/services/chat_repositorio_sqlite.dart';

/// Serviço persistente para recursos extras da Mensageria:
/// - Conversas favoritas
/// - Filtros personalizados de conversas
/// - Listas de transmissão
/// - Histórico de ligações
/// - Comunidades do usuário (isoladas da Ágora Digital e das Lojas)
class ChatRecursosExtrasService {
  ChatRecursosExtrasService._();

  // ===========================================================================
  // CONVERSAS FAVORITAS
  // ===========================================================================

  static Future<bool> alternarFavoritaConversa(
    String conversaId, {
    bool? favorita,
  }) async {
    final db = await ChatRepositorioSqlite.obterDb();
    final rows = await db.query(
      'conversas_chat',
      columns: ['favorita'],
      where: 'id = ?',
      whereArgs: [conversaId],
    );
    final atual = rows.isNotEmpty && ((rows.first['favorita'] as int? ?? 0) == 1);
    final novoValor = favorita ?? !atual;
    if (rows.isNotEmpty) {
      await db.update(
        'conversas_chat',
        {'favorita': novoValor ? 1 : 0},
        where: 'id = ?',
        whereArgs: [conversaId],
      );
    }
    return novoValor;
  }

  // ===========================================================================
  // FILTROS PERSONALIZADOS DE CHATS
  // ===========================================================================

  static Future<List<FiltroChatPersonalizado>> listarFiltros() async {
    final db = await ChatRepositorioSqlite.obterDb();
    final rows = await db.query(
      'filtros_chat_personalizados',
      orderBy: 'ordem ASC, criado_em ASC',
    );
    return rows.map((r) => FiltroChatPersonalizado.fromJson(r)).toList();
  }

  static Future<void> salvarFiltro(FiltroChatPersonalizado filtro) async {
    final db = await ChatRepositorioSqlite.obterDb();
    await db.insert(
      'filtros_chat_personalizados',
      {
        'id': filtro.id,
        'nome': filtro.nome,
        'conversas_json': jsonEncode(filtro.conversasIds),
        'ordem': filtro.ordem,
        'criado_em': filtro.criadoEm.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> excluirFiltro(String filtroId) async {
    final db = await ChatRepositorioSqlite.obterDb();
    await db.delete(
      'filtros_chat_personalizados',
      where: 'id = ?',
      whereArgs: [filtroId],
    );
  }

  static Future<FiltroChatPersonalizado?> alternarConversaNoFiltro({
    required String filtroId,
    required String conversaId,
  }) async {
    final filtros = await listarFiltros();
    final idx = filtros.indexWhere((f) => f.id == filtroId);
    if (idx == -1) return null;
    final atual = filtros[idx];
    final ids = List<String>.from(atual.conversasIds);
    if (ids.contains(conversaId)) {
      ids.remove(conversaId);
    } else {
      ids.add(conversaId);
    }
    final atualizado = atual.copyWith(conversasIds: ids);
    await salvarFiltro(atualizado);
    return atualizado;
  }

  // ===========================================================================
  // LISTAS DE TRANSMISSÃO
  // ===========================================================================

  static Future<List<ListaTransmissao>> listarListasTransmissao() async {
    final db = await ChatRepositorioSqlite.obterDb();
    final rows = await db.query(
      'listas_transmissao_chat',
      orderBy: 'atualizado_em DESC, criado_em DESC',
    );
    return rows.map((r) => ListaTransmissao.fromJson(r)).toList();
  }

  static Future<void> salvarListaTransmissao(ListaTransmissao lista) async {
    final db = await ChatRepositorioSqlite.obterDb();
    await db.insert(
      'listas_transmissao_chat',
      {
        'id': lista.id,
        'nome': lista.nome,
        'destinatarios_json': jsonEncode(lista.destinatariosCpfs),
        'criado_em': lista.criadoEm.toIso8601String(),
        'atualizado_em': (lista.atualizadoEm ?? DateTime.now()).toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> excluirListaTransmissao(String listaId) async {
    final db = await ChatRepositorioSqlite.obterDb();
    await db.delete(
      'listas_transmissao_chat',
      where: 'id = ?',
      whereArgs: [listaId],
    );
  }

  // ===========================================================================
  // HISTÓRICO DE LIGAÇÕES
  // ===========================================================================

  static Future<List<RegistroChamada>> listarHistoricoChamadas({
    int limite = 100,
  }) async {
    final db = await ChatRepositorioSqlite.obterDb();
    final rows = await db.query(
      'historico_chamadas_chat',
      orderBy: 'data_hora DESC',
      limit: limite,
    );
    return rows.map((r) => RegistroChamada.fromJson(r)).toList();
  }

  static Future<void> registrarChamada(RegistroChamada registro) async {
    final db = await ChatRepositorioSqlite.obterDb();
    await db.insert(
      'historico_chamadas_chat',
      {
        'id': registro.id,
        'conversa_id': registro.conversaId,
        'titulo_contato': registro.tituloContato,
        'foto_contato': registro.fotoContato,
        'participantes_json': jsonEncode(registro.participantesIds),
        'tipo': registro.tipo.name,
        'recebida': registro.recebida ? 1 : 0,
        'atendida': registro.atendida ? 1 : 0,
        'duracao_segundos': registro.duracaoSegundos,
        'data_hora': registro.dataHora.toIso8601String(),
        'eh_grupo': registro.ehGrupo ? 1 : 0,
        'eh_agora': registro.ehAgora ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> excluirRegistroChamada(String id) async {
    final db = await ChatRepositorioSqlite.obterDb();
    await db.delete(
      'historico_chamadas_chat',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===========================================================================
  // COMUNIDADES DO USUÁRIO (MENSAGERIA PESSOAL)
  // ===========================================================================

  static Future<List<ComunidadeUsuario>> listarComunidadesUsuario() async {
    final db = await ChatRepositorioSqlite.obterDb();
    final rows = await db.query(
      'comunidades_usuario_chat',
      orderBy: 'criado_em ASC',
    );
    return rows.map((r) => ComunidadeUsuario.fromJson(r)).toList();
  }

  static Future<void> salvarComunidadeUsuario(
    ComunidadeUsuario comunidade,
  ) async {
    final db = await ChatRepositorioSqlite.obterDb();
    await db.insert(
      'comunidades_usuario_chat',
      {
        'id': comunidade.id,
        'nome': comunidade.nome,
        'descricao': comunidade.descricao,
        'foto': comunidade.foto,
        'criador_cpf': comunidade.criadorCpf,
        'membros_json': jsonEncode(comunidade.membrosIds),
        'canais_texto_json': jsonEncode(comunidade.canaisTextoIds),
        'canais_voz_json': jsonEncode(
          comunidade.canaisVoz.map((c) => c.toJson()).toList(),
        ),
        'criado_em': comunidade.criadoEm.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> excluirComunidadeUsuario(String id) async {
    final db = await ChatRepositorioSqlite.obterDb();
    await db.delete(
      'comunidades_usuario_chat',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
