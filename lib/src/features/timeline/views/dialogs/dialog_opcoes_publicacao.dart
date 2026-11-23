import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/auth/views/perfil_social_view.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/views/widgets/avatar_com_story_widget.dart';

/// Resumo das interações de um usuário em uma publicação (like, deslike, republicação).
class InteracaoUsuarioResumo {
  final String cpf;
  final String nome;
  final String foto;
  final bool deuLike;
  final bool deuDeslike;
  final bool republicou;

  const InteracaoUsuarioResumo({
    required this.cpf,
    required this.nome,
    required this.foto,
    this.deuLike = false,
    this.deuDeslike = false,
    this.republicou = false,
  });
}

/// Diálogos auxiliares da publicação: menu de opções (Editar/Excluir/Baixar/Denunciar)
/// e lista de quem deu Like, Deslike ou Republicou.
class DialogOpcoesPublicacao {
  DialogOpcoesPublicacao._();

  static Future<String?> mostrarMenuOpcoes(
    BuildContext context, {
    required AppTheme theme,
    required PublicacaoSocial publicacao,
    required bool ehAutor,
    required bool podeDenunciar,
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: theme.borderColor),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Opções da Publicação',
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 10),
                Divider(color: theme.borderColor.withValues(alpha: 0.4)),
                if (ehAutor) ...[
                  ListTile(
                    leading: Icon(
                      publicacao.fixada
                          ? Icons.push_pin_outlined
                          : Icons.push_pin_rounded,
                      color: theme.textColor,
                    ),
                    title: Text(
                      publicacao.fixada ? 'Desafixar do topo' : 'Fixar no topo',
                      style: theme.getTextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                    ),
                    onTap: () => Navigator.of(ctx).pop('fixar'),
                  ),
                  ListTile(
                    leading: Icon(Icons.edit_outlined, color: theme.textColor),
                    title: Text(
                      'Editar publicação',
                      style: theme.getTextStyle(
                        fontSize: 13.5,
                        color: theme.textColor,
                      ),
                    ),
                    onTap: () => Navigator.of(ctx).pop('editar'),
                  ),
                  ListTile(
                    leading: Icon(
                      publicacao.arquivada
                          ? Icons.unarchive_outlined
                          : Icons.archive_outlined,
                      color: theme.textColor,
                    ),
                    title: Text(
                      publicacao.arquivada
                          ? 'Desarquivar publicação'
                          : 'Arquivar publicação',
                      style: theme.getTextStyle(
                        fontSize: 13.5,
                        color: theme.textColor,
                      ),
                    ),
                    onTap: () => Navigator.of(ctx).pop('arquivar'),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.delete_outline,
                      color: theme.dangerColor,
                    ),
                    title: Text(
                      'Excluir publicação',
                      style: theme.getTextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: theme.dangerColor,
                      ),
                    ),
                    onTap: () => Navigator.of(ctx).pop('excluir'),
                  ),
                ],
                if (publicacao.midias.isNotEmpty &&
                    (publicacao.permitirDownload || ehAutor))
                  ListTile(
                    leading: Icon(
                      Icons.download_rounded,
                      color: theme.textColor,
                    ),
                    title: Text(
                      'Baixar arquivo/mídia',
                      style: theme.getTextStyle(
                        fontSize: 13.5,
                        color: theme.textColor,
                      ),
                    ),
                    onTap: () => Navigator.of(ctx).pop('baixar'),
                  ),
                if (podeDenunciar && !ehAutor)
                  ListTile(
                    leading: Icon(
                      Icons.shield_outlined,
                      color: theme.dangerColor,
                    ),
                    title: Text(
                      'Denunciar publicação',
                      style: theme.getTextStyle(
                        fontSize: 13.5,
                        color: theme.dangerColor,
                      ),
                    ),
                    onTap: () => Navigator.of(ctx).pop('denunciar'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> mostrarListaReacoes(
    BuildContext context, {
    required AppTheme theme,
    required List<ReacaoSocial> reacoes,
    required TipoReacaoSocial tipo,
  }) {
    final filtradas = reacoes.where((r) => r.tipo == tipo).toList();
    final titulo = tipo == TipoReacaoSocial.like
        ? 'Quem deu Like (${filtradas.length})'
        : 'Quem deu Deslike (${filtradas.length})';

    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.cardBackgroundColor,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 360,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.70,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
              if (filtradas.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Nenhuma reação registrada ainda.',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtradas.length,
                    itemBuilder: (_, i) {
                      final r = filtradas[i];
                      final nome = r.usuarioNome.isNotEmpty
                          ? r.usuarioNome
                          : r.usuarioCpf;
                      return ListTile(
                        leading: AvatarComStoryWidget(
                          theme: theme,
                          cpf: r.usuarioCpf,
                          nome: nome,
                          foto: r.usuarioFoto,
                          radius: 16,
                        ),
                        title: Text(
                          nome,
                          style: theme.getTextStyle(
                            fontSize: 13,
                            color: theme.textColor,
                          ),
                        ),
                        trailing: Icon(
                          tipo == TipoReacaoSocial.like
                              ? Icons.thumb_up_alt_rounded
                              : Icons.thumb_down_alt_rounded,
                          color: theme.secondaryTextColor,
                          size: 16,
                        ),
                        onTap: () async {
                          final cpfLimpo =
                              r.usuarioCpf.replaceAll(RegExp(r'\D'), '');
                          final conta = await ContasNousService.buscarPorCpf(
                            cpfLimpo,
                          );
                          if (!ctx.mounted) return;
                          Navigator.of(ctx).pop();
                          if (conta != null && context.mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PerfilSocialView(
                                  usuarioAlvo: conta,
                                  mostrarBotaoVoltar: true,
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Lista em formato de barra com todos os usuários que interagiram (Like, Deslike ou Republicação),
  /// permitindo visitar o perfil público de cada um ao tocar.
  static Future<void> mostrarTodasInteracoes(
    BuildContext context, {
    required AppTheme theme,
    required List<InteracaoUsuarioResumo> interacoes,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.cardBackgroundColor,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 380,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.72,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 8, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Interações (${interacoes.length})',
                        style: theme.getTextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.close_rounded,
                        color: theme.secondaryTextColor,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: theme.borderColor.withValues(alpha: 0.35),
              ),
              if (interacoes.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    'Nenhuma interação registrada ainda.',
                    style: theme.getTextStyle(
                      fontSize: 12.5,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: interacoes.length,
                    itemBuilder: (_, i) {
                      final item = interacoes[i];
                      final nome =
                          item.nome.isNotEmpty ? item.nome : item.cpf;
                      return ListTile(
                        leading: AvatarComStoryWidget(
                          theme: theme,
                          cpf: item.cpf,
                          nome: nome,
                          foto: item.foto,
                          radius: 17,
                        ),
                        title: Text(
                          nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 13.5,
                            color: theme.textColor,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item.deuLike)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.thumb_up_alt_rounded,
                                  size: 16,
                                  color: theme.buttonColor,
                                ),
                              ),
                            if (item.deuDeslike)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.thumb_down_alt_rounded,
                                  size: 16,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                            if (item.republicou)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.repeat_rounded,
                                  size: 16,
                                  color: theme.buttonColor,
                                ),
                              ),
                          ],
                        ),
                        onTap: () async {
                          final cpfLimpo =
                              item.cpf.replaceAll(RegExp(r'\D'), '');
                          final conta =
                              await ContasNousService.buscarPorCpf(cpfLimpo);
                          if (!ctx.mounted) return;
                          Navigator.of(ctx).pop();
                          if (conta != null && context.mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PerfilSocialView(
                                  usuarioAlvo: conta,
                                  mostrarBotaoVoltar: true,
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> mostrarListaCpfsReacao(
    BuildContext context, {
    required AppTheme theme,
    required List<String> cpfs,
    required bool ehLike,
  }) async {
    final todas = await ContasNousService.carregarTodas();
    final mapa = <String, UsuarioNous>{
      for (final u in todas) u.cpf.replaceAll(RegExp(r'\D'), ''): u,
    };
    if (!context.mounted) return;
    final titulo = ehLike
        ? 'Quem deu Like (${cpfs.length})'
        : 'Quem deu Deslike (${cpfs.length})';

    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.cardBackgroundColor,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 360,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.70,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
              if (cpfs.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Nenhuma reação registrada ainda.',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: cpfs.length,
                    itemBuilder: (_, i) {
                      final cpfLimpo = cpfs[i].replaceAll(RegExp(r'\D'), '');
                      final conta = mapa[cpfLimpo];
                      final nome = conta?.nomeExibicao ?? cpfLimpo;
                      return ListTile(
                        leading: AvatarComStoryWidget(
                          theme: theme,
                          cpf: cpfLimpo,
                          nome: nome,
                          foto: conta?.fotoExibicao ?? '',
                          radius: 16,
                        ),
                        title: Text(
                          nome,
                          style: theme.getTextStyle(
                            fontSize: 13,
                            color: theme.textColor,
                          ),
                        ),
                        onTap: conta == null
                            ? null
                            : () {
                                Navigator.of(ctx).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PerfilSocialView(
                                      usuarioAlvo: conta,
                                      mostrarBotaoVoltar: true,
                                    ),
                                  ),
                                );
                              },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
