import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';

/// Cabeçalho superior da caixa de chat da comunidade Nous.
/// Apresenta o título do tópico ativo (editável), opção de apagar/sair e sino de notificações.
class CabecalhoChatGestaoWidget extends StatelessWidget {
  final AppTheme theme;
  final String conversaIdAtiva;
  final String tituloTopicoAtivo;
  final List<ConversaChat> topicos;
  final String cpfLogado;
  final bool notificarTopicoAtivo;
  final VoidCallback onRenomearTopico;
  final VoidCallback onApagarTopico;
  final VoidCallback onSairTopico;
  final VoidCallback onAlternarNotificacao;

  const CabecalhoChatGestaoWidget({
    super.key,
    required this.theme,
    required this.conversaIdAtiva,
    required this.tituloTopicoAtivo,
    required this.topicos,
    required this.cpfLogado,
    required this.notificarTopicoAtivo,
    required this.onRenomearTopico,
    required this.onApagarTopico,
    required this.onSairTopico,
    required this.onAlternarNotificacao,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.borderColor.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.forum_outlined,
            size: 20,
            color: theme.textColor,
          ),
          const SizedBox(width: 8),

          // Título centralizado no meio do espaço do chat, editável
          Expanded(
            child: Center(
              child: InkWell(
                onTap: onRenomearTopico,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          tituloTopicoAtivo,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.edit_outlined,
                        size: 15,
                        color: theme.secondaryTextColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Botão Apagar ou Sair da Sala Comunitária ativa se não for #Geral
          if (conversaIdAtiva != ChatService.idTopicoGeral) ...[
            Builder(
              builder: (context) {
                final topicoAtivo = topicos.firstWhere(
                  (t) => t.id == conversaIdAtiva,
                  orElse: () => ConversaChat(
                    id: conversaIdAtiva,
                    titulo: tituloTopicoAtivo,
                    identificador: 'todos',
                    dataHoraUltimaMensagem: DateTime.now(),
                  ),
                );
                final ehCriador = ChatService.normalizarCpf(topicoAtivo.identificador) ==
                    ChatService.normalizarCpf(cpfLogado);

                if (ehCriador) {
                  return IconButton(
                    tooltip: 'Apagar esta sala comunitária',
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: theme.dangerColor,
                      size: 20,
                    ),
                    onPressed: onApagarTopico,
                  );
                } else {
                  return IconButton(
                    tooltip: 'Sair desta sala comunitária',
                    icon: Icon(
                      Icons.logout_rounded,
                      color: theme.secondaryTextColor,
                      size: 20,
                    ),
                    onPressed: onSairTopico,
                  );
                }
              },
            ),
          ],

          // Ícone para ativar/desativar notificação deste tópico
          IconButton(
            tooltip: notificarTopicoAtivo
                ? 'Notificações ativadas para este tópico (clique para silenciar)'
                : 'Notificações silenciadas para este tópico (clique para ativar)',
            icon: Icon(
              notificarTopicoAtivo
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_outlined,
              color: notificarTopicoAtivo
                  ? const Color(0xFF4CAF50)
                  : theme.secondaryTextColor,
              size: 20,
            ),
            onPressed: onAlternarNotificacao,
          ),
        ],
      ),
    );
  }
}
