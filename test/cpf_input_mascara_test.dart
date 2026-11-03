import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nous/src/features/auth/views/widgets/cpf_input_widget.dart';

void main() {
  testWidgets('CpfTextEditingController ofusca números após os 3 primeiros quando oculto', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final controller = CpfTextEditingController(
                text: '123.456.789-01',
                oculto: true,
              );

              final span = controller.buildTextSpan(
                context: context,
                withComposing: false,
              );

              // Deve manter os 3 primeiros dígitos visíveis e ofuscar os demais com •
              expect(span.toPlainText(), equals('123.•••.•••-••'));
              // O texto real no buffer continua intacto para validações e login
              expect(controller.text, equals('123.456.789-01'));

              // Ao alternar para visível:
              controller.oculto = false;
              final spanVisivel = controller.buildTextSpan(
                context: context,
                withComposing: false,
              );
              expect(spanVisivel.toPlainText(), equals('123.456.789-01'));

              return const SizedBox();
            },
          ),
        ),
      ),
    );
  });

  testWidgets('CpfTextEditingController mantém números visíveis se tiver 3 ou menos dígitos', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final c1 = CpfTextEditingController(text: '12', oculto: true);
              expect(c1.buildTextSpan(context: context, withComposing: false).toPlainText(), equals('12'));

              final c2 = CpfTextEditingController(text: '123.', oculto: true);
              expect(c2.buildTextSpan(context: context, withComposing: false).toPlainText(), equals('123.'));

              final c3 = CpfTextEditingController(text: '123.4', oculto: true);
              expect(c3.buildTextSpan(context: context, withComposing: false).toPlainText(), equals('123.•'));

              return const SizedBox();
            },
          ),
        ),
      ),
    );
  });
}
