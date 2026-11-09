import 'dart:convert';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/features/pdv/models/pagamento_funcionario.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class PagamentosRepositorioLoja {
  static const int limitePadraoMemoria = 100;

  static Future<List<PagamentoFuncionario>> carregarParaMemoria(
    String lojaId, {
    DatabaseExecutor? executor,
    int limite = limitePadraoMemoria,
  }) async {
    final db = executor ?? await BancoDadosService.db;
    final rows = await db.query(
      'pagamentos_funcionarios',
      where: 'loja_id = ?',
      whereArgs: [lojaId],
      orderBy: 'data_hora DESC',
      limit: limite,
    );

    return rows
        .map((r) =>
            PagamentoFuncionario.fromJson(jsonDecode(r['dados_json'] as String)))
        .toList();
  }

  static Future<void> salvarLote(
    DatabaseExecutor executor,
    String lojaId,
    List<PagamentoFuncionario> pagamentos,
  ) async {
    if (pagamentos.isEmpty) return;

    for (final pag in pagamentos) {
      final dadosJson = jsonEncode(pag.toJson());
      await executor.insert(
        'pagamentos_funcionarios',
        {
          'id': pag.id,
          'loja_id': lojaId,
          'data_hora': pag.dataHora.toIso8601String(),
          'valor': pag.valor,
          'dados_json': dadosJson,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  static Future<void> excluirPorId(
    String lojaId,
    String pagamentoId, {
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await BancoDadosService.db;
    await db.delete(
      'pagamentos_funcionarios',
      where: 'loja_id = ? AND id = ?',
      whereArgs: [lojaId, pagamentoId],
    );
  }

  static Future<void> excluirTodosDaLoja(
    String lojaId, {
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await BancoDadosService.db;
    await db.delete(
      'pagamentos_funcionarios',
      where: 'loja_id = ?',
      whereArgs: [lojaId],
    );
  }

  static Future<List<PagamentoFuncionario>> carregarPaginado({
    required String lojaId,
    int limite = 50,
    int offset = 0,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? cpfFuncionario,
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
      'pagamentos_funcionarios',
      where: condicoes.join(' AND '),
      whereArgs: args,
      orderBy: 'data_hora DESC',
      limit: limite,
      offset: offset,
    );

    var lista = rows
        .map((r) =>
            PagamentoFuncionario.fromJson(jsonDecode(r['dados_json'] as String)))
        .toList();

    if (cpfFuncionario != null && cpfFuncionario.isNotEmpty) {
      lista = lista.where((p) => p.cpf == cpfFuncionario).toList();
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
      'SELECT COUNT(*) as total FROM pagamentos_funcionarios WHERE ${condicoes.join(' AND ')}',
      args,
    );

    if (resultado.isEmpty) return 0;
    final valor = resultado.first['total'];
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    return 0;
  }
}
