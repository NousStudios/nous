import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/controllers/mensageria_controller.dart';

/// Barra padrão de composição de texto com botões de câmera, anexo e envio/microfone.
class BarraComposicaoMensagemWidget extends StatelessWidget {
  final AppTheme theme;
  final MensageriaController controller;
  final TextEditingController mensagemController;
  final bool temTexto;
  final VoidCallback onEnviarTexto;
  final VoidCallback onCapturarFotoCamera;
  final VoidCallback onAbrirMenuAnexo;
  final void Function(PointerDownEvent) onPressionarMic;
  final void Function(PointerMoveEvent) onMoverMic;
  final VoidCallback onSoltarMic;

  const BarraComposicaoMensagemWidget({
    super.key,
    required this.theme,
    required this.controller,
    required this.mensagemController,
    required this.temTexto,
    required this.onEnviarTexto,
    required this.onCapturarFotoCamera,
    required this.onAbrirMenuAnexo,
    required this.onPressionarMic,
    required this.onMoverMic,
    required this.onSoltarMic,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            Icons.camera_alt_rounded,
            color: theme.textColor,
            size: 22,
          ),
          tooltip: 'Câmera / Tirar foto',
          onPressed: onCapturarFotoCamera,
        ),
        IconButton(
          icon: Icon(
            Icons.attach_file_rounded,
            color: theme.textColor,
            size: 22,
          ),
          tooltip: 'Anexar imagem, arquivo, comanda ou áudio',
          onPressed: onAbrirMenuAnexo,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 42, maxHeight: 110),
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
                      event.logicalKey == LogicalKeyboardKey.enter) {
                    if (HardwareKeyboard.instance.isShiftPressed) {
                      return KeyEventResult.ignored;
                    } else {
                      onEnviarTexto();
                      return KeyEventResult.handled;
                    }
                  }
                }
                return KeyEventResult.ignored;
              },
              child: TextField(
                controller: mensagemController,
                keyboardType: TextInputType.multiline,
                textInputAction: (Platform.isAndroid || Platform.isIOS)
                    ? TextInputAction.newline
                    : TextInputAction.send,
                minLines: 1,
                maxLines: 4,
                style: theme.getTextStyle(fontSize: 13, color: theme.textColor),
                onSubmitted: (Platform.isAndroid || Platform.isIOS)
                    ? null
                    : (_) => onEnviarTexto(),
                decoration: InputDecoration(
                  hintText: controller.modoLoja
                      ? 'Responder em nome de ${controller.nomeLoja ?? "Loja"}...'
                      : 'Digite uma mensagem...',
                  hintStyle: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.secondaryTextColor,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (temTexto)
          InkWell(
            onTap: onEnviarTexto,
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
                size: 19,
                color: theme.buttonTextColor,
              ),
            ),
          )
        else
          Listener(
            onPointerDown: onPressionarMic,
            onPointerMove: onMoverMic,
            onPointerUp: (_) => onSoltarMic(),
            onPointerCancel: (_) => onSoltarMic(),
            child: Tooltip(
              message: 'Segure para gravar • Arraste ↑ para travar',
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.buttonColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mic_rounded,
                  size: 19,
                  color: theme.buttonTextColor,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
