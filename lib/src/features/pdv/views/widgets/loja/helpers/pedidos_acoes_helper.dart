import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/estoque_baixa_service.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:nous/src/features/pdv/views/dialogs/dialog_confirmacao_estorno_pedido.dart';
import 'package:nous/src/features/pdv/views/widgets/cancelar_pedido_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/gestao_loja_container.dart';

/// Helper responsável pelas ações de ciclo de vida dos pedidos (aceite,
/// conclusão, comentário, recusa, cancelamento, exclusão, venda e rede local).
class PedidosAcoesHelper {
  final BuildContext Function() obterContext;
  final bool Function() estaMontado;
  final String lojaId;
  final List<PedidoLoja> Function() obterPedidos;
  final List<ItemLoja> Function() obterItens;
  final List<MovimentoEstoque> Function() obterMovimentos;
  final String Function() obterCpfLogado;
  final String Function() obterNomeLogado;
  final void Function(void Function()) setState;
  final VoidCallback aoPersistir;
  final VoidCallback aoSincronizarComPdv;
  final void Function(TipoAcao tipo, String descricao) registrarAcao;
  final String Function(int numero) formatarNumeroPedido;
  final String Function(double valor) formatarValor;
  final String Function(double qtd) formatarQuantidade;
  final String Function(UnidadeItemLoja u) rotuloUnidadeCurto;
  final void Function(AbaPedidos) definirAbaPedidos;

  const PedidosAcoesHelper({
    required this.obterContext,
    required this.estaMontado,
    required this.lojaId,
    required this.obterPedidos,
    required this.obterItens,
    required this.obterMovimentos,
    required this.obterCpfLogado,
    required this.obterNomeLogado,
    required this.setState,
    required this.aoPersistir,
    required this.aoSincronizarComPdv,
    required this.registrarAcao,
    required this.formatarNumeroPedido,
    required this.formatarValor,
    required this.formatarQuantidade,
    required this.rotuloUnidadeCurto,
    required this.definirAbaPedidos,
  });

  int _encontrarIndicePedido(List<PedidoLoja> pedidos, String id) {
    var indice = pedidos.indexWhere((p) => p.id == id);
    if (indice == -1 && estaMontado()) {
      aoSincronizarComPdv();
      indice = pedidos.indexWhere((p) => p.id == id);
    }
    return indice;
  }

  void _despacharPedidoRede(
    PedidoLoja pedido, {
    String tipoEvento = 'pedido_atualizado',
  }) {
    if (ClienteRedeLocal().conectado) {
      ClienteRedeLocal().enviarPedido(pedido);
    }
    if (ServidorRedeLocal().ativo) {
      ServidorRedeLocal().notificarTodos({
        'tipo': tipoEvento,
        'lojaId': lojaId,
        'pedido': pedido.toJson(),
      });
    }
  }

  void _despacharMovimentosEstoqueRede(List<MovimentoEstoque> movimentos) {
    for (final mov in movimentos) {
      if (ClienteRedeLocal().conectado) {
        ClienteRedeLocal().enviarMovimentoEstoque(mov, lojaId: lojaId);
      }
      if (ServidorRedeLocal().ativo) {
        ServidorRedeLocal().notificarTodos({
          'tipo': 'estoque_atualizado',
          'lojaId': lojaId,
          'movimento': mov.toJson(),
        });
      }
    }
  }

  void _registrarBaixasEstoque(
    List<MovimentoEstoque> movimentosBaixa,
    List<ItemLoja> itens,
    int numeroPedido, {
    required String sufixoMotivo,
  }) {
    for (final movimento in movimentosBaixa) {
      final item = itens.firstWhere(
        (i) => i.id == movimento.itemId,
        orElse: () => const ItemLoja(id: '', nome: ''),
      );
      final quantidade = formatarQuantidade(movimento.quantidade);
      final unidade = rotuloUnidadeCurto(item.unidadeBase);
      registrarAcao(
        TipoAcao.movimentoEstoqueRegistrado,
        'Baixa automática de $quantidade $unidade de '
        '"${item.nome}" $sufixoMotivo ${formatarNumeroPedido(numeroPedido)}',
      );
    }
  }

  void alterarStatusPedido(String id, StatusPedido novoStatus) {
    final pedidos = obterPedidos();
    final indice = _encontrarIndicePedido(pedidos, id);
    if (indice == -1) return;

    final pedido = pedidos[indice];
    final eraNovoEAceitou =
        pedido.status == StatusPedido.novo && novoStatus == StatusPedido.aceito;
    final pedidoAtualizado = pedido.copyWith(status: novoStatus);

    final itens = obterItens();
    final movimentos = obterMovimentos();
    final movimentosBaixa = <MovimentoEstoque>[];

    if (eraNovoEAceitou && pedido.itens.isNotEmpty) {
      movimentosBaixa.addAll(
        EstoqueBaixaService.calcularMovimentosBaixa(
          itensVendidos: pedido.itens,
          itensCadastrados: itens,
          motivo: 'Pedido ${formatarNumeroPedido(pedido.numero)} aceito',
          cpfAutor: obterCpfLogado(),
          nomeAutor: obterNomeLogado(),
        ),
      );
    }

    setState(() {
      pedidos[indice] = pedidoAtualizado;
      if (movimentosBaixa.isNotEmpty) {
        movimentos.addAll(movimentosBaixa);
      }
    });
    aoPersistir();

    _despacharPedidoRede(pedidoAtualizado);
    _despacharMovimentosEstoqueRede(movimentosBaixa);

    if (novoStatus == StatusPedido.aceito) {
      registrarAcao(
        TipoAcao.pedidoAceito,
        'Pedido ${formatarNumeroPedido(pedido.numero)} aceito '
        '(${formatarValor(pedido.valor)})',
      );
      _registrarBaixasEstoque(
        movimentosBaixa,
        itens,
        pedido.numero,
        sufixoMotivo: 'pelo aceite do pedido',
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
    _despacharPedidoRede(pedidoAtualizado);

    registrarAcao(
      TipoAcao.comentarioSalvo,
      'Comentário salvo no pedido ${formatarNumeroPedido(pedido.numero)}',
    );
  }

  void cancelarPedidoSilencioso(
    String id, {
    String motivo = 'Cancelado automaticamente',
  }) {
    final pedidos = obterPedidos();
    final indice = _encontrarIndicePedido(pedidos, id);
    if (indice == -1) return;

    final pedido = pedidos[indice];
    final cancelado = pedido.copyWith(
      status: StatusPedido.cancelado,
      motivoCancelamento: motivo,
      dataHoraCancelamento: DateTime.now(),
      canceladoPorNome: 'Sistema',
    );
    setState(() {
      pedidos[indice] = cancelado;
    });
    aoPersistir();
    _despacharPedidoRede(cancelado);
  }

  Future<void> cancelarPedidoComDialog(String id) async {
    final pedidos = obterPedidos();
    final itens = obterItens();
    final movimentos = obterMovimentos();

    final indice = pedidos.indexWhere((p) => p.id == id);
    if (indice == -1) return;
    final pedido = pedidos[indice];

    final resultado = await CancelarPedidoDialog.mostrar(
      obterContext(),
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

    final movimentosEstorno = <MovimentoEstoque>[];
    setState(() {
      pedidos[indice] = pedidoCancelado;

      if (resultado.devolverEstoque) {
        movimentosEstorno.addAll(
          EstoqueBaixaService.calcularMovimentosEstorno(
            itensVendidos: pedido.itens,
            itensCadastrados: itens,
            motivo:
                'Estorno - Pedido ${formatarNumeroPedido(pedido.numero)} cancelado: ${resultado.motivo}',
            cpfAutor: obterCpfLogado(),
            nomeAutor: obterNomeLogado(),
          ),
        );
        movimentos.addAll(movimentosEstorno);
      }
    });

    aoPersistir();
    _despacharMovimentosEstoqueRede(movimentosEstorno);
    _despacharPedidoRede(pedidoCancelado);

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
    final indice = _encontrarIndicePedido(pedidos, id);
    if (indice == -1) return;
    final pedido = pedidos[indice];

    final agora = DateTime.now();
    final pedidoCancelado = pedido.copyWith(
      status: StatusPedido.cancelado,
      motivoCancelamento: 'Recusado pelo atendente',
      dataHoraCancelamento: agora,
      canceladoPorCpf: obterCpfLogado(),
      canceladoPorNome: obterNomeLogado(),
    );

    setState(() {
      pedidos[indice] = pedidoCancelado;
    });

    // Se o pedido era proveniente de um PedidoProgramado, registra que foi gerado hoje para não regenerar
    if (pedido.id.startsWith('prog_') && estaMontado()) {
      final pdv = obterContext().read<PdvProvider>();
      final lojaAtual = pdv.buscarPorId(lojaId);
      if (lojaAtual != null) {
        final programadosAtualizados = lojaAtual.pedidosProgramados.map((prog) {
          if (pedido.id.startsWith('prog_${prog.id}_')) {
            return prog.copyWith(ultimaDataGerado: agora);
          }
          return prog;
        }).toList();
        pdv.adicionarOuAtualizarLoja(
          lojaAtual.copyWith(pedidosProgramados: programadosAtualizados),
        );
      }
    }

    aoPersistir();
    _despacharPedidoRede(pedidoCancelado);

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
        obterContext(),
        theme: ThemeController.currentTheme.value,
        pedido: pedido,
      );
    }

    if (!estaMontado()) return;

    final movimentosEstorno = <MovimentoEstoque>[];
    setState(() {
      pedidos.removeWhere((p) => p.id == id);
      if (devolverEstoque) {
        movimentosEstorno.addAll(
          EstoqueBaixaService.calcularMovimentosEstorno(
            itensVendidos: pedido.itens,
            itensCadastrados: itens,
            motivo:
                'Estorno por exclusão do Pedido ${formatarNumeroPedido(pedido.numero)}',
            cpfAutor: obterCpfLogado(),
            nomeAutor: obterNomeLogado(),
          ),
        );
        movimentos.addAll(movimentosEstorno);
      }
    });
    await LojasService.excluirPedidoIndividual(lojaId, id);
    aoPersistir();

    _despacharMovimentosEstoqueRede(movimentosEstorno);

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
      movimentos.addAll(movimentosEstoque);
    });
    aoPersistir();

    _despacharPedidoRede(pedido, tipoEvento: 'pedido_adicionado');
    _despacharMovimentosEstoqueRede(movimentosEstoque);

    registrarAcao(
      TipoAcao.novaVenda,
      'Nova venda ${formatarNumeroPedido(pedido.numero)} para '
      '"${pedido.clienteNome}" (${formatarValor(pedido.valor)})',
    );

    _registrarBaixasEstoque(
      movimentosEstoque,
      itens,
      pedido.numero,
      sufixoMotivo: 'pelo pedido',
    );
  }
}
