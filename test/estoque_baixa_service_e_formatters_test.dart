import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nous/src/core/utils/texto_formatters.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/services/estoque_baixa_service.dart';

void main() {
  group('EstoqueBaixaService - Baixa e Estorno Centralizados', () {
    const itemPizza = ItemLoja(
      id: 'item-pizza',
      nome: 'Pizza Grande',
      preco: '50.00',
      consumoPorVenda: 1.0,
    );

    const itemQueijo = ItemLoja(
      id: 'item-queijo',
      nome: 'Mussarela Extra',
      preco: '5.00',
      consumoPorVenda: 150.0, // consome 150g por porção
    );

    const itemFarinha = ItemLoja(
      id: 'item-farinha',
      nome: 'Farinha Especial',
      preco: '10.00',
      consumoPorVenda: 250.0, // consome 250g por pizza
    );

    test('calcularMovimentosBaixa debita item e acompanhamentos com consumo ponderado', () {
      final itensVendidos = [
        const ItemVendido(
          itemId: 'item-farinha',
          nomeItem: 'Farinha Especial',
          precoItem: 10.0,
          quantidade: 2, // 2 pizzas = 2 x 250g = 500g
          acompanhamentos: [
            AcompanhamentoEscolhido(
              itemId: 'item-queijo',
              nomeItem: 'Mussarela Extra',
              quantidadePorUnidade: 2, // 2 porções extras por pizza = 2 x 2 x 150g = 600g
              precoItem: 5.0,
            ),
          ],
        ),
      ];

      final movimentos = EstoqueBaixaService.calcularMovimentosBaixa(
        itensVendidos: itensVendidos,
        itensCadastrados: [itemPizza, itemQueijo, itemFarinha],
        motivo: 'Venda Balcão #101',
        cpfAutor: '00000000000',
        nomeAutor: 'Operador Teste',
      );

      expect(movimentos.length, 2);

      // Movimento do item principal
      expect(movimentos[0].itemId, itemFarinha.id);
      expect(movimentos[0].tipo, TipoMovimentoEstoque.saida);
      expect(movimentos[0].quantidade, 500.0);
      expect(movimentos[0].categoria, CategoriaMovimentoEstoque.venda);

      // Movimento do acompanhamento
      expect(movimentos[1].itemId, itemQueijo.id);
      expect(movimentos[1].tipo, TipoMovimentoEstoque.saida);
      expect(movimentos[1].quantidade, 600.0);
      expect(movimentos[1].motivo, contains('Acompanhamento'));
    });

    test('calcularMovimentosEstorno credita itens e acompanhamentos com ponderação idêntica', () {
      final itensVendidos = [
        const ItemVendido(
          itemId: 'item-farinha',
          nomeItem: 'Farinha Especial',
          precoItem: 10.0,
          quantidade: 1, // 1 x 250g = 250g
          acompanhamentos: [
            AcompanhamentoEscolhido(
              itemId: 'item-queijo',
              nomeItem: 'Mussarela Extra',
              quantidadePorUnidade: 1, // 1 x 1 x 150g = 150g
              precoItem: 5.0,
            ),
          ],
        ),
      ];

      final movimentos = EstoqueBaixaService.calcularMovimentosEstorno(
        itensVendidos: itensVendidos,
        itensCadastrados: [itemPizza, itemQueijo, itemFarinha],
        motivo: 'Estorno Cancelamento',
        cpfAutor: '00000000000',
        nomeAutor: 'Gerente Teste',
      );

      expect(movimentos.length, 2);
      expect(movimentos[0].tipo, TipoMovimentoEstoque.entrada);
      expect(movimentos[0].quantidade, 250.0);
      expect(movimentos[0].categoria, CategoriaMovimentoEstoque.ajuste);

      expect(movimentos[1].tipo, TipoMovimentoEstoque.entrada);
      expect(movimentos[1].quantidade, 150.0);
      expect(movimentos[1].categoria, CategoriaMovimentoEstoque.ajuste);
    });
  });

  group('PrimeiraLetraMaiusculaFormatter', () {
    final formatter = PrimeiraLetraMaiusculaFormatter();

    test('formata primeira letra das palavras em maiúscula', () {
      const entrada = 'joao silva-santos d\'avila';
      final resultado = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(
          text: entrada,
          selection: TextSelection.collapsed(offset: entrada.length),
        ),
      );

      expect(resultado.text, 'Joao Silva-Santos D\'Avila');
    });
  });
}
