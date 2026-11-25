import 'package:flutter/foundation.dart';
import 'package:nous/src/features/chat/services/chat_repositorio_sqlite.dart';
import 'package:nous/src/features/chat/services/chat_sincronizacao_service.dart';

/// Helper para ações em mensagens e conversas locais com despacho de eventos na rede.
class ChatAcoesHelper {
  ChatAcoesHelper._();

  static Future<void> excluirConversaLocal(
    String conversaId, {
    bool originadoDaRede = false,
    required VoidCallback aoNotificar,
  }) async {
    await ChatRepositorioSqlite.excluirConversaLocal(conversaId);
    aoNotificar();
    if (!originadoDaRede) {
      ChatSincronizacaoService.despacharEventoRede({
        'tipo': 'conversa_excluida',
        'conversaId': conversaId,
      });
    }
  }

  static Future<bool> alternarFixarMensagem(
    String msgId, {
    bool? fixar,
    String? conversaId,
    required VoidCallback aoNotificar,
  }) async {
    final novo = await ChatRepositorioSqlite.alternarFixarMensagem(
      msgId,
      fixar: fixar,
    );
    aoNotificar();
    ChatSincronizacaoService.despacharEventoRede({
      'tipo': 'mensagem_fixada',
      'id': msgId,
      'conversaId': conversaId ?? '',
      'fixada': novo,
    });
    return novo;
  }

  static Future<Map<String, String>> reagirMensagem(
    String msgId,
    String autorId,
    String emoji, {
    String? conversaId,
    required VoidCallback aoNotificar,
  }) async {
    final reacoes = await ChatRepositorioSqlite.reagirMensagem(
      msgId,
      autorId,
      emoji,
    );
    aoNotificar();
    ChatSincronizacaoService.despacharEventoRede({
      'tipo': 'mensagem_reacao',
      'id': msgId,
      'conversaId': conversaId ?? '',
      'reacoes': reacoes,
    });
    return reacoes;
  }

  static Future<void> atualizarDadosComandaMensagem({
    required String msgId,
    required String dadosPedidoJson,
    String? texto,
    required VoidCallback aoNotificar,
  }) async {
    final db = await ChatRepositorioSqlite.obterDb();
    await db.update(
      'mensagens_chat',
      {
        'dados_pedido_json': dadosPedidoJson,
        if (texto != null && texto.isNotEmpty) 'texto': texto,
      },
      where: 'id = ?',
      whereArgs: [msgId],
    );
    aoNotificar();
    ChatSincronizacaoService.despacharEventoRede({
      'tipo': 'comanda_atualizada',
      'id': msgId,
      'dadosPedidoJson': dadosPedidoJson,
      'texto': ?texto,
    });
  }
}
