import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/notificacoes/models/convite_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/referencia_loja.dart';

class ResultadoImportacao {
  final int contasImportadas;
  final int lojasImportadas;
  final int referenciasImportadas;
  final int convitesImportados;

  const ResultadoImportacao({
    required this.contasImportadas,
    required this.lojasImportadas,
    required this.referenciasImportadas,
    required this.convitesImportados,
  });

  int get total =>
      contasImportadas +
      lojasImportadas +
      referenciasImportadas +
      convitesImportados;
}

class BackupService {
  BackupService._();

  static const String _prefixo = 'nous_';
  static const String _chaveContas = 'nous_contas_cpf';
  static const String _prefixoLoja = 'nous_lojas_';
  static const String _prefixoReferencia = 'nous_referencias_';
  static const String _prefixoConvite = 'nous_convites_';

  static Future<Map<String, dynamic>> gerarJson() async {
    final prefs = await SharedPreferences.getInstance();

    final contasTexto = prefs.getString(_chaveContas);
    final contas =
        contasTexto == null ? <dynamic>[] : jsonDecode(contasTexto) as List<dynamic>;

    final cofres = <Map<String, dynamic>>[];
    final convites = <Map<String, dynamic>>[];
    final cpfsJaProcessados = <String>{};

    for (final chave in prefs.getKeys()) {
      if (chave.startsWith(_prefixoLoja) ||
          chave.startsWith(_prefixoReferencia)) {
        final cpf = chave.startsWith(_prefixoLoja)
            ? chave.substring(_prefixoLoja.length)
            : chave.substring(_prefixoReferencia.length);
        if (cpfsJaProcessados.contains(cpf)) continue;
        cpfsJaProcessados.add(cpf);

        final lojasTexto = prefs.getString(_prefixoLoja + cpf) ?? '[]';
        final refsTexto = prefs.getString(_prefixoReferencia + cpf) ?? '[]';
        cofres.add({
          'cpf': cpf,
          'lojas': jsonDecode(lojasTexto),
          'referencias': jsonDecode(refsTexto),
        });
      } else if (chave.startsWith(_prefixoConvite)) {
        final cpf = chave.substring(_prefixoConvite.length);
        final texto = prefs.getString(chave) ?? '[]';
        convites.add({
          'cpf': cpf,
          'convites': jsonDecode(texto),
        });
      }
    }

    return {
      'versao': 1,
      'exportadoEm': DateTime.now().toIso8601String(),
      'contas': contas,
      'cofres': cofres,
      'convites': convites,
    };
  }

  static Future<String?> exportar() async {
    final json = await gerarJson();
    final texto = const JsonEncoder.withIndent('  ').convert(json);

    final agora = DateTime.now();
    String dois(int n) => n.toString().padLeft(2, '0');
    final sufixo = '${agora.year}${dois(agora.month)}${dois(agora.day)}_'
        '${dois(agora.hour)}${dois(agora.minute)}${dois(agora.second)}';

    const grupo = XTypeGroup(label: 'Backup Nous', extensions: ['json']);
    final local = await getSaveLocation(
      suggestedName: 'nous_backup_$sufixo.json',
      acceptedTypeGroups: const [grupo],
    );
    if (local == null) return null;

    final arquivo = File(local.path);
    await arquivo.writeAsString(texto);
    return local.path;
  }

  static Future<ResultadoImportacao?> importar({
    required bool substituir,
  }) async {
    const grupo = XTypeGroup(label: 'Backup Nous', extensions: ['json']);
    final arquivo = await openFile(acceptedTypeGroups: const [grupo]);
    if (arquivo == null) return null;

    final texto = await arquivo.readAsString();
    final json = jsonDecode(texto) as Map<String, dynamic>;
    return aplicarJson(json, substituir: substituir);
  }

  static Future<ResultadoImportacao> aplicarJson(
    Map<String, dynamic> json, {
    required bool substituir,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (substituir) {
      final chaves =
          prefs.getKeys().where((k) => k.startsWith(_prefixo)).toList();
      for (final k in chaves) {
        await prefs.remove(k);
      }
    }

    int contasImportadas = 0;
    int lojasImportadas = 0;
    int referenciasImportadas = 0;
    int convitesImportados = 0;

    final contasNovas = (json['contas'] as List<dynamic>? ?? const [])
        .map((item) => UsuarioNous.fromJson(item as Map<String, dynamic>))
        .toList();

    final contasAtuais = <UsuarioNous>[];
    final contasTexto = prefs.getString(_chaveContas);
    if (contasTexto != null && contasTexto.isNotEmpty) {
      final lista = jsonDecode(contasTexto) as List<dynamic>;
      contasAtuais.addAll(lista
          .map((item) => UsuarioNous.fromJson(item as Map<String, dynamic>)));
    }

    for (final nova in contasNovas) {
      final indice = contasAtuais.indexWhere((c) => c.cpf == nova.cpf);
      if (indice == -1) {
        contasAtuais.add(nova);
      } else {
        final emailsUnicos = {
          ...contasAtuais[indice].emails,
          ...nova.emails,
        }.toList();
        contasAtuais[indice] = nova.copyWith(emails: emailsUnicos);
      }
      contasImportadas++;
    }

    await prefs.setString(
      _chaveContas,
      jsonEncode(contasAtuais.map((c) => c.toJson()).toList()),
    );

    final cofresJson = json['cofres'] as List<dynamic>? ?? const [];
    for (final item in cofresJson) {
      final mapa = item as Map<String, dynamic>;
      final cpf = mapa['cpf'] as String;

      final lojasNovas = (mapa['lojas'] as List<dynamic>? ?? const [])
          .map((e) => Loja.fromJson(e as Map<String, dynamic>))
          .toList();
      final refsNovas = (mapa['referencias'] as List<dynamic>? ?? const [])
          .map((e) => ReferenciaLoja.fromJson(e as Map<String, dynamic>))
          .toList();

      final lojasAtuais = <Loja>[];
      final lojasTexto = prefs.getString(_prefixoLoja + cpf);
      if (lojasTexto != null && lojasTexto.isNotEmpty) {
        final lista = jsonDecode(lojasTexto) as List<dynamic>;
        lojasAtuais.addAll(lista
            .map((e) => Loja.fromJson(e as Map<String, dynamic>)));
      }

      for (final nova in lojasNovas) {
        final indice = lojasAtuais.indexWhere((l) => l.id == nova.id);
        if (indice == -1) {
          lojasAtuais.add(nova);
        } else {
          lojasAtuais[indice] = nova;
        }
        lojasImportadas++;
      }

      await prefs.setString(
        _prefixoLoja + cpf,
        jsonEncode(lojasAtuais.map((l) => l.toJson()).toList()),
      );

      final refsAtuais = <ReferenciaLoja>[];
      final refsTexto = prefs.getString(_prefixoReferencia + cpf);
      if (refsTexto != null && refsTexto.isNotEmpty) {
        final lista = jsonDecode(refsTexto) as List<dynamic>;
        refsAtuais.addAll(lista
            .map((e) => ReferenciaLoja.fromJson(e as Map<String, dynamic>)));
      }

      for (final nova in refsNovas) {
        if (!refsAtuais.any((r) => r.lojaId == nova.lojaId)) {
          refsAtuais.add(nova);
          referenciasImportadas++;
        }
      }

      await prefs.setString(
        _prefixoReferencia + cpf,
        jsonEncode(refsAtuais.map((r) => r.toJson()).toList()),
      );
    }

    final convitesJson = json['convites'] as List<dynamic>? ?? const [];
    for (final item in convitesJson) {
      final mapa = item as Map<String, dynamic>;
      final cpf = mapa['cpf'] as String;

      final novos = (mapa['convites'] as List<dynamic>? ?? const [])
          .map((e) => ConviteLoja.fromJson(e as Map<String, dynamic>))
          .toList();

      final atuais = <ConviteLoja>[];
      final texto = prefs.getString(_prefixoConvite + cpf);
      if (texto != null && texto.isNotEmpty) {
        final lista = jsonDecode(texto) as List<dynamic>;
        atuais.addAll(lista
            .map((e) => ConviteLoja.fromJson(e as Map<String, dynamic>)));
      }

      for (final novo in novos) {
        if (!atuais.any((c) => c.id == novo.id)) {
          atuais.add(novo);
          convitesImportados++;
        }
      }

      await prefs.setString(
        _prefixoConvite + cpf,
        jsonEncode(atuais.map((c) => c.toJson()).toList()),
      );
    }

    return ResultadoImportacao(
      contasImportadas: contasImportadas,
      lojasImportadas: lojasImportadas,
      referenciasImportadas: referenciasImportadas,
      convitesImportados: convitesImportados,
    );
  }
}