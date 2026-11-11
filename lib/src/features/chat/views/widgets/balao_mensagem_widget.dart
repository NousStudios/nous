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
  final bool modoLoja;
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
    this.modoLoja = false,
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
            maxWidth: msg.tipo == 'comanda'
                ? (MediaQuery.sizeOf(context).width * 0.88).clamp(280.0, 340.0)
                : MediaQuery.sizeOf(context).width * 0.72,
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
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nome de quem envia sempre no lado esquerdo superior
                if (conversa.ehGrupo && !enviadaPorMim)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        msg.remetenteNome,
                        style: theme.getTextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ),
                  )
                else if (msg.nomeAtendente.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
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
                    modoLoja: modoLoja,
                    theme: theme,
                    onVerComanda: () => onVerComanda(msg),
                  )
                else
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      msg.texto,
                      style: theme.getTextStyle(
                        fontSize: 13,
                        color: theme.textColor,
                      ),
                    ),
                  ),

                if (msg.reacoes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: () {
                        final contagem = <String, int>{};
                        for (final emo in msg.reacoes.values) {
                          contagem[emo] = (contagem[emo] ?? 0) + 1;
                        }
                        return contagem.entries.map((e) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.backgroundColor.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: theme.borderColor.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(e.key, style: const TextStyle(fontSize: 12)),
                                if (e.value > 1) ...[
                                  const SizedBox(width: 3),
                                  Text(
                                    '${e.value}',
                                    style: theme.getTextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: theme.secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList();
                      }(),
                    ),
                  ),
                ],

                const SizedBox(height: 3),
                // Hora e traços de visto sempre no canto direito inferior
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (msg.fixada) ...[
                        Icon(
                          Icons.push_pin_rounded,
                          size: 11,
                          color: theme.secondaryTextColor.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 3),
                      ],
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
                      if (enviadaPorMim || msg.tipo == 'comanda') ...[
                        const SizedBox(width: 4),
                        if (msg.lida || msg.statusEnvio == 'lida')
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
