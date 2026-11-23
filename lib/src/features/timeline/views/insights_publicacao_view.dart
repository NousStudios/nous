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
import 'package:nous/src/features/timeline/views/widgets/avatar_com_story_widget.dart';

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

  String _formatarTempo(int segundos) {
    if (segundos <= 0) return '0s';
    if (segundos < 60) return '${segundos}s';
    final min = segundos ~/ 60;
    final seg = segundos % 60;
    return '${min}m ${seg}s';
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

  Future<void> _mostrarListaVisualizadores() async {
    final theme = widget.theme;
    final cpfs = _pub.visualizadoresCpfs
        .map((c) => c.replaceAll(RegExp(r'\D'), ''))
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();

    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: theme.borderColor),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        'Quem visualizou (${cpfs.length})',
                        style: theme.getTextStyle(
                          fontSize: 15,
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
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.borderColor.withValues(alpha: 0.35)),
              if (cpfs.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Nenhuma visualização nominal registrada ainda.',
                    style: theme.getTextStyle(
                      fontSize: 12.5,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: cpfs.length,
                    itemBuilder: (_, i) {
                      final cpf = cpfs[i];
                      final conta = _contasPorCpf[cpf];
                      final nome = conta?.nomeExibicao.isNotEmpty == true
                          ? conta!.nomeExibicao
                          : cpf;
                      final handle = conta?.usernameExibicao ?? '';
                      return ListTile(
                        leading: AvatarComStoryWidget(
                          theme: theme,
                          cpf: cpf,
                          nome: nome,
                          foto: conta?.fotoExibicao ?? '',
                          radius: 17,
                          usuario: conta,
                        ),
                        title: Text(
                          nome,
                          style: theme.getTextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: theme.textColor,
                          ),
                        ),
                        subtitle: handle.isNotEmpty
                            ? Text(
                                handle,
                                style: theme.getTextStyle(
                                  fontSize: 11.5,
                                  color: theme.secondaryTextColor,
                                ),
                              )
                            : null,
                        trailing: Icon(
                          Icons.visibility_outlined,
                          size: 16,
                          color: theme.secondaryTextColor,
                        ),
                        onTap: () => _abrirPerfilPorCpf(ctx, cpf),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarGraficoTempoEngajamento() async {
    final theme = widget.theme;
    final entradas = _pub.tempoPorVisualizador.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxSeg = entradas.isNotEmpty ? entradas.first.value : 1;

    String classificar(int seg) {
      if (seg >= 30) return 'Muito engajado';
      if (seg >= 10) return 'Engajado';
      return 'Leitura rápida';
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: theme.borderColor),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 460,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.80,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        'Engajamento por Tempo',
                        style: theme.getTextStyle(
                          fontSize: 15,
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
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.borderColor.withValues(alpha: 0.35)),
              if (entradas.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Ainda não há registros individuais de tempo de permanência.',
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(
                      fontSize: 12.5,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(14),
                    itemCount: entradas.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final entry = entradas[i];
                      final cpf = entry.key.replaceAll(RegExp(r'\D'), '');
                      final seg = entry.value;
                      final conta = _contasPorCpf[cpf];
                      final nome = conta?.nomeExibicao.isNotEmpty == true
                          ? conta!.nomeExibicao
                          : cpf;
                      final fracao = (seg / maxSeg).clamp(0.05, 1.0);
                      final nivel = classificar(seg);

                      return InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _abrirPerfilPorCpf(ctx, cpf),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  AvatarComStoryWidget(
                                    theme: theme,
                                    cpf: cpf,
                                    nome: nome,
                                    foto: conta?.fotoExibicao ?? '',
                                    radius: 15,
                                    usuario: conta,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      nome,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.getTextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: theme.textColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: seg >= 30
                                          ? theme.buttonColor
                                              .withValues(alpha: 0.16)
                                          : theme.backgroundColor
                                              .withValues(alpha: 0.55),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      nivel,
                                      style: theme.getTextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: seg >= 30
                                            ? theme.buttonColor
                                            : theme.secondaryTextColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatarTempo(seg),
                                    style: theme.getTextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: fracao,
                                  minHeight: 8,
                                  backgroundColor:
                                      theme.borderColor.withValues(alpha: 0.25),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    seg >= 30
                                        ? theme.buttonColor
                                        : theme.textColor
                                            .withValues(alpha: 0.65),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarListaComentarios() async {
    final theme = widget.theme;
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: theme.borderColor),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        'Quem comentou (${_comentarios.length})',
                        style: theme.getTextStyle(
                          fontSize: 15,
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
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.borderColor.withValues(alpha: 0.35)),
              if (_comentarios.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Nenhum comentário registrado ainda.',
                    style: theme.getTextStyle(
                      fontSize: 12.5,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _comentarios.length,
                    itemBuilder: (_, i) {
                      final c = _comentarios[i];
                      final nome =
                          c.autorNome.isNotEmpty ? c.autorNome : c.autorCpf;
                      return ListTile(
                        leading: AvatarComStoryWidget(
                          theme: theme,
                          cpf: c.autorCpf,
                          nome: nome,
                          foto: c.autorFoto,
                          radius: 17,
                        ),
                        title: Text(
                          nome,
                          style: theme.getTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.textColor,
                          ),
                        ),
                        subtitle: Text(
                          c.texto,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 12,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                        onTap: () => _abrirPerfilPorCpf(ctx, c.autorCpf),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
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
    final somaOrigens = origens.values.fold<int>(0, (a, b) => a + b);

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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardBackgroundColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumo de Alcance (toque para ver detalhes)',
                      style: theme.getTextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetrica(
                            icone: Icons.visibility_outlined,
                            rotulo: 'Visualizações',
                            valor: '$totalVis',
                            onTap: _mostrarListaVisualizadores,
                          ),
                        ),
                        Expanded(
                          child: _buildMetrica(
                            icone: Icons.timer_outlined,
                            rotulo: 'Tempo médio',
                            valor: _formatarTempo(
                              _pub.tempoMedioVisualizacaoSegundos,
                            ),
                            onTap: _mostrarGraficoTempoEngajamento,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetrica(
                            icone: Icons.thumb_up_off_alt_rounded,
                            rotulo: 'Likes',
                            valor: '$likesCount',
                            onTap: () =>
                                DialogOpcoesPublicacao.mostrarListaReacoes(
                              context,
                              theme: theme,
                              reacoes: _reacoes,
                              tipo: TipoReacaoSocial.like,
                            ),
                          ),
                        ),
                        Expanded(
                          child: _buildMetrica(
                            icone: Icons.mode_comment_outlined,
                            rotulo: 'Comentários',
                            valor: '$comentariosCount',
                            onTap: _mostrarListaComentarios,
                          ),
                        ),
                        Expanded(
                          child: _buildMetrica(
                            icone: Icons.thumb_down_off_alt_rounded,
                            rotulo: 'Deslikes',
                            valor: '$deslikesCount',
                            onTap: () =>
                                DialogOpcoesPublicacao.mostrarListaReacoes(
                              context,
                              theme: theme,
                              reacoes: _reacoes,
                              tipo: TipoReacaoSocial.deslike,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardBackgroundColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Por onde a publicação foi vista',
                      style: theme.getTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final entry in origens.entries) ...[
                      _buildBarraOrigem(
                        rotulo: entry.key,
                        valor: entry.value,
                        total: somaOrigens > 0 ? somaOrigens : 1,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetrica({
    required IconData icone,
    required String rotulo,
    required String valor,
    VoidCallback? onTap,
  }) {
    final theme = widget.theme;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: theme.backgroundColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.borderColor.withValues(alpha: 0.45)),
        ),
        child: Column(
          children: [
            Icon(icone, size: 18, color: theme.textColor),
            const SizedBox(height: 6),
            Text(
              valor,
              style: theme.getTextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              rotulo,
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 11,
                color: theme.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarraOrigem({
    required String rotulo,
    required int valor,
    required int total,
  }) {
    final theme = widget.theme;
    final fracao = (valor / total).clamp(0.0, 1.0);
    final pct = (fracao * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              rotulo,
              style: theme.getTextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.textColor,
              ),
            ),
            Text(
              '$valor ($pct%)',
              style: theme.getTextStyle(
                fontSize: 12,
                color: theme.secondaryTextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fracao,
            minHeight: 7,
            backgroundColor: theme.borderColor.withValues(alpha: 0.25),
            valueColor: AlwaysStoppedAnimation<Color>(theme.buttonColor),
          ),
        ),
      ],
    );
  }
}
