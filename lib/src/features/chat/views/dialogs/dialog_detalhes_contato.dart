import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/auth/views/perfil_social_view.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/services/resolvedor_foto_chat.dart';
import 'package:nous/src/features/chat/views/dialogs/widgets/painel_midias_links_docs_chat_widget.dart';
import 'package:nous/src/features/chat/views/dialogs/widgets/painel_participantes_grupo_chat_widget.dart';

class DialogDetalhesContato {
  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required ConversaChat conversa,
    required UsuarioNous? contaLogada,
    required Future<String?> Function() onSelecionarFotoGrupo,
    required Future<void> Function(ConversaChat c) onExportarBackup,
    required void Function(ConversaChat c) onSolicitarExclusao,
    required void Function(ConversaChat c) onSolicitarSaidaGrupo,
    required void Function(String caminho) onVisualizarFotoAmpliada,
    required void Function(String caminho) onAbrirArquivo,
  }) async {
    ConversaChat conversaAtual = conversa;
    final participantesInfo = <String, UsuarioNous?>{};

    if (conversa.ehGrupo) {
      for (final cpf in conversa.participantesIds) {
        final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
        if (cpfLimpo.isNotEmpty) {
          participantesInfo[cpf] = await ContasNousService.buscarPorCpf(
            cpfLimpo,
          );
        }
      }
    }

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.cardBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.borderColor),
              ),
              contentPadding: const EdgeInsets.all(20),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 420,
                  maxHeight: MediaQuery.sizeOf(context).height * 0.90,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: Icon(
                            Icons.close,
                            color: theme.secondaryTextColor,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ),
                      if (conversaAtual.ehGrupo)
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            ResolvedorFotoChat.instancia.buildAvatar(
                              dialogCtx,
                              theme: theme,
                              conversa: conversaAtual,
                              raio: 46,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: InkWell(
                                onTap: () async {
                                  final novoCaminho =
                                      await onSelecionarFotoGrupo();
                                  if (novoCaminho != null &&
                                      novoCaminho.isNotEmpty) {
                                    await ChatService.atualizarFotoGrupo(
                                      conversaAtual.id,
                                      novoCaminho,
                                    );
                                    setDialogState(() {
                                      conversaAtual = conversaAtual.copyWith(
                                        foto: novoCaminho,
                                      );
                                    });
                                    if (dialogCtx.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          backgroundColor:
                                              theme.cardBackgroundColor,
                                          content: Text(
                                            'Foto do grupo atualizada com sucesso!',
                                            style: theme.getTextStyle(
                                              color: theme.textColor,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: theme.buttonColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.cardBackgroundColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt_rounded,
                                    size: 16,
                                    color: theme.buttonTextColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        ResolvedorFotoChat.instancia.buildAvatar(
                          dialogCtx,
                          theme: theme,
                          conversa: conversaAtual,
                          raio: 42,
                        ),
                      const SizedBox(height: 12),
                      Text(
                        conversaAtual.ehGrupo
                            ? (conversaAtual.nomeGrupo.isNotEmpty
                                  ? conversaAtual.nomeGrupo
                                  : conversaAtual.titulo)
                            : (conversaAtual.titulo.isNotEmpty &&
                                      conversaAtual.titulo != 'Conversa'
                                  ? conversaAtual.titulo
                                  : (conversaAtual.subtitulo.isNotEmpty
                                        ? conversaAtual.subtitulo
                                        : 'Contato')),
                        textAlign: TextAlign.center,
                        style: theme.getTextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        conversaAtual.ehGrupo
                            ? 'Grupo • ${conversaAtual.participantesIds.length} participantes'
                            : (conversaAtual.subtitulo.isNotEmpty
                                  ? conversaAtual.subtitulo
                                  : 'Usuário Nous'),
                        textAlign: TextAlign.center,
                        style: theme.getTextStyle(
                          fontSize: 12,
                          color: theme.secondaryTextColor,
                        ),
                      ),

                      // Participantes do Grupo
                      if (conversaAtual.ehGrupo) ...[
                        const SizedBox(height: 14),
                        PainelParticipantesGrupoChatWidget(
                          theme: theme,
                          conversa: conversaAtual,
                          contaLogada: contaLogada,
                          participantesInfo: participantesInfo,
                        ),
                      ],
                      const SizedBox(height: 18),
                      Divider(color: theme.borderColor.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),

                      // Mídias, Links e Docs compartilhados
                      PainelMidiasLinksDocsChatWidget(
                        theme: theme,
                        conversa: conversaAtual,
                        onVisualizarFotoAmpliada: onVisualizarFotoAmpliada,
                        onAbrirArquivo: onAbrirArquivo,
                      ),

                      const SizedBox(height: 16),

                      // Botão Ver Perfil Público se for pessoa
                      if (!conversaAtual.ehLoja && !conversaAtual.ehGrupo) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.buttonColor,
                              foregroundColor: theme.buttonTextColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: Icon(
                              Icons.person_outline,
                              color: theme.buttonTextColor,
                              size: 18,
                            ),
                            label: Text(
                              'Ver Perfil Público',
                              style: theme.getTextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.buttonTextColor,
                              ),
                            ),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              UsuarioNous? usuario;
                              final cpfLimpo = conversaAtual.identificador
                                  .replaceAll(RegExp(r'\D'), '');
                              if (cpfLimpo.length == 11) {
                                usuario = await ContasNousService.buscarPorCpf(
                                  cpfLimpo,
                                );
                              }
                              final fotoDoChat = ResolvedorFotoChat.instancia
                                  .obterFotoEmCache(cpfLimpo);
                              final fotoMelhor = fotoDoChat.isNotEmpty
                                  ? fotoDoChat
                                  : conversaAtual.foto;

                              if (usuario != null) {
                                if (usuario.foto.isEmpty && fotoMelhor.isNotEmpty) {
                                  usuario = usuario.copyWith(foto: fotoMelhor);
                                }
                              } else {
                                usuario = UsuarioNous(
                                  cpf: conversaAtual.identificador,
                                  nome: conversaAtual.titulo,
                                  apelido: '',
                                  foto: fotoMelhor,
                                  dataNascimento: '',
                                );
                              }
                              if (context.mounted) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PerfilSocialView(
                                      usuarioAlvo: usuario,
                                      mostrarBotaoVoltar: true,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Botão Exportar Backup da Conversa
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.textColor,
                            side: BorderSide(color: theme.borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                          icon: Icon(
                            Icons.download_rounded,
                            color: theme.textColor,
                            size: 18,
                          ),
                          label: Text(
                            'Exportar backup da conversa',
                            style: theme.getTextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            onExportarBackup(conversaAtual);
                          },
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Botão Excluir Conversa
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.dangerColor,
                            side: BorderSide(
                              color: theme.dangerColor.withValues(alpha: 0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: theme.dangerColor,
                            size: 18,
                          ),
                          label: Text(
                            'Excluir conversa',
                            style: theme.getTextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.dangerColor,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            onSolicitarExclusao(conversaAtual);
                          },
                        ),
                      ),

                      // Botão Sair do Grupo se for grupo
                      if (conversaAtual.ehGrupo) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.dangerColor,
                              side: BorderSide(
                                color: theme.dangerColor.withValues(alpha: 0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                            icon: Icon(
                              Icons.logout_rounded,
                              color: theme.dangerColor,
                              size: 18,
                            ),
                            label: Text(
                              'Sair do grupo',
                              style: theme.getTextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.dangerColor,
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              onSolicitarSaidaGrupo(conversaAtual);
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
