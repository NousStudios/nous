import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/services/preferencias_soberanas_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/player_video_nous_widget.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
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
import 'package:nous/src/features/timeline/views/widgets/card_escrito_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/card_publicacao_completo_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/camera_criacao_view.dart';
import 'package:nous/src/features/timeline/views/widgets/lista_interacoes_perfil_widget.dart';

/// Seção modular da Rede Social no Perfil Público (Stories + Feeds Configuráveis).
class TimelinePerfilSection extends StatefulWidget {
  final AppTheme theme;
  final UsuarioNous contaPerfil;
  final UsuarioNous? usuarioLogado;
  final bool ehProprioUsuario;
  final ScrollController? scrollController;

  const TimelinePerfilSection({
    super.key,
    required this.theme,
    required this.contaPerfil,
    required this.usuarioLogado,
    required this.ehProprioUsuario,
    this.scrollController,
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
  final Map<TipoFeedSocial, bool> _modoGaleriaPorTimeline = {};
  bool _carregando = false;

  bool _suportaGaleria(TipoFeedSocial tipo) =>
      tipo != TipoFeedSocial.escritos &&
      tipo != TipoFeedSocial.interacoes &&
      tipo != TipoFeedSocial.denuncias;

  bool _estaEmGaleria(TipoFeedSocial tipo) {
    if (!_suportaGaleria(tipo)) return false;
    if (tipo == TipoFeedSocial.fotos) return _modoGaleria3Colunas;
    final salvo = _modoGaleriaPorTimeline[tipo];
    if (salvo != null) return salvo;
    return tipo == TipoFeedSocial.salvos ||
        tipo == TipoFeedSocial.likes ||
        tipo == TipoFeedSocial.deslikes;
  }

  static const int _tamanhoPagina = 18;
  bool _carregandoMais = false;
  bool _temMaisPublicacoes = true;

  @override
  void initState() {
    super.initState();
    TimelineService.alteracoesTimelineNotifier.addListener(_aoAtualizarRede);
    widget.scrollController?.addListener(_aoRolarPerfil);
    _carregarTudo();
  }

  @override
  void didUpdateWidget(covariant TimelinePerfilSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_aoRolarPerfil);
      widget.scrollController?.addListener(_aoRolarPerfil);
    }
    if (oldWidget.contaPerfil.cpf != widget.contaPerfil.cpf ||
        oldWidget.contaPerfil.modoFotosGaleria !=
            widget.contaPerfil.modoFotosGaleria ||
        !listEquals(
          oldWidget.contaPerfil.timelinesVisiveis,
          widget.contaPerfil.timelinesVisiveis,
        )) {
      _carregarTudo();
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_aoRolarPerfil);
    TimelineService.alteracoesTimelineNotifier.removeListener(_aoAtualizarRede);
    super.dispose();
  }

  void _aoRolarPerfil() {
    final ctrl = widget.scrollController;
    if (ctrl == null || !ctrl.hasClients) return;
    if (ctrl.position.pixels >= ctrl.position.maxScrollExtent - 320) {
      _carregarMaisPublicacoes();
    }
  }

  bool _ehFeedPaginavel(TipoFeedSocial? tipo) {
    return tipo == TipoFeedSocial.fotos ||
        tipo == TipoFeedSocial.videos ||
        tipo == TipoFeedSocial.documentos ||
        tipo == TipoFeedSocial.livros ||
        tipo == TipoFeedSocial.musicas ||
        tipo == TipoFeedSocial.escritos ||
        tipo == TipoFeedSocial.republicacoes;
  }

  Future<void> _carregarMaisPublicacoes() async {
    if (_carregando || _carregandoMais || !_temMaisPublicacoes) return;
    if (_feedExtraSelecionado != null || !_ehFeedPaginavel(_tipoSelecionado)) {
      return;
    }
    setState(() => _carregandoMais = true);
    try {
      final lote = await TimelineService.listarFeedDoUsuario(
        cpf: widget.contaPerfil.cpf,
        tipo: _tipoSelecionado!,
        limit: _tamanhoPagina,
        offset: _publicacoes.length,
      );
      if (!mounted) return;
      final existentes = _publicacoes.map((p) => p.id).toSet();
      final novas = lote.where((p) => !existentes.contains(p.id)).toList();
      setState(() {
        _publicacoes = [..._publicacoes, ...novas];
        _temMaisPublicacoes = lote.length >= _tamanhoPagina;
        _carregandoMais = false;
      });
    } catch (_) {
      if (mounted) setState(() => _carregandoMais = false);
    }
  }

  void _aoAtualizarRede() {
    if (mounted) _carregarTudo();
  }

  Future<void> _carregarTudo() async {
    if (!mounted) return;
    setState(() => _carregando = true);

    final cpf = widget.contaPerfil.cpf;
    List<TipoFeedSocial> visiveis;
    if (widget.contaPerfil.timelinesVisiveis.isNotEmpty) {
      visiveis = widget.contaPerfil.timelinesVisiveis
          .map(
            (n) => TipoFeedSocial.values.where((e) => e.name == n).firstOrNull,
          )
          .whereType<TipoFeedSocial>()
          .toList();
      if (visiveis.isEmpty) {
        visiveis = await TimelineService.obterTimelinesVisiveis(cpf);
      }
    } else {
      visiveis = await TimelineService.obterTimelinesVisiveis(cpf);
    }
    final stories = await TimelineService.listarStories(cpf);
    final destaques =
        stories.where((s) => s.ehDestaquePermanente && !s.arquivado).toList();
    final extras = await TimelineService.listarFeedsPersonalizados(cpf);
    _modoGaleria3Colunas = widget.contaPerfil.modoFotosGaleria;
    for (final t in TipoFeedSocial.values) {
      if (_suportaGaleria(t) && t != TipoFeedSocial.fotos) {
        final salvo = await PreferenciasSoberanasService.obterTexto(
          'timeline_modo_exibicao_${cpf}_${t.name}',
        );
        if (salvo == 'galeria3') {
          _modoGaleriaPorTimeline[t] = true;
        } else if (salvo == 'feed') {
          _modoGaleriaPorTimeline[t] = false;
        }
      }
    }

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
          denuncias = await TimelineService.listarDenunciasDoUsuario(cpf);
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
        case TipoFeedSocial.livros:
        case TipoFeedSocial.musicas:
        case TipoFeedSocial.escritos:
        case TipoFeedSocial.republicacoes:
          pubs = await TimelineService.listarFeedDoUsuario(
            cpf: cpf,
            tipo: _tipoSelecionado!,
            limit: _tamanhoPagina,
            offset: 0,
          );
          break;
      }
    }

    if (!mounted) return;
    setState(() {
      _timelinesVisiveis = visiveis;
      _stories = destaques;
      _feedsExtras = extras;
      _publicacoes = pubs;
      _interacoes = interacoes;
      _denuncias = denuncias;
      _temMaisPublicacoes =
          _ehFeedPaginavel(_tipoSelecionado) && pubs.length >= _tamanhoPagina;
      _carregandoMais = false;
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
                if (_suportaGaleria(tipo)) ...[
                  Builder(
                    builder: (_) {
                      final estaEmGaleria = _estaEmGaleria(tipo);
                      return ListTile(
                        leading: Icon(
                          estaEmGaleria
                              ? Icons.view_agenda_outlined
                              : Icons.grid_view_rounded,
                          color: theme.textColor,
                        ),
                        title: Text(
                          estaEmGaleria
                              ? 'Exibir em Feed Completo'
                              : 'Exibir em Galeria (3 por linha)',
                          style: theme.getTextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: theme.textColor,
                          ),
                        ),
                        subtitle: Text(
                          estaEmGaleria
                              ? 'Mostra cabeçalho, colaboradores, curtidas e comentários'
                              : 'Grade compacta (3 itens por linha)',
                          style: theme.getTextStyle(
                            fontSize: 11,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                        onTap: () => Navigator.of(ctx).pop('alternar_modo'),
                      );
                    },
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
      if (tipo == TipoFeedSocial.fotos) {
        final novoModoGaleria = !_modoGaleria3Colunas;
        await PreferenciasSoberanasService.salvarTexto(
          'timeline_modo_exibicao_${widget.contaPerfil.cpf}_fotos',
          novoModoGaleria ? 'galeria3' : 'feed',
        );
        if (mounted && widget.ehProprioUsuario) {
          try {
            await context.read<AuthProvider>().atualizarOrganizacaoTimelines(
                  modoFotosGaleria: novoModoGaleria,
                );
          } catch (_) {}
        }
        if (mounted) {
          setState(() => _modoGaleria3Colunas = novoModoGaleria);
        }
        return;
      }
      final novoModo = !_estaEmGaleria(tipo);
      final cpfLimpo = widget.contaPerfil.cpf.replaceAll(RegExp(r'\D'), '');
      await PreferenciasSoberanasService.salvarTexto(
        'timeline_modo_exibicao_${cpfLimpo}_${tipo.name}',
        novoModo ? 'galeria3' : 'feed',
      );
      if (mounted) {
        setState(() => _modoGaleriaPorTimeline[tipo] = novoModo);
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
      if (mounted && widget.ehProprioUsuario) {
        try {
          await context.read<AuthProvider>().atualizarOrganizacaoTimelines(
                timelinesVisiveis: nova.map((e) => e.name).toList(),
              );
        } catch (_) {}
      }
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
      case TipoFeedSocial.livros:
        return Icons.menu_book_outlined;
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
      case TipoFeedSocial.livros:
        return 'Livros';
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
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.ehProprioUsuario)
                  Padding(
                    padding: EdgeInsets.only(right: _stories.isNotEmpty ? 10 : 0),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (camCtx) => CameraCriacaoView(
                            theme: theme,
                            autor: widget.contaPerfil,
                            ativa: true,
                            onVoltarPerfil: () => Navigator.of(camCtx).pop(),
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
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
                            child: Icon(
                              Icons.add,
                              size: 22,
                              color: theme.textColor,
                            ),
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
                    ),
                  ),
                for (int idxStory = 0; idxStory < _stories.length; idxStory++)
                  Padding(
                    padding: EdgeInsets.only(
                      right: idxStory < _stories.length - 1 ? 10 : 0,
                    ),
                    child: GestureDetector(
                      onTap: () => DialogVisualizarStory.mostrar(
                        context,
                        theme: theme,
                        story: _stories[idxStory],
                        stories: _stories,
                        indiceInicial: idxStory,
                        ehAutor: widget.ehProprioUsuario,
                        usuarioLogado: widget.usuarioLogado,
                      ),
                      child: SizedBox(
                        width: 62,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.cardBackgroundColor,
                                border: Border.all(
                                  color: theme.borderColor,
                                  width: 2,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _stories[idxStory].caminhoMidia.isNotEmpty
                                  ? FutureBuilder<String?>(
                                      future:
                                          TimelineService.resolverCaminhoMidia(
                                        _stories[idxStory].caminhoMidia,
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
                              _stories[idxStory].tituloDestaque.isNotEmpty
                                  ? _stories[idxStory].tituloDestaque
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
                    ),
                  ),
              ],
            ),
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
                          final auth = context.read<AuthProvider>();
                          final ok = await DialogAdicionarFeed.mostrar(
                            context,
                            theme: theme,
                            donoCpf: widget.contaPerfil.cpf,
                          );
                          if (ok == true) {
                            final novasVisiveis =
                                await TimelineService.obterTimelinesVisiveis(
                              widget.contaPerfil.cpf,
                            );
                            try {
                              await auth.atualizarOrganizacaoTimelines(
                                timelinesVisiveis: novasVisiveis
                                    .map((e) => e.name)
                                    .toList(),
                              );
                            } catch (_) {}
                            await _carregarTudo();
                          }
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
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (details) {
              if (_timelinesVisiveis.length <= 1 || _tipoSelecionado == null) {
                return;
              }
              final vel = details.primaryVelocity ?? 0;
              if (vel.abs() < 220) return;
              final idxAtual = _timelinesVisiveis.indexOf(_tipoSelecionado!);
              if (idxAtual < 0) return;
              final novoIdx = vel < 0 ? idxAtual + 1 : idxAtual - 1;
              if (novoIdx < 0 || novoIdx >= _timelinesVisiveis.length) return;
              setState(() {
                _feedExtraSelecionado = null;
                _tipoSelecionado = _timelinesVisiveis[novoIdx];
              });
              _carregarTudo();
            },
            child: _buildConteudoFeed(theme),
          ),
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
      return ListaInteracoesPerfilWidget(
        theme: theme,
        interacoes: _interacoes,
        denuncias: _denuncias,
        cpfPerfil: widget.contaPerfil.cpf,
        nomePerfil: widget.contaPerfil.nomeExibicao,
        fotoPerfil: widget.contaPerfil.fotoExibicao,
        usuarioLogado: widget.usuarioLogado,
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

    if (_tipoSelecionado != null && _estaEmGaleria(_tipoSelecionado!)) {
      return _buildGaleria3Colunas(theme);
    }

    return Column(
      children: _publicacoes.asMap().entries.map((entry) {
        final pub = entry.value;
        final ehEscrito = pub.tipo == TipoFeedSocial.escritos ||
            (_tipoSelecionado == TipoFeedSocial.republicacoes &&
                pub.midias.isEmpty);
        if (ehEscrito) {
          return CardEscritoWidget(
            key: ValueKey('feed_escrito_${_tipoSelecionado?.name}_${pub.id}'),
            theme: theme,
            publicacao: pub,
            usuarioLogado: widget.usuarioLogado,
            listaPublicacoes: _publicacoes,
            indiceInicial: entry.key,
            abrirDetalhesAoTocarCabecalho: true,
          );
        }
        return CardPublicacaoCompletoWidget(
          key: ValueKey('feed_card_${_tipoSelecionado?.name}_${pub.id}'),
          theme: theme,
          publicacao: pub,
          usuarioLogado: widget.usuarioLogado,
          listaPublicacoes: _publicacoes,
          indiceInicial: entry.key,
          abrirDetalhesAoTocarCabecalho: true,
          subtituloRepublicadoPor:
              _tipoSelecionado == TipoFeedSocial.republicacoes
                  ? widget.contaPerfil.nomeExibicao
                  : null,
        );
      }).toList(),
    );
  }

  Widget _buildTileGaleria(AppTheme theme, PublicacaoSocial pub) {
    final primeiraMidia = pub.midias.isNotEmpty ? pub.midias.first : null;
    final ext = (primeiraMidia?.mimeTipo ?? '').toLowerCase();
    final ehVideo = pub.tipo == TipoFeedSocial.videos ||
        ext == 'mp4' ||
        ext == 'mov' ||
        ext == 'webm' ||
        ext == 'mkv' ||
        ext == 'avi';
    final ehImagem = primeiraMidia != null &&
        (ext == 'jpg' ||
            ext == 'jpeg' ||
            ext == 'png' ||
            ext == 'webp' ||
            ext == 'gif' ||
            (ext.isEmpty && pub.tipo == TipoFeedSocial.fotos));

    return Container(
      color: theme.cardBackgroundColor.withValues(alpha: 0.6),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (ehVideo) ...[
            if (pub.capaCaminho.isNotEmpty)
              _renderImg(
                MidiaPublicacao(caminhoRelativo: pub.capaCaminho),
                BoxFit.cover,
                null,
                Alignment.center,
              )
            else if (primeiraMidia != null)
              FutureBuilder<Uint8List?>(
                future: PlayerVideoNousWidget.obterOuGerarCapaVideo(
                  primeiraMidia.caminhoRelativo,
                ),
                builder: (_, snap) {
                  if (snap.data != null && snap.data!.isNotEmpty) {
                    return Image.memory(snap.data!, fit: BoxFit.cover);
                  }
                  return Container(
                    color: theme.backgroundColor.withValues(alpha: 0.55),
                    child: Center(
                      child: Icon(
                        Icons.videocam_outlined,
                        size: 28,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  );
                },
              )
            else
              Container(
                color: theme.backgroundColor.withValues(alpha: 0.55),
                child: Center(
                  child: Icon(
                    Icons.videocam_outlined,
                    size: 28,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ),
          ] else if (pub.midias.isEmpty)
            Center(
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
          else if (ehImagem)
            _renderImg(
              primeiraMidia,
              BoxFit.cover,
              null,
              Alignment(pub.alinhamentoX, pub.alinhamentoY),
            )
          else if (ext == 'pdf' ||
              primeiraMidia!.nomeArquivo.toLowerCase().endsWith('.pdf'))
            (pub.capaCaminho.isNotEmpty
                ? _renderImg(
                    MidiaPublicacao(caminhoRelativo: pub.capaCaminho),
                    BoxFit.cover,
                    null,
                    Alignment.topCenter,
                  )
                : FutureBuilder<Uint8List?>(
                    future: TimelineService.obterOuGerarMiniaturaPdf(
                      primeiraMidia!.caminhoRelativo,
                    ),
                    builder: (context, snap) {
                      final bytes = snap.data;
                      if (bytes != null && bytes.isNotEmpty) {
                        return Container(
                          color: const Color(0xFFF7F7F7),
                          child: Image.memory(
                            bytes,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            gaplessPlayback: true,
                          ),
                        );
                      }
                      return Container(
                        color: theme.backgroundColor.withValues(alpha: 0.45),
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.picture_as_pdf_outlined,
                              size: 26,
                              color: theme.textColor,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              primeiraMidia.nomeArquivo.isNotEmpty
                                  ? primeiraMidia.nomeArquivo
                                  : pub.texto,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: theme.getTextStyle(
                                fontSize: 10,
                                color: theme.textColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ))
          else
            Container(
              color: theme.backgroundColor.withValues(alpha: 0.45),
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    pub.tipo == TipoFeedSocial.musicas
                        ? Icons.music_note_rounded
                        : _iconeTimeline(pub.tipo),
                    size: 26,
                    color: theme.textColor,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    primeiraMidia.nomeArquivo.isNotEmpty
                        ? primeiraMidia.nomeArquivo
                        : pub.texto,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(
                      fontSize: 10,
                      color: theme.textColor,
                    ),
                  ),
                ],
              ),
            ),
          if (pub.fixada)
            const Positioned(
              top: 6,
              left: 6,
              child: Icon(
                Icons.push_pin_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          if (ehVideo)
            const Positioned(
              top: 6,
              right: 6,
              child: Icon(
                Icons.play_arrow_rounded,
                size: 20,
                color: Colors.white,
              ),
            )
          else if (pub.midias.length > 1)
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
        final tile = GestureDetector(
          onTap: () => DialogDetalhesPublicacao.mostrar(
            context,
            theme: theme,
            publicacao: pub,
            usuarioLogado: widget.usuarioLogado,
            listaPublicacoes: _publicacoes,
            indiceInicial: index,
          ),
          child: _buildTileGaleria(theme, pub),
        );

        if (!widget.ehProprioUsuario) {
          return KeyedSubtree(
            key: ValueKey('galeria_pub_${pub.id}'),
            child: tile,
          );
        }

        return DragTarget<int>(
          key: ValueKey('galeria_pub_${pub.id}'),
          onWillAcceptWithDetails: (details) => details.data != index,
          onAcceptWithDetails: (details) async {
            await TimelineService.reordenarPublicacaoNaLista(
              listaAtual: _publicacoes,
              indiceAtual: details.data,
              novoIndice: index,
            );
            await _carregarTudo();
          },
          builder: (ctx, candidateData, rejectedData) {
            final emAlvo = candidateData.isNotEmpty;
            return AnimatedScale(
              duration: const Duration(milliseconds: 160),
              scale: emAlvo ? 0.92 : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: emAlvo
                    ? BoxDecoration(
                        border: Border.all(
                          color: theme.buttonColor,
                          width: 2.5,
                        ),
                      )
                    : null,
                child: LongPressDraggable<int>(
                  data: index,
                  feedback: Material(
                    color: Colors.transparent,
                    elevation: 10,
                    child: SizedBox(
                      width: 112,
                      height: 112,
                      child: Transform.scale(
                        scale: 1.06,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildTileGaleria(theme, pub),
                        ),
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.30,
                    child: _buildTileGaleria(theme, pub),
                  ),
                  child: tile,
                ),
              ),
            );
          },
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
