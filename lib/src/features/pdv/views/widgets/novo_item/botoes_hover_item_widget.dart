import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Botão com efeito hover para seleção de Unidade de Medida (un, g, ml).
class BotaoHoverUnidade extends StatefulWidget {
  final AppTheme theme;
  final String rotulo;
  final bool selecionado;
  final VoidCallback aoClicar;

  const BotaoHoverUnidade({
    super.key,
    required this.theme,
    required this.rotulo,
    required this.selecionado,
    required this.aoClicar,
  });

  @override
  State<BotaoHoverUnidade> createState() => _BotaoHoverUnidadeState();
}

class _BotaoHoverUnidadeState extends State<BotaoHoverUnidade> {
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
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: corFundo,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: corBorda,
              width: ativo ? 1.6 : 1.0,
            ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.rotulo,
                maxLines: 1,
                style: theme.getTextStyle(
                  fontSize: 12,
                  fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
                  color: corTexto,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão com efeito hover para seleção de Tipo de Item (Produto vs Serviço).
class BotaoHoverTipoItem extends StatefulWidget {
  final AppTheme theme;
  final String rotulo;
  final IconData icone;
  final bool selecionado;
  final VoidCallback aoClicar;

  const BotaoHoverTipoItem({
    super.key,
    required this.theme,
    required this.rotulo,
    required this.icone,
    required this.selecionado,
    required this.aoClicar,
  });

  @override
  State<BotaoHoverTipoItem> createState() => _BotaoHoverTipoItemState();
}

class _BotaoHoverTipoItemState extends State<BotaoHoverTipoItem> {
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
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: corFundo,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: corBorda,
              width: ativo ? 1.6 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icone,
                size: 16,
                color: corTexto,
              ),
              const SizedBox(width: 8),
              Text(
                widget.rotulo,
                style: theme.getTextStyle(
                  fontSize: 12,
                  fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
                  color: corTexto,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                ativo
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 15,
                color: ativo ? corTexto : theme.secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
