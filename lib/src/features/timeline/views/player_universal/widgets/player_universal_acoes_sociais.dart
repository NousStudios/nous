import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Barra de ações sociais da publicação em reprodução (curtir, não curtir,
/// salvar, comentários e compartilhamento no chat).
class PlayerUniversalAcoesSociais extends StatelessWidget {
  final AppTheme theme;
  final bool curtiu;
  final bool descurtiu;
  final bool salvo;
  final VoidCallback onCurtir;
  final VoidCallback onDescurtir;
  final VoidCallback? onSalvar;
  final VoidCallback onComentarios;
  final VoidCallback? onCompartilhar;

  const PlayerUniversalAcoesSociais({
    super.key,
    required this.theme,
    required this.curtiu,
    required this.descurtiu,
    required this.salvo,
    required this.onCurtir,
    required this.onDescurtir,
    required this.onSalvar,
    required this.onComentarios,
    required this.onCompartilhar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          tooltip: 'Curtir',
          onPressed: onCurtir,
          icon: Icon(
            curtiu ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
            color: curtiu ? theme.textColor : theme.secondaryTextColor,
            size: 20,
          ),
        ),
        IconButton(
          tooltip: 'Não curtir',
          onPressed: onDescurtir,
          icon: Icon(
            descurtiu ? Icons.thumb_down_rounded : Icons.thumb_down_outlined,
            color: descurtiu ? theme.dangerColor : theme.secondaryTextColor,
            size: 20,
          ),
        ),
        IconButton(
          tooltip: 'Salvar publicação',
          onPressed: onSalvar,
          icon: Icon(
            salvo ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
            color: salvo ? theme.textColor : theme.secondaryTextColor,
            size: 21,
          ),
        ),
        IconButton(
          tooltip: 'Comentários',
          onPressed: onComentarios,
          icon: Icon(
            Icons.chat_bubble_outline_rounded,
            color: theme.secondaryTextColor,
            size: 20,
          ),
        ),
        IconButton(
          tooltip: 'Compartilhar no chat',
          onPressed: onCompartilhar,
          icon: Icon(
            Icons.share_outlined,
            color: theme.secondaryTextColor,
            size: 20,
          ),
        ),
      ],
    );
  }
}
