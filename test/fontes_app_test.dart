import 'package:flutter_test/flutter_test.dart';
import 'package:nous/src/core/theme/fontes_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Unificação de Tipografia (FontesApp)', () {
    test('Lista mestra contém opções completas e consagradas para tela e térmica', () {
      expect(FontesApp.todas.length, greaterThanOrEqualTo(11));

      final ids = FontesApp.todas.map((f) => f.id).toList();
      expect(ids, contains('belleza'));
      expect(ids, contains('padrao')); // Arial / Helvetica
      expect(ids, contains('mono')); // Courier
      expect(ids, contains('roboto'));
      expect(ids, contains('roboto_mono'));
      expect(ids, contains('open_sans'));
      expect(ids, contains('inter'));
      expect(ids, contains('lato'));
      expect(ids, contains('poppins'));
      expect(ids, contains('montserrat'));
      expect(ids, contains('serifada')); // Times New Roman
    });

    test('obterPorIdOuNome resolve com precisão e preserva retrocompatibilidade', () {
      // IDs históricos do Nous
      expect(FontesApp.obterPorIdOuNome('padrao').familiaFlutter, equals('Arial'));
      expect(FontesApp.obterPorIdOuNome('mono').familiaFlutter, equals('Courier New'));
      expect(FontesApp.obterPorIdOuNome('serifada').familiaFlutter, equals('Times New Roman'));
      expect(FontesApp.obterPorIdOuNome('belleza').familiaFlutter, equals('Belleza'));

      // Aliases diretos pelo nome
      expect(FontesApp.obterPorIdOuNome('Arial').id, equals('padrao'));
      expect(FontesApp.obterPorIdOuNome('Courier').id, equals('mono'));
      expect(FontesApp.obterPorIdOuNome('Roboto Mono').id, equals('roboto_mono'));
      expect(FontesApp.obterPorIdOuNome('Open Sans').id, equals('open_sans'));
      expect(FontesApp.obterPorIdOuNome('Inexistente').id, equals('belleza')); // Fallback seguro
    });

    test('criarTextStyle gera estilo sem exceções', () {
      for (final opcao in FontesApp.todas) {
        final estilo = FontesApp.criarTextStyle(
          fontName: opcao.familiaFlutter,
          fontSize: 14,
        );
        expect(estilo, isNotNull);
        expect(estilo.fontSize, equals(14));
      }
    });

    test('resolverFontePdf e resolverFonteNegritoPdf resolvem fontes de recibo e documentos', () async {
      // Testando as principais fontes térmicas integradas ao motor PDF
      final fPadrao = await FontesApp.resolverFontePdf('padrao');
      final fMono = await FontesApp.resolverFontePdf('mono');
      final fSerif = await FontesApp.resolverFontePdf('serifada');

      expect(fPadrao, isNotNull);
      expect(fMono, isNotNull);
      expect(fSerif, isNotNull);

      final fPadraoNegrito = await FontesApp.resolverFonteNegritoPdf('padrao');
      final fMonoNegrito = await FontesApp.resolverFonteNegritoPdf('mono');

      expect(fPadraoNegrito, isNotNull);
      expect(fMonoNegrito, isNotNull);
    });
  });
}
