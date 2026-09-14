// IMPORTS: Trazem os pacotes e componentes necessários para construir a tela
import 'package:flutter/material.dart';

// IMPORT DO NOSSO COMPONENTE: Traz a barra superior customizada com o botão de configurações
import 'package:nous/src/core/widgets/custom_app_bar.dart';

// Widget principal da tela de Termos de Uso (Stateless pois não altera estado internamente)
class TermsView extends StatelessWidget {
  const TermsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold é a estrutura visual base de qualquer tela no Flutter (com suporte a barra top, fundo, etc.)
    return Scaffold(
      // Define a cor de fundo da tela inteira como preta
      backgroundColor: Colors.black,
      
      // Chamada da nossa CustomAppBar que possui o botão de configurações no canto superior direito
      appBar: const CustomAppBar(
        title: 'Termos de Uso',
      ),
      
      // Corpo principal da tela
      body: Center(
        // ConstrainedBox limita a largura máxima da área de leitura em 700px (ótimo para telas largas de tablets/PC)
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
            // Define o espaçamento interno nas laterais (24px) e topo/base (16px)
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                // Expanded faz o conteúdo de texto ocupar todo o espaço vertical disponível acima do botão
                Expanded(
                  // SingleChildScrollView permite rolar o texto se ele for maior que a tela do celular
                  child: SingleChildScrollView(
                    child: Column(
                      // Alinha os textos à esquerda
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        // Título principal do documento
                        Text(
                          'Termos e Condições de Uso - Nous',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16), // Espaçamento vertical
                        
                        // Data de revisão dos termos
                        Text(
                          'Última atualização: Setembro de 2026',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        SizedBox(height: 24),
                        
                        // SEÇÕES DOS TERMOS DE USO (usando nossos widgets auxiliares criados no final do arquivo)
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
                
                // ESPAÇO E BOTÃO DE CONFIRMAÇÃO (Fica fixo na parte inferior da tela)
                const SizedBox(height: 16),
                ElevatedButton(
                  // Estilização visual do botão arredondado branco
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(50), // Largura total e altura de 50px
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // Bordas bem arredondadas
                    ),
                  ),
                  // Navigator.pop fecha a tela atual e retorna para a tela anterior (Login)
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

// ==============================================================================
// WIDGETS AUXILIARES
// Facilitam a reutilização do código dos títulos e textos para manter o padrão visual
// ==============================================================================

// Helper para títulos de seção
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

// Helper para o texto explicativo das seções
class _SectionBody extends StatelessWidget {
  final String text;
  const _SectionBody({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70, // Texto levemente transparente para contraste agradável
        fontSize: 14,
        height: 1.5, // Altura da linha para melhorar a leitura
      ),
    );
  }
}