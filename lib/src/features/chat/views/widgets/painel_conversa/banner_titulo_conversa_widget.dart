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
        margin: const EdgeInsets.only(top: 8, bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          color: theme.cardBackgroundColor.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: temTitulo
                ? theme.buttonColor.withValues(alpha: 0.45)
                : theme.borderColor.withValues(alpha: 0.6),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              temTitulo
                  ? Icons.bookmark_outline_rounded
                  : Icons.edit_note_rounded,
              size: 18,
              color: temTitulo ? theme.buttonColor : theme.secondaryTextColor,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    temTitulo ? 'TÍTULO DA CONVERSA' : 'TÍTULO DO CHAT',
                    style: theme
                        .getTextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: temTitulo
                              ? theme.buttonColor
                              : theme.secondaryTextColor,
                        )
                        .copyWith(letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    temTitulo
                        ? titulo
                        : 'Definir assunto ou título para esta conversa',
                    style: theme
                        .getTextStyle(
                          fontSize: 12,
                          fontWeight:
                              temTitulo ? FontWeight.bold : FontWeight.normal,
                          color: temTitulo
                              ? theme.textColor
                              : theme.secondaryTextColor,
                        )
                        .copyWith(
                          fontStyle:
                              temTitulo ? FontStyle.normal : FontStyle.italic,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: temTitulo
                  ? 'Alterar título da conversa'
                  : 'Adicionar título',
              child: InkWell(
                onTap: () => onRenomearConversa(conversa),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 15,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
