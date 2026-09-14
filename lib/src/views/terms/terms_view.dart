import 'package:flutter/material.dart';

class TermsView extends StatelessWidget {
  const TermsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Termos de Uso',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700), // Mantém a leitura confortável em telas grandes
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Termos e Condições de Uso - Nous',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Última atualização: Setembro de 2026',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        SizedBox(height: 24),
                        _SectionTitle(title: '1. Aceitação dos Termos'),
                        _SectionBody(
                          text: 'Ao acessar e utilizar a plataforma Nous, você concorda em cumprir e respeitar os presentes Termos de Uso. Caso não concorde com qualquer disposição, você não deve utilizar a aplicação.',
                        ),
                        _SectionTitle(title: '2. Sobre o Serviço'),
                        _SectionBody(
                          text: 'O Nous é uma plataforma de autogestão comercial e social focada em autonomia local, descentralização de serviços e privacidade dos dados do usuário.',
                        ),
                        _SectionTitle(title: '3. Privacidade e Proteção de Dados'),
                        _SectionBody(
                          text: 'Seus dados e informações de identificação (como CPF) são tratados com foco em segurança e confidencialidade, sendo utilizados estritamente para o funcionamento das ferramentas da plataforma.',
                        ),
                        _SectionTitle(title: '4. Modificações dos Termos'),
                        _SectionBody(
                          text: 'Reservamo-nos o direito de alterar estes termos a qualquer momento. Alterações significativas serão notificadas na própria aplicação.',
                        ),
                        SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                
                // Botão de confirmação/retorno
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Entendi e Concordo',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widgets auxiliares para padronizar a formatação das seções
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  final String text;
  const _SectionBody({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
        height: 1.5,
      ),
    );
  }
}