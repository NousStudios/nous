import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';

/// Banner no início do chat que exibe o título da conversa centralizado
/// ("Nova Conversa" por padrão) e o pequeno pincel de edição no canto direito inferior.
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
    final titulo = conversa.temTituloConversa
        ? conversa.tituloConversa.trim()
        : 'Nova Conversa';

    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 18),
        padding: const EdgeInsets.fromLTRB(18, 12, 10, 6),
        constraints: const BoxConstraints(minWidth: 200, maxWidth: 460),
        decoration: BoxDecoration(
          color: theme.cardBackgroundColor.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.borderColor.withValues(alpha: 0.65),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextoRolante(
                texto: titulo,
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.bottomRight,
              child: Tooltip(
                message: 'Renomear conversa',
                child: InkWell(
                  onTap: () => onRenomearConversa(conversa),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Icon(
                      Icons.brush_rounded,
                      size: 13,
                      color: theme.secondaryTextColor.withValues(alpha: 0.85),
                    ),
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
