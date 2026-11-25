import 'package:flutter/material.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/modelos_nova_venda.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_venda/calculadora_nova_venda.dart';

/// Cálculos financeiros de totais, rótulos e gestão das formas de pagamento da venda.
class NovaVendaPagamentoHelper {
  const NovaVendaPagamentoHelper._();

  /// Formata o rótulo de desconto ou acréscimo indicando percentual quando aplicável.
  static String rotuloAjuste(String textoCampo, String rotuloPadrao) {
    final limpo = textoCampo.trim();
    if (limpo.contains('%')) {
      return '$rotuloPadrao ($limpo)';
    }
    return rotuloPadrao;
  }

  /// Calcula o total líquido da venda garantindo piso zero.
  static double calcularTotal({
    required double subtotalDosItens,
    required double frete,
    required double acrescimo,
    required double desconto,
  }) {
    final total = subtotalDosItens + frete + acrescimo - desconto;
    return total < 0 ? 0 : total;
  }

  /// Soma os valores informados em todas as linhas de pagamento.
  static double somaTotalPagamentos(List<LinhaPagamento> pagamentos) {
    var soma = 0.0;
    for (final pagamento in pagamentos) {
      soma += CalculadoraNovaVenda.precoComoNumero(pagamento.controller.text);
    }
    return soma;
  }

  /// Calcula quanto falta pagar considerando o total e a soma dos pagamentos.
  static double calcularFalta({
    required double total,
    required double somaPagamentos,
  }) {
    final falta = total - somaPagamentos;
    return falta < 0 ? 0.0 : falta;
  }

  /// Calcula o troco devido considerando a soma dos pagamentos e o total.
  static double calcularTroco({
    required double total,
    required double somaPagamentos,
  }) {
    final troco = somaPagamentos - total;
    return troco < 0 ? 0.0 : troco;
  }

  /// Remove uma forma de pagamento pelo nome e libera seu controller.
  static void removerForma({
    required List<LinhaPagamento> pagamentos,
    required String forma,
  }) {
    final indice = pagamentos.indexWhere((p) => p.forma == forma);
    if (indice == -1) return;
    pagamentos[indice].dispose();
    pagamentos.removeAt(indice);
  }

  /// Recalcula o valor da linha "À Prazo" com base no restante não coberto pelas demais formas.
  static void recalcularPrazo({
    required List<LinhaPagamento> pagamentos,
    required String formaAPrazo,
    required double total,
  }) {
    if (!pagamentos.any((p) => p.forma == formaAPrazo)) return;
    final outras = pagamentos
        .where((p) => p.forma != formaAPrazo)
        .fold<double>(
          0.0,
          (s, p) => s + CalculadoraNovaVenda.precoComoNumero(p.controller.text),
        );
    final restante = total - outras;
    final valorAPrazo = restante < 0 ? 0.0 : restante;
    final indice = pagamentos.indexWhere((p) => p.forma == formaAPrazo);
    if (indice != -1) {
      pagamentos[indice].controller.text =
          CalculadoraNovaVenda.valorComVirgula(valorAPrazo);
    }
  }

  /// Alterna ou adiciona uma forma de pagamento, retornando uma mensagem de aviso se inválida.
  static String? escolherForma({
    required String forma,
    required String formaAPrazo,
    required List<LinhaPagamento> pagamentos,
    required Cliente? clienteSelecionado,
    required double total,
  }) {
    final jaTem = pagamentos.any((p) => p.forma == forma);
    if (jaTem) {
      removerForma(pagamentos: pagamentos, forma: forma);
      recalcularPrazo(
        pagamentos: pagamentos,
        formaAPrazo: formaAPrazo,
        total: total,
      );
      return null;
    }

    if (forma == formaAPrazo && clienteSelecionado == null) {
      return 'Selecione um cliente cadastrado para vender a prazo.';
    }

    final String valorInicial;
    if (forma == formaAPrazo) {
      valorInicial = '0,00';
    } else {
      final outras = pagamentos
          .where((p) => p.forma != formaAPrazo)
          .fold<double>(
            0.0,
            (s, p) => s + CalculadoraNovaVenda.precoComoNumero(p.controller.text),
          );
      final restante = total - outras;
      final valor = restante < 0 ? 0.0 : restante;
      valorInicial = CalculadoraNovaVenda.valorComVirgula(valor);
    }

    final novoPagamento = LinhaPagamento(
      forma: forma,
      valorInicial: valorInicial,
    );
    novoPagamento.controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: novoPagamento.controller.text.length,
    );
    pagamentos.add(novoPagamento);

    recalcularPrazo(
      pagamentos: pagamentos,
      formaAPrazo: formaAPrazo,
      total: total,
    );
    return null;
  }
}
