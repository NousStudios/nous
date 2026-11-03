import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';

/// Barra horizontal de rolagem contendo os tópicos comunitários da loja/rede.
class BarraTopicosComunitariosWidget extends StatelessWidget {
  final AppTheme theme;
  final List<ConversaChat> topicos;
  final String conversaIdAtiva;
  final ValueChanged<ConversaChat> onSelecionarTopico;
  final VoidCallback onCriarNovoTopico;
  final VoidCallback onExplorarSalas;

  const BarraTopicosComunitariosWidget({
    super.key,
    required this.theme,
    required this.topicos,
    required this.conversaIdAtiva,
    required this.onSelecionarTopico,
    required this.onCriarNovoTopico,
    required this.onExplorarSalas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...topicos.map((topico) {
              final ehAtivo = topico.id == conversaIdAtiva;
              final nome = topico.titulo.isNotEmpty ? topico.titulo : 'Geral';
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => onSelecionarTopico(topico),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: ehAtivo
                          ? theme.buttonColor
                          : theme.cardBackgroundColor.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: ehAtivo
                            ? theme.buttonColor
                            : theme.borderColor.withValues(alpha: 0.7),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tag_rounded,
                          size: 14,
                          color: ehAtivo ? theme.buttonTextColor : theme.secondaryTextColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          nome,
                          style: theme.getTextStyle(
                            fontSize: 12,
                            fontWeight: ehAtivo ? FontWeight.bold : FontWeight.w500,
                            color: ehAtivo ? theme.buttonTextColor : theme.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            InkWell(
              onTap: onCriarNovoTopico,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: theme.cardBackgroundColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.7),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 15, color: theme.textColor),
                    const SizedBox(width: 4),
                    Text(
                      'Novo Tópico',
                      style: theme.getTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onExplorarSalas,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: theme.cardBackgroundColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.7),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.explore_outlined, size: 15, color: theme.textColor),
                    const SizedBox(width: 4),
                    Text(
                      'Explorar Salas',
                      style: theme.getTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
