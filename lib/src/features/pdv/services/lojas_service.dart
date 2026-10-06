import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pagamento_funcionario.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/referencia_loja.dart';

class LojasService {
  LojasService._();

  static Future<List<Loja>> carregar(String cpf) async {
    final db = await BancoDadosService.db;
    final rows = await db.query(
      'lojas',
      where: 'cpf_dono = ?',
      whereArgs: [cpf],
    );

    if (rows.isEmpty) return [];

    final listaLojas = <Loja>[];
    for (final row in rows) {
      final lojaMap =
          jsonDecode(row['dados_json'] as String) as Map<String, dynamic>;
      final lojaId = row['id'] as String;

      final pedRows = await db.query(
        'pedidos',
        where: 'loja_id = ?',
        whereArgs: [lojaId],
        orderBy: 'data_hora DESC',
      );
      final pedidos = pedRows
          .map((r) =>
              PedidoLoja.fromJson(jsonDecode(r['dados_json'] as String)))
          .toList();

      final estRows = await db.query(
        'movimentos_estoque',
        where: 'loja_id = ?',
        whereArgs: [lojaId],
        orderBy: 'data_hora DESC',
      );
      final movimentos = estRows
          .map((r) =>
              MovimentoEstoque.fromJson(jsonDecode(r['dados_json'] as String)))
          .toList();

      final pagRows = await db.query(
        'pagamentos_funcionarios',
        where: 'loja_id = ?',
        whereArgs: [lojaId],
        orderBy: 'data_hora DESC',
      );
      final pagamentos = pagRows
          .map((r) => PagamentoFuncionario.fromJson(
              jsonDecode(r['dados_json'] as String)))
          .toList();

      final loja = Loja.fromJson(lojaMap).copyWith(
        pedidosLoja: pedidos,
        movimentosEstoque: movimentos,
        pagamentosFuncionarios: pagamentos,
      );
      listaLojas.add(loja);
    }

    return listaLojas;
  }

  static Future<void> salvar(String cpf, List<Loja> lojas) async {
    final db = await BancoDadosService.db;

    await db.transaction((txn) async {
      final idsAtuais = lojas.map((l) => l.id).toList();

      if (idsAtuais.isEmpty) {
        await txn.delete('lojas', where: 'cpf_dono = ?', whereArgs: [cpf]);
      } else {
        final placeholders = List.filled(idsAtuais.length, '?').join(',');
        await txn.delete(
          'lojas',
          where: 'cpf_dono = ? AND id NOT IN ($placeholders)',
          whereArgs: [cpf, ...idsAtuais],
        );
      }

      for (final loja in lojas) {
        final lojaMap = loja.toJson();
        final lojaBaseMap = Map<String, dynamic>.from(lojaMap)
          ..['pedidosLoja'] = const []
          ..['movimentosEstoque'] = const []
          ..['pagamentosFuncionarios'] = const [];

        await txn.insert(
          'lojas',
          {
            'id': loja.id,
            'cpf_dono':
                loja.cpfDonoOriginal.isNotEmpty ? loja.cpfDonoOriginal : cpf,
            'nome': loja.nome,
            'dados_json': jsonEncode(lojaBaseMap),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        final pedidosIds = <String>[];
        for (final p in loja.pedidosLoja) {
          pedidosIds.add(p.id);
          await txn.insert(
            'pedidos',
            {
              'id': p.id,
              'loja_id': loja.id,
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

        if (pedidosIds.isEmpty) {
          await txn
              .delete('pedidos', where: 'loja_id = ?', whereArgs: [loja.id]);
        } else {
          final pPlaceholders = List.filled(pedidosIds.length, '?').join(',');
          await txn.delete(
            'pedidos',
            where: 'loja_id = ? AND id NOT IN ($pPlaceholders)',
            whereArgs: [loja.id, ...pedidosIds],
          );
        }

        final estoqueIds = <String>[];
        for (final m in loja.movimentosEstoque) {
          estoqueIds.add(m.id);
          await txn.insert(
            'movimentos_estoque',
            {
              'id': m.id,
              'loja_id': loja.id,
              'item_id': m.itemId,
              'tipo': m.tipo.name,
              'data_hora': m.dataHora.toIso8601String(),
              'custo_total': m.custoTotal,
              'dados_json': jsonEncode(m.toJson()),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        if (estoqueIds.isEmpty) {
          await txn.delete('movimentos_estoque',
              where: 'loja_id = ?', whereArgs: [loja.id]);
        } else {
          final ePlaceholders = List.filled(estoqueIds.length, '?').join(',');
          await txn.delete(
            'movimentos_estoque',
            where: 'loja_id = ? AND id NOT IN ($ePlaceholders)',
            whereArgs: [loja.id, ...estoqueIds],
          );
        }

        final pagamentosIds = <String>[];
        for (final pag in loja.pagamentosFuncionarios) {
          pagamentosIds.add(pag.id);
          await txn.insert(
            'pagamentos_funcionarios',
            {
              'id': pag.id,
              'loja_id': loja.id,
              'data_hora': pag.dataHora.toIso8601String(),
              'valor': pag.valor,
              'dados_json': jsonEncode(pag.toJson()),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        if (pagamentosIds.isEmpty) {
          await txn.delete('pagamentos_funcionarios',
              where: 'loja_id = ?', whereArgs: [loja.id]);
        } else {
          final pagPlaceholders =
              List.filled(pagamentosIds.length, '?').join(',');
          await txn.delete(
            'pagamentos_funcionarios',
            where: 'loja_id = ? AND id NOT IN ($pagPlaceholders)',
            whereArgs: [loja.id, ...pagamentosIds],
          );
        }
      }
    });
  }

  static Future<void> excluirTodas(String cpf) async {
    final db = await BancoDadosService.db;
    final lojas = await carregar(cpf);
    await db.transaction((txn) async {
      for (final l in lojas) {
        await txn
            .delete('pedidos', where: 'loja_id = ?', whereArgs: [l.id]);
        await txn.delete('movimentos_estoque',
            where: 'loja_id = ?', whereArgs: [l.id]);
        await txn.delete('pagamentos_funcionarios',
            where: 'loja_id = ?', whereArgs: [l.id]);
      }
      await txn.delete('lojas', where: 'cpf_dono = ?', whereArgs: [cpf]);
      await txn
          .delete('referencias_loja', where: 'cpf = ?', whereArgs: [cpf]);
    });
  }

  static Future<List<ReferenciaLoja>> carregarReferencias(String cpf) async {
    final db = await BancoDadosService.db;
    final rows = await db.query(
      'referencias_loja',
      where: 'cpf = ?',
      whereArgs: [cpf],
    );
    return rows
        .map((r) =>
            ReferenciaLoja.fromJson(jsonDecode(r['dados_json'] as String)))
        .toList();
  }

  static Future<void> salvarReferencias(
    String cpf,
    List<ReferenciaLoja> referencias,
  ) async {
    final db = await BancoDadosService.db;
    await db.transaction((txn) async {
      await txn
          .delete('referencias_loja', where: 'cpf = ?', whereArgs: [cpf]);
      for (final ref in referencias) {
        final refId = '$cpf-${ref.lojaId}';
        await txn.insert(
          'referencias_loja',
          {
            'id': refId,
            'cpf': cpf,
            'loja_id': ref.lojaId,
            'dados_json': jsonEncode(ref.toJson()),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  static Future<void> adicionarReferencia(
    String cpf,
    ReferenciaLoja referencia,
  ) async {
    final atuais = await carregarReferencias(cpf);
    final jaTem = atuais.any((r) => r.lojaId == referencia.lojaId);
    if (jaTem) return;
    await salvarReferencias(cpf, [...atuais, referencia]);
  }

  static Future<void> removerReferencia(String cpf, String lojaId) async {
    final db = await BancoDadosService.db;
    await db.delete(
      'referencias_loja',
      where: 'cpf = ? AND loja_id = ?',
      whereArgs: [cpf, lojaId],
    );
  }
}