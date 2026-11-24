import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/services/preferencias_soberanas_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/models/salvos_denuncia_social.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_adicionar_feed.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_criar_publicacao.dart';
import 'package:nous/src/features/timeline/views/widgets/perfil_section/timeline_feed_conteudo_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/perfil_section/timeline_galeria_grid_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/perfil_section/timeline_stories_bar_widget.dart';

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

  String _nomeTimeline(TipoFeedSocial tipo) => switch (tipo) {
        TipoFeedSocial.fotos => 'Fotos',
        TipoFeedSocial.videos => 'Vídeos',
        TipoFeedSocial.documentos => 'Documentos',
        TipoFeedSocial.livros => 'Livros',
        TipoFeedSocial.musicas => 'Músicas',
        TipoFeedSocial.escritos => 'Escritos',
        TipoFeedSocial.republicacoes => 'Republicações',
        TipoFeedSocial.interacoes => 'Interações',
        TipoFeedSocial.salvos => 'Conteúdos Salvos',
        TipoFeedSocial.likes => 'Likes',
        TipoFeedSocial.deslikes => 'Deslikes',
        TipoFeedSocial.denuncias => 'Denúncias',
      };

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Stories (apenas + Story se vazio no próprio perfil)
        if (_stories.isNotEmpty || widget.ehProprioUsuario)
          TimelineStoriesBarWidget(
            theme: theme,
            stories: _stories,
            contaPerfil: widget.contaPerfil,
            usuarioLogado: widget.usuarioLogado,
            ehProprioUsuario: widget.ehProprioUsuario,
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
                      icone: iconeTimelineSocial(tipo),
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
            child: TimelineFeedConteudoWidget(
              theme: theme,
              feedExtraSelecionado: _feedExtraSelecionado,
              tipoSelecionado: _tipoSelecionado,
              estaEmGaleria: _tipoSelecionado != null &&
                  _estaEmGaleria(_tipoSelecionado!),
              publicacoes: _publicacoes,
              interacoes: _interacoes,
              denuncias: _denuncias,
              contaPerfil: widget.contaPerfil,
              usuarioLogado: widget.usuarioLogado,
              ehProprioUsuario: widget.ehProprioUsuario,
              modoGaleria3Colunas: _modoGaleria3Colunas,
              onRecarregar: _carregarTudo,
            ),
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
}
