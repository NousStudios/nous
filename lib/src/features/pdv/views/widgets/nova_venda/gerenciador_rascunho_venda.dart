import 'package:flutter/material.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/modelos_nova_venda.dart';

/// Gerenciador de rascunhos temporários de venda mantidos em memória por loja.
class GerenciadorRascunhoVenda {
  static final Map<String, RascunhoVenda> rascunhosPorLoja = {};

  static void limparRascunho(String? lojaId) {
    rascunhosPorLoja.remove(lojaId ?? '');
  }

  static void restaurarRascunho({
    required String? lojaId,
    required Cliente? Function(String id) buscarCliente,
    required TextEditingController clienteController,
    required TextEditingController freteController,
    required TextEditingController descontoController,
    required TextEditingController acrescimoController,
    required List<LinhaCarrinho> carrinho,
    required List<LinhaPagamento> pagamentos,
    required void Function(Cliente? cliente) onClienteRestaurado,
  }) {
    final chaveLoja = lojaId ?? '';
    final rascunho = rascunhosPorLoja[chaveLoja];
    if (rascunho == null) return;

    if (rascunho.clienteId != null) {
      onClienteRestaurado(buscarCliente(rascunho.clienteId!));
    }
    clienteController.text = rascunho.clienteNomeDigitado;
    freteController.text = rascunho.frete;
    descontoController.text = rascunho.desconto;
    acrescimoController.text = rascunho.acrescimo;

    for (final item in rascunho.itens) {
      final linha = LinhaCarrinho(
        chave: item.chave,
        itemId: item.itemId,
        categoriaId: item.categoriaId,
        varianteNome: item.varianteNome,
        precoVariante: item.precoVariante,
        acompanhamentos: Map<String, int>.from(item.acompanhamentos),
      );
      linha.quantidade = item.quantidade;
      linha.observacaoController.text = item.observacao;
      carrinho.add(linha);
    }

    for (final pag in rascunho.pagamentos) {
      pagamentos.add(LinhaPagamento(
        forma: pag.forma,
        valorInicial: pag.valor,
      ));
    }
  }

  static void salvarRascunho({
    required String? lojaId,
    required List<LinhaCarrinho> carrinho,
    required List<LinhaPagamento> pagamentos,
    required Cliente? clienteSelecionado,
    required TextEditingController clienteController,
    required TextEditingController freteController,
    required TextEditingController descontoController,
    required TextEditingController acrescimoController,
  }) {
    final temDados = carrinho.isNotEmpty ||
        pagamentos.isNotEmpty ||
        clienteSelecionado != null ||
        clienteController.text.trim().isNotEmpty ||
        freteController.text.trim().isNotEmpty ||
        descontoController.text.trim().isNotEmpty ||
        acrescimoController.text.trim().isNotEmpty;

    final chaveLoja = lojaId ?? '';
    if (temDados) {
      rascunhosPorLoja[chaveLoja] = RascunhoVenda(
        itens: carrinho.map((linha) {
          return ItemRascunho(
            chave: linha.chave,
            itemId: linha.itemId,
            categoriaId: linha.categoriaId,
            varianteNome: linha.varianteNome,
            precoVariante: linha.precoVariante,
            quantidade: linha.quantidade,
            acompanhamentos: Map<String, int>.from(linha.acompanhamentosPorItemId),
            observacao: linha.observacaoController.text,
          );
        }).toList(),
        pagamentos: pagamentos.map((p) {
          return (forma: p.forma, valor: p.controller.text);
        }).toList(),
        clienteId: clienteSelecionado?.id,
        clienteNomeDigitado: clienteController.text,
        frete: freteController.text,
        desconto: descontoController.text,
        acrescimo: acrescimoController.text,
      );
    } else {
      rascunhosPorLoja.remove(chaveLoja);
    }
  }
}
