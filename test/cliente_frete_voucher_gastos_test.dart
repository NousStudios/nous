import 'package:flutter_test/flutter_test.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/gasto_diario.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/services/impressao/impressao_utils.dart';
import 'package:nous/src/features/pdv/services/loja/consolidador_loja_local.dart';
import 'package:nous/src/features/pdv/views/widgets/financeiro/financeiro_operacoes_helper.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_venda/nova_venda_controller.dart';

void main() {
  group('Cliente - Frete Padrão e Preenchimento Automático', () {
    test('Cliente serializa, desserializa e faz copyWith de fretePadrao', () {
      final cliente = const Cliente(
        id: 'cli_frete_1',
        nome: 'Maico Providence',
        fretePadrao: 7.50,
      );

      final json = cliente.toJson();
      expect(json['fretePadrao'], equals(7.50));

      final recriado = Cliente.fromJson(json);
      expect(recriado.fretePadrao, equals(7.50));

      final alterado = recriado.copyWith(fretePadrao: 10.0);
      expect(alterado.fretePadrao, equals(10.0));
    });

    test('NovaVendaController preenche automaticamente frete ao selecionar cliente com fretePadrao', () {
      final clienteComFrete = const Cliente(
        id: 'c1',
        nome: 'Maico Providence',
        fretePadrao: 8.00,
      );

      final controller = NovaVendaController(
        theme: AppTheme(),
        itensDisponiveis: const [],
        categoriasDisponiveis: const [],
        gruposDisponiveis: const [],
        obterClientes: () => [clienteComFrete],
        obterPedidos: () => [],
        aoAbrirClientes: () async {},
        nomeVendedor: 'Providence',
        cnpjVendedor: '',
        proximoNumero: 1,
        cpfAutor: '12345678900',
        nomeAutor: 'Operador',
        onConcluir: (_, _) {},
        aoCriarItem: (_, _, _, [_]) async {},
        configuracoesImpressora: const ConfiguracoesImpressora(),
      );
      addTearDown(controller.dispose);

      expect(controller.freteController.text, isEmpty);

      controller.selecionarCliente(clienteComFrete);

      expect(controller.freteController.text, equals('8,00'));
      expect(controller.frete, equals(8.00));
    });
  });

  group('Forma de Pagamento - Voucher no PDV e Financeiro', () {
    test('Voucher está presente nas listas oficiais de pagamento', () {
      expect(NovaVendaController.formasDePagamento.contains('Voucher'), isTrue);
      expect(FinanceiroOperacoesHelper.formasDePagamento.contains('Voucher'), isTrue);
      expect(kFormasDePagamentoImpressao.contains('Voucher'), isTrue);
    });

    test('FinanceiroOperacoesHelper computa entradas de Voucher', () {
      final pedidos = [
        PedidoLoja(
          id: 'p1',
          numero: 1,
          clienteNome: 'Cliente 1',
          produtoNome: 'Refeição',
          valor: 50.0,
          formaPagamento: 'Voucher',
          status: StatusPedido.concluido,
          dataHora: DateTime.now(),
        ),
        PedidoLoja(
          id: 'p2',
          numero: 2,
          clienteNome: 'Cliente 2',
          produtoNome: 'Bebida',
          valor: 20.0,
          formaPagamento: 'Pix',
          status: StatusPedido.concluido,
          dataHora: DateTime.now(),
        ),
      ];

      final totalVoucher = FinanceiroOperacoesHelper.calcularEntradasPorForma(pedidos, 'Voucher');
      expect(totalVoucher, equals(50.0));

      final totalEntradas = FinanceiroOperacoesHelper.calcularTotalEntradas(pedidos);
      expect(totalEntradas, equals(70.0));
    });
  });

  group('Gastos do Dia e Consolidação de Loja', () {
    test('GastoDiario serializa, desserializa e ConsolidadorLojaLocal une gastos', () {
      final gasto1 = GastoDiario.novo(
        valor: 150.0,
        descricao: 'Carnes e hortifruti',
      );
      final gasto2 = GastoDiario.novo(
        valor: 45.0,
        descricao: 'Embalagens e sacolas',
      );

      final json1 = gasto1.toJson();
      expect(json1['valor'], equals(150.0));
      expect(json1['descricao'], equals('Carnes e hortifruti'));

      final recriado1 = GastoDiario.fromJson(json1);
      expect(recriado1.valor, equals(150.0));
      expect(recriado1.id, equals(gasto1.id));

      final lojaLocal = const Loja(
        id: 'lj1',
        nome: 'Providence',
        cnpj: '',
        telefone: '',
        endereco: '',
        numero: '',
        email: '',
        categorias: '',
        tags: '',
      ).copyWith(gastosDiarios: [gasto1]);

      final lojaNova = lojaLocal.copyWith(gastosDiarios: [gasto2]);

      final consolidada = ConsolidadorLojaLocal.consolidar(
        lojaNova,
        lojaLocal,
        mesclarColecoesRemotas: true,
      );

      expect(consolidada.gastosDiarios.length, equals(2));
      final totalGastos = consolidada.gastosDiarios.fold<double>(0.0, (s, g) => s + g.valor);
      expect(totalGastos, equals(195.0));
    });
  });
}
