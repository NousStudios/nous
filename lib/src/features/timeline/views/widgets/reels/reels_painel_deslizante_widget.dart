import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Painel animado deslizante reutilizado pelas abas de comentários e descrição
/// completa do visualizador Reels compacto.
class ReelsPainelDeslizanteWidget extends StatefulWidget {
  final AppTheme theme;
  final bool aberto;
  final double alturaTotal;
  final double fatorTopo;
  final String titulo;
  final Widget? acaoEsquerda;
  final EdgeInsetsGeometry paddingConteudo;
  final Widget conteudo;
  final Widget? rodape;
  final VoidCallback onFechar;

  const ReelsPainelDeslizanteWidget({
    super.key,
    required this.theme,
    required this.aberto,
    required this.alturaTotal,
    required this.fatorTopo,
    required this.titulo,
    this.acaoEsquerda,
    this.paddingConteudo = const EdgeInsets.all(14),
    required this.conteudo,
    this.rodape,
    required this.onFechar,
  });

  @override
  State<ReelsPainelDeslizanteWidget> createState() =>
      _ReelsPainelDeslizanteWidgetState();
}

class _ReelsPainelDeslizanteWidgetState
    extends State<ReelsPainelDeslizanteWidget> {
  double _arrastoPendente = 0.0;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final topoAberto = widget.alturaTotal * widget.fatorTopo;
    final fundoFechado = -widget.alturaTotal * (1.0 - widget.fatorTopo);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      left: 0,
      right: 0,
      top: widget.aberto ? topoAberto : widget.alturaTotal,
      bottom: widget.aberto ? 0 : fundoFechado,
      child: Material(
        color: theme.cardBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(18),
            ),
            border: Border(
              top: BorderSide(
                color: theme.borderColor.withValues(alpha: 0.55),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: (_) => _arrastoPendente = 0.0,
                onVerticalDragUpdate: (d) {
                  _arrastoPendente += d.delta.dy;
                },
                onVerticalDragEnd: (d) {
                  if (_arrastoPendente > 24 ||
                      (d.primaryVelocity ?? 0) > 180) {
                    widget.onFechar();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color:
                              theme.secondaryTextColor.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (widget.acaoEsquerda != null)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: widget.acaoEsquerda!,
                            ),
                          Center(
                            child: Text(
                              widget.titulo,
                              style: theme.getTextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                Icons.close_rounded,
                                color: theme.secondaryTextColor,
                              ),
                              onPressed: widget.onFechar,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Divider(
                height: 1,
                color: theme.borderColor.withValues(alpha: 0.35),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: widget.paddingConteudo,
                  child: widget.conteudo,
                ),
              ),
              if (widget.rodape != null) widget.rodape!,
            ],
          ),
        ),
      ),
    );
  }
}
