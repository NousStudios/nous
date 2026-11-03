import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Botão com efeito hover para seleção de tipo de movimento de estoque (Entrada/Saída).
class BotaoHoverTipoEstoque extends StatefulWidget {
  final AppTheme theme;
  final String rotulo;
  final bool selecionado;
  final VoidCallback aoClicar;

  const BotaoHoverTipoEstoque({
    super.key,
    required this.theme,
    required this.rotulo,
    required this.selecionado,
    required this.aoClicar,
  });

  @override
  State<BotaoHoverTipoEstoque> createState() => _BotaoHoverTipoEstoqueState();
}

class _BotaoHoverTipoEstoqueState extends State<BotaoHoverTipoEstoque> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final ativo = widget.selecionado;
    final corAtiva = theme.buttonColor != Colors.transparent
        ? theme.buttonColor
        : theme.borderColor.withValues(alpha: 0.25);

    final corFundo = ativo
        ? (_hover ? corAtiva.withValues(alpha: 0.35) : corAtiva)
        : (_hover
            ? theme.borderColor.withValues(alpha: 0.12)
            : Colors.transparent);

    final corBorda = ativo
        ? theme.textColor
        : (_hover
            ? theme.borderColor
            : theme.borderColor.withValues(alpha: 0.6));

    final corTexto = ativo
        ? (theme.buttonColor != Colors.transparent
            ? theme.buttonTextColor
            : theme.textColor)
        : theme.textColor;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.aoClicar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: corFundo,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: corBorda,
              width: ativo ? 1.6 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              widget.rotulo,
              style: theme.getTextStyle(
                fontSize: 12,
                fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
                color: corTexto,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
