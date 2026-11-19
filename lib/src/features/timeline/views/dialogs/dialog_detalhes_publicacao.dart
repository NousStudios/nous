import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_denuncia_social.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_enviar_publicacao_chat.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_mapa_comentarios.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_opcoes_publicacao.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_salvar_publicacao.dart';
import 'package:nous/src/features/timeline/views/insights_publicacao_view.dart';
import 'package:nous/src/features/timeline/views/widgets/arvore_comentarios_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/texto_com_hashtags_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/cabecalho_autor_colaboradores_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/carrossel_fotos_publicacao.dart';
import 'package:nous/src/features/timeline/views/widgets/widget_midia_publicacao.dart';

class DialogDetalhesPublicacao extends StatefulWidget {
  final AppTheme theme;
  final PublicacaoSocial publicacao;
  final UsuarioNous? usuarioLogado;

  const DialogDetalhesPublicacao({
    super.key,
    required this.theme,
    required this.publicacao,
    required this.usuarioLogado,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required PublicacaoSocial publicacao,
    required UsuarioNous? usuarioLogado,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => DialogDetalhesPublicacao(
          theme: theme,
          publicacao: publicacao,
          usuarioLogado: usuarioLogado,
        ),
      ),
    );
  }

  @override
  State<DialogDetalhesPublicacao> createState() =>
      _DialogDetalhesPublicacaoState();
}

class _DialogDetalhesPublicacaoState extends State<DialogDetalhesPublicacao> {
  final TextEditingController _comentarioCtrl = TextEditingController();
  final FocusNode _comentarioFocus = FocusNode();
  late PublicacaoSocial _pub;
  List<ReacaoSocial> _reacoes = [];
  List<ComentarioSocial> _comentarios = [];
  List<UsuarioNous> _coautoresResolvidos = [];
  ComentarioSocial? _respondendoAComentario;
  bool _baixando = false;

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

  @override
  void initState() {
    super.initState();
    _pub = widget.publicacao;
    _carregarInteracoes();
    _carregarCoautores();
    TimelineService.alteracoesTimelineNotifier
        .addListener(_onTimelineAtualizada);
  }

  @override
  void dispose() {
    TimelineService.alteracoesTimelineNotifier
        .removeListener(_onTimelineAtualizada);
    _comentarioCtrl.dispose();
    _comentarioFocus.dispose();
    super.dispose();
  }

  void _onTimelineAtualizada() {
    if (mounted) _carregarInteracoes();
  }

  Future<void> _carregarCoautores() async {
    if (_pub.coautoresCpfs.isEmpty) return;
    final todas = await ContasNousService.carregarTodas();
    final lista = <UsuarioNous>[];
    for (final cpf in _pub.coautoresCpfs) {
      final limpo = cpf.replaceAll(RegExp(r'\D'), '');
      final u = todas
          .where((c) => c.cpf.replaceAll(RegExp(r'\D'), '') == limpo)
          .firstOrNull;
      lista.add(
        u ??
            UsuarioNous(
              cpf: limpo,
              nome: 'Colaborador',
              dataNascimento: '',
            ),
      );
    }
    if (mounted) {
      setState(() => _coautoresResolvidos = lista);
    }
  }

  Future<void> _carregarInteracoes() async {
    final reacoes = await TimelineService.listarReacoes(_pub.id);
    final comentarios = await TimelineService.listarComentarios(_pub.id);
    if (!mounted) return;
    setState(() {
      _reacoes = reacoes;
      _comentarios = comentarios;
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
    await _carregarInteracoes();
  }

  Future<void> _enviarComentario() async {
    final u = _obterUsuarioEfetivo();
    final texto = _comentarioCtrl.text.trim();
    if (u == null || texto.isEmpty) return;
    final respId = _respondendoAComentario?.id ?? '';
    _comentarioCtrl.clear();
    setState(() => _respondendoAComentario = null);
    await TimelineService.adicionarComentario(
      publicacaoId: _pub.id,
      autorCpf: u.cpf,
      autorNome: u.nomeExibicao,
      autorFoto: u.fotoExibicao,
      texto: texto,
      respostaDeId: respId,
    );
    await _carregarInteracoes();
  }

  Future<void> _republicar() async {
    final u = _obterUsuarioEfetivo();
    if (u == null) return;
    await TimelineService.republicar(
      original: _pub,
      meuCpf: u.cpf,
      meuNome: u.nomeExibicao,
      minhaFoto: u.fotoExibicao,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicação republicada no seu perfil!')),
      );
    }
  }

  Future<void> _enviarNoChat() async {
    final u = _obterUsuarioEfetivo();
    if (u == null) return;
    final enviou = await DialogEnviarPublicacaoChat.mostrar(
      context,
      theme: widget.theme,
      publicacao: _pub,
      remetente: u,
    );
    if (enviou == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicação enviada pelo chat!')),
      );
    }
  }

  Future<void> _baixarPrimeiraMidia() async {
    if (_pub.midias.isEmpty || _baixando) return;
    setState(() => _baixando = true);
    final salvo = await TimelineService.baixarMidia(_pub.midias.first);
    if (mounted) {
      setState(() => _baixando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            salvo != null
                ? 'Arquivo salvo em: $salvo'
                : 'Não foi possível baixar o arquivo.',
          ),
        ),
      );
    }
  }

  Future<void> _editarPublicacao() async {
    final theme = widget.theme;
    final editCtrl = TextEditingController(text: _pub.texto);
    final novoTexto = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        title: Text(
          'Editar Publicação',
          textAlign: TextAlign.center,
          style: theme.getTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        content: ThemedTextField(
          theme: theme,
          controller: editCtrl,
          linhas: 4,
          label: 'Legenda ou texto',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(editCtrl.text),
            child: Text(
              'Salvar',
              style: theme.getTextStyle(
                color: theme.buttonColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    editCtrl.dispose();
    if (novoTexto != null) {
      final atualizada = await TimelineService.editarPublicacao(
        _pub,
        novoTexto: novoTexto,
      );
      if (mounted) setState(() => _pub = atualizada);
    }
  }

  Future<void> _excluirPublicacao() async {
    final theme = widget.theme;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        title: Text(
          'Excluir Publicação',
          textAlign: TextAlign.center,
          style: theme.getTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        content: Text(
          'Tem certeza que deseja excluir esta publicação?',
          style: theme.getTextStyle(
            fontSize: 13,
            color: theme.secondaryTextColor,
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
              style: theme.getTextStyle(
                color: theme.dangerColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await TimelineService.excluirPublicacao(_pub);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _abrirMenuOpcoesPublicacao(bool ehAutor) async {
    final theme = widget.theme;
    final u = _obterUsuarioEfetivo();

    final acao = await DialogOpcoesPublicacao.mostrarMenuOpcoes(
      context,
      theme: theme,
      publicacao: _pub,
      ehAutor: ehAutor,
      podeDenunciar: u != null,
    );

    if (!mounted || acao == null) return;
    if (acao == 'fixar') {
      final atualizada = await TimelineService.alternarFixarPublicacao(_pub);
      if (mounted) {
        setState(() => _pub = atualizada);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              atualizada.fixada
                  ? 'Publicação fixada no topo!'
                  : 'Publicação desafixada.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else if (acao == 'editar') {
      await _editarPublicacao();
    } else if (acao == 'arquivar') {
      await TimelineService.arquivarPublicacao(
        _pub,
        arquivar: !_pub.arquivada,
      );
      if (mounted) Navigator.of(context).pop();
    } else if (acao == 'excluir') {
      await _excluirPublicacao();
    } else if (acao == 'baixar') {
      await _baixarPrimeiraMidia();
    } else if (acao == 'denunciar' && u != null) {
      final ok = await DialogDenunciaSocial.mostrar(
        context,
        theme: theme,
        denunciante: u,
        alvoCpf: _pub.autorCpf,
        alvoNome: _pub.autorNome,
        publicacaoId: _pub.id,
      );
      if (ok == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Denúncia registrada.')),
        );
      }
    }
  }

  void _mostrarListaReacoes(TipoReacaoSocial tipo) {
    DialogOpcoesPublicacao.mostrarListaReacoes(
      context,
      theme: widget.theme,
      reacoes: _reacoes,
      tipo: tipo,
    );
  }

  String _formatarDataHora(DateTime dt) {
    final l = dt.toLocal();
    final d = l.day.toString().padLeft(2, '0');
    final m = l.month.toString().padLeft(2, '0');
    final h = l.hour.toString().padLeft(2, '0');
    final min = l.minute.toString().padLeft(2, '0');
    return '$d/$m/${l.year} • $h:$min';
  }

  Widget _buildBotaoReacaoSemBorda({
    required AppTheme theme,
    required IconData icone,
    required int contagem,
    required VoidCallback onTapIcone,
    required VoidCallback onTapContagem,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTapIcone,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(icone, size: 19, color: theme.textColor),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTapContagem,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Text(
                '$contagem',
                style: theme.getTextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarraAcoes({
    required AppTheme theme,
    required PublicacaoSocial pub,
    required UsuarioNous? usuarioEfetivo,
    required int likes,
    required int deslikes,
    required ReacaoSocial? minhaReacao,
  }) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBotaoReacaoSemBorda(
                  theme: theme,
                  icone: minhaReacao?.tipo == TipoReacaoSocial.like
                      ? Icons.thumb_up_alt_rounded
                      : Icons.thumb_up_off_alt_rounded,
                  contagem: likes,
                  onTapIcone: () => _reagir(TipoReacaoSocial.like),
                  onTapContagem: () =>
                      _mostrarListaReacoes(TipoReacaoSocial.like),
                ),
                const SizedBox(width: 4),
                _buildBotaoReacaoSemBorda(
                  theme: theme,
                  icone: minhaReacao?.tipo == TipoReacaoSocial.deslike
                      ? Icons.thumb_down_alt_rounded
                      : Icons.thumb_down_off_alt_rounded,
                  contagem: deslikes,
                  onTapIcone: () => _reagir(TipoReacaoSocial.deslike),
                  onTapContagem: () =>
                      _mostrarListaReacoes(TipoReacaoSocial.deslike),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                  tooltip: 'Republicar no meu perfil',
                  icon: Icon(
                    Icons.repeat_rounded,
                    size: 19,
                    color: theme.textColor,
                  ),
                  onPressed: _republicar,
                ),
                if (usuarioEfetivo != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    tooltip: 'Salvar conteúdo',
                    icon: Icon(
                      Icons.bookmark_border_rounded,
                      size: 19,
                      color: theme.textColor,
                    ),
                    onPressed: () async {
                      final salvo = await DialogSalvarPublicacao.mostrar(
                        context,
                        theme: theme,
                        usuarioCpf: usuarioEfetivo.cpf,
                        publicacaoId: pub.id,
                      );
                      if (salvo == true && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Conteúdo salvo!'),
                          ),
                        );
                      }
                    },
                  ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                  tooltip: 'Enviar pelo chat',
                  icon: Icon(
                    Icons.send_rounded,
                    size: 18,
                    color: theme.textColor,
                  ),
                  onPressed: _enviarNoChat,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => InsightsPublicacaoView.abrir(
            context,
            theme: theme,
            publicacao: pub,
            totalCurtidas: likes,
            totalDeslikes: deslikes,
            totalComentarios: _comentarios.length,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.visibility_outlined,
                  size: 13,
                  color: theme.secondaryTextColor,
                ),
                const SizedBox(width: 3),
                Text(
                  '${pub.visualizacoes}',
                  style: theme.getTextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          _formatarDataHora(pub.criadaEm),
          style: theme.getTextStyle(
            fontSize: 10.5,
            color: theme.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSecaoComentarios({
    required AppTheme theme,
    required PublicacaoSocial pub,
    required List<ComentarioSocial> comentariosRaiz,
    required bool ehAutor,
    required String meuCpf,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Comentários (${_comentarios.length})',
              style: theme.getTextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
            TextButton.icon(
              onPressed: () => DialogMapaComentarios.mostrar(
                context,
                theme: theme,
                publicacao: pub,
                comentarios: _comentarios,
                ehAutorPublicacao: ehAutor,
                meuCpfLimpo: meuCpf,
                onResponder: (c) {
                  setState(() => _respondendoAComentario = c);
                  _comentarioFocus.requestFocus();
                },
                onAlternarFixar: (c) async {
                  await TimelineService.alternarFixarComentario(c);
                  await _carregarInteracoes();
                },
                onExcluir: (c) async {
                  await TimelineService.excluirComentario(c);
                  await _carregarInteracoes();
                },
              ),
              icon: Icon(
                Icons.account_tree_outlined,
                size: 16,
                color: theme.buttonColor,
              ),
              label: Text(
                'Mapa da Conversa',
                style: theme.getTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.buttonColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (final c in comentariosRaiz)
          ArvoreComentariosWidget(
            theme: theme,
            todosComentarios: _comentarios,
            comentario: c,
            ehAutorPublicacao: ehAutor,
            meuCpf: meuCpf,
            onResponder: (alvo) {
              setState(() => _respondendoAComentario = alvo);
              _comentarioFocus.requestFocus();
            },
            onAlternarFixar: (alvo) async {
              await TimelineService.alternarFixarComentario(alvo);
              await _carregarInteracoes();
            },
            onExcluir: (alvo) async {
              await TimelineService.excluirComentario(alvo);
              await _carregarInteracoes();
            },
          ),
      ],
    );
  }

  Widget _buildBarraInputComentario(AppTheme theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        border: Border(
          top: BorderSide(color: theme.borderColor.withValues(alpha: 0.4)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_respondendoAComentario != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.reply_rounded, size: 15, color: theme.buttonColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Respondendo a ${_respondendoAComentario!.autorNome}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.getTextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: theme.buttonColor,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () =>
                        setState(() => _respondendoAComentario = null),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _comentarioCtrl,
                  focusNode: _comentarioFocus,
                  onSubmitted: (_) => _enviarComentario(),
                  style: theme.getTextStyle(
                    fontSize: 13.5,
                    color: theme.textColor,
                  ),
                  decoration: InputDecoration(
                    hintText: _respondendoAComentario != null
                        ? 'Escrever sub-resposta...'
                        : 'Escrever um comentário...',
                    hintStyle: theme.getTextStyle(
                      fontSize: 12.5,
                      color: theme.secondaryTextColor,
                    ),
                    filled: true,
                    fillColor: theme.backgroundColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: theme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: theme.borderColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.buttonColor,
                  foregroundColor: theme.buttonTextColor,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(11),
                  minimumSize: const Size(42, 42),
                ),
                onPressed: _enviarComentario,
                child: Icon(
                  Icons.send_rounded,
                  size: 18,
                  color: theme.buttonTextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final pub = _pub;
    final usuarioEfetivo = _obterUsuarioEfetivo();
    final meuCpf =
        (usuarioEfetivo?.cpf ?? '').replaceAll(RegExp(r'\D'), '');
    final ehAutor =
        meuCpf.isNotEmpty &&
        meuCpf == pub.autorCpf.replaceAll(RegExp(r'\D'), '');

    final likes = _reacoes.where((r) => r.tipo == TipoReacaoSocial.like).length;
    final deslikes =
        _reacoes.where((r) => r.tipo == TipoReacaoSocial.deslike).length;
    final minhaReacao = _reacoes
        .where((r) => r.usuarioCpf.replaceAll(RegExp(r'\D'), '') == meuCpf)
        .firstOrNull;

    final idsComentarios = _comentarios.map((c) => c.id).toSet();
    final comentariosRaiz = _comentarios
        .where(
          (c) =>
              !c.excluido &&
              (c.respostaDeId.isEmpty ||
                  !idsComentarios.contains(c.respostaDeId)),
        )
        .toList()
      ..sort((a, b) {
        if (a.fixado != b.fixado) return a.fixado ? -1 : 1;
        return a.criadaEm.compareTo(b.criadaEm);
      });

    final ehDesktop = MediaQuery.sizeOf(context).width >= 820;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ehDesktop ? 1080 : 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Linha superior: seta à esquerda + nome da página
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 6, 12, 4),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Voltar',
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: theme.textColor,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Publicação',
                        style: theme.getTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: theme.borderColor.withValues(alpha: 0.4),
                ),

                if (ehDesktop)
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (pub.midias.isNotEmpty)
                          Expanded(
                            flex: 3,
                            child: Container(
                              color: theme.cardBackgroundColor
                                  .withValues(alpha: 0.3),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(12),
                              child: _buildMidias(
                                theme,
                                pub,
                                ajustarTelaCheia: true,
                              ),
                            ),
                          ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              border: pub.midias.isNotEmpty
                                  ? Border(
                                      left: BorderSide(
                                        color: theme.borderColor
                                            .withValues(alpha: 0.4),
                                      ),
                                    )
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(12, 10, 6, 8),
                                  child: CabecalhoAutorColaboradoresWidget(
                                    theme: theme,
                                    publicacao: pub,
                                    coautoresResolvidos: _coautoresResolvidos,
                                    trailing: IconButton(
                                      visualDensity: VisualDensity.compact,
                                      tooltip: 'Mais opções da publicação',
                                      icon: Icon(
                                        Icons.more_horiz_rounded,
                                        color: theme.textColor,
                                      ),
                                      onPressed: () =>
                                          _abrirMenuOpcoesPublicacao(ehAutor),
                                    ),
                                  ),
                                ),
                                Divider(
                                  height: 1,
                                  color:
                                      theme.borderColor.withValues(alpha: 0.3),
                                ),
                                Expanded(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        if (pub.texto.isNotEmpty) ...[
                                          TextoComHashtagsWidget(
                                            theme: theme,
                                            texto: pub.texto,
                                            fontSize: 13.5,
                                          ),
                                          const SizedBox(height: 12),
                                        ],
                                        _buildSecaoComentarios(
                                          theme: theme,
                                          pub: pub,
                                          comentariosRaiz: comentariosRaiz,
                                          ehAutor: ehAutor,
                                          meuCpf: meuCpf,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Divider(
                                  height: 1,
                                  color:
                                      theme.borderColor.withValues(alpha: 0.3),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 4, 12, 4),
                                  child: _buildBarraAcoes(
                                    theme: theme,
                                    pub: pub,
                                    usuarioEfetivo: usuarioEfetivo,
                                    likes: likes,
                                    deslikes: deslikes,
                                    minhaReacao: minhaReacao,
                                  ),
                                ),
                                if (usuarioEfetivo != null)
                                  _buildBarraInputComentario(theme),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  // Cabeçalho Autor + Colaboradores + 3 pontos à direita
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 6, 8),
                    child: CabecalhoAutorColaboradoresWidget(
                      theme: theme,
                      publicacao: pub,
                      coautoresResolvidos: _coautoresResolvidos,
                      trailing: IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Mais opções da publicação',
                        icon: Icon(
                          Icons.more_horiz_rounded,
                          color: theme.textColor,
                        ),
                        onPressed: () => _abrirMenuOpcoesPublicacao(ehAutor),
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: theme.borderColor.withValues(alpha: 0.4),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (pub.midias.isNotEmpty) ...[
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight:
                                    MediaQuery.sizeOf(context).height * 0.50,
                              ),
                              child: _buildMidias(
                                theme,
                                pub,
                                ajustarTelaCheia: true,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          _buildBarraAcoes(
                            theme: theme,
                            pub: pub,
                            usuarioEfetivo: usuarioEfetivo,
                            likes: likes,
                            deslikes: deslikes,
                            minhaReacao: minhaReacao,
                          ),
                          const SizedBox(height: 10),
                          if (pub.texto.isNotEmpty) ...[
                            TextoComHashtagsWidget(
                              theme: theme,
                              texto: pub.texto,
                              fontSize: 14,
                            ),
                            const SizedBox(height: 14),
                          ],
                          _buildSecaoComentarios(
                            theme: theme,
                            pub: pub,
                            comentariosRaiz: comentariosRaiz,
                            ehAutor: ehAutor,
                            meuCpf: meuCpf,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (usuarioEfetivo != null) _buildBarraInputComentario(theme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMidias(
    AppTheme theme,
    PublicacaoSocial pub, {
    bool ajustarTelaCheia = false,
  }) {
    final todasFotos = pub.midias.every((m) {
      final ext = m.mimeTipo.toLowerCase();
      return ext == 'jpg' ||
          ext == 'jpeg' ||
          ext == 'png' ||
          ext == 'webp' ||
          (ext.isEmpty && pub.tipo == TipoFeedSocial.fotos);
    });
    if (todasFotos) {
      return CarrosselFotosPublicacao(
        theme: theme,
        midias: pub.midias,
        aspectRatio: pub.aspectRatioEfetivo,
        alignment: Alignment(pub.alinhamentoX, pub.alinhamentoY),
        escalaZoomPadrao: pub.escalaZoom,
        ajustarTelaCheia: ajustarTelaCheia,
        onDoubleTapLike: () => _reagir(TipoReacaoSocial.like),
      );
    }

    return WidgetMidiaPublicacao(theme: theme, publicacao: pub);
  }
}
