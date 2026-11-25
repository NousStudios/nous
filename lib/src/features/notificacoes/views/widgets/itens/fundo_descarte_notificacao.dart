import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Fundo exibido ao arrastar um card de notificação para dispensá-lo.
class FundoDescarteNotificacao extends StatelessWidget {
  final AppTheme theme;
  final AlignmentGeometry alignment;

  const FundoDescarteNotificacao({
    super.key,
    required this.theme,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.dangerColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.visibility_off_outlined,
        color: theme.dangerColor,
        size: 20,
      ),
    );
  }
}
