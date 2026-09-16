import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/features/auth/views/login_view.dart';
import 'package:nous/src/features/pdv/views/widgets/criar_perfil_dialog.dart';
import 'package:nous/src/features/pdv/views/dados_perfil_view.dart';

// Esta é a tela "raiz" do app, mostrada logo depois do login ou de
// "Entrar como visitante". Ela lista os perfis profissionais do usuário
// (por enquanto só a "Loja Padrão") e permite criar novos perfis.
class PerfisPdvView extends StatelessWidget {
  const PerfisPdvView({super.key});

  // Largura máxima que o bloco de conteúdo pode ter. Em telas largas
  // (tablet, desktop, navegador), o conteúdo para de crescer ao chegar
  // nesse valor e fica centralizado. Em telas estreitas (celular), como
  // a tela é menor que esse número, essa regra nem chega a "entrar em
  // ação" — o bloco continua ocupando a largura disponível normalmente.
  static const double _larguraMaximaConteudo = 600;

  // Função chamada quando o usuário clica em "Sair" dentro do popup de
  // Configurações. pushAndRemoveUntil troca de tela E apaga toda a pilha de
  // navegação anterior — ou seja, depois disso não existe mais "voltar" para
  // a tela de Perfis por engano; a única forma de chegar aqui de novo é
  // fazendo login/entrando como visitante outra vez.
  void _handleLogout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginView()),
      (route) => false, // false para TODAS as rotas = apaga tudo
    );
  }

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder reconstrói essa tela toda vez que o tema
    // (cores, fonte, etc.) muda — é assim que o app troca de tema em
    // tempo real, sem precisar recarregar a tela.
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: CustomAppBar(
            title: 'Meus Perfis',
            // false: esta é a "tela raiz" pós-login/visitante. Não existe
            // "voltar" para o login a partir daqui — só existe ir PRA
            // FRENTE, para outras telas do app.
            showBackButton: false,
            onLogout: () => _handleLogout(context),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              // IMPORTANTE: mudamos de CrossAxisAlignment.start para
              // .stretch. Isso faz o Column "esticar" seus filhos para
              // ocupar toda a largura disponível. Sem isso, o Center logo
              // abaixo não teria uma largura de referência para centralizar
              // o conteúdo — ele simplesmente encolheria para o tamanho do
              // próprio conteúdo e ficaria "preso" no canto esquerdo.
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Center: pega toda a largura que o Column deu a ele
                  // (a tela toda, menos o padding) e centraliza o filho
                  // dentro desse espaço.
                  Center(
                    child: ConstrainedBox(
                      // ConstrainedBox: é o "container invisível" que você
                      // pediu. Ele não desenha nada na tela sozinho, só
                      // limita o tamanho máximo do que está dentro dele.
                      constraints: const BoxConstraints(
                        maxWidth: _larguraMaximaConteudo,
                      ),
                      child: Container(
                        // width: double.infinity continua aqui de
                        // propósito: ele faz o card visual ocupar toda a
                        // largura QUE FOI PERMITIDA pelo ConstrainedBox
                        // acima (ou seja, até 600 de largura, ou menos se
                        // a tela for menor que isso).
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.backgroundColor.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.borderColor.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Column(
                          // Aqui dentro mantemos .start: queremos que o
                          // título e o card "Loja Padrão" fiquem alinhados
                          // à esquerda DENTRO do card, só o card inteiro
                          // que fica centralizado na tela.
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Center aqui centraliza o título dentro da
                            // largura do card. Funciona pelo mesmo motivo
                            // que o botão "Criar Perfil" logo abaixo já
                            // fica centralizado: o Column externo usa
                            // .stretch, então esse Container recebe uma
                            // largura definida, e o Center consegue usar
                            // essa largura para centralizar seu filho.
                            Center(
                              child: Text(
                                'Meus Perfis Profissionais',
                                style: theme.getTextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            _PerfilCard(
                              theme: theme,
                              icon: Icons.storefront,
                              label: 'Loja Padrão',
                              onTap: () {
                                // Por enquanto não existe nenhum lugar
                                // guardando os dados reais da loja (isso
                                // vai vir com um PdvProvider no futuro),
                                // então abrimos a tela sem nada
                                // preenchido.
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const DadosPerfilView(),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 20),

                            // Center aqui dentro do card centraliza só o
                            // botão "Criar Perfil" dentro da largura do
                            // próprio card (isso já existia antes e
                            // continua igual).
                            Center(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: theme.textColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  side: BorderSide(color: theme.borderColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  // Abre o popup de escolha de categoria
                                  // por cima da tela atual. showDialog já
                                  // escurece o fundo sozinho — é esse
                                  // efeito de "tela ofuscada atrás" que
                                  // você viu na sua captura de tela.
                                  showCriarPerfilDialog(context);
                                },
                                icon: Icon(
                                  Icons.add,
                                  color: theme.textColor,
                                  size: 18,
                                ),
                                label: Text(
                                  'Criar Perfil',
                                  style: theme.getTextStyle(
                                    fontSize: 14,
                                    color: theme.textColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Widget que representa um "cartão" clicável de perfil (ex: a Loja Padrão).
// É reaproveitável: no futuro, cada novo perfil criado pelo usuário pode
// usar esse mesmo widget, só mudando o ícone e o texto.
//
// Agora ele é um StatefulWidget (antes era Stateless) porque precisa
// guardar uma informação que muda com o tempo: se o mouse está ou não em
// cima do card neste exato momento (_hovering, lá na classe de Estado
// abaixo). Um StatelessWidget não tem como "lembrar" disso.
class _PerfilCard extends StatefulWidget {
  final AppTheme theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PerfilCard({
    required this.theme,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_PerfilCard> createState() => _PerfilCardState();
}

class _PerfilCardState extends State<_PerfilCard> {
  // true enquanto o cursor do mouse estiver em cima do card. Isso só é
  // relevante em telas com mouse (web/desktop) — no celular, como não
  // existe cursor "pairando" sobre a tela, essa variável nunca vira true,
  // e o card simplesmente fica sempre com a cor normal, exatamente como
  // se esse recurso não existisse. Ou seja: nada quebra no celular.
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    // Como agora estamos numa classe de Estado (State), os dados que
    // vieram de fora (theme, icon, label, onTap) não ficam mais direto em
    // "this.theme" etc., e sim dentro de "widget.theme", "widget.icon"...
    final theme = widget.theme;

    // MouseRegion "escuta" quando o cursor do mouse entra e sai da área
    // do widget filho. onEnter e onExit disparam setState(), que avisa o
    // Flutter: "os dados mudaram, redesenhe esse widget" — é assim que a
    // troca de cor aparece na tela.
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        // AnimatedContainer é igual a um Container comum, mas quando uma
        // das propriedades dele muda (aqui, a cor de fundo), ele faz uma
        // transição suave até o novo valor em vez de trocar de repente.
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 100,
          height: 100,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            // Aqui está a regra pedida: com o mouse em cima, o fundo do
            // card usa buttonColor — a mesma cor de fundo usada em todos
            // os botões sólidos do app. Sem o mouse em cima, volta para a
            // cor normal do card (cardBackgroundColor).
            color: _hovering ? theme.buttonColor : theme.cardBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.borderColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 32,
                // O ícone também troca de cor junto: quando o fundo vira
                // buttonColor, o ícone (e o texto logo abaixo) passam a
                // usar buttonTextColor, do mesmo jeito que o texto dos
                // botões do app muda de cor conforme o fundo do botão.
                color: _hovering
                    ? theme.buttonTextColor
                    : theme.secondaryTextColor,
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: _hovering ? theme.buttonTextColor : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}