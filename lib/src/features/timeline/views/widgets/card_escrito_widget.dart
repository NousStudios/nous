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
import 'package:nous/src/features/timeline/views/dialogs/dialog_colaboradores_publicacao.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_denuncia_social.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_detalhes_publicacao.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_editar_publicacao.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_enviar_publicacao_chat.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_opcoes_publicacao.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_republicar_opcoes.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_salvar_publicacao.dart';
import 'package:nous/src/features/timeline/views/insights_publicacao_view.dart';
import 'package:nous/src/features/timeline/views/widgets/avatar_com_story_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/texto_com_hashtags_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/widget_midia_publicacao.dart';

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

  String _formatarDataHoraTweet(DateTime dt) {
    final l = dt.toLocal();
    final h = l.hour.toString().padLeft(2, '0');
    final min = l.minute.toString().padLeft(2, '0');
    final d = l.day.toString().padLeft(2, '0');
    final m = l.month.toString().padLeft(2, '0');
    return '$h:$min • $d/$m/${l.year}';
  }

  Widget _buildStatClicavel({
    required AppTheme theme,
    required int valor,
    required String rotulo,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$valor ',
                style: theme.getTextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              TextSpan(
                text: rotulo,
                style: theme.getTextStyle(
                  fontSize: 12.5,
                  color: theme.secondaryTextColor,
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
    final pub = _pub;
    final u = _obterUsuarioEfetivo();
    final meuCpf = (u?.cpf ?? '').replaceAll(RegExp(r'\D'), '');
    final ehAutor =
        meuCpf.isNotEmpty &&
        meuCpf == pub.autorCpf.replaceAll(RegExp(r'\D'), '');

    final likes = _reacoes.where((r) => r.tipo == TipoReacaoSocial.like).length;
    final deslikes =
        _reacoes.where((r) => r.tipo == TipoReacaoSocial.deslike).length;
    final minhaReacao = _reacoes
        .where((r) => r.usuarioCpf.replaceAll(RegExp(r'\D'), '') == meuCpf)
        .firstOrNull;

    final nomeAutor = _autorResolvido?.nomeExibicao.isNotEmpty == true
        ? _autorResolvido!.nomeExibicao
        : (pub.autorNome.isNotEmpty ? pub.autorNome : 'Cidadão Nous');
    final handleAutor = _autorResolvido?.usernameExibicao ?? '';

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
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IgnorePointer(
                    ignoring: widget.abrirDetalhesAoTocarCabecalho,
                    child: AvatarComStoryWidget(
                      theme: theme,
                      cpf: pub.autorCpf,
                      nome: nomeAutor,
                      foto: _autorResolvido?.fotoExibicao ?? pub.autorFoto,
                      radius: 20,
                      onTapSemStory: widget.abrirDetalhesAoTocarCabecalho
                          ? _abrirDetalhes
                          : _visitarAutor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: widget.abrirDetalhesAoTocarCabecalho
                          ? _abrirDetalhes
                          : _visitarAutor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  nomeAutor,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.getTextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '• ${_formatarDataHoraTweet(pub.criadaEm)}',
                                style: theme.getTextStyle(
                                  fontSize: 10.5,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                              if (_coautoresResolvidos.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () =>
                                      DialogColaboradoresPublicacao.mostrar(
                                    context,
                                    theme: theme,
                                    publicacao: pub,
                                  ),
                                  child: Text(
                                    '+ ${_coautoresResolvidos.length} colab.',
                                    style: theme.getTextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: theme.textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (handleAutor.isNotEmpty)
                            Text(
                              handleAutor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.getTextStyle(
                                fontSize: 12,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (pub.fixada)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.push_pin_rounded,
                        size: 15,
                        color: theme.textColor,
                      ),
                    ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    tooltip: 'Mais opções',
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      color: theme.secondaryTextColor,
                    ),
                    onPressed: () => _abrirMenuOpcoes(ehAutor),
                  ),
                ],
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
              if (_publicacaoCitada != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 50),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => DialogDetalhesPublicacao.mostrar(
                      context,
                      theme: theme,
                      publicacao: _publicacaoCitada!,
                      usuarioLogado: u,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.backgroundColor.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.borderColor.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AvatarComStoryWidget(
                                theme: theme,
                                cpf: _publicacaoCitada!.autorCpf,
                                nome: _publicacaoCitada!.autorNome,
                                foto: _publicacaoCitada!.autorFoto,
                                radius: 10,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _publicacaoCitada!.autorNome.isNotEmpty
                                      ? _publicacaoCitada!.autorNome
                                      : 'Publicação original',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.getTextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_publicacaoCitada!.texto.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              _publicacaoCitada!.texto,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: theme.getTextStyle(
                                fontSize: 12.5,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          ],
                          if (_publicacaoCitada!.midias.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            WidgetMidiaPublicacao(
                              theme: theme,
                              publicacao: _publicacaoCitada!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              // 3. Marcador de visualizações discreto à direita
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      size: 13.5,
                      color: theme.secondaryTextColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${pub.visualizacoes}',
                      style: theme.getTextStyle(
                        fontSize: 11.5,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Contadores clicáveis (Republicações, Likes, Deslikes, Comentários)
              if (likes > 0 ||
                  deslikes > 0 ||
                  _totalRepublicacoes > 0 ||
                  _totalComentarios > 0) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 50),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Divider(
                        height: 1,
                        color: theme.borderColor.withValues(alpha: 0.25),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          if (_totalRepublicacoes > 0)
                            _buildStatClicavel(
                              theme: theme,
                              valor: _totalRepublicacoes,
                              rotulo: _totalRepublicacoes == 1
                                  ? 'Republicação'
                                  : 'Republicações',
                            ),
                          if (likes > 0)
                            _buildStatClicavel(
                              theme: theme,
                              valor: likes,
                              rotulo: likes == 1 ? 'Like' : 'Likes',
                              onTap: () =>
                                  DialogOpcoesPublicacao.mostrarListaReacoes(
                                context,
                                theme: theme,
                                reacoes: _reacoes,
                                tipo: TipoReacaoSocial.like,
                              ),
                            ),
                          if (deslikes > 0)
                            _buildStatClicavel(
                              theme: theme,
                              valor: deslikes,
                              rotulo: deslikes == 1 ? 'Deslike' : 'Deslikes',
                              onTap: () =>
                                  DialogOpcoesPublicacao.mostrarListaReacoes(
                                context,
                                theme: theme,
                                reacoes: _reacoes,
                                tipo: TipoReacaoSocial.deslike,
                              ),
                            ),
                          if (_totalComentarios > 0)
                            _buildStatClicavel(
                              theme: theme,
                              valor: _totalComentarios,
                              rotulo: _totalComentarios == 1
                                  ? 'Comentário'
                                  : 'Comentários',
                              onTap: _abrirDetalhes,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // 5. Barra inferior: Like > Deslike > Comentário > Republicar > Enviar pelo chat > Salvar
              const SizedBox(height: 6),
              Divider(
                height: 1,
                color: theme.borderColor.withValues(alpha: 0.25),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Like',
                    icon: Icon(
                      minhaReacao?.tipo == TipoReacaoSocial.like
                          ? Icons.thumb_up_alt_rounded
                          : Icons.thumb_up_off_alt_rounded,
                      size: 18,
                      color: minhaReacao?.tipo == TipoReacaoSocial.like
                          ? theme.textColor
                          : theme.secondaryTextColor,
                    ),
                    onPressed: () => _reagir(TipoReacaoSocial.like),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Deslike',
                    icon: Icon(
                      minhaReacao?.tipo == TipoReacaoSocial.deslike
                          ? Icons.thumb_down_alt_rounded
                          : Icons.thumb_down_off_alt_rounded,
                      size: 18,
                      color: minhaReacao?.tipo == TipoReacaoSocial.deslike
                          ? theme.dangerColor
                          : theme.secondaryTextColor,
                    ),
                    onPressed: () => _reagir(TipoReacaoSocial.deslike),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Comentar',
                    icon: Icon(
                      Icons.mode_comment_outlined,
                      size: 18,
                      color: theme.secondaryTextColor,
                    ),
                    onPressed: _abrirDetalhes,
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Republicar',
                    icon: Icon(
                      Icons.repeat_rounded,
                      size: 19,
                      color: theme.secondaryTextColor,
                    ),
                    onPressed: u == null
                        ? null
                        : () => DialogRepublicarOpcoes.mostrar(
                              context,
                              theme: theme,
                              publicacao: pub,
                              usuario: u,
                            ),
                  ),
                  if (u != null) ...[
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Enviar no Chat',
                      icon: Icon(
                        Icons.send_rounded,
                        size: 17,
                        color: theme.secondaryTextColor,
                      ),
                      onPressed: () => DialogEnviarPublicacaoChat.mostrar(
                        context,
                        theme: theme,
                        publicacao: pub,
                        remetente: u,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Salvar',
                      icon: Icon(
                        Icons.bookmark_border_rounded,
                        size: 19,
                        color: theme.secondaryTextColor,
                      ),
                      onPressed: () => DialogSalvarPublicacao.mostrar(
                        context,
                        theme: theme,
                        publicacaoId: pub.id,
                        usuarioCpf: u.cpf,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
