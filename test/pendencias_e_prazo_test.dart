import 'package:flutter_test/flutter_test.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';

void main() {
  group('Pendências Agrupadas e Formas de Pagamento no Financeiro', () {
    test(
        'Múltiplos pedidos a prazo do mesmo cliente devem ser agrupados somando o total devido e indicando o último pedido',
        () {
      final dataAntiga = DateTime(2026, 10, 13, 11, 30);
      final dataRecente = DateTime(2026, 10, 13, 13, 15);

      final pedido1 = PedidoLoja(
        id: 'ped-1',
        numero: 101,
        clienteId: 'cli-joao',
        clienteNome: 'João da Marmita',
        produtoNome: 'Marmitex P',
        dataHora: dataAntiga,
        valor: 20.0,
        status: StatusPedido.concluido,
        formaPagamento: 'À Prazo',
        quitado: false,
        valorPago: 0.0,
      );

      final pedido2 = PedidoLoja(
        id: 'ped-2',
        numero: 108,
        clienteId: 'cli-joao',
        clienteNome: 'João da Marmita',
        produtoNome: 'Marmitex G + Refrigerante',
        dataHora: dataRecente,
        valor: 35.0,
        status: StatusPedido.concluido,
        formaPagamento: 'À Prazo',
        quitado: false,
        valorPago: 0.0,
      );

      final pedidos = [pedido1, pedido2];

      // Lógica de agrupamento espelhada da UI
      final abertos = pedidos.where((p) => p.aPrazoEmAberto).toList();
      final grupos = <String, List<PedidoLoja>>{};
      for (final p in abertos) {
        final chave = (p.clienteId != null && p.clienteId!.trim().isNotEmpty)
            ? 'id:${p.clienteId!.trim()}'
            : 'nome:${p.clienteNome.trim().toLowerCase()}';
        grupos.putIfAbsent(chave, () => []).add(p);
      }

      expect(grupos.length, 1);
      final grupoJoao = grupos['id:cli-joao']!;
      expect(grupoJoao.length, 2);

      grupoJoao.sort((a, b) => b.dataHora.compareTo(a.dataHora));
      final ultimo = grupoJoao.first;
      final totalDevido =
          grupoJoao.fold<double>(0.0, (s, p) => s + p.valorRestante);

      // O último pedido deve ser o pedido #108
      expect(ultimo.numero, 108);
      expect(ultimo.dataHora, dataRecente);
      // O total devido deve ser R$ 55,00 (20 + 35)
      expect(totalDevido, 55.0);
    });

    test(
        'Contabilização de Entradas por forma de pagamento soma valor de vendas à prazo corretamente',
        () {
      final vendasConcluidas = [
        PedidoLoja(
          id: 'v1',
          numero: 1,
          clienteNome: 'Cliente Pix',
          produtoNome: 'Marmita',
          dataHora: DateTime.now(),
          valor: 25.0,
          status: StatusPedido.concluido,
          formaPagamento: 'Pix',
          quitado: true,
          valorPago: 25.0,
        ),
        PedidoLoja(
          id: 'v2',
          numero: 2,
          clienteId: 'cli-1',
          clienteNome: 'Cliente Prazo',
          produtoNome: 'Marmita à prazo',
          dataHora: DateTime.now(),
          valor: 30.0,
          status: StatusPedido.concluido,
          formaPagamento: 'À Prazo',
          quitado: false,
          valorPago: 0.0,
        ),
      ];

      double entradasPorForma(String forma) {
        var soma = 0.0;
        final ehPrazo = forma.trim().toLowerCase() == 'à prazo' ||
            forma.trim().toLowerCase() == 'a prazo';
        for (final venda in vendasConcluidas) {
          for (final p in venda.todosPagamentos) {
            final pEhPrazo = p.forma.trim().toLowerCase() == 'à prazo' ||
                p.forma.trim().toLowerCase() == 'a prazo' ||
                p.forma.toLowerCase().contains('prazo');
            if (ehPrazo && pEhPrazo) {
              soma += p.valor;
            } else if (!ehPrazo &&
                !pEhPrazo &&
                p.forma.trim().toLowerCase() == forma.trim().toLowerCase()) {
              soma += p.valor;
            }
          }
        }
        return soma;
      }

      expect(entradasPorForma('Pix'), 25.0);
      expect(entradasPorForma('À Prazo'), 30.0);
      expect(entradasPorForma('Dinheiro'), 0.0);
    });

    test(
        'Quitar pedido a prazo zera valor restante e marca quitado como true',
        () {
      final pedidoOriginal = PedidoLoja(
        id: 'ped-fiado',
        numero: 99,
        clienteId: 'cli-99',
        clienteNome: 'Trabalhador Local',
        produtoNome: 'Almoço',
        dataHora: DateTime.now(),
        valor: 22.50,
        status: StatusPedido.concluido,
        formaPagamento: 'À Prazo',
        quitado: false,
        valorPago: 0.0,
      );

      expect(pedidoOriginal.aPrazoEmAberto, isTrue);
      expect(pedidoOriginal.valorRestante, 22.50);

      final pedidoQuitado = pedidoOriginal.copyWith(
        quitado: true,
        valorPago: pedidoOriginal.valor,
      );

      expect(pedidoQuitado.quitado, isTrue);
      expect(pedidoQuitado.valorRestante, 0.0);
      expect(pedidoQuitado.aPrazoEmAberto, isFalse);
    });
  });
}
