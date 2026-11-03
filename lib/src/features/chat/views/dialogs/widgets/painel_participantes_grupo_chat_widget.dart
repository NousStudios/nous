import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

class PainelParticipantesGrupoChatWidget extends StatelessWidget {
  final AppTheme theme;
  final ConversaChat conversa;
  final UsuarioNous? contaLogada;
  final Map<String, UsuarioNous?> participantesInfo;

  const PainelParticipantesGrupoChatWidget({
    super.key,
    required this.theme,
    required this.conversa,
    required this.contaLogada,
    required this.participantesInfo,
  });

  static String _formatarCpf(String cpf) {
    final d = cpf.replaceAll(RegExp(r'\D'), '');
    if (d.length != 11) return cpf;
    return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6, 9)}-${d.substring(9)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 18,
                color: theme.textColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Participantes (${conversa.participantesIds.length})',
                style: theme.getTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...conversa.participantesIds.map((cpf) {
            final ehEu = contaLogada != null &&
                ChatService.normalizarCpf(contaLogada!.cpf) ==
                    ChatService.normalizarCpf(cpf);
            final uInfo = participantesInfo[cpf];
            final nome =
                ehEu ? 'Você' : (uInfo?.nomeExibicao ?? 'Usuário Nous');
            final foto =
                ehEu ? contaLogada!.fotoExibicao : (uInfo?.fotoExibicao ?? '');
            final fotoRes = ImagemService.resolverCaminhoExistente(foto);
            final temF = fotoRes != null && File(fotoRes).existsSync();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        theme.borderColor.withValues(alpha: 0.3),
                    backgroundImage:
                        temF ? FileImage(File(fotoRes)) : null,
                    child: !temF
                        ? Icon(
                            Icons.person,
                            size: 16,
                            color: theme.textColor,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nome,
                          style: theme.getTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.textColor,
                          ),
                        ),
                        Text(
                          _formatarCpf(cpf),
                          style: theme.getTextStyle(
                            fontSize: 10,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (ehEu)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.buttonColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Você',
                        style: theme.getTextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.buttonColor,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
