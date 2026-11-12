import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';

/// Título no início do chat ("Nova Conversa" por padrão), incorporado
/// diretamente ao fluxo da conversa, centralizado e editável com um simples toque.
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
      child: Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 20),
        child: InkWell(
          onTap: () => onRenomearConversa(conversa),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
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
          ),
        ),
      ),
    );
  }
}
