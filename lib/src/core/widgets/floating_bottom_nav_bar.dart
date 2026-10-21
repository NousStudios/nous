import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/views/perfil_social_view.dart';
import 'package:nous/src/features/pdv/views/perfis_pdv_view.dart';

// Barra de navegação flutuante universal do APP.
// 0: Carrinho (Meus Perfis / PDV)
// 1: Perfil Social do Usuário Nous
// 2: Busca
// 3: Lista / Pedidos
// 4: Trocar de Loja / Prédio
class FloatingBottomNavBar extends StatefulWidget {
  final double maxWidth;
  final int indiceSelecionado;
  final ValueChanged<int>? onTrocarIndice;

  const FloatingBottomNavBar({
    super.key,
    required this.maxWidth,
    this.indiceSelecionado = 0,
    this.onTrocarIndice,
  });

  @override
  State<FloatingBottomNavBar> createState() => _FloatingBottomNavBarState();
}

class _FloatingBottomNavBarState extends State<FloatingBottomNavBar> {
  late int _indiceAtual;

  static const _icones = [
    Icons.shopping_cart_outlined,
    Icons.person_outline,
    Icons.search,
    Icons.receipt_long_outlined,
    Icons.store_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _indiceAtual = widget.indiceSelecionado;
  }

  @override
  void didUpdateWidget(covariant FloatingBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.indiceSelecionado != widget.indiceSelecionado) {
      _indiceAtual = widget.indiceSelecionado;
    }
  }

  void _aoTocarIcone(int indice) {
    if (widget.onTrocarIndice != null) {
      widget.onTrocarIndice!(indice);
      return;
    }

    if (indice == _indiceAtual) return;

    if (indice == 0) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PerfisPdvView()),
        (route) => route.isFirst,
      );
    } else if (indice == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PerfilSocialView()),
      );
    } else {
      setState(() => _indiceAtual = indice);
    }
  }

  @override
  Widget build(BuildContext context) {
    final larguraDaTela = MediaQuery.sizeOf(context).width;
    final sobra = larguraDaTela - widget.maxWidth;
    final margemLateral = (sobra / 2).clamp(0.0, larguraDaTela / 2);

    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return Padding(
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
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_icones.length, (indice) {
                final selecionado = indice == _indiceAtual;
                return IconButton(
                  icon: Icon(
                    _icones[indice],
                    color: selecionado
                        ? theme.textColor
                        : theme.secondaryTextColor,
                  ),
                  onPressed: () => _aoTocarIcone(indice),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}