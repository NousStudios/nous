import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class BancoDadosService {
  BancoDadosService._();

  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _inicializar();
    return _db!;
  }

  static Future<void> inicializar() async {
    if (_db != null) return;
    _db = await _inicializar();
  }

  static Future<Database> _inicializar() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dir = await getApplicationSupportDirectory();
    final caminhoPasta = p.join(dir.path, 'Nous');
    final pasta = Directory(caminhoPasta);
    if (!pasta.existsSync()) {
      await pasta.create(recursive: true);
    }

    final caminhoDb = p.join(caminhoPasta, 'nous.db');

    final banco = await databaseFactory.openDatabase(
      caminhoDb,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, versao) async {
          await _criarTabelas(db);
        },
      ),
    );

    await _migrarDadosDoSharedPreferencesSeNecessario(banco);

    return banco;
  }

  static Future<void> _criarTabelas(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS contas_usuarios (
        cpf TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        dados_json TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS lojas (
        id TEXT PRIMARY KEY,
        cpf_dono TEXT NOT NULL,
        nome TEXT NOT NULL,
        dados_json TEXT NOT NULL
      );
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_lojas_cpf ON lojas (cpf_dono);');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pedidos (
        id TEXT PRIMARY KEY,
        loja_id TEXT NOT NULL,
        numero INTEGER NOT NULL,
        data_hora TEXT NOT NULL,
        status TEXT NOT NULL,
        valor REAL NOT NULL,
        cliente_nome TEXT,
        dados_json TEXT NOT NULL
      );
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_pedidos_loja_data ON pedidos (loja_id, data_hora DESC);');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_pedidos_loja_status ON pedidos (loja_id, status);');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS movimentos_estoque (
        id TEXT PRIMARY KEY,
        loja_id TEXT NOT NULL,
        item_id TEXT NOT NULL,
        tipo TEXT NOT NULL,
        data_hora TEXT NOT NULL,
        custo_total REAL NOT NULL,
        dados_json TEXT NOT NULL
      );
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_estoque_loja_data ON movimentos_estoque (loja_id, data_hora DESC);');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pagamentos_funcionarios (
        id TEXT PRIMARY KEY,
        loja_id TEXT NOT NULL,
        data_hora TEXT NOT NULL,
        valor REAL NOT NULL,
        dados_json TEXT NOT NULL
      );
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_pagamentos_loja_data ON pagamentos_funcionarios (loja_id, data_hora DESC);');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS referencias_loja (
        id TEXT PRIMARY KEY,
        cpf TEXT NOT NULL,
        loja_id TEXT NOT NULL,
        dados_json TEXT NOT NULL
      );
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_referencias_cpf ON referencias_loja (cpf);');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS convites (
        id TEXT PRIMARY KEY,
        cpf_destinatario TEXT NOT NULL,
        dados_json TEXT NOT NULL
      );
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_convites_cpf ON convites (cpf_destinatario);');
  }

  static int _primeiroValorInteiro(List<Map<String, Object?>> list) {
    if (list.isEmpty) return 0;
    final row = list.first;
    if (row.isEmpty) return 0;
    final val = row.values.first;
    if (val is int) return val;
    if (val is num) return val.toInt();
    return 0;
  }

  static Future<void> _migrarDadosDoSharedPreferencesSeNecessario(
      Database db) async {
    final contagemLojas = _primeiroValorInteiro(
      await db.rawQuery('SELECT COUNT(*) FROM lojas'),
    );
    final contagemContas = _primeiroValorInteiro(
      await db.rawQuery('SELECT COUNT(*) FROM contas_usuarios'),
    );

    if (contagemLojas > 0 || contagemContas > 0) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    final contasTexto = prefs.getString('nous_contas_cpf');
    if (contasTexto != null && contasTexto.isNotEmpty) {
      try {
        final lista = jsonDecode(contasTexto) as List<dynamic>;
        for (final item in lista) {
          final mapa = item as Map<String, dynamic>;
          final cpf = mapa['cpf']?.toString() ?? '';
          final nome = mapa['nome']?.toString() ?? '';
          if (cpf.isNotEmpty) {
            await db.insert(
              'contas_usuarios',
              {
                'cpf': cpf,
                'nome': nome,
                'dados_json': jsonEncode(mapa),
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      } catch (_) {}
    }

    const prefixoLoja = 'nous_lojas_';
    const prefixoRef = 'nous_referencias_';
    const prefixoConvite = 'nous_convites_';

    for (final chave in prefs.getKeys()) {
      if (chave.startsWith(prefixoLoja)) {
        final cpf = chave.substring(prefixoLoja.length);
        final texto = prefs.getString(chave);
        if (texto == null || texto.isEmpty) continue;
        try {
          final listaLojas = jsonDecode(texto) as List<dynamic>;
          for (final itemLoja in listaLojas) {
            final lojaMap = itemLoja as Map<String, dynamic>;
            final lojaId = lojaMap['id']?.toString() ?? '';
            final nomeLoja = lojaMap['nome']?.toString() ?? '';
            final cpfDono = lojaMap['cpfDonoOriginal']?.toString() ?? cpf;
            if (lojaId.isEmpty) continue;

            final pedidosList =
                lojaMap['pedidos'] as List<dynamic>? ?? const [];
            for (final pItem in pedidosList) {
              final pMap = pItem as Map<String, dynamic>;
              final pId = pMap['id']?.toString() ?? '';
              final pNumero = (pMap['numero'] as num?)?.toInt() ?? 0;
              final pData = pMap['dataHora']?.toString() ?? '';
              final pStatus = pMap['status']?.toString() ?? '';
              final pValor = (pMap['valor'] as num?)?.toDouble() ?? 0.0;
              final pCliente = pMap['clienteNome']?.toString() ?? '';
              if (pId.isNotEmpty) {
                await db.insert(
                  'pedidos',
                  {
                    'id': pId,
                    'loja_id': lojaId,
                    'numero': pNumero,
                    'data_hora': pData,
                    'status': pStatus,
                    'valor': pValor,
                    'cliente_nome': pCliente,
                    'dados_json': jsonEncode(pMap),
                  },
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
              }
            }

            final estoquesList =
                lojaMap['movimentosEstoque'] as List<dynamic>? ?? const [];
            for (final eItem in estoquesList) {
              final eMap = eItem as Map<String, dynamic>;
              final eId = eMap['id']?.toString() ?? '';
              final eItemId = eMap['itemId']?.toString() ?? '';
              final eTipo = eMap['tipo']?.toString() ?? '';
              final eData = eMap['dataHora']?.toString() ?? '';
              final qtd = (eMap['quantidade'] as num?)?.toDouble() ?? 0.0;
              final custo = (eMap['custoUnitario'] as num?)?.toDouble() ?? 0.0;
              if (eId.isNotEmpty) {
                await db.insert(
                  'movimentos_estoque',
                  {
                    'id': eId,
                    'loja_id': lojaId,
                    'item_id': eItemId,
                    'tipo': eTipo,
                    'data_hora': eData,
                    'custo_total': qtd * custo,
                    'dados_json': jsonEncode(eMap),
                  },
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
              }
            }

            final pagamentosList =
                lojaMap['pagamentosFuncionarios'] as List<dynamic>? ?? const [];
            for (final pagItem in pagamentosList) {
              final pagMap = pagItem as Map<String, dynamic>;
              final pagId = pagMap['id']?.toString() ?? '';
              final pagData = pagMap['dataHora']?.toString() ?? '';
              final pagValor = (pagMap['valor'] as num?)?.toDouble() ?? 0.0;
              if (pagId.isNotEmpty) {
                await db.insert(
                  'pagamentos_funcionarios',
                  {
                    'id': pagId,
                    'loja_id': lojaId,
                    'data_hora': pagData,
                    'valor': pagValor,
                    'dados_json': jsonEncode(pagMap),
                  },
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
              }
            }

            await db.insert(
              'lojas',
              {
                'id': lojaId,
                'cpf_dono': cpfDono,
                'nome': nomeLoja,
                'dados_json': jsonEncode(lojaMap),
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        } catch (_) {}
      } else if (chave.startsWith(prefixoRef)) {
        final cpf = chave.substring(prefixoRef.length);
        final texto = prefs.getString(chave);
        if (texto == null || texto.isEmpty) continue;
        try {
          final listaRefs = jsonDecode(texto) as List<dynamic>;
          for (final itemRef in listaRefs) {
            final refMap = itemRef as Map<String, dynamic>;
            final refLojaId = refMap['lojaId']?.toString() ?? '';
            final refId = '$cpf-$refLojaId';
            if (refLojaId.isNotEmpty) {
              await db.insert(
                'referencias_loja',
                {
                  'id': refId,
                  'cpf': cpf,
                  'loja_id': refLojaId,
                  'dados_json': jsonEncode(refMap),
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }
        } catch (_) {}
      } else if (chave.startsWith(prefixoConvite)) {
        final cpf = chave.substring(prefixoConvite.length);
        final texto = prefs.getString(chave);
        if (texto == null || texto.isEmpty) continue;
        try {
          final listaConvites = jsonDecode(texto) as List<dynamic>;
          for (final itemConvite in listaConvites) {
            final cMap = itemConvite as Map<String, dynamic>;
            final cId = cMap['id']?.toString() ?? '';
            if (cId.isNotEmpty) {
              await db.insert(
                'convites',
                {
                  'id': cId,
                  'cpf_destinatario': cpf,
                  'dados_json': jsonEncode(cMap),
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }
        } catch (_) {}
      }
    }
  }
}
