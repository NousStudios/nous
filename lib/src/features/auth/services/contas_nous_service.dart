import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/features/auth/models/fundadores_nous.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_excluidas_service.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';
import 'package:nous/src/features/pdv/models/loja.dart';

class ContasNousService {
  ContasNousService._();

  static List<UsuarioNous>? _cacheTodas;
  static final Map<String, UsuarioNous> _cachePorCpf = {};

  static void invalidarCache() {
    _cacheTodas = null;
    _cachePorCpf.clear();
  }

  static Future<List<UsuarioNous>> carregarTodas() async {
    if (_cacheTodas != null) {
      return List<UsuarioNous>.from(_cacheTodas!);
    }
    final db = await BancoDadosService.db;
    final rows = await db.query('contas_usuarios');
    final lista = rows
        .map((r) => FundadoresNous.aplicarSeloFundadorSeAplicavel(
            UsuarioNous.fromJson(jsonDecode(r['dados_json'] as String))))
        .toList();
    _cacheTodas = lista;
    for (final u in lista) {
      final cpfLimpo = u.cpf.replaceAll(RegExp(r'\D'), '');
      if (cpfLimpo.isNotEmpty) {
        _cachePorCpf[cpfLimpo] = u;
      }
    }
    return List<UsuarioNous>.from(lista);
  }

  static Future<UsuarioNous?> buscarPorCpf(String cpf) async {
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
    if (cpfLimpo.isNotEmpty && _cachePorCpf.containsKey(cpfLimpo)) {
      return _cachePorCpf[cpfLimpo];
    }
    final db = await BancoDadosService.db;
    final rows = await db.query(
      'contas_usuarios',
      where:
          "cpf = ? OR cpf = ? OR REPLACE(REPLACE(REPLACE(cpf, '.', ''), '-', ''), ' ', '') = ?",
      whereArgs: [cpf, cpfLimpo, cpfLimpo],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final usuario = FundadoresNous.aplicarSeloFundadorSeAplicavel(
      UsuarioNous.fromJson(jsonDecode(rows.first['dados_json'] as String)),
    );
    if (cpfLimpo.isNotEmpty) {
      _cachePorCpf[cpfLimpo] = usuario;
    }
    return usuario;
  }

  static Future<List<UsuarioNous>> buscarPorTermo(String termo) async {
    final contas = await carregarTodas();
    if (termo.isEmpty) return contas;
    final t = termo.trim().toLowerCase();
    final tSemArroba = t.startsWith('@') ? t.substring(1) : t;
    final digitos = t.replaceAll(RegExp(r'\D'), '');

    return contas.where((c) {
      if (c.nome.toLowerCase().contains(t) ||
          c.nomeExibicao.toLowerCase().contains(t)) {
        return true;
      }
      if (c.nomeDeUsuario.toLowerCase().contains(tSemArroba) ||
          c.usernameExibicao.toLowerCase().contains(tSemArroba)) {
        return true;
      }
      if (c.apelido.toLowerCase().contains(t) ||
          c.apelidoExibicao.toLowerCase().contains(t)) {
        return true;
      }
      if (digitos.isNotEmpty &&
          c.cpf.replaceAll(RegExp(r'\D'), '').contains(digitos)) {
        return true;
      }
      return false;
    }).toList();
  }

  static Future<String?> buscarCpfDoEmail(String email) async {
    final emailLimpo = email.trim().toLowerCase();
    if (emailLimpo.isEmpty) return null;
    final contas = await carregarTodas();
    for (final conta in contas) {
      if (conta.emails.any((e) => e.trim().toLowerCase() == emailLimpo)) {
        return conta.cpf;
      }
    }
    return null;
  }

  static Future<void> salvar(
    UsuarioNous conta, {
    bool permitirReativacao = false,
  }) async {
    final cpfLimpo = CpfValidator.onlyDigits(conta.cpf);
    if (cpfLimpo.isEmpty) return;

    if (permitirReativacao) {
      await ContasExcluidasService.removerPorCpf(cpfLimpo);
    } else if (await ContasExcluidasService.estaExcluido(cpfLimpo)) {
      await excluir(cpfLimpo);
      return;
    }

    final contaComSelo = FundadoresNous.aplicarSeloFundadorSeAplicavel(conta);
    final db = await BancoDadosService.db;
    await db.insert(
      'contas_usuarios',
      {
        'cpf': contaComSelo.cpf,
        'nome': contaComSelo.nome,
        'dados_json': jsonEncode(contaComSelo.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    invalidarCache();
  }

  static Future<void> excluir(String cpf) async {
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
    final db = await BancoDadosService.db;
    await db.delete(
      'contas_usuarios',
      where:
          "cpf = ? OR cpf = ? OR REPLACE(REPLACE(REPLACE(cpf, '.', ''), '-', ''), ' ', '') = ?",
      whereArgs: [cpf, cpfLimpo, cpfLimpo],
    );
    invalidarCache();
  }

  /// Varre o SQLite em busca de contas excluídas ou órfãs e corrige inconsistências:
  /// 1. Remove de `contas_usuarios` qualquer CPF presente em `contas_excluidas_nous` ou inválido.
  /// 2. Remove registros duplicados de um mesmo CPF (com e sem máscara) em `contas_usuarios`.
  /// 3. Expurga membros excluídos ou inexistentes da loja coletiva (`loja_nous_coletiva`).
  /// 4. Remove referências órfãs de `loja_nous_coletiva` em `referencias_loja`.
  static Future<int> varrerECorrigirBanco() async {
    var removidos = 0;
    try {
      final db = await BancoDadosService.db;
      final excluidas = await ContasExcluidasService.carregarTodas();
      final cpfsExcluidos = excluidas
          .map((e) => CpfValidator.onlyDigits(e.cpf))
          .where((c) => c.isNotEmpty)
          .toSet();

      final rowsContas = await db.query('contas_usuarios');
      final chavesVistas = <String, String>{};
      final cpfsAtivos = <String>{};

      for (final row in rowsContas) {
        final chaveLinha = row['cpf']?.toString() ?? '';
        final cpfNorm = CpfValidator.onlyDigits(chaveLinha);

        if (cpfNorm.length != 11 || cpfsExcluidos.contains(cpfNorm)) {
          await db.delete(
            'contas_usuarios',
            where: 'cpf = ?',
            whereArgs: [chaveLinha],
          );
          removidos++;
          continue;
        }

        // Expurga registros fantasmas recriados no passado com placeholder "Usuário Nous"
        // sem chaves criptográficas, sem data de criação e sem e-mails vinculados.
        try {
          final dados =
              jsonDecode(row['dados_json'] as String) as Map<String, dynamic>;
          final nome = (dados['nome']?.toString() ?? '').trim().toLowerCase();
          final chavePub = (dados['chavePublica']?.toString() ?? '').trim();
          final criadoEm = (dados['criadoEm']?.toString() ?? '').trim();
          final emails = (dados['emails'] as List<dynamic>? ?? const []);
          final ehFantasmaPlaceholder =
              (nome == 'usuário nous' || nome == 'usuario nous') &&
                  chavePub.isEmpty &&
                  criadoEm.isEmpty &&
                  emails.isEmpty;
          if (ehFantasmaPlaceholder) {
            await ContasExcluidasService.registrarExclusao(
              UsuarioNous.fromJson(dados),
            );
            cpfsExcluidos.add(cpfNorm);
            await db.delete(
              'contas_usuarios',
              where: 'cpf = ?',
              whereArgs: [chaveLinha],
            );
            removidos++;
            continue;
          }
        } catch (_) {}

        if (chavesVistas.containsKey(cpfNorm)) {
          // Mantém preferencialmente a chave já normalizada (apenas dígitos)
          final chaveAnterior = chavesVistas[cpfNorm]!;
          if (chaveAnterior != cpfNorm && chaveLinha == cpfNorm) {
            await db.delete(
              'contas_usuarios',
              where: 'cpf = ?',
              whereArgs: [chaveAnterior],
            );
            chavesVistas[cpfNorm] = chaveLinha;
          } else {
            await db.delete(
              'contas_usuarios',
              where: 'cpf = ?',
              whereArgs: [chaveLinha],
            );
          }
          removidos++;
          continue;
        }

        chavesVistas[cpfNorm] = chaveLinha;
        cpfsAtivos.add(cpfNorm);
      }

      // Varre membros da loja coletiva Nous na tabela `lojas`
      final rowsColetiva = await db.query(
        'lojas',
        where: 'id = ?',
        whereArgs: ['loja_nous_coletiva'],
        limit: 1,
      );
      if (rowsColetiva.isNotEmpty) {
        final dadosStr = rowsColetiva.first['dados_json'] as String?;
        if (dadosStr != null && dadosStr.isNotEmpty) {
          final lojaColetiva =
              Loja.fromJson(jsonDecode(dadosStr) as Map<String, dynamic>);
          final membrosLimpos = lojaColetiva.membros.where((m) {
            final mCpf = CpfValidator.onlyDigits(m.cpf);
            if (mCpf.length != 11) return false;
            if (cpfsExcluidos.contains(mCpf)) return false;
            if (cpfsAtivos.isNotEmpty && !cpfsAtivos.contains(mCpf)) {
              return false;
            }
            return true;
          }).toList();

          if (membrosLimpos.length != lojaColetiva.membros.length) {
            removidos += lojaColetiva.membros.length - membrosLimpos.length;
            final atualizada = lojaColetiva.copyWith(membros: membrosLimpos);
            await db.update(
              'lojas',
              {'dados_json': jsonEncode(atualizada.toJson())},
              where: 'id = ?',
              whereArgs: ['loja_nous_coletiva'],
            );
          }
        }
      }

      // Remove referências de loja coletiva pertencentes a CPFs excluídos
      if (cpfsExcluidos.isNotEmpty) {
        final rowsRefs = await db.query(
          'referencias_loja',
          where: 'loja_id = ?',
          whereArgs: ['loja_nous_coletiva'],
        );
        for (final r in rowsRefs) {
          final rCpf = CpfValidator.onlyDigits(r['cpf']?.toString() ?? '');
          if (cpfsExcluidos.contains(rCpf)) {
            await db.delete(
              'referencias_loja',
              where: 'id = ?',
              whereArgs: [r['id']],
            );
            removidos++;
          }
        }
      }

      if (removidos > 0) {
        invalidarCache();
        debugPrint(
          '[ContasNousService] Varredura SQLite concluiu e removeu $removidos registro(s) excluído(s)/órfão(s).',
        );
      }
    } catch (e) {
      debugPrint('[ContasNousService] Erro na varredura SQLite: $e');
    }
    return removidos;
  }
}