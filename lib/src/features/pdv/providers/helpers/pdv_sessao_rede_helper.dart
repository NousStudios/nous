import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/providers/helpers/pdv_layout_impressora_helper.dart';
import 'package:nous/src/features/pdv/providers/helpers/pdv_membros_cargos_helper.dart';
import 'package:nous/src/features/pdv/providers/helpers/pdv_sincronizacao_dados_helper.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

/// Helper responsável por orquestrar sessão, rede local e sincronizações assíncronas do [PdvProvider].
class PdvSessaoRedeHelper {
  static bool get clienteRedeConectado => ClienteRedeLocal().conectado;

  static void tentarAutoConectarRedeLocal(PdvProvider provider) {
    unawaited(() async {
      try {
        if (!ServidorRedeLocal().ativo) {
          if (ClienteRedeLocal().conectado) {
            await ClienteRedeLocal().atualizarIdentidadeUsuario(
              cpf: provider.cpfAtual,
            );
            await ClienteRedeLocal().sincronizarPerfisLojasComServidor();
            return;
          }
          final prefs = await SharedPreferences.getInstance();
          final ultimoIp = prefs.getString('nous_ultimo_ip_balcao');
          if (ultimoIp != null && ultimoIp.isNotEmpty) {
            await ClienteRedeLocal().tentarAutoConectarSeDisponivel(provider);
          }
        }
      } catch (_) {}
    }());
  }

  static Future<Loja?> alternarFuncaoDesenvolvedorNous({
    required List<Loja> lojas,
    required String idLojaColetivaNous,
    required String cpf,
  }) async {
    final idxLoja = lojas.indexWhere((l) => l.id == idLojaColetivaNous);
    if (idxLoja == -1) return null;

    final lojaAtualizada = PdvMembrosCargosHelper.alternarFuncaoDesenvolvedor(
      lojas[idxLoja],
      cpf,
    );
    lojas[idxLoja] = lojaAtualizada;
    await LojasService.salvarLojaIndividual(lojaAtualizada);

    if (ClienteRedeLocal().conectado) {
      ClienteRedeLocal().enviarLojaAtualizada(lojaAtualizada, imediato: true);
    }
    if (ServidorRedeLocal().ativo) {
      ServidorRedeLocal().notificarTodos({
        'tipo': 'loja_atualizada',
        'loja': lojaAtualizada.toJson(),
      });
    }
    return lojaAtualizada;
  }

  static Future<List<Loja>> carregarLojasVisitante() async {
    try {
      return await LojasService.carregarTodasComerciaisParaVisitante();
    } catch (e) {
      debugPrint('[PdvProvider] Erro ao carregar lojas para visitante: $e');
      return const [];
    }
  }

  static void sincronizarFotoUsuarioEmClientes({
    required List<Loja> lojas,
    required String cpf,
    required String novaFoto,
    required Future<void> Function(Loja) salvarNoCofre,
    required VoidCallback onAlterado,
  }) {
    unawaited(
      PdvSincronizacaoDadosHelper.sincronizarFotoUsuarioEmClientes(
        lojas: lojas,
        cpf: cpf,
        novaFoto: novaFoto,
        salvarNoCofre: salvarNoCofre,
      ).then((alterou) {
        if (alterou) onAlterado();
      }),
    );
  }

  static void sincronizarDadosUsuarioEmLojas({
    required List<Loja> lojas,
    required UsuarioNous usuario,
    required Future<void> Function(Loja) salvarNoCofre,
    required VoidCallback onAlterado,
  }) {
    unawaited(
      PdvSincronizacaoDadosHelper.sincronizarDadosUsuarioEmLojas(
        lojas: lojas,
        usuario: usuario,
        salvarNoCofre: salvarNoCofre,
      ).then((alterou) {
        if (alterou) onAlterado();
      }),
    );
  }

  static void atualizarConfiguracoesImpressora({
    required List<Loja> lojas,
    required String id,
    required ConfiguracoesImpressora configuracoes,
    required String idLojaColetivaNous,
    required Future<void> Function(Loja) salvarNoCofre,
    required VoidCallback onConcluido,
  }) {
    unawaited(
      PdvLayoutImpressoraHelper.atualizarConfiguracoesImpressora(
        lojas: lojas,
        id: id,
        configuracoes: configuracoes,
        idLojaColetivaNous: idLojaColetivaNous,
        salvarNoCofre: salvarNoCofre,
      ).then((_) => onConcluido()),
    );
  }
}
