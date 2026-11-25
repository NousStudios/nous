import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_enviar_publicacao_chat.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_opcoes_publicacao.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_republicar_opcoes.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_salvar_publicacao.dart';

/// Rodapé do card de escrito com visualizações, contadores clicáveis
/// e barra inferior de ações (like, deslike, comentar, republicar, enviar e salvar).
class CardEscritoRodapeWidget extends StatelessWidget {
  final AppTheme theme;
  final PublicacaoSocial publicacao;
  final UsuarioNous? usuarioLogado;
  final List<ReacaoSocial> reacoes;
  final int totalComentarios;
  final int totalRepublicacoes;
  final ValueChanged<TipoReacaoSocial> onReagir;
  final VoidCallback onAbrirDetalhes;

  const CardEscritoRodapeWidget({
    super.key,
    required this.theme,
    required this.publicacao,
    required this.usuarioLogado,
    required this.reacoes,
    required this.totalComentarios,
    required this.totalRepublicacoes,
    required this.onReagir,
    required this.onAbrirDetalhes,
  });

  Widget _buildStatClicavel({
    required int valor,
    required String rotulo,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$valor ',
                style: theme.getTextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              TextSpan(
                text: rotulo,
                style: theme.getTextStyle(
                  fontSize: 12.5,
                  color: theme.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = usuarioLogado;
    final meuCpf = (u?.cpf ?? '').replaceAll(RegExp(r'\D'), '');
    final likes = reacoes.where((r) => r.tipo == TipoReacaoSocial.like).length;
    final deslikes =
        reacoes.where((r) => r.tipo == TipoReacaoSocial.deslike).length;
    final minhaReacao = reacoes
        .where((r) => r.usuarioCpf.replaceAll(RegExp(r'\D'), '') == meuCpf)
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Marcador de visualizações discreto à direita
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 50),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 13.5,
                color: theme.secondaryTextColor,
              ),
              const SizedBox(width: 4),
              Text(
                '${publicacao.visualizacoes}',
                style: theme.getTextStyle(
                  fontSize: 11.5,
                  color: theme.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),

        // Contadores clicáveis (Republicações, Likes, Deslikes, Comentários)
        if (likes > 0 ||
            deslikes > 0 ||
            totalRepublicacoes > 0 ||
            totalComentarios > 0) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Divider(
                  height: 1,
                  color: theme.borderColor.withValues(alpha: 0.25),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    if (totalRepublicacoes > 0)
                      _buildStatClicavel(
                        valor: totalRepublicacoes,
                        rotulo: totalRepublicacoes == 1
                            ? 'Republicação'
                            : 'Republicações',
                      ),
                    if (likes > 0)
                      _buildStatClicavel(
                        valor: likes,
                        rotulo: likes == 1 ? 'Like' : 'Likes',
                        onTap: () => DialogOpcoesPublicacao.mostrarListaReacoes(
                          context,
                          theme: theme,
                          reacoes: reacoes,
                          tipo: TipoReacaoSocial.like,
                        ),
                      ),
                    if (deslikes > 0)
                      _buildStatClicavel(
                        valor: deslikes,
                        rotulo: deslikes == 1 ? 'Deslike' : 'Deslikes',
                        onTap: () => DialogOpcoesPublicacao.mostrarListaReacoes(
                          context,
                          theme: theme,
                          reacoes: reacoes,
                          tipo: TipoReacaoSocial.deslike,
                        ),
                      ),
                    if (totalComentarios > 0)
                      _buildStatClicavel(
                        valor: totalComentarios,
                        rotulo: totalComentarios == 1
                            ? 'Comentário'
                            : 'Comentários',
                        onTap: onAbrirDetalhes,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],

        // Barra inferior: Like > Deslike > Comentário > Republicar > Enviar pelo chat > Salvar
        const SizedBox(height: 6),
        Divider(
          height: 1,
          color: theme.borderColor.withValues(alpha: 0.25),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Like',
              icon: Icon(
                minhaReacao?.tipo == TipoReacaoSocial.like
                    ? Icons.thumb_up_alt_rounded
                    : Icons.thumb_up_off_alt_rounded,
                size: 18,
                color: minhaReacao?.tipo == TipoReacaoSocial.like
                    ? theme.textColor
                    : theme.secondaryTextColor,
              ),
              onPressed: () => onReagir(TipoReacaoSocial.like),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Deslike',
              icon: Icon(
                minhaReacao?.tipo == TipoReacaoSocial.deslike
                    ? Icons.thumb_down_alt_rounded
                    : Icons.thumb_down_off_alt_rounded,
                size: 18,
                color: minhaReacao?.tipo == TipoReacaoSocial.deslike
                    ? theme.dangerColor
                    : theme.secondaryTextColor,
              ),
              onPressed: () => onReagir(TipoReacaoSocial.deslike),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Comentar',
              icon: Icon(
                Icons.mode_comment_outlined,
                size: 18,
                color: theme.secondaryTextColor,
              ),
              onPressed: onAbrirDetalhes,
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Republicar',
              icon: Icon(
                Icons.repeat_rounded,
                size: 19,
                color: theme.secondaryTextColor,
              ),
              onPressed: u == null
                  ? null
                  : () => DialogRepublicarOpcoes.mostrar(
                        context,
                        theme: theme,
                        publicacao: publicacao,
                        usuario: u,
                      ),
            ),
            if (u != null) ...[
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Enviar no Chat',
                icon: Icon(
                  Icons.send_rounded,
                  size: 17,
                  color: theme.secondaryTextColor,
                ),
                onPressed: () => DialogEnviarPublicacaoChat.mostrar(
                  context,
                  theme: theme,
                  publicacao: publicacao,
                  remetente: u,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Salvar',
                icon: Icon(
                  Icons.bookmark_border_rounded,
                  size: 19,
                  color: theme.secondaryTextColor,
                ),
                onPressed: () => DialogSalvarPublicacao.mostrar(
                  context,
                  theme: theme,
                  publicacaoId: publicacao.id,
                  usuarioCpf: u.cpf,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
