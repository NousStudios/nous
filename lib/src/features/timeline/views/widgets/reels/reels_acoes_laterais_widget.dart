import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';

/// Coluna lateral direita de ações rápidas do visualizador Reels compacto.
class ReelsAcoesLateraisWidget extends StatelessWidget {
  final AppTheme theme;
  final TipoReacaoSocial? minhaReacao;
  final int likes;
  final int deslikes;
  final int totalComentarios;
  final Future<void> Function(TipoReacaoSocial tipo) onReagir;
  final VoidCallback onAbrirComentarios;
  final VoidCallback onRepublicar;
  final VoidCallback onEnviarChat;
  final VoidCallback onSalvar;
  final VoidCallback onAtivarModoLimpo;

  const ReelsAcoesLateraisWidget({
    super.key,
    required this.theme,
    required this.minhaReacao,
    required this.likes,
    required this.deslikes,
    required this.totalComentarios,
    required this.onReagir,
    required this.onAbrirComentarios,
    required this.onRepublicar,
    required this.onEnviarChat,
    required this.onSalvar,
    required this.onAtivarModoLimpo,
  });

  Widget _botaoAcao({
    required IconData icone,
    required String? rotulo,
    required VoidCallback? onTap,
    bool ativo = false,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icone,
              size: 20,
              color: theme.textColor,
            ),
            if (rotulo != null) ...[
              const SizedBox(height: 2),
              Text(
                rotulo,
                style: theme.getTextStyle(
                  fontSize: 10.5,
                  fontWeight: ativo ? FontWeight.bold : FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _botaoAcao(
          icone: minhaReacao == TipoReacaoSocial.like
              ? Icons.thumb_up
              : Icons.thumb_up_outlined,
          rotulo: '$likes',
          ativo: minhaReacao == TipoReacaoSocial.like,
          onTap: () => onReagir(TipoReacaoSocial.like),
        ),
        _botaoAcao(
          icone: minhaReacao == TipoReacaoSocial.deslike
              ? Icons.thumb_down
              : Icons.thumb_down_outlined,
          rotulo: '$deslikes',
          ativo: minhaReacao == TipoReacaoSocial.deslike,
          onTap: () => onReagir(TipoReacaoSocial.deslike),
        ),
        _botaoAcao(
          icone: Icons.mode_comment_outlined,
          rotulo: '$totalComentarios',
          onTap: onAbrirComentarios,
        ),
        _botaoAcao(
          icone: Icons.repeat_rounded,
          rotulo: null,
          onTap: onRepublicar,
        ),
        _botaoAcao(
          icone: Icons.send_rounded,
          rotulo: null,
          onTap: onEnviarChat,
        ),
        _botaoAcao(
          icone: Icons.bookmark_border_rounded,
          rotulo: null,
          onTap: onSalvar,
        ),
        _botaoAcao(
          icone: Icons.fullscreen_rounded,
          rotulo: null,
          onTap: onAtivarModoLimpo,
        ),
      ],
    );
  }
}
