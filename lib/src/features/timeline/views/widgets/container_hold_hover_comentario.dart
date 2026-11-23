import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';

/// Envolve o container de um comentário com uma animação progressiva de hover
/// ao segurar (420 ms) antes de abrir o menu contextual de Fixar/Excluir,
/// além de suportar clique direito no desktop.
class ContainerHoldHoverComentario extends StatefulWidget {
  final AppTheme theme;
  final bool habilitado;
  final BorderRadius borderRadius;
  final Widget child;
  final ValueChanged<Offset> onAbrirMenu;

  const ContainerHoldHoverComentario({
    super.key,
    required this.theme,
    required this.habilitado,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    required this.child,
    required this.onAbrirMenu,
  });

  /// Menu contextual padrão do Nous para comentários (Fixar / Desafixar / Excluir).
  static Future<void> mostrarMenuAcoesComentario(
    BuildContext context, {
    required AppTheme theme,
    required ComentarioSocial comentario,
    required bool ehAutorPublicacao,
    required String meuCpfLimpo,
    required Offset posicaoGlobal,
    required ValueChanged<ComentarioSocial> onAlternarFixar,
    required ValueChanged<ComentarioSocial> onExcluir,
  }) async {
    final ehMeuComentario =
        meuCpfLimpo.isNotEmpty &&
        comentario.autorCpf.replaceAll(RegExp(r'\D'), '') == meuCpfLimpo;
    if (!ehAutorPublicacao && !ehMeuComentario) return;

    final box = Overlay.maybeOf(context)?.context.findRenderObject()
        as RenderBox?;
    final tamanhoTela = box?.size ?? MediaQuery.sizeOf(context);
    final position = RelativeRect.fromLTRB(
      posicaoGlobal.dx - 70,
      (posicaoGlobal.dy - 92).clamp(8.0, tamanhoTela.height - 96),
      tamanhoTela.width - posicaoGlobal.dx - 70,
      tamanhoTela.height - posicaoGlobal.dy,
    );

    final acao = await showMenu<String>(
      context: context,
      color: theme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      position: position,
      items: [
        if (ehAutorPublicacao)
          PopupMenuItem<String>(
            value: 'fixar',
            height: 36,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  comentario.fixado
                      ? Icons.push_pin_outlined
                      : Icons.push_pin_rounded,
                  size: 16,
                  color: theme.textColor,
                ),
                const SizedBox(width: 8),
                Text(
                  comentario.fixado ? 'Desafixar' : 'Fixar',
                  style: theme.getTextStyle(
                    fontSize: 12.5,
                    color: theme.textColor,
                  ),
                ),
              ],
            ),
          ),
        if (ehAutorPublicacao || ehMeuComentario)
          PopupMenuItem<String>(
            value: 'excluir',
            height: 36,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: theme.dangerColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Excluir',
                  style: theme.getTextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: theme.dangerColor,
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    if (acao == 'fixar') {
      onAlternarFixar(comentario);
    } else if (acao == 'excluir') {
      onExcluir(comentario);
    }
  }

  @override
  State<ContainerHoldHoverComentario> createState() =>
      _ContainerHoldHoverComentarioState();
}

class _ContainerHoldHoverComentarioState
    extends State<ContainerHoldHoverComentario>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  Offset _ultimaPosicao = Offset.zero;
  bool _disparou = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_disparou && mounted) {
          _disparou = true;
          widget.onAbrirMenu(_ultimaPosicao);
          _ctrl.value = 0.0;
        }
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _iniciarSegurar(Offset posicao) {
    if (!widget.habilitado) return;
    _disparou = false;
    _ultimaPosicao = posicao;
    _ctrl.forward(from: 0.0);
  }

  void _cancelarSegurar() {
    if (!_disparou && _ctrl.isAnimating) {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onSecondaryTapUp: widget.habilitado
          ? (d) => widget.onAbrirMenu(d.globalPosition)
          : null,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (e) {
          if (e.buttons == 1 || e.buttons == 0) {
            _iniciarSegurar(e.position);
          }
        },
        onPointerMove: (e) {
          _ultimaPosicao = e.position;
        },
        onPointerUp: (_) => _cancelarSegurar(),
        onPointerCancel: (_) => _cancelarSegurar(),
        child: ClipRRect(
          borderRadius: widget.borderRadius,
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, _) {
                    if (_ctrl.value <= 0.001) return const SizedBox.shrink();
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _ctrl.value,
                      child: Container(
                        color: widget.theme.textColor.withValues(alpha: 0.09),
                      ),
                    );
                  },
                ),
              ),
              widget.child,
            ],
          ),
        ),
      ),
    );
  }
}
