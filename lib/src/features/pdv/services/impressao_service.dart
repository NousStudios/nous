import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pagamento_funcionario.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/turno_caixa.dart';
import 'package:nous/src/features/pdv/services/relatorios_pdf_service.dart';
import 'package:nous/src/features/pdv/services/impressao/impressao_utils.dart';
import 'package:nous/src/features/pdv/services/impressao/gerador_bobina_comanda.dart';
import 'package:nous/src/features/pdv/services/impressao/gerador_bobina_caixa.dart';
import 'package:nous/src/features/pdv/services/impressao/gerador_bobina_mesa.dart';
import 'package:nous/src/features/pdv/services/impressao/gerador_bobina_financeiro.dart';

class ImpressaoService {
  static PdfPageFormat formatoPapel(ConfiguracoesImpressora? config) =>
      ImpressaoUtils.formatoPapel(config);

  static Future<List<Printer>> listarImpressoras() async {
    try {
      return await Printing.listPrinters();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> imprimirTeste({
    required ConfiguracoesImpressora config,
  }) =>
      GeradorBobinaComanda.imprimirTeste(config: config);

  static Future<void> imprimirExemploComanda({
    required ConfiguracoesImpressora config,
    required String cliente,
    String? cnpj,
    String? telefone,
    String? endereco,
    String? email,
    String? redesSociais,
    String? descricao,
    required List<MapEntry<String, double>> itens,
    required String pagamento,
    String? rodape,
  }) =>
      GeradorBobinaComanda.imprimirExemploComanda(
        config: config,
        cliente: cliente,
        cnpj: cnpj,
        telefone: telefone,
        endereco: endereco,
        email: email,
        redesSociais: redesSociais,
        descricao: descricao,
        itens: itens,
        pagamento: pagamento,
        rodape: rodape,
      );

  static Future<void> imprimirComandaPedido({
    required ConfiguracoesImpressora config,
    required PedidoLoja pedido,
    Cliente? cliente,
    List<String>? camposClienteComanda,
  }) =>
      GeradorBobinaComanda.imprimirComandaPedido(
        config: config,
        pedido: pedido,
        cliente: cliente,
        camposClienteComanda:
            camposClienteComanda ?? config.camposClienteComanda,
      );

  static Future<void> imprimirComanda({
    required ConfiguracoesImpressora config,
    required PedidoLoja pedido,
    Cliente? cliente,
    List<String>? camposClienteComanda,
  }) =>
      imprimirComandaPedido(
        config: config,
        pedido: pedido,
        cliente: cliente,
        camposClienteComanda:
            camposClienteComanda ?? config.camposClienteComanda,
      );

  static Future<void> imprimirFechamentoCaixa({
    required ConfiguracoesImpressora config,
    required String lojaNome,
    required String lojaCnpj,
    required TurnoCaixa turno,
    required double vendasDinheiro,
    required double vendasOutros,
    double vendasAPrazo = 0.0,
    required double saldoEsperado,
    required double saldoInformado,
    String observacao = '',
  }) =>
      GeradorBobinaCaixa.imprimirFechamentoCaixa(
        config: config,
        lojaNome: lojaNome,
        lojaCnpj: lojaCnpj,
        turno: turno,
        vendasDinheiro: vendasDinheiro,
        vendasOutros: vendasOutros,
        vendasAPrazo: vendasAPrazo,
        saldoEsperado: saldoEsperado,
        saldoInformado: saldoInformado,
        observacao: observacao,
      );

  static Future<void> imprimirMovimentoCaixa({
    required ConfiguracoesImpressora config,
    required String lojaNome,
    required String lojaCnpj,
    required TipoMovimentoCaixa tipo,
    required double valor,
    required String motivo,
    required DateTime dataHora,
    String operadorNome = '',
  }) =>
      GeradorBobinaCaixa.imprimirMovimentoCaixa(
        config: config,
        lojaNome: lojaNome,
        lojaCnpj: lojaCnpj,
        tipo: tipo,
        valor: valor,
        motivo: motivo,
        dataHora: dataHora,
        operadorNome: operadorNome,
      );

  static Future<void> imprimirConferenciaMesa({
    required ConfiguracoesImpressora config,
    required MesaLoja mesa,
    required String nomeLoja,
  }) =>
      GeradorBobinaMesa.imprimirConferenciaMesa(
        config: config,
        mesa: mesa,
        nomeLoja: nomeLoja,
      );

  static Future<void> imprimirFinanceiro({
    required ConfiguracoesImpressora config,
    required Loja loja,
    required String periodo,
    required List<PedidoLoja> vendas,
    required List<PedidoLoja> pedidosAceitos,
    required List<PagamentoFuncionario> pagamentos,
    required List<MovimentoEstoque> movimentos,
    required double saidaEstoque,
    required bool contarEstoque,
  }) =>
      GeradorBobinaFinanceiro.imprimirFinanceiro(
        config: config,
        loja: loja,
        periodo: periodo,
        vendas: vendas,
        pedidosAceitos: pedidosAceitos,
        pagamentos: pagamentos,
        movimentos: movimentos,
        saidaEstoque: saidaEstoque,
        contarEstoque: contarEstoque,
      );

  /// Exporta o pedido em formato PDF A4.
  /// Delegado para [RelatoriosPdfService.exportarComandaPDF].
  static Future<String?> exportarComandaPDF({
    required PedidoLoja pedido,
    required String rodape,
    Cliente? cliente,
    List<String> camposClienteComanda = kCamposClienteComandaPadrao,
  }) =>
      RelatoriosPdfService.exportarComandaPDF(
        pedido: pedido,
        rodape: rodape,
        cliente: cliente,
        camposClienteComanda: camposClienteComanda,
      );

  /// Exporta o relatório financeiro do período em PDF A4.
  /// Delegado para [RelatoriosPdfService.exportarFinanceiroPDF].
  static Future<String?> exportarFinanceiroPDF({
    required Loja loja,
    required String periodo,
    required String rodape,
    required List<PedidoLoja> vendas,
    required List<PedidoLoja> pedidosAceitos,
    required List<PagamentoFuncionario> pagamentos,
    required List<MovimentoEstoque> movimentos,
    required double saidaEstoque,
    required bool contarEstoque,
  }) =>
      RelatoriosPdfService.exportarFinanceiroPDF(
        loja: loja,
        periodo: periodo,
        rodape: rodape,
        vendas: vendas,
        pedidosAceitos: pedidosAceitos,
        pagamentos: pagamentos,
        movimentos: movimentos,
        saidaEstoque: saidaEstoque,
        contarEstoque: contarEstoque,
      );

  /// Exporta o Demonstrativo de Resultado do Exercício (DRE) em PDF A4.
  /// Delegado para [RelatoriosPdfService.exportarDREPDF].
  static Future<String?> exportarDREPDF({
    required Loja loja,
    required String periodo,
    required double receita,
    required double cmv,
    required double lucroBruto,
    required double margemBruta,
    required double despesasPessoal,
    required double resultadoLiquido,
    required double margemLiquida,
    required String rodape,
  }) =>
      RelatoriosPdfService.exportarDREPDF(
        loja: loja,
        periodo: periodo,
        receita: receita,
        cmv: cmv,
        lucroBruto: lucroBruto,
        margemBruta: margemBruta,
        despesasPessoal: despesasPessoal,
        resultadoLiquido: resultadoLiquido,
        margemLiquida: margemLiquida,
        rodape: rodape,
      );

  /// Exporta o extrato analítico de compras e débitos do cliente em PDF A4.
  /// Delegado para [RelatoriosPdfService.exportarExtratoClientePDF].
  static Future<String?> exportarExtratoClientePDF({
    required Loja loja,
    required Cliente cliente,
    required List<PedidoLoja> pedidos,
  }) =>
      RelatoriosPdfService.exportarExtratoClientePDF(
        loja: loja,
        cliente: cliente,
        pedidos: pedidos,
      );
}