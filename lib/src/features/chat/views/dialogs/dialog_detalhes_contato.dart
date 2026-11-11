import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_switch.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/auth/views/perfil_social_view.dart';
import 'package:nous/src/features/auth/views/widgets/ficha_usuario_dialog.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/services/resolvedor_foto_chat.dart';
import 'package:nous/src/features/chat/views/dialogs/dialog_mensagens_favoritadas.dart';
import 'package:nous/src/features/chat/views/dialogs/widgets/painel_midias_links_docs_chat_widget.dart';
import 'package:nous/src/features/chat/views/dialogs/widgets/painel_participantes_grupo_chat_widget.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';

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
    void Function(ConversaChat c)? onRenomearConversa,
    void Function(ConversaChat c)? onAbrirMinhaFichaLoja,
  }) async {
    ConversaChat conversaAtual = conversa;
    final participantesInfo = <String, UsuarioNous?>{};

    UsuarioNous? usuarioInterlocutor;
    String biografiaRecado = '';
    var cpfLimpo = conversa.identificador.replaceAll(RegExp(r'\D'), '');
    if (cpfLimpo.length != 11 && conversa.id.startsWith('user_')) {
      final meuCpfLogado = ChatService.normalizarCpf(contaLogada?.cpf ?? '');
      cpfLimpo = ChatService.extrairOutroCpf(conversa.id, meuCpfLogado);
    }

    if (cpfLimpo.length == 11) {
      usuarioInterlocutor = await ContasNousService.buscarPorCpf(cpfLimpo);
      if (usuarioInterlocutor != null &&
          usuarioInterlocutor.biografia.trim().isNotEmpty) {
        biografiaRecado = usuarioInterlocutor.biografia.trim();
      }
    } else if (conversa.ehLoja) {
      if (context.mounted) {
        final pdv = context.read<PdvProvider?>();
        final loja = pdv?.buscarPorId(
          conversa.lojaId ?? conversa.identificador,
        );
        if (loja != null) {
          if (loja.categorias.trim().isNotEmpty) {
            biografiaRecado = loja.categorias.trim();
          } else if (loja.tags.trim().isNotEmpty) {
            biografiaRecado = loja.tags.trim();
          }
        }
      }
    }

    if (conversa.ehGrupo) {
      for (final cpf in conversa.participantesIds) {
        final cLimpo = cpf.replaceAll(RegExp(r'\D'), '');
        if (cLimpo.isNotEmpty) {
          participantesInfo[cpf] = await ContasNousService.buscarPorCpf(
            cLimpo,
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
            final fotoAtual = conversaAtual.foto.isNotEmpty
                ? conversaAtual.foto
                : ResolvedorFotoChat.instancia.obterFotoEmCache(cpfLimpo);

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

                      // Avatar Clicável em Destaque (Tela Cheia)
                      GestureDetector(
                        onTap: () {
                          if (fotoAtual.isNotEmpty) {
                            onVisualizarFotoAmpliada(fotoAtual);
                          }
                        },
                        child: conversaAtual.ehGrupo
                            ? Stack(
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
                                            conversaAtual =
                                                conversaAtual.copyWith(
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
                            : Tooltip(
                                message: 'Toque para ver a foto em tela cheia',
                                child: ResolvedorFotoChat.instancia.buildAvatar(
                                  dialogCtx,
                                  theme: theme,
                                  conversa: conversaAtual,
                                  raio: 46,
                                ),
                              ),
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

                      // Frase da Biografia em destaque sem container
                      if (biografiaRecado.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            biografiaRecado,
                            textAlign: TextAlign.center,
                            style: theme
                                .getTextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textColor,
                                )
                                .copyWith(fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],

                      // Botão de Compartilhar centralizado (e Minha Ficha quando loja)
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _BotaoAcaoRapida(
                            icone: Icons.share_rounded,
                            rotulo: 'Compartilhar',
                            theme: theme,
                            onTap: () {
                              final textoCartao =
                                  '👤 Contato Nous: ${conversaAtual.titulo} (${conversaAtual.subtitulo})\nID: ${conversaAtual.identificador}';
                              Clipboard.setData(
                                ClipboardData(text: textoCartao),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: theme.cardBackgroundColor,
                                  content: Text(
                                    'Dados copiados para a área de transferência!',
                                    style: theme.getTextStyle(
                                      color: theme.textColor,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (conversaAtual.ehLoja && onAbrirMinhaFichaLoja != null)
                            _BotaoAcaoRapida(
                              icone: Icons.badge_outlined,
                              rotulo: 'Minha Ficha',
                              theme: theme,
                              onTap: () {
                                Navigator.pop(ctx);
                                onAbrirMinhaFichaLoja(conversaAtual);
                              },
                            ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      Divider(color: theme.borderColor.withValues(alpha: 0.4)),

                      // Silenciar Notificações com ThemedSwitch
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          conversaAtual.silenciada
                              ? Icons.notifications_off_rounded
                              : Icons.notifications_active_outlined,
                          color: theme.textColor,
                          size: 20,
                        ),
                        title: Text(
                          'Silenciar notificações',
                          style: theme.getTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        trailing: ThemedSwitch(
                          theme: theme,
                          value: conversaAtual.silenciada,
                          onChanged: (val) async {
                            await ChatService.alternarSilenciarConversa(
                              conversaAtual.id,
                            );
                            setDialogState(() {
                              conversaAtual =
                                  conversaAtual.copyWith(silenciada: val);
                            });
                          },
                        ),
                      ),

                      // Mensagens Favoritadas
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.star_rounded,
                          color: theme.textColor,
                          size: 20,
                        ),
                        title: Text(
                          'Mensagens favoritadas',
                          style: theme.getTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: theme.secondaryTextColor,
                          size: 20,
                        ),
                        onTap: () {
                          DialogMensagensFavoritadas.mostrar(
                            context: context,
                            theme: theme,
                            conversa: conversaAtual,
                            onVisualizarFotoAmpliada: (m) =>
                                onVisualizarFotoAmpliada(m.caminhoAnexo),
                            onAbrirArquivo: (m) =>
                                onAbrirArquivo(m.caminhoAnexo),
                            onVerComanda: (_) {},
                          );
                        },
                      ),

                      // Participantes do Grupo
                      if (conversaAtual.ehGrupo) ...[
                        const SizedBox(height: 8),
                        PainelParticipantesGrupoChatWidget(
                          theme: theme,
                          conversa: conversaAtual,
                          contaLogada: contaLogada,
                          participantesInfo: participantesInfo,
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Mídias, Links e Docs compartilhados
                      PainelMidiasLinksDocsChatWidget(
                        theme: theme,
                        conversa: conversaAtual,
                        onVisualizarFotoAmpliada: onVisualizarFotoAmpliada,
                        onAbrirArquivo: onAbrirArquivo,
                      ),

                      const SizedBox(height: 16),

                      // Botões Identidade do Usuário e Ver Perfil Público se for pessoa
                      if (!conversaAtual.ehLoja && !conversaAtual.ehGrupo) ...[
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
                              Icons.badge_outlined,
                              color: theme.textColor,
                              size: 18,
                            ),
                            label: Text(
                              'Identidade do Usuário',
                              style: theme.getTextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                            onPressed: () async {
                              UsuarioNous? usuario = usuarioInterlocutor;
                              if (usuario == null && cpfLimpo.length == 11) {
                                usuario = await ContasNousService.buscarPorCpf(
                                  cpfLimpo,
                                );
                                if (usuario == null && context.mounted) {
                                  final auth = context.read<AuthProvider?>();
                                  usuario = auth?.buscarContaPorCpf(cpfLimpo);
                                }
                              }
                              final fotoMelhor = fotoAtual.isNotEmpty
                                  ? fotoAtual
                                  : conversaAtual.foto;
                              if (usuario != null) {
                                if (usuario.foto.isEmpty &&
                                    fotoMelhor.isNotEmpty) {
                                  usuario = usuario.copyWith(foto: fotoMelhor);
                                }
                              } else {
                                usuario = UsuarioNous(
                                  cpf: cpfLimpo.length == 11
                                      ? cpfLimpo
                                      : conversaAtual.identificador,
                                  nome: conversaAtual.titulo,
                                  apelido: '',
                                  foto: fotoMelhor,
                                  dataNascimento: '',
                                );
                              }
                              if (dialogCtx.mounted) {
                                FichaUsuarioDialog.mostrar(
                                  dialogCtx,
                                  theme: theme,
                                  usuario: usuario,
                                  somenteLeitura: true,
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
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
                              UsuarioNous? usuario = usuarioInterlocutor;
                              if (usuario == null && cpfLimpo.length == 11) {
                                usuario = await ContasNousService.buscarPorCpf(
                                  cpfLimpo,
                                );
                                if (usuario == null && context.mounted) {
                                  final auth = context.read<AuthProvider?>();
                                  usuario = auth?.buscarContaPorCpf(cpfLimpo);
                                }
                              }

                              final fotoMelhor = fotoAtual.isNotEmpty
                                  ? fotoAtual
                                  : conversaAtual.foto;

                              if (usuario != null) {
                                if (usuario.foto.isEmpty &&
                                    fotoMelhor.isNotEmpty) {
                                  usuario = usuario.copyWith(foto: fotoMelhor);
                                }
                              } else {
                                usuario = UsuarioNous(
                                  cpf: cpfLimpo.length == 11
                                      ? cpfLimpo
                                      : conversaAtual.identificador,
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

class _BotaoAcaoRapida extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final AppTheme theme;
  final VoidCallback onTap;

  const _BotaoAcaoRapida({
    required this.icone,
    required this.rotulo,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icone,
              color: theme.textColor,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              rotulo,
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
