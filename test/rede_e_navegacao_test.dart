import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nous/src/core/services/atualizacao_service.dart';
import 'package:nous/src/core/services/rede_logger_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/atualizacao_dialog.dart';
import 'package:nous/src/core/widgets/floating_bottom_nav_bar.dart';
import 'package:nous/src/features/busca/views/busca_mapa_view.dart';
import 'package:nous/src/features/chat/views/mensageria_view.dart';
import 'package:nous/src/features/pdv/views/perfis_pdv_view.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
    tempDir = Directory.systemTemp.createTempSync('nous_nav_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => tempDir.path,
    );
  });

  tearDownAll(() {
    try {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('RedeLoggerService', () {
    test('mantém buffer circular limitado e registra erros', () {
      RedeLoggerService.limpar();
      for (var i = 0; i < 130; i++) {
        RedeLoggerService.registrar('Teste', 'Msg $i', erro: i.isEven);
      }
      final regs = RedeLoggerService.registros;
      expect(regs.length, 120);
      expect(regs.first.mensagem, 'Msg 10');
      expect(regs.last.mensagem, 'Msg 129');
      RedeLoggerService.limpar();
    });
  });

  group('FloatingBottomNavBar — Restauração de Última Tela', () {
    test('usuário novo abre BuscaMapaView por padrão', () async {
      final tela = await FloatingBottomNavBar.obterTelaInicialPorCpf(
        '00011122233',
      );
      expect(tela, isA<BuscaMapaView>());
    });

    test('usuário recorrente retorna para a última aba salva do CPF', () async {
      await FloatingBottomNavBar.salvarUltimaAba('12345678900', 0, 1);
      final telaPdv = await FloatingBottomNavBar.obterTelaInicialPorCpf(
        '123.456.789-00',
      );
      expect(telaPdv, isA<PerfisPdvView>());

      await FloatingBottomNavBar.salvarUltimaAba('12345678900', 1, 1);
      final telaChat = await FloatingBottomNavBar.obterTelaInicialPorCpf(
        '12345678900',
      );
      expect(telaChat, isA<MensageriaView>());
    });
  });

  group('AtualizacaoDialog — Reatividade de infoAtualizacao', () {
    testWidgets('atualiza botão Instalar imediatamente quando infoAtualizacao muda',
        (tester) async {
      AtualizacaoService.verificando.value = false;
      AtualizacaoService.baixando.value = false;
      AtualizacaoService.temAtualizacao.value = true;
      AtualizacaoService.infoAtualizacao.value = const InfoAtualizacao(
        versao: '1.1.45',
        nomeVersao: 'v1.1.45',
        urlDownload: 'http://127.0.0.1/antigo.apk',
        descricao: '',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AtualizacaoDialog(theme: ThemeController.currentTheme.value),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Instalar v1.1.45'), findsOneWidget);

      AtualizacaoService.infoAtualizacao.value = const InfoAtualizacao(
        versao: '1.1.47',
        nomeVersao: 'v1.1.47',
        urlDownload: 'http://127.0.0.1/novo.apk',
        descricao: '',
      );
      await tester.pump();

      expect(find.text('Instalar v1.1.47'), findsOneWidget);
    });
  });
}
