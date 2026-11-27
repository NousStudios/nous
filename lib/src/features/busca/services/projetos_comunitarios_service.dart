import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/features/busca/models/projeto_comunitario.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

/// Persistência soberana local dos Projetos Comunitários no Mapa (Autogestão Social).
class ProjetosComunitariosService {
  ProjetosComunitariosService._();

  static bool _tabelaGarantida = false;
  static final ValueNotifier<int> versaoAtualizacao = ValueNotifier<int>(0);

  static Future<Database> _db() async {
    final db = await BancoDadosService.db;
    if (!_tabelaGarantida) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS projetos_comunitarios (
          id TEXT PRIMARY KEY,
          dados_json TEXT NOT NULL,
          atualizado_em TEXT NOT NULL
        );
      ''');
      _tabelaGarantida = true;
    }
    return db;
  }

  static Future<List<ProjetoComunitario>> listarTodos() async {
    final db = await _db();
    final rows = await db.query(
      'projetos_comunitarios',
      orderBy: 'atualizado_em DESC',
    );
    final lista = <ProjetoComunitario>[];
    for (final row in rows) {
      try {
        final map =
            jsonDecode(row['dados_json'] as String) as Map<String, dynamic>;
        lista.add(ProjetoComunitario.fromJson(map));
      } catch (_) {}
    }
    return lista;
  }

  static Future<void> salvar(
    ProjetoComunitario projeto, {
    bool originadoDaRede = false,
  }) async {
    final db = await _db();
    await db.insert(
      'projetos_comunitarios',
      {
        'id': projeto.id,
        'dados_json': jsonEncode(projeto.toJson()),
        'atualizado_em': projeto.atualizadoEm.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    versaoAtualizacao.value++;
    if (!originadoDaRede) {
      final evento = {
        'tipo': 'projeto_comunitario_salvo',
        'projeto': projeto.toJson(),
      };
      if (ServidorRedeLocal().ativo) {
        ServidorRedeLocal().notificarTodos(evento);
      } else if (ClienteRedeLocal().conectado) {
        ClienteRedeLocal().enviarEventoWs(evento);
      }
    }
  }

  static Future<void> mesclarRemotos(List<ProjetoComunitario> remotos) async {
    if (remotos.isEmpty) return;
    final locais = {for (final p in await listarTodos()) p.id: p};
    var alterou = false;
    for (final r in remotos) {
      final local = locais[r.id];
      if (local == null) {
        await salvar(r, originadoDaRede: true);
        alterou = true;
      } else {
        final base = r.atualizadoEm.isAfter(local.atualizadoEm) ? r : local;
        final apoiosUnidos = {
          ...local.apoiadoresCpfs,
          ...r.apoiadoresCpfs,
        }.toList();
        if (r.atualizadoEm.isAfter(local.atualizadoEm) ||
            apoiosUnidos.length != local.apoiadoresCpfs.length) {
          await salvar(
            base.copyWith(apoiadoresCpfs: apoiosUnidos),
            originadoDaRede: true,
          );
          alterou = true;
        }
      }
    }
    if (alterou) {
      versaoAtualizacao.value++;
    }
  }

  static Future<ProjetoComunitario> alternarApoio({
    required ProjetoComunitario projeto,
    required String cpfUsuario,
  }) async {
    final cpfNorm = cpfUsuario.replaceAll(RegExp(r'\D'), '');
    if (cpfNorm.isEmpty) return projeto;
    final apoiadores = List<String>.from(projeto.apoiadoresCpfs);
    if (apoiadores.contains(cpfNorm)) {
      apoiadores.remove(cpfNorm);
    } else {
      apoiadores.add(cpfNorm);
    }
    final atualizado = projeto.copyWith(
      apoiadoresCpfs: apoiadores,
      atualizadoEm: DateTime.now(),
    );
    await salvar(atualizado);
    return atualizado;
  }

  static Future<ProjetoComunitario> assumirResponsabilidade({
    required ProjetoComunitario projeto,
    required String cpfUsuario,
    required String nomeUsuario,
  }) async {
    final atualizado = projeto.copyWith(
      responsavelCpf: cpfUsuario.replaceAll(RegExp(r'\D'), ''),
      responsavelNome: nomeUsuario,
      status: StatusProjetoComunitario.emAndamento,
      atualizadoEm: DateTime.now(),
    );
    await salvar(atualizado);
    return atualizado;
  }

  static Future<ProjetoComunitario> atualizarStatus({
    required ProjetoComunitario projeto,
    required StatusProjetoComunitario status,
  }) async {
    final atualizado = projeto.copyWith(
      status: status,
      atualizadoEm: DateTime.now(),
    );
    await salvar(atualizado);
    return atualizado;
  }
}
