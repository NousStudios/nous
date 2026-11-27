import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_repositorio_sqlite.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/services/timeline_sync_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/widgets/stories/story_conteudo_midia_widget.dart';
import 'package:nous/src/features/timeline/views/dialogs/widgets/stories/story_modais_helper.dart';
import 'package:nous/src/features/timeline/views/dialogs/widgets/stories/story_topo_e_resposta_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/editor_story_view.dart';
import 'package:nous/src/features/timeline/views/widgets/texto_com_hashtags_widget.dart';

export 'dialog_criar_story.dart';

/// Visualizador de Stories estilo Instagram/WhatsApp com:
/// - Animação de expansão ao abrir e sucção ao fechar (ou arrastar para baixo);
/// - Barra de progresso segmentada de 5 segundos por story;
/// - Pausa ao segurar a tela, avanço/recuo nas bordas;
/// - Resposta rápida e reações enviadas direto para o Chat do autor.
class DialogVisualizarStory extends StatefulWidget {
  final AppTheme theme;
  final List<StorySocial> stories;
  final int indiceInicial;
  final bool ehAutor;
  final UsuarioNous? usuarioLogado;

  const DialogVisualizarStory({
    super.key,
    required this.theme,
    required this.stories,
    this.indiceInicial = 0,
    this.ehAutor = false,
    this.usuarioLogado,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required StorySocial story,
    List<StorySocial>? stories,
    int indiceInicial = 0,
    bool ehAutor = false,
    UsuarioNous? usuarioLogado,
  }) {
    final lista = (stories != null && stories.isNotEmpty) ? stories : [story];
    final idx = indiceInicial.clamp(0, lista.length - 1);

    return Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: true,
        barrierColor: theme.backgroundColor.withValues(alpha: 0.88),
        transitionDuration: const Duration(milliseconds: 340),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, _, _) => DialogVisualizarStory(
          theme: theme,
          stories: lista,
          indiceInicial: idx,
          ehAutor: ehAutor,
          usuarioLogado: usuarioLogado,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curva = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return AnimatedBuilder(
            animation: curva,
            builder: (context, _) {
              final v = curva.value.clamp(0.0, 1.0);
              final escala = 0.14 + (0.86 * v);
              final raioBorda = (1.0 - v) * 140.0;
              return Opacity(
                opacity: v,
                child: Transform.scale(
                  scale: escala,
                  alignment: Alignment.center,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(raioBorda),
                    child: child,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  State<DialogVisualizarStory> createState() => _DialogVisualizarStoryState();
}

class _DialogVisualizarStoryState extends State<DialogVisualizarStory>
    with SingleTickerProviderStateMixin {
  static const Duration _duracaoStory = Duration(seconds: 5);

  late final AnimationController _timerCtrl;
  final TextEditingController _respostaCtrl = TextEditingController();
  final FocusNode _respostaFocus = FocusNode();

  late List<StorySocial> _stories;
  late int _indiceAtual;
  bool _ocultarChrome = false;
  double _arrastoVerticalY = 0.0;
  bool _fechando = false;
  bool _pausadoManual = false;

  StorySocial get _storyAtual => _stories[_indiceAtual];

  @override
  void initState() {
    super.initState();
    _stories = List<StorySocial>.from(widget.stories);
    _indiceAtual = widget.indiceInicial.clamp(0, _stories.length - 1);

    _timerCtrl = AnimationController(vsync: this, duration: _duracaoStory)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _avancarStory();
        }
      });

    _respostaFocus.addListener(() {
      if (_respostaFocus.hasFocus) {
        _timerCtrl.stop();
      } else if (!_ocultarChrome && mounted) {
        _timerCtrl.forward();
      }
    });

    _iniciarStoryAtual();
  }

  @override
  void dispose() {
    _timerCtrl.dispose();
    _respostaCtrl.dispose();
    _respostaFocus.dispose();
    super.dispose();
  }

  void _iniciarStoryAtual() {
    _pausadoManual = false;
    _timerCtrl.stop();
    _timerCtrl.value = 0.0;
    _timerCtrl.forward();

    final viewerCpf = widget.usuarioLogado?.cpf ?? '';
    if (viewerCpf.isNotEmpty && !widget.ehAutor) {
      TimelineService.registrarVisualizacaoStory(_storyAtual, viewerCpf);
    }
  }

  void _fecharSeguro() {
    if (_fechando || !mounted) return;
    _fechando = true;
    _timerCtrl.stop();
    Navigator.of(context).pop();
  }

  void _avancarStory() {
    if (!mounted || _fechando) return;
    if (_indiceAtual < _stories.length - 1) {
      setState(() => _indiceAtual++);
      _iniciarStoryAtual();
    } else {
      _fecharSeguro();
    }
  }

  void _voltarStory() {
    if (!mounted) return;
    if (_indiceAtual > 0) {
      setState(() => _indiceAtual--);
      _iniciarStoryAtual();
    } else {
      _iniciarStoryAtual();
    }
  }

  Future<void> _enviarResposta(String texto) async {
    final u = widget.usuarioLogado;
    if (u == null || texto.trim().isEmpty) return;
    _respostaCtrl.clear();
    _respostaFocus.unfocus();
    await TimelineService.enviarRespostaStoryNoChat(
      story: _storyAtual,
      meuCpf: u.cpf,
      meuNome: u.nomeExibicao,
      minhaFoto: u.fotoExibicao,
      respostaTexto: texto,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resposta enviada para o chat!'),
          duration: Duration(seconds: 2),
        ),
      );
      _timerCtrl.forward();
    }
  }

  Future<void> _alternarDestaque() async {
    _timerCtrl.stop();
    final atualizado = await TimelineService.alternarDestaqueStory(_storyAtual);
    if (!mounted) return;
    setState(() {
      _stories[_indiceAtual] = atualizado;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          atualizado.ehDestaquePermanente
              ? 'Story fixado nos Destaques permanentes!'
              : 'Removido dos Destaques permanentes.',
        ),
      ),
    );
    _timerCtrl.forward();
  }

  Future<void> _mostrarVisualizadores() async {
    _timerCtrl.stop();
    await StoryModaisHelper.mostrarVisualizadores(
      context,
      theme: widget.theme,
      story: _storyAtual,
    );
    if (mounted) _timerCtrl.forward();
  }

  Future<void> _confirmarExclusao() async {
    _timerCtrl.stop();
    final confirmar = await StoryModaisHelper.confirmarExclusao(
      context,
      theme: widget.theme,
    );
    if (!mounted) return;

    if (confirmar) {
      await TimelineService.excluirStory(_storyAtual);
      if (!mounted) return;
      if (_stories.length <= 1) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          _stories.removeAt(_indiceAtual);
          if (_indiceAtual >= _stories.length) {
            _indiceAtual = _stories.length - 1;
          }
        });
        _iniciarStoryAtual();
      }
    } else {
      _timerCtrl.forward();
    }
  }

  Future<void> _arquivarStory() async {
    final arquivado = _storyAtual.copyWith(
      arquivado: !_storyAtual.arquivado,
      atualizadoEm: DateTime.now(),
    );
    await TimelineRepositorioSqlite.salvarStory(arquivado);
    TimelineService.notificarAlteracao();
    TimelineSyncService.despacharEventoRede('timeline_story', {
      'story': arquivado.toJson(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          arquivado.arquivado
              ? 'Story arquivado em Arquivos da Conta.'
              : 'Story restaurado dos arquivos.',
        ),
      ),
    );
    if (_stories.length <= 1) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _stories.removeAt(_indiceAtual);
        if (_indiceAtual >= _stories.length) {
          _indiceAtual = _stories.length - 1;
        }
      });
      _iniciarStoryAtual();
    }
  }

  Future<void> _encaminharNoChat(StorySocial story) async {
    final usuario = widget.usuarioLogado;
    if (usuario == null) return;
    _timerCtrl.stop();
    try {
      await StoryModaisHelper.encaminharNoChat(
        context,
        theme: widget.theme,
        story: story,
        usuarioLogado: usuario,
      );
    } finally {
      if (mounted) _timerCtrl.forward();
    }
  }

  Future<void> _repostarNoMeuStory(StorySocial story) async {
    final usuario = widget.usuarioLogado;
    if (usuario == null) return;
    _timerCtrl.stop();
    try {
      final repostado = await EditorStoryView.mostrar(
        context,
        theme: widget.theme,
        autor: usuario,
        caminhoArquivo: story.caminhoMidia,
        ehVideo: story.tipoMidia == 'video',
        storyRepostOriginal: story,
      );
      if (repostado != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Story repostado no seu perfil!')),
        );
      }
    } finally {
      if (mounted) _timerCtrl.forward();
    }
  }

  Future<void> _abrirMencao(String handle) async {
    _timerCtrl.stop();
    try {
      await TextoComHashtagsWidget.abrirPerfilPorHandle(context, handle);
    } finally {
      if (mounted && !_pausadoManual && !_fechando) {
        _timerCtrl.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final story = _storyAtual;
    final escalaArrasto = (1.0 - (_arrastoVerticalY / 600.0)).clamp(0.76, 1.0);
    final providerAutor = ImagemService.obterImageProvider(story.autorFoto);
    final temRodapeResposta = !widget.ehAutor && widget.usuarioLogado != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: (d) {
          if (d.delta.dy > 0 || _arrastoVerticalY > 0) {
            _timerCtrl.stop();
            setState(() {
              _arrastoVerticalY =
                  (_arrastoVerticalY + d.delta.dy).clamp(0.0, 260.0);
            });
          }
        },
        onVerticalDragEnd: (_) {
          if (_arrastoVerticalY > 85) {
            _fecharSeguro();
          } else {
            setState(() => _arrastoVerticalY = 0.0);
            if (!_pausadoManual) _timerCtrl.forward();
          }
        },
        onLongPressStart: (_) {
          _timerCtrl.stop();
          setState(() => _ocultarChrome = true);
        },
        onLongPressEnd: (_) {
          setState(() => _ocultarChrome = false);
          _timerCtrl.forward();
        },
        onTapUp: (details) {
          if (_respostaFocus.hasFocus) {
            _respostaFocus.unfocus();
            return;
          }
          final largura = MediaQuery.sizeOf(context).width;
          if (details.globalPosition.dx < largura * 0.32) {
            _voltarStory();
          } else {
            _avancarStory();
          }
        },
        child: Transform.translate(
          offset: Offset(0, _arrastoVerticalY),
          child: Transform.scale(
            scale: escalaArrasto,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.backgroundColor,
                    borderRadius: BorderRadius.circular(
                      _arrastoVerticalY > 4 ? 24 : 0,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SafeArea(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        StoryConteudoMidiaWidget(
                          theme: theme,
                          story: story,
                          ocultarChrome: _ocultarChrome,
                          temRodapeResposta: temRodapeResposta,
                          podeVoltar: _indiceAtual > 0,
                          podeAvancar: _stories.length > 1,
                          onVoltar: _voltarStory,
                          onAvancar: _avancarStory,
                          onTapMencao: _abrirMencao,
                        ),
                        StoryTopoWidget(
                          theme: theme,
                          story: story,
                          totalStories: _stories.length,
                          indiceAtual: _indiceAtual,
                          timerCtrl: _timerCtrl,
                          providerAutor: providerAutor,
                          ocultarChrome: _ocultarChrome,
                          pausadoManual: _pausadoManual,
                          onAlternarPausa: () {
                            setState(() => _pausadoManual = !_pausadoManual);
                            if (_pausadoManual) {
                              _timerCtrl.stop();
                            } else {
                              _timerCtrl.forward();
                            }
                          },
                          onFechar: _fecharSeguro,
                        ),
                        if (widget.ehAutor)
                          StoryRodapeAutorWidget(
                            theme: theme,
                            story: story,
                            ocultarChrome: _ocultarChrome,
                            onMostrarVisualizadores: _mostrarVisualizadores,
                            onEncaminhar: () => _encaminharNoChat(story),
                            onAlternarDestaque: _alternarDestaque,
                            onArquivar: _arquivarStory,
                            onExcluir: _confirmarExclusao,
                          ),
                        if (temRodapeResposta)
                          StoryRodapeRespostaWidget(
                            theme: theme,
                            respostaCtrl: _respostaCtrl,
                            respostaFocus: _respostaFocus,
                            ocultarChrome: _ocultarChrome,
                            onEnviarResposta: _enviarResposta,
                            onEncaminhar: () => _encaminharNoChat(story),
                            onRepostar: () => _repostarNoMeuStory(story),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
