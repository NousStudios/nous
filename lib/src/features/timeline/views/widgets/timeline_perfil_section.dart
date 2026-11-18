import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nous/src/core/services/preferencias_soberanas_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/models/salvos_denuncia_social.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_adicionar_feed.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_criar_publicacao.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_detalhes_publicacao.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_stories.dart';
import 'package:nous/src/features/timeline/views/widgets/card_publicacao_completo_widget.dart';

/// Seção modular da Rede Social no Perfil Público (Stories + Feeds Configuráveis).
class TimelinePerfilSection extends StatefulWidget {
  final AppTheme theme;
  final UsuarioNous contaPerfil;
  final UsuarioNous? usuarioLogado;
  final bool ehProprioUsuario;

  const TimelinePerfilSection({
    super.key,
    required this.theme,
    required this.contaPerfil,
    required this.usuarioLogado,
    required this.ehProprioUsuario,
  });

  @override
  State<TimelinePerfilSection> createState() => _TimelinePerfilSectionState();
}

class _TimelinePerfilSectionState extends State<TimelinePerfilSection> {
  TipoFeedSocial? _tipoSelecionado = TipoFeedSocial.fotos;
  FeedPersonalizado? _feedExtraSelecionado;

  List<TipoFeedSocial> _timelinesVisiveis =
      List<TipoFeedSocial>.from(TimelineService.timelinesPadrao);
  List<StorySocial> _stories = [];
  List<PublicacaoSocial> _publicacoes = [];
  List<RegistroInteracaoUsuario> _interacoes = [];
  List<DenunciaSocial> _denuncias = [];
  List<FeedPersonalizado> _feedsExtras = [];
  bool _modoGaleria3Colunas = false;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    TimelineService.alteracoesTimelineNotifier.addListener(_aoAtualizarRede);
    _carregarTudo();
  }

  @override
  void didUpdateWidget(covariant TimelinePerfilSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contaPerfil.cpf != widget.contaPerfil.cpf) {
      _carregarTudo();
    }
  }

  @override
  void dispose() {
    TimelineService.alteracoesTimelineNotifier.removeListener(_aoAtualizarRede);
    super.dispose();
  }

  void _aoAtualizarRede() {
    if (mounted) _carregarTudo();
  }

  Future<void> _carregarTudo() async {
    if (!mounted) return;
    setState(() => _carregando = true);

    final cpf = widget.contaPerfil.cpf;
    final visiveis = await TimelineService.obterTimelinesVisiveis(cpf);
    final stories = await TimelineService.listarStories(cpf);
    final extras = await TimelineService.listarFeedsPersonalizados(cpf);
    final modoSalvo = await PreferenciasSoberanasService.obterTexto(
      'timeline_modo_exibicao_${cpf}_fotos',
    );
    _modoGaleria3Colunas = modoSalvo == 'galeria3';

    if (_feedExtraSelecionado == null &&
        (_tipoSelecionado == null || !visiveis.contains(_tipoSelecionado))) {
      _tipoSelecionado = visiveis.isNotEmpty ? visiveis.first : null;
    }

    List<PublicacaoSocial> pubs = [];
    List<RegistroInteracaoUsuario> interacoes = [];
    List<DenunciaSocial> denuncias = [];

    if (_feedExtraSelecionado == null && _tipoSelecionado != null) {
      switch (_tipoSelecionado!) {
        case TipoFeedSocial.interacoes:
          interacoes = await TimelineService.listarInteracoesDoUsuario(cpf);
          break;
        case TipoFeedSocial.salvos:
          pubs = await TimelineService.listarPublicacoesSalvas(
            donoPerfilCpf: cpf,
            visualizadorCpf: widget.usuarioLogado?.cpf ?? '',
          );
          break;
        case TipoFeedSocial.likes:
          pubs = await TimelineService.listarPublicacoesPorReacao(
            cpf: cpf,
            tipo: TipoReacaoSocial.like,
          );
          break;
        case TipoFeedSocial.deslikes:
          pubs = await TimelineService.listarPublicacoesPorReacao(
            cpf: cpf,
            tipo: TipoReacaoSocial.deslike,
          );
          break;
        case TipoFeedSocial.denuncias:
          denuncias = await TimelineService.listarDenunciasDoUsuario(cpf);
          break;
        case TipoFeedSocial.fotos:
        case TipoFeedSocial.videos:
        case TipoFeedSocial.documentos:
        case TipoFeedSocial.musicas:
        case TipoFeedSocial.escritos:
        case TipoFeedSocial.republicacoes:
          pubs = await TimelineService.listarFeedDoUsuario(
            cpf: cpf,
            tipo: _tipoSelecionado!,
          );
          break;
      }
    }

    if (!mounted) return;
    setState(() {
      _timelinesVisiveis = visiveis;
      _stories = stories;
      _feedsExtras = extras;
      _publicacoes = pubs;
      _interacoes = interacoes;
      _denuncias = denuncias;
      _carregando = false;
    });
  }

  Future<void> _abrirOpcoesAbaTimeline(TipoFeedSocial tipo) async {
    if (!widget.ehProprioUsuario) return;
    final theme = widget.theme;

    final acao = await showDialog<String>(
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
                  _nomeTimeline(tipo),
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 10),
                Divider(color: theme.borderColor.withValues(alpha: 0.4)),
                if (tipo == TipoFeedSocial.fotos) ...[
                  ListTile(
                    leading: Icon(
                      _modoGaleria3Colunas
                          ? Icons.view_agenda_outlined
                          : Icons.grid_view_rounded,
                      color: theme.buttonColor,
                    ),
                    title: Text(
                      _modoGaleria3Colunas
                          ? 'Exibir em Feed Completo'
                          : 'Exibir em Galeria (3 por linha)',
                      style: theme.getTextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                    ),
                    subtitle: Text(
                      _modoGaleria3Colunas
                          ? 'Mostra cabeçalho, colaboradores, curtidas e comentários'
                          : 'Grade compacta estilo Instagram (3 fotos por linha)',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                    onTap: () => Navigator.of(ctx).pop('alternar_modo'),
                  ),
                  Divider(color: theme.borderColor.withValues(alpha: 0.25)),
                ],
                ListTile(
                  leading: Icon(
                    Icons.visibility_off_outlined,
                    color: theme.dangerColor,
                  ),
                  title: Text(
                    'Ocultar timeline do perfil',
                    style: theme.getTextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: theme.dangerColor,
                    ),
                  ),
                  onTap: () => Navigator.of(ctx).pop('ocultar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!mounted || acao == null) return;

    if (acao == 'alternar_modo') {
      final novoModoGaleria = !_modoGaleria3Colunas;
      await PreferenciasSoberanasService.salvarTexto(
        'timeline_modo_exibicao_${widget.contaPerfil.cpf}_fotos',
        novoModoGaleria ? 'galeria3' : 'feed',
      );
      if (mounted) {
        setState(() => _modoGaleria3Colunas = novoModoGaleria);
      }
      return;
    }

    if (acao == 'ocultar') {
      await _confirmarOcultarTimeline(tipo);
    }
  }

  Future<void> _confirmarOcultarTimeline(TipoFeedSocial tipo) async {
    if (!widget.ehProprioUsuario) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.theme.cardBackgroundColor,
        title: Text(
          'Ocultar timeline',
          style: widget.theme.getTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: widget.theme.textColor,
          ),
        ),
        content: Text(
          'Deseja ocultar "${_nomeTimeline(tipo)}" do seu perfil público? Você pode adicioná-la novamente no "+".',
          style: widget.theme.getTextStyle(
            fontSize: 13,
            color: widget.theme.secondaryTextColor,
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
              'Ocultar',
              style: widget.theme.getTextStyle(
                color: widget.theme.dangerColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      final nova = List<TipoFeedSocial>.from(_timelinesVisiveis)..remove(tipo);
      await TimelineService.salvarTimelinesVisiveis(
        widget.contaPerfil.cpf,
        nova,
      );
      await _carregarTudo();
    }
  }

  Future<void> _abrirCriarPublicacao() async {
    final pub = await DialogCriarPublicacao.mostrar(
      context,
      theme: widget.theme,
      autor: widget.contaPerfil,
      tipoInicial: _tipoSelecionado ?? TipoFeedSocial.fotos,
    );
    if (pub != null && mounted) {
      setState(() {
        _feedExtraSelecionado = null;
        _tipoSelecionado = pub.tipo;
      });
      await _carregarTudo();
    }
  }

  IconData _iconeTimeline(TipoFeedSocial tipo) {
    switch (tipo) {
      case TipoFeedSocial.fotos:
        return Icons.grid_on_sharp;
      case TipoFeedSocial.videos:
        return Icons.play_circle_outline_rounded;
      case TipoFeedSocial.documentos:
        return Icons.description_outlined;
      case TipoFeedSocial.musicas:
        return Icons.music_note_outlined;
      case TipoFeedSocial.escritos:
        return Icons.article_outlined;
      case TipoFeedSocial.republicacoes:
        return Icons.repeat_rounded;
      case TipoFeedSocial.interacoes:
        return Icons.history_toggle_off_rounded;
      case TipoFeedSocial.salvos:
        return Icons.bookmark_border_rounded;
      case TipoFeedSocial.likes:
        return Icons.thumb_up_off_alt_rounded;
      case TipoFeedSocial.deslikes:
        return Icons.thumb_down_off_alt_rounded;
      case TipoFeedSocial.denuncias:
        return Icons.shield_outlined;
    }
  }

  String _nomeTimeline(TipoFeedSocial tipo) {
    switch (tipo) {
      case TipoFeedSocial.fotos:
        return 'Fotos';
      case TipoFeedSocial.videos:
        return 'Vídeos';
      case TipoFeedSocial.documentos:
        return 'Documentos';
      case TipoFeedSocial.musicas:
        return 'Músicas';
      case TipoFeedSocial.escritos:
        return 'Escritos';
      case TipoFeedSocial.republicacoes:
        return 'Republicações';
      case TipoFeedSocial.interacoes:
        return 'Interações';
      case TipoFeedSocial.salvos:
        return 'Conteúdos Salvos';
      case TipoFeedSocial.likes:
        return 'Likes';
      case TipoFeedSocial.deslikes:
        return 'Deslikes';
      case TipoFeedSocial.denuncias:
        return 'Denúncias';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Stories (apenas + Story se vazio no próprio perfil)
        if (_stories.isNotEmpty || widget.ehProprioUsuario)
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _stories.length + (widget.ehProprioUsuario ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                if (widget.ehProprioUsuario && index == 0) {
                  return GestureDetector(
                    onTap: () => DialogCriarStory.mostrar(
                      context,
                      theme: theme,
                      autor: widget.contaPerfil,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.cardBackgroundColor,
                            border: Border.all(
                              color: theme.borderColor.withValues(alpha: 0.7),
                              width: 1.4,
                            ),
                          ),
                          child: Icon(Icons.add, size: 22, color: theme.textColor),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '+ Story',
                          style: theme.getTextStyle(
                            fontSize: 10,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final idxStory = widget.ehProprioUsuario ? index - 1 : index;
                final story = _stories[idxStory];
                return GestureDetector(
                  onTap: () => DialogVisualizarStory.mostrar(
                    context,
                    theme: theme,
                    story: story,
                    stories: _stories,
                    indiceInicial: idxStory,
                    ehAutor: widget.ehProprioUsuario,
                    usuarioLogado: widget.usuarioLogado,
                  ),
                  child: SizedBox(
                    width: 62,
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.cardBackgroundColor,
                            border: Border.all(
                              color: theme.buttonColor,
                              width: 2,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: story.caminhoMidia.isNotEmpty
                              ? FutureBuilder<String?>(
                                  future: TimelineService.resolverCaminhoMidia(
                                    story.caminhoMidia,
                                  ),
                                  builder: (_, snap) {
                                    if (snap.data == null) {
                                      return Icon(
                                        Icons.auto_awesome,
                                        size: 20,
                                        color: theme.textColor,
                                      );
                                    }
                                    return Image.file(
                                      File(snap.data!),
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                              : Icon(
                                  Icons.text_fields_rounded,
                                  size: 20,
                                  color: theme.textColor,
                                ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          story.tituloDestaque.isNotEmpty
                              ? story.tituloDestaque
                              : 'Story',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 10,
                            color: theme.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

        const SizedBox(height: 10),
        Divider(
          height: 1,
          thickness: 1,
          color: theme.borderColor.withValues(alpha: 0.4),
        ),

        // 2. Barra Rolante Horizontal Centralizada (apenas ícones) + '+' só no próprio perfil
        SizedBox(
          height: 48,
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final tipo in _timelinesVisiveis)
                    _buildAbaIcone(
                      theme: theme,
                      icone: _iconeTimeline(tipo),
                      tooltip: _nomeTimeline(tipo),
                      selecionada: _feedExtraSelecionado == null &&
                          _tipoSelecionado == tipo,
                      onTap: () {
                        setState(() {
                          _feedExtraSelecionado = null;
                          _tipoSelecionado = tipo;
                        });
                        _carregarTudo();
                      },
                      onLongPress: widget.ehProprioUsuario
                          ? () => _abrirOpcoesAbaTimeline(tipo)
                          : null,
                    ),
                  for (final extra in _feedsExtras)
                    _buildAbaIcone(
                      theme: theme,
                      icone: Icons.rss_feed_rounded,
                      tooltip: extra.titulo,
                      selecionada: _feedExtraSelecionado?.id == extra.id,
                      onTap: () {
                        setState(() => _feedExtraSelecionado = extra);
                        _carregarTudo();
                      },
                    ),
                  if (widget.ehProprioUsuario)
                    Tooltip(
                      message: 'Criar timeline ou importar de outras redes',
                      child: InkWell(
                        onTap: () async {
                          final ok = await DialogAdicionarFeed.mostrar(
                            context,
                            theme: theme,
                            donoCpf: widget.contaPerfil.cpf,
                          );
                          if (ok == true) await _carregarTudo();
                        },
                        child: SizedBox(
                          width: 56,
                          height: 44,
                          child: Center(
                            child: Icon(
                              Icons.add,
                              size: 20,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        if (widget.ehProprioUsuario) ...[
          const SizedBox(height: 10),
          Center(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.textColor,
                side: BorderSide(color: theme.borderColor),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              ),
              onPressed: _abrirCriarPublicacao,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
              label: const Text('Nova Publicação'),
            ),
          ),
        ],

        const SizedBox(height: 10),

        if (_carregando)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          _buildConteudoFeed(theme),
      ],
    );
  }

  Widget _buildAbaIcone({
    required AppTheme theme,
    required IconData icone,
    required String tooltip,
    required bool selecionada,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          width: 68,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selecionada ? theme.textColor : Colors.transparent,
                width: 2.0,
              ),
            ),
          ),
          child: Center(
            child: Icon(
              icone,
              size: 20,
              color: selecionada ? theme.textColor : theme.secondaryTextColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConteudoFeed(AppTheme theme) {
    if (_feedExtraSelecionado != null) {
      final extra = _feedExtraSelecionado!;
      return EstadoVazioContainer(
        theme: theme,
        mensagem:
            'Feed conectado: ${extra.titulo}\nOrigem: ${extra.origem.name} (${extra.urlOuIdentificador.isNotEmpty ? extra.urlOuIdentificador : "local"})',
      );
    }

    if (_tipoSelecionado == TipoFeedSocial.interacoes) {
      if (_interacoes.isEmpty) {
        return EstadoVazioContainer(
          theme: theme,
          mensagem: 'Nenhuma interação pública registrada na rede ainda.',
        );
      }
      return Column(
        children: _interacoes.map((item) {
          return Card(
            color: theme.cardBackgroundColor,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                item.tipoAcao == 'like'
                    ? Icons.thumb_up_alt_rounded
                    : item.tipoAcao == 'deslike'
                        ? Icons.thumb_down_alt_rounded
                        : item.tipoAcao == 'comentario'
                            ? Icons.chat_bubble_outline_rounded
                            : Icons.repeat_rounded,
                color: theme.buttonColor,
                size: 18,
              ),
              title: Text(
                item.resumo,
                style: theme.getTextStyle(fontSize: 12.5, color: theme.textColor),
              ),
            ),
          );
        }).toList(),
      );
    }

    if (_tipoSelecionado == TipoFeedSocial.denuncias) {
      if (_denuncias.isEmpty) {
        return EstadoVazioContainer(
          theme: theme,
          mensagem: 'Nenhuma denúncia registrada.',
        );
      }
      return Column(
        children: _denuncias.map((d) {
          final euDenunciei =
              d.denuncianteCpf == widget.contaPerfil.cpf.replaceAll(RegExp(r'\D'), '');
          return Card(
            color: theme.cardBackgroundColor,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(Icons.shield_outlined, color: theme.dangerColor),
              title: Text(
                euDenunciei
                    ? 'Denúncia feita contra ${d.alvoNome}'
                    : 'Denúncia recebida de ${d.denuncianteNome}',
                style: theme.getTextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              subtitle: Text(
                d.motivo,
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
              ),
            ),
          );
        }).toList(),
      );
    }

    if (_publicacoes.isEmpty) {
      return EstadoVazioContainer(
        theme: theme,
        mensagem: 'Nenhuma publicação neste feed ainda.',
      );
    }

    if (_tipoSelecionado == TipoFeedSocial.fotos) {
      if (_modoGaleria3Colunas) {
        return _buildGaleria3Colunas(theme);
      }
      return Column(
        children: _publicacoes
            .map(
              (pub) => CardPublicacaoCompletoWidget(
                theme: theme,
                publicacao: pub,
                usuarioLogado: widget.usuarioLogado,
              ),
            )
            .toList(),
      );
    }

    return Column(
      children: _publicacoes.map((pub) {
        return Card(
          color: theme.cardBackgroundColor,
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            onTap: () => DialogDetalhesPublicacao.mostrar(
              context,
              theme: theme,
              publicacao: pub,
              usuarioLogado: widget.usuarioLogado,
            ),
            leading: Icon(_iconeTimeline(pub.tipo), color: theme.buttonColor),
            title: Text(
              pub.texto.isNotEmpty
                  ? pub.texto
                  : (pub.midias.isNotEmpty
                      ? pub.midias.first.nomeArquivo
                      : 'Publicação'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.getTextStyle(fontSize: 13, color: theme.textColor),
            ),
            trailing: Icon(
              Icons.open_in_new_rounded,
              size: 16,
              color: theme.secondaryTextColor,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGaleria3Colunas(AppTheme theme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _publicacoes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (_, index) {
        final pub = _publicacoes[index];
        return GestureDetector(
          onTap: () => DialogDetalhesPublicacao.mostrar(
            context,
            theme: theme,
            publicacao: pub,
            usuarioLogado: widget.usuarioLogado,
          ),
          child: Container(
            color: theme.cardBackgroundColor.withValues(alpha: 0.6),
            child: pub.midias.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        pub.texto,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.getTextStyle(
                          fontSize: 10.5,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      _renderImg(
                        pub.midias.first,
                        BoxFit.cover,
                        null,
                        Alignment(pub.alinhamentoX, pub.alinhamentoY),
                      ),
                      if (pub.midias.length > 1)
                        const Positioned(
                          top: 6,
                          right: 6,
                          child: Icon(
                            Icons.collections_outlined,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _renderImg(
    MidiaPublicacao m,
    BoxFit fit,
    double? aspectRatio,
    Alignment alignment,
  ) {
    final alignFinal = (m.alinhamentoX != 0.0 || m.alinhamentoY != 0.0)
        ? Alignment(m.alinhamentoX, m.alinhamentoY)
        : alignment;

    Widget buildArquivo(String path) {
      final img = ClipRect(
        child: Transform.scale(
          scale: m.escalaZoom.clamp(1.0, 3.5),
          alignment: alignFinal,
          child: Image.file(
            File(path),
            fit: fit,
            alignment: alignFinal,
            cacheWidth: _modoGaleria3Colunas ? 420 : 900,
          ),
        ),
      );
      if (aspectRatio != null) {
        return AspectRatio(aspectRatio: aspectRatio, child: img);
      }
      return img;
    }

    final syncPath = TimelineService.resolverCaminhoMidiaSync(m.caminhoRelativo);
    if (syncPath != null) {
      return buildArquivo(syncPath);
    }

    return FutureBuilder<String?>(
      future: TimelineService.resolverCaminhoMidia(m.caminhoRelativo),
      builder: (_, snap) {
        final path = snap.data;
        if (path == null) return const SizedBox(height: 120);
        return buildArquivo(path);
      },
    );
  }
}
