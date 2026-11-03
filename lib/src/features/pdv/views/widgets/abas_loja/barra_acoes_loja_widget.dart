import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Barra de ações horizontais da aba Loja (Novo Item, Nova Categoria, Novo Grupo, Estoque).
class BarraAcoesLojaWidget extends StatelessWidget {
  final AppTheme theme;
  final double maxWidth;
  final VoidCallback onNovoItem;
  final VoidCallback onNovaCategoria;
  final VoidCallback onNovoGrupo;
  final VoidCallback onEstoque;

  const BarraAcoesLojaWidget({
    super.key,
    required this.theme,
    required this.maxWidth,
    required this.onNovoItem,
    required this.onNovaCategoria,
    required this.onNovoGrupo,
    required this.onEstoque,
  });

  static Widget botaoAcao(
    AppTheme theme,
    String rotulo,
    VoidCallback onPressed, {
    IconData? icone,
    Color? corDestaque,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: corDestaque ?? theme.textColor,
        side: BorderSide(color: corDestaque ?? theme.borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[
            Icon(icone, size: 14, color: corDestaque ?? theme.textColor),
            const SizedBox(width: 6),
          ],
          Text(
            rotulo,
            style: theme.getTextStyle(
              fontSize: 12,
              color: corDestaque ?? theme.textColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: theme.backgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                botaoAcao(theme, 'Novo Item', onNovoItem),
                const SizedBox(width: 8),
                botaoAcao(theme, 'Nova Categoria', onNovaCategoria),
                const SizedBox(width: 8),
                botaoAcao(theme, 'Novo Grupo', onNovoGrupo),
                const SizedBox(width: 8),
                botaoAcao(theme, 'Estoque', onEstoque),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
