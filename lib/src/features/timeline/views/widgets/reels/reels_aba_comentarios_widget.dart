import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Aba inferior recolhida de comentários do visualizador Reels compacto.
/// Abre o painel de comentários ao tocar ou arrastar para cima.
class ReelsAbaComentariosWidget extends StatefulWidget {
  final AppTheme theme;
  final int totalComentarios;
  final VoidCallback onAbrir;

  const ReelsAbaComentariosWidget({
    super.key,
    required this.theme,
    required this.totalComentarios,
    required this.onAbrir,
  });

  @override
  State<ReelsAbaComentariosWidget> createState() =>
      _ReelsAbaComentariosWidgetState();
}

class _ReelsAbaComentariosWidgetState extends State<ReelsAbaComentariosWidget> {
  double _arrastoPendente = 0.0;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onAbrir,
      onVerticalDragStart: (_) => _arrastoPendente = 0.0,
      onVerticalDragUpdate: (d) {
        _arrastoPendente += d.delta.dy;
      },
      onVerticalDragEnd: (d) {
        if (_arrastoPendente < -20 || (d.primaryVelocity ?? 0) < -180) {
          widget.onAbrir();
        }
      },
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: theme.cardBackgroundColor.withValues(alpha: 0.94),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(16),
          ),
          border: Border(
            top: BorderSide(
              color: theme.borderColor.withValues(alpha: 0.45),
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 3.5,
              margin: const EdgeInsets.only(bottom: 5),
              decoration: BoxDecoration(
                color: theme.secondaryTextColor.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 16,
                  color: theme.secondaryTextColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'Comentários (${widget.totalComentarios})',
                  style: theme.getTextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
