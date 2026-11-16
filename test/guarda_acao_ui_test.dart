import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nous/src/core/services/guarda_acao_ui.dart';

void main() {
  setUp(() => GuardaAcaoUi.limparParaTestes());

  test('executarUnico bloqueia chamadas concorrentes enquanto Future está ativo',
      () async {
    var execucoes = 0;
    final completer = Completer<void>();

    final f1 = GuardaAcaoUi.executarUnico('abrir_config', () async {
      execucoes++;
      await completer.future;
    });
    final f2 = GuardaAcaoUi.executarUnico('abrir_config', () async {
      execucoes++;
    });
    final f3 = GuardaAcaoUi.executarUnico('abrir_config', () async {
      execucoes++;
    });

    completer.complete();
    await Future.wait([f1, f2, f3]);

    expect(execucoes, 1);
  });

  test('executarSincrono bloqueia cliques repetidos dentro do cooldown', () {
    var cliques = 0;
    expect(
      GuardaAcaoUi.executarSincrono('abrir_loja_1', () => cliques++),
      isTrue,
    );
    expect(
      GuardaAcaoUi.executarSincrono('abrir_loja_1', () => cliques++),
      isFalse,
    );
    expect(
      GuardaAcaoUi.executarSincrono('abrir_loja_2', () => cliques++),
      isTrue,
    );
    expect(cliques, 2);
  });
}
