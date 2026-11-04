import 'dart:convert';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MovimentosRepositorioLoja {
  static const int limitePadraoMemoria = 2000;

  static Future<List<MovimentoEstoque>> carregarParaMemoria(
    String lojaId, {
    DatabaseExecutor? executor,
    int limite = limitePadraoMemoria,
  }) async {
    final db = executor ?? await BancoDadosService.db;
    final rows = await db.query(
      'movimentos_estoque',
      where: 'loja_id = ?',
      whereArgs: [lojaId],
      orderBy: 'data_hora DESC',
      limit: limite,
    );

    return rows
        .map((r) =>
            MovimentoEstoque.fromJson(jsonDecode(r['dados_json'] as String)))
        .toList();
  }

  static Future<void> salvarLote(
    DatabaseExecutor executor,
    String lojaId,
    List<MovimentoEstoque> movimentos,
  ) async {
    if (movimentos.isEmpty) return;

    for (final mov in movimentos) {
      final dadosJson = jsonEncode(mov.toJson());
      await executor.insert(
        'movimentos_estoque',
        {
          'id': mov.id,
          'loja_id': lojaId,
          'item_id': mov.itemId,
          'tipo': mov.tipo.name,
          'data_hora': mov.dataHora.toIso8601String(),
          'custo_total': mov.custoTotal,
          'dados_json': dadosJson,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  static Future<void> excluirPorId(
    String lojaId,
    String movimentoId, {
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await BancoDadosService.db;
    await db.delete(
      'movimentos_estoque',
      where: 'loja_id = ? AND id = ?',
      whereArgs: [lojaId, movimentoId],
    );
  }

  static Future<void> excluirTodosDaLoja(
    String lojaId, {
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await BancoDadosService.db;
    await db.delete(
      'movimentos_estoque',
      where: 'loja_id = ?',
      whereArgs: [lojaId],
    );
  }

  static Future<List<MovimentoEstoque>> carregarPaginado({
    required String lojaId,
    int limite = 50,
    int offset = 0,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? itemId,
  }) async {
    final db = await BancoDadosService.db;
    final condicoes = <String>['loja_id = ?'];
    final args = <dynamic>[lojaId];

    if (dataInicio != null) {
      condicoes.add('data_hora >= ?');
      args.add(dataInicio.toIso8601String());
    }
    if (dataFim != null) {
      condicoes.add('data_hora <= ?');
      args.add(dataFim.toIso8601String());
    }

    final rows = await db.query(
      'movimentos_estoque',
      where: condicoes.join(' AND '),
      whereArgs: args,
      orderBy: 'data_hora DESC',
      limit: limite,
      offset: offset,
    );

    var lista = rows
        .map((r) =>
            MovimentoEstoque.fromJson(jsonDecode(r['dados_json'] as String)))
        .toList();

    if (itemId != null && itemId.isNotEmpty) {
      lista = lista.where((m) => m.itemId == itemId).toList();
    }

    return lista;
  }

  static Future<int> contarTotal({
    required String lojaId,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    final db = await BancoDadosService.db;
    final condicoes = <String>['loja_id = ?'];
    final args = <dynamic>[lojaId];

    if (dataInicio != null) {
      condicoes.add('data_hora >= ?');
      args.add(dataInicio.toIso8601String());
    }
    if (dataFim != null) {
      condicoes.add('data_hora <= ?');
      args.add(dataFim.toIso8601String());
    }

    final resultado = await db.rawQuery(
      'SELECT COUNT(*) as total FROM movimentos_estoque WHERE ${condicoes.join(' AND ')}',
      args,
    );

    if (resultado.isNotEmpty && resultado.first.containsKey('total')) {
      final val = resultado.first['total'];
      if (val is int) return val;
      if (val is num) return val.toInt();
    }
    return 0;
  }
}
