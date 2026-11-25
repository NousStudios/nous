import 'package:flutter/material.dart';
import 'package:nous/src/features/pdv/services/gerador_comprovante_venda.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_venda/finalizador_nova_venda.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_venda/nova_venda_controller.dart';

/// Montagem de comanda e orquestração da finalização da venda.
class NovaVendaFinalizacaoHelper {
  const NovaVendaFinalizacaoHelper._();

  /// Monta o texto da comanda térmica com os dados atuais do controller.
  static String montarComanda(NovaVendaController c) {
    return GeradorComprovanteVenda.montarComandaTexto(
      nomeVendedor: c.nomeVendedor,
      cnpjVendedor: c.cnpjVendedor,
      numeroPedido: c.proximoNumero,
      dataHora: c.dataHora,
      nomeClienteDigitado: c.clienteController.text,
      clienteSelecionado: c.clienteSelecionado,
      deveMostrarCampoCliente: c.deveMostrarCampoCliente,
      carrinho: c.carrinho,
      nomeExibicaoLinha: c.nomeExibicaoDaLinha,
      subtotalBaseLinha: c.subtotalBaseDaLinha,
      buscarItem: c.buscarItem,
      precoComoNumero: NovaVendaController.precoComoNumero,
      valorComVirgula: NovaVendaController.valorComVirgula,
      subtotalDosItens: c.subtotalDosItens,
      frete: c.frete,
      desconto: c.desconto,
      rotuloDesconto: c.rotuloDesconto,
      acrescimo: c.acrescimo,
      rotuloAcrescimo: c.rotuloAcrescimo,
      total: c.total,
      pagamentos: c.pagamentos,
      troco: c.troco,
    );
  }

  /// Executa a validação, geração de pedido/estoque e conclusão da venda.
  static Future<void> concluir(
    NovaVendaController c,
    BuildContext context,
  ) async {
    await FinalizadorNovaVenda.executar(
      context: context,
      theme: c.theme,
      lojaId: c.lojaId,
      carrinho: c.carrinho,
      pagamentos: c.pagamentos,
      clienteSelecionado: c.clienteSelecionado,
      clienteNomeDigitado: c.clienteController.text,
      subtotalDosItens: c.subtotalDosItens,
      frete: c.frete,
      desconto: c.desconto,
      acrescimo: c.acrescimo,
      total: c.total,
      falta: c.falta,
      troco: c.troco,
      temAPrazo: c.temAPrazo,
      montarComanda: c.montarComanda,
      buscarItem: c.buscarItem,
      buscarCategoria: c.buscarCategoria,
      nomeVendedor: c.nomeVendedor,
      cnpjVendedor: c.cnpjVendedor,
      proximoNumero: c.proximoNumero,
      cpfAutor: c.cpfAutor,
      nomeAutor: c.nomeAutor,
      configuracoesImpressora: c.configuracoesImpressora,
      itensDisponiveis: c.itensDisponiveis,
      onMostrarAviso: c.mostrarAviso,
      onConcluir: c.onConcluir,
      onVendaFinalizadaComSucesso: () {
        c.vendaConcluida = true;
        NovaVendaController.limparRascunho(c.lojaId);
      },
    );
  }
}
