import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/controllers/mensageria_controller.dart';
import 'package:nous/src/features/chat/services/gravador_audio_service.dart';

/// Barra de composição e envio de mensagens (texto, áudio, câmera e anexos).
class BarraEnvioMensagemWidget extends StatefulWidget {
  final MensageriaController controller;
  final AppTheme theme;
  final TextEditingController mensagemController;
  final VoidCallback onEnviarTexto;
  final void Function(String caminho, String duracao, int tamanho) onEnviarAudio;
  final VoidCallback onCapturarFotoCamera;
  final VoidCallback onAbrirMenuAnexo;

  const BarraEnvioMensagemWidget({
    super.key,
    required this.controller,
    required this.theme,
    required this.mensagemController,
    required this.onEnviarTexto,
    required this.onEnviarAudio,
    required this.onCapturarFotoCamera,
    required this.onAbrirMenuAnexo,
  });

  @override
  State<BarraEnvioMensagemWidget> createState() => _BarraEnvioMensagemWidgetState();
}

class _BarraEnvioMensagemWidgetState extends State<BarraEnvioMensagemWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return ValueListenableBuilder<bool>(
      valueListenable: GravadorAudioService.instancia.gravandoNotifier,
      builder: (context, gravando, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: theme.cardBackgroundColor,
            border: Border(
              top: BorderSide(
                color: theme.borderColor.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: gravando
              ? Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: theme.dangerColor,
                        size: 24,
                      ),
                      tooltip: 'Cancelar e descartar áudio',
                      onPressed: () =>
                          GravadorAudioService.instancia.cancelarGravacao(),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: theme.dangerColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(21),
                          border: Border.all(
                            color: theme.dangerColor.withValues(
                              alpha: 0.35,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.fiber_manual_record_rounded,
                              color: theme.dangerColor,
                              size: 14,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Gravando áudio...',
                              style: theme.getTextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.dangerColor,
                              ),
                            ),
                            const Spacer(),
                            ValueListenableBuilder<Duration>(
                              valueListenable: GravadorAudioService
                                  .instancia
                                  .duracaoNotifier,
                              builder: (context, dur, _) {
                                final min = dur.inMinutes;
                                final sec = dur.inSeconds % 60;
                                return Text(
                                  '$min:${sec.toString().padLeft(2, '0')}',
                                  style: theme.getTextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textColor,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () async {
                        final gravado = await GravadorAudioService.instancia
                            .finalizarGravacao();
                        if (gravado != null) {
                          final tamanho = await File(
                            gravado.caminho,
                          ).length();
                          final duracaoSegundos = gravado.duracao.inSeconds;
                          final minutos = duracaoSegundos ~/ 60;
                          final segundos = duracaoSegundos % 60;
                          final duracaoTexto =
                              '$minutos:${segundos.toString().padLeft(2, '0')}';
                          widget.onEnviarAudio(
                            gravado.caminho,
                            duracaoTexto,
                            tamanho,
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(21),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: theme.buttonColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.send_rounded,
                          size: 18,
                          color: theme.buttonTextColor,
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.camera_alt_rounded,
                        color: theme.textColor,
                        size: 22,
                      ),
                      tooltip: 'Câmera / Tirar foto',
                      onPressed: widget.onCapturarFotoCamera,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.attach_file_rounded,
                        color: theme.textColor,
                        size: 22,
                      ),
                      tooltip: 'Anexar imagem, arquivo, comanda ou áudio',
                      onPressed: widget.onAbrirMenuAnexo,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(
                          minHeight: 42,
                          maxHeight: 110,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: theme.backgroundColor,
                          borderRadius: BorderRadius.circular(21),
                          border: Border.all(
                            color: theme.borderColor.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Focus(
                          onKeyEvent: (node, event) {
                            if (!Platform.isAndroid && !Platform.isIOS) {
                              if (event is KeyDownEvent &&
                                  event.logicalKey ==
                                      LogicalKeyboardKey.enter) {
                                if (HardwareKeyboard
                                    .instance
                                    .isShiftPressed) {
                                  return KeyEventResult.ignored;
                                } else {
                                  widget.onEnviarTexto();
                                  return KeyEventResult.handled;
                                }
                              }
                            }
                            return KeyEventResult.ignored;
                          },
                          child: TextField(
                            controller: widget.mensagemController,
                            keyboardType: TextInputType.multiline,
                            textInputAction:
                                (Platform.isAndroid || Platform.isIOS)
                                ? TextInputAction.newline
                                : TextInputAction.send,
                            minLines: 1,
                            maxLines: 4,
                            style: theme.getTextStyle(
                              fontSize: 13,
                              color: theme.textColor,
                            ),
                            onSubmitted:
                                (Platform.isAndroid || Platform.isIOS)
                                ? null
                                : (_) => widget.onEnviarTexto(),
                            decoration: InputDecoration(
                              hintText: widget.controller.modoLoja
                                  ? 'Responder em nome de ${widget.controller.nomeLoja ?? "Loja"}...'
                                  : 'Digite uma mensagem...',
                              hintStyle: theme.getTextStyle(
                                fontSize: 12,
                                color: theme.secondaryTextColor,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: widget.mensagemController.text.trim().isNotEmpty
                          ? widget.onEnviarTexto
                          : () => GravadorAudioService.instancia
                                .iniciarGravacao(),
                      borderRadius: BorderRadius.circular(21),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: theme.buttonColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.mensagemController.text.trim().isNotEmpty
                              ? Icons.send_rounded
                              : Icons.mic_rounded,
                          size: 19,
                          color: theme.buttonTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
