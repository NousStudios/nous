import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/core/services/preferencias_soberanas_service.dart';
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
      } else {
        final pend = await PreferenciasSoberanasService.obterLista(
          'convites_pendentes_envio',
        );
        final jsonStr = jsonEncode(payload);
        if (!pend.contains(jsonStr)) {
          await PreferenciasSoberanasService.salvarLista(
            'convites_pendentes_envio',
            [...pend, jsonStr],
          );
        }
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
      } else {
        final pend = await PreferenciasSoberanasService.obterLista(
          'convites_pendentes_remocao',
        );
        final chave = '$cpf|$conviteId';
        if (!pend.contains(chave)) {
          await PreferenciasSoberanasService.salvarLista(
            'convites_pendentes_remocao',
            [...pend, chave],
          );
        }
      }
    } catch (e) {
      debugPrint('[ConvitesService] Erro ao despachar remoção de convite pela rede: $e');
    }
  }

  /// Drena convites e remoções de convites realizados offline assim que o terminal conecta.
  static Future<void> drenarPendenciasOffline() async {
    if (!ClienteRedeLocal().conectado) return;
    try {
      final envios = await PreferenciasSoberanasService.obterLista(
        'convites_pendentes_envio',
      );
      if (envios.isNotEmpty) {
        for (final raw in envios) {
          try {
            final payload = jsonDecode(raw) as Map<String, dynamic>;
            ClienteRedeLocal().enviarMensagemRaw(payload);
          } catch (_) {}
        }
        await PreferenciasSoberanasService.salvarLista(
          'convites_pendentes_envio',
          const [],
        );
      }

      final remocoes = await PreferenciasSoberanasService.obterLista(
        'convites_pendentes_remocao',
      );
      if (remocoes.isNotEmpty) {
        for (final item in remocoes) {
          final partes = item.split('|');
          if (partes.length == 2) {
            ClienteRedeLocal().enviarMensagemRaw({
              'tipo': 'convite_loja_removido',
              'cpf': partes[0],
              'conviteId': partes[1],
            });
          }
        }
        await PreferenciasSoberanasService.salvarLista(
          'convites_pendentes_remocao',
          const [],
        );
      }
    } catch (_) {}
  }
}