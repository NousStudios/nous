import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/timeline/models/notificacao_social.dart';

/// Card minimalista para notificações da rede social (curtidas, deslikes,
/// comentários, republicações, menções `@`, seguidores e convites de colaboração).
class CardNotificacaoSocial extends StatelessWidget {
  final AppTheme theme;
  final NotificacaoSocial notificacao;
  final VoidCallback onTap;
  final ValueChanged<bool>? onResponderConvite;

  const CardNotificacaoSocial({
    super.key,
    required this.theme,
    required this.notificacao,
    required this.onTap,
    this.onResponderConvite,
  });

  String _tempoRelativo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }

  ({IconData icon, Color color}) _iconeTipo() {
    switch (notificacao.tipo) {
      case TipoNotificacaoSocial.curtida:
        return (icon: Icons.thumb_up_alt_rounded, color: theme.textColor);
      case TipoNotificacaoSocial.deslike:
        return (icon: Icons.thumb_down_alt_rounded, color: theme.dangerColor);
      case TipoNotificacaoSocial.comentario:
        return (
          icon: Icons.chat_bubble_outline_rounded,
          color: theme.textColor,
        );
      case TipoNotificacaoSocial.republicacao:
        return (icon: Icons.repeat_rounded, color: theme.textColor);
      case TipoNotificacaoSocial.novoSeguidor:
        return (
          icon: Icons.person_add_alt_1_rounded,
          color: theme.textColor,
        );
      case TipoNotificacaoSocial.mencao:
        return (icon: Icons.alternate_email_rounded, color: theme.textColor);
      case TipoNotificacaoSocial.conviteColaboracao:
        return (icon: Icons.group_add_rounded, color: theme.textColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final caminhoFoto = notificacao.autorFoto.isNotEmpty
        ? ImagemService.resolverCaminhoExistente(notificacao.autorFoto)
        : null;
    final temFoto = caminhoFoto != null && File(caminhoFoto).existsSync();
    final inicial = notificacao.autorNome.trim().isNotEmpty
        ? notificacao.autorNome.trim()[0].toUpperCase()
        : '?';
    final infoIcone = _iconeTipo();
    final ehConviteColab =
        notificacao.tipo == TipoNotificacaoSocial.conviteColaboracao;

    return Card(
      color: theme.backgroundColor.withValues(alpha: 0.4),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: notificacao.lida
              ? theme.borderColor.withValues(alpha: 0.3)
              : theme.borderColor.withValues(alpha: 0.8),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 19,
                        backgroundColor: theme.cardBackgroundColor,
                        backgroundImage:
                            temFoto ? FileImage(File(caminhoFoto)) : null,
                        child: temFoto
                            ? null
                            : Text(
                                inicial,
                                style: theme.getTextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor,
                                ),
                              ),
                      ),
                      Positioned(
                        right: -3,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: theme.cardBackgroundColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.borderColor.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Icon(
                            infoIcone.icon,
                            size: 11,
                            color: infoIcone.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notificacao.resumo,
                          style: theme.getTextStyle(
                            fontSize: 12.5,
                            fontWeight: notificacao.lida
                                ? FontWeight.normal
                                : FontWeight.w600,
                            color: theme.textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _tempoRelativo(notificacao.criadaEm),
                          style: theme.getTextStyle(
                            fontSize: 10.5,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!notificacao.lida)
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(left: 6),
                      decoration: BoxDecoration(
                        color: theme.dangerColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              if (ehConviteColab && onResponderConvite != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.dangerColor,
                          side: BorderSide(
                            color: theme.dangerColor.withValues(alpha: 0.6),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => onResponderConvite!(false),
                        child: Text(
                          'Recusar',
                          style: theme.getTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.dangerColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.textColor,
                          side: BorderSide(color: theme.borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => onResponderConvite!(true),
                        child: Text(
                          'Aceitar',
                          style: theme.getTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
