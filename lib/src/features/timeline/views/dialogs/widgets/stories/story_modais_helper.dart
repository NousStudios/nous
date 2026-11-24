import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_repositorio_sqlite.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';

/// Modais auxiliares do visualizador de Stories: visualizadores,
/// encaminhamento no chat e confirmação de exclusão.
abstract final class StoryModaisHelper {
  static Future<void> mostrarVisualizadores(
    BuildContext context, {
    required AppTheme theme,
    required StorySocial story,
  }) async {
    final cpfs = story.visualizadoPorCpfs;
    final todasContas = await ContasNousService.carregarTodas();
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        title: Text(
          'Visualizações (${cpfs.length})',
          style: theme.getTextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        content: SizedBox(
          width: 320,
          child: cpfs.isEmpty
              ? Text(
                  'Ninguém visualizou este story ainda.',
                  style: theme.getTextStyle(
                    fontSize: 13,
                    color: theme.secondaryTextColor,
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: cpfs.length,
                  itemBuilder: (_, i) {
                    final cpf = cpfs[i];
                    final conta = todasContas
                        .where(
                          (c) =>
                              c.cpf.replaceAll(RegExp(r'\D'), '') ==
                              cpf.replaceAll(RegExp(r'\D'), ''),
                        )
                        .firstOrNull;
                    final nome = conta?.nomeExibicao.isNotEmpty == true
                        ? conta!.nomeExibicao
                        : cpf;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.visibility_outlined,
                        size: 18,
                        color: theme.buttonColor,
                      ),
                      title: Text(
                        nome,
                        style: theme.getTextStyle(
                          fontSize: 13,
                          color: theme.textColor,
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  static Future<bool> confirmarExclusao(
    BuildContext context, {
    required AppTheme theme,
  }) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        title: Text(
          'Excluir Story',
          style: theme.getTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        content: Text(
          'Deseja remover este story de todos os aparelhos?',
          style: theme.getTextStyle(
            fontSize: 13,
            color: theme.secondaryTextColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Excluir',
              style: theme.getTextStyle(
                color: theme.dangerColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    return confirmar == true;
  }

  static Future<void> encaminharNoChat(
    BuildContext context, {
    required AppTheme theme,
    required StorySocial story,
    required UsuarioNous usuarioLogado,
  }) async {
    final meuCpfNorm =
        TimelineRepositorioSqlite.normalizarCpf(usuarioLogado.cpf);
    final todasContas = await ContasNousService.carregarTodas();
    final contatos = todasContas
        .where(
          (c) =>
              TimelineRepositorioSqlite.normalizarCpf(c.cpf) != meuCpfNorm &&
              c.cpf.trim().isNotEmpty,
        )
        .toList();
    if (!context.mounted) return;

    final destino = await showDialog<UsuarioNous>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        title: Text(
          'Enviar Story no Chat',
          style: theme.getTextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        content: SizedBox(
          width: 320,
          height: 300,
          child: contatos.isEmpty
              ? Center(
                  child: Text(
                    'Nenhum contato encontrado na rede.',
                    style: theme.getTextStyle(
                      fontSize: 13,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: contatos.length,
                  itemBuilder: (_, i) {
                    final c = contatos[i];
                    final img = ImagemService.obterImageProvider(c.fotoExibicao);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: img,
                        child: img == null
                            ? Text(
                                c.nomeExibicao.isNotEmpty
                                    ? c.nomeExibicao[0].toUpperCase()
                                    : '?',
                              )
                            : null,
                      ),
                      title: Text(
                        c.nomeExibicao,
                        style: theme.getTextStyle(
                          fontSize: 13,
                          color: theme.textColor,
                        ),
                      ),
                      subtitle: c.nomeDeUsuario.isNotEmpty
                          ? Text(
                              '@${c.nomeDeUsuario}',
                              style: theme.getTextStyle(
                                fontSize: 11,
                                color: theme.secondaryTextColor,
                              ),
                            )
                          : null,
                      onTap: () => Navigator.of(ctx).pop(c),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancelar',
              style: theme.getTextStyle(color: theme.secondaryTextColor),
            ),
          ),
        ],
      ),
    );

    if (destino != null) {
      await TimelineService.encaminharStoryNoChat(
        story: story,
        meuCpf: usuarioLogado.cpf,
        meuNome: usuarioLogado.nomeExibicao,
        minhaFoto: usuarioLogado.fotoExibicao,
        destinatarioCpf: destino.cpf,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Story enviado para ${destino.nomeExibicao}!'),
          ),
        );
      }
    }
  }
}
