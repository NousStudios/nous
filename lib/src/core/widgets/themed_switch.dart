import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Componente padronizado de Switch (On/Off) do Nous.
/// Mantém alto contraste e excelente legibilidade em temas escuros e claros,
/// com polegar iluminado em [textColor], trilha ativa com contraste em [borderColor]
/// e contorno nítido no estado desligado.
class ThemedSwitch extends StatelessWidget {
  final AppTheme theme;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const ThemedSwitch({
    super.key,
    required this.theme,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      activeThumbColor: theme.textColor,
      activeTrackColor: theme.borderColor.withValues(alpha: 0.45),
      inactiveThumbColor: theme.secondaryTextColor,
      inactiveTrackColor: Colors.transparent,
      trackOutlineColor: WidgetStatePropertyAll(theme.borderColor),
    );
  }
}
