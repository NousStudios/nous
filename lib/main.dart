import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/theme/contrast_helper.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/views/login_view.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/backup_service.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BancoDadosService.inicializar();
  await ThemeController.init();
  // Dispara o snapshot de segurança diário em segundo plano sem travar a inicialização
  BackupService.realizarBackupAutomaticoSeNecessario();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PdvProvider()),
        ChangeNotifierProvider(create: (_) => NotificacoesProvider()),
      ],
      child: ValueListenableBuilder<AppTheme>(
        valueListenable: ThemeController.currentTheme,
        builder: (context, theme, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Nous',
            scrollBehavior: AppScrollBehavior(),
            theme: ThemeData(
              scaffoldBackgroundColor: theme.backgroundColor,
              scrollbarTheme: const ScrollbarThemeData(
                thumbVisibility: WidgetStatePropertyAll(false),
                trackVisibility: WidgetStatePropertyAll(false),
                thickness: WidgetStatePropertyAll(0),
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: theme.backgroundColor,
                foregroundColor: theme.textColor,
                elevation: 0,
              ),
              dialogTheme: DialogThemeData(
                backgroundColor: theme.cardBackgroundColor,
              ),
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: getBrightnessFor(theme.backgroundColor),
              ),
            ),
            home: const LoginView(),
          );
        },
      ),
    );
  }
}