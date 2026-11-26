import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/core/widgets/floating_bottom_nav_bar.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/timeline/controllers/player_universal_controller.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/services/timeline_repositorio_sqlite.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_detalhes_publicacao.dart';
import 'package:nous/src/features/timeline/views/player_universal/capa_midia_universal_widget.dart';
import 'package:nous/src/features/timeline/views/player_universal/mini_player_universal_widget.dart';
import 'package:nous/src/features/timeline/views/player_universal/player_universal_expandido_view.dart';

/// Hub centralizado de mídia da rede Nous (PDFs/Livros, Músicas e Vídeos).
/// Acessado ao alternar o slot "Busca e Mapa" na barra de navegação inferior.
class PlayerUniversalView extends StatefulWidget {
  const PlayerUniversalView({super.key});

  @override
  State<PlayerUniversalView> createState() => _PlayerUniversalViewState();
}

class _PlayerUniversalViewState extends State<PlayerUniversalView> {
  // 0 = PDF, 1 = Música, 2 = Vídeo
  int _abaSelecionada = 1;
  bool _carregando = true;

  List<PublicacaoSocial> _musicas = [];
  List<PublicacaoSocial> _pdfs = [];
  List<PublicacaoSocial> _videos = [];
  List<PublicacaoSocial> _videosSeguindo = [];
  List<PublicacaoSocial> _pdfsSeguindo = [];

  @override
  void initState() {
    super.initState();
    TimelineService.alteracoesTimelineNotifier.addListener(_aoAtualizarTimeline);
    _carregarMidias();
  }

  @override
  void dispose() {
    TimelineService.alteracoesTimelineNotifier.removeListener(_aoAtualizarTimeline);
    super.dispose();
  }

  void _aoAtualizarTimeline() {
    if (mounted) _carregarMidias();
  }

  Future<void> _carregarMidias() async {
    setState(() => _carregando = true);
    try {
      final usuario = context.read<AuthProvider>().contaAtual;
      final todas = await TimelineRepositorioSqlite.listarPublicacoesDescoberta(
        limit: 160,
      );

      final seguindoCpfs = usuario == null
          ? <String>{}
          : usuario.seguindo
              .map(TimelineRepositorioSqlite.normalizarCpf)
              .where((c) => c.isNotEmpty)
              .toSet();

      final musicas = todas
          .where(PlayerUniversalController.possuiAudio)
          .toList()
        ..sort((a, b) => b.visualizacoes.compareTo(a.visualizacoes));

      final pdfs = todas
          .where((p) =>
              p.tipo == TipoFeedSocial.documentos ||
              p.tipo == TipoFeedSocial.livros)
          .toList()
        ..sort((a, b) => b.visualizacoes.compareTo(a.visualizacoes));

      final videos = todas
          .where(PlayerUniversalController.possuiVideo)
          .toList()
        ..sort((a, b) => b.criadaEm.compareTo(a.criadaEm));

      final videosSeg = videos
          .where((v) => seguindoCpfs
              .contains(TimelineRepositorioSqlite.normalizarCpf(v.autorCpf)))
          .toList();

      final pdfsSeg = pdfs
          .where((d) => seguindoCpfs
              .contains(TimelineRepositorioSqlite.normalizarCpf(d.autorCpf)))
          .toList();

      if (!mounted) return;
      setState(() {
        _musicas = musicas;
        _pdfs = pdfs;
        _videos = videos;
        _videosSeguindo = videosSeg;
        _pdfsSeguindo = pdfsSeg.isNotEmpty ? pdfsSeg : pdfs;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  Future<void> _abrirAudio(
    PublicacaoSocial pub,
    List<PublicacaoSocial> fila,
  ) async {
    final usuario = context.read<AuthProvider>().contaAtual;
    if (usuario != null) {
      TimelineService.registrarVisualizacaoPublicacao(
        pub,
        origem: 'player_universal',
        visualizadorCpf: usuario.cpf,
      );
    }
    await PlayerUniversalController.instancia.tocarPublicacao(
      pub,
      novaFila: fila,
      iniciarComoVideo: false,
    );
  }

  Future<void> _abrirVideo(
    AppTheme theme,
    PublicacaoSocial pub,
    List<PublicacaoSocial> fila,
  ) async {
    final usuario = context.read<AuthProvider>().contaAtual;
    if (usuario != null) {
      TimelineService.registrarVisualizacaoPublicacao(
        pub,
        origem: 'player_universal',
        visualizadorCpf: usuario.cpf,
      );
    }
    await PlayerUniversalController.instancia.tocarPublicacao(
      pub,
      novaFila: fila,
      iniciarComoVideo: true,
    );
    if (!mounted) return;
    await PlayerUniversalExpandidoView.mostrar(context, theme: theme);
  }

  void _abrirPdf(AppTheme theme, PublicacaoSocial pub) {
    final usuario = context.read<AuthProvider>().contaAtual;
    DialogDetalhesPublicacao.mostrar(
      context,
      theme: theme,
      publicacao: pub,
      usuarioLogado: usuario,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return Scaffold(
              backgroundColor: theme.backgroundColor,
              appBar: const CustomAppBar(
                title: 'Player Universal',
                showBackButton: false,
              ),
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                    child: _buildSeletorAbas(theme),
                  ),
                  Expanded(
                    child: _carregando
                        ? Center(
                            child: CircularProgressIndicator(
                              color: theme.textColor,
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _carregarMidias,
                            color: theme.textColor,
                            backgroundColor: theme.cardBackgroundColor,
                            child: _buildConteudoAba(theme),
                          ),
                  ),
                  MiniPlayerUniversalWidget(theme: theme),
                  FloatingBottomNavBar(
                    slotSelecionado: 2,
                    subIndiceSelecionado: 1,
                    maxWidth: constraints.maxWidth,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSeletorAbas(AppTheme theme) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: theme.cardBackgroundColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: theme.borderColor.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBotaoAba(theme, 0, 'PDF'),
            _buildBotaoAba(theme, 1, 'Música'),
            _buildBotaoAba(theme, 2, 'Vídeo'),
          ],
        ),
      ),
    );
  }

  Widget _buildBotaoAba(AppTheme theme, int idx, String label) {
    final ativo = _abaSelecionada == idx;
    return GestureDetector(
      onTap: () => setState(() => _abaSelecionada = idx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: BoxDecoration(
          color: ativo
              ? theme.textColor.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: ativo ? theme.textColor : theme.secondaryTextColor,
            fontSize: 13,
            fontWeight: ativo ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildConteudoAba(AppTheme theme) {
    switch (_abaSelecionada) {
      case 0:
        return _buildAbaPdf(theme);
      case 2:
        return _buildAbaVideo(theme);
      case 1:
      default:
        return _buildAbaMusica(theme);
    }
  }

  Widget _buildCabecalhoSecao(
    AppTheme theme,
    String titulo,
    String subtitulo,
    IconData icone,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.cardBackgroundColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.6),
              ),
            ),
            child: Icon(icone, size: 17, color: theme.textColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitulo,
                  style: TextStyle(
                    color: theme.secondaryTextColor,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.secondaryTextColor,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildGrade3Colunas(
    AppTheme theme,
    List<PublicacaoSocial> itens, {
    required void Function(PublicacaoSocial) aoTocar,
  }) {
    final exibidos = itens.take(9).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: exibidos.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.88,
        ),
        itemBuilder: (context, index) {
          final pub = exibidos[index];
          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => aoTocar(pub),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CapaMidiaUniversalWidget(
                    theme: theme,
                    publicacao: pub,
                    largura: double.infinity,
                    altura: double.infinity,
                    borderRadius: 10,
                    tamanhoIcone: 30,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  PlayerUniversalController.obterTitulo(pub),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCarrosselHorizontal(
    AppTheme theme,
    List<PublicacaoSocial> itens, {
    required void Function(PublicacaoSocial) aoTocar,
  }) {
    return SizedBox(
      height: 162,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: itens.take(15).length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final pub = itens[index];
          return SizedBox(
            width: 122,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => aoTocar(pub),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CapaMidiaUniversalWidget(
                    theme: theme,
                    publicacao: pub,
                    largura: 122,
                    altura: 116,
                    borderRadius: 12,
                    tamanhoIcone: 42,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    PlayerUniversalController.obterTitulo(pub),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    pub.autorNome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.secondaryTextColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAbaMusica(AppTheme theme) {
    if (_musicas.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 40),
          EstadoVazioContainer(
            theme: theme,
            mensagem: 'Nenhuma música publicada na rede ainda',
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 18),
      children: [
        _buildCabecalhoSecao(
          theme,
          'Músicas mais ouvidas',
          'Baseado no histórico da rede local',
          Icons.graphic_eq_rounded,
        ),
        _buildGrade3Colunas(
          theme,
          _musicas,
          aoTocar: (pub) => _abrirAudio(pub, _musicas),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            'Álbuns e Destaques',
            style: TextStyle(
              color: theme.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _buildCarrosselHorizontal(
          theme,
          _musicas.reversed.toList(),
          aoTocar: (pub) => _abrirAudio(pub, _musicas),
        ),
      ],
    );
  }

  Widget _buildAbaPdf(AppTheme theme) {
    if (_pdfs.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 40),
          EstadoVazioContainer(
            theme: theme,
            mensagem: 'Nenhum PDF ou livro publicado na rede ainda',
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 18),
      children: [
        _buildCabecalhoSecao(
          theme,
          'Leituras seguidas',
          'Baseado em quem você segue e lê',
          Icons.menu_book_rounded,
        ),
        _buildGrade3Colunas(
          theme,
          _pdfsSeguindo,
          aoTocar: (pub) => _abrirPdf(theme, pub),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            'Livros e documentos em alta',
            style: TextStyle(
              color: theme.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _buildCarrosselHorizontal(
          theme,
          _pdfs,
          aoTocar: (pub) => _abrirPdf(theme, pub),
        ),
      ],
    );
  }

  Widget _buildAbaVideo(AppTheme theme) {
    if (_videos.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 40),
          EstadoVazioContainer(
            theme: theme,
            mensagem: 'Nenhum vídeo publicado na rede ainda',
          ),
        ],
      );
    }

    final principal = _videos.first;
    final demais =
        _videos.length > 1 ? _videos.sublist(1) : <PublicacaoSocial>[];

    return ListView(
      padding: const EdgeInsets.only(bottom: 18),
      children: [
        _buildCabecalhoSecao(
          theme,
          'Sugestões de vídeos',
          'Baseado nas publicações da rede',
          Icons.ondemand_video_rounded,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildCardVideoDestaque(theme, principal),
        ),
        if (_videosSeguindo.isNotEmpty) ...[
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              'De quem você segue',
              style: TextStyle(
                color: theme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildCarrosselHorizontal(
            theme,
            _videosSeguindo,
            aoTocar: (pub) => _abrirVideo(theme, pub, _videos),
          ),
        ],
        if (demais.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              'Mais vídeos na rede',
              style: TextStyle(
                color: theme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...demais.take(10).map(
                (v) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: _buildCardVideoDestaque(theme, v),
                ),
              ),
        ],
      ],
    );
  }

  Widget _buildCardVideoDestaque(AppTheme theme, PublicacaoSocial pub) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _abrirVideo(theme, pub, _videos),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CapaMidiaUniversalWidget(
                  theme: theme,
                  publicacao: pub,
                  largura: double.infinity,
                  altura: double.infinity,
                  borderRadius: 12,
                  tamanhoIcone: 48,
                ),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: theme.backgroundColor.withValues(alpha: 0.72),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: theme.textColor,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            PlayerUniversalController.obterTitulo(pub),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${pub.autorNome} · ${pub.visualizacoes} visualizações',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.secondaryTextColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
