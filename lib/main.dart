import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/theme/contrast_helper.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/views/login_view.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';

// NOVO: classe que ensina o Flutter a tratar o MOUSE também como um
// jeito válido de "arrastar para rolar" uma lista. Por padrão, o
// Flutter só reconhece toque (dedo) e caneta para isso — no
// computador, com mouse, o comportamento padrão é só usar a barra de
// rolagem ou a rodinha, sem poder clicar-e-arrastar. Essa classe
// herda o comportamento padrão do Material (MaterialScrollBehavior) e
// só adiciona o mouse (e o trackpad) na lista de "dispositivos que
// podem arrastar para rolar".
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

Future<void> main() async {
  // Garante que o Flutter está pronto para operações assíncronas antes do runApp,
  // necessário porque vamos carregar os temas salvos do armazenamento do aparelho.
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega os temas que o usuário salvou em sessões anteriores, antes de exibir qualquer tela.
  await ThemeController.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider serve para registrar VÁRIOS providers de uma vez, sem
    // precisar aninhar um ChangeNotifierProvider dentro do outro à mão.
    // Cada item da lista "providers" abaixo funciona exatamente como o
    // ChangeNotifierProvider único que já existia antes — cada um cria UMA
    // instância da sua classe quando o app abre, e disponibiliza ela para
    // toda a árvore de widgets abaixo (ou seja, para o app inteiro, já que
    // isso envolve o MaterialApp).
    //
    // Qualquer tela vai poder acessar tanto o AuthProvider (dados de login)
    // quanto o PdvProvider (dados da loja/perfil) com context.watch<...>()
    // ou context.read<...>(), sem precisar receber nada por parâmetro.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PdvProvider()),
      ],
      child: ValueListenableBuilder<AppTheme>(
        // ValueListenableBuilder continua aqui do mesmo jeito que estava —
        // ele cuida do TEMA (cores/fonte), que é um assunto separado dos
        // providers acima (que cuidam de LOGIN e de DADOS DO PDV). Cada um
        // cuida da sua parte.
        valueListenable: ThemeController.currentTheme,
        builder: (context, theme, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Nous',
            // NOVO: diz para o app inteiro usar o comportamento de
            // rolagem customizado acima, que libera o mouse para
            // "clicar e arrastar" em qualquer lista rolável do app
            // (inclusive a lista horizontal de "Itens").
            scrollBehavior: AppScrollBehavior(),
            theme: ThemeData(
              // Define a cor de fundo padrão de todos os Scaffolds do app
              scaffoldBackgroundColor: theme.backgroundColor,

              // Define a cor da AppBar globalmente
              appBarTheme: AppBarTheme(
                backgroundColor: theme.backgroundColor,
                foregroundColor: theme.textColor,
                elevation: 0,
              ),

              // Define a cor de diálogos/modais
              dialogTheme: DialogThemeData(
                backgroundColor: theme.cardBackgroundColor,
              ),

              // Define o tema de cores base do Material
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                // Calcula o brilho de verdade, com base na luminância da cor de fundo
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