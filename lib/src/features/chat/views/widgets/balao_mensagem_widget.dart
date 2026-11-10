import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/views/widgets/cards/card_mensagem_arquivo.dart';
import 'package:nous/src/features/chat/views/widgets/cards/card_mensagem_audio.dart';
import 'package:nous/src/features/chat/views/widgets/cards/card_mensagem_comanda.dart';
import 'package:nous/src/features/chat/views/widgets/cards/card_mensagem_imagem.dart';

class BalaoMensagemWidget extends StatelessWidget {
  final MensagemChat msg;
  final ConversaChat conversa;
  final bool enviadaPorMim;
  final AppTheme theme;
  final void Function(MensagemChat) onMostrarMenu;
  final void Function(MensagemChat) onVerHistoricoEdicoes;
  final void Function(String) onAbrirArquivo;
  final void Function(String) onVisualizarFotoAmpliada;
  final void Function(MensagemChat) onVerComanda;

  const BalaoMensagemWidget({
    super.key,
    required this.msg,
    required this.conversa,
    required this.enviadaPorMim,
    required this.theme,
    required this.onMostrarMenu,
    required this.onVerHistoricoEdicoes,
    required this.onAbrirArquivo,
    required this.onVisualizarFotoAmpliada,
    required this.onVerComanda,
  });

  String _formatarHora(DateTime dataHora) {
    final local = dataHora.toLocal();
    final hora = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$hora:$min';
  }

  void _copiarAoToqueDuplo(BuildContext context) {
    final textoCopiar = msg.texto.trim().isNotEmpty
        ? msg.texto.trim()
        : (msg.nomeAnexo.trim().isNotEmpty ? msg.nomeAnexo.trim() : '');
    if (textoCopiar.isEmpty) return;
    Clipboard.setData(ClipboardData(text: textoCopiar));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: theme.cardBackgroundColor,
          duration: const Duration(milliseconds: 1200),
          content: Text(
            'Mensagem copiada!',
            style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (msg.tipo == 'texto' && msg.texto.trim().isEmpty && msg.caminhoAnexo.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: enviadaPorMim ? Alignment.centerRight : Alignment.centerLeft,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onDoubleTap: () => _copiarAoToqueDuplo(context),
        onLongPress: () => onMostrarMenu(msg),
        onSecondaryTap: () => onMostrarMenu(msg),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.72,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: enviadaPorMim
                ? theme.buttonColor.withValues(alpha: 0.18)
                : theme.cardBackgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: Radius.circular(enviadaPorMim ? 12 : 2),
              bottomRight: Radius.circular(enviadaPorMim ? 2 : 12),
            ),
            border: Border.all(
              color: enviadaPorMim
                  ? theme.buttonColor.withValues(alpha: 0.4)
                  : theme.borderColor.withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            crossAxisAlignment: enviadaPorMim
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              // Se for grupo ou loja com atendente, exibe o autor
              if (conversa.ehGrupo && !enviadaPorMim)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    msg.remetenteNome,
                    style: theme.getTextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                )
              else if (msg.nomeAtendente.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '${msg.remetenteNome} (${msg.nomeAtendente})',
                    style: theme.getTextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ),

              // Renderização do conteúdo conforme o tipo
              if (msg.tipo == 'imagem')
                CardMensagemImagem(
                  msg: msg,
                  enviadaPorMim: enviadaPorMim,
                  theme: theme,
                  onVisualizarFoto: onVisualizarFotoAmpliada,
                )
              else if (msg.tipo == 'arquivo')
                CardMensagemArquivo(
                  msg: msg,
                  enviadaPorMim: enviadaPorMim,
                  theme: theme,
                  onAbrir: () => onAbrirArquivo(msg.caminhoAnexo),
                )
              else if (msg.tipo == 'audio')
                CardMensagemAudio(
                  msg: msg,
                  theme: theme,
                  enviadaPorMim: enviadaPorMim,
                )
              else if (msg.tipo == 'comanda')
                CardMensagemComanda(
                  msg: msg,
                  enviadaPorMim: enviadaPorMim,
                  theme: theme,
                  onVerComanda: () => onVerComanda(msg),
                )
              else
                Text(
                  msg.texto,
                  style: theme.getTextStyle(
                    fontSize: 13,
                    color: theme.textColor,
                  ),
                ),

              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (msg.editada) ...[
                    InkWell(
                      onTap: () => onVerHistoricoEdicoes(msg),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          '(editada)',
                          style: theme
                              .getTextStyle(
                                fontSize: 9,
                                color: theme.secondaryTextColor.withValues(
                                  alpha: 0.9,
                                ),
                              )
                              .copyWith(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (msg.favorita) ...[
                    Icon(
                      Icons.star_rounded,
                      size: 11,
                      color: theme.secondaryTextColor.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 3),
                  ],
                  Text(
                    _formatarHora(msg.dataHora),
                    style: theme.getTextStyle(
                      fontSize: 9,
                      color: theme.secondaryTextColor.withValues(alpha: 0.8),
                    ),
                  ),
                  if (enviadaPorMim) ...[
                    const SizedBox(width: 4),
                    if (msg.statusEnvio == 'pendente')
                      Icon(
                        Icons.access_time_rounded,
                        size: 11,
                        color: theme.secondaryTextColor.withValues(alpha: 0.8),
                      )
                    else if (msg.lida || msg.statusEnvio == 'lida')
                      const Icon(
                        Icons.done_all,
                        size: 13,
                        color: Color(0xFF34B7F1),
                      )
                    else if (msg.entregue || msg.statusEnvio == 'entregue')
                      Icon(
                        Icons.done_all,
                        size: 13,
                        color: theme.secondaryTextColor.withValues(alpha: 0.85),
                      )
                    else
                      Icon(
                        Icons.check,
                        size: 13,
                        color: theme.secondaryTextColor.withValues(alpha: 0.8),
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
