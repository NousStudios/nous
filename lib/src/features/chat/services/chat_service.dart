import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/core/services/som_service.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:nous/src/features/chat/services/notificacao_android_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

class ChatService {
  ChatService._();

  static final ValueNotifier<int> alteracoesChatNotifier = ValueNotifier<int>(0);
  static bool _tabelasCriadas = false;

  static void notificarAlteracao() {
    alteracoesChatNotifier.value++;
  }

  static String normalizarCpf(String cpf) {
    return cpf.replaceAll(RegExp(r'\D'), '');
  }

  static String conversaIdLojaUsuario(String lojaId, String usuarioCpf) {
    final prefixo = lojaId.startsWith('loja_') ? lojaId : 'loja_$lojaId';
    return '${prefixo}_usuario_${normalizarCpf(usuarioCpf)}';
  }

  static String conversaIdEntreUsuarios(String cpfA, String cpfB) {
    final c1 = normalizarCpf(cpfA);
    final c2 = normalizarCpf(cpfB);
    final lista = [c1, c2]..sort();
    return 'user_${lista[0]}_user_${lista[1]}';
  }

  static Future<Database> _obterDb() async {
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

      // Migração dinâmica segura para bases já existentes
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
      ];
      for (final sql in alteracoesConversas) {
        try {
          await db.execute(sql);
        } catch (_) {}
      }

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

  /// Salva uma cópia permanente do arquivo anexo no diretório seguro de dados do aplicativo
  static Future<String?> salvarArquivoAnexo(String caminhoOriginal) async {
    try {
      final arquivoOriginal = File(caminhoOriginal);
      if (!await arquivoOriginal.exists()) return null;
      final base = await ImagemService.obterDiretorioBase();
      final pasta = Directory('${base.path}/anexos_chat');
      if (!await pasta.exists()) {
        await pasta.create(recursive: true);
      }
      final nome = p.basename(caminhoOriginal);
      final idUnico = DateTime.now().millisecondsSinceEpoch;
      final destino = File('${pasta.path}/${idUnico}_$nome');
      await arquivoOriginal.copy(destino.path);
      return destino.path;
    } catch (e) {
      debugPrint('[ChatService] Erro ao salvar anexo de arquivo: $e');
      return null;
    }
  }

  /// Converte qualquer mensagem em resumo textual legível para a lista de conversas
  static String gerarResumoMensagem(MensagemChat msg) {
    if (msg.tipo == 'imagem') {
      return msg.texto.isNotEmpty ? '📷 ${msg.texto}' : '📷 Foto';
    } else if (msg.tipo == 'arquivo') {
      return msg.texto.isNotEmpty
          ? '📎 ${msg.texto}'
          : '📎 ${msg.nomeAnexo.isNotEmpty ? msg.nomeAnexo : "Arquivo"}';
    } else if (msg.tipo == 'audio') {
      return msg.texto.isNotEmpty ? '🎤 ${msg.texto}' : '🎤 Mensagem de Voz';
    } else if (msg.tipo == 'comanda') {
      return msg.texto.isNotEmpty ? '🧾 ${msg.texto}' : '🧾 Comanda de Pedido';
    }
    return msg.texto;
  }

  static List<String> _decodificarParticipantes(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return const [];
  }

  /// Migração defensiva: garante que qualquer conversa que já tenha mensagens no banco legado passe a ter sua linha na tabela conversas_chat
  static Future<void> _migrarHistoricoExistenteParaConversas(Database db) async {
    try {
      final conversasExistentes =
          await db.query('conversas_chat', columns: ['id']);
      final idsExistentes =
          conversasExistentes.map((e) => e['id'] as String).toSet();

      final rowsIds =
          await db.rawQuery('SELECT DISTINCT conversa_id FROM mensagens_chat');
      for (final row in rowsIds) {
        final convId = row['conversa_id'] as String?;
        if (convId == null || convId.isEmpty || idsExistentes.contains(convId)) {
          continue;
        }

        final ultimas = await db.query(
          'mensagens_chat',
          where: 'conversa_id = ?',
          whereArgs: [convId],
          orderBy: 'data_hora DESC',
          limit: 1,
        );
        if (ultimas.isEmpty) continue;

        final ult = ultimas.first;
        final ultTexto = ult['texto'] as String? ?? '';
        final ultData =
            ult['data_hora'] as String? ?? DateTime.now().toIso8601String();
        final remetenteId = ult['remetente_id'] as String? ?? '';
        final remetenteNome =
            ult['remetente_nome'] as String? ?? 'Contato Nous';
        final remetenteFoto = ult['remetente_foto'] as String? ?? '';
        final destId = ult['destinatario_id'] as String? ?? '';

        String titulo = remetenteNome;
        String subtitulo = 'Conversa';
        String foto = remetenteFoto;
        String identificador = destId.isNotEmpty ? destId : remetenteId;
        final ehLoja = convId.startsWith('loja_');
        final ehGrupo = convId.startsWith('grupo_');
        String? lojaId;

        if (ehLoja) {
          final partes = convId.split('_');
          if (partes.length >= 2) lojaId = partes[1];
          subtitulo = 'Loja Nous';
        } else if (convId.startsWith('user_')) {
          subtitulo = 'Contato Nous';
        }

        await db.insert(
          'conversas_chat',
          {
            'id': convId,
            'titulo': titulo,
            'subtitulo': subtitulo,
            'foto': foto,
            'identificador': identificador,
            'eh_loja': ehLoja ? 1 : 0,
            'eh_grupo': ehGrupo ? 1 : 0,
            'loja_id': lojaId ?? '',
            'participantes_json': jsonEncode([remetenteId, destId]),
            'criado_em': ultData,
            'atualizado_em': ultData,
            'ultima_mensagem': ultTexto,
            'data_hora_ultima_mensagem': ultData,
            'arquivada': 0,
            'fixada': 0,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        idsExistentes.add(convId);
      }
    } catch (e) {
      debugPrint('[ChatService] Erro na migração defensiva de conversas: $e');
    }
  }

  /// Fonte Única da Verdade: retorna todas as conversas persistidas no SQLite
  static Future<List<ConversaChat>> obterTodasConversas({
    String? cpfUsuario,
    String? lojaId,
    bool incluirArquivadas = false,
  }) async {
    final db = await _obterDb();
    await _migrarHistoricoExistenteParaConversas(db);

    List<Map<String, dynamic>> rows;
    if (lojaId != null && lojaId.isNotEmpty) {
      rows = await db.query(
        'conversas_chat',
        where:
            'loja_id = ? ${incluirArquivadas ? "" : "AND (arquivada IS NULL OR arquivada = 0)"}',
        whereArgs: [lojaId],
        orderBy:
            'fixada DESC, COALESCE(data_hora_ultima_mensagem, atualizado_em, criado_em) DESC',
      );
    } else {
      final cpfNorm =
          cpfUsuario != null ? normalizarCpf(cpfUsuario) : '';
      if (cpfNorm.isNotEmpty) {
        rows = await db.query(
          'conversas_chat',
          where:
              '(loja_id IS NULL OR loja_id = "") ${incluirArquivadas ? "" : "AND (arquivada IS NULL OR arquivada = 0)"} AND (participantes_json LIKE ? OR identificador = ? OR id LIKE ?)',
          whereArgs: ['%$cpfNorm%', cpfNorm, '%$cpfNorm%'],
          orderBy:
              'fixada DESC, COALESCE(data_hora_ultima_mensagem, atualizado_em, criado_em) DESC',
        );
      } else {
        rows = await db.query(
          'conversas_chat',
          where:
              '(loja_id IS NULL OR loja_id = "") ${incluirArquivadas ? "" : "AND (arquivada IS NULL OR arquivada = 0)"}',
          orderBy:
              'fixada DESC, COALESCE(data_hora_ultima_mensagem, atualizado_em, criado_em) DESC',
        );
      }
    }

    final titulosCustom = await obterTitulosCustomizados();
    final resultado = <ConversaChat>[];

    for (final r in rows) {
      final convId = r['id'] as String;
      final msgs =
          await carregarMensagens(convId, idVisualizador: cpfUsuario);
      final naoLidas =
          await contarNaoLidasNaConversa(convId, cpfUsuario ?? '');
      final ultMsg = msgs.isNotEmpty
          ? gerarResumoMensagem(msgs.last)
          : (r['ultima_mensagem'] as String? ?? '');
      final dataHoraUlt = msgs.isNotEmpty
          ? msgs.last.dataHora
          : (DateTime.tryParse(r['data_hora_ultima_mensagem'] as String? ?? '') ??
              DateTime.tryParse(r['criado_em'] as String? ?? '') ??
              DateTime.now());

      final tituloFinal =
          titulosCustom[convId] ?? (r['titulo'] as String? ?? 'Conversa');

      resultado.add(ConversaChat(
        id: convId,
        titulo: tituloFinal,
        subtitulo: r['subtitulo'] as String? ?? '',
        foto: r['foto'] as String? ?? '',
        identificador: r['identificador'] as String? ?? convId,
        ehLoja: (r['eh_loja'] as int? ?? 0) == 1,
        ehGrupo: (r['eh_grupo'] as int? ?? 0) == 1,
        lojaId: r['loja_id'] as String?,
        participantesIds:
            _decodificarParticipantes(r['participantes_json'] as String?),
        ultimaMensagem: ultMsg,
        dataHoraUltimaMensagem: dataHoraUlt,
        naoLidasCount: naoLidas,
        mensagens: msgs,
        fixada: (r['fixada'] as int? ?? 0) == 1,
        arquivada: (r['arquivada'] as int? ?? 0) == 1,
        atualizadaEm: DateTime.tryParse(r['atualizado_em'] as String? ?? ''),
      ));
    }

    return resultado;
  }

  /// Garante que uma conversa exista formalmente no banco de dados SQLite (nunca sumirá)
  static Future<ConversaChat> obterOuCriarConversa({
    required String id,
    required String titulo,
    String subtitulo = '',
    String foto = '',
    required String identificador,
    bool ehLoja = false,
    bool ehGrupo = false,
    String? lojaId,
    String? cpfUsuario,
    List<String> participantesIds = const [],
  }) async {
    final db = await _obterDb();
    final rows = await db.query(
      'conversas_chat',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isNotEmpty) {
      final r = rows.first;
      final msgs = await carregarMensagens(id);
      final ultMsg = msgs.isNotEmpty
          ? gerarResumoMensagem(msgs.last)
          : (r['ultima_mensagem'] as String? ?? '');
      final dataHoraUlt = msgs.isNotEmpty
          ? msgs.last.dataHora
          : (DateTime.tryParse(r['data_hora_ultima_mensagem'] as String? ?? '') ??
              DateTime.now());

      return ConversaChat(
        id: r['id'] as String,
        titulo: (r['titulo'] as String? ?? '').isNotEmpty
            ? r['titulo'] as String
            : titulo,
        subtitulo: (r['subtitulo'] as String? ?? '').isNotEmpty
            ? r['subtitulo'] as String
            : subtitulo,
        foto: (r['foto'] as String? ?? '').isNotEmpty
            ? r['foto'] as String
            : foto,
        identificador: r['identificador'] as String? ?? identificador,
        ehLoja: (r['eh_loja'] as int? ?? 0) == 1,
        ehGrupo: (r['eh_grupo'] as int? ?? 0) == 1,
        lojaId: r['loja_id'] as String? ?? lojaId,
        participantesIds:
            _decodificarParticipantes(r['participantes_json'] as String?),
        ultimaMensagem: ultMsg,
        dataHoraUltimaMensagem: dataHoraUlt,
        mensagens: msgs,
        fixada: (r['fixada'] as int? ?? 0) == 1,
        arquivada: (r['arquivada'] as int? ?? 0) == 1,
        atualizadaEm: DateTime.tryParse(r['atualizado_em'] as String? ?? ''),
      );
    }

    final agora = DateTime.now();
    await db.insert(
      'conversas_chat',
      {
        'id': id,
        'titulo': titulo,
        'subtitulo': subtitulo,
        'foto': foto,
        'identificador': identificador,
        'eh_loja': ehLoja ? 1 : 0,
        'eh_grupo': ehGrupo ? 1 : 0,
        'loja_id': lojaId ?? '',
        'participantes_json': jsonEncode(participantesIds),
        'criado_em': agora.toIso8601String(),
        'atualizado_em': agora.toIso8601String(),
        'ultima_mensagem': '',
        'data_hora_ultima_mensagem': agora.toIso8601String(),
        'arquivada': 0,
        'fixada': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    notificarAlteracao();

    return ConversaChat(
      id: id,
      titulo: titulo,
      subtitulo: subtitulo,
      foto: foto,
      identificador: identificador,
      ehLoja: ehLoja,
      ehGrupo: ehGrupo,
      lojaId: lojaId,
      participantesIds: participantesIds,
      ultimaMensagem: '',
      dataHoraUltimaMensagem: agora,
      atualizadaEm: agora,
      mensagens: const [],
    );
  }

  /// Salva ou atualiza uma conversa formalmente no SQLite
  static Future<void> salvarConversa(ConversaChat conversa) async {
    final db = await _obterDb();
    final agora = DateTime.now();
    await db.insert(
      'conversas_chat',
      {
        'id': conversa.id,
        'titulo': conversa.titulo,
        'subtitulo': conversa.subtitulo,
        'foto': conversa.foto,
        'identificador': conversa.identificador,
        'eh_loja': conversa.ehLoja ? 1 : 0,
        'eh_grupo': conversa.ehGrupo ? 1 : 0,
        'loja_id': conversa.lojaId ?? '',
        'participantes_json': jsonEncode(conversa.participantesIds),
        'criado_em': agora.toIso8601String(),
        'atualizado_em': agora.toIso8601String(),
        'ultima_mensagem': conversa.ultimaMensagem,
        'data_hora_ultima_mensagem':
            conversa.dataHoraUltimaMensagem.toIso8601String(),
        'arquivada': conversa.arquivada ? 1 : 0,
        'fixada': conversa.fixada ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notificarAlteracao();
  }

  static Future<void> alternarFixarConversa(
      String conversaId, [bool? fixar]) async {
    final db = await _obterDb();
    bool novoValor = fixar ?? false;
    if (fixar == null) {
      final rows = await db.query(
        'conversas_chat',
        columns: ['fixada'],
        where: 'id = ?',
        whereArgs: [conversaId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        novoValor = (rows.first['fixada'] as int? ?? 0) == 0;
      } else {
        novoValor = true;
      }
    }
    await db.update(
      'conversas_chat',
      {'fixada': novoValor ? 1 : 0},
      where: 'id = ?',
      whereArgs: [conversaId],
    );
    notificarAlteracao();
  }

  static Future<void> alternarArquivarConversa(
      String conversaId, [bool? arquivar]) async {
    final db = await _obterDb();
    bool novoValor = arquivar ?? false;
    if (arquivar == null) {
      final rows = await db.query(
        'conversas_chat',
        columns: ['arquivada'],
        where: 'id = ?',
        whereArgs: [conversaId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        novoValor = (rows.first['arquivada'] as int? ?? 0) == 0;
      } else {
        novoValor = true;
      }
    }
    await db.update(
      'conversas_chat',
      {'arquivada': novoValor ? 1 : 0},
      where: 'id = ?',
      whereArgs: [conversaId],
    );
    notificarAlteracao();
  }

  /// Drena mensagens pendentes na fila offline assim que uma conexão de rede for restabelecida
  static Future<void> drenarFilaDeSaida() async {
    try {
      final db = await _obterDb();
      final rows = await db.query(
        'mensagens_chat',
        where: 'status_envio = ?',
        whereArgs: ['pendente'],
        orderBy: 'data_hora ASC',
      );
      if (rows.isEmpty) return;

      final servidor = ServidorRedeLocal();
      final cliente = ClienteRedeLocal();
      if (!servidor.ativo && !cliente.conectado) {
        return;
      }

      for (final r in rows) {
        final msg = MensagemChat.fromJson(r);
        await despacharMensagemParaRede(msg);
        await db.update(
          'mensagens_chat',
          {'status_envio': 'enviada'},
          where: 'id = ?',
          whereArgs: [msg.id],
        );
      }
      notificarAlteracao();
    } catch (e) {
      debugPrint('[ChatService] Erro ao drenar fila de saída de mensagens: $e');
    }
  }

  /// Envio otimista instantâneo: grava no banco local em microssegundos e dispara a rede de forma não-bloqueante
  static Future<MensagemChat> enviarMensagemInstantanea(MensagemChat mensagem) async {
    final db = await _obterDb();
    final resumo = gerarResumoMensagem(mensagem);

    await db.insert(
      'mensagens_chat',
      {
        'id': mensagem.id,
        'conversa_id': mensagem.conversaId,
        'remetente_id': mensagem.remetenteId,
        'remetente_nome': mensagem.remetenteNome,
        'remetente_foto': mensagem.remetenteFoto,
        'destinatario_id': mensagem.destinatarioId,
        'texto': mensagem.texto,
        'data_hora': mensagem.dataHora.toIso8601String(),
        'nome_atendente': mensagem.nomeAtendente,
        'cpf_atendente': mensagem.cpfAtendente,
        'lida': 0,
        'tipo': mensagem.tipo,
        'caminho_anexo': mensagem.caminhoAnexo,
        'nome_anexo': mensagem.nomeAnexo,
        'tamanho_anexo': mensagem.tamanhoAnexo,
        'pedido_id': mensagem.pedidoId,
        'dados_pedido_json': mensagem.dadosPedidoJson,
        'editada': 0,
        'historico_edicoes': jsonEncode(mensagem.historicoEdicoes),
        'status_envio': 'pendente',
        'entregue': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final count = await db.update(
      'conversas_chat',
      {
        'ultima_mensagem': resumo,
        'data_hora_ultima_mensagem': mensagem.dataHora.toIso8601String(),
        'atualizado_em': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [mensagem.conversaId],
    );

    if (count == 0) {
      final ehLoja = mensagem.conversaId.startsWith('loja_');
      final ehGrupo = mensagem.conversaId.startsWith('grupo_');
      String? lojaId;
      if (ehLoja) {
        final partes = mensagem.conversaId.split('_');
        if (partes.length >= 2) lojaId = partes[1];
      }

      await db.insert(
        'conversas_chat',
        {
          'id': mensagem.conversaId,
          'titulo': mensagem.remetenteNome,
          'subtitulo': ehLoja ? 'Loja Nous' : 'Contato Nous',
          'foto': mensagem.remetenteFoto,
          'identificador': mensagem.destinatarioId,
          'eh_loja': ehLoja ? 1 : 0,
          'eh_grupo': ehGrupo ? 1 : 0,
          'loja_id': lojaId ?? '',
          'participantes_json':
              jsonEncode([mensagem.remetenteId, mensagem.destinatarioId]),
          'criado_em': mensagem.dataHora.toIso8601String(),
          'atualizado_em': DateTime.now().toIso8601String(),
          'ultima_mensagem': resumo,
          'data_hora_ultima_mensagem': mensagem.dataHora.toIso8601String(),
          'arquivada': 0,
          'fixada': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    notificarAlteracao();

    unawaited(() async {
      try {
        final servidor = ServidorRedeLocal();
        final cliente = ClienteRedeLocal();
        if (servidor.ativo || cliente.conectado) {
          await despacharMensagemParaRede(mensagem);
          await db.update(
            'mensagens_chat',
            {'status_envio': 'enviada'},
            where: 'id = ?',
            whereArgs: [mensagem.id],
          );
          notificarAlteracao();
        }
      } catch (e) {
        debugPrint(
            '[ChatService] Despacho em background falhou, mantido como pendente na fila: $e');
      }
    }());

    return mensagem.copyWith(statusEnvio: 'enviada');
  }

  static Future<void> salvarMensagem(
    MensagemChat mensagem, {
    bool originadaDaRede = false,
  }) async {
    final db = await _obterDb();
    final resumo = gerarResumoMensagem(mensagem);

    await db.insert(
      'mensagens_chat',
      {
        'id': mensagem.id,
        'conversa_id': mensagem.conversaId,
        'remetente_id': mensagem.remetenteId,
        'remetente_nome': mensagem.remetenteNome,
        'remetente_foto': mensagem.remetenteFoto,
        'destinatario_id': mensagem.destinatarioId,
        'texto': mensagem.texto,
        'data_hora': mensagem.dataHora.toIso8601String(),
        'nome_atendente': mensagem.nomeAtendente,
        'cpf_atendente': mensagem.cpfAtendente,
        'lida': mensagem.lida ? 1 : 0,
        'tipo': mensagem.tipo,
        'caminho_anexo': mensagem.caminhoAnexo,
        'nome_anexo': mensagem.nomeAnexo,
        'tamanho_anexo': mensagem.tamanhoAnexo,
        'pedido_id': mensagem.pedidoId,
        'dados_pedido_json': mensagem.dadosPedidoJson,
        'editada': mensagem.editada ? 1 : 0,
        'historico_edicoes': jsonEncode(mensagem.historicoEdicoes),
        'status_envio': mensagem.statusEnvio,
        'entregue': mensagem.entregue ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final count = await db.update(
      'conversas_chat',
      {
        'ultima_mensagem': resumo,
        'data_hora_ultima_mensagem': mensagem.dataHora.toIso8601String(),
        'atualizado_em': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [mensagem.conversaId],
    );

    if (count == 0) {
      final ehLoja = mensagem.conversaId.startsWith('loja_');
      final ehGrupo = mensagem.conversaId.startsWith('grupo_');
      String? lojaId;
      if (ehLoja) {
        final partes = mensagem.conversaId.split('_');
        if (partes.length >= 2) lojaId = partes[1];
      }

      await db.insert(
        'conversas_chat',
        {
          'id': mensagem.conversaId,
          'titulo': mensagem.remetenteNome.isNotEmpty
              ? mensagem.remetenteNome
              : 'Conversa',
          'subtitulo': ehLoja ? 'Loja Nous' : 'Contato Nous',
          'foto': mensagem.remetenteFoto,
          'identificador': mensagem.destinatarioId.isNotEmpty
              ? mensagem.destinatarioId
              : mensagem.remetenteId,
          'eh_loja': ehLoja ? 1 : 0,
          'eh_grupo': ehGrupo ? 1 : 0,
          'loja_id': lojaId ?? '',
          'participantes_json':
              jsonEncode([mensagem.remetenteId, mensagem.destinatarioId]),
          'criado_em': mensagem.dataHora.toIso8601String(),
          'atualizado_em': DateTime.now().toIso8601String(),
          'ultima_mensagem': resumo,
          'data_hora_ultima_mensagem': mensagem.dataHora.toIso8601String(),
          'arquivada': 0,
          'fixada': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    notificarAlteracao();

    if (!originadaDaRede) {
      await despacharMensagemParaRede(mensagem);
    }
  }

  /// Despacha a mensagem para a malha da rede local (seja via servidor balcão ou cliente móvel)
  static Future<void> despacharMensagemParaRede(MensagemChat mensagem) async {
    try {
      final dadosEnvio = mensagem.toJson();

      // Se a mensagem contiver anexo (imagem ou arquivo), embute os bytes em Base64 para sincronização física imediata
      if (mensagem.caminhoAnexo.isNotEmpty) {
        final caminhoResolvido =
            ImagemService.resolverCaminhoExistente(mensagem.caminhoAnexo);
        if (caminhoResolvido != null && File(caminhoResolvido).existsSync()) {
          try {
            final bytes = await File(caminhoResolvido).readAsBytes();
            if (bytes.isNotEmpty && bytes.length <= 25 * 1024 * 1024) {
              dadosEnvio['anexoBytesBase64'] = base64Encode(bytes);
            }
          } catch (e) {
            debugPrint('[ChatService] Erro ao ler bytes do anexo para envio: $e');
          }
        }
      }

      final servidor = ServidorRedeLocal();
      if (servidor.ativo) {
        servidor.notificarTodos({
          'tipo': 'mensagem_chat',
          'mensagem': dadosEnvio,
        });
        return;
      }

      final cliente = ClienteRedeLocal();
      if (cliente.conectado) {
        await cliente.enviarMensagemChat(mensagem, payloadCustomizado: dadosEnvio);
      }
    } catch (e) {
      debugPrint('[ChatService] Erro ao despachar mensagem pela rede local: $e');
    }
  }

  /// Processa e persiste uma mensagem recebida de outro dispositivo conectado no Wi-Fi
  static Future<void> processarMensagemRecebidaDaRede(
    Map<String, dynamic> dadosMensagem, {
    bool emitirAlertaSonoro = true,
  }) async {
    try {
      final tipoEvento = dadosMensagem['tipo'] as String?;
      if (tipoEvento == 'mensagem_editada') {
        final id = dadosMensagem['id'] as String?;
        final novoTexto = dadosMensagem['novoTexto'] as String?;
        final historico = dadosMensagem['historicoEdicoes'];
        if (id != null && novoTexto != null) {
          final db = await _obterDb();
          await db.update(
            'mensagens_chat',
            {
              'texto': novoTexto,
              'editada': 1,
              if (historico != null) 'historico_edicoes': jsonEncode(historico),
            },
            where: 'id = ?',
            whereArgs: [id],
          );
          notificarAlteracao();
        }
        return;
      } else if (tipoEvento == 'mensagem_excluida') {
        final id = dadosMensagem['id'] as String?;
        if (id != null) {
          final db = await _obterDb();
          await db.delete('mensagens_chat', where: 'id = ?', whereArgs: [id]);
          notificarAlteracao();
        }
        return;
      } else if (tipoEvento == 'conversa_renomeada') {
        final convId = dadosMensagem['conversaId'] as String?;
        final novoTitulo = dadosMensagem['novoTitulo'] as String?;
        if (convId != null && novoTitulo != null) {
          final db = await _obterDb();
          final count = await db.update(
            'conversas_chat',
            {'titulo': novoTitulo},
            where: 'id = ?',
            whereArgs: [convId],
          );
          if (count == 0) {
            await db.insert(
              'conversas_chat',
              {
                'id': convId,
                'titulo': novoTitulo,
                'subtitulo': '',
                'identificador': convId,
                'eh_loja': 0,
                'eh_grupo': 0,
                'participantes_json': '[]',
                'criado_em': DateTime.now().toIso8601String(),
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          notificarAlteracao();
        }
        return;
      } else if (tipoEvento == 'grupo_criado') {
        final grupo = dadosMensagem['grupo'] as Map<String, dynamic>?;
        if (grupo != null) {
          final db = await _obterDb();
          await db.insert(
            'conversas_chat',
            {
              'id': grupo['id'],
              'titulo': grupo['titulo'],
              'subtitulo': grupo['subtitulo'],
              'foto': grupo['foto'] ?? '',
              'identificador': grupo['identificador'] ?? grupo['id'],
              'eh_loja': (grupo['eh_loja'] as int?) ?? 0,
              'eh_grupo': 1,
              'loja_id': grupo['loja_id'] ?? grupo['lojaId'] ?? '',
              'participantes_json': grupo['participantes_json'] ?? '[]',
              'criado_em': grupo['criado_em'] ?? DateTime.now().toIso8601String(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          notificarAlteracao();
        }
        return;
      } else if (tipoEvento == 'grupo_atualizado') {
        final grupoId = dadosMensagem['grupoId'] as String?;
        final novaFoto = dadosMensagem['foto'] as String?;
        final novoTitulo = dadosMensagem['titulo'] as String?;
        if (grupoId != null) {
          final db = await _obterDb();
          final updates = <String, dynamic>{};
          if (novaFoto != null) updates['foto'] = novaFoto;
          if (novoTitulo != null) updates['titulo'] = novoTitulo;
          if (updates.isNotEmpty) {
            await db.update('conversas_chat', updates, where: 'id = ?', whereArgs: [grupoId]);
            notificarAlteracao();
          }
        }
        return;
      } else if (tipoEvento == 'mensagens_lidas') {
        final convId = dadosMensagem['conversaId'] as String?;
        if (convId != null) {
          final db = await _obterDb();
          await db.update(
            'mensagens_chat',
            {'lida': 1, 'status_envio': 'lida'},
            where: 'conversa_id = ?',
            whereArgs: [convId],
          );
          notificarAlteracao();
        }
        return;
      } else if (tipoEvento == 'mensagem_entregue') {
        final id = dadosMensagem['id'] as String?;
        final convId = dadosMensagem['conversaId'] as String?;
        if (id != null || convId != null) {
          final db = await _obterDb();
          await db.update(
            'mensagens_chat',
            {
              'entregue': 1,
              'status_envio': 'entregue',
            },
            where: id != null ? 'id = ?' : 'conversa_id = ?',
            whereArgs: [id ?? convId!],
          );
          notificarAlteracao();
        }
        return;
      }

      var mensagem = MensagemChat.fromJson(dadosMensagem);

      // Se a mensagem vier com bytes do anexo em Base64, salva o arquivo físico localmente
      final anexoBase64 = dadosMensagem['anexoBytesBase64'] as String?;
      if (anexoBase64 != null && anexoBase64.isNotEmpty) {
        try {
          final bytes = base64Decode(anexoBase64);
          if (mensagem.tipo == 'imagem') {
            final ext = mensagem.nomeAnexo.split('.').last.toLowerCase();
            final salvo = await ImagemService.salvarBytesImagemLocal(
              bytes,
              extensaoOriginal: ext,
              nomeSugerido: mensagem.nomeAnexo,
            );
            if (salvo != null) {
              mensagem = mensagem.copyWith(caminhoAnexo: salvo);
            }
          } else {
            final salvo = await ImagemService.salvarBytesAnexoLocal(
              bytes,
              categoria: 'arquivos',
              nomeSugerido: mensagem.nomeAnexo,
            );
            if (salvo != null) {
              mensagem = mensagem.copyWith(caminhoAnexo: salvo);
            }
          }
        } catch (e) {
          debugPrint('[ChatService] Erro ao gravar anexo recebido via rede: $e');
        }
      } else if (mensagem.tipo == 'imagem' && mensagem.caminhoAnexo.isNotEmpty) {
        // Fallback: se não veio Base64 e o arquivo não existe localmente, tenta baixar do balcão caso conectado
        final existeLocal =
            ImagemService.resolverCaminhoExistente(mensagem.caminhoAnexo) != null;
        if (!existeLocal && ClienteRedeLocal().conectado) {
          try {
            final baixado = await ClienteRedeLocal()
                .baixarImagemRemota(mensagem.caminhoAnexo);
            if (baixado.isNotEmpty && baixado != mensagem.caminhoAnexo) {
              mensagem = mensagem.copyWith(caminhoAnexo: baixado);
            }
          } catch (_) {}
        }
      }

      await salvarMensagem(mensagem, originadaDaRede: true);

      // Avisa imediatamente ao remetente pela rede que a mensagem foi entregue (2 checks cinzas)
      despacharConfirmacaoEntrega(mensagem.id, mensagem.conversaId);

      if (emitirAlertaSonoro) {
        SomService.tocarBipPadrao();
      }
      // Notificação nativa no sistema operacional Android estilo WhatsApp
      await NotificacaoAndroidService.exibirNotificacaoMensagem(mensagem);
    } catch (e) {
      debugPrint('[ChatService] Erro ao processar mensagem recebida da rede: $e');
    }
  }

  /// Despacha confirmação de entrega para o remetente através da malha local
  static void despacharConfirmacaoEntrega(String msgId, String convId) {
    try {
      final payload = {
        'tipo': 'mensagem_entregue',
        'id': msgId,
        'conversaId': convId,
      };
      final servidor = ServidorRedeLocal();
      if (servidor.ativo) {
        servidor.notificarTodos(payload);
        return;
      }
      final cliente = ClienteRedeLocal();
      if (cliente.conectado) {
        cliente.enviarEventoWs(payload);
      }
    } catch (e) {
      debugPrint('[ChatService] Erro ao despachar confirmação de entrega: $e');
    }
  }

  /// Sincroniza conversas e mensagens do balcão ao conectar um terminal móvel na rede local
  static Future<void> sincronizarMensagensComBalcao({
    required String ipServidor,
    required int portaServidor,
    String? cpfUsuario,
    String? lojaId,
  }) async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final queryParams = <String, String>{};
      if (cpfUsuario != null && cpfUsuario.isNotEmpty) {
        queryParams['cpf'] = normalizarCpf(cpfUsuario);
      }
      if (lojaId != null && lojaId.isNotEmpty) {
        queryParams['lojaId'] = lojaId;
      }

      // 1. Baixar conversas e grupos registrados no balcão
      try {
        final uriConversas = Uri.http('$ipServidor:$portaServidor', '/api/chat/conversas', queryParams);
        final reqConv = await client.getUrl(uriConversas);
        final respConv = await reqConv.close();
        if (respConv.statusCode == HttpStatus.ok) {
          final bodyConv = await utf8.decodeStream(respConv);
          final dadosConv = jsonDecode(bodyConv) as Map<String, dynamic>;
          if (dadosConv['sucesso'] == true && dadosConv['conversas'] is List) {
            final listaConv = dadosConv['conversas'] as List<dynamic>;
            for (final c in listaConv) {
              if (c is Map<String, dynamic>) {
                await salvarConversaLocal(c);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[ChatService] Erro ao sincronizar conversas do balcão: $e');
      }

      // 2. Baixar mensagens registradas no balcão
      final uri = Uri.http('$ipServidor:$portaServidor', '/api/chat/mensagens', queryParams);
      final req = await client.getUrl(uri);
      final resp = await req.close();

      if (resp.statusCode == HttpStatus.ok) {
        final body = await utf8.decodeStream(resp);
        final dados = jsonDecode(body) as Map<String, dynamic>;
        if (dados['sucesso'] == true && dados['mensagens'] is List) {
          final lista = dados['mensagens'] as List<dynamic>;
          for (final item in lista) {
            if (item is Map<String, dynamic>) {
              var msg = MensagemChat.fromJson(item);
              if (msg.tipo == 'imagem' && msg.caminhoAnexo.isNotEmpty) {
                final existeLocal =
                    ImagemService.resolverCaminhoExistente(msg.caminhoAnexo) != null;
                if (!existeLocal && ClienteRedeLocal().conectado) {
                  try {
                    final baixado = await ClienteRedeLocal()
                        .baixarImagemRemota(msg.caminhoAnexo);
                    if (baixado.isNotEmpty && baixado != msg.caminhoAnexo) {
                      msg = msg.copyWith(caminhoAnexo: baixado);
                    }
                  } catch (_) {}
                }
              }
              await salvarMensagem(msg, originadaDaRede: true);
            }
          }
        }
      }

      // 3. Enviar conversas e mensagens locais para o balcão (garantir sincronização bidirecional pan-dispositivo)
      try {
        final conversasLocais = await obterConversasParaSincronizacao(cpf: cpfUsuario, lojaId: lojaId);
        final mensagensLocais = await obterMensagensParaSincronizacao(cpf: cpfUsuario, lojaId: lojaId);
        if (conversasLocais.isNotEmpty || mensagensLocais.isNotEmpty) {
          final uriSync = Uri.http('$ipServidor:$portaServidor', '/api/chat/conversas/sync');
          final reqSync = await client.postUrl(uriSync);
          reqSync.headers.contentType = ContentType.json;
          reqSync.write(jsonEncode({
            'conversas': conversasLocais,
            'mensagens': mensagensLocais,
          }));
          await reqSync.close();
        }
      } catch (_) {}

      notificarAlteracao();
    } catch (e) {
      debugPrint('[ChatService] Erro ao sincronizar mensagens com balcão: $e');
    }
  }

  /// Retorna as conversas persistidas no banco para envio em bloco pela rede Wi-Fi
  static Future<List<Map<String, dynamic>>> obterConversasParaSincronizacao({
    String? cpf,
    String? lojaId,
  }) async {
    final db = await _obterDb();
    if (lojaId != null && lojaId.isNotEmpty) {
      return await db.query(
        'conversas_chat',
        where: 'loja_id = ?',
        whereArgs: [lojaId],
      );
    } else if (cpf != null && cpf.isNotEmpty) {
      final cpfNorm = normalizarCpf(cpf);
      return await db.query(
        'conversas_chat',
        where: '(loja_id IS NULL OR loja_id = "") AND (participantes_json LIKE ? OR id LIKE ?)',
        whereArgs: ['%$cpfNorm%', '%$cpfNorm%'],
      );
    } else {
      return await db.query('conversas_chat');
    }
  }

  /// Salva ou mescla uma conversa recebida da rede local
  static Future<void> salvarConversaLocal(Map<String, dynamic> c) async {
    final db = await _obterDb();
    await db.insert(
      'conversas_chat',
      {
        'id': c['id'],
        'titulo': c['titulo'] ?? 'Conversa',
        'subtitulo': c['subtitulo'] ?? '',
        'foto': c['foto'] ?? '',
        'identificador': c['identificador'] ?? c['id'],
        'eh_loja': (c['eh_loja'] as int?) ?? 0,
        'eh_grupo': (c['eh_grupo'] as int?) ?? 0,
        'loja_id': c['loja_id'] ?? c['lojaId'] ?? '',
        'participantes_json': c['participantes_json'] ?? '[]',
        'criado_em': c['criado_em'] ?? DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retorna as mensagens persistidas no banco para envio em bloco pela rede Wi-Fi
  static Future<List<Map<String, dynamic>>> obterMensagensParaSincronizacao({
    String? cpf,
    String? lojaId,
  }) async {
    final db = await _obterDb();
    if (cpf != null && cpf.isNotEmpty) {
      final cpfNorm = normalizarCpf(cpf);
      return await db.query(
        'mensagens_chat',
        where: 'remetente_id = ? OR destinatario_id = ? OR conversa_id LIKE ?',
        whereArgs: [cpf, cpf, '%$cpfNorm%'],
        orderBy: 'data_hora ASC',
      );
    } else if (lojaId != null && lojaId.isNotEmpty) {
      return await db.query(
        'mensagens_chat',
        where: 'remetente_id = ? OR destinatario_id = ? OR conversa_id LIKE ?',
        whereArgs: [lojaId, lojaId, '%$lojaId%'],
        orderBy: 'data_hora ASC',
      );
    } else {
      return await db.query('mensagens_chat', orderBy: 'data_hora ASC');
    }
  }

  static Future<List<MensagemChat>> carregarMensagens(
    String conversaId, {
    String? idVisualizador,
  }) async {
    final db = await _obterDb();
    final rows = await db.query(
      'mensagens_chat',
      where: 'conversa_id = ?',
      whereArgs: [conversaId],
      orderBy: 'data_hora ASC',
    );

    return rows.map((r) {
      final remetente = r['remetente_id'] as String? ?? '';
      final enviadaPorMim = idVisualizador != null &&
          (remetente == idVisualizador ||
              (normalizarCpf(remetente).isNotEmpty &&
                  normalizarCpf(remetente) == normalizarCpf(idVisualizador)));
      final lida = (r['lida'] as int? ?? 0) == 1;
      final entregue = (r['entregue'] as int? ?? 0) == 1;
      final statusEnvio = r['status_envio'] as String? ??
          (lida ? 'lida' : (entregue ? 'entregue' : 'enviada'));

      return MensagemChat(
        id: r['id'] as String? ?? '',
        conversaId: r['conversa_id'] as String? ?? '',
        remetenteId: remetente,
        remetenteNome: r['remetente_nome'] as String? ?? '',
        remetenteFoto: r['remetente_foto'] as String? ?? '',
        destinatarioId: r['destinatario_id'] as String? ?? '',
        texto: r['texto'] as String? ?? '',
        dataHora: DateTime.tryParse(r['data_hora'] as String? ?? '') ??
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
          try {
            final raw = r['historico_edicoes'] as String? ?? '[]';
            return (jsonDecode(raw) as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          } catch (_) {
            return <Map<String, dynamic>>[];
          }
        }(),
        statusEnvio: statusEnvio,
        entregue: entregue,
      );
    }).toList();
  }

  static Future<void> marcarComoLidas(
    String conversaId,
    String idLeitor,
  ) async {
    final db = await _obterDb();
    final rows = await db.query(
      'mensagens_chat',
      where: 'conversa_id = ? AND lida = 0',
      whereArgs: [conversaId],
    );

    bool alterou = false;
    for (final r in rows) {
      final remetente = r['remetente_id'] as String? ?? '';
      final ehDoProprioLeitor = remetente == idLeitor ||
          (normalizarCpf(remetente).isNotEmpty &&
              normalizarCpf(remetente) == normalizarCpf(idLeitor));

      if (!ehDoProprioLeitor) {
        await db.update(
          'mensagens_chat',
          {'lida': 1},
          where: 'id = ?',
          whereArgs: [r['id']],
        );
        alterou = true;
      }
    }

    if (alterou) {
      notificarAlteracao();
      _despacharEventoRede({
        'tipo': 'mensagens_lidas',
        'conversaId': conversaId,
        'idLeitor': idLeitor,
      });
    }
  }

  static Future<bool> temMensagensNaoLidasNaLoja(String lojaId) async {
    final db = await _obterDb();
    final rows = await db.query(
      'mensagens_chat',
      where: '(destinatario_id = ? OR conversa_id LIKE ?) AND remetente_id != ? AND lida = 0',
      whereArgs: [lojaId, 'loja_${lojaId}_%', lojaId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  static Future<List<MensagemChat>> obterMensagensNaoLidasDaLoja(String lojaId) async {
    final db = await _obterDb();
    final rows = await db.query(
      'mensagens_chat',
      where: '(destinatario_id = ? OR conversa_id LIKE ?) AND remetente_id != ? AND lida = 0',
      whereArgs: [lojaId, 'loja_${lojaId}_%', lojaId],
      orderBy: 'data_hora DESC',
    );
    return rows.map((r) => MensagemChat(
      id: r['id'] as String? ?? '',
      conversaId: r['conversa_id'] as String? ?? '',
      remetenteId: r['remetente_id'] as String? ?? '',
      remetenteNome: r['remetente_nome'] as String? ?? '',
      remetenteFoto: r['remetente_foto'] as String? ?? '',
      destinatarioId: r['destinatario_id'] as String? ?? '',
      texto: r['texto'] as String? ?? '',
      dataHora: DateTime.tryParse(r['data_hora'] as String? ?? '') ?? DateTime.now(),
      enviadaPorMim: false,
      nomeAtendente: r['nome_atendente'] as String? ?? '',
      cpfAtendente: r['cpf_atendente'] as String? ?? '',
      lida: false,
    )).toList();
  }

  static Future<void> marcarMensagensDaLojaComoLidas(
    String lojaId,
    String idLeitor,
  ) async {
    final db = await _obterDb();
    final rows = await db.query(
      'mensagens_chat',
      where: '(destinatario_id = ? OR conversa_id LIKE ?) AND remetente_id != ? AND lida = 0',
      whereArgs: [lojaId, 'loja_${lojaId}_%', idLeitor],
    );

    if (rows.isNotEmpty) {
      await db.update(
        'mensagens_chat',
        {'lida': 1},
        where: '(destinatario_id = ? OR conversa_id LIKE ?) AND remetente_id != ? AND lida = 0',
        whereArgs: [lojaId, 'loja_${lojaId}_%', idLeitor],
      );
      notificarAlteracao();
      _despacharEventoRede({
        'tipo': 'mensagens_lidas',
        'conversaId': 'loja_${lojaId}_geral',
        'idLeitor': idLeitor,
      });
    }
  }

  static Future<bool> temMensagensNaoLidasNoUsuario(String cpf) async {
    final db = await _obterDb();
    final cpfNorm = normalizarCpf(cpf);
    if (cpfNorm.isEmpty) return false;
    final rows = await db.query(
      'mensagens_chat',
      where: '(destinatario_id = ? OR conversa_id LIKE ?) AND remetente_id != ? AND lida = 0',
      whereArgs: [cpfNorm, '%$cpfNorm%', cpfNorm],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  static Future<List<MensagemChat>> obterMensagensNaoLidasDoUsuario(String cpf) async {
    final db = await _obterDb();
    final cpfNorm = normalizarCpf(cpf);
    if (cpfNorm.isEmpty) return [];
    final rows = await db.query(
      'mensagens_chat',
      where: '(destinatario_id = ? OR conversa_id LIKE ?) AND remetente_id != ? AND lida = 0',
      whereArgs: [cpfNorm, '%$cpfNorm%', cpfNorm],
      orderBy: 'data_hora DESC',
    );
    return rows.map((r) => MensagemChat(
      id: r['id'] as String? ?? '',
      conversaId: r['conversa_id'] as String? ?? '',
      remetenteId: r['remetente_id'] as String? ?? '',
      remetenteNome: r['remetente_nome'] as String? ?? '',
      remetenteFoto: r['remetente_foto'] as String? ?? '',
      destinatarioId: r['destinatario_id'] as String? ?? '',
      texto: r['texto'] as String? ?? '',
      dataHora: DateTime.tryParse(r['data_hora'] as String? ?? '') ?? DateTime.now(),
      enviadaPorMim: false,
      nomeAtendente: r['nome_atendente'] as String? ?? '',
      cpfAtendente: r['cpf_atendente'] as String? ?? '',
      lida: false,
    )).toList();
  }

  /// Retorna todos os CPFs com quem o usuário já trocou mensagens no banco local
  static Future<Map<String, ({String nome, String foto})>> obterInterlocutoresDoUsuario(String cpf) async {
    final db = await _obterDb();
    final cpfNorm = normalizarCpf(cpf);
    if (cpfNorm.isEmpty) return {};

    final rows = await db.query(
      'mensagens_chat',
      columns: ['remetente_id', 'remetente_nome', 'remetente_foto', 'destinatario_id'],
      where: 'conversa_id LIKE ? AND remetente_id != "sistema"',
      whereArgs: ['%$cpfNorm%'],
      orderBy: 'data_hora DESC',
    );

    final resultado = <String, ({String nome, String foto})>{};
    for (final r in rows) {
      final rem = normalizarCpf(r['remetente_id'] as String? ?? '');
      final dest = normalizarCpf(r['destinatario_id'] as String? ?? '');
      final outroCpf = rem == cpfNorm ? dest : rem;
      if (outroCpf.length == 11 && outroCpf != cpfNorm && !resultado.containsKey(outroCpf)) {
        final nome = rem != cpfNorm ? (r['remetente_nome'] as String? ?? '') : '';
        final foto = rem != cpfNorm ? (r['remetente_foto'] as String? ?? '') : '';
        resultado[outroCpf] = (nome: nome, foto: foto);
      }
    }
    return resultado;
  }

  static Future<int> contarNaoLidasNaConversa(
    String conversaId,
    String idVisualizador,
  ) async {
    final db = await _obterDb();
    final rows = await db.query(
      'mensagens_chat',
      where: 'conversa_id = ? AND lida = 0',
      whereArgs: [conversaId],
    );

    int count = 0;
    for (final r in rows) {
      final remetente = r['remetente_id'] as String? ?? '';
      final ehDoProprio = remetente == idVisualizador ||
          (normalizarCpf(remetente).isNotEmpty &&
              normalizarCpf(remetente) == normalizarCpf(idVisualizador));
      if (!ehDoProprio) {
        count++;
      }
    }
    return count;
  }

  static Future<ConversaChat> criarGrupo({
    required String nome,
    required List<String> membrosCpfs,
    required String autorCpf,
    required String autorNome,
    String? lojaOrigemId,
  }) async {
    final db = await _obterDb();
    final id = 'grupo_${DateTime.now().millisecondsSinceEpoch}';
    final participantes = {
      ...membrosCpfs.map(normalizarCpf),
      normalizarCpf(autorCpf),
    }.where((c) => c.isNotEmpty).toList();

    final conversa = ConversaChat(
      id: id,
      titulo: nome,
      subtitulo: 'Grupo • ${participantes.length} participantes',
      identificador: id,
      ehLoja: false,
      ehGrupo: true,
      lojaId: lojaOrigemId,
      participantesIds: participantes,
      ultimaMensagem: 'Grupo criado por $autorNome',
      dataHoraUltimaMensagem: DateTime.now(),
    );

    await db.insert(
      'conversas_chat',
      {
        'id': conversa.id,
        'titulo': conversa.titulo,
        'subtitulo': conversa.subtitulo,
        'foto': conversa.foto,
        'identificador': conversa.identificador,
        'eh_loja': conversa.ehLoja ? 1 : 0,
        'eh_grupo': 1,
        'loja_id': lojaOrigemId ?? '',
        'participantes_json': jsonEncode(participantes),
        'criado_em': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Mensagem inicial de sistema
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

    _despacharEventoRede({
      'tipo': 'grupo_criado',
      'grupo': {
        'id': conversa.id,
        'titulo': conversa.titulo,
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

    notificarAlteracao();
    return conversa;
  }

  static Future<List<ConversaChat>> carregarGrupos({
    String? cpfParticipante,
    String? lojaId,
  }) async {
    final db = await _obterDb();
    final List<Map<String, dynamic>> rows;

    if (lojaId != null && lojaId.isNotEmpty) {
      // Escopo de Loja: busca estritamente grupos desta loja
      rows = await db.query(
        'conversas_chat',
        where: 'eh_grupo = 1 AND loja_id = ?',
        whereArgs: [lojaId],
        orderBy: 'criado_em DESC',
      );
    } else {
      // Escopo Social: busca apenas grupos que NÃO pertencem a uma loja
      rows = await db.query(
        'conversas_chat',
        where: 'eh_grupo = 1 AND (loja_id IS NULL OR loja_id = "")',
        orderBy: 'criado_em DESC',
      );
    }

    final List<ConversaChat> resultado = [];
    final cpfNorm = cpfParticipante != null ? normalizarCpf(cpfParticipante) : '';

    for (final r in rows) {
      final jsonPart = r['participantes_json'] as String? ?? '[]';
      List<String> part = [];
      try {
        part = (jsonDecode(jsonPart) as List<dynamic>)
            .map((e) => e.toString())
            .toList();
      } catch (_) {}

      // No modo social, o usuário precisa ser um dos participantes do grupo
      if ((lojaId == null || lojaId.isEmpty) && cpfNorm.isNotEmpty && !part.contains(cpfNorm)) {
        continue;
      }

      final id = r['id'] as String;
      final msgs = await carregarMensagens(id, idVisualizador: cpfParticipante);
      final ultimaMsg = msgs.isNotEmpty ? msgs.last.texto : 'Grupo criado';
      final dataHoraUltima = msgs.isNotEmpty ? msgs.last.dataHora : DateTime.now();

      resultado.add(
        ConversaChat(
          id: id,
          titulo: r['titulo'] as String? ?? 'Grupo',
          subtitulo: 'Grupo • ${part.length} participantes',
          foto: r['foto'] as String? ?? '',
          identificador: id,
          ehGrupo: true,
          lojaId: r['loja_id'] as String? ?? '',
          participantesIds: part,
          ultimaMensagem: ultimaMsg,
          dataHoraUltimaMensagem: dataHoraUltima,
          mensagens: msgs,
        ),
      );
    }

    return resultado;
  }

  static Future<void> atualizarFotoGrupo(String grupoId, String caminhoFoto) async {
    final db = await _obterDb();
    await db.update(
      'conversas_chat',
      {'foto': caminhoFoto},
      where: 'id = ?',
      whereArgs: [grupoId],
    );

    _despacharEventoRede({
      'tipo': 'grupo_atualizado',
      'grupoId': grupoId,
      'foto': caminhoFoto,
    });

    notificarAlteracao();
  }

    static Future<void> editarMensagem(String id, String novoTexto) async {
      final db = await _obterDb();
      final rows = await db.query(
        'mensagens_chat',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return;

      final r = rows.first;
      final textoAntigo = r['texto'] as String? ?? '';
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
          'texto': novoTexto.trim(),
          'editada': 1,
          'historico_edicoes': jsonEncode(historico),
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      notificarAlteracao();

      _despacharEventoRede({
        'tipo': 'mensagem_editada',
        'id': id,
        'conversaId': r['conversa_id'],
        'novoTexto': novoTexto.trim(),
        'historicoEdicoes': historico,
      });
    }

    static Future<bool> excluirMensagem(String id) async {
      final db = await _obterDb();
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

      // Regra: exclusão permitida apenas até 1 minuto (60 segundos) após o envio
      if (diferencaSegundos > 60) {
        return false;
      }

      final conversaId = rows.first['conversa_id'] as String? ?? '';
      await db.delete(
        'mensagens_chat',
        where: 'id = ?',
        whereArgs: [id],
      );

      notificarAlteracao();

      _despacharEventoRede({
        'tipo': 'mensagem_excluida',
        'id': id,
        'conversaId': conversaId,
      });
      return true;
    }

    static Future<void> renomearConversa(String conversaId, String novoTitulo) async {
      final db = await _obterDb();
      final count = await db.update(
        'conversas_chat',
        {'titulo': novoTitulo.trim()},
        where: 'id = ?',
        whereArgs: [conversaId],
      );
      if (count == 0) {
        await db.insert(
          'conversas_chat',
          {
            'id': conversaId,
            'titulo': novoTitulo.trim(),
            'subtitulo': '',
            'identificador': conversaId,
            'eh_loja': 0,
            'eh_grupo': 0,
            'participantes_json': '[]',
            'criado_em': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      notificarAlteracao();

      _despacharEventoRede({
        'tipo': 'conversa_renomeada',
        'conversaId': conversaId,
        'novoTitulo': novoTitulo.trim(),
      });
    }

    static Future<Map<String, String>> obterTitulosCustomizados() async {
      final db = await _obterDb();
      final rows = await db.query('conversas_chat', columns: ['id', 'titulo']);
      final mapa = <String, String>{};
      for (final r in rows) {
        final id = r['id'] as String? ?? '';
        final tit = r['titulo'] as String? ?? '';
        if (id.isNotEmpty && tit.isNotEmpty) {
          mapa[id] = tit;
        }
      }
      return mapa;
    }

    static Future<void> excluirConversaLocal(String conversaId) async {
      final db = await _obterDb();
      await db.delete('mensagens_chat', where: 'conversa_id = ?', whereArgs: [conversaId]);
      await db.delete('conversas_chat', where: 'id = ?', whereArgs: [conversaId]);
      notificarAlteracao();
    }

    static void _despacharEventoRede(Map<String, dynamic> evento) {
      try {
        final servidor = ServidorRedeLocal();
        if (servidor.ativo) {
          servidor.notificarTodos({
            'tipo': 'mensagem_chat',
            'mensagem': evento,
          });
          return;
        }
        final cliente = ClienteRedeLocal();
        if (cliente.conectado) {
          cliente.enviarMensagemRaw({
            'tipo': 'mensagem_chat',
            'mensagem': evento,
          });
        }
      } catch (e) {
        debugPrint('[ChatService] Erro ao despachar evento para a rede: $e');
      }
    }
  }
