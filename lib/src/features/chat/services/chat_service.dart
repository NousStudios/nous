import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/core/services/som_service.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

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
          lida INTEGER NOT NULL DEFAULT 0
        );
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_chat_conversa ON mensagens_chat (conversa_id);',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_chat_destinatario ON mensagens_chat (destinatario_id);',
      );

      await db.execute('''
        CREATE TABLE IF NOT EXISTS conversas_chat (
          id TEXT PRIMARY KEY,
          titulo TEXT NOT NULL,
          subtitulo TEXT,
          foto TEXT,
          identificador TEXT NOT NULL,
          eh_loja INTEGER NOT NULL DEFAULT 0,
          eh_grupo INTEGER NOT NULL DEFAULT 0,
          participantes_json TEXT,
          criado_em TEXT NOT NULL
        );
      ''');

      _tabelasCriadas = true;
    }
    return db;
  }

  static Future<void> salvarMensagem(
    MensagemChat mensagem, {
    bool originadaDaRede = false,
  }) async {
    final db = await _obterDb();
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
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notificarAlteracao();

    if (!originadaDaRede) {
      await despacharMensagemParaRede(mensagem);
    }
  }

  /// Despacha a mensagem para a malha da rede local (seja via servidor balcão ou cliente móvel)
  static Future<void> despacharMensagemParaRede(MensagemChat mensagem) async {
    try {
      final servidor = ServidorRedeLocal();
      if (servidor.ativo) {
        servidor.notificarTodos({
          'tipo': 'mensagem_chat',
          'mensagem': mensagem.toJson(),
        });
        return;
      }

      final cliente = ClienteRedeLocal();
      if (cliente.conectado) {
        await cliente.enviarMensagemChat(mensagem);
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
      final mensagem = MensagemChat.fromJson(dadosMensagem);
      await salvarMensagem(mensagem, originadaDaRede: true);
      if (emitirAlertaSonoro) {
        SomService.tocarBipPadrao();
      }
    } catch (e) {
      debugPrint('[ChatService] Erro ao processar mensagem recebida da rede: $e');
    }
  }

  /// Sincroniza mensagens do balcão ao conectar um terminal móvel na rede local
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
              final msg = MensagemChat.fromJson(item);
              await salvarMensagem(msg, originadaDaRede: true);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[ChatService] Erro ao sincronizar mensagens com balcão: $e');
    }
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
        lida: (r['lida'] as int? ?? 1) == 1,
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
        'participantes_json': jsonEncode(participantes),
        'criado_em': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Mensagem inicial de sistema
    await salvarMensagem(
      MensagemChat(
        id: 'msg_sys_${DateTime.now().millisecondsSinceEpoch}',
        conversaId: id,
        remetenteId: 'sistema',
        remetenteNome: 'Sistema',
        destinatarioId: id,
        texto: '$autorNome criou o grupo "$nome".',
        dataHora: DateTime.now(),
        lida: true,
      ),
    );

    notificarAlteracao();
    return conversa;
  }

  static Future<List<ConversaChat>> carregarGrupos({
    String? cpfParticipante,
  }) async {
    final db = await _obterDb();
    final rows = await db.query(
      'conversas_chat',
      where: 'eh_grupo = 1',
      orderBy: 'criado_em DESC',
    );

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

      if (cpfNorm.isNotEmpty && !part.contains(cpfNorm)) {
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
          identificador: id,
          ehGrupo: true,
          participantesIds: part,
          ultimaMensagem: ultimaMsg,
          dataHoraUltimaMensagem: dataHoraUltima,
          mensagens: msgs,
        ),
      );
    }

    return resultado;
  }
}
