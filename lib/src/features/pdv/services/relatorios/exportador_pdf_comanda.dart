import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/services/relatorios/pdf_formatacao_util.dart';

/// Gerador e exportador do relatório de Comanda em formato PDF A4.
class ExportadorPdfComanda {
  static Future<String?> exportar({
    required PedidoLoja pedido,
    required String rodape,
    Cliente? cliente,
    List<String> camposClienteComanda = kCamposClienteComandaPadrao,
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

    double subtotalItens = 0;
    for (final item in pedido.itens) {
      subtotalItens += item.subtotal;
    }

    final linhasCliente =
        PdfFormatacaoUtil.dadosDoCliente(cliente, camposClienteComanda);
    final pagamentos = pedido.todosPagamentos;

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
              width: 150,
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
              child: pw.Text('Comanda', style: estiloTitulo),
            ),
          );
          if (pedido.nomeVendedor.isNotEmpty) {
            blocos.add(
              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 4),
                  child: pw.Text(
                    pedido.nomeVendedor,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }
          if (pedido.cnpjVendedor.isNotEmpty) {
            blocos.add(
              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text(
                    'CNPJ: ${pedido.cnpjVendedor}',
                    style: estiloMiudo,
                  ),
                ),
              ),
            );
          }

          blocos.add(pw.SizedBox(height: 16));
          blocos.add(pw.Divider());
          blocos.add(pw.SizedBox(height: 8));

          blocos.add(
            pw.Text('Dados do Pedido', style: estiloSecao),
          );
          blocos.add(pw.SizedBox(height: 6));
          blocos.add(linhaDupla('Pedido', PdfFormatacaoUtil.numero(pedido.numero)));
          blocos.add(linhaDupla('Data', PdfFormatacaoUtil.dataHora(pedido.dataHora)));
          blocos.add(linhaDupla('Cliente', pedido.clienteNome));
          for (final linha in linhasCliente) {
            blocos.add(linhaDupla(linha.key, linha.value));
          }
          blocos.add(linhaDupla('Produtos', pedido.produtoNome));
          blocos.add(linhaDupla('Situação', PdfFormatacaoUtil.situacao(pedido.status)));

          blocos.add(pw.SizedBox(height: 16));
          blocos.add(pw.Text('Itens', style: estiloSecao));
          blocos.add(pw.SizedBox(height: 6));

          if (pedido.itens.isEmpty) {
            blocos.add(
              pw.Text(
                'Nenhum item detalhado nesta venda.',
                style: estiloMiudo,
              ),
            );
          } else {
            for (final item in pedido.itens) {
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
                              '${item.quantidade}x ${item.nomeExibicao}',
                              style: estiloCorpo,
                            ),
                          ),
                          pw.Text(
                            PdfFormatacaoUtil.valor(item.subtotalBase),
                            style: estiloCorpo,
                          ),
                        ],
                      ),
                      for (final a in item.acompanhamentos)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(
                            left: 12,
                            top: 2,
                          ),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Expanded(
                                child: pw.Text(
                                  '${a.quantidadePorUnidade}x ${a.nomeItem} por unidade',
                                  style: estiloMiudo,
                                ),
                              ),
                              pw.Text(
                                PdfFormatacaoUtil.valor(a.precoItem *
                                    a.quantidadePorUnidade *
                                    item.quantidade),
                                style: estiloMiudo,
                              ),
                            ],
                          ),
                        ),
                      if (item.observacao.trim().isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(
                            left: 12,
                            top: 2,
                          ),
                          child: pw.Text(
                            'Obs: ${item.observacao.trim()}',
                            style: estiloMiudo,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }
          }

          blocos.add(pw.SizedBox(height: 16));
          blocos.add(pw.Text('Resumo', style: estiloSecao));
          blocos.add(pw.SizedBox(height: 6));
          blocos.add(linhaDupla('Subtotal', PdfFormatacaoUtil.valor(subtotalItens)));
          if (pedido.frete > 0) {
            blocos.add(linhaDupla('Frete', PdfFormatacaoUtil.valor(pedido.frete)));
          }
          if (pedido.desconto > 0) {
            blocos.add(
              linhaDupla('Desconto', '-${PdfFormatacaoUtil.valor(pedido.desconto)}'),
            );
          }
          if (pedido.acrescimo > 0) {
            blocos.add(
              linhaDupla('Acréscimo', PdfFormatacaoUtil.valor(pedido.acrescimo)),
            );
          }
          blocos.add(
            linhaDupla('Valor total', PdfFormatacaoUtil.valor(pedido.valor),
                negrito: true),
          );

          if (pagamentos.isNotEmpty) {
            blocos.add(pw.SizedBox(height: 8));
            blocos.add(pw.Text('Pagamentos', style: estiloSecao));
            blocos.add(pw.SizedBox(height: 6));
            for (final p in pagamentos) {
              blocos.add(linhaDupla(p.forma, PdfFormatacaoUtil.valor(p.valor)));
            }
            if (pedido.troco > 0) {
              blocos.add(
                linhaDupla('Troco', PdfFormatacaoUtil.valor(pedido.troco),
                    negrito: true),
              );
            }
          }

          if (pedido.formaPagamento == 'À Prazo' ||
              pedido.todosPagamentos.any((p) => p.forma == 'À Prazo')) {
            blocos.add(pw.SizedBox(height: 8));
            blocos.add(
              linhaDupla(
                'Pagamento à prazo',
                pedido.quitado ? 'Quitado' : 'Em aberto',
              ),
            );
            blocos.add(
              linhaDupla(
                'Já pago',
                PdfFormatacaoUtil.valor(
                    pedido.quitado ? pedido.valor : pedido.valorPago),
              ),
            );
            blocos.add(
              linhaDupla(
                'Restante',
                PdfFormatacaoUtil.valor(
                    pedido.quitado ? 0 : pedido.valorRestante),
              ),
            );
          }

          if (pedido.comentario.trim().isNotEmpty) {
            blocos.add(pw.SizedBox(height: 16));
            blocos.add(pw.Text('Comentário', style: estiloSecao));
            blocos.add(pw.SizedBox(height: 6));
            blocos.add(
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(6),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      pedido.comentario.trim(),
                      style: estiloCorpo,
                    ),
                    if (pedido.comentarioAutorNome.isNotEmpty ||
                        pedido.comentarioAutorCpf.isNotEmpty ||
                        pedido.comentarioAutorEmail.isNotEmpty) ...[
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Por: ${[
                          if (pedido.comentarioAutorNome.isNotEmpty)
                            pedido.comentarioAutorNome,
                          if (pedido.comentarioAutorCpf.isNotEmpty)
                            pedido.comentarioAutorCpf,
                          if (pedido.comentarioAutorEmail.isNotEmpty)
                            pedido.comentarioAutorEmail,
                        ].join(' • ')}',
                        style: estiloMiudo,
                      ),
                    ],
                    if (pedido.comentarioDataHora != null) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Em: ${PdfFormatacaoUtil.dataHora(pedido.comentarioDataHora!)}',
                        style: estiloMiudo,
                      ),
                    ],
                  ],
                ),
              ),
            );
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
    return PdfFormatacaoUtil.salvarArquivoPdf(
      bytes: bytes,
      nomeSugerido:
          'comanda_${pedido.numero.toString().padLeft(4, '0')}.pdf',
    );
  }
}
