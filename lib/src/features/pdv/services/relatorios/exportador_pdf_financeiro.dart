import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pagamento_funcionario.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/services/relatorios/pdf_formatacao_util.dart';

/// Gerador e exportador do Relatório Financeiro e Orçamentário em formato PDF A4.
class ExportadorPdfFinanceiro {
  static Future<String?> exportar({
    required Loja loja,
    required String periodo,
    required String rodape,
    required List<PedidoLoja> vendas,
    required List<PedidoLoja> pedidosAceitos,
    required List<PagamentoFuncionario> pagamentos,
    required List<MovimentoEstoque> movimentos,
    required double saidaEstoque,
    required bool contarEstoque,
  }) async {
    final doc = pw.Document();

    final estiloTitulo = pw.TextStyle(
      fontSize: 20,
      fontWeight: pw.FontWeight.bold,
    );
    final estiloSecao = pw.TextStyle(
      fontSize: 13,
      fontWeight: pw.FontWeight.bold,
    );
    final estiloCorpo = const pw.TextStyle(fontSize: 11);
    final estiloMiudo = const pw.TextStyle(
      fontSize: 9,
      color: PdfColors.grey700,
    );

    final entradasPorForma = <String, double>{
      for (final f in kFormasDePagamento) f: 0.0,
    };
    for (final p in vendas) {
      for (final pag in p.todosPagamentos) {
        final ehPrazo = pag.forma.trim().toLowerCase() == 'à prazo' ||
            pag.forma.trim().toLowerCase() == 'a prazo' ||
            pag.forma.toLowerCase().contains('prazo');
        final chave = ehPrazo ? 'À Prazo' : pag.forma;
        entradasPorForma[chave] =
            (entradasPorForma[chave] ?? 0) + pag.valor;
      }
    }

    double totalEntradas = 0;
    for (final v in entradasPorForma.values) {
      totalEntradas += v;
    }
    double totalAReceber = 0;
    for (final p in pedidosAceitos) {
      totalAReceber += p.valor;
    }
    for (final p in vendas) {
      if (p.aPrazoEmAberto) {
        totalAReceber += p.valorRestante;
      }
    }
    double totalPagamentos = 0;
    for (final p in pagamentos) {
      totalPagamentos += p.valor;
    }
    final totalSaidas =
        totalPagamentos + (contarEstoque ? saidaEstoque : 0);
    final saldo = totalEntradas - totalSaidas;

    final comprasPorFornecedor =
        PdfFormatacaoUtil.comprasPorFornecedor(movimentos);
    final comprasOrdenadas = comprasPorFornecedor.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    double totalCompras = 0;
    for (final e in comprasOrdenadas) {
      totalCompras += e.value;
    }

    final vendasOrdenadas = [...vendas]
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));
    final pagamentosOrdenados = [...pagamentos]
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));
    final movimentosOrdenados = [...movimentos]
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));

    pw.Widget linhaDupla(
      String rotulo,
      String valor, {
      bool negrito = false,
    }) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 220,
              child: pw.Text(
                rotulo,
                style: negrito
                    ? pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      )
                    : estiloCorpo,
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                valor,
                style: negrito
                    ? pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      )
                    : estiloCorpo,
              ),
            ),
          ],
        ),
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          final blocos = <pw.Widget>[];

          blocos.add(
            pw.Center(
              child: pw.Text('Relatório Financeiro', style: estiloTitulo),
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
                      fontSize: 14,
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
                  child: pw.Text(
                    'CNPJ: ${loja.cnpj}',
                    style: estiloMiudo,
                  ),
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

          blocos.add(pw.SizedBox(height: 16));
          blocos.add(pw.Divider());
          blocos.add(pw.SizedBox(height: 8));

          blocos.add(
            pw.Text('Entradas por forma de pagamento', style: estiloSecao),
          );
          blocos.add(pw.SizedBox(height: 6));
          for (final forma in kFormasDePagamento) {
            blocos.add(
              linhaDupla(forma, PdfFormatacaoUtil.valor(entradasPorForma[forma] ?? 0)),
            );
          }
          blocos.add(
            linhaDupla('Total de entradas', PdfFormatacaoUtil.valor(totalEntradas),
                negrito: true),
          );

          if (vendasOrdenadas.isNotEmpty) {
            blocos.add(pw.SizedBox(height: 16));
            blocos.add(
              pw.Text('Vendas do período', style: estiloSecao),
            );
            blocos.add(pw.SizedBox(height: 6));
            for (final v in vendasOrdenadas) {
              blocos.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              '${PdfFormatacaoUtil.numero(v.numero)} • ${v.clienteNome}',
                              style: estiloCorpo,
                            ),
                          ),
                          pw.Text(PdfFormatacaoUtil.valor(v.valor),
                              style: estiloCorpo),
                        ],
                      ),
                      pw.Text(
                        '${PdfFormatacaoUtil.dataHora(v.dataHora)}'
                        '${v.todosPagamentos.isNotEmpty ? ' • ${v.todosPagamentos.map((p) => p.forma).where((f) => f.isNotEmpty).join(' + ')}' : ''}',
                        style: estiloMiudo,
                      ),
                    ],
                  ),
                ),
              );
            }
          }

          blocos.add(pw.SizedBox(height: 16));
          blocos.add(pw.Text('Saídas', style: estiloSecao));
          blocos.add(pw.SizedBox(height: 6));
          blocos.add(
            linhaDupla(
              'Pagamentos a funcionários',
              PdfFormatacaoUtil.valor(totalPagamentos),
            ),
          );
          if (contarEstoque) {
            blocos.add(
              linhaDupla('Custo de estoque', PdfFormatacaoUtil.valor(saidaEstoque)),
            );
          }
          blocos.add(
            linhaDupla('Total de saídas', PdfFormatacaoUtil.valor(totalSaidas),
                negrito: true),
          );

          blocos.add(pw.SizedBox(height: 16));
          blocos.add(pw.Text('Balança orçamentária', style: estiloSecao));
          blocos.add(pw.SizedBox(height: 6));
          blocos.add(
            linhaDupla('Saldo', PdfFormatacaoUtil.valor(saldo), negrito: true),
          );
          if (pedidosAceitos.isNotEmpty) {
            blocos.add(
              linhaDupla(
                'A receber (${pedidosAceitos.length})',
                PdfFormatacaoUtil.valor(totalAReceber),
              ),
            );
          }

          if (movimentosOrdenados.isNotEmpty) {
            blocos.add(pw.SizedBox(height: 16));
            blocos.add(
              pw.Text('Movimentos de estoque', style: estiloSecao),
            );
            blocos.add(pw.SizedBox(height: 6));
            for (final m in movimentosOrdenados) {
              final nome = PdfFormatacaoUtil.nomeDoItem(loja, m.itemId);
              final sinal = m.ehEntrada ? '+' : '-';
              final sufixoCusto = m.custoUnitario > 0
                  ? ' • ${PdfFormatacaoUtil.valor(m.custoUnitario)}/un'
                  : '';
              blocos.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              '$sinal${m.quantidade}x $nome$sufixoCusto',
                              style: estiloCorpo,
                            ),
                          ),
                          pw.Text(
                            PdfFormatacaoUtil.valor(m.custoTotal),
                            style: estiloCorpo,
                          ),
                        ],
                      ),
                      pw.Text(
                        '${PdfFormatacaoUtil.dataHora(m.dataHora)}'
                        '${m.nomeAutor.isNotEmpty ? ' • por ${m.nomeAutor}' : ''}'
                        '${m.fornecedorNome.isNotEmpty ? ' • ${m.fornecedorNome}' : ''}'
                        '${m.motivo.trim().isNotEmpty ? ' • ${m.motivo.trim()}' : ''}',
                        style: estiloMiudo,
                      ),
                    ],
                  ),
                ),
              );
            }
          }

          if (comprasOrdenadas.isNotEmpty) {
            blocos.add(pw.SizedBox(height: 16));
            blocos.add(
              pw.Text('Compras por fornecedor', style: estiloSecao),
            );
            blocos.add(pw.SizedBox(height: 6));
            for (final e in comprasOrdenadas) {
              blocos.add(linhaDupla(e.key, PdfFormatacaoUtil.valor(e.value)));
            }
            blocos.add(
              linhaDupla('Total de compras', PdfFormatacaoUtil.valor(totalCompras),
                  negrito: true),
            );
          }

          if (pagamentosOrdenados.isNotEmpty) {
            blocos.add(pw.SizedBox(height: 16));
            blocos.add(
              pw.Text('Pagamentos a funcionários', style: estiloSecao),
            );
            blocos.add(pw.SizedBox(height: 6));
            for (final p in pagamentosOrdenados) {
              blocos.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.Text(p.nome, style: estiloCorpo),
                          ),
                          pw.Text(PdfFormatacaoUtil.valor(p.valor),
                              style: estiloCorpo),
                        ],
                      ),
                      pw.Text(
                        '${PdfFormatacaoUtil.dataHora(p.dataHora)}'
                        '${p.nomeAutor.isNotEmpty ? ' • por ${p.nomeAutor}' : ''}',
                        style: estiloMiudo,
                      ),
                      if (p.descricao.trim().isNotEmpty)
                        pw.Text(
                          p.descricao.trim(),
                          style: estiloMiudo,
                        ),
                    ],
                  ),
                ),
              );
            }
          }

          if (rodape.isNotEmpty) {
            blocos.add(pw.SizedBox(height: 20));
            for (final l in rodape.split('\n')) {
              blocos.add(
                pw.Center(
                  child: pw.Text(l, style: estiloMiudo),
                ),
              );
            }
          }

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

    return PdfFormatacaoUtil.salvarArquivoPdf(
      bytes: bytes,
      nomeSugerido: 'financeiro_$sufixo.pdf',
    );
  }
}
