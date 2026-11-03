import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/services/relatorios/pdf_formatacao_util.dart';

/// Gerador e exportador do Demonstrativo de Resultado do Exercício (DRE) em PDF A4.
class ExportadorPdfDre {
  static Future<String?> exportar({
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
  }) async {
    final doc = pw.Document();

    final estiloTitulo = pw.TextStyle(
      fontSize: 18,
      fontWeight: pw.FontWeight.bold,
    );
    final estiloMiudo = const pw.TextStyle(
      fontSize: 9,
      color: PdfColors.grey700,
    );

    pw.Widget linhaDRE(
      String descricao,
      String valor, {
      bool destaque = false,
      bool subtrair = false,
      bool resultado = false,
      PdfColor? corValor,
    }) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              descricao,
              style: pw.TextStyle(
                fontSize: resultado ? 12 : 11,
                fontWeight:
                    destaque || resultado ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
            pw.Text(
              valor,
              style: pw.TextStyle(
                fontSize: resultado ? 12 : 11,
                fontWeight:
                    destaque || resultado ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: corValor,
              ),
            ),
          ],
        ),
      );
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) {
          final blocos = <pw.Widget>[];

          blocos.add(
            pw.Center(
              child: pw.Text(
                'Demonstrativo de Resultado do Exercício (DRE)',
                style: estiloTitulo,
              ),
            ),
          );

          if (loja.nome.isNotEmpty) {
            blocos.add(
              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 4),
                  child: pw.Text(
                    loja.nome,
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }

          if (loja.cnpj.isNotEmpty) {
            blocos.add(
              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text('CNPJ: ${loja.cnpj}', style: estiloMiudo),
                ),
              ),
            );
          }

          blocos.add(
            pw.Center(
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(top: 6),
                child: pw.Text(
                  'Período: $periodo • Emitido em ${PdfFormatacaoUtil.dataHora(DateTime.now())}',
                  style: estiloMiudo,
                ),
              ),
            ),
          );

          blocos.add(pw.SizedBox(height: 20));
          blocos.add(pw.Divider(thickness: 1.2));
          blocos.add(pw.SizedBox(height: 12));

          blocos.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  linhaDRE(
                    '1. Receita Operacional Bruta',
                    PdfFormatacaoUtil.valor(receita),
                    destaque: true,
                  ),
                  pw.SizedBox(height: 4),
                  linhaDRE(
                    '2. (-) Custo dos Produtos / Insumos (CMV)',
                    PdfFormatacaoUtil.valor(cmv),
                    subtrair: true,
                  ),
                  pw.Divider(color: PdfColors.grey300),
                  linhaDRE(
                    '3. (=) Lucro Operacional Bruto',
                    PdfFormatacaoUtil.valor(lucroBruto),
                    destaque: true,
                    resultado: true,
                    corValor: lucroBruto < 0 ? PdfColors.red800 : null,
                  ),
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      'Margem Bruta: ${margemBruta.toStringAsFixed(1)}%',
                      style: estiloMiudo,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  linhaDRE(
                    '4. (-) Pagamentos a Trabalhadores',
                    PdfFormatacaoUtil.valor(despesasPessoal),
                    subtrair: true,
                  ),
                  pw.Divider(color: PdfColors.grey400, thickness: 1.2),
                  linhaDRE(
                    '5. (=) Resultado Líquido do Período',
                    PdfFormatacaoUtil.valor(resultadoLiquido),
                    destaque: true,
                    resultado: true,
                    corValor:
                        resultadoLiquido < 0 ? PdfColors.red800 : PdfColors.green800,
                  ),
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      'Margem Líquida: ${margemLiquida.toStringAsFixed(1)}%',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: resultadoLiquido < 0
                            ? PdfColors.red800
                            : PdfColors.grey800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

          blocos.add(pw.SizedBox(height: 24));
          blocos.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Text(
                'Nota de Transparência e Autogestão: O Demonstrativo de Resultado (DRE) sintetiza o desempenho operacional e cooperativo do negócio no período, sem camuflagem de custos ou perdas, proporcionando visibilidade equitativa para toda a comunidade trabalhadora.',
                style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          );

          if (rodape.isNotEmpty) {
            blocos.add(pw.SizedBox(height: 18));
            for (final l in rodape.split('\n')) {
              blocos.add(
                pw.Center(
                  child: pw.Text(l, style: estiloMiudo),
                ),
              );
            }
          }

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: blocos,
          );
        },
      ),
    );

    final bytes = await doc.save();

    final agora = DateTime.now();
    final sufixo =
        '${agora.year}${agora.month.toString().padLeft(2, '0')}'
        '${agora.day.toString().padLeft(2, '0')}_'
        '${agora.hour.toString().padLeft(2, '0')}'
        '${agora.minute.toString().padLeft(2, '0')}';

    return PdfFormatacaoUtil.salvarArquivoPdf(
      bytes: bytes,
      nomeSugerido: 'dre_$sufixo.pdf',
    );
  }
}
