import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/auth/views/perfil_social_view.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/services/resolvedor_foto_chat.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

class DialogDetalhesContato {
  static String _formatarTamanho(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String _formatarCpf(String cpf) {
    final d = cpf.replaceAll(RegExp(r'\D'), '');
    if (d.length != 11) return cpf;
    return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6, 9)}-${d.substring(9)}';
  }

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
                        Container(
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
                                    'Participantes (${conversaAtual.participantesIds.length})',
                                    style: theme.getTextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ...conversaAtual.participantesIds.map((cpf) {
                                final ehEu =
                                    contaLogada != null &&
                                    ChatService.normalizarCpf(
                                          contaLogada.cpf,
                                        ) ==
                                        ChatService.normalizarCpf(cpf);
                                final uInfo = participantesInfo[cpf];
                                final nome = ehEu
                                    ? 'Você'
                                    : (uInfo?.nomeExibicao ?? 'Usuário Nous');
                                final foto = ehEu
                                    ? contaLogada.fotoExibicao
                                    : (uInfo?.fotoExibicao ?? '');
                                final fotoRes =
                                    ImagemService.resolverCaminhoExistente(
                                      foto,
                                    );
                                final temF =
                                    fotoRes != null &&
                                    File(fotoRes).existsSync();

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: theme.borderColor
                                            .withValues(alpha: 0.3),
                                        backgroundImage: temF
                                            ? FileImage(File(fotoRes))
                                            : null,
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                            color: theme.buttonColor.withValues(
                                              alpha: 0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
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
                        ),
                      ],
                      const SizedBox(height: 18),
                      Divider(color: theme.borderColor.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),

                      // Mídias, Links e Docs compartilhados (usando conversaAtual.mensagens viva)
                      Builder(
                        builder: (bCtx) {
                          final midias = conversaAtual.mensagens
                              .where(
                                (m) =>
                                    m.tipo == 'imagem' &&
                                    m.caminhoAnexo.trim().isNotEmpty,
                              )
                              .toList();
                          final docs = conversaAtual.mensagens
                              .where(
                                (m) =>
                                    m.tipo == 'arquivo' &&
                                    m.caminhoAnexo.trim().isNotEmpty,
                              )
                              .toList();
                          final links = conversaAtual.mensagens
                              .where(
                                (m) =>
                                    m.tipo == 'texto' &&
                                    (m.texto.contains('http://') ||
                                        m.texto.contains('https://') ||
                                        m.texto.contains('www.')),
                              )
                              .toList();
                          final totalItens =
                              midias.length + docs.length + links.length;

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
                                      Icons.photo_library_outlined,
                                      size: 18,
                                      color: theme.textColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Mídias, Links e Docs',
                                      style: theme.getTextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: theme.textColor,
                                      ),
                                    ),
                                    if (totalItens > 0) ...[
                                      const Spacer(),
                                      Text(
                                        '$totalItens',
                                        style: theme.getTextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: theme.secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (totalItens == 0)
                                  Text(
                                    'Nenhuma mídia ou documento compartilhado nesta conversa.',
                                    style: theme.getTextStyle(
                                      fontSize: 11,
                                      color: theme.secondaryTextColor,
                                    ),
                                  )
                                else ...[
                                  // Fotos
                                  if (midias.isNotEmpty) ...[
                                    Text(
                                      'Fotos (${midias.length})',
                                      style: theme.getTextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: theme.secondaryTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: midias.map((m) {
                                        final resolvido =
                                            ImagemService.resolverCaminhoExistente(
                                              m.caminhoAnexo,
                                            );
                                        final existe =
                                            resolvido != null &&
                                            File(resolvido).existsSync();

                                        return InkWell(
                                          onTap: existe
                                              ? () => onVisualizarFotoAmpliada(
                                                  resolvido,
                                                )
                                              : null,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Container(
                                            width: 64,
                                            height: 64,
                                            decoration: BoxDecoration(
                                              color: theme.cardBackgroundColor,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: theme.borderColor
                                                    .withValues(alpha: 0.6),
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(7),
                                              child: existe
                                                  ? Image.file(
                                                      File(resolvido),
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) => Icon(
                                                            Icons
                                                                .broken_image_outlined,
                                                            size: 24,
                                                            color: theme
                                                                .secondaryTextColor,
                                                          ),
                                                    )
                                                  : Icon(
                                                      Icons.image_outlined,
                                                      size: 24,
                                                      color: theme
                                                          .secondaryTextColor,
                                                    ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 10),
                                  ],

                                  // Documentos
                                  if (docs.isNotEmpty) ...[
                                    Text(
                                      'Documentos (${docs.length})',
                                      style: theme.getTextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: theme.secondaryTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Column(
                                      children: docs.map((d) {
                                        return Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 6,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.cardBackgroundColor,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: theme.borderColor
                                                  .withValues(alpha: 0.5),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons
                                                    .insert_drive_file_outlined,
                                                size: 20,
                                                color: theme.textColor,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      d.nomeAnexo.isNotEmpty
                                                          ? d.nomeAnexo
                                                          : 'Arquivo',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: theme.getTextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: theme.textColor,
                                                      ),
                                                    ),
                                                    if (d.tamanhoAnexo > 0)
                                                      Text(
                                                        _formatarTamanho(
                                                          d.tamanhoAnexo,
                                                        ),
                                                        style: theme.getTextStyle(
                                                          fontSize: 10,
                                                          color: theme
                                                              .secondaryTextColor,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.open_in_new_rounded,
                                                  size: 16,
                                                  color: theme.textColor,
                                                ),
                                                tooltip: 'Abrir',
                                                visualDensity:
                                                    VisualDensity.compact,
                                                onPressed: () => onAbrirArquivo(
                                                  d.caminhoAnexo,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 6),
                                  ],

                                  // Links
                                  if (links.isNotEmpty) ...[
                                    Text(
                                      'Links (${links.length})',
                                      style: theme.getTextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: theme.secondaryTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Column(
                                      children: links.map((l) {
                                        return Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 6,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.cardBackgroundColor,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: theme.borderColor
                                                  .withValues(alpha: 0.5),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.link,
                                                size: 18,
                                                color: theme.buttonColor,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: SelectableText(
                                                  l.texto,
                                                  style: theme.getTextStyle(
                                                    fontSize: 11,
                                                    color: theme.textColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          );
                        },
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
