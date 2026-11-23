import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_repositorio_sqlite.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
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
        barrierColor: Colors.black.withValues(alpha: 0.88),
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

  bool _fechando = false;
  bool _pausadoManual = false;

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

  String _formatarTempoStory(StorySocial s) {
    final diff = DateTime.now().difference(s.criadoEm);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    final l = s.criadoEm.toLocal();
    final d = l.day.toString().padLeft(2, '0');
    final m = l.month.toString().padLeft(2, '0');
    return '$d/$m/${l.year}';
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
    final cpfs = _storyAtual.visualizadoPorCpfs;
    final todasContas = await ContasNousService.carregarTodas();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.theme.cardBackgroundColor,
        title: Text(
          'Visualizações (${cpfs.length})',
          style: widget.theme.getTextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: widget.theme.textColor,
          ),
        ),
        content: SizedBox(
          width: 320,
          child: cpfs.isEmpty
              ? Text(
                  'Ninguém visualizou este story ainda.',
                  style: widget.theme.getTextStyle(
                    fontSize: 13,
                    color: widget.theme.secondaryTextColor,
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
                        color: widget.theme.buttonColor,
                      ),
                      title: Text(
                        nome,
                        style: widget.theme.getTextStyle(
                          fontSize: 13,
                          color: widget.theme.textColor,
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
    if (mounted) _timerCtrl.forward();
  }

  Future<void> _confirmarExclusao() async {
    _timerCtrl.stop();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.theme.cardBackgroundColor,
        title: Text(
          'Excluir Story',
          style: widget.theme.getTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: widget.theme.textColor,
          ),
        ),
        content: Text(
          'Deseja remover este story de todos os aparelhos?',
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
              'Excluir',
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
    } else if (mounted) {
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
      final meuCpfNorm = TimelineRepositorioSqlite.normalizarCpf(usuario.cpf);
      final todasContas = await ContasNousService.carregarTodas();
      final contatos = todasContas
          .where(
            (c) =>
                TimelineRepositorioSqlite.normalizarCpf(c.cpf) != meuCpfNorm &&
                c.cpf.trim().isNotEmpty,
          )
          .toList();
      if (!mounted) return;
      final destino = await showDialog<UsuarioNous>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: widget.theme.cardBackgroundColor,
          title: Text(
            'Enviar Story no Chat',
            style: widget.theme.getTextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: widget.theme.textColor,
            ),
          ),
          content: SizedBox(
            width: 320,
            height: 300,
            child: contatos.isEmpty
                ? Center(
                    child: Text(
                      'Nenhum contato encontrado na rede.',
                      style: widget.theme.getTextStyle(
                        fontSize: 13,
                        color: widget.theme.secondaryTextColor,
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
                          style: widget.theme.getTextStyle(
                            fontSize: 13,
                            color: widget.theme.textColor,
                          ),
                        ),
                        subtitle: c.nomeDeUsuario.isNotEmpty
                            ? Text(
                                '@${c.nomeDeUsuario}',
                                style: widget.theme.getTextStyle(
                                  fontSize: 11,
                                  color: widget.theme.secondaryTextColor,
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
                style: widget.theme.getTextStyle(
                  color: widget.theme.secondaryTextColor,
                ),
              ),
            ),
          ],
        ),
      );
      if (destino != null) {
        await TimelineService.encaminharStoryNoChat(
          story: story,
          meuCpf: usuario.cpf,
          meuNome: usuario.nomeExibicao,
          minhaFoto: usuario.fotoExibicao,
          destinatarioCpf: destino.cpf,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Story enviado para ${destino.nomeExibicao}!'),
            ),
          );
        }
      }
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

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final story = _storyAtual;
    final escalaArrasto =
        (1.0 - (_arrastoVerticalY / 600.0)).clamp(0.76, 1.0);
    final providerAutor = ImagemService.obterImageProvider(story.autorFoto);

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
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(
                      _arrastoVerticalY > 4 ? 24 : 0,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SafeArea(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 1. Mídia ou Fundo de Texto em Tela Cheia
                        if (story.caminhoMidia.isNotEmpty)
                          FutureBuilder<String?>(
                            future: TimelineService.resolverCaminhoMidia(
                              story.caminhoMidia,
                            ),
                              builder: (context, snap) {
                                final path = snap.data;
                                if (path == null) {
                                  if (snap.connectionState ==
                                      ConnectionState.done) {
                                    return const Center(
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        color: Colors.white54,
                                        size: 48,
                                      ),
                                    );
                                  }
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  );
                                }
                                if (story.tipoMidia == 'video') {
                                  return Center(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.buttonColor,
                                        foregroundColor: theme.buttonTextColor,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 14,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.play_circle_fill_rounded,
                                        size: 28,
                                      ),
                                      label: const Text('Reproduzir vídeo'),
                                      onPressed: () async {
                                        try {
                                          await launchUrl(
                                            Uri.file(path),
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                        } catch (_) {}
                                      },
                                    ),
                                  );
                                }
                                return Image.file(
                                  File(path),
                                  fit: BoxFit.contain,
                                  cacheWidth: 1080,
                                  errorBuilder: (_, _, _) => const Center(
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: Colors.white54,
                                      size: 48,
                                    ),
                                  ),
                                );
                              },
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            alignment: Alignment.center,
                            decoration: story.corFundoHex.isNotEmpty
                                ? BoxDecoration(
                                    color: Color(
                                      int.tryParse(
                                            story.corFundoHex,
                                            radix: 16,
                                          ) ??
                                          0xFF18181B,
                                    ),
                                  )
                                : BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        theme.buttonColor
                                            .withValues(alpha: 0.85),
                                        theme.cardBackgroundColor,
                                      ],
                                    ),
                                  ),
                            child: story.texto.isNotEmpty
                                ? Text(
                                    story.texto,
                                    textAlign: TextAlign.center,
                                    style: theme.getTextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),

                        // Camadas de texto personalizadas (arrastadas pelo editor)
                        if (story.camadasTexto.isNotEmpty)
                          LayoutBuilder(
                            builder: (ctx, box) => Stack(
                              children: [
                                for (final camada in story.camadasTexto)
                                  Positioned(
                                    left: (camada.x * box.maxWidth - 110)
                                        .clamp(8.0, box.maxWidth - 120),
                                    top: (camada.y * box.maxHeight - 24)
                                        .clamp(56.0, box.maxHeight - 120),
                                    child: CamadaTextoStoryWidget(
                                      camada: camada,
                                      onTapMencao: (handle) async {
                                        _timerCtrl.stop();
                                        try {
                                          await TextoComHashtagsWidget
                                              .abrirPerfilPorHandle(
                                            context,
                                            handle,
                                          );
                                        } finally {
                                          if (mounted &&
                                              !_pausadoManual &&
                                              !_fechando) {
                                            _timerCtrl.forward();
                                          }
                                        }
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),

                        // Legenda sobreposta quando há imagem + texto
                        if (story.caminhoMidia.isNotEmpty &&
                            story.texto.isNotEmpty)
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: (!widget.ehAutor &&
                                    widget.usuarioLogado != null)
                                ? 88
                                : 32,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 180),
                              opacity: _ocultarChrome ? 0.0 : 1.0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.60),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  story.texto,
                                  textAlign: TextAlign.center,
                                  style: theme.getTextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Setas laterais discretas para navegar entre Stories
                        if (_indiceAtual > 0)
                          Positioned(
                            left: 8,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 180),
                                opacity: _ocultarChrome ? 0.0 : 1.0,
                                child: InkWell(
                                  onTap: _voltarStory,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.42),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.chevron_left_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (_stories.length > 1)
                          Positioned(
                            right: 8,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 180),
                                opacity: _ocultarChrome ? 0.0 : 1.0,
                                child: InkWell(
                                  onTap: _avancarStory,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.42),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.chevron_right_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // 2. Topo: Barras de Progresso Segmentadas + Cabeçalho do Autor
                        Positioned(
                          top: 8,
                          left: 10,
                          right: 10,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 180),
                            opacity: _ocultarChrome ? 0.0 : 1.0,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Barras segmentadas
                                Row(
                                  children: List.generate(_stories.length, (i) {
                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 2,
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: AnimatedBuilder(
                                            animation: _timerCtrl,
                                            builder: (_, _) {
                                              final double prog;
                                              if (i < _indiceAtual) {
                                                prog = 1.0;
                                              } else if (i == _indiceAtual) {
                                                prog = _timerCtrl.value;
                                              } else {
                                                prog = 0.0;
                                              }
                                              return LinearProgressIndicator(
                                                value: prog,
                                                minHeight: 3,
                                                backgroundColor: Colors.white
                                                    .withValues(alpha: 0.30),
                                                valueColor:
                                                    const AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 10),
                                // Linha do Autor e Ações
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 17,
                                      backgroundColor: Colors.white24,
                                      backgroundImage: providerAutor,
                                      child: providerAutor == null
                                          ? const Icon(
                                              Icons.person,
                                              size: 18,
                                              color: Colors.white,
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
                                            story.tituloDestaque.isNotEmpty
                                                ? '${story.autorNome} • ${story.tituloDestaque}'
                                                : (story.autorNome.isNotEmpty
                                                      ? story.autorNome
                                                      : 'Story Nous'),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.getTextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          if (story.storyOriginalId.isNotEmpty)
                                            Text(
                                              'Repostado de ${story.autorOriginalNome.isNotEmpty ? story.autorOriginalNome : "outro perfil"}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.getTextStyle(
                                                fontSize: 10.5,
                                                color: Colors.white.withValues(
                                                  alpha: 0.78,
                                                ),
                                              ),
                                            ),
                                          Text(
                                            _formatarTempoStory(story),
                                            style: theme.getTextStyle(
                                              fontSize: 11,
                                              color: Colors.white.withValues(
                                                alpha: 0.78,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: _pausadoManual
                                          ? 'Retomar story'
                                          : 'Pausar story',
                                      icon: Icon(
                                        _pausadoManual
                                            ? Icons.play_arrow_rounded
                                            : Icons.pause_rounded,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        setState(
                                          () => _pausadoManual = !_pausadoManual,
                                        );
                                        if (_pausadoManual) {
                                          _timerCtrl.stop();
                                        } else {
                                          _timerCtrl.forward();
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                      ),
                                      onPressed: _fecharSeguro,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 3. Rodapé estilo Instagram: Visualizadores + Destacar / Arquivar / Excluir (para autor)
                        if (widget.ehAutor)
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 10,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 180),
                              opacity: _ocultarChrome ? 0.0 : 1.0,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: _mostrarVisualizadores,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.black.withValues(alpha: 0.55),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.22,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: FutureBuilder<List<UsuarioNous>>(
                                              future:
                                                  ContasNousService.carregarTodas(),
                                              builder: (context, snap) {
                                                final cpfs =
                                                    story.visualizadoPorCpfs;
                                                if (cpfs.isEmpty) {
                                                  return Row(
                                                    children: [
                                                      const Icon(
                                                        Icons
                                                            .visibility_outlined,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Flexible(
                                                        child: Text(
                                                          '0 visualizações',
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: theme
                                                              .getTextStyle(
                                                            fontSize: 12,
                                                            color: Colors.white
                                                                .withValues(
                                                              alpha: 0.85,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                }
                                                return Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.visibility_outlined,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      '${cpfs.length} visualizações',
                                                      style: theme.getTextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            tooltip: 'Enviar no chat',
                                            icon: const Icon(
                                              Icons.send_outlined,
                                              color: Colors.white,
                                              size: 19,
                                            ),
                                            onPressed: () =>
                                                _encaminharNoChat(story),
                                          ),
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            tooltip: story.ehDestaquePermanente
                                                ? 'Remover destaque'
                                                : 'Destacar',
                                            icon: Icon(
                                              story.ehDestaquePermanente
                                                  ? Icons.bookmark_rounded
                                                  : Icons
                                                      .bookmark_border_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            onPressed: _alternarDestaque,
                                          ),
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            tooltip: 'Arquivar story',
                                            icon: const Icon(
                                              Icons.archive_outlined,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            onPressed: _arquivarStory,
                                          ),
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            tooltip: 'Excluir story',
                                            icon: Icon(
                                              Icons.delete_outline,
                                              color: theme.dangerColor,
                                              size: 20,
                                            ),
                                            onPressed: _confirmarExclusao,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        if (!widget.ehAutor && widget.usuarioLogado != null)
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 10,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 180),
                              opacity: _ocultarChrome ? 0.0 : 1.0,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 42,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.55,
                                        ),
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.45,
                                          ),
                                        ),
                                      ),
                                      child: TextField(
                                        controller: _respostaCtrl,
                                        focusNode: _respostaFocus,
                                        style: theme.getTextStyle(
                                          fontSize: 13,
                                          color: Colors.white,
                                        ),
                                        onSubmitted: _enviarResposta,
                                        decoration: InputDecoration(
                                          hintText: 'Enviar mensagem...',
                                          hintStyle: theme.getTextStyle(
                                            fontSize: 12.5,
                                            color: Colors.white.withValues(
                                              alpha: 0.70,
                                            ),
                                          ),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  for (final emoji in const ['❤️', '🔥', '👏'])
                                    InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () => _enviarResposta(emoji),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 6,
                                        ),
                                        child: Text(
                                          emoji,
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ),
                                    ),
                                  IconButton(
                                    tooltip: 'Enviar resposta',
                                    icon: const Icon(
                                      Icons.send_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        _enviarResposta(_respostaCtrl.text),
                                  ),
                                  IconButton(
                                    tooltip: 'Enviar no chat',
                                    icon: const Icon(
                                      Icons.share_outlined,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () => _encaminharNoChat(story),
                                  ),
                                  IconButton(
                                    tooltip: 'Repostar no meu Story',
                                    icon: const Icon(
                                      Icons.repeat_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () => _repostarNoMeuStory(story),
                                  ),
                                ],
                              ),
                            ),
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
