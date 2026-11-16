import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/core/services/gerador_id.dart';
import 'package:nous/src/features/chat/services/chat_repositorio_sqlite.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

/// Gerencia a fila persistente de eventos de chat (Outbox) para que edições,
/// exclusões, reações e confirmações de leitura não se percam offline, além
/// da tabela relacional de recibos por participante (`recibos_leitura_chat`).
class ChatOutboxERecibosService {
  ChatOutboxERecibosService._();

  static bool _tabelasCriadas = false;

  static Future<Database> _obterDb() async {
    final db = await BancoDadosService.db;
    if (!_tabelasCriadas) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS outbox_eventos_chat (
          id TEXT PRIMARY KEY,
          tipo TEXT NOT NULL,
          payload_json TEXT NOT NULL,
          criado_em TEXT NOT NULL
        );
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS recibos_leitura_chat (
          mensagem_id TEXT NOT NULL,
          leitor_id TEXT NOT NULL,
          entregue_em TEXT,
          lida_em TEXT,
          PRIMARY KEY (mensagem_id, leitor_id)
        );
      ''');
      _tabelasCriadas = true;
    }
    return db;
  }

  /// Enfileira um evento de chat para envio posterior quando a rede estiver disponível.
  static Future<void> enfileirarEvento(Map<String, dynamic> evento) async {
    try {
      final tipo = evento['tipo']?.toString() ?? '';
      if (tipo.isEmpty) return;
      final db = await _obterDb();
      await db.insert(
        'outbox_eventos_chat',
        {
          'id': 'evt_${gerarIdUnico()}',
          'tipo': tipo,
          'payload_json': jsonEncode(evento),
          'criado_em': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('[ChatOutbox] Erro ao enfileirar evento: $e');
    }
  }

  /// Drena eventos pendentes no Outbox assim que houver conexão ativa.
  static Future<int> drenarEventosPendentes() async {
    final servidor = ServidorRedeLocal();
    final cliente = ClienteRedeLocal();
    if (!servidor.ativo && !cliente.conectado) return 0;

    int enviados = 0;
    try {
      final db = await _obterDb();
      final rows = await db.query(
        'outbox_eventos_chat',
        orderBy: 'criado_em ASC',
        limit: 100,
      );
      for (final row in rows) {
        final id = row['id']?.toString() ?? '';
        final raw = row['payload_json']?.toString() ?? '';
        if (id.isEmpty || raw.isEmpty) continue;
        try {
          final evento = jsonDecode(raw) as Map<String, dynamic>;
          if (servidor.ativo) {
            servidor.notificarTodos(evento);
          } else if (cliente.conectado) {
            cliente.enviarEventoWs(evento);
          } else {
            break;
          }
          await db.delete(
            'outbox_eventos_chat',
            where: 'id = ?',
            whereArgs: [id],
          );
          enviados++;
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[ChatOutbox] Erro ao drenar eventos pendentes: $e');
    }
    return enviados;
  }

  /// Registra entrega para um participante específico na tabela relacional de recibos.
  static Future<void> registrarEntrega(String mensagemId, String leitorId) async {
    if (mensagemId.isEmpty || leitorId.isEmpty) return;
    try {
      final db = await _obterDb();
      final agora = DateTime.now().toIso8601String();
      await db.rawInsert('''
        INSERT INTO recibos_leitura_chat (mensagem_id, leitor_id, entregue_em)
        VALUES (?, ?, ?)
        ON CONFLICT(mensagem_id, leitor_id) DO UPDATE SET
          entregue_em = COALESCE(recibos_leitura_chat.entregue_em, excluded.entregue_em)
      ''', [mensagemId, leitorId, agora]);
    } catch (_) {}
  }

  /// Registra leitura de todas as mensagens recebidas na conversa para um leitor específico.
  static Future<void> registrarLeituraConversa(
    String conversaId,
    String leitorId,
  ) async {
    if (conversaId.isEmpty || leitorId.isEmpty) return;
    try {
      final db = await _obterDb();
      final agora = DateTime.now().toIso8601String();
      final rows = await db.query(
        'mensagens_chat',
        columns: ['id'],
        where: 'conversa_id = ? AND remetente_id != ?',
        whereArgs: [conversaId, leitorId],
      );
      for (final r in rows) {
        final msgId = r['id']?.toString() ?? '';
        if (msgId.isEmpty) continue;
        await db.rawInsert('''
          INSERT INTO recibos_leitura_chat (mensagem_id, leitor_id, entregue_em, lida_em)
          VALUES (?, ?, ?, ?)
          ON CONFLICT(mensagem_id, leitor_id) DO UPDATE SET
            entregue_em = COALESCE(recibos_leitura_chat.entregue_em, excluded.entregue_em),
            lida_em = COALESCE(recibos_leitura_chat.lida_em, excluded.lida_em)
        ''', [msgId, leitorId, agora, agora]);
      }
    } catch (_) {}
  }

  /// Autocura de integridade temporal: normaliza mensagens que ficaram com horários
  /// no futuro devido a divergências de timezone (ex: UTC não convertido).
  static Future<void> curarTimestampsAnomalosDoPassado() async {
    try {
      final db = await ChatRepositorioSqlite.obterDb();
      final agora = DateTime.now();
      final limiteFuturo =
          agora.add(const Duration(minutes: 5)).toIso8601String();
      final noFuturo = await db.query(
        'mensagens_chat',
        columns: ['id', 'data_hora'],
        where: 'data_hora > ?',
        whereArgs: [limiteFuturo],
      );
      for (final m in noFuturo) {
        final id = m['id'] as String;
        final dataStr = m['data_hora'] as String;
        final dt = DateTime.tryParse(dataStr);
        if (dt != null) {
          final diffHoras = dt.difference(agora).inHours;
          final DateTime corrigida;
          if (diffHoras >= 2 && diffHoras <= 4) {
            corrigida = dt.subtract(const Duration(hours: 3));
          } else {
            corrigida = agora;
          }
          await db.update(
            'mensagens_chat',
            {'data_hora': corrigida.toIso8601String()},
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      }
    } catch (_) {}
  }
}
