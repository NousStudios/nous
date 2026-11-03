import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Campo para leitura e bipagem de código de barras ou digitação do nome do produto.
class CampoBipadorBalcaoWidget extends StatelessWidget {
  final AppTheme theme;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final VoidCallback onLimpar;

  const CampoBipadorBalcaoWidget({
    super.key,
    required this.theme,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onLimpar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.textColor.withValues(alpha: 0.7),
          width: 1.8,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.qr_code_scanner_rounded, size: 26, color: theme.textColor),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              cursorColor: theme.textColor,
              style: theme.getTextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
              decoration: InputDecoration(
                hintText:
                    'Passe o código de barras ou digite o nome do item e aperte Enter...',
                hintStyle: theme.getTextStyle(
                  fontSize: 13,
                  color: theme.secondaryTextColor.withValues(alpha: 0.7),
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: onChanged,
              onSubmitted: (_) => onSubmitted(),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              color: theme.secondaryTextColor,
              onPressed: onLimpar,
            ),
          const SizedBox(width: 4),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.buttonColor != Colors.transparent
                  ? theme.buttonColor
                  : theme.borderColor.withValues(alpha: 0.3),
              foregroundColor: theme.textColor,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: theme.textColor),
              ),
            ),
            onPressed: onSubmitted,
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              'Inserir (Enter)',
              style: theme.getTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
