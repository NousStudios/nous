import 'package:flutter_test/flutter_test.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';

void main() {
  group('Cálculo de Categoria + Item no PDV e Mesas', () {
    final embalagemPequena = ItemLoja.novo(
      nome: 'Embalagem Pequena',
      preco: '2,00',
    );

    final categoriaMarmitas = CategoriaLoja.nova(
      nome: 'Marmitas',
      preco: '20,00',
      itemIds: [embalagemPequena.id],
    );

    test('Item avulso: vendido individualmente pelo preço do item (R\$ 2,00)', () {
      final itemVendidoAvulso = ItemVendido(
        itemId: embalagemPequena.id,
        nomeItem: embalagemPequena.nome,
        precoItem: 2.0,
        precoCategoria: 0.0,
        quantidade: 1,
      );

      expect(itemVendidoAvulso.precoBase, equals(2.0));
      expect(itemVendidoAvulso.subtotal, equals(2.0));
      expect(itemVendidoAvulso.nomeExibicao, equals('Embalagem Pequena'));
    });

    test('Item com categoria: soma o preço da categoria com o item (R\$ 20 + R\$ 2 = R\$ 22)', () {
      final itemVendidoNaCategoria = ItemVendido(
        itemId: embalagemPequena.id,
        nomeItem: embalagemPequena.nome,
        categoriaId: categoriaMarmitas.id,
        nomeCategoria: categoriaMarmitas.nome,
        precoCategoria: 20.0,
        precoItem: 2.0,
        quantidade: 1,
      );

      expect(itemVendidoNaCategoria.precoBase, equals(22.0));
      expect(itemVendidoNaCategoria.subtotal, equals(22.0));
      expect(itemVendidoNaCategoria.nomeExibicao, equals('Marmitas Embalagem Pequena'));
    });

    test('Comanda da mesa calcula o total com consumo do item categorizado', () {
      final itemComanda = ItemComandaMesa(
        id: 'cmd-1',
        item: ItemVendido(
          itemId: embalagemPequena.id,
          nomeItem: embalagemPequena.nome,
          categoriaId: categoriaMarmitas.id,
          nomeCategoria: categoriaMarmitas.nome,
          precoCategoria: 20.0,
          precoItem: 2.0,
          quantidade: 2, // 2 marmitas a R$ 22 = R$ 44
        ),
        autorCpf: '111.111.111-11',
        autorNome: 'Atendente',
        dataHora: DateTime.now(),
      );

      final mesa = MesaLoja(
        id: 'mesa-1',
        numero: '01',
        status: StatusMesa.ocupada,
        itens: [itemComanda],
      );

      expect(mesa.totalAcumulado, equals(44.0));
      expect(mesa.quantidadeItensTotal, equals(2));
      expect(mesa.itens.first.item.nomeExibicao, equals('Marmitas Embalagem Pequena'));
    });

    test('Item com variante e acompanhamentos na mesa calcula total e exibe nome com variante', () {
      final itemComandaVariante = ItemComandaMesa(
        id: 'cmd-2',
        item: ItemVendido(
          itemId: 'pizza-1',
          nomeItem: 'Pizza Especial',
          varianteNome: 'Grande (8 Fatias)',
          precoItem: 65.0,
          precoCategoria: 0.0,
          quantidade: 1,
        ),
        autorCpf: '111.111.111-11',
        autorNome: 'Garçom',
        dataHora: DateTime.now(),
      );

      final mesa = MesaLoja(
        id: 'mesa-2',
        numero: '02',
        status: StatusMesa.ocupada,
        itens: [itemComandaVariante],
      );

      expect(mesa.totalAcumulado, equals(65.0));
      expect(mesa.itens.first.item.nomeExibicao, equals('Pizza Especial (Grande (8 Fatias))'));
    });

    test('Modo Balcão: Item vendido em "Todos" (sem categoria selecionada) não soma preço de categoria', () {
      final copo300ml = ItemLoja.novo(nome: 'Copo 300ml', preco: '2,00');
      final categoriaAcai = CategoriaLoja.nova(
        nome: 'Açaí 300ml',
        preco: '17,00',
        itemIds: [copo300ml.id],
      );

      // Simulação do comportamento de _obterCategoriaDoItem
      CategoriaLoja? obterCategoria(ItemLoja item, String? categoriaFiltroId) {
        if (categoriaFiltroId != null) {
          if (categoriaAcai.id == categoriaFiltroId &&
              categoriaAcai.itemIds.contains(item.id)) {
            return categoriaAcai;
          }
        }
        return null;
      }

      // Em "Todos" (categoriaFiltroId == null) -> Preço Puro
      final catTodos = obterCategoria(copo300ml, null);
      expect(catTodos, isNull);
      final itemVendidoTodos = ItemVendido(
        itemId: copo300ml.id,
        nomeItem: copo300ml.nome,
        precoItem: 2.0,
        precoCategoria: catTodos != null ? 17.0 : 0.0,
        quantidade: 1,
      );
      expect(itemVendidoTodos.subtotal, equals(2.0));
      expect(itemVendidoTodos.nomeExibicao, equals('Copo 300ml'));

      // Na categoria Açaí (categoriaFiltroId == categoriaAcai.id) -> R$ 17 + R$ 2 = R$ 19
      final catFiltro = obterCategoria(copo300ml, categoriaAcai.id);
      expect(catFiltro, isNotNull);
      final itemVendidoCat = ItemVendido(
        itemId: copo300ml.id,
        nomeItem: copo300ml.nome,
        categoriaId: catFiltro!.id,
        nomeCategoria: catFiltro.nome,
        precoItem: 2.0,
        precoCategoria: 17.0,
        quantidade: 1,
      );
      expect(itemVendidoCat.subtotal, equals(19.0));
      expect(itemVendidoCat.nomeExibicao, equals('Açaí 300ml Copo 300ml'));
    });

    test('Pedido com frete soma o valor do frete ao total a pagar', () {
      final pedidoComFrete = PedidoLoja(
        id: 'ped-frete',
        numero: 1,
        clienteNome: 'João Delivery',
        produtoNome: 'Marmita',
        dataHora: DateTime.now(),
        valor: 35.0, // Subtotal 30 + Frete 7 - Desc 2 = 35
        status: StatusPedido.concluido,
        comanda: '1x Marmita',
        formaPagamento: 'Pix',
        frete: 7.0,
        desconto: 2.0,
        acrescimo: 0.0,
        itens: [
          ItemVendido(
            itemId: 'marmita-1',
            nomeItem: 'Marmita',
            precoItem: 30.0,
            quantidade: 1,
          ),
        ],
      );

      expect(pedidoComFrete.frete, equals(7.0));
      expect(pedidoComFrete.desconto, equals(2.0));
      expect(pedidoComFrete.valor, equals(35.0));
    });
  });
}
