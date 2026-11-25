import 'package:flutter/foundation.dart';
import 'package:nous/src/core/utils/json_isolate_utils.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/busca/services/mapa_espelhamento_service.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/terminal_conectado_info.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/rede_local/handlers/helpers/cliente_ws_chamada_webrtc_helper.dart';
import 'package:nous/src/features/pdv/services/rede_local/handlers/helpers/cliente_ws_chat_social_helper.dart';
import 'package:nous/src/features/pdv/services/rede_local/handlers/helpers/cliente_ws_loja_sync_helper.dart';
import 'package:nous/src/features/pdv/services/rede_local/handlers/helpers/cliente_ws_usuarios_convites_helper.dart';

/// Contexto de execução para processamento de mensagens WebSocket no Cliente de Rede Local.
class ClienteWsContext {
  final PdvProvider? pdvProvider;
  final AuthProvider? authProvider;
  final ValueNotifier<List<TerminalConectadoInfo>> presencasAtivas;
  final Loja? Function() obterLojaSincronizada;
  final void Function(Loja) definirLojaSincronizada;
  final void Function(bool) definirAplicandoAtualizacaoRemota;
  final Future<Loja> Function(Loja) sincronizarImagensRemotas;
  final Future<void> Function(Loja) vincularLojaSeNecessario;
  final Future<void> Function(Loja) enviarLojaCuradaParaServidor;
  final void Function(List<String>) curarFotosUsuariosAusentesNoServidor;
  final Future<void> Function() sincronizarPerfisLojasComServidor;
  final void Function(Map<String, dynamic>) processarSinalChamada;
  final Future<String> Function(String) baixarImagemRemota;
  final Future<List<PedidoLoja>> Function(String lojaId, List<String> ids)
      reconciliarPedidosNoServidor;

  const ClienteWsContext({
    required this.pdvProvider,
    required this.authProvider,
    required this.presencasAtivas,
    required this.obterLojaSincronizada,
    required this.definirLojaSincronizada,
    required this.definirAplicandoAtualizacaoRemota,
    required this.sincronizarImagensRemotas,
    required this.vincularLojaSeNecessario,
    required this.enviarLojaCuradaParaServidor,
    required this.curarFotosUsuariosAusentesNoServidor,
    required this.sincronizarPerfisLojasComServidor,
    required this.processarSinalChamada,
    required this.baixarImagemRemota,
    required this.reconciliarPedidosNoServidor,
  });
}

/// Manipulador desacoplado de eventos e mensagens WebSocket recebidas pelo servidor balcão.
class ClienteWsMessageHandler {
  static Future<void> processarMensagem(dynamic msg, ClienteWsContext ctx) async {
    try {
      final dados = await decodificarJsonMapaSeguro(msg as String);
      final tipo = dados['tipo'] as String?;

      if (tipo == 'pong') {
        return;
      }

      if (tipo == 'mapa_navegacao_sync' || tipo == 'mapa_posicao_gps') {
        MapaEspelhamentoService.instancia.receberEventoRede(
          dados,
          ctx.authProvider?.cpf,
        );
        return;
      }

      if (tipo == 'presencas_atualizadas') {
        final lista = dados['presencas'] as List<dynamic>? ?? [];
        ctx.presencasAtivas.value = lista
            .map((e) => TerminalConectadoInfo.fromJson(e as Map<String, dynamic>))
            .toList();
        return;
      }

      if (tipo == 'loja_excluida') {
        final lojaId = dados['lojaId'] as String?;
        if (lojaId != null && ctx.pdvProvider != null) {
          await ctx.pdvProvider!.excluirLoja(lojaId, originadaDaRede: true);
        }
        return;
      }

      if (await ClienteWsLojaSyncHelper.tentarProcessar(tipo, dados, ctx)) {
        return;
      }

      if (await ClienteWsUsuariosConvitesHelper.tentarProcessar(tipo, dados, ctx)) {
        return;
      }

      if (await ClienteWsChatSocialHelper.tentarProcessar(tipo, dados, ctx)) {
        return;
      }

      if (tipo != null && tipo.startsWith('chamada_')) {
        ctx.processarSinalChamada(dados);
        return;
      }
    } catch (e) {
      debugPrint('[ClienteRedeLocal] Erro ao processar mensagem WebSocket: $e');
    }
  }

  /// Processa e roteia pacotes WebRTC de áudio e vídeo recebidos via WebSocket
  static void processarSinalChamada({
    required Map<String, dynamic> dados,
    required String meuCpf,
    required List<Loja>? lojasLocal,
  }) {
    ClienteWsChamadaWebRtcHelper.processarSinalChamada(
      dados: dados,
      meuCpf: meuCpf,
      lojasLocal: lojasLocal,
    );
  }
}
