import 'package:flutter_test/flutter_test.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';

void main() {
  group('Filtro de Notificações por Loja e Limpeza em Massa', () {
    test('itensEstoqueBaixoPorLoja retorna apenas alertas da loja especificada', () {
      final pdv = PdvProvider();

      const itemLojaA = ItemLoja(
        id: 'item_a',
        nome: 'Refrigerante',
        preco: '5.00',
      );

      const itemLojaB = ItemLoja(
        id: 'item_b',
        nome: 'Suco',
        preco: '7.00',
      );

      final movEstoqueBaixoA = MovimentoEstoque.novo(
        itemId: 'item_a',
        tipo: TipoMovimentoEstoque.entrada,
        quantidade: 2.0,
      );

      final movEstoqueBaixoB = MovimentoEstoque.novo(
        itemId: 'item_b',
        tipo: TipoMovimentoEstoque.entrada,
        quantidade: 3.0,
      );

      final lojaA = Loja(
        id: 'loja_1',
        nome: 'Loja Centro',
        cnpj: '11.111.111/0001-11',
        telefone: '11999999999',
        endereco: 'Rua A',
        numero: '10',
        email: 'loja1@teste.com',
        categorias: 'Padrão',
        tags: 'bebidas',
        cpfDonoOriginal: '11111111111',
        itensLoja: const [itemLojaA],
        movimentosEstoque: [movEstoqueBaixoA],
      );

      final lojaB = Loja(
        id: 'loja_2',
        nome: 'Loja Bairro',
        cnpj: '22.222.222/0001-22',
        telefone: '11888888888',
        endereco: 'Rua B',
        numero: '20',
        email: 'loja2@teste.com',
        categorias: 'Padrão',
        tags: 'bebidas',
        cpfDonoOriginal: '11111111111',
        itensLoja: const [itemLojaB],
        movimentosEstoque: [movEstoqueBaixoB],
      );

      pdv.adicionarOuAtualizarLoja(lojaA);
      pdv.adicionarOuAtualizarLoja(lojaB);

      // Todos os alertas de todas as lojas
      expect(pdv.todosItensEstoqueBaixo.length, 2);

      // Alertas restritos à Loja 1
      final alertasLoja1 = pdv.itensEstoqueBaixoPorLoja('loja_1');
      expect(alertasLoja1.length, 1);
      expect(alertasLoja1.first.lojaId, 'loja_1');
      expect(alertasLoja1.first.item.id, 'item_a');

      // Alertas restritos à Loja 2
      final alertasLoja2 = pdv.itensEstoqueBaixoPorLoja('loja_2');
      expect(alertasLoja2.length, 1);
      expect(alertasLoja2.first.lojaId, 'loja_2');
      expect(alertasLoja2.first.item.id, 'item_b');

      // Loja inexistente retorna lista vazia
      expect(pdv.itensEstoqueBaixoPorLoja('loja_inexistente').isEmpty, true);
    });

    test('dispensarTodasNaSessao limpa todas as notificações fornecidas de uma só vez', () {
      final notificacoes = NotificacoesProvider();

      final idsParaLimpar = [
        'convite_1',
        'convite_2',
        'alerta_estoque_loja_1_item_a',
        'alerta_estoque_loja_1_item_b',
      ];

      expect(notificacoes.estaDispensadaNaSessao('convite_1'), false);
      expect(notificacoes.estaDispensadaNaSessao('alerta_estoque_loja_1_item_a'), false);

      notificacoes.dispensarTodasNaSessao(idsParaLimpar);

      for (final id in idsParaLimpar) {
        expect(notificacoes.estaDispensadaNaSessao(id), true);
      }

      notificacoes.restaurarDispensadasSessao();
      for (final id in idsParaLimpar) {
        expect(notificacoes.estaDispensadaNaSessao(id), false);
      }
    });
  });
}
