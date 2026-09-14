import 'package:flutter/material.dart';

// Importe seus widgets das pastas locais
import 'package:nous/src/views/login/widgets/cpf_input_widget.dart';
import 'package:nous/src/views/login/widgets/login_buttons_widget.dart';
import 'package:nous/src/views/login/widgets/logo_widget.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
                  
                  // Componente do Logo
                  const LogoWidget(),
                  const SizedBox(height: 16),

                  // Título e Subtítulo
                  const Text(
                    'Nous',
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Software Universal de Autogestão\nComercial e Social',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 40),

                  // Componentes Modulares
                  const CpfInputWidget(),
                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Leia os Termos de Uso',
                      style: TextStyle(
                        color: Colors.grey,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botões de Ação
                  const LoginButtonsWidget(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}