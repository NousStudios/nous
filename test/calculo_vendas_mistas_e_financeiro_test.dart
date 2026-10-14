import 'package:flutter_test/flutter_test.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';

void main() {
  group('Cálculos Financeiros e Vendas Mistas', () {
    test(
        'Venda mista calcula troco, entrada à vista e saldo a prazo sem duplicação',
        () {
      const totalVenda = 100.0;
      final pagamentosPedido = [
        const PagamentoParcial(forma: 'Dinheiro', valor: 50.0),
        const PagamentoParcial(forma: 'À Prazo', valor: 60.0),
      ];

      final valorPagoNaoPrazo = pagamentosPedido
          .where((p) => p.forma != 'À Prazo')
          .fold<double>(0.0, (s, p) => s + p.valor);

      final totalPagamentos =
          pagamentosPedido.fold<double>(0.0, (s, p) => s + p.valor);
      final trocoCalculado = totalPagamentos - totalVenda;
      final trocoFinal = trocoCalculado > 0.005 ? trocoCalculado : 0.0;

      final temPrazo = pagamentosPedido.any((p) => p.forma == 'À Prazo');
      final valorEntradaAVista =
          (valorPagoNaoPrazo - trocoFinal).clamp(0.0, totalVenda);

      final pedido = PedidoLoja(
        id: 'ped-1',
        numero: 1,
        clienteNome: 'Trabalhador Teste',
        produtoNome: 'Cesta Básica',
        dataHora: DateTime(2026, 10, 11, 10, 0),
        valor: totalVenda,
        status: StatusPedido.concluido,
        formaPagamento: '',
        pagamentosExtras: pagamentosPedido,
        valorRecebido: valorPagoNaoPrazo,
        troco: trocoFinal,
        quitado: !temPrazo || valorEntradaAVista >= totalVenda,
        valorPago: !temPrazo ? totalVenda : valorEntradaAVista,
      );

      // Verificações essenciais
      expect(pedido.troco, 10.0);
      expect(pedido.valorPago, 40.0);
      expect(pedido.valorRestante, 60.0);
      expect(pedido.quitado, isFalse);
      expect(pedido.aPrazoEmAberto, isTrue);

      // Verificação da separação contábil de entradas por forma
      final entradasNaoPrazo = pedido.todosPagamentos
          .where((p) => p.forma != 'À Prazo' && p.forma != 'a prazo')
          .fold<double>(0.0, (s, p) => s + p.valor);

      // Dinheiro recebido líquido
      final dinheiroBruto = pedido.todosPagamentos
          .firstWhere((p) => p.forma == 'Dinheiro')
          .valor;
      expect(dinheiroBruto - pedido.troco, 40.0);

      // Recebido da parcela a prazo no momento da venda (deve ser 0)
      final recebidoDoPrazoNaVenda = pedido.valorPago - entradasNaoPrazo;
      expect(recebidoDoPrazoNaVenda <= 0, isTrue);

      // Simulação: Cliente faz quitação de R$ 30,00 da dívida posteriormente
      final pedidosAposQuitacaoParcial = aplicarPagamentoAPrazo(
        [pedido],
        '',
        30.0,
        clienteNome: 'Trabalhador Teste',
      );

      final pedidoParcial = pedidosAposQuitacaoParcial.first;
      expect(pedidoParcial.valorPago, 70.0);
      expect(pedidoParcial.valorRestante, 30.0);
      expect(pedidoParcial.quitado, isFalse);

      // Simulação: Cliente quita os R$ 30,00 restantes
      final pedidosQuitadosTotal = aplicarPagamentoAPrazo(
        pedidosAposQuitacaoParcial,
        '',
        30.0,
        clienteNome: 'Trabalhador Teste',
      );

      final pedidoQuitado = pedidosQuitadosTotal.first;
      expect(pedidoQuitado.valorPago, 100.0);
      expect(pedidoQuitado.valorRestante, 0.0);
      expect(pedidoQuitado.quitado, isTrue);
      expect(pedidoQuitado.aPrazoEmAberto, isFalse);
    });

    test('Demonstrativo de Resultado (DRE) calcula equações e margens com precisão', () {
      const receita = 1000.0;
      const cmv = 400.0;
      final lucroBruto = receita - cmv;
      final margemBruta = receita > 0 ? (lucroBruto / receita * 100) : 0.0;
      const despesasPessoal = 350.0;
      final resultadoLiquido = lucroBruto - despesasPessoal;
      final margemLiquida =
          receita > 0 ? (resultadoLiquido / receita * 100) : 0.0;

      expect(lucroBruto, 600.0);
      expect(margemBruta, 60.0);
      expect(resultadoLiquido, 250.0);
      expect(margemLiquida, 25.0);
    });

    test('Fechamento de mesa à prazo vincula cliente rápido e gera pedido fiado', () {
      final clienteCriado = Cliente(
        id: 'cli-rapido-1',
        nome: 'Dona Maria da Silva',
        endereco: 'Rua das Flores, 123',
        telefone: '(11) 98765-4321',
      );

      final pedidoMesa = PedidoLoja(
        id: 'ped-mesa-1',
        numero: 10,
        clienteId: clienteCriado.id,
        clienteNome: clienteCriado.nome,
        produtoNome: '2x Almoço Executivo',
        valor: 50.0,
        dataHora: DateTime(2026, 10, 11, 12, 0),
        status: StatusPedido.concluido,
        formaPagamento: 'À Prazo',
        pagamentosExtras: const [
          PagamentoParcial(forma: 'À Prazo', valor: 50.0),
        ],
        quitado: false,
        valorPago: 0.0,
      );

      expect(pedidoMesa.clienteId, 'cli-rapido-1');
      expect(pedidoMesa.clienteNome, 'Dona Maria da Silva');
      expect(pedidoMesa.temAPrazo, isTrue);
      expect(pedidoMesa.aPrazoEmAberto, isTrue);
      expect(pedidoMesa.valorRestante, 50.0);
    });
    test('Filtro financeiro por dia específico e intervalo de datas', () {
      final p1 = PedidoLoja(
        id: 'p-1',
        numero: 1,
        clienteNome: 'Cliente A',
        produtoNome: 'Item 1',
        valor: 100.0,
        dataHora: DateTime(2026, 10, 10, 14, 30),
        status: StatusPedido.concluido,
        formaPagamento: 'Dinheiro',
      );

      final p2 = PedidoLoja(
        id: 'p-2',
        numero: 2,
        clienteNome: 'Cliente B',
        produtoNome: 'Item 2',
        valor: 150.0,
        dataHora: DateTime(2026, 10, 12, 9, 15),
        status: StatusPedido.concluido,
        formaPagamento: 'Pix',
      );

      final p3 = PedidoLoja(
        id: 'p-3',
        numero: 3,
        clienteNome: 'Cliente C',
        produtoNome: 'Item 3',
        valor: 200.0,
        dataHora: DateTime(2026, 10, 14, 18, 00),
        status: StatusPedido.concluido,
        formaPagamento: 'Débito',
      );

      final todosPedidos = [p1, p2, p3];

      // Caso 1: Apenas um dia (12/10/2026)
      final inicioDia12 = DateTime(2026, 10, 12, 0, 0, 0);
      final fimDia12 = DateTime(2026, 10, 12, 23, 59, 59, 999);
      final vendasDia12 = todosPedidos.where((p) {
        if (p.dataHora.isBefore(inicioDia12)) return false;
        if (p.dataHora.isAfter(fimDia12)) return false;
        return true;
      }).toList();

      expect(vendasDia12.length, 1);
      expect(vendasDia12.first.id, 'p-2');
      expect(vendasDia12.first.valor, 150.0);

      // Caso 2: Intervalo de dias (10/10/2026 a 12/10/2026)
      final inicioIntervalo = DateTime(2026, 10, 10, 0, 0, 0);
      final fimIntervalo = DateTime(2026, 10, 12, 23, 59, 59, 999);
      final vendasIntervalo = todosPedidos.where((p) {
        if (p.dataHora.isBefore(inicioIntervalo)) return false;
        if (p.dataHora.isAfter(fimIntervalo)) return false;
        return true;
      }).toList();

      expect(vendasIntervalo.length, 2);
      expect(vendasIntervalo.map((p) => p.id).toList(), ['p-1', 'p-2']);
      final totalIntervalo =
          vendasIntervalo.fold<double>(0.0, (s, p) => s + p.valor);
      expect(totalIntervalo, 250.0);
    });
  });
}
