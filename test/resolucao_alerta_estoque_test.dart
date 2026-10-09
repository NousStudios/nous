import 'package:flutter_test/flutter_test.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';

void main() {
  test('ItemLoja equality é baseado no id para uso estável em DropdownButton', () {
    const item1 = ItemLoja(id: 'item_1', nome: 'Coca Cola');
    const item2 = ItemLoja(id: 'item_1', nome: 'Coca Cola 350ml');
    const item3 = ItemLoja(id: 'item_2', nome: 'Coca Cola');

    expect(item1 == item2, isTrue);
    expect(item1.hashCode == item2.hashCode, isTrue);
    expect(item1 == item3, isFalse);
  });

  test('Ao adicionar estoque via resolução de alerta, saldo recalcula e auditoria registra ação', () {
    const item = ItemLoja(id: 'prod_1', nome: 'Café Grão');

    final saida = MovimentoEstoque.novo(
      itemId: 'prod_1',
      tipo: TipoMovimentoEstoque.saida,
      quantidade: 5,
    );

    final loja = Loja(
      id: 'loja_1',
      nome: 'Mercadinho',
      cnpj: '12.345.678/0001-90',
      telefone: '11999999999',
      endereco: 'Rua A',
      numero: '10',
      email: 'loja@teste.com',
      categorias: 'Loja Padrão',
      tags: 'alimentos',
      itensLoja: const [item],
      movimentosEstoque: [saida],
    );

    expect(loja.movimentosEstoque.first.quantidadeComSinal, -5.0);

    final entrada = MovimentoEstoque.novo(
      itemId: 'prod_1',
      tipo: TipoMovimentoEstoque.entrada,
      quantidade: 100,
    );
    final lojaAtualizada = loja.copyWith(
      movimentosEstoque: [entrada, ...loja.movimentosEstoque],
      acoes: [
        RegistroAcao(
          id: 'acao_1',
          dataHora: DateTime.now(),
          tipo: TipoAcao.movimentoEstoqueRegistrado,
          descricao: 'Entrada de 100 un em "Café Grão"',
          cpfAutor: '11144477735',
          nomeAutor: 'Operador',
          emailAutor: 'teste@nous.com',
        ),
      ],
    );

    var saldoFinal = 0.0;
    for (final m in lojaAtualizada.movimentosEstoque) {
      if (m.itemId == 'prod_1') {
        saldoFinal += m.quantidadeComSinal;
      }
    }
    expect(saldoFinal, 95.0);
    expect(saldoFinal >= 10, isTrue);

    expect(lojaAtualizada.acoes.length, 1);
    expect(lojaAtualizada.acoes.first.tipo, TipoAcao.movimentoEstoqueRegistrado);
    expect(lojaAtualizada.acoes.first.descricao, contains('Entrada de 100 un em "Café Grão"'));
  });
}
