import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/services/gravador_audio_service.dart';

/// Barra inferior de envio de texto, anexo, câmera e gravação de áudio do chat de Gestão Nous.
class BarraEnvioMensagemGestao extends StatelessWidget {
  final AppTheme theme;
  final TextEditingController controller;
  final VoidCallback onEnviarTexto;
  final VoidCallback onIniciarGravacaoVoz;
  final VoidCallback onFinalizarEEnviarGravacaoVoz;
  final VoidCallback onCancelarGravacaoVoz;
  final VoidCallback onCapturarFotoCamera;
  final VoidCallback onAbrirMenuAnexo;
  final ValueChanged<String>? onChanged;

  const BarraEnvioMensagemGestao({
    super.key,
    required this.theme,
    required this.controller,
    required this.onEnviarTexto,
    required this.onIniciarGravacaoVoz,
    required this.onFinalizarEEnviarGravacaoVoz,
    required this.onCancelarGravacaoVoz,
    required this.onCapturarFotoCamera,
    required this.onAbrirMenuAnexo,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GravadorAudioService.instancia.gravandoNotifier,
      builder: (context, gravando, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: theme.borderColor.withValues(alpha: 0.4),
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
                      tooltip: 'Cancelar gravação',
                      onPressed: onCancelarGravacaoVoz,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Gravando áudio...',
                            style: theme.getTextStyle(
                              fontSize: 13,
                              color: theme.textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          ValueListenableBuilder<Duration>(
                            valueListenable:
                                GravadorAudioService.instancia.duracaoNotifier,
                            builder: (context, duracao, _) {
                              final min = duracao.inMinutes;
                              final seg = duracao.inSeconds % 60;
                              return Text(
                                '$min:${seg.toString().padLeft(2, '0')}',
                                style: theme.getTextStyle(
                                  fontSize: 13,
                                  color: theme.secondaryTextColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onFinalizarEEnviarGravacaoVoz,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
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
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Câmera / Tirar foto',
                      icon: Icon(
                        Icons.camera_alt_rounded,
                        color: theme.textColor,
                        size: 22,
                      ),
                      onPressed: onCapturarFotoCamera,
                    ),
                    IconButton(
                      tooltip: 'Anexar imagem ou arquivo',
                      icon: Icon(
                        Icons.attach_file_rounded,
                        color: theme.textColor,
                        size: 22,
                      ),
                      onPressed: onAbrirMenuAnexo,
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
                          color: theme.backgroundColor.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(21),
                          border: Border.all(
                            color: theme.borderColor.withValues(alpha: 0.6),
                          ),
                        ),
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          minLines: 1,
                          maxLines: 4,
                          style: theme.getTextStyle(
                            fontSize: 13,
                            color: theme.textColor,
                          ),
                          onChanged: onChanged,
                          onSubmitted: (Platform.isAndroid || Platform.isIOS)
                              ? null
                              : (_) => onEnviarTexto(),
                          decoration: InputDecoration(
                            hintText: 'Escreva uma mensagem...',
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
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: controller.text.trim().isNotEmpty
                          ? onEnviarTexto
                          : onIniciarGravacaoVoz,
                      borderRadius: BorderRadius.circular(21),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: theme.buttonColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          controller.text.trim().isNotEmpty
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
