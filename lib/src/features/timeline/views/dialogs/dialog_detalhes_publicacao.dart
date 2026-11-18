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
import 'package:nous/src/features/timeline/views/widgets/arvore_comentarios_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/cabecalho_autor_colaboradores_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/carrossel_fotos_publicacao.dart';

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
    if (acao == 'editar') {
      await _editarPublicacao();
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

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabeçalho com Avatar do Autor + Colaboradores e botão Fechar
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: CabecalhoAutorColaboradoresWidget(
                          theme: theme,
                          publicacao: pub,
                          coautoresResolvidos: _coautoresResolvidos,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: theme.secondaryTextColor,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
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
                          _buildMidias(theme, pub),
                          const SizedBox(height: 10),
                        ],

                        // Linha de Ícones de Interação + Ícone de Mais Opções (Editar/Excluir) à direita (acima da legenda)
                        Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  // Pílula Like
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.35),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: theme.borderColor.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: () =>
                                              _reagir(TipoReacaoSocial.like),
                                          child: Icon(
                                            minhaReacao?.tipo ==
                                                    TipoReacaoSocial.like
                                                ? Icons.thumb_up_alt_rounded
                                                : Icons
                                                    .thumb_up_off_alt_rounded,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        InkWell(
                                          onTap: () => _mostrarListaReacoes(
                                            TipoReacaoSocial.like,
                                          ),
                                          child: Text(
                                            '$likes',
                                            style: theme.getTextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Pílula Deslike
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.35),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: theme.borderColor.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: () =>
                                              _reagir(TipoReacaoSocial.deslike),
                                          child: Icon(
                                            minhaReacao?.tipo ==
                                                    TipoReacaoSocial.deslike
                                                ? Icons.thumb_down_alt_rounded
                                                : Icons
                                                    .thumb_down_off_alt_rounded,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        InkWell(
                                          onTap: () => _mostrarListaReacoes(
                                            TipoReacaoSocial.deslike,
                                          ),
                                          child: Text(
                                            '$deslikes',
                                            style: theme.getTextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Republicar no meu perfil',
                                    icon: Icon(
                                      Icons.repeat_rounded,
                                      color: theme.textColor,
                                    ),
                                    onPressed: _republicar,
                                  ),
                                  if (usuarioEfetivo != null)
                                    IconButton(
                                      tooltip: 'Salvar conteúdo',
                                      icon: Icon(
                                        Icons.bookmark_border_rounded,
                                        color: theme.textColor,
                                      ),
                                      onPressed: () async {
                                        final salvo =
                                            await DialogSalvarPublicacao
                                                .mostrar(
                                          context,
                                          theme: theme,
                                          usuarioCpf: usuarioEfetivo.cpf,
                                          publicacaoId: pub.id,
                                        );
                                        if (salvo == true && context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text('Conteúdo salvo!'),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  IconButton(
                                    tooltip: 'Enviar pelo chat',
                                    icon: Icon(
                                      Icons.send_rounded,
                                      color: theme.textColor,
                                    ),
                                    onPressed: _enviarNoChat,
                                  ),
                                ],
                              ),
                            ),
                            // Ícone à direita na mesma linha dos ícones de interação (Editar/Excluir/Opções)
                            IconButton(
                              tooltip: 'Mais opções da publicação',
                              icon: Icon(
                                Icons.more_horiz_rounded,
                                color: theme.textColor,
                              ),
                              onPressed: () =>
                                  _abrirMenuOpcoesPublicacao(ehAutor),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),
                        if (pub.texto.isNotEmpty) ...[
                          Text(
                            pub.texto,
                            style: theme.getTextStyle(
                              fontSize: 14,
                              color: theme.textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Builder(
                          builder: (_) {
                            final l = pub.criadaEm.toLocal();
                            final d = l.day.toString().padLeft(2, '0');
                            final m = l.month.toString().padLeft(2, '0');
                            final h = l.hour.toString().padLeft(2, '0');
                            final min = l.minute.toString().padLeft(2, '0');
                            return Text(
                              '$d/$m/${l.year} às $h:$min',
                              style: theme.getTextStyle(
                                fontSize: 11,
                                color: theme.secondaryTextColor,
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // Cabeçalho de Comentários + Botão Mapa Mental
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
                                  await TimelineService.alternarFixarComentario(
                                    c,
                                  );
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
                        const SizedBox(height: 8),

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
                              await TimelineService.alternarFixarComentario(
                                alvo,
                              );
                              await _carregarInteracoes();
                            },
                            onExcluir: (alvo) async {
                              await TimelineService.excluirComentario(alvo);
                              await _carregarInteracoes();
                            },
                          ),
                      ],
                    ),
                  ),
                ),

                // Barra de envio de comentário ou sub-resposta
                if (usuarioEfetivo != null)
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    decoration: BoxDecoration(
                      color: theme.cardBackgroundColor,
                      border: Border(
                        top: BorderSide(
                          color: theme.borderColor.withValues(alpha: 0.4),
                        ),
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
                                Icon(
                                  Icons.reply_rounded,
                                  size: 15,
                                  color: theme.buttonColor,
                                ),
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
                                  onTap: () => setState(
                                    () => _respondendoAComentario = null,
                                  ),
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
                                    borderSide: BorderSide(
                                      color: theme.borderColor,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(
                                      color: theme.borderColor,
                                    ),
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
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMidias(AppTheme theme, PublicacaoSocial pub) {
    if (pub.tipo == TipoFeedSocial.fotos) {
      return CarrosselFotosPublicacao(
        theme: theme,
        midias: pub.midias,
        aspectRatio: pub.aspectRatioEfetivo,
        alignment: Alignment(pub.alinhamentoX, pub.alinhamentoY),
        escalaZoomPadrao: pub.escalaZoom,
        onDoubleTapLike: () => _reagir(TipoReacaoSocial.like),
      );
    }

    return Column(
      children: pub.midias.map((m) {
        return ListTile(
          leading: Icon(
            pub.tipo == TipoFeedSocial.videos
                ? Icons.play_circle_outline_rounded
                : pub.tipo == TipoFeedSocial.musicas
                    ? Icons.music_note_outlined
                    : Icons.description_outlined,
            color: theme.buttonColor,
          ),
          title: Text(
            m.nomeArquivo,
            style: theme.getTextStyle(fontSize: 13, color: theme.textColor),
          ),
        );
      }).toList(),
    );
  }
}
