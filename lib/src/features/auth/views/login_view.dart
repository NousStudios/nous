import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/views/widgets/cpf_input_widget.dart';
import 'package:nous/src/features/auth/views/widgets/login_buttons_widget.dart';
import 'package:nous/src/features/auth/views/widgets/logo_widget.dart';
import 'package:nous/src/features/auth/views/terms_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  @override
  void initState() {
    super.initState();
    ThemeController.isLoginScreen = true;
  }

  @override
  void dispose() {
    ThemeController.isLoginScreen = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.backgroundColor,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      const LogoWidget(),
                      const SizedBox(height: 16),
                      Text(
                        'Nous',
                        style: theme.getTextStyle(
                          fontSize: 36,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Software Universal de Autogestão\nComercial e Social',
                        textAlign: TextAlign.center,
                        style: theme.getTextStyle(
                          fontSize: 16,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 40),
                      const CpfInputWidget(),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TermsView(),
                            ),
                          );
                        },
                        child: Text(
                          'Leia os Termos de Uso',
                          style: theme.getTextStyle(
                            fontSize: 14,
                            color: theme.secondaryTextColor,
                          ).copyWith(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const LoginButtonsWidget(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}