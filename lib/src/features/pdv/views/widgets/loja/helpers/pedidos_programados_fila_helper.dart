import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/services/som_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/notificacoes/views/widgets/notificacoes_dialog.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_programado.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/impressao_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/helpers/gerenciador_dispositivo_local.dart';
import 'package:nous/src/features/pdv/views/dialogs/dialog_conclusao_pedido_tempo.dart';
import 'package:nous/src/features/pdv/views/widgets/comanda_novo_pedido_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/pedidos_programados_dialog.dart';

/// Helper responsável pela verificação de tempo de conclusão, avisos iniciais,
/// filtragem de pedidos programados e processamento da fila de novos pedidos.
class PedidosProgramadosFilaHelper {
  final BuildContext Function() obterContext;
  final bool Function() estaMontado;
  final String lojaId;
  final List<PedidoLoja> Function() obterPedidos;
  final int Function() obterTempoConclusaoMinutos;
  final VoidCallback aoSincronizarComPdv;
  final void Function(String id, StatusPedido novoStatus) aoAlterarStatusPedido;
  final void Function(String id, {String motivo}) aoCancelarPedidoSilencioso;
  final void Function(String id) aoRecusarPedido;
  final String Function(int numero) formatarNumeroPedido;

  final Set<String> _pedidosPerguntados;
  final Set<String> _avisosMostradosNaSessao;
  bool _processandoFilaNovosPedidos = false;

  PedidosProgramadosFilaHelper({
    required this.obterContext,
    required this.estaMontado,
    required this.lojaId,
    required this.obterPedidos,
    required this.obterTempoConclusaoMinutos,
    required this.aoSincronizarComPdv,
    required this.aoAlterarStatusPedido,
    required this.aoCancelarPedidoSilencioso,
    required this.aoRecusarPedido,
    required this.formatarNumeroPedido,
    required Set<String> pedidosPerguntados,
    required Set<String> avisosMostradosNaSessao,
  })  : _pedidosPerguntados = pedidosPerguntados,
        _avisosMostradosNaSessao = avisosMostradosNaSessao;

  bool _mesmoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void verificarPedidosTempoConclusao() {
    if (!estaMontado() || obterTempoConclusaoMinutos() <= 0) return;
    final agora = DateTime.now();
    for (final pedido in obterPedidos()) {
      if (pedido.status == StatusPedido.aceito &&
          !_pedidosPerguntados.contains(pedido.id)) {
        final minutosDecorridos = agora.difference(pedido.dataHora).inMinutes;
        if (minutosDecorridos >= obterTempoConclusaoMinutos()) {
          _pedidosPerguntados.add(pedido.id);
          perguntarConclusaoPedido(pedido);
          break;
        }
      }
    }
  }

  Future<void> perguntarConclusaoPedido(PedidoLoja pedido) async {
    if (!estaMontado()) return;
    final ctx = obterContext();
    final pdv = ctx.read<PdvProvider>();
    final loja = pdv.buscarPorId(lojaId);
    SomService.tocarEvento(SomService.eventoConclusaoPedido, loja: loja);

    final theme = ThemeController.currentTheme.value;

    await DialogConclusaoPedidoTempo.mostrar(
      ctx,
      theme: theme,
      pedido: pedido,
      tempoConclusaoMinutos: obterTempoConclusaoMinutos(),
      onConcluir: () {
        aoAlterarStatusPedido(pedido.id, StatusPedido.concluido);
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            backgroundColor: theme.cardBackgroundColor,
            content: Text(
              'Pedido ${formatarNumeroPedido(pedido.numero)} marcado como concluído!',
              style: theme.getTextStyle(
                color: theme.textColor,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> verificarAvisosIniciais() async {
    if (!estaMontado()) return;
    if (_avisosMostradosNaSessao.contains(lojaId)) return;
    _avisosMostradosNaSessao.add(lojaId);

    final ctx = obterContext();
    if (!ctx.mounted) return;

    // Se houver um balcão/servidor conhecido na rede, aguarda brevemente a
    // reconexão e sincronização inicial antes de abrir avisos de agendamentos.
    if (!ClienteRedeLocal().estaConectado.value) {
      final ultimoBalcao = await GerenciadorDispositivoLocal.obterUltimoBalcao();
      if (ultimoBalcao.ip != null && ultimoBalcao.ip!.isNotEmpty) {
        for (var i = 0; i < 10; i++) {
          if (!estaMontado() || !ctx.mounted) return;
          if (ClienteRedeLocal().estaConectado.value) {
            await Future<void>.delayed(const Duration(milliseconds: 350));
            break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }
      }
    }
    if (!estaMontado() || !ctx.mounted) return;

    final pdv = ctx.read<PdvProvider>();
    if (!ClienteRedeLocal().estaConectado.value) {
      await pdv.verificarEGerarPedidosProgramados(lojaId);
      aoSincronizarComPdv();
    }
    if (!estaMontado() || !ctx.mounted) return;

    final notificacoes = ctx.read<NotificacoesProvider>();
    await notificacoes.carregarDispensadasLoja(lojaId);
    if (!estaMontado() || !ctx.mounted) return;

    final totalEstoqueBaixo = pdv
        .itensEstoqueBaixoPorLoja(lojaId)
        .where(
          (a) => !notificacoes.estaDispensadaNaLoja(
            lojaId,
            'alerta_estoque_${a.lojaId}_${a.item.id}',
          ),
        )
        .length;
    final msgsLoja = (await ChatService.obterMensagensNaoLidasDaLoja(lojaId))
        .where((m) => !notificacoes.estaDispensadaNaLoja(lojaId, 'msg_${m.id}'))
        .toList();
    if (!estaMontado() || !ctx.mounted) return;

    if ((totalEstoqueBaixo + msgsLoja.length) > 0) {
      await NotificacoesDialog.mostrar(ctx, lojaId: lojaId);
    }

    if (!estaMontado() || !ctx.mounted) return;

    final pedidosHoje = _filtrarPedidosProgramadosPendentesHoje(pdv);
    if (pedidosHoje.isNotEmpty) {
      await PedidosProgramadosDialog.mostrar(
        ctx,
        lojaId: lojaId,
        pedidos: pedidosHoje,
      );
    }

    if (!estaMontado() || !ctx.mounted) return;

    await processarFilaNovosPedidos();
  }

  List<PedidoProgramado> _filtrarPedidosProgramadosPendentesHoje(
    PdvProvider pdv,
  ) {
    final lojaAtualAvisos = pdv.buscarPorId(lojaId);
    final agora = DateTime.now();
    final diaStr = agora.day.toString().padLeft(2, '0');
    final mesStr = agora.month.toString().padLeft(2, '0');

    return pdv.pedidosProgramadosDoDia(lojaId).where((prog) {
      if (lojaAtualAvisos == null) return true;
      final jaGeradoHoje = prog.ultimaDataGerado != null &&
          _mesmoDia(prog.ultimaDataGerado!, agora);
      if (jaGeradoHoje) return false;

      final idEsperadoHoje = 'prog_${prog.id}_${agora.year}_${mesStr}_$diaStr';
      final pedidoExistente = lojaAtualAvisos.pedidosLoja.where((p) {
        if (p.id == idEsperadoHoje) return true;
        if (p.id.startsWith('prog_${prog.id}_') &&
            _mesmoDia(p.dataHora, agora)) {
          return true;
        }
        if (prog.clienteId.isNotEmpty &&
            p.clienteId == prog.clienteId &&
            _mesmoDia(p.dataHora, agora) &&
            p.status != StatusPedido.cancelado) {
          return true;
        }
        return false;
      }).firstOrNull;

      if (pedidoExistente != null && pedidoExistente.status != StatusPedido.novo) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> processarFilaNovosPedidos() async {
    if (!estaMontado() || _processandoFilaNovosPedidos) return;
    final ctx = obterContext();
    if (!ctx.mounted) return;
    final pdv = ctx.read<PdvProvider>();
    _processandoFilaNovosPedidos = true;

    try {
      while (estaMontado() && ctx.mounted) {
        final lojaAtual = pdv.buscarPorId(lojaId);
        if (lojaAtual == null) break;

        final agora = DateTime.now();

        // Auto-expurgo preventivo: pedidos 'novos' de dias passados são marcados como cancelados
        final pedidosExpirados = lojaAtual.pedidosLoja
            .where((p) =>
                p.status == StatusPedido.novo && !_mesmoDia(p.dataHora, agora))
            .toList();
        if (pedidosExpirados.isNotEmpty) {
          for (final exp in pedidosExpirados) {
            aoCancelarPedidoSilencioso(
              exp.id,
              motivo: 'Expirado por decurso de prazo',
            );
          }
          continue;
        }

        final novosPedidos = lojaAtual.pedidosLoja
            .where((p) =>
                p.status == StatusPedido.novo && _mesmoDia(p.dataHora, agora))
            .toList();
        if (novosPedidos.isEmpty) break;

        SomService.tocarEvento(SomService.eventoNovoPedido, loja: lojaAtual);

        final pedidoAtual = novosPedidos.first;
        var cliente = lojaAtual.clientesLoja
            .where((c) =>
                (pedidoAtual.clienteId != null &&
                    pedidoAtual.clienteId!.isNotEmpty &&
                    c.id == pedidoAtual.clienteId) ||
                (pedidoAtual.clienteNome.trim().isNotEmpty &&
                    c.nome.trim().toLowerCase() ==
                        pedidoAtual.clienteNome.trim().toLowerCase()))
            .firstOrNull;

        if (pedidoAtual.id.startsWith('prog_')) {
          final prog = lojaAtual.pedidosProgramados
              .where((p) => pedidoAtual.id.startsWith('prog_${p.id}_'))
              .firstOrNull;
          if (prog != null) {
            cliente = prog.resolverCliente(lojaAtual.clientesLoja);
          }
        }

        final acao = await ComandaNovoPedidoDialog.mostrar(
          ctx,
          lojaId: lojaId,
          pedido: pedidoAtual,
          cliente: cliente,
          totalRestantes: novosPedidos.length,
        );

        if (!estaMontado() || !ctx.mounted) break;

        if (acao == AcaoComandaNovoPedido.aceitar) {
          aoAlterarStatusPedido(pedidoAtual.id, StatusPedido.aceito);
          if (lojaAtual.configuracoesImpressora.imprimirAutomaticoAoConcluir) {
            unawaited(
              ImpressaoService.imprimirComanda(
                config: lojaAtual.configuracoesImpressora,
                pedido: pedidoAtual.copyWith(status: StatusPedido.aceito),
                cliente: cliente,
              ),
            );
          }
        } else if (acao == AcaoComandaNovoPedido.recusar) {
          aoRecusarPedido(pedidoAtual.id);
        } else {
          break;
        }
      }
    } finally {
      _processandoFilaNovosPedidos = false;
    }
  }
}
