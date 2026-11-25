import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/auth/views/perfil_social_view.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/notificacoes/views/widgets/cards/card_notificacao_social.dart';
import 'package:nous/src/features/notificacoes/views/widgets/itens/fundo_descarte_notificacao.dart';
import 'package:nous/src/features/timeline/models/notificacao_social.dart';
import 'package:nous/src/features/timeline/services/timeline_repositorio_sqlite.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_detalhes_publicacao.dart';

/// Seção agrupada de notificações sociais (convites, menções ou atividade).
class SecaoNotificacoesSociais extends StatelessWidget {
  final AppTheme theme;
  final String titulo;
  final List<NotificacaoSocial> itens;
  final NotificacoesProvider notificacoes;
  final String cpfUsuario;
  final UsuarioNous? usuarioLogado;

  const SecaoNotificacoesSociais({
    super.key,
    required this.theme,
    required this.titulo,
    required this.itens,
    required this.notificacoes,
    required this.cpfUsuario,
    required this.usuarioLogado,
  });

  @override
  Widget build(BuildContext context) {
    if (itens.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Text(
            '$titulo (${itens.length})',
            style: theme.getTextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
        ),
        for (final s in itens)
          ItemNotificacaoSocial(
            theme: theme,
            notificacao: s,
            notificacoes: notificacoes,
            cpfUsuario: cpfUsuario,
            usuarioLogado: usuarioLogado,
          ),
        const SizedBox(height: 6),
      ],
    );
  }
}

/// Item descartável de notificação social com ações de colaboração e navegação.
class ItemNotificacaoSocial extends StatelessWidget {
  final AppTheme theme;
  final NotificacaoSocial notificacao;
  final NotificacoesProvider notificacoes;
  final String cpfUsuario;
  final UsuarioNous? usuarioLogado;

  const ItemNotificacaoSocial({
    super.key,
    required this.theme,
    required this.notificacao,
    required this.notificacoes,
    required this.cpfUsuario,
    required this.usuarioLogado,
  });

  @override
  Widget build(BuildContext context) {
    final s = notificacao;
    return Dismissible(
      key: ValueKey('nsoc_${s.id}'),
      direction: DismissDirection.horizontal,
      background: FundoDescarteNotificacao(
        theme: theme,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: FundoDescarteNotificacao(
        theme: theme,
        alignment: Alignment.centerRight,
      ),
      onDismissed: (_) async {
        await TimelineRepositorioSqlite.marcarNotificacaoSocialLida(s.id);
        notificacoes.dispensarNaSessao('nsoc_${s.id}');
      },
      child: CardNotificacaoSocial(
        theme: theme,
        notificacao: s,
        onResponderConvite: s.tipo == TipoNotificacaoSocial.conviteColaboracao
            ? (aceitar) async {
                await TimelineService.responderConviteColaboracao(
                  publicacaoId: s.publicacaoId,
                  usuarioCpf: cpfUsuario,
                  aceitar: aceitar,
                  notificacaoId: s.id,
                );
                notificacoes.dispensarNaSessao('nsoc_${s.id}');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        aceitar
                            ? 'Participação aceita! A publicação agora aparece no seu perfil.'
                            : 'Convite de participação recusado.',
                      ),
                    ),
                  );
                }
              }
            : null,
        onTap: () async {
          if (s.tipo != TipoNotificacaoSocial.conviteColaboracao) {
            await TimelineRepositorioSqlite.marcarNotificacaoSocialLida(s.id);
            notificacoes.dispensarNaSessao('nsoc_${s.id}');
          }
          if (!context.mounted) return;
          if (s.publicacaoId.isNotEmpty) {
            final pub = await TimelineRepositorioSqlite.buscarPublicacaoPorId(
              s.publicacaoId,
            );
            if (pub != null && context.mounted) {
              await DialogDetalhesPublicacao.mostrar(
                context,
                theme: theme,
                publicacao: pub,
                usuarioLogado: usuarioLogado,
              );
              return;
            }
          }
          final alvo = await ContasNousService.buscarPorCpf(s.autorCpf);
          if (alvo != null && context.mounted) {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PerfilSocialView(
                  usuarioAlvo: alvo,
                  mostrarBotaoVoltar: true,
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
