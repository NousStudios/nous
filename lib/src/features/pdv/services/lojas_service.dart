import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/fornecedor.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pagamento_funcionario.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/referencia_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

class LojasService {
  LojasService._();

  static Loja sanitizarCaminhosImagens(Loja loja) {
    String logoFinal = loja.logo;
    if (logoFinal.isNotEmpty) {
      logoFinal = ImagemService.resolverCaminhoExistente(logoFinal) ?? logoFinal;
    }

    final novasCategorias = loja.categoriasLoja.map((cat) {
      if (cat.foto.isEmpty) return cat;
      final fotoResolvida = ImagemService.resolverCaminhoExistente(cat.foto) ?? cat.foto;
      return fotoResolvida != cat.foto ? cat.copyWith(foto: fotoResolvida) : cat;
    }).toList();

    final novosItens = loja.itensLoja.map((item) {
      if (item.imagens.isEmpty) return item;
      final novasImagens = item.imagens.map((img) {
        return ImagemService.resolverCaminhoExistente(img) ?? img;
      }).toList();
      return item.copyWith(imagens: novasImagens);
    }).toList();

    final novosClientes = loja.clientesLoja.map((cli) {
      if (cli.foto.isEmpty) return cli;
      final fotoResolvida = ImagemService.resolverCaminhoExistente(cli.foto) ?? cli.foto;
      return fotoResolvida != cli.foto ? cli.copyWith(foto: fotoResolvida) : cli;
    }).toList();

    final novosFornecedores = loja.fornecedoresLoja.map((forn) {
      if (forn.foto.isEmpty) return forn;
      final fotoResolvida = ImagemService.resolverCaminhoExistente(forn.foto) ?? forn.foto;
      return fotoResolvida != forn.foto ? forn.copyWith(foto: fotoResolvida) : forn;
    }).toList();

    final novaGaleria = loja.galeria.map((g) {
      return ImagemService.resolverCaminhoExistente(g) ?? g;
    }).toList();

    return loja.copyWith(
      logo: logoFinal,
      categoriasLoja: novasCategorias,
      itensLoja: novosItens,
      clientesLoja: novosClientes,
      fornecedoresLoja: novosFornecedores,
      galeria: novaGaleria,
    );
  }

  /// Consolida uma loja recebida (remota ou nova) com a loja local já existente,
  /// garantindo proteção absoluta contra perda de imagens físicas válidas locais.
  static Loja consolidarLojaComImagensLocais(Loja lojaNova, Loja? lojaLocal) {
    if (lojaLocal == null) {
      return sanitizarCaminhosImagens(lojaNova);
    }

    // 1. Logo da loja
    String logoFinal = lojaNova.logo;
    final logoResolvida = ImagemService.resolverCaminhoExistente(lojaNova.logo);
    if (logoResolvida != null) {
      logoFinal = logoResolvida;
    } else if (lojaLocal.logo.isNotEmpty && ImagemService.existe(lojaLocal.logo)) {
      // Preserva a logo local válida caso a remota não exista neste disco
      logoFinal = ImagemService.resolverCaminhoExistente(lojaLocal.logo) ?? lojaLocal.logo;
    }

    // 2. Categorias
    final categoriasConsolidadas = <CategoriaLoja>[];
    for (final catNova in lojaNova.categoriasLoja) {
      CategoriaLoja? catLocal;
      for (final c in lojaLocal.categoriasLoja) {
        if (c.id == catNova.id) {
          catLocal = c;
          break;
        }
      }

      String fotoFinal = catNova.foto;
      final fotoResolvida = ImagemService.resolverCaminhoExistente(catNova.foto);
      if (fotoResolvida != null) {
        fotoFinal = fotoResolvida;
      } else if (catLocal != null &&
          catLocal.foto.isNotEmpty &&
          ImagemService.existe(catLocal.foto)) {
        fotoFinal = ImagemService.resolverCaminhoExistente(catLocal.foto) ?? catLocal.foto;
      }

      categoriasConsolidadas.add(catNova.copyWith(foto: fotoFinal));
    }
    for (final cLocal in lojaLocal.categoriasLoja) {
      if (!categoriasConsolidadas.any((c) => c.id == cLocal.id)) {
        categoriasConsolidadas.add(cLocal);
      }
    }

    // 3. Itens
    final itensConsolidados = <ItemLoja>[];
    for (final itemNovo in lojaNova.itensLoja) {
      ItemLoja? itemLocal;
      for (final i in lojaLocal.itensLoja) {
        if (i.id == itemNovo.id) {
          itemLocal = i;
          break;
        }
      }

      final novasImagens = <String>[];
      for (final img in itemNovo.imagens) {
        final imgResolvida = ImagemService.resolverCaminhoExistente(img);
        if (imgResolvida != null) {
          novasImagens.add(imgResolvida);
        }
      }

      // Se nenhuma imagem nova pôde ser resolvida no disco deste aparelho,
      // mas o item local já possui imagens válidas existentes:
      if (novasImagens.isEmpty && itemLocal != null && itemLocal.imagens.isNotEmpty) {
        for (final imgLocal in itemLocal.imagens) {
          final imgLocalResolvida = ImagemService.resolverCaminhoExistente(imgLocal);
          if (imgLocalResolvida != null) {
            novasImagens.add(imgLocalResolvida);
          }
        }
      }

      itensConsolidados.add(itemNovo.copyWith(
        imagens: novasImagens.isNotEmpty ? novasImagens : itemNovo.imagens,
      ));
    }
    for (final iLocal in lojaLocal.itensLoja) {
      if (!itensConsolidados.any((i) => i.id == iLocal.id)) {
        itensConsolidados.add(iLocal);
      }
    }

    // 4. Clientes
    final clientesConsolidados = <Cliente>[];
    for (final cliNovo in lojaNova.clientesLoja) {
      Cliente? cliLocal;
      for (final c in lojaLocal.clientesLoja) {
        if (c.id == cliNovo.id) {
          cliLocal = c;
          break;
        }
      }

      String fotoFinal = cliNovo.foto;
      final fotoResolvida = ImagemService.resolverCaminhoExistente(cliNovo.foto);
      if (fotoResolvida != null) {
        fotoFinal = fotoResolvida;
      } else if (cliLocal != null &&
          cliLocal.foto.isNotEmpty &&
          ImagemService.existe(cliLocal.foto)) {
        fotoFinal = ImagemService.resolverCaminhoExistente(cliLocal.foto) ?? cliLocal.foto;
      }

      clientesConsolidados.add(cliNovo.copyWith(foto: fotoFinal));
    }
    for (final cLocal in lojaLocal.clientesLoja) {
      if (!clientesConsolidados.any((c) => c.id == cLocal.id)) {
        clientesConsolidados.add(cLocal);
      }
    }

    // 5. Fornecedores
    final fornecedoresConsolidados = <Fornecedor>[];
    for (final fornNovo in lojaNova.fornecedoresLoja) {
      Fornecedor? fornLocal;
      for (final f in lojaLocal.fornecedoresLoja) {
        if (f.id == fornNovo.id) {
          fornLocal = f;
          break;
        }
      }

      String fotoFinal = fornNovo.foto;
      final fotoResolvida = ImagemService.resolverCaminhoExistente(fornNovo.foto);
      if (fotoResolvida != null) {
        fotoFinal = fotoResolvida;
      } else if (fornLocal != null &&
          fornLocal.foto.isNotEmpty &&
          ImagemService.existe(fornLocal.foto)) {
        fotoFinal = ImagemService.resolverCaminhoExistente(fornLocal.foto) ?? fornLocal.foto;
      }

      fornecedoresConsolidados.add(fornNovo.copyWith(foto: fotoFinal));
    }
    for (final fLocal in lojaLocal.fornecedoresLoja) {
      if (!fornecedoresConsolidados.any((f) => f.id == fLocal.id)) {
        fornecedoresConsolidados.add(fLocal);
      }
    }

    // 6. Galeria
    final galeriaConsolidada = <String>[];
    for (final g in lojaNova.galeria) {
      final gResolvido = ImagemService.resolverCaminhoExistente(g);
      if (gResolvido != null) {
        galeriaConsolidada.add(gResolvido);
      }
    }
    if (galeriaConsolidada.isEmpty && lojaLocal.galeria.isNotEmpty) {
      for (final g in lojaLocal.galeria) {
        final gResolvido = ImagemService.resolverCaminhoExistente(g);
        if (gResolvido != null) {
          galeriaConsolidada.add(gResolvido);
        }
      }
    }

    // 7. Mesas da loja
    final mesasConsolidadas = List<MesaLoja>.from(lojaNova.mesas);
    for (final mLocal in lojaLocal.mesas) {
      if (!mesasConsolidadas.any((m) => m.id == mLocal.id)) {
        mesasConsolidadas.add(mLocal);
      }
    }

    // 8. Histórico de Ações (Auditoria)
    final acoesMescladas = List<RegistroAcao>.from(lojaLocal.acoes);
    for (final a in lojaNova.acoes) {
      if (!acoesMescladas.any((ex) => ex.id == a.id)) {
        acoesMescladas.add(a);
      }
    }

    return lojaNova.copyWith(
      logo: logoFinal,
      categoriasLoja: categoriasConsolidadas,
      itensLoja: itensConsolidados,
      clientesLoja: clientesConsolidados,
      fornecedoresLoja: fornecedoresConsolidados,
      galeria: galeriaConsolidada,
      mesas: mesasConsolidadas,
      acoes: acoesMescladas,
      layoutExpandido: lojaLocal.layoutExpandido,
      tipoLayoutMaior: lojaLocal.tipoLayoutMaior.isNotEmpty
          ? lojaLocal.tipoLayoutMaior
          : lojaNova.tipoLayoutMaior,
    );
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

    final pedRows = await db.query(
      'pedidos',
      where: 'loja_id = ?',
      whereArgs: [lojaId],
      orderBy: 'data_hora DESC',
    );
    final pedidos = pedRows
        .map((r) => PedidoLoja.fromJson(jsonDecode(r['dados_json'] as String)))
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

    final lojaBruta = Loja.fromJson(lojaMap).copyWith(
      pedidosLoja: pedidos,
      movimentosEstoque: movimentos,
      pagamentosFuncionarios: pagamentos,
    );
    return sanitizarCaminhosImagens(lojaBruta);
  }

  static Future<void> salvar(String cpf, List<Loja> lojas) async {
    final db = await BancoDadosService.db;

    await db.transaction((txn) async {
      final idsAtuais = lojas.map((l) => l.id).toList();

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

      for (var loja in lojas) {
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

  /// Salva ou atualiza uma única loja no cofre do seu dono original com proteção total contra perda de imagens
  static Future<void> salvarLojaIndividual(Loja loja) async {
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
        if (logoAtual.isNotEmpty) {
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