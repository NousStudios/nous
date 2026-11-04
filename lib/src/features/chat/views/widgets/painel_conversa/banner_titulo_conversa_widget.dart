import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';

/// Banner de destaque que exibe o título soberano ou assunto fixado da conversa.
class BannerTituloConversaWidget extends StatelessWidget {
  final ConversaChat conversa;
  final AppTheme theme;
  final void Function(ConversaChat) onRenomearConversa;

  const BannerTituloConversaWidget({
    super.key,
    required this.conversa,
    required this.theme,
    required this.onRenomearConversa,
  });

  @override
  Widget build(BuildContext context) {
    final temTitulo = conversa.temTituloConversa;
    if (!temTitulo) {
      return const SizedBox.shrink();
    }
    final titulo = conversa.tituloConversa;

    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: theme.cardBackgroundColor.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.buttonColor.withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bookmark_outline_rounded,
                  size: 14,
                  color: theme.buttonColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'TÍTULO DA CONVERSA',
                  style: theme
                      .getTextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: theme.buttonColor,
                      )
                      .copyWith(letterSpacing: 1.1),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message: 'Renomear conversa',
                  child: InkWell(
                    onTap: () => onRenomearConversa(conversa),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
