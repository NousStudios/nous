import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:nous/src/core/utils/json_isolate_utils.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/busca/models/avaliacao_produto.dart';
import 'package:nous/src/features/busca/services/avaliacoes_produto_service.dart';
import 'package:nous/src/features/busca/services/mapa_espelhamento_service.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/terminal_conectado_info.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/rede_local/handlers/helpers/servidor_ws_chat_social_helper.dart';
import 'package:nous/src/features/pdv/services/rede_local/handlers/helpers/servidor_ws_identificacao_usuarios_helper.dart';
import 'package:nous/src/features/pdv/services/rede_local/handlers/helpers/servidor_ws_pdv_convites_helper.dart';

/// Contexto de execução para processamento de mensagens WebSocket no Servidor de Rede Local.
class ServidorWsContext {
  final Map<WebSocket, TerminalConectadoInfo> terminaisWs;
  final List<WebSocket> clientesWs;
  final PdvProvider? pdvProvider;
  final AuthProvider? authProvider;
  final Loja? Function() obterLojaAtiva;
  final VoidCallback atualizarListasTerminais;
  final VoidCallback notificarPresencas;
  final void Function(TerminalConectadoInfo) consolidarContaTerminal;
  final void Function(Map<String, dynamic>) processarSinalChamadaLocal;

  const ServidorWsContext({
    required this.terminaisWs,
    required this.clientesWs,
    required this.pdvProvider,
    required this.authProvider,
    required this.obterLojaAtiva,
    required this.atualizarListasTerminais,
    required this.notificarPresencas,
    required this.consolidarContaTerminal,
    required this.processarSinalChamadaLocal,
  });

  /// Envia payload serializado para todos os clientes conectados, exceto o emissor original se fornecido.
  /// Aplica filtragem de privacidade soberana: clientes externos recebem apenas eventos pertinentes
  /// a eles e visões públicas/cardápios, bloqueando o vazamento de dados internos de gestão.
  void retransmitirParaOutros(String payload, {WebSocket? exceto}) {
    Map<String, dynamic>? dados;
    try {
      final dec = jsonDecode(payload);
      if (dec is Map<String, dynamic>) {
        dados = dec;
      }
    } catch (_) {}

    final tipo = dados?['tipo'] as String?;

    for (final cliente in List<WebSocket>.from(clientesWs)) {
      if (cliente == exceto) continue;

      final terminal = terminaisWs[cliente];

      if (tipo != null && tipo.startsWith('timeline_')) {
        // Não envia eventos sociais para sockets não autenticados/desconhecidos
        final cpfTerminal = (terminal?.cpf ?? '').replaceAll(RegExp(r'\D'), '');
        if (terminal == null ||
            cpfTerminal.isEmpty ||
            terminal.tipoConexao == 'desconhecido') {
          continue;
        }
      }

      final ehCliente = terminal?.tipoConexao == 'cliente';

      if (ehCliente && dados != null) {
        // Clientes externos não devem receber dados de clientes, estoque interno ou caixa
        if (tipo == 'cliente_atualizado' ||
            tipo == 'movimento_estoque' ||
            tipo == 'caixa_atualizado') {
          continue;
        }

        // Se for atualização de loja, cliente recebe apenas a visão pública do cardápio
        if (tipo == 'loja_atualizada') {
          try {
            final lojaMap = dados['loja'] as Map<String, dynamic>?;
            if (lojaMap != null) {
              final lojaObj = Loja.fromJson(lojaMap);
              final payloadSanitizado = jsonEncode({
                ...dados,
                'loja': lojaObj.toVisaoPublica().toJson(),
              });
              cliente.add(payloadSanitizado);
              continue;
            }
          } catch (_) {}
        }

        // Se for pedido adicionado ou atualizado, cliente só recebe se o pedido pertencer a ele
        if (tipo == 'pedido_atualizado' || tipo == 'pedido_adicionado') {
          try {
            final pedMap = dados['pedido'] as Map<String, dynamic>?;
            if (pedMap != null) {
              final pedCpf =
                  pedMap['cpfCliente']?.toString().replaceAll(RegExp(r'\D'), '');
              final pedClienteId = pedMap['clienteId']?.toString();
              final termCpf = terminal?.cpf?.replaceAll(RegExp(r'\D'), '');
              final termId = terminal?.id;

              final ehMeuPedido =
                  (termCpf != null && termCpf.isNotEmpty && termCpf == pedCpf) ||
                      (termId != null &&
                          termId.isNotEmpty &&
                          termId == pedClienteId);

              if (!ehMeuPedido) {
                continue;
              }
            }
          } catch (_) {}
        }
      }

      try {
        cliente.add(payload);
      } catch (_) {}
    }
  }
}

/// Manipulador desacoplado de eventos e mensagens WebSocket recebidas pelos clientes conectados.
class ServidorWsMessageHandler {
  static Future<void> processarMensagem(
    WebSocket ws,
    dynamic msg,
    ServidorWsContext ctx,
  ) async {
    try {
      final dados = await decodificarJsonMapaSeguro(msg as String);
      final tipo = dados['tipo'] as String?;

      if (tipo == 'ping') {
        ws.add(jsonEncode({
          'tipo': 'pong',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }));
        return;
      }

      if (tipo == 'mapa_navegacao_sync' || tipo == 'mapa_posicao_gps') {
        MapaEspelhamentoService.instancia.receberEventoRede(
          dados,
          ctx.authProvider?.cpf,
        );
        ctx.retransmitirParaOutros(msg, exceto: ws);
        return;
      }

      if (tipo == 'avaliacao_produto_salva') {
        final avalMap = dados['avaliacao'];
        if (avalMap is Map<String, dynamic>) {
          await AvaliacoesProdutoService.salvarAvaliacaoRemota(
            AvaliacaoProduto.fromJson(avalMap),
          );
          ctx.retransmitirParaOutros(msg, exceto: ws);
        }
        return;
      }

      if (tipo == 'avaliacao_produto_reacao') {
        final avaliacaoId = dados['avaliacaoId'] as String? ?? '';
        final curtir = dados['curtir'] == true;
        if (avaliacaoId.isNotEmpty) {
          await AvaliacoesProdutoService.aplicarReacaoRemota(
            avaliacaoId: avaliacaoId,
            curtir: curtir,
          );
          ctx.retransmitirParaOutros(msg, exceto: ws);
        }
        return;
      }

      if (tipo == 'solicitar_avaliacoes_sync') {
        final lista = await AvaliacoesProdutoService.exportarTodasParaSync();
        ws.add(jsonEncode({
          'tipo': 'avaliacoes_sync_lote',
          'avaliacoes': lista.map((e) => e.toJson()).toList(),
        }));
        return;
      }

      if (await ServidorWsIdentificacaoUsuariosHelper.tentarProcessar(
        tipo,
        ws,
        dados,
        ctx,
      )) {
        return;
      }

      if (await ServidorWsChatSocialHelper.tentarProcessar(
        tipo,
        ws,
        dados,
        ctx,
      )) {
        return;
      }

      await ServidorWsPdvConvitesHelper.tentarProcessar(
        tipo,
        ws,
        dados,
        ctx,
      );
    } catch (_) {}
  }
}
