import 'package:flutter_test/flutter_test.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_programado.dart';
import 'package:nous/src/features/pdv/providers/helpers/pdv_pedidos_programados_helper.dart';
import 'package:nous/src/features/pdv/services/loja/consolidador_loja_local.dart';

void main() {
  group('Contabilidade do PDV — Dívidas de Clientes e Status de Pedidos', () {
    test('Pedido cancelado ou recusado NÃO pontua como débito do cliente', () {
      final pedidoAtivo = PedidoLoja(
        id: 'ped-camaroes-1',
        numero: 1,
        clienteId: 'cli-camaroes',
        clienteNome: 'Os Camarões',
        produtoNome: 'Marmita Grande',
        dataHora: DateTime.now(),
        valor: 45.0,
        status: StatusPedido.concluido,
        formaPagamento: 'À Prazo',
        quitado: false,
        valorPago: 0.0,
      );

      final pedidoAgendadoRecusado = PedidoLoja(
        id: 'prog_camaroes_2026_11_06',
        numero: 2,
        clienteId: 'cli-camaroes',
        clienteNome: 'Os Camarões',
        produtoNome: 'Marmita Agendada',
        dataHora: DateTime.now(),
        valor: 35.0,
        status: StatusPedido.cancelado,
        motivoCancelamento: 'Recusado pelo atendente',
        formaPagamento: 'À Prazo',
        quitado: false,
        valorPago: 0.0,
      );

      expect(pedidoAtivo.aPrazoEmAberto, isTrue);
      expect(pedidoAgendadoRecusado.aPrazoEmAberto, isFalse);

      final pedidos = [pedidoAtivo, pedidoAgendadoRecusado];

      // Cálculo de dívida do cliente
      var somaDivida = 0.0;
      for (final p in pedidos) {
        if (p.clienteId == 'cli-camaroes' && p.aPrazoEmAberto) {
          somaDivida += p.valorRestante;
        }
      }

      // Deve somar apenas o pedido ativo de R$ 45,00, sem duplicar com os R$ 35,00 do pedido recusado
      expect(somaDivida, 45.0);
    });

    test('Pedido quitado ou parcialmente pago reflete exatamente o saldo restante', () {
      final pedidoParcial = PedidoLoja(
        id: 'ped-parcial',
        numero: 3,
        clienteId: 'cli-joao',
        clienteNome: 'João',
        produtoNome: 'Almoço Completo',
        dataHora: DateTime.now(),
        valor: 50.0,
        status: StatusPedido.concluido,
        formaPagamento: 'À Prazo',
        quitado: false,
        valorPago: 20.0,
      );

      expect(pedidoParcial.aPrazoEmAberto, isTrue);
      expect(pedidoParcial.valorRestante, 30.0);

      final pedidoQuitado = pedidoParcial.copyWith(
        quitado: true,
        valorPago: 50.0,
      );
      expect(pedidoQuitado.aPrazoEmAberto, isFalse);
      expect(pedidoQuitado.valorRestante, 0.0);
    });
  });

  group('Blindagem de Pedidos Programados — Prevenção de Duplicação', () {
    test('Se o pedido agendado do dia foi recusado/cancelado, NÃO regenera cópia duplicada', () {
      final agora = DateTime.now();
      final diaStr = agora.day.toString().padLeft(2, '0');
      final mesStr = agora.month.toString().padLeft(2, '0');
      final idEsperado = 'prog_camaroes_${agora.year}_${mesStr}_$diaStr';

      final programacao = PedidoProgramado(
        id: 'camaroes',
        lojaId: 'loja-1',
        clienteId: 'cli-camaroes',
        clienteNome: 'Os Camarões',
        clienteTelefone: '11999999999',
        clienteEndereco: 'Rua do Mar, 100',
        itens: [
          ItemVendido(
            itemId: 'item-1',
            nomeItem: 'Marmita Camarão',
            quantidade: 1,
            precoItem: 35.0,
          ),
        ],
        valorTotal: 35.0,
        formaPagamento: 'À Prazo',
        horario: '12:00',
        recorrente: true,
        modoProgramacao: 'dias_semana',
        diasSemana: [1, 2, 3, 4, 5, 6, 7], // Todos os dias
        ativo: true,
        dataCriacao: agora.subtract(const Duration(days: 10)),
        ultimaDataGerado: agora, // Marcado como gerado hoje
      );

      final pedidoCancelado = PedidoLoja(
        id: idEsperado,
        numero: 10,
        clienteId: 'cli-camaroes',
        clienteNome: 'Os Camarões',
        produtoNome: 'Marmita Camarão',
        dataHora: agora,
        valor: 35.0,
        status: StatusPedido.cancelado,
        motivoCancelamento: 'Recusado pelo atendente',
        formaPagamento: 'À Prazo',
      );

      final loja = Loja(
        id: 'loja-1',
        nome: 'Marmitaria Providence',
        cnpj: '00000000000100',
        telefone: '11999999999',
        endereco: 'Rua Central, 1',
        numero: '10',
        email: 'loja@providence.com',
        categorias: 'Alimentação',
        tags: 'Marmitas',
        pedidosProgramados: [programacao],
        pedidosLoja: [pedidoCancelado],
      );

      final resultado = PdvPedidosProgramadosHelper.verificarEGerar(loja);

      // Não deve gerar novos pedidos nem alterar a loja
      expect(resultado.alterou, isFalse);
      expect(resultado.pedidosGerados, isEmpty);
    });

    test('Se um pedido avulso com valor aumentado for tirado para o cliente no dia, agendado não duplica', () {
      final agora = DateTime.now();

      final programacao = PedidoProgramado(
        id: 'camaroes-2',
        lojaId: 'loja-1',
        clienteId: 'cli-camaroes-2',
        clienteNome: 'Os Camarões',
        clienteTelefone: '11999999999',
        clienteEndereco: 'Rua do Mar, 100',
        itens: [
          ItemVendido(
            itemId: 'item-1',
            nomeItem: 'Marmita Padrão',
            quantidade: 1,
            precoItem: 30.0,
          ),
        ],
        valorTotal: 30.0,
        formaPagamento: 'À Prazo',
        horario: '12:00',
        recorrente: true,
        modoProgramacao: 'dias_semana',
        diasSemana: [1, 2, 3, 4, 5, 6, 7],
        ativo: true,
        dataCriacao: agora.subtract(const Duration(days: 5)),
        ultimaDataGerado: null,
      );

      // O atendente tirou manualmente um pedido de R$ 55,00 hoje cedo para o cliente
      final pedidoManualAumentado = PedidoLoja(
        id: 'ped-manual-aumentado',
        numero: 11,
        clienteId: 'cli-camaroes-2',
        clienteNome: 'Os Camarões',
        produtoNome: 'Marmita Especial + Bebida',
        dataHora: agora,
        valor: 55.0,
        status: StatusPedido.concluido,
        formaPagamento: 'À Prazo',
      );

      final loja = Loja(
        id: 'loja-1',
        nome: 'Marmitaria Providence',
        cnpj: '00000000000100',
        telefone: '11999999999',
        endereco: 'Rua Central, 1',
        numero: '10',
        email: 'loja@providence.com',
        categorias: 'Alimentação',
        tags: 'Marmitas',
        pedidosProgramados: [programacao],
        pedidosLoja: [pedidoManualAumentado],
      );

      final resultado = PdvPedidosProgramadosHelper.verificarEGerar(loja);

      // Não deve gerar pedido duplicado para o cliente atendido
      expect(resultado.pedidosGerados, isEmpty);
    });
  });

  group('Reconciliação e Máquina de Estados Soberana de Pedidos', () {
    test('Status Cancelado tem precedência máxima sobre status Novo na mesclagem', () {
      final agora = DateTime.now();
      final pedidoNovo = PedidoLoja(
        id: 'ped-conflito-1',
        numero: 5,
        clienteNome: 'Cliente Teste',
        produtoNome: 'Refeição',
        dataHora: agora,
        valor: 40.0,
        status: StatusPedido.novo,
      );

      final pedidoCancelado = PedidoLoja(
        id: 'ped-conflito-1',
        numero: 5,
        clienteNome: 'Cliente Teste',
        produtoNome: 'Refeição',
        dataHora: agora,
        valor: 40.0,
        status: StatusPedido.cancelado,
        motivoCancelamento: 'Recusado pelo atendente',
      );

      final mescladoA = ConsolidadorLojaLocal.mesclarDoisPedidos(pedidoNovo, pedidoCancelado);
      final mescladoB = ConsolidadorLojaLocal.mesclarDoisPedidos(pedidoCancelado, pedidoNovo);

      expect(mescladoA.status, StatusPedido.cancelado);
      expect(mescladoB.status, StatusPedido.cancelado);
      expect(mescladoA.motivoCancelamento, 'Recusado pelo atendente');
      expect(mescladoB.motivoCancelamento, 'Recusado pelo atendente');
    });
  });
}
