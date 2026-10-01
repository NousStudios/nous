import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';

const PdfPageFormat _papel58mm = PdfPageFormat(
  58 * PdfPageFormat.mm,
  200 * PdfPageFormat.mm,
  marginLeft: 5 * PdfPageFormat.mm,
  marginRight: 5 * PdfPageFormat.mm,
  marginTop: 2 * PdfPageFormat.mm,
  marginBottom: 2 * PdfPageFormat.mm,
);

class ImpressaoService {
  static Future<List<Printer>> listarImpressoras() async {
    try {
      return await Printing.listPrinters();
    } catch (_) {
      return const [];
    }
  }

  static double _tamanhoEmPontos(String tamanho) {
    switch (tamanho) {
      case 'pequena':
        return 8;
      case 'grande':
        return 12;
      case 'normal':
      default:
        return 10;
    }
  }

  static String _valor(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  static String _numero(int n) => '#${n.toString().padLeft(4, '0')}';

  static String _dataHora(DateTime d) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year} '
        '${dois(d.hour)}:${dois(d.minute)}';
  }

  static String _situacao(StatusPedido s) {
    switch (s) {
      case StatusPedido.novo:
        return 'Novo';
      case StatusPedido.aceito:
        return 'Aceito';
      case StatusPedido.concluido:
        return 'Concluído';
    }
  }

  static Future<void> imprimirTeste({
    required ConfiguracoesImpressora config,
  }) async {
    final doc = pw.Document();
    final tamanho = _tamanhoEmPontos(config.tamanhoFonte);

    doc.addPage(
      pw.Page(
        pageFormat: _papel58mm,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(
                child: pw.Text(
                  'Teste de impressão Nous',
                  style: pw.TextStyle(
                    fontSize: tamanho + 2,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  'Trabalhar todos, trabalhar menos, produzir o necessário, redistribuir tudo!',
                  style: pw.TextStyle(fontSize: tamanho),
                ),
              ),
              pw.SizedBox(height: 10),
            ],
          );
        },
      ),
    );

    final bytes = await doc.save();
    await _enviarParaImpressora(
      bytes: bytes,
      nomeImpressora: config.nomeImpressora,
      jobName: 'TesteNous',
    );
  }

  static Future<void> imprimirComanda({
    required ConfiguracoesImpressora config,
    required PedidoLoja pedido,
  }) async {
    final doc = pw.Document();
    final tamanho = _tamanhoEmPontos(config.tamanhoFonte);

    pw.TextStyle estilo({bool negrito = false, double? tamanhoCustom}) {
      return pw.TextStyle(
        fontSize: tamanhoCustom ?? tamanho,
        fontWeight: negrito ? pw.FontWeight.bold : pw.FontWeight.normal,
      );
    }

    pw.Widget linhaDupla(
      String esquerda,
      String direita, {
      bool negrito = false,
    }) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(esquerda, style: estilo(negrito: negrito)),
            ),
            pw.Text(direita, style: estilo(negrito: negrito)),
          ],
        ),
      );
    }

    double subtotal = 0;
    for (final item in pedido.itens) {
      subtotal += item.subtotal;
    }

    doc.addPage(
      pw.Page(
        pageFormat: _papel58mm,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              if (pedido.nomeVendedor.isNotEmpty)
                pw.Center(
                  child: pw.Text(pedido.nomeVendedor, style: estilo()),
                ),
              if (pedido.cnpjVendedor.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    'CNPJ: ${pedido.cnpjVendedor}',
                    style: estilo(),
                  ),
                ),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text(
                  'Pedido ${_numero(pedido.numero)}',
                  style: estilo(negrito: true),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Data: ${_dataHora(pedido.dataHora)}',
                  style: estilo(),
                ),
              ),
              pw.SizedBox(height: 6),
              linhaDupla('Cliente', pedido.clienteNome),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text('ITENS', style: estilo(negrito: true)),
              ),
              pw.SizedBox(height: 4),
              if (pedido.itens.isEmpty)
                pw.Center(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Text(
                      'Nenhum item registrado.',
                      style: estilo(),
                    ),
                  ),
                )
              else
                for (final item in pedido.itens) ...[
                  pw.SizedBox(height: 4),
                  linhaDupla(
                    '${item.quantidade}x ${item.nomeExibicao}',
                    _valor(item.subtotal),
                  ),
                  for (final a in item.acompanhamentos)
                    linhaDupla(
                      '   ${a.quantidadePorUnidade}x ${a.nomeItem} por unidade',
                      _valor(a.precoItem *
                          a.quantidadePorUnidade *
                          item.quantidade),
                    ),
                  if (item.observacao.trim().isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2),
                      child: pw.Text(
                        'Obs: ${item.observacao.trim()}',
                        style: estilo(tamanhoCustom: tamanho - 1),
                      ),
                    ),
                ],
              pw.SizedBox(height: 8),
              pw.Divider(),
              linhaDupla('Subtotal', _valor(subtotal)),
              linhaDupla('Frete', _valor(pedido.frete)),
              if (pedido.desconto > 0)
                linhaDupla('Desconto', '-${_valor(pedido.desconto)}'),
              if (pedido.acrescimo > 0)
                linhaDupla('Acréscimo', _valor(pedido.acrescimo)),
              linhaDupla('TOTAL', _valor(pedido.valor), negrito: true),
              pw.SizedBox(height: 4),
              linhaDupla(
                'Pagamento',
                pedido.formaPagamento.isEmpty ? '-' : pedido.formaPagamento,
              ),
              if (pedido.formaPagamento == 'Dinheiro') ...[
                linhaDupla('Valor recebido', '-'),
                linhaDupla('Troco', '-', negrito: true),
              ],
              if (config.rodape.isNotEmpty) ...[
                pw.SizedBox(height: 12),
                for (final l in config.rodape.split('\n'))
                  pw.Center(child: pw.Text(l, style: estilo())),
              ],
            ],
          );
        },
      ),
    );

    final bytes = await doc.save();
    await _enviarParaImpressora(
      bytes: bytes,
      nomeImpressora: config.nomeImpressora,
      jobName: 'ComandaNous-${pedido.numero}',
    );
  }

  static Future<String?> exportarComandaPDF({
    required PedidoLoja pedido,
    required String rodape,
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
          blocos.add(linhaDupla('Pedido', _numero(pedido.numero)));
          blocos.add(linhaDupla('Data', _dataHora(pedido.dataHora)));
          blocos.add(linhaDupla('Cliente', pedido.clienteNome));
          blocos.add(linhaDupla('Produtos', pedido.produtoNome));
          blocos.add(
            linhaDupla(
              'Forma de pagamento',
              pedido.formaPagamento.isEmpty
                  ? 'Não informada'
                  : pedido.formaPagamento,
            ),
          );
          blocos.add(linhaDupla('Situação', _situacao(pedido.status)));

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
                            _valor(item.subtotal),
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
                            crossAxisAlignment:
                                pw.CrossAxisAlignment.start,
                            children: [
                              pw.Expanded(
                                child: pw.Text(
                                  '${a.quantidadePorUnidade}x ${a.nomeItem} por unidade',
                                  style: estiloMiudo,
                                ),
                              ),
                              pw.Text(
                                _valor(a.precoItem *
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
          blocos.add(linhaDupla('Subtotal', _valor(subtotalItens)));
          if (pedido.frete > 0) {
            blocos.add(linhaDupla('Frete', _valor(pedido.frete)));
          }
          if (pedido.desconto > 0) {
            blocos.add(
              linhaDupla('Desconto', '-${_valor(pedido.desconto)}'),
            );
          }
          if (pedido.acrescimo > 0) {
            blocos.add(
              linhaDupla('Acréscimo', _valor(pedido.acrescimo)),
            );
          }
          blocos.add(
            linhaDupla('Valor total', _valor(pedido.valor), negrito: true),
          );

          if (pedido.formaPagamento == 'À Prazo') {
            blocos.add(
              linhaDupla(
                'Pagamento',
                pedido.quitado ? 'Quitado' : 'Em aberto',
              ),
            );
            blocos.add(
              linhaDupla(
                'Já pago',
                _valor(pedido.quitado ? pedido.valor : pedido.valorPago),
              ),
            );
            blocos.add(
              linhaDupla(
                'Restante',
                _valor(pedido.quitado ? 0 : pedido.valorRestante),
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
                        'Em: ${_dataHora(pedido.comentarioDataHora!)}',
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

    const grupo = XTypeGroup(label: 'PDF', extensions: ['pdf']);
    final local = await getSaveLocation(
      suggestedName:
          'comanda_${pedido.numero.toString().padLeft(4, '0')}.pdf',
      acceptedTypeGroups: const [grupo],
    );

    if (local == null) return null;

    final arquivo = File(local.path);
    await arquivo.writeAsBytes(bytes);
    return local.path;
  }

  static Future<void> _enviarParaImpressora({
    required Uint8List bytes,
    required String nomeImpressora,
    required String jobName,
  }) async {
    if (nomeImpressora.isEmpty) {
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: jobName,
      );
      return;
    }

    final printer = Printer(url: nomeImpressora, name: nomeImpressora);
    await Printing.directPrintPdf(
      printer: printer,
      onLayout: (format) async => bytes,
      name: jobName,
      format: _papel58mm,
      dynamicLayout: false,
    );
  }
}