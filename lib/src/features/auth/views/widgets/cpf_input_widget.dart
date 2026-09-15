import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

class CpfInputWidget extends StatelessWidget {
  final TextEditingController? controller;

  const CpfInputWidget({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    // Escuta o tema global, igual ao padrão usado em LoginView e TermsView
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center, // Centraliza tanto o hint quanto o texto digitado
          // Cor do texto digitado vem do tema, no lugar de Colors.white fixo
          style: theme.getTextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Digite seu CPF',
            // Cor do texto de dica (placeholder) vem do tema
            hintStyle: theme.getTextStyle(
              fontSize: 16,
              color: theme.secondaryTextColor,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: theme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: theme.textColor),
            ),
          ),
        );
      },
    );
  }
}