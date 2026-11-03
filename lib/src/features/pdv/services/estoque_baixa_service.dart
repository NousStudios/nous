import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';

/// Serviço soberano e unificado para cálculo e geração de movimentos de estoque
/// decorrentes de vendas, consumo de acompanhamentos e estornos/cancelamentos no PDV.
class EstoqueBaixaService {
  EstoqueBaixaService._();

  /// Gera os movimentos de saída de estoque para os itens vendidos e seus acompanhamentos,
  /// ponderando a quantidade consumida pelo `consumoPorVenda` de cada item cadastrado.
  static List<MovimentoEstoque> calcularMovimentosBaixa({
    required List<ItemVendido> itensVendidos,
    required List<ItemLoja> itensCadastrados,
    required String motivo,
    required String cpfAutor,
    required String nomeAutor,
    CategoriaMovimentoEstoque categoria = CategoriaMovimentoEstoque.venda,
  }) {
    final movimentos = <MovimentoEstoque>[];

    for (final item in itensVendidos) {
      final itemCadastrado =
          itensCadastrados.where((i) => i.id == item.itemId).firstOrNull;
      final consumo = (itemCadastrado != null && itemCadastrado.consumoPorVenda > 0)
          ? itemCadastrado.consumoPorVenda
          : 1.0;
      final qtdBaixar = item.quantidade * consumo;

      movimentos.add(
        MovimentoEstoque.novo(
          itemId: item.itemId,
          tipo: TipoMovimentoEstoque.saida,
          quantidade: qtdBaixar,
          motivo: motivo,
          cpfAutor: cpfAutor,
          nomeAutor: nomeAutor,
          categoria: categoria,
        ),
      );

      for (final acomp in item.acompanhamentos) {
        final acompCadastrado =
            itensCadastrados.where((i) => i.id == acomp.itemId).firstOrNull;
        final consumoAcomp =
            (acompCadastrado != null && acompCadastrado.consumoPorVenda > 0)
                ? acompCadastrado.consumoPorVenda
                : 1.0;
        final qtdAcompBaixar =
            acomp.quantidadePorUnidade * item.quantidade * consumoAcomp;

        movimentos.add(
          MovimentoEstoque.novo(
            itemId: acomp.itemId,
            tipo: TipoMovimentoEstoque.saida,
            quantidade: qtdAcompBaixar,
            motivo: 'Acompanhamento: $motivo',
            cpfAutor: cpfAutor,
            nomeAutor: nomeAutor,
            categoria: categoria,
          ),
        );
      }
    }

    return movimentos;
  }

  /// Gera os movimentos de entrada (estorno) de estoque para os itens e acompanhamentos
  /// de um pedido cancelado ou excluído.
  static List<MovimentoEstoque> calcularMovimentosEstorno({
    required List<ItemVendido> itensVendidos,
    required List<ItemLoja> itensCadastrados,
    required String motivo,
    required String cpfAutor,
    required String nomeAutor,
    CategoriaMovimentoEstoque categoria = CategoriaMovimentoEstoque.ajuste,
  }) {
    final movimentos = <MovimentoEstoque>[];

    for (final item in itensVendidos) {
      final itemCadastrado =
          itensCadastrados.where((i) => i.id == item.itemId).firstOrNull;
      final consumo = (itemCadastrado != null && itemCadastrado.consumoPorVenda > 0)
          ? itemCadastrado.consumoPorVenda
          : 1.0;
      final qtdEstornar = item.quantidade * consumo;

      movimentos.add(
        MovimentoEstoque.novo(
          itemId: item.itemId,
          tipo: TipoMovimentoEstoque.entrada,
          quantidade: qtdEstornar,
          motivo: motivo,
          cpfAutor: cpfAutor,
          nomeAutor: nomeAutor,
          categoria: categoria,
        ),
      );

      for (final acomp in item.acompanhamentos) {
        final acompCadastrado =
            itensCadastrados.where((i) => i.id == acomp.itemId).firstOrNull;
        final consumoAcomp =
            (acompCadastrado != null && acompCadastrado.consumoPorVenda > 0)
                ? acompCadastrado.consumoPorVenda
                : 1.0;
        final qtdAcompEstornar =
            acomp.quantidadePorUnidade * item.quantidade * consumoAcomp;

        movimentos.add(
          MovimentoEstoque.novo(
            itemId: acomp.itemId,
            tipo: TipoMovimentoEstoque.entrada,
            quantidade: qtdAcompEstornar,
            motivo: 'Estorno Acompanhamento: $motivo',
            cpfAutor: cpfAutor,
            nomeAutor: nomeAutor,
            categoria: categoria,
          ),
        );
      }
    }

    return movimentos;
  }
}
