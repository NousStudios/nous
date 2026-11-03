import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pagamento_funcionario.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/services/relatorios/exportador_pdf_comanda.dart';
import 'package:nous/src/features/pdv/services/relatorios/exportador_pdf_dre.dart';
import 'package:nous/src/features/pdv/services/relatorios/exportador_pdf_extrato_cliente.dart';
import 'package:nous/src/features/pdv/services/relatorios/exportador_pdf_financeiro.dart';

/// Facade central para geração e exportação de relatórios documentais A4 em PDF.
///
/// Delega as regras de layout e renderização para geradores modulares especializados
/// em `lib/src/features/pdv/services/relatorios/`.
class RelatoriosPdfService {
  /// Gera e exporta uma comanda detalhada do pedido em formato PDF A4.
  static Future<String?> exportarComandaPDF({
    required PedidoLoja pedido,
    required String rodape,
    Cliente? cliente,
    List<String> camposClienteComanda = kCamposClienteComandaPadrao,
  }) =>
      ExportadorPdfComanda.exportar(
        pedido: pedido,
        rodape: rodape,
        cliente: cliente,
        camposClienteComanda: camposClienteComanda,
      );

  /// Gera e exporta o relatório financeiro consolidado do período em formato PDF A4.
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
      ExportadorPdfFinanceiro.exportar(
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

  /// Gera e exporta o Demonstrativo de Resultado do Exercício (DRE) em formato PDF A4.
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
      ExportadorPdfDre.exportar(
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

  /// Gera e exporta o extrato de compras e histórico de um cliente em formato PDF A4.
  static Future<String?> exportarExtratoClientePDF({
    required Loja loja,
    required Cliente cliente,
    required List<PedidoLoja> pedidos,
  }) =>
      ExportadorPdfExtratoCliente.exportar(
        loja: loja,
        cliente: cliente,
        pedidos: pedidos,
      );
}
