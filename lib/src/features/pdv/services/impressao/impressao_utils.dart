import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:nous/src/core/theme/fontes_app.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';

const PdfPageFormat kPapel58mmPadrao = PdfPageFormat(
  58 * PdfPageFormat.mm,
  200 * PdfPageFormat.mm,
  marginLeft: 5.0 * PdfPageFormat.mm,
  marginRight: 3.0 * PdfPageFormat.mm,
  marginTop: 2 * PdfPageFormat.mm,
  marginBottom: 2 * PdfPageFormat.mm,
);

const List<String> kFormasDePagamentoImpressao = [
  'Pix',
  'Dinheiro',
  'Débito',
  'Crédito',
  'À Prazo',
];

class ImpressaoUtils {
  static Future<pw.Font> resolverFonte(String modelo) async {
    return FontesApp.resolverFontePdf(modelo);
  }

  static Future<pw.Font> resolverFonteNegrito(String modelo) async {
    return FontesApp.resolverFonteNegritoPdf(modelo);
  }

  static PdfPageFormat formatoPapel(ConfiguracoesImpressora? config) {
    final margemEsquerda = (config != null && config.margemEsquerdaMm > 0
            ? config.margemEsquerdaMm
            : 5.0) *
        PdfPageFormat.mm;
    final margemDireita = (config != null && config.margemDireitaMm > 0
            ? config.margemDireitaMm
            : 3.0) *
        PdfPageFormat.mm;
    final larguraMm = (config != null && config.larguraPapelMm > 0)
        ? config.larguraPapelMm
        : 58.0;
    return PdfPageFormat(
      larguraMm * PdfPageFormat.mm,
      200 * PdfPageFormat.mm,
      marginLeft: margemEsquerda,
      marginRight: margemDireita,
      marginTop: 2 * PdfPageFormat.mm,
      marginBottom: 2 * PdfPageFormat.mm,
    );
  }

  static double tamanhoEmPontos(String tamanho) {
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

  static String valor(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  static String numero(int n) => '#${n.toString().padLeft(4, '0')}';

  static String dataHora(DateTime d) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year} '
        '${dois(d.hour)}:${dois(d.minute)}';
  }

  static List<MapEntry<String, String>> dadosDoCliente(
    Cliente? cliente,
    List<String> camposSelecionados,
  ) {
    if (cliente == null) return const [];
    final linhas = <MapEntry<String, String>>[];

    if (camposSelecionados.contains('cnpj') &&
        cliente.cnpj.trim().isNotEmpty) {
      linhas.add(MapEntry('CNPJ', cliente.cnpj.trim()));
    }
    if (camposSelecionados.contains('telefone') &&
        cliente.telefone.trim().isNotEmpty) {
      linhas.add(MapEntry('Telefone', cliente.telefone.trim()));
    }
    if (camposSelecionados.contains('endereco')) {
      final endereco = cliente.endereco.trim();
      final numero = cliente.numero.trim();
      if (endereco.isNotEmpty) {
        linhas.add(MapEntry(
          'Endereço',
          numero.isEmpty ? endereco : '$endereco, $numero',
        ));
      } else if (numero.isNotEmpty) {
        linhas.add(MapEntry('Número', numero));
      }
    }
    if (camposSelecionados.contains('email') &&
        cliente.email.trim().isNotEmpty) {
      linhas.add(MapEntry('Email', cliente.email.trim()));
    }
    if (camposSelecionados.contains('redesSociais') &&
        cliente.redesSociais.trim().isNotEmpty) {
      linhas.add(MapEntry('Redes sociais', cliente.redesSociais.trim()));
    }
    if (camposSelecionados.contains('descricao') &&
        cliente.descricao.trim().isNotEmpty) {
      linhas.add(MapEntry('Descrição', cliente.descricao.trim()));
    }

    return linhas;
  }

  static pw.Widget linhaDupla(
    String esquerda,
    String direita, {
    required pw.TextStyle Function({bool negrito, double? tamanhoCustom})
        estilo,
    bool negrito = false,
    double espacamentoVertical = 1.0,
  }) {
    final ehPreco = direita.trim().startsWith('R\$') ||
        direita.trim().startsWith('-R\$') ||
        direita.trim().startsWith('+R\$');

    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: espacamentoVertical),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (ehPreco)
            pw.Expanded(
              child: pw.Text(esquerda, style: estilo(negrito: negrito)),
            )
          else
            pw.Text(
              esquerda.endsWith(':') ? esquerda : '$esquerda:',
              style: estilo(negrito: negrito),
            ),
          pw.SizedBox(width: 8),
          if (ehPreco)
            pw.Text(
              direita,
              style: estilo(negrito: negrito),
              textAlign: pw.TextAlign.right,
            )
          else
            pw.Expanded(
              child: pw.Text(
                direita,
                textAlign: pw.TextAlign.right,
                style: estilo(negrito: negrito),
              ),
            ),
        ],
      ),
    );
  }

  static Future<void> enviarParaImpressora({
    required Uint8List bytes,
    required String nomeImpressora,
    required String jobName,
    PdfPageFormat? format,
  }) async {
    final formatoFinal = format ?? kPapel58mmPadrao;
    if (nomeImpressora.isEmpty) {
      await Printing.layoutPdf(
        onLayout: (f) async => bytes,
        name: jobName,
        format: formatoFinal,
      );
      return;
    }

    final printer = Printer(url: nomeImpressora, name: nomeImpressora);
    await Printing.directPrintPdf(
      printer: printer,
      onLayout: (f) async => bytes,
      name: jobName,
      format: formatoFinal,
      dynamicLayout: false,
    );
  }
}
