import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/terminal_conectado_info.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

/// Gerencia o upgrade HTTP -> WebSocket e a recepção inicial do terminal na rede local
class ServidorWsUpgradeHandler {
  ServidorWsUpgradeHandler._();

  static Future<void> processarUpgrade({
    required HttpRequest request,
    required String? ipServidor,
    required List<WebSocket> clientesWs,
    required Map<WebSocket, TerminalConectadoInfo> terminaisWs,
    required Loja? Function() obterLojaAtiva,
    required PdvProvider? pdvProvider,
    required List<TerminalConectadoInfo> Function() obterTodasPresencas,
    required VoidCallback atualizarListasTerminais,
    required VoidCallback notificarPresencas,
    required void Function(WebSocket ws, dynamic msg) onMensagem,
  }) async {
    try {
      final ipRemoto = request.connectionInfo?.remoteAddress.address ?? '127.0.0.1';
      final ehLoopback = request.connectionInfo?.remoteAddress.isLoopback ?? false;
      final ehIpLocal = ipRemoto == '127.0.0.1' ||
          ipRemoto == '::1' ||
          (ipServidor != null && ipRemoto == ipServidor);

      if (ehLoopback || ehIpLocal) {
        debugPrint(
          '[ServidorWsUpgradeHandler] Rejeitando conexão WebSocket loopback da própria máquina ($ipRemoto).',
        );
        request.response.statusCode = HttpStatus.badRequest;
        await request.response.close();
        return;
      }

      final ws = await WebSocketTransformer.upgrade(request);

      // Encerra imediatamente qualquer conexão órfã/zumbi anterior do mesmo IP
      final conexoesAntigas = terminaisWs.entries
          .where((entry) => entry.value.ip == ipRemoto)
          .map((entry) => entry.key)
          .toList();
      for (final wsAntigo in conexoesAntigas) {
        debugPrint(
          '[ServidorWsUpgradeHandler] Encerrando socket zumbi anterior do IP: $ipRemoto',
        );
        clientesWs.remove(wsAntigo);
        terminaisWs.remove(wsAntigo);
        try {
          wsAntigo.close();
        } catch (_) {}
      }

      final terminal = TerminalConectadoInfo(
        id: 'term_${DateTime.now().millisecondsSinceEpoch}',
        nome: 'Terminal ($ipRemoto)',
        ip: ipRemoto,
        conectadoEm: DateTime.now(),
      );

      clientesWs.add(ws);
      terminaisWs[ws] = terminal;
      atualizarListasTerminais();

      debugPrint(
        '[ServidorWsUpgradeHandler] Novo terminal conectado: $ipRemoto. Total: ${clientesWs.length}',
      );

      // Envia dados iniciais da loja e lista de presenças ativas
      final lojaParaEnvio = obterLojaAtiva();
      if (lojaParaEnvio != null) {
        final fotosUsuariosAusentes = <String>[];
        for (final m in lojaParaEnvio.membros) {
          final cpfLimpo = m.cpf.replaceAll(RegExp(r'\D'), '');
          if (cpfLimpo.isNotEmpty) {
            final contaMembro =
                await ContasNousService.buscarPorCpf(cpfLimpo);
            final temFotoFisica = contaMembro != null &&
                contaMembro.foto.trim().isNotEmpty &&
                ImagemService.resolverCaminhoExistente(contaMembro.foto) !=
                    null;
            if (!temFotoFisica) {
              fotosUsuariosAusentes.add(cpfLimpo);
            }
          }
        }

        final lojaNous =
            pdvProvider?.buscarPorId(PdvProvider.idLojaColetivaNous);
        final dispensadasLoja = NotificacoesProvider.instanciaAtiva
                ?.obterDispensadasPorLoja(lojaParaEnvio.id)
                .toList() ??
            <String>[];

        ws.add(
          jsonEncode({
            'tipo': 'dados_iniciais',
            'loja': lojaParaEnvio.toJson(),
            if (lojaNous != null) 'lojaNousColetiva': lojaNous.toJson(),
            'presencas':
                obterTodasPresencas().map((p) => p.toJson()).toList(),
            'fotosUsuariosAusentes': fotosUsuariosAusentes,
            'notificacoesDispensadasLoja': dispensadasLoja,
          }),
        );
      } else {
        final lojaNous =
            pdvProvider?.buscarPorId(PdvProvider.idLojaColetivaNous);
        ws.add(
          jsonEncode({
            'tipo': 'dados_iniciais',
            'loja': null,
            if (lojaNous != null) 'lojaNousColetiva': lojaNous.toJson(),
            'presencas':
                obterTodasPresencas().map((p) => p.toJson()).toList(),
            'fotosUsuariosAusentes': <String>[],
          }),
        );
      }

      ws.listen(
        (msg) => onMensagem(ws, msg),
        onDone: () {
          debugPrint(
            '[ServidorWsUpgradeHandler] Conexão WebSocket onDone para terminal: ${terminal.ip} (${terminal.nome})',
          );
          clientesWs.remove(ws);
          terminaisWs.remove(ws);
          atualizarListasTerminais();
          notificarPresencas();
        },
        onError: (err) {
          debugPrint(
            '[ServidorWsUpgradeHandler] Conexão WebSocket onError para terminal: ${terminal.ip} ($err)',
          );
          clientesWs.remove(ws);
          terminaisWs.remove(ws);
          atualizarListasTerminais();
          notificarPresencas();
        },
      );
    } catch (e) {
      debugPrint('[ServidorWsUpgradeHandler] Erro no upgrade WebSocket: $e');
    }
  }
}
