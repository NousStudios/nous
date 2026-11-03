import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

/// Card especializado para exibição de notificações de novas mensagens do chat.
class CardNotificacaoChat extends StatelessWidget {
  final AppTheme theme;
  final MensagemChat msg;
  final VoidCallback onTap;

  const CardNotificacaoChat({
    super.key,
    required this.theme,
    required this.msg,
    required this.onTap,
  });

  static String _doisDigitos(int n) => n.toString().padLeft(2, '0');

  static String _dataHoraCurta(DateTime d) =>
      '${_doisDigitos(d.day)}/${_doisDigitos(d.month)}/${d.year} '
      '${_doisDigitos(d.hour)}:${_doisDigitos(d.minute)}';

  @override
  Widget build(BuildContext context) {
    final fotoResolvida =
        ImagemService.resolverCaminhoExistente(msg.remetenteFoto);
    final temFoto = fotoResolvida != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.backgroundColor.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.buttonColor.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.borderColor.withValues(alpha: 0.3),
                  backgroundImage:
                      temFoto ? FileImage(File(fotoResolvida)) : null,
                  child: !temFoto
                      ? Icon(
                          Icons.person,
                          size: 20,
                          color: theme.textColor,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextoRolante(
                              texto: msg.remetenteNome.isNotEmpty
                                  ? msg.remetenteNome
                                  : 'Mensagem',
                              style: theme.getTextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _dataHoraCurta(msg.dataHora),
                            style: theme.getTextStyle(
                              fontSize: 10,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      TextoRolante(
                        texto: msg.texto,
                        style: theme.getTextStyle(
                          fontSize: 12,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 18,
                  color: theme.buttonColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
