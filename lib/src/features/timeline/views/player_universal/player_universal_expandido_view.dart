import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/player_video_nous_widget.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/timeline/controllers/player_universal_controller.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/services/timeline_repositorio_sqlite.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_detalhes_publicacao.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_enviar_publicacao_chat.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_salvar_publicacao.dart';
import 'package:nous/src/features/timeline/views/player_universal/capa_midia_universal_widget.dart';
import 'package:nous/src/features/timeline/views/player_universal/painel_lateral_player_widget.dart';

/// Tela expandida do Player Universal (Música, Vídeo, Fila, Letra e Cifra).
/// No desktop (>= 860 px) apresenta layout em 2 colunas estilo YouTube Music /
/// Spotify com fundo desfocado da miniatura do arquivo.
class PlayerUniversalExpandidoView extends StatefulWidget {
  final AppTheme theme;

  const PlayerUniversalExpandidoView({
    super.key,
    required this.theme,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PlayerUniversalExpandidoView(theme: theme),
      ),
    );
  }

  @override
  State<PlayerUniversalExpandidoView> createState() =>
      _PlayerUniversalExpandidoViewState();
}

class _PlayerUniversalExpandidoViewState
    extends State<PlayerUniversalExpandidoView> {
  final PlayerUniversalController _ctrl = PlayerUniversalController.instancia;

  // No mobile: null = player principal; 0/1/2 = painel aberto.
  // No desktop: _abaLateralSelecionada controla a coluna direita (0/1/2).
  int? _abaMobileAberta;
  int _abaDesktopSelecionada = 0;

  String _ultimoIdReacoes = '';
  bool _curtiu = false;
  bool _descurtiu = false;
  bool _salvo = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_aoAtualizarController);
    _carregarInteracoes();
  }

  @override
  void dispose() {
    _ctrl.removeListener(_aoAtualizarController);
    super.dispose();
  }

  void _aoAtualizarController() {
    final idAtual = _ctrl.atual?.id ?? '';
    if (idAtual.isNotEmpty && idAtual != _ultimoIdReacoes) {
      _carregarInteracoes();
    }
  }

  Future<void> _carregarInteracoes() async {
    final pub = _ctrl.atual;
    final usuario = context.read<AuthProvider>().contaAtual;
    if (pub == null || usuario == null) return;
    _ultimoIdReacoes = pub.id;
    final cpfNorm = TimelineRepositorioSqlite.normalizarCpf(usuario.cpf);
    final reacoes =
        await TimelineRepositorioSqlite.listarReacoesDaPublicacao(pub.id);
    final salvos =
        await TimelineRepositorioSqlite.listarItensSalvosDoUsuario(cpfNorm);

    if (!mounted) return;
    setState(() {
      _curtiu = reacoes.any(
        (r) =>
            TimelineRepositorioSqlite.normalizarCpf(r.usuarioCpf) == cpfNorm &&
            r.tipo == TipoReacaoSocial.like,
      );
      _descurtiu = reacoes.any(
        (r) =>
            TimelineRepositorioSqlite.normalizarCpf(r.usuarioCpf) == cpfNorm &&
            r.tipo == TipoReacaoSocial.deslike,
      );
      _salvo = salvos.any((s) => s.publicacaoId == pub.id);
    });
  }

  Future<void> _alternarReacao(TipoReacaoSocial tipo) async {
    final pub = _ctrl.atual;
    final usuario = context.read<AuthProvider>().contaAtual;
    if (pub == null || usuario == null) return;
    await TimelineService.alternarReacao(
      publicacaoId: pub.id,
      usuarioCpf: usuario.cpf,
      usuarioNome: usuario.nome,
      usuarioFoto: usuario.fotoExibicao,
      tipo: tipo,
    );
    await _carregarInteracoes();
  }

  String _formatarDuracao(Duration d) {
    final total = d.inSeconds.clamp(0, 86400);
    final min = (total ~/ 60).toString().padLeft(2, '0');
    final seg = (total % 60).toString().padLeft(2, '0');
    return '$min:$seg';
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          final pub = _ctrl.atual;
          if (pub == null) {
            return SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Nenhuma mídia selecionada.',
                      style: TextStyle(color: theme.secondaryTextColor),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Voltar',
                        style: TextStyle(color: theme.textColor),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final fundoProvider =
              CapaMidiaUniversalWidget.obterImageProvider(pub);

          return Stack(
            children: [
              if (fundoProvider != null)
                Positioned.fill(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 54, sigmaY: 54),
                    child: Transform.scale(
                      scale: 1.15,
                      child: Image(
                        image: fundoProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.backgroundColor.withValues(
                          alpha: fundoProvider != null ? 0.66 : 1.0,
                        ),
                        theme.backgroundColor.withValues(
                          alpha: fundoProvider != null ? 0.84 : 1.0,
                        ),
                        theme.backgroundColor.withValues(
                          alpha: fundoProvider != null ? 0.96 : 1.0,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final ehDesktop = constraints.maxWidth >= 860;
                    return Column(
                      children: [
                        _buildBarraTopo(theme, pub),
                        Expanded(
                          child: ehDesktop
                              ? _buildLayoutDesktop(theme, pub, constraints)
                              : _buildLayoutMobile(theme, pub),
                        ),
                        if (!ehDesktop) _buildAbasInferioresMobile(theme),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBarraTopo(AppTheme theme, PublicacaoSocial pub) {
    final temAudio = PlayerUniversalController.possuiAudio(pub);
    final temVideo = PlayerUniversalController.possuiVideo(pub);
    final usuario = context.read<AuthProvider>().contaAtual;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Minimizar',
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: theme.textColor,
              size: 28,
            ),
          ),
          const Spacer(),
          if (temAudio || temVideo)
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: theme.cardBackgroundColor.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.borderColor.withValues(alpha: 0.65),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToggleModo(
                    theme: theme,
                    label: 'Música',
                    ativo: !_ctrl.modoVideo,
                    habilitado: temAudio,
                    onTap: () => _ctrl.definirModoVideo(false),
                  ),
                  _buildToggleModo(
                    theme: theme,
                    label: 'Vídeo',
                    ativo: _ctrl.modoVideo,
                    habilitado: temVideo,
                    onTap: () => _ctrl.definirModoVideo(true),
                  ),
                ],
              ),
            ),
          const Spacer(),
          IconButton(
            tooltip: 'Abrir publicação original',
            onPressed: () {
              DialogDetalhesPublicacao.mostrar(
                context,
                theme: theme,
                publicacao: pub,
                usuarioLogado: usuario,
              );
            },
            icon: Icon(
              Icons.open_in_new_rounded,
              color: theme.textColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleModo({
    required AppTheme theme,
    required String label,
    required bool ativo,
    required bool habilitado,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: habilitado ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: ativo
              ? theme.textColor.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: !habilitado
                ? theme.secondaryTextColor.withValues(alpha: 0.38)
                : ativo
                    ? theme.textColor
                    : theme.secondaryTextColor,
            fontSize: 12.5,
            fontWeight: ativo ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildLayoutDesktop(
    AppTheme theme,
    PublicacaoSocial pub,
    BoxConstraints constraints,
  ) {
    final tamanhoCapa =
        (constraints.maxHeight * 0.42).clamp(220.0, 340.0);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: Center(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: _buildBlocoPlayer(
                        theme,
                        pub,
                        tamanhoCapa: tamanhoCapa,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 36),
              Expanded(
                flex: 5,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardBackgroundColor.withValues(alpha: 0.56),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.45),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: theme.borderColor.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildBotaoAba(
                              theme,
                              idx: 0,
                              label: 'A SEGUIR',
                              ativo: _abaDesktopSelecionada == 0,
                              onTap: () =>
                                  setState(() => _abaDesktopSelecionada = 0),
                            ),
                            _buildBotaoAba(
                              theme,
                              idx: 1,
                              label: 'LETRA',
                              ativo: _abaDesktopSelecionada == 1,
                              onTap: () =>
                                  setState(() => _abaDesktopSelecionada = 1),
                            ),
                            _buildBotaoAba(
                              theme,
                              idx: 2,
                              label: 'CIFRA',
                              ativo: _abaDesktopSelecionada == 2,
                              onTap: () =>
                                  setState(() => _abaDesktopSelecionada = 2),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _buildConteudoPainel(
                          theme,
                          pub,
                          _abaDesktopSelecionada,
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
    );
  }

  Widget _buildLayoutMobile(AppTheme theme, PublicacaoSocial pub) {
    if (_abaMobileAberta != null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: _buildConteudoPainel(theme, pub, _abaMobileAberta!),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final tamanhoCapa =
            (constraints.maxWidth * 0.66).clamp(180.0, 300.0);
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _buildBlocoPlayer(
                theme,
                pub,
                tamanhoCapa: tamanhoCapa,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBlocoPlayer(
    AppTheme theme,
    PublicacaoSocial pub, {
    required double tamanhoCapa,
  }) {
    final meta = _ctrl.estadoAudio.metadados;
    final tituloMeta = (meta?.titulo ?? '').trim();
    final artistaMeta = (meta?.artista ?? '').trim();
    final titulo = tituloMeta.isNotEmpty
        ? tituloMeta
        : PlayerUniversalController.obterTitulo(pub);
    final autor = artistaMeta.isNotEmpty
        ? '$artistaMeta · ${pub.autorNome}'
        : (pub.autorNome.isNotEmpty ? pub.autorNome : 'Autor');

    final usuario = context.read<AuthProvider>().contaAtual;
    final duracao = _ctrl.estadoAudio.duracaoEstimada;
    final pos = _ctrl.estadoAudio.posicao;
    final maxMs = duracao.inMilliseconds > 0 ? duracao.inMilliseconds : 1;
    final posMs = pos.inMilliseconds.clamp(0, maxMs);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_ctrl.modoVideo)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 290),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: PlayerVideoNousWidget(
                key: ValueKey('player_univ_video_${pub.id}'),
                theme: theme,
                caminhoVideo:
                    PlayerUniversalController.obterCaminhoMidiaPrincipal(
                  pub,
                  preferirVideo: true,
                ),
                caminhoCapa: pub.capaCaminho,
                autoPlay: true,
                titulo: titulo,
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: theme.backgroundColor.withValues(alpha: 0.55),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: CapaMidiaUniversalWidget(
              theme: theme,
              publicacao: pub,
              largura: tamanhoCapa,
              altura: tamanhoCapa,
              borderRadius: 18,
              tamanhoIcone: 84,
            ),
          ),
        const SizedBox(height: 22),
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                autor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.secondaryTextColor,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Divider(color: theme.borderColor.withValues(alpha: 0.35), height: 1),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              tooltip: 'Curtir',
              onPressed: () => _alternarReacao(TipoReacaoSocial.like),
              icon: Icon(
                _curtiu ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                color: _curtiu ? theme.textColor : theme.secondaryTextColor,
                size: 20,
              ),
            ),
            IconButton(
              tooltip: 'Não curtir',
              onPressed: () => _alternarReacao(TipoReacaoSocial.deslike),
              icon: Icon(
                _descurtiu
                    ? Icons.thumb_down_rounded
                    : Icons.thumb_down_outlined,
                color: _descurtiu
                    ? theme.dangerColor
                    : theme.secondaryTextColor,
                size: 20,
              ),
            ),
            IconButton(
              tooltip: 'Salvar publicação',
              onPressed: usuario == null
                  ? null
                  : () async {
                      await DialogSalvarPublicacao.mostrar(
                        context,
                        theme: theme,
                        usuarioCpf: usuario.cpf,
                        publicacaoId: pub.id,
                      );
                      await _carregarInteracoes();
                    },
              icon: Icon(
                _salvo ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
                color: _salvo ? theme.textColor : theme.secondaryTextColor,
                size: 21,
              ),
            ),
            IconButton(
              tooltip: 'Comentários',
              onPressed: () {
                DialogDetalhesPublicacao.mostrar(
                  context,
                  theme: theme,
                  publicacao: pub,
                  usuarioLogado: usuario,
                );
              },
              icon: Icon(
                Icons.chat_bubble_outline_rounded,
                color: theme.secondaryTextColor,
                size: 20,
              ),
            ),
            IconButton(
              tooltip: 'Compartilhar no chat',
              onPressed: usuario == null
                  ? null
                  : () {
                      DialogEnviarPublicacaoChat.mostrar(
                        context,
                        theme: theme,
                        publicacao: pub,
                        remetente: usuario,
                      );
                    },
              icon: Icon(
                Icons.share_outlined,
                color: theme.secondaryTextColor,
                size: 20,
              ),
            ),
          ],
        ),
        if (!_ctrl.modoVideo) ...[
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: theme.textColor,
              inactiveTrackColor: theme.borderColor.withValues(alpha: 0.4),
              thumbColor: theme.textColor,
            ),
            child: Slider(
              value: posMs.toDouble(),
              min: 0,
              max: maxMs.toDouble(),
              onChanged: (v) {
                _ctrl.buscarPosicao(Duration(milliseconds: v.round()));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatarDuracao(pos),
                  style: TextStyle(
                    color: theme.secondaryTextColor,
                    fontSize: 11.5,
                  ),
                ),
                Text(
                  _formatarDuracao(duracao),
                  style: TextStyle(
                    color: theme.secondaryTextColor,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              tooltip: 'Aleatório',
              onPressed: _ctrl.alternarAleatorio,
              icon: Icon(
                Icons.shuffle_rounded,
                color: _ctrl.aleatorio
                    ? theme.textColor
                    : theme.secondaryTextColor.withValues(alpha: 0.65),
                size: 22,
              ),
            ),
            IconButton(
              tooltip: 'Anterior',
              onPressed: _ctrl.anterior,
              icon: Icon(
                Icons.skip_previous_rounded,
                color: theme.textColor,
                size: 32,
              ),
            ),
            if (!_ctrl.modoVideo)
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: theme.textColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  tooltip: _ctrl.estaTocando ? 'Pausar' : 'Reproduzir',
                  onPressed: _ctrl.alternarPlayPause,
                  icon: Icon(
                    _ctrl.estaTocando
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: theme.backgroundColor,
                    size: 32,
                  ),
                ),
              ),
            IconButton(
              tooltip: 'Próxima',
              onPressed: _ctrl.proxima,
              icon: Icon(
                Icons.skip_next_rounded,
                color: theme.textColor,
                size: 32,
              ),
            ),
            IconButton(
              tooltip: 'Repetir',
              onPressed: _ctrl.alternarRepetir,
              icon: Icon(
                Icons.repeat_rounded,
                color: _ctrl.repetir
                    ? theme.textColor
                    : theme.secondaryTextColor.withValues(alpha: 0.65),
                size: 22,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConteudoPainel(
    AppTheme theme,
    PublicacaoSocial pub,
    int abaIdx,
  ) {
    return PainelLateralPlayerWidget(
      theme: theme,
      publicacao: pub,
      abaIndex: abaIdx,
      controller: _ctrl,
    );
  }

  Widget _buildAbasInferioresMobile(AppTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.borderColor.withValues(alpha: 0.35)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBotaoAba(
            theme,
            idx: 0,
            label: 'A SEGUIR',
            ativo: _abaMobileAberta == 0,
            onTap: () => setState(
              () => _abaMobileAberta = _abaMobileAberta == 0 ? null : 0,
            ),
          ),
          _buildBotaoAba(
            theme,
            idx: 1,
            label: 'LETRA',
            ativo: _abaMobileAberta == 1,
            onTap: () => setState(
              () => _abaMobileAberta = _abaMobileAberta == 1 ? null : 1,
            ),
          ),
          _buildBotaoAba(
            theme,
            idx: 2,
            label: 'CIFRA',
            ativo: _abaMobileAberta == 2,
            onTap: () => setState(
              () => _abaMobileAberta = _abaMobileAberta == 2 ? null : 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoAba(
    AppTheme theme, {
    required int idx,
    required String label,
    required bool ativo,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: ativo
              ? theme.textColor.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: ativo ? theme.textColor : theme.secondaryTextColor,
            fontSize: 12,
            fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}
