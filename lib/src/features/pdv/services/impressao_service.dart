import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';

const PdfPageFormat _papel58mm = PdfPageFormat(
  58 * PdfPageFormat.mm,
  200 * PdfPageFormat.mm,
  marginAll: 2 * PdfPageFormat.mm,
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
    final fonte = pw.Font.courier();

    final linhas = <String>[
      'Pedido #${pedido.numero.toString().padLeft(4, '0')}',
      'Data: ${_dataHora(pedido.dataHora)}',
      'Cliente: ${pedido.clienteNome}',
      '',
      ...pedido.comanda.split('\n'),
      '',
      if (config.rodape.isNotEmpty) ...config.rodape.split('\n'),
    ];

    doc.addPage(
      pw.Page(
        pageFormat: _papel58mm,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (final linha in linhas)
                pw.Text(
                  linha,
                  style: pw.TextStyle(fontSize: tamanho, font: fonte),
                ),
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

  static String _dataHora(DateTime d) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year} '
        '${dois(d.hour)}:${dois(d.minute)}';
  }
}