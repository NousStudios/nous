import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/modelos_nova_venda.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/baixa_estoque_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/venda_concluida_dialog.dart';

/// Helper responsável pela validação, montagem do pedido e confirmação de conclusão da Nova Venda.
class FinalizadorNovaVenda {
  static const String formaAPrazo = 'À Prazo';

  static double precoComoNumero(String texto) {
    var limpo = texto.replaceAll(RegExp(r'[^0-9,.]'), '');
    if (limpo.contains(',')) {
      limpo = limpo.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(limpo) ?? 0;
  }

  static String valorComVirgula(double valor) =>
      valor.toStringAsFixed(2).replaceAll('.', ',');

  static Future<void> executar({
    required BuildContext context,
    required AppTheme theme,
    required String? lojaId,
    required List<LinhaCarrinho> carrinho,
    required List<LinhaPagamento> pagamentos,
    required Cliente? clienteSelecionado,
    required String clienteNomeDigitado,
    required double subtotalDosItens,
    required double frete,
    required double desconto,
    required double acrescimo,
    required double total,
    required double falta,
    required double troco,
    required bool temAPrazo,
    required String Function() montarComanda,
    required ItemLoja? Function(String id) buscarItem,
    required dynamic Function(String id) buscarCategoria,
    required String nomeVendedor,
    required String cnpjVendedor,
    required int proximoNumero,
    required String cpfAutor,
    required String nomeAutor,
    required ConfiguracoesImpressora configuracoesImpressora,
    required List<ItemLoja> itensDisponiveis,
    required void Function(String aviso) onMostrarAviso,
    required void Function(PedidoLoja pedido, List<MovimentoEstoque> movimentosEstoque) onConcluir,
    required VoidCallback onVendaFinalizadaComSucesso,
  }) async {
    if (carrinho.isEmpty) {
      onMostrarAviso('Adicione ao menos um produto.');
      return;
    }

    if (pagamentos.isEmpty) {
      onMostrarAviso('Escolha ao menos uma forma de pagamento.');
      return;
    }

    if (temAPrazo && clienteSelecionado == null) {
      onMostrarAviso('Selecione um cliente cadastrado para vender a prazo.');
      return;
    }

    if (falta > 0.005) {
      onMostrarAviso(
        'Faltam R\$ ${valorComVirgula(falta)} para completar o pagamento.',
      );
      return;
    }

    if (temAPrazo && troco > 0.005) {
      onMostrarAviso(
        'Não pode haver troco numa venda com pagamento à prazo.',
      );
      return;
    }

    final itensVendidos = <ItemVendido>[];
    for (final linha in carrinho) {
      final item = buscarItem(linha.itemId);
      if (item == null) continue;
      final categoria = linha.categoriaId == null
          ? null
          : buscarCategoria(linha.categoriaId!);
      final acompanhamentos = <AcompanhamentoEscolhido>[];
      linha.acompanhamentosPorItemId.forEach((itemId, quantidade) {
        if (quantidade <= 0) return;
        final acompanhamento = buscarItem(itemId);
        if (acompanhamento == null) return;
        acompanhamentos.add(AcompanhamentoEscolhido(
          itemId: acompanhamento.id,
          nomeItem: acompanhamento.nome,
          precoItem: precoComoNumero(acompanhamento.preco),
          quantidadePorUnidade: quantidade,
        ));
      });
      final precoItem = linha.precoVariante.trim().isNotEmpty
          ? precoComoNumero(linha.precoVariante)
          : precoComoNumero(item.preco);

      itensVendidos.add(ItemVendido(
        itemId: item.id,
        nomeItem: item.nome,
        foto: item.imagens.isNotEmpty ? item.imagens.first : '',
        categoriaId: categoria?.id,
        nomeCategoria: categoria?.nome,
        varianteNome: linha.varianteNome,
        precoItem: precoItem,
        precoCategoria:
            categoria == null ? 0 : precoComoNumero(categoria.preco),
        quantidade: linha.quantidade,
        acompanhamentos: acompanhamentos,
        observacao: linha.observacaoController.text.trim(),
      ));
    }

    final nomes = itensVendidos.map((i) => i.nomeExibicao).toList();
    final resumo = nomes.length > 1
        ? '${nomes.first} +${nomes.length - 1}'
        : (nomes.isEmpty ? 'Venda' : nomes.first);
    final cliente = clienteNomeDigitado.trim();

    final pagamentosPedido = pagamentos
        .map((p) => PagamentoParcial(
              forma: p.forma,
              valor: precoComoNumero(p.controller.text),
            ))
        .toList();

    final formaUnica =
        pagamentosPedido.length == 1 ? pagamentosPedido.first.forma : '';

    final valorPagoNaoPrazo = pagamentosPedido
        .where((p) => p.forma != formaAPrazo)
        .fold<double>(0.0, (s, p) => s + p.valor);

    final totalPagamentos =
        pagamentosPedido.fold<double>(0.0, (s, p) => s + p.valor);
    final trocoCalculado = totalPagamentos - total;
    final trocoFinal = trocoCalculado > 0.005 ? trocoCalculado : 0.0;
    final valorEntradaAVista =
        (valorPagoNaoPrazo - trocoFinal).clamp(0.0, total);

    final pedido = PedidoLoja(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      numero: proximoNumero,
      clienteId: clienteSelecionado?.id,
      clienteNome: cliente.isEmpty ? 'Cliente' : cliente,
      produtoNome: resumo,
      dataHora: DateTime.now(),
      valor: total,
      status: StatusPedido.aceito,
      comanda: montarComanda(),
      formaPagamento: formaUnica,
      pagamentosExtras:
          pagamentosPedido.length > 1 ? pagamentosPedido : const [],
      valorRecebido: valorPagoNaoPrazo,
      troco: trocoFinal,
      quitado: !temAPrazo || valorEntradaAVista >= total,
      valorPago: !temAPrazo ? total : valorEntradaAVista,
      itens: itensVendidos,
      frete: frete,
      desconto: desconto,
      acrescimo: acrescimo,
      nomeVendedor: nomeVendedor,
      cnpjVendedor: cnpjVendedor,
      lojaId: lojaId ?? '',
    );

    final movimentosSugeridos = await BaixaEstoqueDialog.mostrar(
      context,
      theme: theme,
      itensDisponiveis: itensDisponiveis,
      pedido: pedido,
      cpfAutor: cpfAutor,
      nomeAutor: nomeAutor,
    );

    if (!context.mounted) return;
    if (movimentosSugeridos == null) return;

    final confirmou = await VendaConcluidaDialog.mostrar(
      context,
      theme: theme,
      pedido: pedido,
      configuracoesImpressora: configuracoesImpressora,
      cliente: clienteSelecionado,
    );

    if (!context.mounted) return;

    if (confirmou) {
      onVendaFinalizadaComSucesso();
      Navigator.of(context).pop();
      onConcluir(pedido, movimentosSugeridos);
    }
  }
}
