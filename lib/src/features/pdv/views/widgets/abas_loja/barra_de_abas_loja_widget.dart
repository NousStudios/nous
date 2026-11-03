import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/views/dados_perfil_view.dart' show AbaLoja;

class BarraDeAbasDaLojaWidget extends StatelessWidget {
  final AppTheme theme;
  final AbaLoja abaSelecionada;
  final ValueChanged<AbaLoja> aoTrocarAba;
  final double maxWidth;
  final bool ehLojaColetivaNous;

  const BarraDeAbasDaLojaWidget({
    super.key,
    required this.theme,
    required this.abaSelecionada,
    required this.aoTrocarAba,
    this.maxWidth = 1400.0,
    this.ehLojaColetivaNous = false,
  });

  String _rotulo(AbaLoja aba) {
    switch (aba) {
      case AbaLoja.dados:
        return 'Dados';
      case AbaLoja.interface:
        return 'Ajustes';
      case AbaLoja.loja:
        return 'Loja';
      case AbaLoja.gestao:
        return 'Gestão';
    }
  }

  @override
  Widget build(BuildContext context) {
    final larguraDaTela = MediaQuery.sizeOf(context).width;
    final sobra = larguraDaTela - maxWidth;
    final margemLateral = (sobra / 2).clamp(0.0, larguraDaTela / 2);

    final abas = ehLojaColetivaNous
        ? const [AbaLoja.dados, AbaLoja.gestao]
        : AbaLoja.values;

    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        border: Border(top: BorderSide(color: theme.borderColor)),
      ),
      padding: EdgeInsets.only(
        left: margemLateral + 12,
        right: margemLateral + 12,
        top: 10,
        bottom: 10,
      ),
      child: Row(
        children: abas.map((aba) {
          final selecionada = aba == abaSelecionada;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: BotaoAbaLojaWidget(
                theme: theme,
                rotulo: _rotulo(aba),
                selecionada: selecionada,
                aoClicar: () => aoTrocarAba(aba),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class BotaoAbaLojaWidget extends StatefulWidget {
  final AppTheme theme;
  final String rotulo;
  final bool selecionada;
  final VoidCallback aoClicar;

  const BotaoAbaLojaWidget({
    super.key,
    required this.theme,
    required this.rotulo,
    required this.selecionada,
    required this.aoClicar,
  });

  @override
  State<BotaoAbaLojaWidget> createState() => _BotaoAbaLojaWidgetState();
}

class _BotaoAbaLojaWidgetState extends State<BotaoAbaLojaWidget> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final selecionada = widget.selecionada;
    final fundoAtivo = theme.buttonColor != Colors.transparent
        ? theme.buttonColor
        : theme.borderColor.withValues(alpha: 0.25);
    final textoAtivo = theme.buttonColor != Colors.transparent
        ? theme.buttonTextColor
        : theme.textColor;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.aoClicar,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selecionada
                ? (_hover
                    ? (theme.buttonColor != Colors.transparent
                        ? theme.buttonColor.withValues(alpha: 0.85)
                        : theme.borderColor.withValues(alpha: 0.35))
                    : fundoAtivo)
                : (_hover
                    ? theme.borderColor.withValues(alpha: 0.18)
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selecionada || _hover
                  ? theme.textColor
                  : theme.borderColor.withValues(alpha: 0.45),
              width: selecionada ? 1.6 : 1.0,
            ),
          ),
          child: Text(
            widget.rotulo,
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 12,
              fontWeight: selecionada ? FontWeight.bold : FontWeight.normal,
              color: selecionada
                  ? textoAtivo
                  : (_hover ? theme.textColor : theme.secondaryTextColor),
            ),
          ),
        ),
      ),
    );
  }
}
