import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/core/services/criptografia_service.dart';
import 'package:nous/src/core/services/gerador_id.dart';
import 'package:nous/src/features/auth/models/solicitacao_validacao_identidade.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';

/// Serviço responsável pelo gerenciamento de validação e atesto comunitário de identidades.
class ValidacaoIdentidadeService {
  ValidacaoIdentidadeService._();

  static bool _tabelaCriada = false;

  static Future<void> _garantirTabela(Database db) async {
    if (_tabelaCriada) return;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS validacoes_identidade (
        id TEXT PRIMARY KEY,
        cpf_candidato TEXT NOT NULL,
        status TEXT NOT NULL,
        data_hora_solicitacao TEXT NOT NULL,
        dados_json TEXT NOT NULL
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_val_status ON validacoes_identidade (status);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_val_cpf ON validacoes_identidade (cpf_candidato);',
    );
    _tabelaCriada = true;
  }

  /// Submete uma nova solicitação de validação de identidade
  static Future<SolicitacaoValidacaoIdentidade> submeterSolicitacao(UsuarioNous usuario) async {
    final db = await BancoDadosService.db;
    await _garantirTabela(db);

    final agora = DateTime.now().toIso8601String();
    final id = 'val_${gerarIdUnico()}';

    final solicitacao = SolicitacaoValidacaoIdentidade(
      id: id,
      cpfCandidato: usuario.cpf,
      nomeCandidato: usuario.nomeExibicao,
      apelidoCandidato: usuario.apelidoExibicao,
      nomeDeUsuario: usuario.nomeDeUsuario,
      fotoCandidato: usuario.foto,
      chavePublicaCandidato: usuario.chavePublica,
      dataHoraSolicitacao: agora,
      status: StatusValidacaoIdentidade.pendente,
    );

    await db.insert(
      'validacoes_identidade',
      {
        'id': id,
        'cpf_candidato': usuario.cpf,
        'status': solicitacao.status.name,
        'data_hora_solicitacao': agora,
        'dados_json': jsonEncode(solicitacao.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    debugPrint('[ValidacaoIdentidadeService] Solicitação de validação criada para ${usuario.cpf}');
    return solicitacao;
  }

  /// Lista solicitações de validação (todas ou filtradas por status)
  static Future<List<SolicitacaoValidacaoIdentidade>> listarSolicitacoes({
    StatusValidacaoIdentidade? status,
  }) async {
    final db = await BancoDadosService.db;
    await _garantirTabela(db);

    final List<Map<String, Object?>> resultados;
    if (status != null) {
      resultados = await db.query(
        'validacoes_identidade',
        where: 'status = ?',
        whereArgs: [status.name],
        orderBy: 'data_hora_solicitacao DESC',
      );
    } else {
      resultados = await db.query(
        'validacoes_identidade',
        orderBy: 'data_hora_solicitacao DESC',
      );
    }

    final lista = <SolicitacaoValidacaoIdentidade>[];
    for (final row in resultados) {
      final jsonStr = row['dados_json']?.toString();
      if (jsonStr != null && jsonStr.isNotEmpty) {
        try {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          lista.add(SolicitacaoValidacaoIdentidade.fromJson(map));
        } catch (_) {}
      }
    }
    return lista;
  }

  /// Aprova e atesta a identidade de um cidadão com assinatura criptográfica Ed25519
  static Future<bool> aprovarIdentidade({
    required SolicitacaoValidacaoIdentidade solicitacao,
    required String cpfValidador,
    required String nomeValidador,
  }) async {
    final agora = DateTime.now().toIso8601String();
    var atualizada = solicitacao.copyWith(
      status: StatusValidacaoIdentidade.aprovado,
      cpfValidador: cpfValidador,
      nomeValidador: nomeValidador,
      dataHoraValidacao: agora,
    );

    // Gera a assinatura criptográfica soberana da validação
    final carga = atualizada.gerarCargaParaAssinatura();
    final assinatura = await CriptografiaService.assinarDados(
      cpf: cpfValidador,
      mensagem: carga,
    );

    if (assinatura != null) {
      atualizada = atualizada.copyWith(assinaturaValidador: assinatura);
    }

    final db = await BancoDadosService.db;
    await _garantirTabela(db);

    await db.update(
      'validacoes_identidade',
      {
        'status': atualizada.status.name,
        'dados_json': jsonEncode(atualizada.toJson()),
      },
      where: 'id = ?',
      whereArgs: [atualizada.id],
    );

    debugPrint('[ValidacaoIdentidadeService] Identidade de ${atualizada.cpfCandidato} ATESTADA com sucesso por $nomeValidador!');
    return true;
  }

  /// Rejeita a solicitação com justificativa
  static Future<bool> rejeitarIdentidade({
    required SolicitacaoValidacaoIdentidade solicitacao,
    required String cpfValidador,
    required String nomeValidador,
    required String justificativa,
  }) async {
    final agora = DateTime.now().toIso8601String();
    final atualizada = solicitacao.copyWith(
      status: StatusValidacaoIdentidade.rejeitado,
      cpfValidador: cpfValidador,
      nomeValidador: nomeValidador,
      dataHoraValidacao: agora,
      justificativa: justificativa,
    );

    final db = await BancoDadosService.db;
    await _garantirTabela(db);

    await db.update(
      'validacoes_identidade',
      {
        'status': atualizada.status.name,
        'dados_json': jsonEncode(atualizada.toJson()),
      },
      where: 'id = ?',
      whereArgs: [atualizada.id],
    );

    return true;
  }
}
