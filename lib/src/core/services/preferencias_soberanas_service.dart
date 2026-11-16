import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';

/// Armazena preferências de negócio do usuário/loja diretamente no SQLite
/// para que sobrevivam a trocas de máquina e façam parte do Backup Soberano.
/// Faz migração transparente de chaves legadas do SharedPreferences.
class PreferenciasSoberanasService {
  PreferenciasSoberanasService._();

  static bool _tabelaCriada = false;

  static Future<Database> _obterDb() async {
    final db = await BancoDadosService.db;
    if (!_tabelaCriada) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS preferencias_usuario (
          chave TEXT PRIMARY KEY,
          valor TEXT NOT NULL,
          atualizado_em TEXT NOT NULL
        );
      ''');
      _tabelaCriada = true;
    }
    return db;
  }

  /// Lê uma lista de strings associada a [chave], migrando do SharedPreferences se necessário.
  static Future<List<String>> obterLista(String chave) async {
    try {
      final db = await _obterDb();
      final rows = await db.query(
        'preferencias_usuario',
        columns: ['valor'],
        where: 'chave = ?',
        whereArgs: [chave],
        limit: 1,
      );

      if (rows.isNotEmpty) {
        final raw = rows.first['valor']?.toString() ?? '[]';
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      }

      // Fallback transparente de chaves legadas no SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final legado = prefs.getStringList(chave);
      if (legado != null && legado.isNotEmpty) {
        await salvarLista(chave, legado);
        return legado;
      }
    } catch (_) {}
    return <String>[];
  }

  /// Persiste uma lista de strings no SQLite (e mantém espelho no SharedPreferences para compatibilidade).
  static Future<void> salvarLista(String chave, List<String> valores) async {
    try {
      final unicos = valores.toSet().toList();
      final db = await _obterDb();
      await db.insert(
        'preferencias_usuario',
        {
          'chave': chave,
          'valor': jsonEncode(unicos),
          'atualizado_em': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(chave, unicos);
    } catch (_) {}
  }

  /// Lê uma string associada a [chave], migrando do SharedPreferences se necessário.
  static Future<String?> obterTexto(String chave) async {
    try {
      final db = await _obterDb();
      final rows = await db.query(
        'preferencias_usuario',
        columns: ['valor'],
        where: 'chave = ?',
        whereArgs: [chave],
        limit: 1,
      );

      if (rows.isNotEmpty) {
        final raw = rows.first['valor']?.toString();
        if (raw != null && raw.isNotEmpty) {
          return raw;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final legado = prefs.getString(chave);
      if (legado != null && legado.isNotEmpty) {
        await salvarTexto(chave, legado);
        return legado;
      }
    } catch (_) {}
    return null;
  }

  /// Persiste uma string no SQLite (e mantém espelho no SharedPreferences para compatibilidade).
  static Future<void> salvarTexto(String chave, String valor) async {
    try {
      final db = await _obterDb();
      await db.insert(
        'preferencias_usuario',
        {
          'chave': chave,
          'valor': valor,
          'atualizado_em': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(chave, valor);
    } catch (_) {}
  }

  /// Exporta todas as preferências para o Backup JSON.
  static Future<List<Map<String, dynamic>>> exportarTodas() async {
    try {
      final db = await _obterDb();
      return await db.query('preferencias_usuario');
    } catch (_) {
      return const [];
    }
  }

  /// Restaura preferências do Backup JSON mesclando listas sem sobrescrever dados locais mais ricos.
  static Future<void> importarTodas(List<dynamic> itens) async {
    if (itens.isEmpty) return;
    try {
      final db = await _obterDb();
      for (final item in itens) {
        if (item is! Map<String, dynamic>) continue;
        final chave = item['chave']?.toString() ?? '';
        final valor = item['valor']?.toString() ?? '';
        if (chave.isEmpty || valor.isEmpty) continue;

        final existentes = await db.query(
          'preferencias_usuario',
          columns: ['valor'],
          where: 'chave = ?',
          whereArgs: [chave],
          limit: 1,
        );

        if (existentes.isEmpty) {
          await db.insert(
            'preferencias_usuario',
            Map<String, dynamic>.from(item),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } else {
          // Mescla listas se ambas forem JSON array
          try {
            final localDec = jsonDecode(existentes.first['valor']?.toString() ?? '[]');
            final remDec = jsonDecode(valor);
            if (localDec is List && remDec is List) {
              final mesclada = {
                ...localDec.map((e) => e.toString()),
                ...remDec.map((e) => e.toString()),
              }.toList();
              await salvarLista(chave, mesclada);
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
  }
}
