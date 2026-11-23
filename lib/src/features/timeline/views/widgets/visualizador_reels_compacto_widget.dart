import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/player_video_nous_widget.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_opcoes_publicacao.dart';
import 'package:nous/src/features/timeline/views/widgets/avatar_com_story_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/cabecalho_autor_colaboradores_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/texto_com_hashtags_widget.dart';

/// Visualizador em tela cheia (estilo Reels) para o modo compacto/mobile,
/// suportando rolagem vertical entre publicações (vídeos e fotos),
/// barra lateral direita de ações e aba inferior expansível de comentários.
class VisualizadorReelsCompactoWidget extends StatefulWidget {
  final AppTheme theme;
  final List<PublicacaoSocial> publicacoes;
  final int indiceAtivo;
  final PublicacaoSocial pubAtiva;
  final UsuarioNous? usuarioLogado;
  final List<ReacaoSocial> reacoes;
  final List<PublicacaoSocial> republicacoes;
  final List<ComentarioSocial> comentarios;
  final List<UsuarioNous> coautoresResolvidos;
  final TipoReacaoSocial? minhaReacao;
  final int likes;
  final int deslikes;
  final bool baixando;
  final ValueChanged<int> onTrocarPublicacao;
  final Future<void> Function(TipoReacaoSocial tipo) onReagir;
  final VoidCallback onRepublicar;
  final VoidCallback onSalvar;
  final VoidCallback onEnviarChat;
  final VoidCallback onMaisOpcoes;
  final VoidCallback onDownload;
  final VoidCallback onAbrirMapaComentarios;
  final Widget Function(
    AppTheme theme,
    PublicacaoSocial pub,
    bool ehAtiva,
  ) buildMidia;
  final Widget Function(AppTheme theme, PublicacaoSocial pub)
      buildConteudoComentarios;
  final Widget Function(AppTheme theme) buildInputComentario;

  const VisualizadorReelsCompactoWidget({
    super.key,
    required this.theme,
    required this.publicacoes,
    required this.indiceAtivo,
    required this.pubAtiva,
    this.usuarioLogado,
    required this.reacoes,
    this.republicacoes = const [],
    required this.comentarios,
    required this.coautoresResolvidos,
    required this.minhaReacao,
    required this.likes,
    required this.deslikes,
    required this.baixando,
    required this.onTrocarPublicacao,
    required this.onReagir,
    required this.onRepublicar,
    required this.onSalvar,
    required this.onEnviarChat,
    required this.onMaisOpcoes,
    required this.onDownload,
    required this.onAbrirMapaComentarios,
    required this.buildMidia,
    required this.buildConteudoComentarios,
    required this.buildInputComentario,
  });

  @override
  State<VisualizadorReelsCompactoWidget> createState() =>
      _VisualizadorReelsCompactoWidgetState();
}

class _VisualizadorReelsCompactoWidgetState
    extends State<VisualizadorReelsCompactoWidget> {
  late PageController _pageController;
  bool _comentariosAbertos = false;
  bool _descricaoAberta = false;
  bool _modoLimpo = false;
  double _arrastoPendente = 0.0;
  DateTime? _ultimoScrollRoda;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.indiceAtivo);
  }

  @override
  void didUpdateWidget(covariant VisualizadorReelsCompactoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.indiceAtivo != widget.indiceAtivo &&
        _pageController.hasClients &&
        _pageController.page?.round() != widget.indiceAtivo) {
      _pageController.jumpToPage(widget.indiceAtivo);
    }
    if (oldWidget.pubAtiva.id != widget.pubAtiva.id) {
      _descricaoAberta = false;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatarData(DateTime d) {
    final dia = d.day.toString().padLeft(2, '0');
    final mes = d.month.toString().padLeft(2, '0');
    final ano = d.year;
    final hora = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$ano • $hora:$min';
  }

  List<InteracaoUsuarioResumo> _construirResumoInteracoes() {
    final mapa = <String, InteracaoUsuarioResumo>{};
    for (final r in widget.reacoes) {
      final cpf = r.usuarioCpf.replaceAll(RegExp(r'\D'), '');
      if (cpf.isEmpty) continue;
      final atual = mapa[cpf];
      mapa[cpf] = InteracaoUsuarioResumo(
        cpf: cpf,
        nome: r.usuarioNome.isNotEmpty
            ? r.usuarioNome
            : (atual?.nome ?? cpf),
        foto: r.usuarioFoto.isNotEmpty
            ? r.usuarioFoto
            : (atual?.foto ?? ''),
        deuLike: (atual?.deuLike ?? false) || r.tipo == TipoReacaoSocial.like,
        deuDeslike:
            (atual?.deuDeslike ?? false) || r.tipo == TipoReacaoSocial.deslike,
        republicou: atual?.republicou ?? false,
      );
    }
    for (final rep in widget.republicacoes) {
      final cpf = rep.autorCpf.replaceAll(RegExp(r'\D'), '');
      if (cpf.isEmpty) continue;
      final atual = mapa[cpf];
      mapa[cpf] = InteracaoUsuarioResumo(
        cpf: cpf,
        nome: rep.autorNome.isNotEmpty
            ? rep.autorNome
            : (atual?.nome ?? cpf),
        foto: rep.autorFoto.isNotEmpty
            ? rep.autorFoto
            : (atual?.foto ?? ''),
        deuLike: atual?.deuLike ?? false,
        deuDeslike: atual?.deuDeslike ?? false,
        republicou: true,
      );
    }
    return mapa.values.toList();
  }

  Widget _buildMiniaturasSeguidos(
    AppTheme theme,
    List<InteracaoUsuarioResumo> todasInteracoes,
  ) {
    if (todasInteracoes.isEmpty) return const SizedBox.shrink();
    final seguindoSet = (widget.usuarioLogado?.seguindo ?? const <String>[])
        .map((c) => c.replaceAll(RegExp(r'\D'), ''))
        .where((c) => c.isNotEmpty)
        .toSet();
    final seguidos = todasInteracoes
        .where((i) => seguindoSet.contains(i.cpf))
        .take(3)
        .toList();
    if (seguidos.isEmpty) return const SizedBox.shrink();

    final largura = 22.0 + (seguidos.length - 1) * 14.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => DialogOpcoesPublicacao.mostrarTodasInteracoes(
        context,
        theme: theme,
        interacoes: todasInteracoes,
      ),
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: SizedBox(
          width: largura,
          height: 24,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (int i = 0; i < seguidos.length; i++)
                Positioned(
                  left: i * 14.0,
                  top: 0,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AvatarComStoryWidget(
                        theme: theme,
                        cpf: seguidos[i].cpf,
                        nome: seguidos[i].nome,
                        foto: seguidos[i].foto,
                        radius: 11,
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: theme.cardBackgroundColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            seguidos[i].deuLike
                                ? Icons.thumb_up_alt_rounded
                                : seguidos[i].republicou
                                    ? Icons.repeat_rounded
                                    : Icons.thumb_down_alt_rounded,
                            size: 8,
                            color: seguidos[i].deuDeslike &&
                                    !seguidos[i].deuLike &&
                                    !seguidos[i].republicou
                                ? theme.secondaryTextColor
                                : theme.textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botaoAcaoLateral({
    required IconData icone,
    required String? rotulo,
    required VoidCallback? onTap,
    bool ativo = false,
  }) {
    final theme = widget.theme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icone,
              size: 20,
              color: theme.textColor,
            ),
            if (rotulo != null) ...[
              const SizedBox(height: 2),
              Text(
                rotulo,
                style: theme.getTextStyle(
                  fontSize: 10.5,
                  fontWeight: ativo ? FontWeight.bold : FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final pub = widget.pubAtiva;
    final alturaTotal = MediaQuery.sizeOf(context).height;
    final topoPainelComentarios = alturaTotal * 0.30;
    final todasInteracoes = _construirResumoInteracoes();

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Mídia em tela cheia com rolagem vertical entre publicações
        Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent &&
                !_comentariosAbertos &&
                !_descricaoAberta &&
                widget.publicacoes.length > 1) {
              final agora = DateTime.now();
              if (_ultimoScrollRoda != null &&
                  agora.difference(_ultimoScrollRoda!).inMilliseconds < 280) {
                return;
              }
              if (event.scrollDelta.dy > 10 &&
                  widget.indiceAtivo < widget.publicacoes.length - 1) {
                _ultimoScrollRoda = agora;
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                );
              } else if (event.scrollDelta.dy < -10 &&
                  widget.indiceAtivo > 0) {
                _ultimoScrollRoda = agora;
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                );
              }
            }
          },
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            scrollBehavior: const MaterialScrollBehavior().copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            ),
            itemCount: widget.publicacoes.length,
            onPageChanged: (novoIndex) {
              PlayerVideoNousWidget.pausarTodos();
              setState(() {
                _comentariosAbertos = false;
                _descricaoAberta = false;
              });
              widget.onTrocarPublicacao(novoIndex);
            },
            itemBuilder: (ctx, index) {
              final item = widget.publicacoes[index];
              final ehAtiva = index == widget.indiceAtivo;
              return Container(
                color: theme.backgroundColor,
                padding: _modoLimpo
                    ? EdgeInsets.zero
                    : const EdgeInsets.only(top: 52, bottom: 168),
                child: Center(
                  child: widget.buildMidia(theme, item, ehAtiva),
                ),
              );
            },
          ),
        ),

        // 2. Gradiente sutil inferior para legibilidade de legenda e botões
        if (!_modoLimpo)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 200,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      theme.backgroundColor.withValues(alpha: 0.88),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // 3. Barra superior flutuante (voltar, contador de sequência e menu)
        if (!_modoLimpo)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.backgroundColor.withValues(alpha: 0.80),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: theme.textColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    pub.tipo == TipoFeedSocial.videos ? 'Vídeos' : 'Fotos',
                    style: theme.getTextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                  if (widget.publicacoes.length > 1) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.cardBackgroundColor.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.borderColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        '${widget.indiceAtivo + 1}/${widget.publicacoes.length}',
                        style: theme.getTextStyle(
                          fontSize: 11,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    tooltip: 'Mais opções da publicação',
                    icon: Icon(Icons.more_horiz_rounded, color: theme.textColor),
                    onPressed: widget.onMaisOpcoes,
                  ),
                ],
              ),
            ),
          ),

        // 4. Autor, prévia de 2 linhas da descrição (toque abre aba completa), visualizações e data
        if (!_modoLimpo)
          Positioned(
            left: 14,
            right: 64,
            bottom: 58,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CabecalhoAutorColaboradoresWidget(
                  theme: theme,
                  publicacao: pub,
                  coautoresResolvidos: widget.coautoresResolvidos,
                ),
                if (pub.texto.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _descricaoAberta = true),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          pub.texto,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 13,
                            color: theme.textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ver descrição completa',
                          style: theme.getTextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildMiniaturasSeguidos(theme, todasInteracoes),
                    Expanded(
                      child: Text(
                        pub.tipo == TipoFeedSocial.videos
                            ? '${pub.visualizacoes} visualizações • ${_formatarData(pub.criadaEm)}'
                            : _formatarData(pub.criadaEm),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.getTextStyle(
                          fontSize: 11,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // 5. Coluna direita de ações (sem bordas, compacta)
        if (!_modoLimpo)
          Positioned(
            right: 8,
            bottom: 58,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _botaoAcaoLateral(
                  icone: widget.minhaReacao == TipoReacaoSocial.like
                      ? Icons.thumb_up
                      : Icons.thumb_up_outlined,
                  rotulo: '${widget.likes}',
                  ativo: widget.minhaReacao == TipoReacaoSocial.like,
                  onTap: () => widget.onReagir(TipoReacaoSocial.like),
                ),
                _botaoAcaoLateral(
                  icone: widget.minhaReacao == TipoReacaoSocial.deslike
                      ? Icons.thumb_down
                      : Icons.thumb_down_outlined,
                  rotulo: '${widget.deslikes}',
                  ativo: widget.minhaReacao == TipoReacaoSocial.deslike,
                  onTap: () => widget.onReagir(TipoReacaoSocial.deslike),
                ),
                _botaoAcaoLateral(
                  icone: Icons.mode_comment_outlined,
                  rotulo: '${widget.comentarios.length}',
                  onTap: () => setState(() {
                    _descricaoAberta = false;
                    _comentariosAbertos = true;
                  }),
                ),
                _botaoAcaoLateral(
                  icone: Icons.repeat_rounded,
                  rotulo: null,
                  onTap: widget.onRepublicar,
                ),
                _botaoAcaoLateral(
                  icone: Icons.send_rounded,
                  rotulo: null,
                  onTap: widget.onEnviarChat,
                ),
                _botaoAcaoLateral(
                  icone: Icons.bookmark_border_rounded,
                  rotulo: null,
                  onTap: widget.onSalvar,
                ),
                _botaoAcaoLateral(
                  icone: Icons.fullscreen_rounded,
                  rotulo: null,
                  onTap: () => setState(() {
                    _comentariosAbertos = false;
                    _descricaoAberta = false;
                    _modoLimpo = true;
                  }),
                ),
              ],
            ),
          ),

        // Botão discreto para sair do modo limpo
        if (_modoLimpo)
          Positioned(
            right: 12,
            bottom: 14,
            child: IconButton(
              tooltip: 'Mostrar interface',
              style: IconButton.styleFrom(
                backgroundColor:
                    theme.cardBackgroundColor.withValues(alpha: 0.65),
              ),
              icon: Icon(
                Icons.fullscreen_exit_rounded,
                size: 20,
                color: theme.textColor,
              ),
              onPressed: () => setState(() => _modoLimpo = false),
            ),
          ),

        // 6. Aba inferior "Comentários" (toque ou arrasto para cima abre o painel)
        if (!_modoLimpo && !_comentariosAbertos && !_descricaoAberta)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _comentariosAbertos = true),
              onVerticalDragStart: (_) => _arrastoPendente = 0.0,
              onVerticalDragUpdate: (d) {
                _arrastoPendente += d.delta.dy;
              },
              onVerticalDragEnd: (d) {
                if (_arrastoPendente < -20 ||
                    (d.primaryVelocity ?? 0) < -180) {
                  setState(() => _comentariosAbertos = true);
                }
              },
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: theme.cardBackgroundColor.withValues(alpha: 0.94),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: theme.borderColor.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 34,
                      height: 3.5,
                      margin: const EdgeInsets.only(bottom: 5),
                      decoration: BoxDecoration(
                        color: theme.secondaryTextColor.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.keyboard_arrow_up_rounded,
                          size: 16,
                          color: theme.secondaryTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Comentários (${widget.comentarios.length})',
                          style: theme.getTextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: theme.textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

        // 7. Fundo clicável quando painel de comentários ou descrição está aberto
        if (_comentariosAbertos || _descricaoAberta)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() {
                _comentariosAbertos = false;
                _descricaoAberta = false;
              }),
              child: Container(
                color: theme.backgroundColor.withValues(alpha: 0.45),
              ),
            ),
          ),

        // 8. Painel animado interno de Comentários (arrasta para baixo ou toca X para fechar)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          left: 0,
          right: 0,
          top: _comentariosAbertos ? topoPainelComentarios : alturaTotal,
          bottom: _comentariosAbertos ? 0 : -alturaTotal * 0.70,
          child: Material(
            color: theme.cardBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                border: Border(
                  top: BorderSide(
                    color: theme.borderColor.withValues(alpha: 0.55),
                  ),
                ),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragStart: (_) => _arrastoPendente = 0.0,
                    onVerticalDragUpdate: (d) {
                      _arrastoPendente += d.delta.dy;
                    },
                    onVerticalDragEnd: (d) {
                      if (_arrastoPendente > 24 ||
                          (d.primaryVelocity ?? 0) > 180) {
                        setState(() => _comentariosAbertos = false);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                      child: Column(
                        children: [
                          Container(
                            width: 36,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: theme.secondaryTextColor
                                  .withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: widget.onAbrirMapaComentarios,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.account_tree_outlined,
                                          size: 16,
                                          color: theme.textColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Mapa',
                                          style: theme.getTextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: theme.textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Center(
                                child: Text(
                                  'Comentários (${widget.comentarios.length})',
                                  style: theme.getTextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textColor,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color: theme.secondaryTextColor,
                                  ),
                                  onPressed: () => setState(
                                    () => _comentariosAbertos = false,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: theme.borderColor.withValues(alpha: 0.35),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(14),
                      child: widget.buildConteudoComentarios(theme, pub),
                    ),
                  ),
                  widget.buildInputComentario(theme),
                ],
              ),
            ),
          ),
        ),

        // 9. Painel animado interno de Descrição completa
        AnimatedPositioned(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          left: 0,
          right: 0,
          top: _descricaoAberta ? alturaTotal * 0.40 : alturaTotal,
          bottom: _descricaoAberta ? 0 : -alturaTotal * 0.60,
          child: Material(
            color: theme.cardBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                border: Border(
                  top: BorderSide(
                    color: theme.borderColor.withValues(alpha: 0.55),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragStart: (_) => _arrastoPendente = 0.0,
                    onVerticalDragUpdate: (d) {
                      _arrastoPendente += d.delta.dy;
                    },
                    onVerticalDragEnd: (d) {
                      if (_arrastoPendente > 24 ||
                          (d.primaryVelocity ?? 0) > 180) {
                        setState(() => _descricaoAberta = false);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                      child: Column(
                        children: [
                          Container(
                            width: 36,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: theme.secondaryTextColor
                                  .withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Center(
                                child: Text(
                                  'Descrição',
                                  style: theme.getTextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textColor,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color: theme.secondaryTextColor,
                                  ),
                                  onPressed: () => setState(
                                    () => _descricaoAberta = false,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: theme.borderColor.withValues(alpha: 0.35),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CabecalhoAutorColaboradoresWidget(
                            theme: theme,
                            publicacao: pub,
                            coautoresResolvidos: widget.coautoresResolvidos,
                          ),
                          const SizedBox(height: 12),
                          TextoComHashtagsWidget(
                            theme: theme,
                            texto: pub.texto,
                            fontSize: 14,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            pub.tipo == TipoFeedSocial.videos
                                ? '${pub.visualizacoes} visualizações • ${_formatarData(pub.criadaEm)}'
                                : _formatarData(pub.criadaEm),
                            style: theme.getTextStyle(
                              fontSize: 11.5,
                              color: theme.secondaryTextColor,
                            ),
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
      ],
    );
  }
}
