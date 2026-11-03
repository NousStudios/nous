import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/views/widgets/visualizador_imagem_chat_dialog.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/views/widgets/gestao_nous/card_audio_mensagem_gestao.dart';

/// Bolha individual de mensagem para o chat comunitário de Gestão Nous.
class BolhaMensagemGestao extends StatelessWidget {
  final AppTheme theme;
  final MensagemChat msg;
  final bool ehMinha;
  final String cpfLogado;
  final VoidCallback? onAtualizarChat;

  const BolhaMensagemGestao({
    super.key,
    required this.theme,
    required this.msg,
    required this.ehMinha,
    required this.cpfLogado,
    this.onAtualizarChat,
  });

  String _formatarHora(DateTime d) {
    final hora = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$hora:$min';
  }

  void _mostrarMenuMensagem(BuildContext context) {
    final agora = DateTime.now();
    final diferencaSegundos = agora.difference(msg.dataHora).inSeconds;
    final ehMinhaMsg = ehMinha ||
        ChatService.normalizarCpf(msg.remetenteId) == ChatService.normalizarCpf(cpfLogado);
    final podeExcluir = ehMinhaMsg && diferencaSegundos <= 60;
    final podeEditar = ehMinhaMsg && msg.tipo == 'texto';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Row(
            children: [
              Icon(Icons.chat_bubble_outline_rounded, color: theme.textColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Opções da Mensagem',
                style: theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (msg.texto.isNotEmpty) ...[
                  ListTile(
                    leading: Icon(Icons.copy_rounded, color: theme.textColor, size: 20),
                    title: Text('Copiar Texto', style: theme.getTextStyle(color: theme.textColor)),
                    onTap: () {
                      Navigator.pop(ctx);
                      Clipboard.setData(ClipboardData(text: msg.texto));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Texto copiado para a área de transferência.')),
                      );
                    },
                  ),
                  Divider(color: theme.borderColor.withValues(alpha: 0.3)),
                ],
                if (podeEditar) ...[
                  ListTile(
                    leading: Icon(Icons.edit_outlined, color: theme.textColor, size: 20),
                    title: Text('Editar', style: theme.getTextStyle(color: theme.textColor)),
                    subtitle: Text(
                      'Mantém o histórico de versões visível',
                      style: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _dialogEditarMensagem(context);
                    },
                  ),
                  Divider(color: theme.borderColor.withValues(alpha: 0.3)),
                ],
                if (ehMinhaMsg) ...[
                  ListTile(
                    enabled: podeExcluir,
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      color: podeExcluir
                          ? theme.dangerColor
                          : theme.secondaryTextColor.withValues(alpha: 0.5),
                      size: 20,
                    ),
                    title: Text(
                      'Excluir para todos',
                      style: theme.getTextStyle(
                        color: podeExcluir
                            ? theme.dangerColor
                            : theme.secondaryTextColor.withValues(alpha: 0.5),
                      ),
                    ),
                    subtitle: Text(
                      podeExcluir
                          ? 'Disponível por mais ${60 - diferencaSegundos}s'
                          : 'Exclusão permitida apenas até 1 minuto após o envio',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                    onTap: podeExcluir
                        ? () {
                            Navigator.pop(ctx);
                            _confirmarExclusaoMensagem(context);
                          }
                        : null,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _dialogEditarMensagem(BuildContext context) {
    final controller = TextEditingController(text: msg.texto);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Editar Mensagem',
            style: theme.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            style: theme.getTextStyle(color: theme.textColor),
            decoration: InputDecoration(
              hintText: 'Digite o novo texto...',
              hintStyle: theme.getTextStyle(color: theme.secondaryTextColor),
              filled: true,
              fillColor: theme.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.borderColor),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar', style: theme.getTextStyle(color: theme.secondaryTextColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: theme.buttonColor),
              onPressed: () async {
                final novoTexto = controller.text.trim();
                if (novoTexto.isEmpty || novoTexto == msg.texto) {
                  Navigator.pop(ctx);
                  return;
                }
                Navigator.pop(ctx);
                await ChatService.editarMensagem(msg.id, novoTexto);
                onAtualizarChat?.call();
              },
              child: Text(
                'Salvar Alteração',
                style: theme.getTextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.buttonTextColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmarExclusaoMensagem(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Excluir para todos?',
            style: theme.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: Text(
            'Esta mensagem será apagada para todos os participantes do tópico.',
            style: theme.getTextStyle(fontSize: 13, color: theme.secondaryTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar', style: theme.getTextStyle(color: theme.secondaryTextColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: theme.dangerColor),
              onPressed: () async {
                Navigator.pop(ctx);
                await ChatService.excluirMensagem(msg.id);
                onAtualizarChat?.call();
              },
              child: Text(
                'Excluir',
                style: theme.getTextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.buttonTextColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImagemAnexo(BuildContext context, String caminho) {
    final resolvido = ImagemService.resolverCaminhoExistente(caminho) ?? caminho;
    final file = File(resolvido);

    if (!file.existsSync() && caminho.isNotEmpty && ClienteRedeLocal().conectado) {
      ClienteRedeLocal().baixarImagemRemota(caminho).then((baixado) {
        if (baixado.isNotEmpty) onAtualizarChat?.call();
      });
    }

    if (file.existsSync()) {
      return GestureDetector(
        onTap: () => VisualizadorImagemChatDialog.abrir(
          context,
          caminho: resolvido,
          theme: theme,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            height: 160,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.borderColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image, size: 16, color: theme.secondaryTextColor),
          const SizedBox(width: 6),
          Text(
            'Foto anexada (baixando...)',
            style: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildArquivoAnexo(MensagemChat msg) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.borderColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file_rounded, size: 20, color: theme.textColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              msg.nomeAnexo.isNotEmpty ? msg.nomeAnexo : 'Arquivo anexado',
              overflow: TextOverflow.ellipsis,
              style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fotoResolvida = ImagemService.resolverCaminhoExistente(msg.remetenteFoto);
    final temFoto = fotoResolvida != null && File(fotoResolvida).existsSync();
    final ehMinhaMsg = ehMinha ||
        ChatService.normalizarCpf(msg.remetenteId) == ChatService.normalizarCpf(cpfLogado);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: ehMinhaMsg ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!ehMinhaMsg) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: theme.borderColor.withValues(alpha: 0.3),
              backgroundImage: temFoto ? FileImage(File(fotoResolvida)) : null,
              child: !temFoto
                  ? Icon(Icons.person, size: 16, color: theme.textColor)
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onLongPress: () => _mostrarMenuMensagem(context),
              onSecondaryTap: () => _mostrarMenuMensagem(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: ehMinhaMsg
                      ? theme.textColor.withValues(alpha: 0.15)
                      : theme.cardBackgroundColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: Radius.circular(ehMinhaMsg ? 12 : 2),
                    bottomRight: Radius.circular(ehMinhaMsg ? 2 : 12),
                  ),
                  border: Border.all(
                    color: ehMinhaMsg
                        ? theme.textColor.withValues(alpha: 0.4)
                        : theme.borderColor.withValues(alpha: 0.6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      ehMinhaMsg ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!ehMinhaMsg)
                      Text(
                        msg.remetenteNome.isNotEmpty ? msg.remetenteNome : 'Membro',
                        style: theme.getTextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    if (msg.tipo == 'imagem' && msg.caminhoAnexo.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _buildImagemAnexo(context, msg.caminhoAnexo),
                    ] else if (msg.tipo == 'audio' && msg.caminhoAnexo.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      CardAudioMensagemGestao(
                        msg: msg,
                        theme: theme,
                        enviadaPorMim: ehMinhaMsg,
                      ),
                    ] else if (msg.tipo == 'arquivo' && msg.caminhoAnexo.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _buildArquivoAnexo(msg),
                    ],
                    if (msg.texto.isNotEmpty &&
                        msg.tipo != 'audio' &&
                        (msg.tipo != 'imagem' || msg.texto != 'Foto compartilhada')) ...[
                      const SizedBox(height: 2),
                      Text(
                        msg.texto,
                        style: theme.getTextStyle(
                          fontSize: 13,
                          color: theme.textColor,
                        ),
                      ),
                    ],
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (msg.editada) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(
                              '(editada)',
                              style: theme.getTextStyle(
                                fontSize: 9,
                                color: theme.secondaryTextColor.withValues(alpha: 0.9),
                              ).copyWith(fontStyle: FontStyle.italic),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          _formatarHora(msg.dataHora),
                          style: theme.getTextStyle(
                            fontSize: 9,
                            color: theme.secondaryTextColor.withValues(alpha: 0.7),
                          ),
                        ),
                        if (ehMinhaMsg) ...[
                          const SizedBox(width: 4),
                          if (msg.statusEnvio == 'pendente')
                            Icon(
                              Icons.access_time_rounded,
                              size: 11,
                              color: theme.secondaryTextColor.withValues(alpha: 0.7),
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
          ),
          if (ehMinhaMsg) const SizedBox(width: 4),
        ],
      ),
    );
  }
}
