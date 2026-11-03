import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pagamento_funcionario.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/referencia_loja.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/loja/sanitizador_imagens_loja.dart';
import 'package:nous/src/features/pdv/services/loja/consolidador_loja_local.dart';
import 'package:nous/src/features/pdv/services/loja/pedidos_repositorio_loja.dart';

class LojasService {
  LojasService._();

  static Loja sanitizarCaminhosImagens(Loja loja) =>
      SanitizadorImagensLoja.sanitizar(loja);

  /// Consolida uma loja recebida (remota ou nova) com a loja local já existente,
  /// garantindo proteção absoluta contra perda de imagens físicas válidas locais.
  static Loja consolidarLojaComImagensLocais(
    Loja lojaNova,
    Loja? lojaLocal, {
    bool manterItensAusentes = false,
  }) =>
      ConsolidadorLojaLocal.consolidar(
        lojaNova,
        lojaLocal,
        manterItensAusentes: manterItensAusentes,
      );


  /// Verifica se um identificador, tag ou nome pertence a uma criação de host falso/temporário
  static bool ehLojaHostFalsa(String? id, [String? tags, String? nome]) {
    if (id != null && (id.startsWith('host_') || id.startsWith('temp_host_'))) return true;
    if (tags != null && tags.contains('host_pessoal')) return true;
    if (nome != null && (nome.startsWith('Host:') || nome.startsWith('Host '))) return true;
    return false;
  }

  /// Remove quaisquer lojas artificiais ou resquícios de host pessoal criados acidentalmente.
  static Future<void> expurgarLojasHostFalsas() async {
    try {
      final db = await BancoDadosService.db;
      final lojasFalsas = await db.query(
        'lojas',
        where: "id LIKE 'host_%' OR tags LIKE '%host_pessoal%' OR nome LIKE 'Host:%'",
      );
      for (final row in lojasFalsas) {
        final id = row['id'] as String;
        await db.delete('pedidos', where: 'loja_id = ?', whereArgs: [id]);
        await db.delete('movimentos_estoque', where: 'loja_id = ?', whereArgs: [id]);
        await db.delete('pagamentos_funcionarios', where: 'loja_id = ?', whereArgs: [id]);
        await db.delete('lojas', where: 'id = ?', whereArgs: [id]);
        await db.delete('referencias_loja', where: 'loja_id = ?', whereArgs: [id]);
      }
      await db.delete('referencias_loja', where: "loja_id LIKE 'host_%'");
    } catch (e) {
      debugPrint('[LojasService] Erro ao expurgar lojas host falsas: $e');
    }
  }

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

      if (ehLojaHostFalsa(lojaId, lojaMap['tags'] as String?, lojaMap['nome'] as String?)) {
        continue;
      }

      final pedidos = await PedidosRepositorioLoja.carregarParaMemoria(
        lojaId,
        executor: db,
      );

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

      final lojaBruta = Loja.fromJson(lojaMap).copyWith(
        pedidosLoja: pedidos,
        movimentosEstoque: movimentos,
        pagamentosFuncionarios: pagamentos,
      );
      final loja = sanitizarCaminhosImagens(lojaBruta);
      listaLojas.add(loja);
    }

    return listaLojas;
  }

  static Future<Loja?> carregarLojaPorId(String lojaId) async {
    if (ehLojaHostFalsa(lojaId)) return null;
    final db = await BancoDadosService.db;
    final rows = await db.query(
      'lojas',
      where: 'id = ?',
      whereArgs: [lojaId],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final row = rows.first;
    final lojaMap =
        jsonDecode(row['dados_json'] as String) as Map<String, dynamic>;

    final pedidos = await PedidosRepositorioLoja.carregarParaMemoria(
      lojaId,
      executor: db,
    );

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

    final lojaBruta = Loja.fromJson(lojaMap).copyWith(
      pedidosLoja: pedidos,
      movimentosEstoque: movimentos,
      pagamentosFuncionarios: pagamentos,
    );
    return sanitizarCaminhosImagens(lojaBruta);
  }

  static Future<void> salvar(String cpf, List<Loja> lojas) async {
    final db = await BancoDadosService.db;
    final lojasValidas = lojas
        .where((l) => !ehLojaHostFalsa(l.id, l.tags, l.nome))
        .toList();

    await db.transaction((txn) async {
      final idsAtuais = lojasValidas.map((l) => l.id).toList();

      if (idsAtuais.isEmpty) {
        final lojasParaDeletar = await txn.query(
          'lojas',
          columns: ['id'],
          where: 'cpf_dono = ?',
          whereArgs: [cpf],
        );
        for (final row in lojasParaDeletar) {
          final lId = row['id'] as String;
          await txn.delete('pedidos', where: 'loja_id = ?', whereArgs: [lId]);
          await txn.delete('movimentos_estoque',
              where: 'loja_id = ?', whereArgs: [lId]);
          await txn.delete('pagamentos_funcionarios',
              where: 'loja_id = ?', whereArgs: [lId]);
        }
        await txn.delete('lojas', where: 'cpf_dono = ?', whereArgs: [cpf]);
      } else {
        final placeholders = List.filled(idsAtuais.length, '?').join(',');
        final lojasParaDeletar = await txn.query(
          'lojas',
          columns: ['id'],
          where: 'cpf_dono = ? AND id NOT IN ($placeholders)',
          whereArgs: [cpf, ...idsAtuais],
        );
        for (final row in lojasParaDeletar) {
          final lId = row['id'] as String;
          await txn.delete('pedidos', where: 'loja_id = ?', whereArgs: [lId]);
          await txn.delete('movimentos_estoque',
              where: 'loja_id = ?', whereArgs: [lId]);
          await txn.delete('pagamentos_funcionarios',
              where: 'loja_id = ?', whereArgs: [lId]);
        }
        await txn.delete(
          'lojas',
          where: 'cpf_dono = ? AND id NOT IN ($placeholders)',
          whereArgs: [cpf, ...idsAtuais],
        );
      }

      for (var loja in lojasValidas) {
        loja = sanitizarCaminhosImagens(loja);
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

        await PedidosRepositorioLoja.salvarLote(
          txn,
          loja.id,
          loja.pedidosLoja,
        );

        // Proteção Soberana Local-First: nunca deleta pedidos, estoque ou pagamentos
        // existentes no banco SQLite por omissão na lista em memória!
      }
    });
  }

  /// Consulta pedidos da loja de forma paginada para relatórios e históricos sem carregar tudo na memória RAM.
  static Future<List<PedidoLoja>> carregarPedidosPaginados({
    required String lojaId,
    int limite = 100,
    int offset = 0,
    DateTime? dataInicio,
    DateTime? dataFim,
    StatusPedido? status,
  }) =>
      PedidosRepositorioLoja.carregarPaginado(
        lojaId: lojaId,
        limite: limite,
        offset: offset,
        dataInicio: dataInicio,
        dataFim: dataFim,
        status: status,
      );

  /// Retorna a contagem total de pedidos sob os filtros informados diretamente pelo SQLite.
  static Future<int> contarTotalPedidos({
    required String lojaId,
    DateTime? dataInicio,
    DateTime? dataFim,
    StatusPedido? status,
  }) =>
      PedidosRepositorioLoja.contarTotal(
        lojaId: lojaId,
        dataInicio: dataInicio,
        dataFim: dataFim,
        status: status,
      );


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
        .where((ref) => !ehLojaHostFalsa(ref.lojaId))
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
    if (ehLojaHostFalsa(referencia.lojaId)) return;
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

  /// Salva ou atualiza uma única loja no cofre do seu dono original com proteção total contra perda de imagens
  static Future<void> salvarLojaIndividual(Loja loja) async {
    if (ehLojaHostFalsa(loja.id, loja.tags, loja.nome)) return;
    final dono = loja.cpfDonoOriginal.isNotEmpty ? loja.cpfDonoOriginal : 'sistema';
    final cofre = await carregar(dono);
    final idx = cofre.indexWhere((l) => l.id == loja.id);
    if (idx == -1) {
      final existente = await carregarLojaPorId(loja.id);
      cofre.add(consolidarLojaComImagensLocais(loja, existente));
    } else {
      cofre[idx] = consolidarLojaComImagensLocais(loja, cofre[idx]);
    }
    await salvar(dono, cofre);
  }

  /// Executa uma verificação proativa de integridade nas lojas salvas no SQLite.
  /// Caso alguma imagem (logo, categorias, itens, clientes, fornecedores ou galeria)
  /// esteja apontando para um caminho inexistente (como /data/user/... no Windows
  /// ou caminhos de outras máquinas), tenta localizá-la nas pastas locais de imagens
  /// e nos backups automáticos históricos, curando o banco de dados silenciosamente.
  static Future<void> autocuraImagensDeLojas() async {
    try {
      final db = await BancoDadosService.db;
      final rows = await db.query('lojas');
      if (rows.isEmpty) return;

      // 1. Localiza os backups mais recentes para caso precise consultar mapeamentos históricos
      final backups = <File>[];
      try {
        final dirSuporte = await getApplicationSupportDirectory();
        final pastaBackups = Directory(p.join(dirSuporte.path, 'Nous', 'backups'));
        if (pastaBackups.existsSync()) {
          final arqs = pastaBackups
              .listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.json'))
              .toList();
          arqs.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
          backups.addAll(arqs);
        }
      } catch (_) {}

      // Também busca na pasta de backups legada se existir
      if (Platform.isWindows) {
        final appData = Platform.environment['APPDATA'];
        if (appData != null && appData.isNotEmpty) {
          final legada = Directory('$appData/com.example/nous/Nous/backups');
          if (legada.existsSync()) {
            final arqs = legada
                .listSync()
                .whereType<File>()
                .where((f) => f.path.endsWith('.json'))
                .toList();
            arqs.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
            for (final a in arqs) {
              if (!backups.any((b) => p.basename(b.path) == p.basename(a.path))) {
                backups.add(a);
              }
            }
          }
        }
      }

      for (final row in rows) {
        final id = row['id'] as String;
        final dadosJson = row['dados_json'] as String;
        final map = jsonDecode(dadosJson) as Map<String, dynamic>;
        var houveCorrecao = false;

        // 1. Logo
        final logoAtual = map['logo'] as String? ?? '';
        if (logoAtual.isNotEmpty && !ImagemService.ehAsset(logoAtual)) {
          final resolvida = ImagemService.resolverCaminhoExistente(logoAtual);
          if (resolvida != null && resolvida != logoAtual) {
            map['logo'] = resolvida;
            houveCorrecao = true;
          } else if (resolvida == null) {
            final doBackup = await _buscarFotoNoBackup(backups, id, 'logo', null);
            if (doBackup != null) {
              final resolvidaBackup = ImagemService.resolverCaminhoExistente(doBackup);
              if (resolvidaBackup != null) {
                map['logo'] = resolvidaBackup;
                houveCorrecao = true;
              }
            }
          }
        }

        // 2. Categorias
        final cats = (map['categoriasLoja'] as List? ?? []);
        for (final c in cats) {
          final foto = c['foto'] as String? ?? '';
          if (foto.isNotEmpty) {
            final resolvida = ImagemService.resolverCaminhoExistente(foto);
            if (resolvida != null && resolvida != foto) {
              c['foto'] = resolvida;
              houveCorrecao = true;
            } else if (resolvida == null) {
              final catId = c['id'] as String? ?? '';
              final doBackup = await _buscarFotoNoBackup(backups, id, 'categoria', catId);
              if (doBackup != null) {
                final resolvidaBackup = ImagemService.resolverCaminhoExistente(doBackup);
                if (resolvidaBackup != null) {
                  c['foto'] = resolvidaBackup;
                  houveCorrecao = true;
                }
              }
            }
          }
        }

        // 3. Itens
        final itens = (map['itensLoja'] as List? ?? []);
        for (final it in itens) {
          final imgs = (it['imagens'] as List? ?? []).map((e) => e.toString()).toList();
          final novasImgs = <String>[];
          var itemCorrigido = false;

          for (final img in imgs) {
            final resolvida = ImagemService.resolverCaminhoExistente(img);
            if (resolvida != null) {
              novasImgs.add(resolvida);
              if (resolvida != img) itemCorrigido = true;
            } else {
              final itemId = it['id'] as String? ?? '';
              final doBackup = await _buscarFotoNoBackup(backups, id, 'item', itemId);
              if (doBackup != null) {
                final resolvidaBackup = ImagemService.resolverCaminhoExistente(doBackup);
                if (resolvidaBackup != null) {
                  novasImgs.add(resolvidaBackup);
                  itemCorrigido = true;
                }
              }
            }
          }

          if (itemCorrigido && novasImgs.isNotEmpty) {
            it['imagens'] = novasImgs;
            houveCorrecao = true;
          }
        }

        // 4. Clientes
        final clientes = (map['clientesLoja'] as List? ?? []);
        for (final cli in clientes) {
          final foto = cli['foto'] as String? ?? '';
          if (foto.isNotEmpty) {
            final resolvida = ImagemService.resolverCaminhoExistente(foto);
            if (resolvida != null && resolvida != foto) {
              cli['foto'] = resolvida;
              houveCorrecao = true;
            }
          }
        }

        // 5. Fornecedores
        final fornecedores = (map['fornecedoresLoja'] as List? ?? []);
        for (final forn in fornecedores) {
          final foto = forn['foto'] as String? ?? '';
          if (foto.isNotEmpty) {
            final resolvida = ImagemService.resolverCaminhoExistente(foto);
            if (resolvida != null && resolvida != foto) {
              forn['foto'] = resolvida;
              houveCorrecao = true;
            }
          }
        }

        // 6. Galeria
        final galeria = (map['galeria'] as List? ?? []).map((e) => e.toString()).toList();
        final novaGaleria = <String>[];
        var galeriaCorrigida = false;
        for (final g in galeria) {
          final resolvida = ImagemService.resolverCaminhoExistente(g);
          if (resolvida != null) {
            novaGaleria.add(resolvida);
            if (resolvida != g) galeriaCorrigida = true;
          }
        }
        if (galeriaCorrigida && novaGaleria.isNotEmpty) {
          map['galeria'] = novaGaleria;
          houveCorrecao = true;
        }

        if (houveCorrecao) {
          await db.update(
            'lojas',
            {'dados_json': jsonEncode(map)},
            where: 'id = ?',
            whereArgs: [id],
          );
          debugPrint('[LojasService] Autocura de imagens executada com sucesso para a loja "$id"');
        }
      }
    } catch (e) {
      debugPrint('[LojasService] Erro na autocura de imagens: $e');
    }
  }

  static Future<String?> _buscarFotoNoBackup(
    List<File> backups,
    String lojaId,
    String tipo,
    String? elementoId,
  ) async {
    for (final b in backups) {
      try {
        final content = await b.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        final cofres = json['cofres'] as List<dynamic>? ?? [];
        for (final c in cofres) {
          final lojas = c['lojas'] as List<dynamic>? ?? [];
          for (final l in lojas) {
            if (l['id'] == lojaId) {
              if (tipo == 'logo') {
                final logo = l['logo'] as String? ?? '';
                if (logo.isNotEmpty && ImagemService.existe(logo)) return logo;
              } else if (tipo == 'categoria') {
                for (final cat in (l['categoriasLoja'] as List? ?? [])) {
                  if (cat['id'] == elementoId) {
                    final foto = cat['foto'] as String? ?? '';
                    if (foto.isNotEmpty && ImagemService.existe(foto)) return foto;
                  }
                }
              } else if (tipo == 'item') {
                for (final it in (l['itensLoja'] as List? ?? [])) {
                  if (it['id'] == elementoId) {
                    final imgs = (it['imagens'] as List? ?? []);
                    for (final img in imgs) {
                      final str = img.toString();
                      if (str.isNotEmpty && ImagemService.existe(str)) return str;
                    }
                  }
                }
              }
            }
          }
        }
      } catch (_) {}
    }
    return null;
  }
}