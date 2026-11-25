import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:nous/src/core/services/som_service.dart';
import 'package:nous/src/features/notificacoes/models/convite_loja.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/notificacoes/services/convites_service.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/handlers/autorizador_loja_balcao.dart';
import 'package:nous/src/features/pdv/services/rede_local/handlers/servidor_ws_message_handler.dart';

/// Helper para processamento de eventos de pedidos, clientes, lojas e convites no servidor WS.
class ServidorWsPdvConvitesHelper {
  /// Tenta processar eventos de PDV e convites de loja. Retorna `true` se tratado.
  static Future<bool> tentarProcessar(
    String? tipo,
    WebSocket ws,
    Map<String, dynamic> dados,
    ServidorWsContext ctx,
  ) async {
    if (tipo == 'pedido_atualizado' || tipo == 'pedido_adicionado') {
      processarPedidoAtualizado(ws, dados, ctx);
      return true;
    }

    if (tipo == 'cliente_atualizado') {
      processarClienteAtualizado(ws, dados, ctx);
      return true;
    }

    if (tipo == 'loja_excluida') {
      await processarLojaExcluida(ws, dados, ctx);
      return true;
    }

    if (tipo == 'novo_convite_loja') {
      await processarNovoConviteLoja(ws, dados, ctx);
      return true;
    }

    if (tipo == 'convite_loja_removido') {
      await processarConviteLojaRemovido(ws, dados, ctx);
      return true;
    }

    return false;
  }

  static void processarPedidoAtualizado(
    WebSocket ws,
    Map<String, dynamic> dados,
    ServidorWsContext ctx,
  ) {
    if (dados['pedido'] == null || ctx.pdvProvider == null) return;
    final pedido = PedidoLoja.fromJson(
      dados['pedido'] as Map<String, dynamic>,
    );
    final lojaAtiva = ctx.obterLojaAtiva();
    final lojaIdExplicito = pedido.lojaId.isNotEmpty
        ? pedido.lojaId
        : (dados['lojaId'] as String? ?? '');
    final lojaIdAlvo = lojaIdExplicito.isNotEmpty
        ? lojaIdExplicito
        : (lojaAtiva?.id ?? '');

    final lojaAtual = AutorizadorLojaBalcao.obterLojaHospedada(
      lojaIdBruto: lojaIdAlvo,
      lojaAtiva: lojaAtiva,
      pdvProvider: ctx.pdvProvider,
      cpfOperadorBalcao: ctx.authProvider?.contaAtual?.cpf,
    );
    if (lojaAtual != null) {
      final pedidos = List<PedidoLoja>.from(lojaAtual.pedidosLoja);
      final idx = pedidos.indexWhere((p) => p.id == pedido.id);
      final ehNovo = idx == -1;
      if (idx != -1) {
        pedidos[idx] = pedido;
      } else {
        pedidos.insert(0, pedido);
      }
      ctx.pdvProvider!.atualizarListasLoja(lojaAtual.id, pedidos: pedidos);

      if (ehNovo) {
        SomService.tocarEvento(
          SomService.eventoNovoPedido,
          loja: lojaAtual,
        );
      }

      final payload = jsonEncode({
        'tipo': ehNovo ? 'pedido_adicionado' : 'pedido_atualizado',
        'lojaId': lojaAtual.id,
        'pedido': pedido.toJson(),
      });
      ctx.retransmitirParaOutros(payload, exceto: ws);
    } else {
      debugPrint(
        '[ServidorRedeLocal] Pedido ignorado: loja "$lojaIdAlvo" não é hospedada por este balcão.',
      );
    }
  }

  static void processarClienteAtualizado(
    WebSocket ws,
    Map<String, dynamic> dados,
    ServidorWsContext ctx,
  ) {
    if (dados['cliente'] == null || ctx.pdvProvider == null) return;
    final cliente = Cliente.fromJson(
      dados['cliente'] as Map<String, dynamic>,
    );
    final lojaAtiva = ctx.obterLojaAtiva();
    final lojaIdExplicito = (dados['lojaId'] as String?)?.trim() ?? '';
    final lojaIdAlvo = lojaIdExplicito.isNotEmpty
        ? lojaIdExplicito
        : (lojaAtiva?.id ?? '');

    final lojaAtual = AutorizadorLojaBalcao.obterLojaHospedada(
      lojaIdBruto: lojaIdAlvo,
      lojaAtiva: lojaAtiva,
      pdvProvider: ctx.pdvProvider,
      cpfOperadorBalcao: ctx.authProvider?.contaAtual?.cpf,
    );
    if (lojaAtual != null) {
      final clientes = List<Cliente>.from(lojaAtual.clientesLoja);
      final idx = clientes.indexWhere((c) => c.id == cliente.id);
      if (idx != -1) {
        clientes[idx] = cliente;
      } else {
        clientes.add(cliente);
      }
      ctx.pdvProvider!.atualizarListasLoja(lojaAtual.id, clientes: clientes);

      final payload = jsonEncode({
        'tipo': 'cliente_atualizado',
        'lojaId': lojaAtual.id,
        'cliente': cliente.toJson(),
      });
      ctx.retransmitirParaOutros(payload, exceto: ws);
    }
  }

  static Future<void> processarLojaExcluida(
    WebSocket ws,
    Map<String, dynamic> dados,
    ServidorWsContext ctx,
  ) async {
    final lojaId = dados['lojaId'] as String?;
    final lojaAtual = AutorizadorLojaBalcao.obterLojaHospedada(
      lojaIdBruto: lojaId,
      lojaAtiva: ctx.obterLojaAtiva(),
      pdvProvider: ctx.pdvProvider,
      cpfOperadorBalcao: ctx.authProvider?.contaAtual?.cpf,
    );
    if (lojaAtual != null && ctx.pdvProvider != null) {
      await ctx.pdvProvider!.excluirLoja(lojaAtual.id, originadaDaRede: true);
      final payload = jsonEncode({
        'tipo': 'loja_excluida',
        'lojaId': lojaAtual.id,
      });
      ctx.retransmitirParaOutros(payload, exceto: ws);
    }
  }

  static Future<void> processarNovoConviteLoja(
    WebSocket ws,
    Map<String, dynamic> dados,
    ServidorWsContext ctx,
  ) async {
    if (dados['convite'] == null) return;
    try {
      final convite = ConviteLoja.fromJson(
        dados['convite'] as Map<String, dynamic>,
      );
      Loja? lojaAnexa;
      if (dados['loja'] != null) {
        lojaAnexa = Loja.fromJson(dados['loja'] as Map<String, dynamic>);
        await LojasService.salvarLojaIndividual(lojaAnexa);
      }
      await ConvitesService.adicionar(
        convite.cpfConvidado,
        convite,
        originadoDaRede: true,
      );
      NotificacoesProvider.instanciaAtiva?.recarregarSeuCpf();

      final payload = jsonEncode({
        'tipo': 'novo_convite_loja',
        'convite': convite.toJson(),
        if (lojaAnexa != null) 'loja': lojaAnexa.toJson(),
      });
      ctx.retransmitirParaOutros(payload, exceto: ws);
      debugPrint(
        '[ServidorRedeLocal] Convite da loja "${convite.nomeLoja}" para ${convite.cpfConvidado} retransmitido na rede local.',
      );
    } catch (e) {
      debugPrint(
        '[ServidorRedeLocal] Erro ao processar novo_convite_loja via WS: $e',
      );
    }
  }

  static Future<void> processarConviteLojaRemovido(
    WebSocket ws,
    Map<String, dynamic> dados,
    ServidorWsContext ctx,
  ) async {
    final cpf = dados['cpf'] as String?;
    final conviteId = dados['conviteId'] as String?;
    if (cpf != null && conviteId != null) {
      await ConvitesService.remover(cpf, conviteId, originadoDaRede: true);
      NotificacoesProvider.instanciaAtiva?.recarregarSeuCpf();
      final payload = jsonEncode({
        'tipo': 'convite_loja_removido',
        'cpf': cpf,
        'conviteId': conviteId,
      });
      ctx.retransmitirParaOutros(payload, exceto: ws);
    }
  }
}
