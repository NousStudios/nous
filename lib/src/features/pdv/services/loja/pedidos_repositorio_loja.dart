import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';

/// Repositório SQLite especializado em consultas e persistência de pedidos de loja,
/// com suporte nativo a paginação, lazy-loading e retenção inteligente em memória RAM.
class PedidosRepositorioLoja {
  PedidosRepositorioLoja._();

  /// Carrega os pedidos ativos (em aberto/andamento) e os últimos [limiteHistorico]
  /// pedidos concluídos/cancelados para consumo em memória sem sobrecarregar o Heap.
  static Future<List<PedidoLoja>> carregarParaMemoria(
    String lojaId, {
    int? limiteHistorico = 80,
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await BancoDadosService.db;

    if (limiteHistorico == null || limiteHistorico <= 0) {
      final pedRows = await db.query(
        'pedidos',
        where: 'loja_id = ?',
        whereArgs: [lojaId],
        orderBy: 'data_hora DESC',
      );
      return pedRows
          .map((r) => PedidoLoja.fromJson(jsonDecode(r['dados_json'] as String)))
          .toList();
    }

    // 1. Sempre carrega todos os pedidos ativos (novo e aceito) para nenhuma operação ficar oculta
    final ativosRows = await db.query(
      'pedidos',
      where: 'loja_id = ? AND status IN (?, ?)',
      whereArgs: [lojaId, StatusPedido.novo.name, StatusPedido.aceito.name],
      orderBy: 'data_hora DESC',
    );
    final pedidosAtivos = ativosRows
        .map((r) => PedidoLoja.fromJson(jsonDecode(r['dados_json'] as String)))
        .toList();

    // 2. Carrega a janela mais recente de pedidos finalizados
    final historicoRows = await db.query(
      'pedidos',
      where: 'loja_id = ? AND status NOT IN (?, ?)',
      whereArgs: [lojaId, StatusPedido.novo.name, StatusPedido.aceito.name],
      orderBy: 'data_hora DESC',
      limit: limiteHistorico,
    );
    final pedidosHistorico = historicoRows
        .map((r) => PedidoLoja.fromJson(jsonDecode(r['dados_json'] as String)))
        .toList();

    final todos = <PedidoLoja>[...pedidosAtivos, ...pedidosHistorico];
    todos.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return todos;
  }

  /// Consulta paginada sob demanda diretamente no banco SQLite para relatórios,
  /// históricos de períodos extensos e telas de auditoria.
  static Future<List<PedidoLoja>> carregarPaginado({
    required String lojaId,
    int limite = 100,
    int offset = 0,
    DateTime? dataInicio,
    DateTime? dataFim,
    StatusPedido? status,
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await BancoDadosService.db;
    final whereClauses = <String>['loja_id = ?'];
    final whereArgs = <dynamic>[lojaId];

    if (dataInicio != null) {
      whereClauses.add('data_hora >= ?');
      whereArgs.add(dataInicio.toIso8601String());
    }
    if (dataFim != null) {
      whereClauses.add('data_hora <= ?');
      whereArgs.add(dataFim.toIso8601String());
    }
    if (status != null) {
      whereClauses.add('status = ?');
      whereArgs.add(status.name);
    }

    final rows = await db.query(
      'pedidos',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'data_hora DESC',
      limit: limite,
      offset: offset,
    );

    return rows
        .map((r) => PedidoLoja.fromJson(jsonDecode(r['dados_json'] as String)))
        .toList();
  }

  /// Conta o total de pedidos que correspondem aos filtros sem decodificar objetos na memória.
  static Future<int> contarTotal({
    required String lojaId,
    DateTime? dataInicio,
    DateTime? dataFim,
    StatusPedido? status,
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await BancoDadosService.db;
    final whereClauses = <String>['loja_id = ?'];
    final whereArgs = <dynamic>[lojaId];

    if (dataInicio != null) {
      whereClauses.add('data_hora >= ?');
      whereArgs.add(dataInicio.toIso8601String());
    }
    if (dataFim != null) {
      whereClauses.add('data_hora <= ?');
      whereArgs.add(dataFim.toIso8601String());
    }
    if (status != null) {
      whereClauses.add('status = ?');
      whereArgs.add(status.name);
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) as total FROM pedidos WHERE ${whereClauses.join(' AND ')}',
      whereArgs,
    );
    if (result.isNotEmpty && result.first.containsKey('total')) {
      final val = result.first['total'];
      if (val is int) return val;
      if (val is num) return val.toInt();
    }
    return 0;
  }

  /// Insere ou atualiza um pedido individualmente de forma rápida no SQLite sem reescrever a loja inteira.
  static Future<void> salvarIndividual(
    PedidoLoja pedido, {
    String? lojaIdFallback,
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await BancoDadosService.db;
    final lId = pedido.lojaId.isNotEmpty ? pedido.lojaId : (lojaIdFallback ?? '');
    await db.insert(
      'pedidos',
      {
        'id': pedido.id,
        'loja_id': lId,
        'numero': pedido.numero,
        'data_hora': pedido.dataHora.toIso8601String(),
        'status': pedido.status.name,
        'valor': pedido.valor,
        'cliente_nome': pedido.clienteNome,
        'dados_json': jsonEncode(pedido.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insere ou atualiza pedidos em lote de forma transacional e não-destrutiva.
  static Future<void> salvarLote(
    DatabaseExecutor txn,
    String lojaId,
    List<PedidoLoja> pedidos,
  ) async {
    for (final p in pedidos) {
      await txn.insert(
        'pedidos',
        {
          'id': p.id,
          'loja_id': p.lojaId.isNotEmpty ? p.lojaId : lojaId,
          'numero': p.numero,
          'data_hora': p.dataHora.toIso8601String(),
          'status': p.status.name,
          'valor': p.valor,
          'cliente_nome': p.clienteNome,
          'dados_json': jsonEncode(p.toJson()),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  static Future<void> excluirPorId(
    String lojaId,
    String pedidoId, {
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await BancoDadosService.db;
    await db.delete(
      'pedidos',
      where: 'loja_id = ? AND id = ?',
      whereArgs: [lojaId, pedidoId],
    );
  }

  static Future<void> excluirTodosDaLoja(
    String lojaId, {
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await BancoDadosService.db;
    await db.delete(
      'pedidos',
      where: 'loja_id = ?',
      whereArgs: [lojaId],
    );
  }
}
