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
  });
}
