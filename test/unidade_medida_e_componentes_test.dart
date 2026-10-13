import 'package:flutter_test/flutter_test.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';

void main() {
  group('Máscara e Formatação Adaptável de Unidades de Medida', () {
    test('Unidade simples (un) mantém formato inteiro ou decimal', () {
      expect(formatarQuantidadeComUnidade(10, UnidadeItemLoja.un), '10 un');
      expect(formatarQuantidadeComUnidade(1.5, UnidadeItemLoja.un), '1,5 un');
      expect(formatarQuantidadeComUnidade(1000, UnidadeItemLoja.un), '1000 un');
    });

    test('Gramas (g) converte automaticamente para kg quando >= 1000g', () {
      expect(formatarQuantidadeComUnidade(500, UnidadeItemLoja.g), '500 g');
      expect(formatarQuantidadeComUnidade(999, UnidadeItemLoja.g), '999 g');
      expect(formatarQuantidadeComUnidade(1000, UnidadeItemLoja.g), '1 kg');
      expect(formatarQuantidadeComUnidade(1500, UnidadeItemLoja.g), '1,5 kg');
      expect(formatarQuantidadeComUnidade(2250, UnidadeItemLoja.g), '2,25 kg');
      expect(formatarQuantidadeComUnidade(10000, UnidadeItemLoja.g), '10 kg');
    });

    test('Mililitros (ml) converte automaticamente para L quando >= 1000ml', () {
      expect(formatarQuantidadeComUnidade(350, UnidadeItemLoja.ml), '350 ml');
      expect(formatarQuantidadeComUnidade(1000, UnidadeItemLoja.ml), '1 L');
      expect(formatarQuantidadeComUnidade(1500, UnidadeItemLoja.ml), '1,5 L');
      expect(formatarQuantidadeComUnidade(2000, UnidadeItemLoja.ml), '2 L');
    });

    test('Saldos negativos preservam sinal com unidade adaptada', () {
      expect(formatarQuantidadeComUnidade(-1000, UnidadeItemLoja.g), '-1 kg');
      expect(formatarQuantidadeComUnidade(-1500, UnidadeItemLoja.ml), '-1,5 L');
      expect(formatarQuantidadeComUnidade(-5, UnidadeItemLoja.un), '-5 un');
    });
  });

  group('Cálculo de ItemVendido com Grupos de Componentes', () {
    test('ItemVendido calcula subtotal somando preço base e adicionais por unidade', () {
      final item = ItemVendido(
        itemId: 'it1',
        nomeItem: 'Hambúrguer Artesanal',
        precoItem: 25.0,
        precoCategoria: 5.0, // Categoria Gourmet
        quantidade: 2,
        acompanhamentos: const [
          AcompanhamentoEscolhido(
            itemId: 'bacon',
            nomeItem: 'Bacon Extra',
            precoItem: 4.0,
            quantidadePorUnidade: 2, // 2x R$ 4 = R$ 8 por hambúrguer
          ),
          AcompanhamentoEscolhido(
            itemId: 'queijo',
            nomeItem: 'Queijo Cheddar',
            precoItem: 3.0,
            quantidadePorUnidade: 1, // 1x R$ 3 = R$ 3 por hambúrguer
          ),
        ],
      );

      // Preço Base = 25 + 5 = 30
      expect(item.precoBase, 30.0);
      // Total de acompanhamentos por unidade = 8 + 3 = 11
      expect(item.totalDosAcompanhamentosPorUnidade, 11.0);
      // Preço unitário total = 30 + 11 = 41
      expect(item.precoUnitario, 41.0);
      // Subtotal de 2 unidades = 41 * 2 = 82
      expect(item.subtotal, 82.0);
    });

    test('ItemVendido preserva variante e observação e serializa perfeitamente', () {
      final item = ItemVendido(
        itemId: 'copo-400',
        nomeItem: 'Copo 400ml',
        varianteNome: 'Isopor',
        observacao: 'Com tampa extra',
        precoItem: 4.50,
        quantidade: 3,
      );

      expect(item.nomeExibicao, 'Copo 400ml (Isopor)');
      expect(item.observacao, 'Com tampa extra');
      expect(item.subtotal, 13.50);

      final json = item.toJson();
      expect(json['varianteNome'], 'Isopor');
      expect(json['observacao'], 'Com tampa extra');

      final reconstruido = ItemVendido.fromJson(json);
      expect(reconstruido.nomeExibicao, 'Copo 400ml (Isopor)');
      expect(reconstruido.varianteNome, 'Isopor');
      expect(reconstruido.observacao, 'Com tampa extra');
      expect(reconstruido.subtotal, 13.50);
    });
  });

  group('Custo Unitário e Persistência de Compra de Estoque', () {
    test('Cálculo de custo unitário a partir de custo total e quantidade', () {
      const custoTotal = 35.00;
      const quantidade = 50.0;
      final custoUnitario = custoTotal / quantidade;
      expect(custoUnitario, 0.70);

      final custoFormatado =
          custoUnitario.toStringAsFixed(2).replaceAll('.', ',');
      expect(custoFormatado, '0,70');

      final item = const ItemLoja(
        id: 'copo-700',
        nome: 'Copo 700ml',
        preco: '2,50',
        precoCusto: '0,70',
        unidadeBase: UnidadeItemLoja.un,
      );

      expect(item.precoCusto, '0,70');
      final json = item.toJson();
      expect(json['precoCusto'], '0,70');

      final reconstruido = ItemLoja.fromJson(json);
      expect(reconstruido.precoCusto, '0,70');
    });

    test(
        'Movimento de Estoque com custo de entrada calcula total e sincroniza precoCusto',
        () {
      final item = const ItemLoja(
        id: 'copo-700',
        nome: 'Copo 700ml',
        preco: '2,50',
        precoCusto: '',
      );

      final mov = MovimentoEstoque.novo(
        itemId: item.id,
        tipo: TipoMovimentoEstoque.entrada,
        quantidade: 50,
        custoUnitario: 0.70,
      );

      expect(mov.ehEntrada, isTrue);
      expect(mov.custoTotal, 35.00);

      final itemAtualizado = item.copyWith(
        precoCusto: mov.custoUnitario.toStringAsFixed(2).replaceAll('.', ','),
      );

      expect(itemAtualizado.precoCusto, '0,70');
    });
  });
}
