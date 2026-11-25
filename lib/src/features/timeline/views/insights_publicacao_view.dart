import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/auth/views/perfil_social_view.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/services/timeline_repositorio_sqlite.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_opcoes_publicacao.dart';
import 'package:nous/src/features/timeline/views/widgets/insights/insights_engajamento_dialogs.dart';
import 'package:nous/src/features/timeline/views/widgets/insights/insights_origens_card.dart';
import 'package:nous/src/features/timeline/views/widgets/insights/insights_resumo_alcance_card.dart';

/// Página de Insights da Publicação (visualizações, tempo médio, reações e origens).
/// Todos os containers são clicáveis para transparência completa de quem interagiu
/// e gráfico de engajamento por tempo de permanência.
class InsightsPublicacaoView extends StatefulWidget {
  final AppTheme theme;
  final PublicacaoSocial publicacao;
  final int totalCurtidas;
  final int totalDeslikes;
  final int totalComentarios;

  const InsightsPublicacaoView({
    super.key,
    required this.theme,
    required this.publicacao,
    required this.totalCurtidas,
    required this.totalDeslikes,
    required this.totalComentarios,
  });

  static Future<void> abrir(
    BuildContext context, {
    required AppTheme theme,
    required PublicacaoSocial publicacao,
    int totalCurtidas = 0,
    int totalDeslikes = 0,
    int totalComentarios = 0,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InsightsPublicacaoView(
          theme: theme,
          publicacao: publicacao,
          totalCurtidas: totalCurtidas,
          totalDeslikes: totalDeslikes,
          totalComentarios: totalComentarios,
        ),
      ),
    );
  }

  @override
  State<InsightsPublicacaoView> createState() => _InsightsPublicacaoViewState();
}

class _InsightsPublicacaoViewState extends State<InsightsPublicacaoView> {
  late PublicacaoSocial _pub;
  List<ReacaoSocial> _reacoes = [];
  List<ComentarioSocial> _comentarios = [];
  Map<String, UsuarioNous> _contasPorCpf = {};

  @override
  void initState() {
    super.initState();
    _pub = widget.publicacao;
    _carregarDetalhes();
  }

  Future<void> _carregarDetalhes() async {
    final atualizada =
        await TimelineRepositorioSqlite.buscarPublicacaoPorId(_pub.id) ?? _pub;
    final reacoes = await TimelineService.listarReacoes(_pub.id);
    final comentarios = await TimelineService.listarComentarios(_pub.id);
    final contas = await ContasNousService.carregarTodas();
    final mapa = <String, UsuarioNous>{};
    for (final c in contas) {
      final cpfNorm = c.cpf.replaceAll(RegExp(r'\D'), '');
      if (cpfNorm.isNotEmpty) mapa[cpfNorm] = c;
    }
    if (!mounted) return;
    setState(() {
      _pub = atualizada;
      _reacoes = reacoes;
      _comentarios = comentarios.where((c) => !c.excluido).toList();
      _contasPorCpf = mapa;
    });
  }

  Future<void> _abrirPerfilPorCpf(BuildContext ctxDialog, String cpf) async {
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
    final conta = _contasPorCpf[cpfLimpo] ??
        await ContasNousService.buscarPorCpf(cpfLimpo);
    if (!ctxDialog.mounted) return;
    Navigator.of(ctxDialog).pop();
    if (conta != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PerfilSocialView(
            usuarioAlvo: conta,
            mostrarBotaoVoltar: true,
          ),
        ),
      );
    }
  }

  Future<void> _mostrarListaVisualizadores() {
    return InsightsEngajamentoDialogs.mostrarListaVisualizadores(
      context,
      theme: widget.theme,
      visualizadoresCpfs: _pub.visualizadoresCpfs,
      contasPorCpf: _contasPorCpf,
      onAbrirPerfil: _abrirPerfilPorCpf,
    );
  }

  Future<void> _mostrarGraficoTempoEngajamento() {
    return InsightsEngajamentoDialogs.mostrarGraficoTempoEngajamento(
      context,
      theme: widget.theme,
      tempoPorVisualizador: _pub.tempoPorVisualizador,
      contasPorCpf: _contasPorCpf,
      onAbrirPerfil: _abrirPerfilPorCpf,
    );
  }

  Future<void> _mostrarListaComentarios() {
    return InsightsEngajamentoDialogs.mostrarListaComentarios(
      context,
      theme: widget.theme,
      comentarios: _comentarios,
      onAbrirPerfil: _abrirPerfilPorCpf,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final totalVis = _pub.visualizacoes;
    final likesCount = _reacoes.isNotEmpty
        ? _reacoes.where((r) => r.tipo == TipoReacaoSocial.like).length
        : widget.totalCurtidas;
    final deslikesCount = _reacoes.isNotEmpty
        ? _reacoes.where((r) => r.tipo == TipoReacaoSocial.deslike).length
        : widget.totalDeslikes;
    final comentariosCount = _comentarios.isNotEmpty
        ? _comentarios.length
        : widget.totalComentarios;

    final origens = _pub.visualizacoesPorOrigem.isEmpty
        ? <String, int>{
            'Feed Principal': totalVis,
            'Perfil Público': 0,
            'Descoberta / Busca': 0,
          }
        : _pub.visualizacoesPorOrigem;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardBackgroundColor,
        foregroundColor: theme.textColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Insights da Publicação',
          style: theme.getTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              InsightsResumoAlcanceCard(
                theme: theme,
                totalVisualizacoes: totalVis,
                tempoMedioFormatado: InsightsEngajamentoDialogs.formatarTempo(
                  _pub.tempoMedioVisualizacaoSegundos,
                ),
                totalLikes: likesCount,
                totalComentarios: comentariosCount,
                totalDeslikes: deslikesCount,
                onTapVisualizacoes: _mostrarListaVisualizadores,
                onTapTempoMedio: _mostrarGraficoTempoEngajamento,
                onTapLikes: () => DialogOpcoesPublicacao.mostrarListaReacoes(
                  context,
                  theme: theme,
                  reacoes: _reacoes,
                  tipo: TipoReacaoSocial.like,
                ),
                onTapComentarios: _mostrarListaComentarios,
                onTapDeslikes: () => DialogOpcoesPublicacao.mostrarListaReacoes(
                  context,
                  theme: theme,
                  reacoes: _reacoes,
                  tipo: TipoReacaoSocial.deslike,
                ),
              ),
              const SizedBox(height: 14),
              InsightsOrigensCard(
                theme: theme,
                origens: origens,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
