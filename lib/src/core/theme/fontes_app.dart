import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Modelo de definição de fonte unificada do ecossistema Nous.
/// Atende simultaneamente à interface gráfica (telas/diálogos) e à
/// geração de documentos e comandas térmicas (PDF/térmica de 58mm e 80mm).
class OpcaoFonte {
  /// Identificador persistido no cofre da loja e nas preferências do app.
  final String id;

  /// Nome amigável exibido nos menus dropdowns de seleção.
  final String rotulo;

  /// Nome da família de fonte para a interface Flutter.
  final String familiaFlutter;

  /// Se a fonte é do Google Fonts (carregada dinamicamente com fallback).
  final bool ehGoogleFont;

  /// Se a fonte é monoespaçada (caracteres com larguras idênticas).
  final bool ehMonoespacada;

  /// Descrição técnica do perfil da fonte.
  final String descricao;

  const OpcaoFonte({
    required this.id,
    required this.rotulo,
    required this.familiaFlutter,
    this.ehGoogleFont = false,
    this.ehMonoespacada = false,
    this.descricao = '',
  });
}

class FontesApp {
  static pw.Font? _fonteBellezaCache;

  /// Lista mestra unificada de todas as fontes disponíveis na aplicação e nas comandas.
  static const List<OpcaoFonte> todas = [
    OpcaoFonte(
      id: 'belleza',
      rotulo: 'Belleza (Padrão Nous)',
      familiaFlutter: 'Belleza',
      descricao: 'Identidade visual do Nous, elegante e artística.',
    ),
    OpcaoFonte(
      id: 'padrao', // Retrocompatível com 'padrao' e 'arial'
      rotulo: 'Arial / Helvetica (Ideal p/ Térmica)',
      familiaFlutter: 'Arial',
      descricao: 'Clássica sem serifa, traços uniformes e nítidos em bobinas térmicas.',
    ),
    OpcaoFonte(
      id: 'mono', // Retrocompatível com 'mono' e 'courier'
      rotulo: 'Courier (Monoespaçada de Recibo)',
      familiaFlutter: 'Courier New',
      ehMonoespacada: true,
      descricao: 'Alinhamento vertical milimétrico de preços e colunas.',
    ),
    OpcaoFonte(
      id: 'roboto',
      rotulo: 'Roboto (Google / Android)',
      familiaFlutter: 'Roboto',
      ehGoogleFont: true,
      descricao: 'Moderna, equilibrada e de alta legibilidade.',
    ),
    OpcaoFonte(
      id: 'roboto_mono',
      rotulo: 'Roboto Mono (Alinhada p/ Térmica)',
      familiaFlutter: 'Roboto Mono',
      ehGoogleFont: true,
      ehMonoespacada: true,
      descricao: 'Monoespaçada moderna com excelente definição de números.',
    ),
    OpcaoFonte(
      id: 'open_sans',
      rotulo: 'Open Sans (Nítida p/ Térmica)',
      familiaFlutter: 'Open Sans',
      ehGoogleFont: true,
      descricao: 'Caracteres abertos que evitam borrões em impressão térmica.',
    ),
    OpcaoFonte(
      id: 'inter',
      rotulo: 'Inter (Alta Precisão)',
      familiaFlutter: 'Inter',
      ehGoogleFont: true,
      descricao: 'Desenhada para máxima clareza em telas e relatórios.',
    ),
    OpcaoFonte(
      id: 'lato',
      rotulo: 'Lato (Harmoniosa)',
      familiaFlutter: 'Lato',
      ehGoogleFont: true,
      descricao: 'Sem serifa suave e profissional.',
    ),
    OpcaoFonte(
      id: 'poppins',
      rotulo: 'Poppins (Geométrica)',
      familiaFlutter: 'Poppins',
      ehGoogleFont: true,
      descricao: 'Formas geométricas limpas e contemporâneas.',
    ),
    OpcaoFonte(
      id: 'montserrat',
      rotulo: 'Montserrat (Robusta)',
      familiaFlutter: 'Montserrat',
      ehGoogleFont: true,
      descricao: 'Excelente contraste e presença visual.',
    ),
    OpcaoFonte(
      id: 'serifada', // Retrocompatível com 'serifada' e 'times'
      rotulo: 'Times New Roman (Serifada Formal)',
      familiaFlutter: 'Times New Roman',
      descricao: 'Serifada clássica para extratos e recibos formais.',
    ),
  ];

  /// Lista de nomes simples para compatibilidade com seletores baseados em String.
  static List<String> get nomesSimples =>
      todas.map((f) => f.familiaFlutter).toList();

  /// Encontra a opção de fonte correspondente ao ID ou nome da família.
  static OpcaoFonte obterPorIdOuNome(String valor) {
    final v = valor.trim().toLowerCase();
    for (final f in todas) {
      if (f.id.toLowerCase() == v ||
          f.familiaFlutter.toLowerCase() == v ||
          f.rotulo.toLowerCase().contains(v)) {
        return f;
      }
    }
    // Aliases e retrocompatibilidade histórica:
    if (v == 'arial' || v == 'helvetica' || v == 'sem serifa') {
      return todas.firstWhere((f) => f.id == 'padrao');
    }
    if (v == 'courier' || v == 'monospace' || v == 'recibo') {
      return todas.firstWhere((f) => f.id == 'mono');
    }
    if (v == 'times' || v == 'times new roman' || v == 'serif') {
      return todas.firstWhere((f) => f.id == 'serifada');
    }
    // Fallback padrão Nous
    return todas.first;
  }

  /// Retorna o TextStyle com a fonte aplicada na interface gráfica Flutter de forma soberana e local.
  static TextStyle criarTextStyle({
    required String fontName,
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
  }) {
    final opcao = obterPorIdOuNome(fontName);

    return TextStyle(
      fontFamily: opcao.familiaFlutter,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// Resolve a fonte normal para documentos PDF e impressões térmicas.
  static Future<pw.Font> resolverFontePdf(String modelo) async {
    final opcao = obterPorIdOuNome(modelo);

    switch (opcao.id) {
      case 'mono':
        return pw.Font.courier();
      case 'serifada':
        return pw.Font.times();
      case 'padrao':
        return pw.Font.helvetica();
      case 'belleza':
        try {
          if (_fonteBellezaCache != null) return _fonteBellezaCache!;
          final bytes =
              await rootBundle.load('assets/fonts/Belleza-Regular.ttf');
          _fonteBellezaCache = pw.Font.ttf(bytes);
          return _fonteBellezaCache!;
        } catch (_) {
          return pw.Font.helvetica();
        }
      case 'roboto':
        try {
          return await PdfGoogleFonts.robotoRegular();
        } catch (_) {
          return pw.Font.helvetica();
        }
      case 'roboto_mono':
        try {
          return await PdfGoogleFonts.robotoMonoRegular();
        } catch (_) {
          return pw.Font.courier();
        }
      case 'open_sans':
        try {
          return await PdfGoogleFonts.openSansRegular();
        } catch (_) {
          return pw.Font.helvetica();
        }
      case 'inter':
        try {
          return await PdfGoogleFonts.interRegular();
        } catch (_) {
          return pw.Font.helvetica();
        }
      case 'lato':
        try {
          return await PdfGoogleFonts.latoRegular();
        } catch (_) {
          return pw.Font.helvetica();
        }
      case 'poppins':
        try {
          return await PdfGoogleFonts.poppinsRegular();
        } catch (_) {
          return pw.Font.helvetica();
        }
      case 'montserrat':
        try {
          return await PdfGoogleFonts.montserratRegular();
        } catch (_) {
          return pw.Font.helvetica();
        }
      default:
        return pw.Font.helvetica();
    }
  }

  /// Resolve a fonte em negrito para documentos PDF e impressões térmicas.
  static Future<pw.Font> resolverFonteNegritoPdf(String modelo) async {
    final opcao = obterPorIdOuNome(modelo);

    switch (opcao.id) {
      case 'mono':
        return pw.Font.courierBold();
      case 'serifada':
        return pw.Font.timesBold();
      case 'padrao':
        return pw.Font.helveticaBold();
      case 'belleza':
        try {
          if (_fonteBellezaCache != null) return _fonteBellezaCache!;
          final bytes =
              await rootBundle.load('assets/fonts/Belleza-Regular.ttf');
          _fonteBellezaCache = pw.Font.ttf(bytes);
          return _fonteBellezaCache!;
        } catch (_) {
          return pw.Font.helveticaBold();
        }
      case 'roboto':
        try {
          return await PdfGoogleFonts.robotoBold();
        } catch (_) {
          return pw.Font.helveticaBold();
        }
      case 'roboto_mono':
        try {
          return await PdfGoogleFonts.robotoMonoBold();
        } catch (_) {
          return pw.Font.courierBold();
        }
      case 'open_sans':
        try {
          return await PdfGoogleFonts.openSansBold();
        } catch (_) {
          return pw.Font.helveticaBold();
        }
      case 'inter':
        try {
          return await PdfGoogleFonts.interBold();
        } catch (_) {
          return pw.Font.helveticaBold();
        }
      case 'lato':
        try {
          return await PdfGoogleFonts.latoBold();
        } catch (_) {
          return pw.Font.helveticaBold();
        }
      case 'poppins':
        try {
          return await PdfGoogleFonts.poppinsBold();
        } catch (_) {
          return pw.Font.helveticaBold();
        }
      case 'montserrat':
        try {
          return await PdfGoogleFonts.montserratBold();
        } catch (_) {
          return pw.Font.helveticaBold();
        }
      default:
        return pw.Font.helveticaBold();
    }
  }
}
