import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/main.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/views/mensageria_view.dart';
import 'package:nous/src/features/chat/views/widgets/painel_conversa_ativa_widget.dart';
import 'package:nous/src/features/chat/controllers/mensageria_controller.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return Directory.systemTemp.path;
      },
    );
  });

  testWidgets('MyApp inicializa e renderiza tela de login',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await ThemeController.init();

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.byType(MyApp), findsOneWidget);
  });

  testWidgets('MensageriaView abre em modo Desktop sem travar',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await ThemeController.init();
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => PdvProvider()),
          ChangeNotifierProvider(create: (_) => NotificacoesProvider()),
        ],
        child: const MaterialApp(
          home: MensageriaView(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MensageriaView), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('PainelConversaAtivaWidget abre conversa de loja no Desktop sem travar',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await ThemeController.init();
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final controller = MensageriaController();
    final conversaLoja = ConversaChat(
      id: 'loja_berenice_usuario_47192956813',
      titulo: 'Berenice',
      subtitulo: 'Restaurante e Lanchonete • Centro',
      identificador: 'loja_berenice',
      ehLoja: true,
      lojaId: 'berenice',
      dataHoraUltimaMensagem: DateTime.now(),
    );
    controller.selecionarConversa(conversaLoja);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => PdvProvider()),
          ChangeNotifierProvider(create: (_) => NotificacoesProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: PainelConversaAtivaWidget(
              controller: controller,
              theme: ThemeController.currentTheme.value,
              desktop: true,
              onVoltarMobile: () {},
              onAbrirDetalhes: (_) {},
              onRenomearConversa: (_) {},
              onMostrarMenuMensagem: (_) {},
              onVerHistoricoEdicoes: (_) {},
              onAbrirArquivo: (_) {},
              onVisualizarFotoAmpliada: (_) {},
              onVerComanda: (_) {},
              onEnviarTexto: (_) {},
              onEnviarAudio: (_, __, ___) {},
              onCapturarFotoCamera: () {},
              onAnexarFoto: () {},
              onAnexarArquivo: () {},
              onCompartilharContato: () {},
              onCompartilharComanda: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Berenice'), findsOneWidget);

    controller.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });
}
