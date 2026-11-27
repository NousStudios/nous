import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/features/busca/models/avaliacao_produto.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

class AvaliacoesProdutoService {
  AvaliacoesProdutoService._();

  static bool _tabelaCriada = false;

  /// Notificador reativo incrementado sempre que uma avaliação ou reação muda
  /// (localmente ou vinda da rede Wi-Fi local).
  static final ValueNotifier<int> versaoAtualizacao = ValueNotifier<int>(0);

  static Future<void> _garantirTabela(Database db) async {
    if (_tabelaCriada) return;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS avaliacoes_produtos (
        id TEXT PRIMARY KEY,
        item_id TEXT NOT NULL,
        loja_id TEXT NOT NULL,
        autor_cpf TEXT NOT NULL,
        autor_nome TEXT NOT NULL,
        autor_foto TEXT,
        estrelas INTEGER NOT NULL,
        comentario TEXT NOT NULL,
        criado_em TEXT NOT NULL,
        curtidas INTEGER DEFAULT 0,
        descurtidas INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_avaliacoes_item ON avaliacoes_produtos (item_id)
    ''');
    _tabelaCriada = true;
  }

  static void _notificarAlteracao() {
    versaoAtualizacao.value++;
  }

  /// Retorna as avaliações de um produto específico, opcionalmente filtradas por estrelas.
  static Future<List<AvaliacaoProduto>> obterAvaliacoes(
    String itemId, {
    int? filtroEstrelas,
  }) async {
    try {
      final db = await BancoDadosService.db;
      await _garantirTabela(db);

      String where = 'item_id = ?';
      final whereArgs = <dynamic>[itemId];

      if (filtroEstrelas != null && filtroEstrelas >= 1 && filtroEstrelas <= 5) {
        where += ' AND estrelas = ?';
        whereArgs.add(filtroEstrelas);
      }

      final rows = await db.query(
        'avaliacoes_produtos',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'criado_em DESC',
      );

      final lista = rows.map((r) => AvaliacaoProduto.fromJson(r)).toList();
      return lista;
    } catch (e) {
      debugPrint('[AvaliacoesProdutoService] Erro ao buscar avaliações: $e');
      return const [];
    }
  }

  /// Calcula o resumo de notas médias e distribuição de estrelas de um produto.
  static Future<ResumoAvaliacoesProduto> obterResumoEstrelas(String itemId) async {
    final avaliacoes = await obterAvaliacoes(itemId);
    if (avaliacoes.isEmpty) {
      return ResumoAvaliacoesProduto.vazio;
    }

    int soma = 0;
    final contagem = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (final a in avaliacoes) {
      soma += a.estrelas;
      contagem[a.estrelas] = (contagem[a.estrelas] ?? 0) + 1;
    }

    final media = soma / avaliacoes.length;
    return ResumoAvaliacoesProduto(
      mediaEstrelas: double.parse(media.toStringAsFixed(1)),
      totalAvaliacoes: avaliacoes.length,
      contagemPorEstrela: contagem,
    );
  }

  /// Insere uma nova avaliação para um produto e despacha imediatamente pela rede Wi-Fi local.
  static Future<bool> adicionarAvaliacao({
    required String itemId,
    required String lojaId,
    required String autorCpf,
    required String autorNome,
    String autorFoto = '',
    required int estrelas,
    required String comentario,
  }) async {
    try {
      final db = await BancoDadosService.db;
      await _garantirTabela(db);

      final id =
          'aval_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
      final avaliacao = AvaliacaoProduto(
        id: id,
        itemId: itemId,
        lojaId: lojaId,
        autorCpf: autorCpf,
        autorNome: autorNome,
        autorFoto: autorFoto,
        estrelas: estrelas.clamp(1, 5),
        comentario: comentario.trim(),
        criadoEm: DateTime.now(),
      );

      await db.insert(
        'avaliacoes_produtos',
        avaliacao.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _notificarAlteracao();

      // Despacho imediato na rede local (Contrato Local-First)
      final evento = {
        'tipo': 'avaliacao_produto_salva',
        'avaliacao': avaliacao.toJson(),
      };
      if (ServidorRedeLocal().ativo) {
        ServidorRedeLocal().notificarTodos(evento);
      } else if (ClienteRedeLocal().conectado) {
        ClienteRedeLocal().enviarEventoWs(evento);
      }

      return true;
    } catch (e) {
      debugPrint('[AvaliacoesProdutoService] Erro ao salvar avaliação: $e');
      return false;
    }
  }

  /// Incrementa curtida ou descurtida de uma avaliação e propaga pela rede Wi-Fi local.
  static Future<void> reagirAvaliacao({
    required String avaliacaoId,
    required bool curtir,
  }) async {
    if (avaliacaoId.startsWith('mock_')) return;
    try {
      await aplicarReacaoRemota(avaliacaoId: avaliacaoId, curtir: curtir);

      final evento = {
        'tipo': 'avaliacao_produto_reacao',
        'avaliacaoId': avaliacaoId,
        'curtir': curtir,
      };
      if (ServidorRedeLocal().ativo) {
        ServidorRedeLocal().notificarTodos(evento);
      } else if (ClienteRedeLocal().conectado) {
        ClienteRedeLocal().enviarEventoWs(evento);
      }
    } catch (e) {
      debugPrint('[AvaliacoesProdutoService] Erro ao reagir avaliação: $e');
    }
  }

  /// Persiste uma avaliação recebida pela rede local sem retransmitir em loop.
  static Future<void> salvarAvaliacaoRemota(AvaliacaoProduto avaliacao) async {
    try {
      final db = await BancoDadosService.db;
      await _garantirTabela(db);
      await db.insert(
        'avaliacoes_produtos',
        avaliacao.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _notificarAlteracao();
    } catch (e) {
      debugPrint('[AvaliacoesProdutoService] Erro ao salvar avaliação remota: $e');
    }
  }

  /// Aplica incremento de curtida/descurtida recebido da rede ou localmente.
  static Future<void> aplicarReacaoRemota({
    required String avaliacaoId,
    required bool curtir,
  }) async {
    try {
      final db = await BancoDadosService.db;
      await _garantirTabela(db);
      final coluna = curtir ? 'curtidas' : 'descurtidas';
      await db.rawUpdate(
        'UPDATE avaliacoes_produtos SET $coluna = $coluna + 1 WHERE id = ?',
        [avaliacaoId],
      );
      _notificarAlteracao();
    } catch (e) {
      debugPrint('[AvaliacoesProdutoService] Erro ao aplicar reação remota: $e');
    }
  }

  /// Exporta avaliações persistidas para sincronização inicial em lote na rede local.
  static Future<List<AvaliacaoProduto>> exportarTodasParaSync() async {
    try {
      final db = await BancoDadosService.db;
      await _garantirTabela(db);
      final rows = await db.query(
        'avaliacoes_produtos',
        orderBy: 'criado_em DESC',
        limit: 500,
      );
      return rows.map((r) => AvaliacaoProduto.fromJson(r)).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Mescla avaliações recebidas em lote do servidor balcão.
  static Future<void> mesclarAvaliacoesRemotas(
    List<AvaliacaoProduto> lista,
  ) async {
    if (lista.isEmpty) return;
    try {
      final db = await BancoDadosService.db;
      await _garantirTabela(db);
      await db.transaction((txn) async {
        for (final a in lista) {
          await txn.insert(
            'avaliacoes_produtos',
            a.toJson(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
      _notificarAlteracao();
    } catch (e) {
      debugPrint('[AvaliacoesProdutoService] Erro ao mesclar avaliações: $e');
    }
  }
}
