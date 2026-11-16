import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/core/services/preferencias_soberanas_service.dart';
import 'package:nous/src/features/auth/models/fundadores_nous.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/google_oauth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
    tempDir = Directory.systemTemp.createTempSync('nous_oauth_test_');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => tempDir.path,
    );
    BancoDadosService.resetDbInstanciaParaTestes();
  });

  tearDownAll(() async {
    try {
      final db = await BancoDadosService.db;
      await db.close();
    } catch (_) {}
    BancoDadosService.resetDbInstanciaParaTestes();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  tearDown(() async {
    await GoogleOAuthService.salvarClientId('');
    await GoogleOAuthService.salvarClientSecret('');
  });

  test('GoogleOAuthService descriptografa credenciais padrao sem plaintext',
      () async {
    final clientId = await GoogleOAuthService.obterClientId();
    final clientSecret = await GoogleOAuthService.obterClientSecret();

    expect(clientId, endsWith('.apps.googleusercontent.com'));
    expect(clientId.startsWith('692881081150-'), isTrue);
    expect(clientSecret.startsWith('GOCSPX-'), isTrue);
    expect(clientSecret.length, greaterThan(20));
  });

  test(
      'GoogleOAuthService salva credenciais customizadas criptografadas em SQLite',
      () async {
    const customId = 'teste-custom-id.apps.googleusercontent.com';
    const customSecret = 'GOCSPX-teste-segredo-soberano-123';

    await GoogleOAuthService.salvarClientId(customId);
    await GoogleOAuthService.salvarClientSecret(customSecret);

    final brutoId = await PreferenciasSoberanasService.obterTexto(
          GoogleOAuthService.chavePrefClientId,
        ) ??
        '';
    final brutoSecret = await PreferenciasSoberanasService.obterTexto(
          GoogleOAuthService.chavePrefClientSecret,
        ) ??
        '';

    expect(brutoId.startsWith('v1:'), isTrue);
    expect(brutoSecret.startsWith('v1:'), isTrue);
    expect(brutoId.contains(customId), isFalse);
    expect(brutoSecret.contains(customSecret), isFalse);

    expect(await GoogleOAuthService.obterClientId(), customId);
    expect(await GoogleOAuthService.obterClientSecret(), customSecret);
  });

  test('FundadoresNous marca 47192956813 como verificado pelo sistema', () {
    const fundador = UsuarioNous(
      cpf: '47192956813',
      nome: 'Leonardo Taddeo',
      nomeDeUsuario: 'taddeoleonardo',
      dataNascimento: '01/01/1990',
    );
    final aplicado = FundadoresNous.aplicarSeloFundadorSeAplicavel(fundador);
    expect(aplicado.verificado, isTrue);
    expect(aplicado.validadoPorCpf, FundadoresNous.idSistemaFundador);
    expect(aplicado.validacoes.first['assinatura'], 'FUNDADOR_NOUS');

    const comum = UsuarioNous(
      cpf: '11122233344',
      nome: 'Cidadao Novo',
      dataNascimento: '01/01/1995',
    );
    final comumAplicado = FundadoresNous.aplicarSeloFundadorSeAplicavel(comum);
    expect(comumAplicado.verificado, isFalse);
    expect(comumAplicado.validacoes, isEmpty);
  });

  test('UsuarioNous persiste emailsVerificados e valida posse case-insensitive',
      () {
    const u = UsuarioNous(
      cpf: '12345678900',
      nome: 'Teste',
      dataNascimento: '01/01/1990',
      emails: ['A@Gmail.com', 'legado@teste.com'],
      emailsVerificados: ['a@gmail.com'],
    );
    final json = u.toJson();
    final restaurado = UsuarioNous.fromJson(json);

    expect(restaurado.emailEstaVerificado('a@gmail.com'), isTrue);
    expect(restaurado.emailEstaVerificado('A@GMAIL.COM'), isTrue);
    expect(restaurado.emailEstaVerificado('legado@teste.com'), isFalse);
  });
}
