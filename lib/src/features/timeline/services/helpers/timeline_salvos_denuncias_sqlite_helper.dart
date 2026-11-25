import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/features/timeline/models/salvos_denuncia_social.dart';
import 'package:nous/src/features/timeline/services/helpers/timeline_sqlite_utils.dart';

/// Helper SQLite para listas de salvos, itens salvos e denúncias sociais.
class TimelineSalvosDenunciasSqliteHelper {
  TimelineSalvosDenunciasSqliteHelper._();

  static Future<void> salvarListaSalvos(
    Database db,
    ListaSalvosSocial lista,
  ) async {
    await db.insert(
      'listas_salvos_sociais',
      {
        'id': lista.id,
        'dono_cpf': TimelineSqliteUtils.normalizarCpf(lista.donoCpf),
        'criada_em': lista.criadaEm.toIso8601String(),
        'atualizada_em': lista.atualizadaEfetiva.toIso8601String(),
        'dados_json': jsonEncode(lista.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<ListaSalvosSocial>> listarListasSalvosDoUsuario(
    Database db,
    String cpf,
  ) async {
    final cpfNorm = TimelineSqliteUtils.normalizarCpf(cpf);
    final rows = await db.query(
      'listas_salvos_sociais',
      orderBy: 'criada_em ASC',
    );
    return rows
        .map(
          (r) => ListaSalvosSocial.fromJson(
            TimelineSqliteUtils.decodificarDadosJson(r),
          ),
        )
        .where(
          (l) =>
              TimelineSqliteUtils.normalizarCpf(l.donoCpf) == cpfNorm ||
              l.colaboradoresCpfs
                  .any((c) => TimelineSqliteUtils.normalizarCpf(c) == cpfNorm),
        )
        .toList();
  }

  static Future<void> salvarItemSalvo(
    Database db,
    ItemSalvoSocial item,
  ) async {
    await db.insert(
      'itens_salvos_sociais',
      {
        'id': item.id,
        'lista_id': item.listaId,
        'usuario_cpf': TimelineSqliteUtils.normalizarCpf(item.usuarioCpf),
        'publicacao_id': item.publicacaoId,
        'salvo_em': item.salvoEm.toIso8601String(),
        'atualizada_em': item.salvoEm.toIso8601String(),
        'dados_json': jsonEncode(item.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<ItemSalvoSocial>> listarItensSalvosPorLista(
    Database db,
    String listaId,
  ) async {
    final rows = await db.query(
      'itens_salvos_sociais',
      where: 'lista_id = ?',
      whereArgs: [listaId],
      orderBy: 'salvo_em DESC',
    );
    return rows
        .map(
          (r) => ItemSalvoSocial.fromJson(
            TimelineSqliteUtils.decodificarDadosJson(r),
          ),
        )
        .toList();
  }

  static Future<List<ItemSalvoSocial>> listarItensSalvosDoUsuario(
    Database db,
    String cpf,
  ) async {
    final cpfNorm = TimelineSqliteUtils.normalizarCpf(cpf);
    if (cpfNorm.isEmpty) return const [];
    final rows = await db.query(
      'itens_salvos_sociais',
      where: 'usuario_cpf = ?',
      whereArgs: [cpfNorm],
      orderBy: 'salvo_em DESC',
      limit: 80,
    );
    return rows
        .map(
          (r) => ItemSalvoSocial.fromJson(
            TimelineSqliteUtils.decodificarDadosJson(r),
          ),
        )
        .toList();
  }

  static Future<void> salvarDenuncia(
    Database db,
    DenunciaSocial denuncia,
  ) async {
    await db.insert(
      'denuncias_sociais',
      {
        'id': denuncia.id,
        'denunciante_cpf':
            TimelineSqliteUtils.normalizarCpf(denuncia.denuncianteCpf),
        'alvo_cpf': TimelineSqliteUtils.normalizarCpf(denuncia.alvoCpf),
        'publicacao_id': denuncia.publicacaoId,
        'criada_em': denuncia.criadaEm.toIso8601String(),
        'atualizada_em': denuncia.criadaEm.toIso8601String(),
        'dados_json': jsonEncode(denuncia.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<DenunciaSocial>> listarDenunciasEnvolvendoUsuario(
    Database db,
    String cpf,
  ) async {
    final cpfNorm = TimelineSqliteUtils.normalizarCpf(cpf);
    final rows = await db.query(
      'denuncias_sociais',
      where: 'denunciante_cpf = ? OR alvo_cpf = ?',
      whereArgs: [cpfNorm, cpfNorm],
      orderBy: 'criada_em DESC',
    );
    return rows
        .map(
          (r) => DenunciaSocial.fromJson(
            TimelineSqliteUtils.decodificarDadosJson(r),
          ),
        )
        .toList();
  }
}
