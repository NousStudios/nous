import 'package:flutter/widgets.dart';

/// Representa um item salvo em rascunho de uma nova venda no PDV.
class ItemRascunho {
  final String chave;
  final String itemId;
  final String? categoriaId;
  final String varianteNome;
  final String precoVariante;
  final int quantidade;
  final Map<String, int> acompanhamentos;
  final String observacao;

  const ItemRascunho({
    required this.chave,
    required this.itemId,
    this.categoriaId,
    this.varianteNome = '',
    this.precoVariante = '',
    required this.quantidade,
    required this.acompanhamentos,
    required this.observacao,
  });
}

/// Representa o estado serializado/persistido temporariamente de uma nova venda em andamento.
class RascunhoVenda {
  final List<ItemRascunho> itens;
  final List<({String forma, String valor})> pagamentos;
  final String? clienteId;
  final String clienteNomeDigitado;
  final String frete;
  final String desconto;
  final String acrescimo;

  const RascunhoVenda({
    required this.itens,
    required this.pagamentos,
    this.clienteId,
    this.clienteNomeDigitado = '',
    required this.frete,
    required this.desconto,
    required this.acrescimo,
  });
}

/// Representa uma linha de item adicionado ao carrinho da tela de Nova Venda.
class LinhaCarrinho {
  final String chave;
  final String itemId;
  final String? categoriaId;
  final String varianteNome;
  final String precoVariante;
  int quantidade;
  final Map<String, int> acompanhamentosPorItemId;
  final TextEditingController observacaoController;

  LinhaCarrinho({
    required this.chave,
    required this.itemId,
    this.categoriaId,
    this.varianteNome = '',
    this.precoVariante = '',
    Map<String, int>? acompanhamentos,
  })  : quantidade = 1,
        acompanhamentosPorItemId = acompanhamentos ?? {},
        observacaoController = TextEditingController();

  void dispose() {
    observacaoController.dispose();
  }
}

/// Representa uma linha de pagamento preenchida no fechamento da venda.
class LinhaPagamento {
  final String forma;
  final TextEditingController controller;

  LinhaPagamento({required this.forma, String valorInicial = ''})
      : controller = TextEditingController(text: valorInicial);

  void dispose() {
    controller.dispose();
  }
}
