import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nous/src/core/services/preferencias_soberanas_service.dart';
import 'package:nous/src/core/services/relogio_rede_service.dart';
import 'package:nous/src/features/busca/services/avaliacoes_produto_service.dart';
import 'package:nous/src/features/busca/services/mapa_espelhamento_service.dart';
import 'package:nous/src/features/busca/services/projetos_comunitarios_service.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/notificacoes/services/convites_service.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/referencia_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';

/// Orquestrador de tarefas assíncronas executadas logo após a conexão do cliente ao balcão.
class ClientePosConexaoOrquestrador {
  /// Vincula a loja sincronizada aos perfis locais do usuário se ele for membro ou dono
  static Future<void> vincularLojaSeNecessario({
    required Loja loja,
    required String? cpfLogado,
    required PdvProvider? pdvProvider,
  }) async {
    if (LojasService.ehLojaHostFalsa(loja.id, loja.tags, loja.nome)) return;
    if (cpfLogado != null && cpfLogado.isNotEmpty && pdvProvider != null) {
      final cpfLimpo = cpfLogado.replaceAll(RegExp(r'\D'), '');
      final ehDono =
          loja.cpfDonoOriginal.replaceAll(RegExp(r'\D'), '') == cpfLimpo;
      final ehMembro = loja.membros.any(
        (m) => m.cpf.replaceAll(RegExp(r'\D'), '') == cpfLimpo,
      );

      if (ehDono) {
        await LojasService.removerReferencia(cpfLogado, loja.id);
        return;
      }

      if (!ehMembro) {
        final refs = await LojasService.carregarReferencias(cpfLogado);
        if (refs.any((r) => r.lojaId == loja.id)) {
          await LojasService.removerReferencia(cpfLogado, loja.id);
          await pdvProvider.entrarComCpf(cpfLogado);
          debugPrint(
            '[ClientePosConexaoOrquestrador] Usuário $cpfLimpo não é mais membro da loja "${loja.nome}". Referência removida.',
          );
        }
        return;
      }

      await LojasService.salvarLojaIndividual(loja);

      final refs = await LojasService.carregarReferencias(cpfLogado);
      final jaTem = refs.any((r) => r.lojaId == loja.id);
      if (!jaTem) {
        await LojasService.adicionarReferencia(
          cpfLogado,
          ReferenciaLoja(
            lojaId: loja.id,
            cpfDonoOriginal: loja.cpfDonoOriginal,
          ),
        );
        await pdvProvider.entrarComCpf(cpfLogado);
      }
    }
  }

  /// Executa a rotina resiliente pós-conexão
  static Future<void> executar({
    required String ipServidor,
    required int portaServidor,
    required String cpfLogado,
    required Loja? lojaBrutaParaReconciliar,
    required List<String> imagensAusentesParaReconciliar,
    required List<String> fotosUsuariosAusentesParaReconciliar,
    required PdvProvider? pdvProvider,
    required Future<Loja> Function(Loja, List<String>) reconciliarLojaMutua,
    required void Function(Loja) onLojaSincronizada,
    required void Function(List<String>) curarFotosUsuariosAusentesNoServidor,
    required Future<void> Function() verificarAtualizacaoLocal,
    required Future<void> Function() sincronizarIdentidadeUsuario,
    required Future<void> Function() reconciliarContasComServidor,
    required Future<void> Function() sincronizarPerfisLojasComServidor,
    required String? idLojaSincronizada,
  }) async {
    try {
      unawaited(verificarAtualizacaoLocal());

      // Executa sincronizações independentes em paralelo para reduzir latência de conexão
      await Future.wait([
        RelogioRedeService.instancia.sincronizarComServidor(
          ip: ipServidor,
          porta: portaServidor,
        ),
        if (lojaBrutaParaReconciliar != null)
          () async {
            try {
              final lojaReconciliada = await reconciliarLojaMutua(
                lojaBrutaParaReconciliar,
                imagensAusentesParaReconciliar,
              );
              onLojaSincronizada(lojaReconciliada);
              await pdvProvider?.adicionarOuAtualizarLoja(lojaReconciliada);
              if (fotosUsuariosAusentesParaReconciliar.isNotEmpty) {
                curarFotosUsuariosAusentesNoServidor(
                  fotosUsuariosAusentesParaReconciliar,
                );
              }
            } catch (e) {
              debugPrint('[ClientePosConexaoOrquestrador] Reconciliação mútua assíncrona de mídia: $e');
            }
          }(),
        () async {
          await sincronizarIdentidadeUsuario();
          await reconciliarContasComServidor();
        }(),
        sincronizarPerfisLojasComServidor(),
        ChatService.sincronizarMensagensComBalcao(
          ipServidor: ipServidor,
          portaServidor: portaServidor,
          cpfUsuario: cpfLogado,
          lojaId: idLojaSincronizada,
        ),
        if (idLojaSincronizada != PdvProvider.idLojaColetivaNous)
          ChatService.sincronizarMensagensComBalcao(
            ipServidor: ipServidor,
            portaServidor: portaServidor,
            lojaId: PdvProvider.idLojaColetivaNous,
          ),
        TimelineService.sincronizarComServidorHttp(
          ip: ipServidor,
          porta: portaServidor,
        ),
      ]);
      await ChatService.drenarFilaDeSaida();
      await ConvitesService.drenarPendenciasOffline();
      await NotificacoesProvider.instanciaAtiva?.drenarDispensasOffline();
      ClienteRedeLocal().enviarEventoWs({'tipo': 'solicitar_avaliacoes_sync'});
      final avalLocais = await AvaliacoesProdutoService.exportarTodasParaSync();
      if (avalLocais.isNotEmpty) {
        ClienteRedeLocal().enviarEventoWs({
          'tipo': 'avaliacoes_sync_enviar',
          'avaliacoes': avalLocais.map((e) => e.toJson()).toList(),
        });
      }
      ClienteRedeLocal().enviarEventoWs({'tipo': 'solicitar_projetos_sync'});
      final projLocais = await ProjetosComunitariosService.listarTodos();
      if (projLocais.isNotEmpty) {
        ClienteRedeLocal().enviarEventoWs({
          'tipo': 'projetos_sync_enviar',
          'projetos': projLocais.map((e) => e.toJson()).toList(),
        });
      }
      if (cpfLogado.isNotEmpty) {
        final prefsCpf = await PreferenciasSoberanasService.exportarDoCpf(cpfLogado);
        if (prefsCpf.isNotEmpty) {
          ClienteRedeLocal().enviarEventoWs({
            'tipo': 'preferencias_cpf_sync',
            'cpf': cpfLogado,
            'itens': prefsCpf,
          });
        }
      }
      unawaited(MapaEspelhamentoService.instancia.enviarPosicaoAtualSeMobile(cpfLogado));
      unawaited(
        Future.delayed(
          const Duration(seconds: 3),
          () => verificarAtualizacaoLocal(),
        ),
      );
    } catch (e) {
      debugPrint('[ClientePosConexaoOrquestrador] Erro na sincronização pós-conexão: $e');
    }
  }
}
