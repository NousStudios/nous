import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/services/relatorios/pdf_formatacao_util.dart';

/// Gerador e exportador do Extrato de Compras do Cliente em formato PDF A4.
class ExportadorPdfExtratoCliente {
  static Future<String?> exportar({
    required Loja loja,
    required Cliente cliente,
    required List<PedidoLoja> pedidos,
    String? filtroDescricao,
  }) async {
    final doc = pw.Document();

    final estiloTitulo = pw.TextStyle(
      fontSize: 18,
      fontWeight: pw.FontWeight.bold,
    );
    final estiloSecao = pw.TextStyle(
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
    );
    final estiloCorpo = const pw.TextStyle(fontSize: 10);
    final estiloNegrito = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
    );
    final estiloMiudo = const pw.TextStyle(
      fontSize: 8,
      color: PdfColors.grey700,
    );

    double totalComprado = 0;
    double dividaEmAberto = 0;
    for (final p in pedidos) {
      if (p.status != StatusPedido.cancelado) {
        totalComprado += p.valor;
      }
      if (p.aPrazoEmAberto) {
        dividaEmAberto += p.valorRestante;
      }
    }

    final pedidosOrdenados = [...pedidos]
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          final blocos = <pw.Widget>[];

          // Cabeçalho da Loja
          blocos.add(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        loja.nome.isNotEmpty ? loja.nome : 'Comércio',
                        style: estiloTitulo,
                      ),
                      if (loja.cnpj.isNotEmpty)
                        pw.Text('CNPJ: ${loja.cnpj}', style: estiloCorpo),
                      if (loja.telefone.isNotEmpty)
                        pw.Text('Telefone: ${loja.telefone}', style: estiloCorpo),
                      if (loja.endereco.isNotEmpty)
                        pw.Text(
                          '${loja.endereco}, ${loja.numero}',
                          style: estiloCorpo,
                        ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('EXTRATO DE COMPRAS', style: estiloSecao),
                    pw.SizedBox(height: 4),
                    if (filtroDescricao != null &&
                        filtroDescricao.trim().isNotEmpty) ...[
                      pw.Text(
                        'Filtro: ${filtroDescricao.trim()}',
                        style: estiloMiudo,
                      ),
                      pw.SizedBox(height: 2),
                    ],
                    pw.Text(
                      'Emissão: ${PdfFormatacaoUtil.dataHora(DateTime.now())}',
                      style: estiloMiudo,
                    ),
                    pw.Text('Software Nous', style: estiloMiudo),
                  ],
                ),
              ],
            ),
          );

          blocos.add(pw.SizedBox(height: 12));
          blocos.add(pw.Divider(thickness: 1, color: PdfColors.grey400));
          blocos.add(pw.SizedBox(height: 8));

          // Dados do Cliente & Resumo Financeiro
          blocos.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('DADOS DO CLIENTE', style: estiloSecao),
                        pw.SizedBox(height: 4),
                        pw.Text('Nome: ${cliente.nome}', style: estiloNegrito),
                        if (cliente.cnpj.isNotEmpty)
                          pw.Text('Documento: ${cliente.cnpj}', style: estiloCorpo),
                        if (cliente.telefone.isNotEmpty)
                          pw.Text('Telefone: ${cliente.telefone}', style: estiloCorpo),
                        if (cliente.endereco.isNotEmpty)
                          pw.Text(
                            'Endereço: ${cliente.endereco}, ${cliente.numero}',
                            style: estiloCorpo,
                          ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('RESUMO FINANCEIRO', style: estiloSecao),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Total de Compras: ${pedidosOrdenados.length}',
                          style: estiloCorpo,
                        ),
                        pw.Text(
                          'Total Comprado: ${PdfFormatacaoUtil.valor(totalComprado)}',
                          style: estiloCorpo,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Saldo em Aberto (A Prazo): ${PdfFormatacaoUtil.valor(dividaEmAberto)}',
                          style: pw.TextStyle(
                            fontSize: 10.5,
                            fontWeight: pw.FontWeight.bold,
                            color: dividaEmAberto > 0
                                ? PdfColors.red700
                                : PdfColors.green700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );

          blocos.add(pw.SizedBox(height: 16));
          blocos.add(pw.Text('Histórico de Compras', style: estiloSecao));
          blocos.add(pw.SizedBox(height: 8));

          if (pedidosOrdenados.isEmpty) {
            blocos.add(
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 20),
                child: pw.Center(
                  child: pw.Text(
                    'Nenhum pedido registrado para este cliente.',
                    style: estiloCorpo,
                  ),
                ),
              ),
            );
          } else {
            blocos.add(
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.grey200),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                cellAlignment: pw.Alignment.centerLeft,
                headers: [
                  'Nº',
                  'Data/Hora',
                  'Itens Consumidos',
                  'Pagamento',
                  'Status',
                  'Valor',
                ],
                columnWidths: {
                  0: const pw.FixedColumnWidth(40),
                  1: const pw.FixedColumnWidth(85),
                  2: const pw.FlexColumnWidth(3),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FixedColumnWidth(55),
                  5: const pw.FixedColumnWidth(65),
                },
                data: pedidosOrdenados.map((p) {
                  final itensTexto = p.itens.map((it) {
                    final extras = it.acompanhamentos.isNotEmpty
                        ? ' (+${it.acompanhamentos.map((a) => a.nomeItem).join(', ')})'
                        : '';
                    return '${it.quantidade}x ${it.nomeItem}$extras';
                  }).join('\n');

                  final pagamentosTexto = p.todosPagamentos.isNotEmpty
                      ? p.todosPagamentos
                          .map((pag) => '${pag.forma}: ${PdfFormatacaoUtil.valor(pag.valor)}')
                          .join('\n')
                      : (p.formaPagamento.isNotEmpty
                          ? p.formaPagamento
                          : 'Não inf.');

                  return [
                    PdfFormatacaoUtil.numero(p.numero),
                    PdfFormatacaoUtil.dataHora(p.dataHora),
                    itensTexto.isNotEmpty ? itensTexto : p.produtoNome,
                    pagamentosTexto,
                    PdfFormatacaoUtil.situacao(p.status),
                    PdfFormatacaoUtil.valor(p.valor),
                  ];
                }).toList(),
              ),
            );
          }

          blocos.add(pw.SizedBox(height: 20));
          blocos.add(pw.Divider(thickness: 0.5, color: PdfColors.grey400));
          blocos.add(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Documento não fiscal para conferência e controle.',
                  style: estiloMiudo,
                ),
                pw.Text(
                  'Nous — Software Universal de Autogestão',
                  style: estiloMiudo,
                ),
              ],
            ),
          );

          return blocos;
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

    final nomeSanitizado = cliente.nome
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    return PdfFormatacaoUtil.salvarArquivoPdf(
      bytes: bytes,
      nomeSugerido: 'extrato_${nomeSanitizado}_$sufixo.pdf',
    );
  }
}
