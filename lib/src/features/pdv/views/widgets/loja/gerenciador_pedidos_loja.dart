import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/services/som_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/notificacoes/views/widgets/notificacoes_dialog.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/estoque_baixa_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:nous/src/features/pdv/views/dialogs/dialog_conclusao_pedido_tempo.dart';
import 'package:nous/src/features/pdv/views/dialogs/dialog_confirmacao_estorno_pedido.dart';
import 'package:nous/src/features/pdv/views/widgets/cancelar_pedido_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/comanda_novo_pedido_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/gestao_loja_container.dart';
import 'package:nous/src/features/pdv/views/widgets/pedidos_programados_dialog.dart';

/// Controlador desacoplado responsável pela gestão de pedidos, confirmações,
/// cancelamentos, estornos de estoque, timers e notificações de novos pedidos no PDV.
class GerenciadorPedidosLoja {
  final BuildContext Function() obterContext;
  final bool Function() estaMontado;
  final String lojaId;
  final List<PedidoLoja> Function() obterPedidos;
  final List<ItemLoja> Function() obterItens;
  final List<MovimentoEstoque> Function() obterMovimentos;
  final String Function() obterCpfLogado;
  final String Function() obterNomeLogado;
  final int Function() obterTempoConclusaoMinutos;
  final void Function(void Function()) setState;
  final VoidCallback aoPersistir;
  final void Function(TipoAcao tipo, String descricao) registrarAcao;
  final String Function(int numero) formatarNumeroPedido;
  final String Function(double valor) formatarValor;
  final String Function(double qtd) formatarQuantidade;
  final String Function(UnidadeItemLoja u) rotuloUnidadeCurto;
  final void Function(AbaPedidos) definirAbaPedidos;

  Timer? _timerVerificacaoPedidos;
  final Set<String> _pedidosPerguntados = {};
  static final Set<String> _avisosMostradosNaSessao = {};

  GerenciadorPedidosLoja({
    required this.obterContext,
    required this.estaMontado,
    required this.lojaId,
    required this.obterPedidos,
    required this.obterItens,
    required this.obterMovimentos,
    required this.obterCpfLogado,
    required this.obterNomeLogado,
    required this.obterTempoConclusaoMinutos,
    required this.setState,
    required this.aoPersistir,
    required this.registrarAcao,
    required this.formatarNumeroPedido,
    required this.formatarValor,
    required this.formatarQuantidade,
    required this.rotuloUnidadeCurto,
    required this.definirAbaPedidos,
  });

  BuildContext get context => obterContext();

  void iniciarTimerVerificacaoPedidos() {
    _timerVerificacaoPedidos?.cancel();
    _timerVerificacaoPedidos =
        Timer.periodic(const Duration(seconds: 15), (_) {
      verificarPedidosTempoConclusao();
      if (estaMontado()) {
        if (!ClienteRedeLocal().estaConectado.value) {
          context.read<PdvProvider>().verificarEGerarPedidosProgramados(lojaId);
        }
      }
    });
  }

  void cancelarTimer() {
    _timerVerificacaoPedidos?.cancel();
    _timerVerificacaoPedidos = null;
  }

  void verificarPedidosTempoConclusao() {
    if (!estaMontado() || obterTempoConclusaoMinutos() <= 0) return;
    final agora = DateTime.now();
    for (final pedido in obterPedidos()) {
      if (pedido.status == StatusPedido.aceito &&
          !_pedidosPerguntados.contains(pedido.id)) {
        final minutosDecorridos =
            agora.difference(pedido.dataHora).inMinutes;
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
    final pdv = context.read<PdvProvider>();
    final loja = pdv.buscarPorId(lojaId);
    SomService.tocarEvento(SomService.eventoConclusaoPedido, loja: loja);

    final theme = ThemeController.currentTheme.value;

    await DialogConclusaoPedidoTempo.mostrar(
      context,
      theme: theme,
      pedido: pedido,
      tempoConclusaoMinutos: obterTempoConclusaoMinutos(),
      onConcluir: () {
        alterarStatusPedido(
          pedido.id,
          StatusPedido.concluido,
        );
        ScaffoldMessenger.of(context).showSnackBar(
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

  void alterarStatusPedido(String id, StatusPedido novoStatus) {
    final pedidos = obterPedidos();
    final indice = pedidos.indexWhere((p) => p.id == id);
    if (indice == -1) return;
    final pedido = pedidos[indice];
    final pedidoAtualizado = pedido.copyWith(status: novoStatus);

    setState(() {
      pedidos[indice] = pedidoAtualizado;
    });
    aoPersistir();

    if (ClienteRedeLocal().conectado) {
      ClienteRedeLocal().enviarPedido(pedidoAtualizado);
    }
    if (ServidorRedeLocal().ativo) {
      ServidorRedeLocal().notificarTodos({
        'tipo': 'pedido_atualizado',
        'pedido': pedidoAtualizado.toJson(),
      });
    }

    if (novoStatus == StatusPedido.aceito) {
      registrarAcao(
        TipoAcao.pedidoAceito,
        'Pedido ${formatarNumeroPedido(pedido.numero)} aceito '
            '(${formatarValor(pedido.valor)})',
      );
    } else if (novoStatus == StatusPedido.concluido) {
      registrarAcao(
        TipoAcao.pedidoConcluido,
        'Pedido ${formatarNumeroPedido(pedido.numero)} concluído '
            '(${formatarValor(pedido.valor)})',
      );
    }
  }

  void salvarComentarioPedido(String id, DadosComentario dados) {
    final pedidos = obterPedidos();
    final indice = pedidos.indexWhere((p) => p.id == id);
    if (indice == -1) return;
    final pedido = pedidos[indice];
    final pedidoAtualizado = pedido.copyWith(
      comentario: dados.texto,
      comentarioAutorCpf: dados.cpfAutor,
      comentarioAutorNome: dados.nomeAutor,
      comentarioAutorEmail: dados.emailAutor,
      comentarioDataHora: dados.dataHora,
    );

    setState(() {
      pedidos[indice] = pedidoAtualizado;
    });
    aoPersistir();

    if (ClienteRedeLocal().conectado) {
      ClienteRedeLocal().enviarPedido(pedidoAtualizado);
    }
    if (ServidorRedeLocal().ativo) {
      ServidorRedeLocal().notificarTodos({
        'tipo': 'pedido_atualizado',
        'pedido': pedidoAtualizado.toJson(),
      });
    }

    registrarAcao(
      TipoAcao.comentarioSalvo,
      'Comentário salvo no pedido ${formatarNumeroPedido(pedido.numero)}',
    );
  }

  Future<void> cancelarPedidoComDialog(String id) async {
    final pedidos = obterPedidos();
    final itens = obterItens();
    final movimentos = obterMovimentos();

    final indice = pedidos.indexWhere((p) => p.id == id);
    if (indice == -1) return;
    final pedido = pedidos[indice];

    final resultado = await CancelarPedidoDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      pedido: pedido,
    );

    if (resultado == null || !estaMontado()) return;

    final pedidoCancelado = pedido.copyWith(
      status: StatusPedido.cancelado,
      motivoCancelamento: resultado.motivo,
      dataHoraCancelamento: DateTime.now(),
      canceladoPorCpf: obterCpfLogado(),
      canceladoPorNome: obterNomeLogado(),
      estoqueEstornado: resultado.devolverEstoque,
    );

    setState(() {
      pedidos[indice] = pedidoCancelado;

      if (resultado.devolverEstoque) {
        final movimentosEstorno = EstoqueBaixaService.calcularMovimentosEstorno(
          itensVendidos: pedido.itens,
          itensCadastrados: itens,
          motivo:
              'Estorno - Pedido ${formatarNumeroPedido(pedido.numero)} cancelado: ${resultado.motivo}',
          cpfAutor: obterCpfLogado(),
          nomeAutor: obterNomeLogado(),
        );

        for (final mov in movimentosEstorno) {
          movimentos.add(mov);
          if (ClienteRedeLocal().conectado) {
            ClienteRedeLocal().enviarMovimentoEstoque(mov);
          }
          if (ServidorRedeLocal().ativo) {
            ServidorRedeLocal().notificarTodos({
              'tipo': 'estoque_atualizado',
              'movimento': mov.toJson(),
            });
          }
        }
      }
    });

    aoPersistir();

    if (ClienteRedeLocal().conectado) {
      ClienteRedeLocal().enviarPedido(pedidoCancelado);
    }
    if (ServidorRedeLocal().ativo) {
      ServidorRedeLocal().notificarTodos({
        'tipo': 'pedido_atualizado',
        'pedido': pedidoCancelado.toJson(),
      });
    }

    registrarAcao(
      TipoAcao.pedidoCancelado,
      'Pedido ${formatarNumeroPedido(pedido.numero)} cancelado '
          '(${formatarValor(pedido.valor)}). Motivo: ${resultado.motivo}'
          '${resultado.devolverEstoque ? " [Estoque estornado]" : ""}',
    );

    if (resultado.devolverEstoque) {
      for (final item in pedido.itens) {
        registrarAcao(
          TipoAcao.movimentoEstoqueRegistrado,
          'Estorno de estoque: ${formatarQuantidade(item.quantidade.toDouble())} de '
              '"${item.nomeItem}" pelo cancelamento do pedido ${formatarNumeroPedido(pedido.numero)}',
        );
      }
    }
  }

  void recusarPedido(String id) {
    final pedidos = obterPedidos();
    final indice = pedidos.indexWhere((p) => p.id == id);
    if (indice == -1) return;
    final pedido = pedidos[indice];

    setState(() => pedidos.removeAt(indice));
    aoPersistir();

    registrarAcao(
      TipoAcao.pedidoRecusado,
      'Pedido ${formatarNumeroPedido(pedido.numero)} recusado '
          '(${formatarValor(pedido.valor)})',
    );
  }

  Future<void> excluirPedido(String id) async {
    final pedidos = obterPedidos();
    final itens = obterItens();
    final movimentos = obterMovimentos();

    final indice = pedidos.indexWhere((p) => p.id == id);
    if (indice == -1) return;
    final pedido = pedidos[indice];

    bool devolverEstoque = false;
    final podeEstornar = pedido.itens.isNotEmpty && !pedido.estoqueEstornado;

    if (podeEstornar) {
      devolverEstoque = await DialogConfirmacaoEstornoPedido.mostrar(
        context,
        theme: ThemeController.currentTheme.value,
        pedido: pedido,
      );
    }

    if (!estaMontado()) return;

    setState(() {
      pedidos.removeWhere((p) => p.id == id);
      if (devolverEstoque) {
        final movimentosEstorno = EstoqueBaixaService.calcularMovimentosEstorno(
          itensVendidos: pedido.itens,
          itensCadastrados: itens,
          motivo:
              'Estorno por exclusão do Pedido ${formatarNumeroPedido(pedido.numero)}',
          cpfAutor: obterCpfLogado(),
          nomeAutor: obterNomeLogado(),
        );
        movimentos.addAll(movimentosEstorno);
      }
    });
    aoPersistir();

    registrarAcao(
      TipoAcao.pedidoExcluido,
      'Pedido ${formatarNumeroPedido(pedido.numero)} excluído '
          '(${formatarValor(pedido.valor)})'
          '${devolverEstoque ? " [Estoque estornado]" : ""}',
    );

    if (devolverEstoque) {
      for (final item in pedido.itens) {
        registrarAcao(
          TipoAcao.movimentoEstoqueRegistrado,
          'Estorno de estoque: ${formatarQuantidade(item.quantidade.toDouble())} de '
              '"${item.nomeItem}" pela exclusão do pedido ${formatarNumeroPedido(pedido.numero)}',
        );
      }
    }
  }

  void processarConclusaoVenda(
    PedidoLoja pedido,
    List<MovimentoEstoque> movimentosEstoque,
  ) {
    final pedidos = obterPedidos();
    final movimentos = obterMovimentos();
    final itens = obterItens();

    setState(() {
      pedidos.add(pedido);
      definirAbaPedidos(AbaPedidos.aceitos);
      for (final m in movimentosEstoque) {
        movimentos.add(m);
      }
    });
    aoPersistir();

    if (ClienteRedeLocal().conectado) {
      ClienteRedeLocal().enviarPedido(pedido);
      for (final m in movimentosEstoque) {
        ClienteRedeLocal().enviarMovimentoEstoque(m);
      }
    }
    if (ServidorRedeLocal().ativo) {
      ServidorRedeLocal().notificarTodos({
        'tipo': 'pedido_adicionado',
        'pedido': pedido.toJson(),
      });
      for (final m in movimentosEstoque) {
        ServidorRedeLocal().notificarTodos({
          'tipo': 'estoque_atualizado',
          'movimento': m.toJson(),
        });
      }
    }

    registrarAcao(
      TipoAcao.novaVenda,
      'Nova venda ${formatarNumeroPedido(pedido.numero)} para '
          '"${pedido.clienteNome}" (${formatarValor(pedido.valor)})',
    );

    for (final movimento in movimentosEstoque) {
      final item = itens.firstWhere(
        (i) => i.id == movimento.itemId,
        orElse: () => const ItemLoja(id: '', nome: ''),
      );
      final quantidade = formatarQuantidade(movimento.quantidade);
      final unidade = rotuloUnidadeCurto(item.unidadeBase);
      registrarAcao(
        TipoAcao.movimentoEstoqueRegistrado,
        'Baixa automática de $quantidade $unidade de '
            '"${item.nome}" pelo pedido ${formatarNumeroPedido(pedido.numero)}',
      );
    }
  }

  Future<void> verificarAvisosIniciais() async {
    if (!estaMontado()) return;
    if (_avisosMostradosNaSessao.contains(lojaId)) return;
    _avisosMostradosNaSessao.add(lojaId);

    final ctx = context;
    if (!ctx.mounted) return;
    final pdv = ctx.read<PdvProvider>();
    if (!ClienteRedeLocal().estaConectado.value) {
      await pdv.verificarEGerarPedidosProgramados(lojaId);
    }
    if (!estaMontado() || !ctx.mounted) return;

    final notificacoes = ctx.read<NotificacoesProvider>();
    final quantidadeConvites = notificacoes.quantidadeConvitesAtivos;
    final totalEstoqueBaixo = pdv.itensEstoqueBaixoPorLoja(lojaId)
        .where((a) => !notificacoes
            .estaDispensadaNaSessao('alerta_estoque_${a.lojaId}_${a.item.id}'))
        .length;
    final temNotificacoes = (quantidadeConvites + totalEstoqueBaixo) > 0;

    if (temNotificacoes) {
      await NotificacoesDialog.mostrar(ctx, lojaId: lojaId);
    }

    if (!estaMontado() || !ctx.mounted) return;

    final lojaAtualAvisos = pdv.buscarPorId(lojaId);
    final agora = DateTime.now();
    final diaStr = agora.day.toString().padLeft(2, '0');
    final mesStr = agora.month.toString().padLeft(2, '0');

    final pedidosHoje = pdv.pedidosProgramadosDoDia(lojaId).where((prog) {
      if (lojaAtualAvisos == null) return true;
      final idEsperadoHoje = 'prog_${prog.id}_${agora.year}_${mesStr}_$diaStr';
      final pedidoExistente = lojaAtualAvisos.pedidosLoja.where((p) {
        if (p.id == idEsperadoHoje) return true;
        if (p.id.startsWith('prog_${prog.id}_') &&
            p.dataHora.year == agora.year &&
            p.dataHora.month == agora.month &&
            p.dataHora.day == agora.day) {
          return true;
        }
        return false;
      }).firstOrNull;

      if (pedidoExistente != null && pedidoExistente.status != StatusPedido.novo) {
        return false;
      }
      return true;
    }).toList();

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

  Future<void> processarFilaNovosPedidos() async {
    if (!estaMontado()) return;
    final ctx = context;
    if (!ctx.mounted) return;
    final pdv = ctx.read<PdvProvider>();

    while (estaMontado() && ctx.mounted) {
      final lojaAtual = pdv.buscarPorId(lojaId);
      if (lojaAtual == null) break;

      final novosPedidos = lojaAtual.pedidosLoja
          .where((p) => p.status == StatusPedido.novo)
          .toList();
      if (novosPedidos.isEmpty) break;

      SomService.tocarEvento(SomService.eventoNovoPedido, loja: lojaAtual);

      final pedidoAtual = novosPedidos.first;
      final cliente = lojaAtual.clientesLoja
          .where((c) => c.id == pedidoAtual.clienteId)
          .firstOrNull;

      final acao = await ComandaNovoPedidoDialog.mostrar(
        ctx,
        lojaId: lojaId,
        pedido: pedidoAtual,
        cliente: cliente,
        totalRestantes: novosPedidos.length,
      );

      if (!estaMontado() || !ctx.mounted) break;

      if (acao == AcaoComandaNovoPedido.aceitar) {
        alterarStatusPedido(pedidoAtual.id, StatusPedido.aceito);
      } else if (acao == AcaoComandaNovoPedido.recusar) {
        recusarPedido(pedidoAtual.id);
      } else {
        break;
      }
    }
  }
}
