import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/notificacoes/models/convite_loja.dart';
import 'package:nous/src/features/notificacoes/services/convites_service.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/referencia_loja.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';

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

  bool get vazio => total == 0;
}

class BackupService {
  BackupService._();

  static Future<Map<String, dynamic>> gerarJson() async {
    final contas = await ContasNousService.carregarTodas();
    final db = await BancoDadosService.db;

    final cpfs = <String>{};
    for (final c in contas) {
      if (c.cpf.isNotEmpty) cpfs.add(c.cpf);
    }

    final rowsLojas = await db.rawQuery('SELECT DISTINCT cpf_dono FROM lojas');
    for (final r in rowsLojas) {
      final cpf = r['cpf_dono']?.toString() ?? '';
      if (cpf.isNotEmpty) cpfs.add(cpf);
    }

    final rowsRefs = await db.rawQuery('SELECT DISTINCT cpf FROM referencias_loja');
    for (final r in rowsRefs) {
      final cpf = r['cpf']?.toString() ?? '';
      if (cpf.isNotEmpty) cpfs.add(cpf);
    }

    final cofres = <Map<String, dynamic>>[];
    for (final cpf in cpfs) {
      final lojas = await LojasService.carregar(cpf);
      final refs = await LojasService.carregarReferencias(cpf);
      if (lojas.isNotEmpty || refs.isNotEmpty) {
        cofres.add({
          'cpf': cpf,
          'lojas': lojas.map((l) => l.toJson()).toList(),
          'referencias': refs.map((r) => r.toJson()).toList(),
        });
      }
    }

    final rowsConvites =
        await db.rawQuery('SELECT DISTINCT cpf_destinatario FROM convites');
    final convites = <Map<String, dynamic>>[];
    for (final r in rowsConvites) {
      final cpf = r['cpf_destinatario']?.toString() ?? '';
      if (cpf.isEmpty) continue;
      final lista = await ConvitesService.carregar(cpf);
      if (lista.isNotEmpty) {
        convites.add({
          'cpf': cpf,
          'convites': lista.map((c) => c.toJson()).toList(),
        });
      }
    }

    return {
      'versao': 1,
      'exportadoEm': DateTime.now().toIso8601String(),
      'contas': contas.map((c) => c.toJson()).toList(),
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
    final db = await BancoDadosService.db;

    if (substituir) {
      await db.transaction((txn) async {
        await txn.delete('contas_usuarios');
        await txn.delete('lojas');
        await txn.delete('pedidos');
        await txn.delete('movimentos_estoque');
        await txn.delete('pagamentos_funcionarios');
        await txn.delete('referencias_loja');
        await txn.delete('convites');
      });
    }

    int contasImportadas = 0;
    int lojasImportadas = 0;
    int referenciasImportadas = 0;
    int convitesImportados = 0;

    final contasNovas = (json['contas'] as List<dynamic>? ?? const [])
        .map((item) => UsuarioNous.fromJson(item as Map<String, dynamic>))
        .toList();

    for (final nova in contasNovas) {
      final atual = await ContasNousService.buscarPorCpf(nova.cpf);
      if (atual == null) {
        await ContasNousService.salvar(nova);
      } else {
        final emailsUnicos = {
          ...atual.emails,
          ...nova.emails,
        }.toList();
        await ContasNousService.salvar(nova.copyWith(emails: emailsUnicos));
      }
      contasImportadas++;
    }

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

      final lojasAtuais = await LojasService.carregar(cpf);
      final lojasMescladas = <Loja>[...lojasAtuais];

      for (final nova in lojasNovas) {
        final indice = lojasMescladas.indexWhere((l) => l.id == nova.id);
        if (indice == -1) {
          lojasMescladas.add(nova);
        } else {
          lojasMescladas[indice] = nova;
        }
        lojasImportadas++;
      }

      await LojasService.salvar(cpf, lojasMescladas);

      final refsAtuais = await LojasService.carregarReferencias(cpf);
      final refsMescladas = <ReferenciaLoja>[...refsAtuais];

      for (final nova in refsNovas) {
        if (!refsMescladas.any((r) => r.lojaId == nova.lojaId)) {
          refsMescladas.add(nova);
          referenciasImportadas++;
        }
      }

      await LojasService.salvarReferencias(cpf, refsMescladas);
    }

    final convitesJson = json['convites'] as List<dynamic>? ?? const [];
    for (final item in convitesJson) {
      final mapa = item as Map<String, dynamic>;
      final cpf = mapa['cpf'] as String;

      final novos = (mapa['convites'] as List<dynamic>? ?? const [])
          .map((e) => ConviteLoja.fromJson(e as Map<String, dynamic>))
          .toList();

      final atuais = await ConvitesService.carregar(cpf);
      final mesclados = <ConviteLoja>[...atuais];

      for (final novo in novos) {
        if (!mesclados.any((c) => c.id == novo.id)) {
          mesclados.add(novo);
          convitesImportados++;
        }
      }

      await ConvitesService.salvar(cpf, mesclados);
    }

    return ResultadoImportacao(
      contasImportadas: contasImportadas,
      lojasImportadas: lojasImportadas,
      referenciasImportadas: referenciasImportadas,
      convitesImportados: convitesImportados,
    );
  }
}