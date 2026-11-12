import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';
import 'package:nous/src/features/notificacoes/models/convite_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

class ConvitesService {
  ConvitesService._();

  static Future<List<ConviteLoja>> carregar(String cpf) async {
    final db = await BancoDadosService.db;
    final cpfLimpo = CpfValidator.onlyDigits(cpf);
    final rows = await db.query(
      'convites',
      where: 'cpf_destinatario = ? OR cpf_destinatario = ?',
      whereArgs: [cpfLimpo, cpf],
    );
    return rows
        .map((r) =>
            ConviteLoja.fromJson(jsonDecode(r['dados_json'] as String)))
        .toList();
  }

  static Future<void> salvar(String cpf, List<ConviteLoja> convites) async {
    final db = await BancoDadosService.db;
    final cpfLimpo = CpfValidator.onlyDigits(cpf);
    await db.transaction((txn) async {
      await txn.delete(
        'convites',
        where: 'cpf_destinatario = ? OR cpf_destinatario = ?',
        whereArgs: [cpfLimpo, cpf],
      );
      for (final c in convites) {
        await txn.insert(
          'convites',
          {
            'id': c.id,
            'cpf_destinatario': cpfLimpo,
            'dados_json': jsonEncode(c.toJson()),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  static Future<void> adicionar(
    String cpf,
    ConviteLoja convite, {
    bool originadoDaRede = false,
    Loja? loja,
  }) async {
    final db = await BancoDadosService.db;
    final cpfLimpo = CpfValidator.onlyDigits(cpf);
    await db.insert(
      'convites',
      {
        'id': convite.id,
        'cpf_destinatario': cpfLimpo,
        'dados_json': jsonEncode(convite.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (!originadoDaRede) {
      await despacharConvitePelaRede(convite, loja: loja);
    }
  }

  static Future<void> remover(
    String cpf,
    String conviteId, {
    bool originadoDaRede = false,
  }) async {
    final db = await BancoDadosService.db;
    final cpfLimpo = CpfValidator.onlyDigits(cpf);
    await db.delete(
      'convites',
      where: '(cpf_destinatario = ? OR cpf_destinatario = ?) AND id = ?',
      whereArgs: [cpfLimpo, cpf, conviteId],
    );
    if (!originadoDaRede) {
      await despacharRemocaoConvitePelaRede(cpfLimpo, conviteId);
    }
  }

  /// Despacha o convite via rede local (WebSocket) tanto do Servidor quanto do Cliente
  static Future<void> despacharConvitePelaRede(
    ConviteLoja convite, {
    Loja? loja,
  }) async {
    try {
      final payload = <String, dynamic>{
        'tipo': 'novo_convite_loja',
        'convite': convite.toJson(),
      };
      if (loja != null) {
        payload['loja'] = loja.toJson();
      }

      if (ServidorRedeLocal().ativo) {
        ServidorRedeLocal().notificarTodos(payload);
        debugPrint(
          '[ConvitesService] Convite para ${convite.cpfConvidado} transmitido pelo servidor para todos os terminais.',
        );
      } else if (ClienteRedeLocal().conectado) {
        ClienteRedeLocal().enviarMensagemRaw(payload);
        debugPrint(
          '[ConvitesService] Convite para ${convite.cpfConvidado} transmitido pelo cliente ao balcão.',
        );
      }
    } catch (e) {
      debugPrint('[ConvitesService] Erro ao despachar convite pela rede: $e');
    }
  }

  /// Despacha a remoção/resposta do convite pela rede local
  static Future<void> despacharRemocaoConvitePelaRede(
    String cpf,
    String conviteId,
  ) async {
    try {
      final payload = <String, dynamic>{
        'tipo': 'convite_loja_removido',
        'cpf': cpf,
        'conviteId': conviteId,
      };

      if (ServidorRedeLocal().ativo) {
        ServidorRedeLocal().notificarTodos(payload);
      } else if (ClienteRedeLocal().conectado) {
        ClienteRedeLocal().enviarMensagemRaw(payload);
      }
    } catch (e) {
      debugPrint('[ConvitesService] Erro ao despachar remoção de convite pela rede: $e');
    }
  }
}