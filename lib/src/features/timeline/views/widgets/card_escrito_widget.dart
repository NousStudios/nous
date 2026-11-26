import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/auth/views/perfil_social_view.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/services/timeline_repositorio_sqlite.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_denuncia_social.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_detalhes_publicacao.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_editar_publicacao.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_opcoes_publicacao.dart';
import 'package:nous/src/features/timeline/views/insights_publicacao_view.dart';
import 'package:nous/src/features/timeline/views/widgets/card_escrito/card_escrito_cabecalho_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/card_escrito/card_escrito_citacao_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/card_escrito/card_escrito_rodape_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/texto_com_hashtags_widget.dart';

/// Card da timeline de "Escritos" no padrão visual do Nous,
/// com layout inspirado em microblog/tweet: cabeçalho (avatar, nome e @username),
/// texto com hashtags/menções clicáveis, data/hora, contadores clicáveis e barra de ações.
class CardEscritoWidget extends StatefulWidget {
  final AppTheme theme;
  final PublicacaoSocial publicacao;
  final UsuarioNous? usuarioLogado;
  final List<PublicacaoSocial>? listaPublicacoes;
  final int indiceInicial;
  final ValueChanged<String>? onTapTag;
  final bool abrirDetalhesAoTocarCabecalho;

  const CardEscritoWidget({
    super.key,
    required this.theme,
    required this.publicacao,
    required this.usuarioLogado,
    this.listaPublicacoes,
    this.indiceInicial = 0,
    this.onTapTag,
    this.abrirDetalhesAoTocarCabecalho = false,
  });

  @override
  State<CardEscritoWidget> createState() => _CardEscritoWidgetState();
}

class _CardEscritoWidgetState extends State<CardEscritoWidget> {
  late PublicacaoSocial _pub;
  List<ReacaoSocial> _reacoes = [];
  int _totalComentarios = 0;
  int _totalRepublicacoes = 0;
  UsuarioNous? _autorResolvido;
  PublicacaoSocial? _publicacaoCitada;
  List<UsuarioNous> _coautoresResolvidos = [];

  @override
  void initState() {
    super.initState();
    _pub = widget.publicacao;
    _carregarDados();
    TimelineService.alteracoesTimelineNotifier.addListener(_onAlteracao);
  }

  @override
  void didUpdateWidget(covariant CardEscritoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.publicacao.id != widget.publicacao.id ||
        oldWidget.publicacao.texto != widget.publicacao.texto ||
        oldWidget.publicacao.fixada != widget.publicacao.fixada) {
      _pub = widget.publicacao;
      _carregarDados();
    }
  }

  @override
  void dispose() {
    TimelineService.alteracoesTimelineNotifier.removeListener(_onAlteracao);
    super.dispose();
  }

  void _onAlteracao() {
    if (mounted) _carregarDados();
  }

  UsuarioNous? _obterUsuarioEfetivo() {
    if (widget.usuarioLogado != null) return widget.usuarioLogado;
    try {
      final auth = context.read<AuthProvider>();
      if (auth.contaAtual != null) return auth.contaAtual;
      if (auth.cpf.isNotEmpty) {
        return UsuarioNous(
          cpf: auth.cpf,
          nome: 'Cidadão Nous',
          dataNascimento: '',
        );
      }
    } catch (_) {}
    return null;
  }

  Future<void> _carregarDados() async {
    final reacoes = await TimelineService.listarReacoes(_pub.id);
    final comentarios = await TimelineService.listarComentarios(_pub.id);
    final todasPubs = await TimelineService.listarPublicacoesDescoberta();
    final totalReps = todasPubs
        .where((p) => !p.excluida && p.publicacaoOriginalId == _pub.id)
        .length;

    final cpfAutor = _pub.autorCpf.replaceAll(RegExp(r'\D'), '');
    final autor = cpfAutor.isNotEmpty
        ? await ContasNousService.buscarPorCpf(cpfAutor)
        : null;

    final coautores = <UsuarioNous>[];
    if (_pub.coautoresCpfs.isNotEmpty) {
      final todas = await ContasNousService.carregarTodas();
      for (final cpf in _pub.coautoresCpfs) {
        final limpo = cpf.replaceAll(RegExp(r'\D'), '');
        final u = todas
            .where((c) => c.cpf.replaceAll(RegExp(r'\D'), '') == limpo)
            .firstOrNull;
        coautores.add(
          u ??
              UsuarioNous(
                cpf: limpo,
                nome: 'Colaborador',
                dataNascimento: '',
              ),
        );
      }
    }

    final PublicacaoSocial? citada = _pub.publicacaoOriginalId.isNotEmpty
        ? await TimelineRepositorioSqlite.buscarPublicacaoPorId(
            _pub.publicacaoOriginalId,
          )
        : null;

    if (!mounted) return;
    setState(() {
      _reacoes = reacoes;
      _totalComentarios = comentarios.where((c) => !c.excluido).length;
      _totalRepublicacoes = totalReps;
      _autorResolvido = autor;
      _publicacaoCitada = citada;
      _coautoresResolvidos = coautores;
    });
  }

  Future<void> _reagir(TipoReacaoSocial tipo) async {
    final u = _obterUsuarioEfetivo();
    if (u == null) return;
    await TimelineService.alternarReacao(
      publicacaoId: _pub.id,
      usuarioCpf: u.cpf,
      usuarioNome: u.nomeExibicao,
      usuarioFoto: u.fotoExibicao,
      tipo: tipo,
    );
    await _carregarDados();
  }

  void _abrirDetalhes() {
    DialogDetalhesPublicacao.mostrar(
      context,
      theme: widget.theme,
      publicacao: _pub,
      usuarioLogado: _obterUsuarioEfetivo(),
      listaPublicacoes: widget.listaPublicacoes,
      indiceInicial: widget.indiceInicial,
    );
  }

  Future<void> _visitarAutor() async {
    final conta = _autorResolvido ??
        await ContasNousService.buscarPorCpf(
          _pub.autorCpf.replaceAll(RegExp(r'\D'), ''),
        );
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

  Future<void> _abrirMenuOpcoes(bool ehAutor) async {
    final theme = widget.theme;
    final u = _obterUsuarioEfetivo();
    final acao = await DialogOpcoesPublicacao.mostrarMenuOpcoes(
      context,
      theme: theme,
      publicacao: _pub,
      ehAutor: ehAutor,
      podeDenunciar: !ehAutor && u != null,
    );
    if (!mounted || acao == null) return;

    if (acao == 'editar') {
      final atualizada = await DialogEditarPublicacao.mostrar(
        context,
        theme: theme,
        publicacao: _pub,
      );
      if (atualizada != null && mounted) {
        setState(() => _pub = atualizada);
      }
    } else if (acao == 'fixar') {
      await TimelineService.alternarFixarPublicacao(_pub);
    } else if (acao == 'insights') {
      final likes =
          _reacoes.where((r) => r.tipo == TipoReacaoSocial.like).length;
      final deslikes =
          _reacoes.where((r) => r.tipo == TipoReacaoSocial.deslike).length;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InsightsPublicacaoView(
            theme: theme,
            publicacao: _pub,
            totalCurtidas: likes,
            totalDeslikes: deslikes,
            totalComentarios: _totalComentarios,
          ),
        ),
      );
    } else if (acao == 'excluir') {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          title: Text(
            'Excluir escrito?',
            style: theme.getTextStyle(
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: Text(
            'O escrito será removido do perfil público.',
            style: theme.getTextStyle(color: theme.secondaryTextColor),
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
                style: TextStyle(color: theme.dangerColor),
              ),
            ),
          ],
        ),
      );
      if (confirmar == true) {
        await TimelineService.excluirPublicacao(_pub);
      }
    } else if (acao == 'denunciar' && u != null) {
      await DialogDenunciaSocial.mostrar(
        context,
        theme: theme,
        denunciante: u,
        publicacaoId: _pub.id,
        alvoCpf: _pub.autorCpf,
        alvoNome: _pub.autorNome,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final pub = _pub;
    final u = _obterUsuarioEfetivo();
    final meuCpf = (u?.cpf ?? '').replaceAll(RegExp(r'\D'), '');
    final ehAutor =
        meuCpf.isNotEmpty &&
        meuCpf == pub.autorCpf.replaceAll(RegExp(r'\D'), '');

    return Card(
      color: theme.cardBackgroundColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.borderColor.withValues(alpha: 0.40),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _abrirDetalhes,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Cabeçalho estilo tweet: Avatar + Nome + @username + (...)
              CardEscritoCabecalhoWidget(
                theme: theme,
                publicacao: pub,
                autorResolvido: _autorResolvido,
                coautoresResolvidos: _coautoresResolvidos,
                ehAutor: ehAutor,
                abrirDetalhesAoTocarCabecalho:
                    widget.abrirDetalhesAoTocarCabecalho,
                onAbrirDetalhes: _abrirDetalhes,
                onVisitarAutor: _visitarAutor,
                onAbrirMenuOpcoes: () => _abrirMenuOpcoes(ehAutor),
              ),

              // 2. Corpo do escrito rente ao início do nome e @username
              if (pub.texto.isNotEmpty) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 50),
                  child: TextoComHashtagsWidget(
                    theme: theme,
                    texto: pub.texto,
                    fontSize: 15,
                    onTapTag: widget.onTapTag,
                  ),
                ),
              ],

              // 2b. Publicação citada (quando for citação / quote)
              if (_publicacaoCitada != null && !_publicacaoCitada!.excluida) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 50),
                  child: CardEscritoCitacaoWidget(
                    theme: theme,
                    publicacaoCitada: _publicacaoCitada!,
                    usuarioLogado: u,
                  ),
                ),
              ],

              // 3, 4 e 5. Visualizações, contadores clicáveis e barra de ações
              CardEscritoRodapeWidget(
                theme: theme,
                publicacao: pub,
                usuarioLogado: u,
                reacoes: _reacoes,
                totalComentarios: _totalComentarios,
                totalRepublicacoes: _totalRepublicacoes,
                onReagir: _reagir,
                onAbrirDetalhes: _abrirDetalhes,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
