import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/views/mensageria_view.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/notificacoes/views/widgets/cards/card_notificacao_chat.dart';
import 'package:nous/src/features/notificacoes/views/widgets/itens/fundo_descarte_notificacao.dart';

/// Seção de mensagens de chat não lidas no diálogo de notificações.
class SecaoNotificacoesChat extends StatelessWidget {
  final AppTheme theme;
  final List<MensagemChat> mensagens;
  final NotificacoesProvider notificacoes;
  final String? lojaId;
  final String cpfUsuario;
  final bool exibirEspacamentoInferior;

  const SecaoNotificacoesChat({
    super.key,
    required this.theme,
    required this.mensagens,
    required this.notificacoes,
    required this.lojaId,
    required this.cpfUsuario,
    required this.exibirEspacamentoInferior,
  });

  @override
  Widget build(BuildContext context) {
    if (mensagens.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Row(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 16,
                color: theme.textColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Mensagens (${mensagens.length})',
                style: theme.getTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
        ),
        for (final msg in mensagens)
          Dismissible(
            key: ValueKey('msg_${msg.id}'),
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
              if (lojaId != null) {
                notificacoes.dispensarNotificacoesLoja(
                  lojaId!,
                  ['msg_${msg.id}'],
                );
                ChatService.marcarMensagensDaLojaComoLidas(
                  lojaId!,
                  cpfUsuario,
                );
              } else {
                notificacoes.dispensarNaSessao('msg_${msg.id}');
                ChatService.marcarMensagensDoUsuarioComoLidas(
                  cpfUsuario,
                  [msg.conversaId],
                );
              }
            },
            child: CardNotificacaoChat(
              theme: theme,
              msg: msg,
              onTap: () {
                Navigator.of(context).pop();
                if (lojaId != null) {
                  ChatService.marcarMensagensDaLojaComoLidas(
                    lojaId!,
                    cpfUsuario,
                  );
                } else {
                  ChatService.marcarComoLidas(
                    msg.conversaId,
                    cpfUsuario,
                  );
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MensageriaView(
                      modoLoja: lojaId != null,
                      lojaId: lojaId,
                      conversaInicialId: msg.conversaId,
                      mostrarBotaoVoltar: true,
                    ),
                  ),
                );
              },
            ),
          ),
        if (exibirEspacamentoInferior) const SizedBox(height: 8),
      ],
    );
  }
}
