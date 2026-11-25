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
import 'package:nous/src/features/timeline/views/player_universal/widgets/player_universal_abas_painel.dart';
import 'package:nous/src/features/timeline/views/player_universal/widgets/player_universal_acoes_sociais.dart';
import 'package:nous/src/features/timeline/views/player_universal/widgets/player_universal_barra_topo.dart';
import 'package:nous/src/features/timeline/views/player_universal/widgets/player_universal_controles_reproducao.dart';

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
                    final usuario = context.read<AuthProvider>().contaAtual;
                    return Column(
                      children: [
                        PlayerUniversalBarraTopo(
                          theme: theme,
                          publicacao: pub,
                          controller: _ctrl,
                          onAbrirDetalhes: () {
                            DialogDetalhesPublicacao.mostrar(
                              context,
                              theme: theme,
                              publicacao: pub,
                              usuarioLogado: usuario,
                            );
                          },
                        ),
                        Expanded(
                          child: ehDesktop
                              ? _buildLayoutDesktop(theme, pub, constraints)
                              : _buildLayoutMobile(theme, pub),
                        ),
                        if (!ehDesktop)
                          PlayerUniversalAbasPainel(
                            theme: theme,
                            abaSelecionada: _abaMobileAberta,
                            bordaSuperior: true,
                            onSelecionarAba: (idx) => setState(
                              () => _abaMobileAberta =
                                  _abaMobileAberta == idx ? null : idx,
                            ),
                          ),
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
                      PlayerUniversalAbasPainel(
                        theme: theme,
                        abaSelecionada: _abaDesktopSelecionada,
                        onSelecionarAba: (idx) =>
                            setState(() => _abaDesktopSelecionada = idx),
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
        PlayerUniversalAcoesSociais(
          theme: theme,
          curtiu: _curtiu,
          descurtiu: _descurtiu,
          salvo: _salvo,
          onCurtir: () => _alternarReacao(TipoReacaoSocial.like),
          onDescurtir: () => _alternarReacao(TipoReacaoSocial.deslike),
          onSalvar: usuario == null
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
          onComentarios: () {
            DialogDetalhesPublicacao.mostrar(
              context,
              theme: theme,
              publicacao: pub,
              usuarioLogado: usuario,
            );
          },
          onCompartilhar: usuario == null
              ? null
              : () {
                  DialogEnviarPublicacaoChat.mostrar(
                    context,
                    theme: theme,
                    publicacao: pub,
                    remetente: usuario,
                  );
                },
        ),
        PlayerUniversalControlesReproducao(
          theme: theme,
          controller: _ctrl,
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
}
