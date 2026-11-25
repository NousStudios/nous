import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/notificacoes/models/convite_loja.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/notificacoes/services/gerenciador_acoes_notificacao.dart';
import 'package:nous/src/features/notificacoes/views/widgets/cards/card_notificacao_convite.dart';
import 'package:nous/src/features/notificacoes/views/widgets/itens/fundo_descarte_notificacao.dart';

/// Seção de convites e solicitações de loja no diálogo de notificações.
class SecaoNotificacoesConvites extends StatelessWidget {
  final AppTheme theme;
  final List<ConviteLoja> convites;
  final NotificacoesProvider notificacoes;
  final bool exibirCabecalho;

  const SecaoNotificacoesConvites({
    super.key,
    required this.theme,
    required this.convites,
    required this.notificacoes,
    required this.exibirCabecalho,
  });

  @override
  Widget build(BuildContext context) {
    if (convites.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (exibirCabecalho)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Convites e Solicitações (${convites.length})',
              style: theme.getTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
          ),
        for (final convite in convites)
          Dismissible(
            key: ValueKey('convite_${convite.id}'),
            direction: DismissDirection.horizontal,
            background: FundoDescarteNotificacao(
              theme: theme,
              alignment: Alignment.centerLeft,
            ),
            secondaryBackground: FundoDescarteNotificacao(
              theme: theme,
              alignment: Alignment.centerRight,
            ),
            onDismissed: (_) {
              notificacoes.dispensarNaSessao('convite_${convite.id}');
            },
            child: CardNotificacaoConvite(
              theme: theme,
              convite: convite,
              onAceitar: () => GerenciadorAcoesNotificacao.aceitarConvite(
                context,
                convite,
              ),
              onRecusar: () => GerenciadorAcoesNotificacao.recusarConvite(
                context,
                convite,
              ),
            ),
          ),
      ],
    );
  }
}
