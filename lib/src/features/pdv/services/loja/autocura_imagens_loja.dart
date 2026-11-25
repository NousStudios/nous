import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

/// Responsável pela verificação proativa e autocura de caminhos de imagens
/// das lojas persistidas no SQLite, com fallback em backups históricos.
class AutocuraImagensLoja {
  AutocuraImagensLoja._();

  /// Executa uma verificação proativa de integridade nas lojas salvas no SQLite.
  /// Caso alguma imagem (logo, categorias, itens, clientes, fornecedores ou galeria)
  /// esteja apontando para um caminho inexistente (como /data/user/... no Windows
  /// ou caminhos de outras máquinas), tenta localizá-la nas pastas locais de imagens
  /// e nos backups automáticos históricos, curando o banco de dados silenciosamente.
  static Future<void> executar() async {
    try {
      final db = await BancoDadosService.db;
      final rows = await db.query('lojas');
      if (rows.isEmpty) return;

      final backups = await _localizarBackupsRecentes();
      final cacheBackups = <String, Map<String, dynamic>>{};

      for (final row in rows) {
        final id = row['id'] as String;
        final dadosJson = row['dados_json'] as String;
        final map = jsonDecode(dadosJson) as Map<String, dynamic>;

        final houveCorrecao = await _curarMapaLoja(
          id,
          map,
          backups,
          cacheBackups,
        );

        if (houveCorrecao) {
          await db.update(
            'lojas',
            {'dados_json': jsonEncode(map)},
            where: 'id = ?',
            whereArgs: [id],
          );
          debugPrint(
            '[LojasService] Autocura de imagens executada com sucesso para a loja "$id"',
          );
        }
      }
    } catch (e) {
      debugPrint('[LojasService] Erro na autocura de imagens: $e');
    }
  }

  static Future<List<File>> _localizarBackupsRecentes() async {
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
          arqs.sort(
            (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
          );
          for (final a in arqs) {
            if (!backups.any((b) => p.basename(b.path) == p.basename(a.path))) {
              backups.add(a);
            }
          }
        }
      }
    }

    if (backups.length > 3) {
      backups.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );
      backups.removeRange(3, backups.length);
    }
    return backups;
  }

  static Future<bool> _curarMapaLoja(
    String lojaId,
    Map<String, dynamic> map,
    List<File> backups,
    Map<String, Map<String, dynamic>> cacheBackups,
  ) async {
    var houveCorrecao = false;

    // 1. Logo
    final logoAtual = map['logo'] as String? ?? '';
    if (logoAtual.isNotEmpty && !ImagemService.ehAsset(logoAtual)) {
      final resolvida = ImagemService.resolverCaminhoExistente(logoAtual);
      if (resolvida != null && resolvida != logoAtual) {
        map['logo'] = resolvida;
        houveCorrecao = true;
      } else if (resolvida == null) {
        final doBackup = await _buscarFotoNoBackup(
          backups,
          lojaId,
          'logo',
          null,
          cacheBackups,
        );
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
          final doBackup = await _buscarFotoNoBackup(
            backups,
            lojaId,
            'categoria',
            catId,
            cacheBackups,
          );
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
      final imgs =
          (it['imagens'] as List? ?? []).map((e) => e.toString()).toList();
      final novasImgs = <String>[];
      var itemCorrigido = false;

      for (final img in imgs) {
        final resolvida = ImagemService.resolverCaminhoExistente(img);
        if (resolvida != null) {
          novasImgs.add(resolvida);
          if (resolvida != img) itemCorrigido = true;
        } else {
          final itemId = it['id'] as String? ?? '';
          final doBackup = await _buscarFotoNoBackup(
            backups,
            lojaId,
            'item',
            itemId,
            cacheBackups,
          );
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
    if (_curarListaCampoFoto(map['clientesLoja'] as List? ?? [])) {
      houveCorrecao = true;
    }

    // 5. Fornecedores
    if (_curarListaCampoFoto(map['fornecedoresLoja'] as List? ?? [])) {
      houveCorrecao = true;
    }

    // 6. Galeria
    final galeria =
        (map['galeria'] as List? ?? []).map((e) => e.toString()).toList();
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

    return houveCorrecao;
  }

  static bool _curarListaCampoFoto(List<dynamic> lista) {
    var houveCorrecao = false;
    for (final item in lista) {
      final foto = item['foto'] as String? ?? '';
      if (foto.isNotEmpty) {
        final resolvida = ImagemService.resolverCaminhoExistente(foto);
        if (resolvida != null && resolvida != foto) {
          item['foto'] = resolvida;
          houveCorrecao = true;
        }
      }
    }
    return houveCorrecao;
  }

  static Future<String?> _buscarFotoNoBackup(
    List<File> backups,
    String lojaId,
    String tipo,
    String? elementoId,
    Map<String, Map<String, dynamic>> cacheBackups,
  ) async {
    for (final b in backups) {
      try {
        Map<String, dynamic>? json = cacheBackups[b.path];
        if (json == null) {
          if (await b.length() > 20 * 1024 * 1024) continue;
          final content = await b.readAsString();
          json = jsonDecode(content) as Map<String, dynamic>;
          cacheBackups[b.path] = json;
        }
        final cofres = json['cofres'] as List<dynamic>? ?? [];
        for (final c in cofres) {
          final lojas = c['lojas'] as List<dynamic>? ?? [];
          for (final l in lojas) {
            if (l['id'] != lojaId) continue;

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
      } catch (_) {}
    }
    return null;
  }
}
