import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

// Barra de navegação flutuante do APP inteiro (diferente da barra de
// abas "Dados/Interface/Loja/Gestão", que é só da tela de uma loja
// específica). Essa aqui vai aparecer em várias telas depois do login:
// carrinho (PDV/vendas), perfil, busca, lista/pedidos e "empresas"
// (trocar de loja). Por enquanto é só visual — os botões ainda não
// levam pra lugar nenhum, só mudam de cor quando tocados, esperando
// decidirmos as rotas de cada um.
//
// Fica em core/widgets/ (e não dentro de features/pdv/) porque essa
// barra não é exclusiva do PDV: a ideia é ela aparecer também no chat,
// na timeline, etc., no futuro.
class FloatingBottomNavBar extends StatefulWidget {
  // Largura máxima do bloco de CONTEÚDO da tela que está usando essa
  // barra (ex: 500 na tela de Dados do Perfil, 600 em Meus Perfis).
  // Cada tela passa o próprio número aqui, para a barra flutuante ficar
  // sempre alinhada com a largura do container de conteúdo dela — em
  // vez de usar uma margem fixa igual em toda tela.
  final double maxWidth;

  const FloatingBottomNavBar({super.key, required this.maxWidth});

  @override
  State<FloatingBottomNavBar> createState() => _FloatingBottomNavBarState();
}

class _FloatingBottomNavBarState extends State<FloatingBottomNavBar> {
  // Índice do ícone "aceso" agora. Só efeito visual por enquanto — como
  // ainda não navega pra lugar nenhum, começamos em 0 (carrinho) porque
  // é o coração do PDV.
  int _indiceSelecionado = 0;

  // Um ícone para cada botão, na mesma ordem do protótipo: carrinho,
  // perfil, busca, lista de pedidos e "empresa" (prédio, pra trocar de
  // loja).
  static const _icones = [
    Icons.shopping_cart_outlined,
    Icons.person_outline,
    Icons.search,
    Icons.receipt_long_outlined,
    Icons.store_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    // ---------------------------------------------------------------
    // Mesmo cálculo de margem usado em _BarraDeAbasDaLoja
    // (dados_perfil_view.dart): pega a largura total da tela, descobre
    // quanto "sobra" além da largura máxima de conteúdo pedida, e
    // divide essa sobra por 2 — esse é o espaço de cada lado. O
    // .clamp(0, ...) evita margem negativa em telas menores que
    // maxWidth.
    // ---------------------------------------------------------------
    final larguraDaTela = MediaQuery.sizeOf(context).width;
    final sobra = larguraDaTela - widget.maxWidth;
    final margemLateral = (sobra / 2).clamp(0.0, larguraDaTela / 2);

    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return Padding(
          // Espaço em volta da barra pra ela ficar "flutuando" — sem
          // tocar nas bordas da tela nem grudar no que tiver em cima
          // dela. margemLateral garante que a largura da barra bate
          // com a largura do container de conteúdo da tela.
          padding: EdgeInsets.fromLTRB(
            margemLateral + 24,
            0,
            margemLateral + 24,
            16,
          ),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: theme.cardBackgroundColor,
              // Arredondado nos 4 cantos — diferente da barra de abas
              // da loja, que só tem uma linha reta em cima. É esse
              // arredondamento que dá o efeito "flutuante" do protótipo.
              borderRadius: BorderRadius.circular(28),
              border:
                  Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_icones.length, (indice) {
                final selecionado = indice == _indiceSelecionado;
                return IconButton(
                  icon: Icon(
                    _icones[indice],
                    color:
                        selecionado ? theme.textColor : theme.secondaryTextColor,
                  ),
                  onPressed: () {
                    // todo: por enquanto só troca a cor do ícone tocado.
                    // Quando decidirmos as rotas (ex: ícone do carrinho
                    // leva pra onde?), a navegação de verdade entra aqui.
                    setState(() => _indiceSelecionado = indice);
                  },
                );
              }),
            ),
          ),
        );
      },
    );
  }
}