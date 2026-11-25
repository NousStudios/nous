import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Barra de pesquisa de palavras-chave dentro do histórico da conversa ativa.
class BarraPesquisaConversaWidget extends StatelessWidget {
  final TextEditingController controller;
  final AppTheme theme;
  final String termoBusca;

  const BarraPesquisaConversaWidget({
    super.key,
    required this.controller,
    required this.theme,
    required this.termoBusca,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: theme.borderColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: TextField(
        controller: controller,
        autofocus: true,
        style: theme.getTextStyle(fontSize: 13, color: theme.textColor),
        decoration: InputDecoration(
          hintText: 'Pesquisar palavras-chave no histórico...',
          hintStyle: theme.getTextStyle(
            fontSize: 12,
            color: theme.secondaryTextColor,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: theme.secondaryTextColor,
          ),
          suffixIcon: termoBusca.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    size: 16,
                    color: theme.secondaryTextColor,
                  ),
                  onPressed: () => controller.clear(),
                )
              : null,
          isDense: true,
          filled: true,
          fillColor: theme.backgroundColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: theme.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: theme.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: theme.buttonColor),
          ),
        ),
      ),
    );
  }
}
