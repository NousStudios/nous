import 'package:flutter/foundation.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/compras_usuario_service.dart';

class CarrinhoComprasService {
  CarrinhoComprasService._();

  static final ValueNotifier<int> totalItensNoCarrinho = ValueNotifier<int>(0);
  static final ValueNotifier<ItemVendido?> ultimoItemAdicionado =
      ValueNotifier<ItemVendido?>(null);

  /// Converte string de preço (ex: '12,50' ou 'R$ 12,50') para double com segurança
  static double parsePreco(String raw) {
    final limpo = raw
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();
    // Se tiver formato americano "12.50" sem vírgula, preservar o ponto decimal
    final direto = raw.replaceAll('R\$', '').replaceAll(' ', '').trim();
    if (!direto.contains(',') && direto.contains('.')) {
      return double.tryParse(direto) ?? 0.0;
    }
    return double.tryParse(limpo) ?? 0.0;
  }

  /// Inicializa a contagem de itens em todos os carrinhos de lojas do aparelho
  static Future<void> sincronizarContagemTotal(PdvProvider pdv) async {
    try {
      final carrinhos =
          await ComprasUsuarioService.carregarCarrinhosPendentes(pdv);
      int soma = 0;
      for (final c in carrinhos) {
        soma += c.quantidadeTotal;
      }
      totalItensNoCarrinho.value = soma;
    } catch (_) {}
  }

  /// Adiciona um produto com variante, acompanhamentos e quantidade ao carrinho da loja correspondente
  static Future<bool> adicionarProduto({
    required PdvProvider pdv,
    required Loja loja,
    required ItemLoja item,
    VarianteItem? variante,
    List<AcompanhamentoEscolhido> acompanhamentos = const [],
    int quantidade = 1,
    String observacao = '',
  }) async {
    try {
      final precoVariante =
          variante != null ? parsePreco(variante.preco) : 0.0;
      final precoReal =
          precoVariante > 0 ? precoVariante : parsePreco(item.preco);

      final nomeVariante = variante?.nome ?? '';
      final fotoReal = item.imagens.isNotEmpty ? item.imagens.first : '';
      final categoria = loja.categoriasLoja
          .where((c) => c.itemIds.contains(item.id))
          .firstOrNull;

      final itemVendido = ItemVendido(
        itemId: item.id,
        nomeItem: item.nome,
        foto: fotoReal,
        categoriaId: categoria?.id,
        nomeCategoria: categoria?.nome,
        varianteNome: nomeVariante,
        precoItem: precoReal,
        quantidade: quantidade.clamp(1, 999),
        acompanhamentos: acompanhamentos,
        observacao: observacao,
      );

      final carrinhosAtuais =
          await ComprasUsuarioService.carregarCarrinhosPendentes(pdv);
      final carrinhoLoja =
          carrinhosAtuais.where((c) => c.lojaId == loja.id).firstOrNull;

      final itens = <ItemVendido>[];
      if (carrinhoLoja != null) {
        itens.addAll(carrinhoLoja.itens);
      }

      bool mesmosAcompanhamentos(
        List<AcompanhamentoEscolhido> a,
        List<AcompanhamentoEscolhido> b,
      ) {
        if (a.length != b.length) return false;
        final mapA = {for (final x in a) x.itemId: x.quantidadePorUnidade};
        for (final y in b) {
          if (mapA[y.itemId] != y.quantidadePorUnidade) return false;
        }
        return true;
      }

      final idxExistente = itens.indexWhere(
        (i) =>
            i.itemId == item.id &&
            i.varianteNome == nomeVariante &&
            mesmosAcompanhamentos(i.acompanhamentos, acompanhamentos),
      );

      if (idxExistente >= 0) {
        final atual = itens[idxExistente];
        itens[idxExistente] = atual.copyWith(
          quantidade: atual.quantidade + quantidade,
        );
      } else {
        itens.add(itemVendido);
      }

      await ComprasUsuarioService.salvarCarrinhoPendente(loja.id, itens);
      await sincronizarContagemTotal(pdv);
      ultimoItemAdicionado.value = itemVendido;

      return true;
    } catch (e) {
      debugPrint(
          '[CarrinhoComprasService] Erro ao adicionar item ao carrinho: $e');
      return false;
    }
  }

  /// Remove ou altera a quantidade de um item no carrinho de uma loja
  static Future<void> atualizarQuantidadeItem({
    required PdvProvider pdv,
    required String lojaId,
    required String itemId,
    required String varianteNome,
    required int novaQuantidade,
  }) async {
    final carrinhos =
        await ComprasUsuarioService.carregarCarrinhosPendentes(pdv);
    final carrinho = carrinhos.where((c) => c.lojaId == lojaId).firstOrNull;
    if (carrinho == null) return;

    final itens = List<ItemVendido>.from(carrinho.itens);
    final idx = itens.indexWhere(
      (i) => i.itemId == itemId && i.varianteNome == varianteNome,
    );

    if (idx >= 0) {
      if (novaQuantidade <= 0) {
        itens.removeAt(idx);
      } else {
        itens[idx] = itens[idx].copyWith(quantidade: novaQuantidade);
      }
      await ComprasUsuarioService.salvarCarrinhoPendente(lojaId, itens);
      await sincronizarContagemTotal(pdv);
    }
  }

  /// Limpa todos os itens do carrinho de uma loja específica
  static Future<void> limparCarrinhoLoja({
    required PdvProvider pdv,
    required String lojaId,
  }) async {
    await ComprasUsuarioService.salvarCarrinhoPendente(lojaId, []);
    await sincronizarContagemTotal(pdv);
  }
}
