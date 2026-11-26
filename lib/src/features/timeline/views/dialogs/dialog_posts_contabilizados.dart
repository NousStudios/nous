import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/services/timeline_repositorio_sqlite.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_detalhes_publicacao.dart';

/// Janela que lista exatamente as publicações contabilizadas no contador
/// "Posts" do cabeçalho do perfil público, permitindo abrir cada uma delas.
class DialogPostsContabilizados extends StatefulWidget {
  final AppTheme theme;
  final UsuarioNous contaPerfil;
  final UsuarioNous? usuarioLogado;

  const DialogPostsContabilizados({
    super.key,
    required this.theme,
    required this.contaPerfil,
    required this.usuarioLogado,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required UsuarioNous contaPerfil,
    required UsuarioNous? usuarioLogado,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => DialogPostsContabilizados(
        theme: theme,
        contaPerfil: contaPerfil,
        usuarioLogado: usuarioLogado,
      ),
    );
  }

  @override
  State<DialogPostsContabilizados> createState() =>
      _DialogPostsContabilizadosState();
}

class _DialogPostsContabilizadosState extends State<DialogPostsContabilizados> {
  List<PublicacaoSocial> _lista = const [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    TimelineService.alteracoesTimelineNotifier.addListener(_aoAtualizarTimeline);
    _carregar();
  }

  @override
  void dispose() {
    TimelineService.alteracoesTimelineNotifier.removeListener(_aoAtualizarTimeline);
    super.dispose();
  }

  void _aoAtualizarTimeline() {
    if (mounted) _carregar();
  }

  Future<void> _carregar() async {
    try {
      final res = await TimelineService.listarTodosPostsContabilizados(
        widget.contaPerfil.cpf,
      );
      if (!mounted) return;
      setState(() {
        _lista = res;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  String _rotuloTipo(TipoFeedSocial t) {
    switch (t) {
      case TipoFeedSocial.fotos:
        return 'Foto';
      case TipoFeedSocial.videos:
        return 'Vídeo';
      case TipoFeedSocial.documentos:
        return 'Documento';
      case TipoFeedSocial.livros:
        return 'Livro';
      case TipoFeedSocial.musicas:
        return 'Música';
      case TipoFeedSocial.escritos:
        return 'Escrito';
      default:
        return 'Post';
    }
  }

  IconData _iconeTipo(TipoFeedSocial t) {
    switch (t) {
      case TipoFeedSocial.fotos:
        return Icons.photo_outlined;
      case TipoFeedSocial.videos:
        return Icons.play_circle_outline_rounded;
      case TipoFeedSocial.documentos:
        return Icons.description_outlined;
      case TipoFeedSocial.livros:
        return Icons.menu_book_outlined;
      case TipoFeedSocial.musicas:
        return Icons.music_note_outlined;
      case TipoFeedSocial.escritos:
        return Icons.article_outlined;
      default:
        return Icons.feed_outlined;
    }
  }

  String _dataCurta(DateTime d) {
    final l = d.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/'
        '${l.month.toString().padLeft(2, '0')}/${l.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final cpfDono = TimelineRepositorioSqlite.normalizarCpf(
      widget.contaPerfil.cpf,
    );
    final alturaMax = MediaQuery.sizeOf(context).height * 0.82;

    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor),
      ),
      child: SizedBox(
        width: 460,
        height: _carregando || _lista.isEmpty ? null : alturaMax.clamp(240, 560),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Text(
                      'Posts de ${widget.contaPerfil.nomeExibicao} (${_lista.length})',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.getTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.textColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_carregando)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_lista.isEmpty)
                EstadoVazioContainer(
                  theme: theme,
                  mensagem: 'Nenhuma publicação contabilizada.',
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _lista.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: theme.borderColor.withValues(alpha: 0.25),
                    ),
                    itemBuilder: (_, i) {
                      final pub = _lista[i];
                      final ehColab = TimelineRepositorioSqlite.normalizarCpf(
                            pub.autorCpf,
                          ) !=
                          cpfDono;
                      final titulo = pub.texto.trim().isNotEmpty
                          ? pub.texto.trim()
                          : (pub.midias.isNotEmpty &&
                                  pub.midias.first.nomeArquivo.isNotEmpty
                              ? pub.midias.first.nomeArquivo
                              : _rotuloTipo(pub.tipo));
                      final caminhoCapa = pub.capaCaminho.isNotEmpty
                          ? TimelineService.resolverCaminhoMidiaSync(
                              pub.capaCaminho,
                            )
                          : (pub.tipo == TipoFeedSocial.fotos &&
                                  pub.midias.isNotEmpty
                              ? TimelineService.resolverCaminhoMidiaSync(
                                  pub.midias.first.caminhoRelativo,
                                )
                              : null);
                      final temMiniatura = caminhoCapa != null &&
                          File(caminhoCapa).existsSync();

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: theme.backgroundColor.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.borderColor.withValues(alpha: 0.35),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: temMiniatura
                              ? Image.file(
                                  File(caminhoCapa),
                                  fit: BoxFit.cover,
                                  cacheWidth: 160,
                                  errorBuilder: (_, _, _) => Icon(
                                    _iconeTipo(pub.tipo),
                                    size: 20,
                                    color: theme.textColor,
                                  ),
                                )
                              : Icon(
                                  _iconeTipo(pub.tipo),
                                  size: 20,
                                  color: theme.textColor,
                                ),
                        ),
                        title: Text(
                          titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.textColor,
                          ),
                        ),
                        subtitle: Text(
                          [
                            _rotuloTipo(pub.tipo),
                            if (ehColab) 'Colaboração',
                            _dataCurta(pub.criadaEm),
                          ].join(' • '),
                          style: theme.getTextStyle(
                            fontSize: 11,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: theme.secondaryTextColor,
                        ),
                        onTap: () => DialogDetalhesPublicacao.mostrar(
                          context,
                          theme: theme,
                          publicacao: pub,
                          usuarioLogado: widget.usuarioLogado,
                        ),
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
