import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pagamento_funcionario.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';

/// Helper especialista para operações de estoque, pagamentos a funcionários e transações financeiras.
class PdvEstoqueFinanceiroHelper {
  static Loja resetarTransacoes(
    Loja loja, {
    String autorCpf = '',
    String autorNome = '',
    String autorEmail = '',
  }) {
    final novaAcao = RegistroAcao(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      dataHora: DateTime.now(),
      tipo: TipoAcao.transacoesResetadas,
      descricao:
          'Registros de transações da loja (vendas, caixas e pagamentos) resetados.',
      cpfAutor: autorCpf,
      nomeAutor: autorNome,
      emailAutor: autorEmail,
    );

    // Consolidar saldo de estoque de cada item com custo financeiro zero,
    // preservando rigorosamente a contagem física atual de produtos sem deixar resquícios de compras financeiras.
    final saldosPorItem = <String, double>{};
    for (final m in loja.movimentosEstoque) {
      saldosPorItem[m.itemId] =
          (saldosPorItem[m.itemId] ?? 0.0) + m.quantidadeComSinal;
    }

    final agora = DateTime.now();
    final novosMovimentosEstoque = <MovimentoEstoque>[];
    saldosPorItem.forEach((itemId, saldo) {
      if (saldo != 0.0) {
        novosMovimentosEstoque.add(
          MovimentoEstoque(
            id: '${agora.millisecondsSinceEpoch}_$itemId',
            itemId: itemId,
            tipo: saldo >= 0
                ? TipoMovimentoEstoque.entrada
                : TipoMovimentoEstoque.saida,
            quantidade: saldo.abs(),
            custoUnitario: 0.0,
            dataHora: agora,
            motivo: 'Saldo preservado pós-reset financeiro',
            cpfAutor: autorCpf,
            nomeAutor: autorNome,
            categoria: CategoriaMovimentoEstoque.ajuste,
          ),
        );
      }
    });

    return loja.copyWith(
      pedidosLoja: const [],
      turnosCaixa: const [],
      pagamentosFuncionarios: const [],
      movimentosEstoque: novosMovimentosEstoque,
      acoes: [novaAcao, ...loja.acoes],
    );
  }

  static ({Loja loja, PedidoLoja? pedidoQuitado, double valorQuitado})? quitarPedido(
    Loja loja,
    String pedidoId,
  ) {
    final pedidos = List<PedidoLoja>.from(loja.pedidosLoja);
    final idxPed = pedidos.indexWhere((p) => p.id == pedidoId);
    if (idxPed == -1) return null;
    final pedido = pedidos[idxPed];
    final valorQuitado = pedido.valorRestante;

    pedidos[idxPed] = pedido.copyWith(
      quitado: true,
      valorPago: pedido.valor,
    );

    final atualizada = loja.copyWith(pedidosLoja: pedidos);
    return (loja: atualizada, pedidoQuitado: pedido, valorQuitado: valorQuitado);
  }

  static Loja adicionarMovimentoEstoque(
    Loja loja,
    MovimentoEstoque movimento,
  ) {
    final atual = loja.movimentosEstoque;
    var itensLoja = loja.itensLoja;
    if (movimento.ehEntrada && movimento.custoUnitario > 0) {
      final idxItem = itensLoja.indexWhere((i) => i.id == movimento.itemId);
      if (idxItem != -1) {
        final itemAtual = itensLoja[idxItem];
        final novoCusto =
            movimento.custoUnitario.toStringAsFixed(2).replaceAll('.', ',');
        if (itemAtual.precoCusto != novoCusto) {
          final novosItens = List<ItemLoja>.from(itensLoja);
          novosItens[idxItem] = itemAtual.copyWith(precoCusto: novoCusto);
          itensLoja = novosItens;
        }
      }
    }
    return loja.copyWith(
      movimentosEstoque: [movimento, ...atual],
      itensLoja: itensLoja,
    );
  }

  static Loja removerMovimentoEstoque(Loja loja, String movimentoId) {
    final atual = loja.movimentosEstoque;
    return loja.copyWith(
      movimentosEstoque: atual.where((m) => m.id != movimentoId).toList(),
    );
  }

  static Loja adicionarPagamentoFuncionario(
    Loja loja,
    PagamentoFuncionario pagamento,
  ) {
    final atual = loja.pagamentosFuncionarios;
    return loja.copyWith(
      pagamentosFuncionarios: [pagamento, ...atual],
    );
  }

  static Loja removerPagamentoFuncionario(Loja loja, String pagamentoId) {
    final atual = loja.pagamentosFuncionarios;
    return loja.copyWith(
      pagamentosFuncionarios:
          atual.where((p) => p.id != pagamentoId).toList(),
    );
  }

  static Future<void> executarResetTransacoes({
    required Loja loja,
    required String autorCpf,
    required String autorNome,
    required String autorEmail,
    required Future<void> Function(Loja) salvarEAtualizar,
  }) async {
    final atualizada = resetarTransacoes(
      loja,
      autorCpf: autorCpf,
      autorNome: autorNome,
      autorEmail: autorEmail,
    );
    await LojasService.limparTransacoesBancoLoja(loja.id);
    await salvarEAtualizar(atualizada);
  }

  static void executarQuitarPedido({
    required Loja loja,
    required String pedidoId,
    required String formaRecebimento,
    required String autorCpf,
    required String autorNome,
    required String autorEmail,
    required void Function(Loja) salvarEAtualizar,
    required void Function(double valor, String motivo) registrarSuprimentoCaixa,
    required void Function(RegistroAcao acao) registrarAcao,
  }) {
    final res = quitarPedido(loja, pedidoId);
    if (res == null) return;
    salvarEAtualizar(res.loja);

    if (formaRecebimento.trim().toLowerCase() == 'dinheiro' && res.valorQuitado > 0) {
      registrarSuprimentoCaixa(
        res.valorQuitado,
        'Recebimento de prazo - Pedido #${res.pedidoQuitado?.numero}',
      );
    }

    registrarAcao(
      RegistroAcao(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        dataHora: DateTime.now(),
        tipo: TipoAcao.pagamentoPrazoRecebido,
        descricao:
            'Pedido #${res.pedidoQuitado?.numero} quitado ($formaRecebimento) - R\$ ${res.valorQuitado.toStringAsFixed(2).replaceAll('.', ',')}',
        cpfAutor: autorCpf,
        nomeAutor: autorNome,
        emailAutor: autorEmail,
      ),
    );
  }
}
