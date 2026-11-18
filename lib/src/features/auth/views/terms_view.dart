// IMPORTS: Trazem os pacotes e componentes necessários para construir a tela
import 'package:flutter/material.dart';

// IMPORT DO CONTROLLER DE TEMA: Para redefinir dinamicamente cores e fontes
import 'package:nous/src/core/theme/theme_controller.dart';

// IMPORT DO NOSSO COMPONENTE: Traz a barra superior customizada com o botão de configurações
import 'package:nous/src/core/widgets/custom_app_bar.dart';

// Widget principal da tela de Termos de Uso e Política de Privacidade (LGPD)
class TermsView extends StatelessWidget {
  static const String versaoAtual = '1.0-lgpd-2026';

  const TermsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: const CustomAppBar(
            title: 'Termos e Privacidade (LGPD)',
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Termos de Uso e Política de Privacidade (LGPD) — Nous',
                              style: theme.getTextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                            const SizedBox(height: 12),

                            Text(
                              'Versão $versaoAtual • Atualizado em Novembro de 2026',
                              style: theme.getTextStyle(
                                fontSize: 12,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 24),

                            _SectionTitle(title: '1. Aceitação e Escopo', theme: theme),
                            _SectionBody(
                              text: 'Ao criar sua Conta Nous ou utilizar a plataforma, você concorda com estes Termos de Uso e com esta Política de Privacidade, elaborada em conformidade com a Lei Geral de Proteção de Dados (Lei nº 13.709/2018 — LGPD).',
                              theme: theme,
                            ),

                            _SectionTitle(title: '2. Arquitetura Local-First e Soberania', theme: theme),
                            _SectionBody(
                              text: 'O Nous é um software livre e local-first. Seus dados são armazenados localmente no banco SQLite do seu próprio dispositivo, sem servidores centrais de Big Techs, sem venda de dados e sem rastreadores de publicidade.',
                              theme: theme,
                            ),

                            _SectionTitle(title: '3. Dados Pessoais Tratados e Finalidades (Art. 9º LGPD)', theme: theme),
                            _SectionBody(
                              text: '• Identificação (CPF e Nome): usados como identidade única soberana para vincular seu perfil, lojas e histórico sem depender de hardware.\n• Contato e Perfil (e-mail, @username, foto, biografia): usados para autenticação, recuperação de acesso e interação social.\n• Dados Trabalhistas e Comerciais (ponto, escala, pagamentos, vendas, clientes): usados exclusivamente para autogestão e transparência dentro das lojas de que você participa.',
                              theme: theme,
                            ),

                            _SectionTitle(title: '4. Privacidade por Padrão e Rede Local Wi-Fi', theme: theme),
                            _SectionBody(
                              text: 'Todas as informações pessoais e trabalhistas da sua Conta Nous nascem ocultas por padrão, exceto o nome. Você decide o que tornar público e para qual CPF autorizar acesso. Na mesma rede Wi-Fi local, os dados necessários à operação da loja ou conversa são sincronizados diretamente entre os dispositivos participantes, com criptografia ponta a ponta (E2EE) nas mensagens diretas.',
                              theme: theme,
                            ),

                            _SectionTitle(title: '5. Seus Direitos como Titular (Art. 18 LGPD)', theme: theme),
                            _SectionBody(
                              text: 'Você pode, a qualquer momento diretamente no app:\n• Acessar e corrigir seus dados na Conta Nous;\n• Exportar todos os seus dados em arquivo JSON único (Portabilidade/Backup);\n• Revogar autorizações de visualização concedidas a outros CPFs;\n• Excluir permanentemente sua conta e seus dados locais ("Excluir Conta").',
                              theme: theme,
                            ),

                            _SectionTitle(title: '6. Retenção, Segurança e Encarregado (DPO)', theme: theme),
                            _SectionBody(
                              text: 'Os dados permanecem armazenados localmente enquanto você mantiver sua conta ou loja ativa, observando obrigações legais fiscais/trabalhistas quando aplicável. Dúvidas ou solicitações sobre privacidade podem ser encaminhadas pelo canal oficial do projeto Nous junto ao administrador da rede ou mantenedor responsável.',
                              theme: theme,
                            ),

                            _SectionTitle(title: '7. Atualizações desta Política', theme: theme),
                            _SectionBody(
                              text: 'Alterações relevantes nesta política serão versionadas e apresentadas no próprio aplicativo para ciência e novo registro de consentimento quando necessário.',
                              theme: theme,
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    ElevatedButton(
                      // Botão "Entendi e Concordo" — agora com borda (Cor das Arestas) também,
                      // além do fundo (Cor dos Botões) e do texto (Cor do Texto dos Botões).
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.buttonColor,
                        foregroundColor: theme.buttonTextColor,
                        minimumSize: const Size.fromHeight(50),
                        side: BorderSide(color: theme.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        'Entendi e Concordo',
                        style: theme.getTextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.buttonTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ==============================================================================
// WIDGETS AUXILIARES
// ==============================================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  final AppTheme theme;

  const _SectionTitle({
    required this.title,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: theme.getTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: theme.secondaryTextColor,
        ),
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  final String text;
  final AppTheme theme;

  const _SectionBody({
    required this.text,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: theme.getTextStyle(
        fontSize: 14,
        color: theme.secondaryTextColor,
      ),
    );
  }
}