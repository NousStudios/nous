import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/player_video_nous_widget.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/views/widgets/cabecalho_autor_colaboradores_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/reels/reels_aba_comentarios_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/reels/reels_acoes_laterais_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/reels/reels_barra_superior_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/reels/reels_painel_deslizante_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/reels/reels_rodape_autor_widget.dart';
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

  void _tratarScrollRoda(PointerSignalEvent event) {
    if (event is! PointerScrollEvent ||
        _comentariosAbertos ||
        _descricaoAberta ||
        widget.publicacoes.length <= 1) {
      return;
    }
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
    } else if (event.scrollDelta.dy < -10 && widget.indiceAtivo > 0) {
      _ultimoScrollRoda = agora;
      _pageController.previousPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Widget _buildBotaoMapaComentarios(AppTheme theme) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: widget.onAbrirMapaComentarios,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final pub = widget.pubAtiva;
    final alturaTotal = MediaQuery.sizeOf(context).height;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Mídia em tela cheia com rolagem vertical entre publicações
        Listener(
          onPointerSignal: _tratarScrollRoda,
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
            child: ReelsBarraSuperiorWidget(
              theme: theme,
              tipo: pub.tipo,
              indiceAtivo: widget.indiceAtivo,
              totalPublicacoes: widget.publicacoes.length,
              onVoltar: () => Navigator.of(context).pop(),
              onMaisOpcoes: widget.onMaisOpcoes,
            ),
          ),

        // 4. Autor, prévia de 2 linhas da descrição, visualizações e data
        if (!_modoLimpo)
          Positioned(
            left: 14,
            right: 64,
            bottom: 58,
            child: ReelsRodapeAutorWidget(
              theme: theme,
              publicacao: pub,
              usuarioLogado: widget.usuarioLogado,
              coautoresResolvidos: widget.coautoresResolvidos,
              reacoes: widget.reacoes,
              republicacoes: widget.republicacoes,
              onAbrirDescricao: () => setState(() => _descricaoAberta = true),
            ),
          ),

        // 5. Coluna direita de ações (sem bordas, compacta)
        if (!_modoLimpo)
          Positioned(
            right: 8,
            bottom: 58,
            child: ReelsAcoesLateraisWidget(
              theme: theme,
              minhaReacao: widget.minhaReacao,
              likes: widget.likes,
              deslikes: widget.deslikes,
              totalComentarios: widget.comentarios.length,
              onReagir: widget.onReagir,
              onAbrirComentarios: () => setState(() {
                _descricaoAberta = false;
                _comentariosAbertos = true;
              }),
              onRepublicar: widget.onRepublicar,
              onEnviarChat: widget.onEnviarChat,
              onSalvar: widget.onSalvar,
              onAtivarModoLimpo: () => setState(() {
                _comentariosAbertos = false;
                _descricaoAberta = false;
                _modoLimpo = true;
              }),
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
            child: ReelsAbaComentariosWidget(
              theme: theme,
              totalComentarios: widget.comentarios.length,
              onAbrir: () => setState(() => _comentariosAbertos = true),
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

        // 8. Painel animado interno de Comentários
        ReelsPainelDeslizanteWidget(
          theme: theme,
          aberto: _comentariosAbertos,
          alturaTotal: alturaTotal,
          fatorTopo: 0.30,
          titulo: 'Comentários (${widget.comentarios.length})',
          acaoEsquerda: _buildBotaoMapaComentarios(theme),
          conteudo: widget.buildConteudoComentarios(theme, pub),
          rodape: widget.buildInputComentario(theme),
          onFechar: () => setState(() => _comentariosAbertos = false),
        ),

        // 9. Painel animado interno de Descrição completa
        ReelsPainelDeslizanteWidget(
          theme: theme,
          aberto: _descricaoAberta,
          alturaTotal: alturaTotal,
          fatorTopo: 0.40,
          titulo: 'Descrição',
          paddingConteudo: const EdgeInsets.all(16),
          conteudo: Column(
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
                    ? '${pub.visualizacoes} visualizações • ${formatarDataReels(pub.criadaEm)}'
                    : formatarDataReels(pub.criadaEm),
                style: theme.getTextStyle(
                  fontSize: 11.5,
                  color: theme.secondaryTextColor,
                ),
              ),
            ],
          ),
          onFechar: () => setState(() => _descricaoAberta = false),
        ),
      ],
    );
  }
}
