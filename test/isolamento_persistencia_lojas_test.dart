import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pagamento_funcionario.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/services/backup_service.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tempDir = await Directory.systemTemp.createTemp('nous_isolamento_test_');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return tempDir.path;
      },
    );
    SharedPreferences.setMockInitialValues({});
  });

  test(
      'Persiste múltiplas lojas do mesmo CPF (Laricas e Berenice) com estoque e pagamentos sem rollback SQLite',
      () async {
    const cpfDono = '47192956813';

    final lojaLaricas = Loja(
      id: 'loja_laricas_1',
      cpfDonoOriginal: cpfDono,
      nome: 'Laricas',
      cnpj: '12.345.678/0001-90',
      telefone: '11999999999',
      endereco: 'Rua A',
      numero: '10',
      email: 'laricas@nous.org',
      categorias: 'Restaurante',
      tags: 'Lanches',
      itensLoja: const [
        ItemLoja(id: 'item_l1', nome: 'Hambúrguer Artesanal', preco: '25,00'),
      ],
      movimentosEstoque: [
        MovimentoEstoque(
          id: 'mov_laricas_1',
          itemId: 'item_l1',
          tipo: TipoMovimentoEstoque.entrada,
          quantidade: 20,
          custoUnitario: 10.5,
          dataHora: DateTime(2026, 11, 3, 14, 0),
          motivo: 'Compra inicial',
        ),
      ],
      pagamentosFuncionarios: [
        PagamentoFuncionario(
          id: 'pag_laricas_1',
          cpf: '11122233344',
          nome: 'Trabalhador 1',
          valor: 150.0,
          dataHora: DateTime(2026, 11, 3, 18, 0),
          descricao: 'Diária',
        ),
      ],
    );

    final lojaBerenice = Loja(
      id: 'loja_berenice_2',
      cpfDonoOriginal: cpfDono,
      nome: 'Berenice',
      cnpj: '98.765.432/0001-10',
      telefone: '11888888888',
      endereco: 'Rua B',
      numero: '20',
      email: 'berenice@nous.org',
      categorias: 'Restaurante',
      tags: 'Café',
      itensLoja: const [
        ItemLoja(id: 'item_b1', nome: 'Café Expresso', preco: '8,00'),
        ItemLoja(id: 'item_b2', nome: 'Pão de Queijo', preco: '6,00'),
        ItemLoja(id: 'item_b3', nome: 'Bolo de Milho', preco: '12,00'),
      ],
      mesas: const [
        MesaLoja(id: 'mesa_b1', numero: '01'),
        MesaLoja(id: 'mesa_b2', numero: '02'),
      ],
      pedidosLoja: [
        PedidoLoja(
          id: 'ped_b1',
          lojaId: 'loja_berenice_2',
          numero: 1,
          clienteNome: 'Cliente Berenice',
          produtoNome: 'Café Expresso',
          valor: 8.0,
          dataHora: DateTime(2026, 11, 3, 19, 0),
          status: StatusPedido.concluido,
        ),
      ],
    );

    // 1. Salva Laricas (com estoque e pagamentos) e depois Berenice (com 3 registros)
    await LojasService.salvarLojaIndividual(lojaLaricas);
    await LojasService.salvarLojaIndividual(lojaBerenice);

    // 2. Recarrega do SQLite e verifica que ambas estão íntegras e isoladas
    final carregadas = await LojasService.carregar(cpfDono);
    expect(carregadas.length, 2);

    final laricasBanco =
        carregadas.firstWhere((l) => l.id == 'loja_laricas_1');
    final bereniceBanco =
        carregadas.firstWhere((l) => l.id == 'loja_berenice_2');

    expect(laricasBanco.movimentosEstoque.length, 1);
    expect(laricasBanco.movimentosEstoque.first.itemId, 'item_l1');
    expect(laricasBanco.pagamentosFuncionarios.length, 1);
    expect(laricasBanco.pagamentosFuncionarios.first.valor, 150.0);

    expect(bereniceBanco.itensLoja.length, 3);
    expect(bereniceBanco.mesas.length, 2);
    expect(bereniceBanco.pedidosLoja.length, 1);

    // 3. Testa que exclusão local de mesa e pedido em Berenice persiste sem "ressuscitar"
    await LojasService.excluirPedidoIndividual('loja_berenice_2', 'ped_b1');
    final bereniceSemMesa2EPedido = bereniceBanco.copyWith(
      mesas: const [MesaLoja(id: 'mesa_b1', numero: '01')],
      pedidosLoja: const [],
    );
    await LojasService.salvarLojaIndividual(bereniceSemMesa2EPedido);

    final bereniceAposExclusao =
        await LojasService.carregarLojaPorId('loja_berenice_2');
    expect(bereniceAposExclusao, isNotNull);
    expect(bereniceAposExclusao!.mesas.length, 1);
    expect(bereniceAposExclusao.mesas.first.id, 'mesa_b1');
    expect(bereniceAposExclusao.pedidosLoja, isEmpty);
  });

  test(
      'BackupService.desduplicarLojas nunca funde lojas com nomes e IDs diferentes mesmo com CNPJ repetido',
      () {
    const lojaA = Loja(
      id: 'id_laricas',
      nome: 'Laricas',
      cnpj: '00.000.000/0001-00',
      telefone: '',
      endereco: '',
      numero: '',
      email: '',
      categorias: 'Restaurante',
      tags: '',
    );
    const lojaB = Loja(
      id: 'id_berenice',
      nome: 'Berenice',
      cnpj: '00.000.000/0001-00',
      telefone: '',
      endereco: '',
      numero: '',
      email: '',
      categorias: 'Restaurante',
      tags: '',
    );

    final resultado = BackupService.desduplicarLojas([lojaA, lojaB]);
    expect(resultado.length, 2);
    expect(resultado.map((l) => l.nome).toList(), ['Laricas', 'Berenice']);
  });
}
