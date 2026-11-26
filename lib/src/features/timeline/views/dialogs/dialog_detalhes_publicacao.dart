import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/player_video_nous_widget.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/services/timeline_repositorio_sqlite.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_enviar_publicacao_chat.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_republicar_opcoes.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_salvar_publicacao.dart';
import 'package:nous/src/features/timeline/views/dialogs/widgets/detalhes_publicacao/detalhes_pub_acoes_widget.dart';
import 'package:nous/src/features/timeline/views/dialogs/widgets/detalhes_publicacao/detalhes_pub_comentarios_widget.dart';
import 'package:nous/src/features/timeline/views/dialogs/widgets/detalhes_publicacao/detalhes_pub_layout_padrao_widget.dart';
import 'package:nous/src/features/timeline/views/dialogs/widgets/detalhes_publicacao/detalhes_pub_midias_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/visualizador_reels_compacto_widget.dart';

class DialogDetalhesPublicacao extends StatefulWidget {
  final AppTheme theme;
  final PublicacaoSocial publicacao;
  final UsuarioNous? usuarioLogado;
  final List<PublicacaoSocial>? listaPublicacoes;
  final int indiceInicial;

  const DialogDetalhesPublicacao({
    super.key,
    required this.theme,
    required this.publicacao,
    required this.usuarioLogado,
    this.listaPublicacoes,
    this.indiceInicial = 0,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required PublicacaoSocial publicacao,
    required UsuarioNous? usuarioLogado,
    List<PublicacaoSocial>? listaPublicacoes,
    int indiceInicial = 0,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => DialogDetalhesPublicacao(
          theme: theme,
          publicacao: publicacao,
          usuarioLogado: usuarioLogado,
          listaPublicacoes: listaPublicacoes,
          indiceInicial: indiceInicial,
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
  final GlobalKey _midiasKey = GlobalKey();
  late List<PublicacaoSocial> _lista;
  late int _indiceAtivo;
  late PageController _desktopPageController;
  late PublicacaoSocial _pub;
  List<ReacaoSocial> _reacoes = [];
  List<ComentarioSocial> _comentarios = [];
  List<PublicacaoSocial> _republicacoesPub = [];
  List<UsuarioNous> _coautoresResolvidos = [];
  ComentarioSocial? _respondendoAComentario;
  bool _baixando = false;
  bool _pdfEmTelaCheia = false;
  DateTime _inicioVisualizacao = DateTime.now();

  void _registrarTempoAtual() {
    final seg = DateTime.now().difference(_inicioVisualizacao).inSeconds;
    if (seg >= 1) {
      unawaited(
        TimelineService.registrarTempoVisualizacao(
          _pub.id,
          _obterUsuarioEfetivo()?.cpf,
          seg,
        ),
      );
    }
    _inicioVisualizacao = DateTime.now();
  }

  UsuarioNous? _obterUsuarioEfetivo() {
    if (widget.usuarioLogado != null) return widget.usuarioLogado;
    try {
      final auth = context.read<AuthProvider>();
      if (auth.contaAtual != null) return auth.contaAtual;
      if (auth.cpf.isNotEmpty) {
        return UsuarioNous(cpf: auth.cpf, nome: 'Cidadão Nous', dataNascimento: '');
      }
    } catch (_) {}
    return null;
  }

  @override
  void initState() {
    super.initState();
    _lista = (widget.listaPublicacoes != null &&
            widget.listaPublicacoes!.isNotEmpty)
        ? widget.listaPublicacoes!
        : [widget.publicacao];
    _indiceAtivo = widget.indiceInicial.clamp(0, _lista.length - 1);
    _pub = _lista[_indiceAtivo];
    _desktopPageController = PageController(initialPage: _indiceAtivo);
    _carregarInteracoes();
    _carregarCoautores();
    unawaited(
      TimelineService.registrarVisualizacaoPublicacao(
        _pub,
        origem: 'detalhes',
        visualizadorCpf: _obterUsuarioEfetivo()?.cpf,
      ),
    );
    TimelineService.alteracoesTimelineNotifier
        .addListener(_onTimelineAtualizada);
  }

  @override
  void dispose() {
    _registrarTempoAtual();
    TimelineService.alteracoesTimelineNotifier
        .removeListener(_onTimelineAtualizada);
    _desktopPageController.dispose();
    _comentarioCtrl.dispose();
    _comentarioFocus.dispose();
    super.dispose();
  }

  void _trocarPublicacao(int novoIndice) {
    if (novoIndice < 0 ||
        novoIndice >= _lista.length ||
        novoIndice == _indiceAtivo) {
      return;
    }
    PlayerVideoNousWidget.pausarTodos();
    _registrarTempoAtual();
    setState(() {
      _indiceAtivo = novoIndice;
      _pub = _lista[novoIndice];
      _reacoes = [];
      _comentarios = [];
      _republicacoesPub = [];
      _coautoresResolvidos = [];
      _respondendoAComentario = null;
      _pdfEmTelaCheia = false;
    });
    _carregarInteracoes();
    _carregarCoautores();
    unawaited(
      TimelineService.registrarVisualizacaoPublicacao(
        _pub,
        origem: 'detalhes',
        visualizadorCpf: _obterUsuarioEfetivo()?.cpf,
      ),
    );
  }

  void _onTimelineAtualizada() {
    if (!mounted) return;
    _carregarInteracoes();
    unawaited(() async {
      final mapa = await TimelineRepositorioSqlite.buscarPublicacoesPorIds([_pub.id]);
      final atual = mapa[_pub.id];
      if (!mounted) return;
      if (atual != null && atual.excluida) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      } else if (atual != null && atual.atualizadaEm != _pub.atualizadaEm) {
        setState(() => _pub = atual);
      }
    }());
  }

  Future<void> _carregarCoautores() async {
    if (_pub.coautoresCpfs.isEmpty) return;
    final todas = await ContasNousService.carregarTodas();
    final lista = _pub.coautoresCpfs.map((cpf) {
      final limpo = cpf.replaceAll(RegExp(r'\D'), '');
      return todas
              .where((c) => c.cpf.replaceAll(RegExp(r'\D'), '') == limpo)
              .firstOrNull ??
          UsuarioNous(cpf: limpo, nome: 'Colaborador', dataNascimento: '');
    }).toList();
    if (mounted) setState(() => _coautoresResolvidos = lista);
  }

  Future<void> _carregarInteracoes() async {
    final reacoes = await TimelineService.listarReacoes(_pub.id);
    final comentarios = await TimelineService.listarComentarios(_pub.id);
    final todasPubs = await TimelineService.listarPublicacoesDescoberta();
    final republicacoes = todasPubs
        .where((p) => !p.excluida && p.publicacaoOriginalId == _pub.id)
        .toList();
    if (!mounted) return;
    setState(() {
      _reacoes = reacoes;
      _comentarios = comentarios;
      _republicacoesPub = republicacoes;
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
    setState(() {
      _respondendoAComentario = null;
      _pdfEmTelaCheia = false;
    });
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
    await DialogRepublicarOpcoes.mostrar(
      context,
      theme: widget.theme,
      publicacao: _pub,
      usuario: u,
    );
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

  Future<void> _abrirMenuOpcoesPublicacao(bool ehAutor) {
    return DetalhesPubAcoesWidget.abrirMenuOpcoes(
      context,
      theme: widget.theme,
      publicacao: _pub,
      usuarioEfetivo: _obterUsuarioEfetivo(),
      ehAutor: ehAutor,
      onPublicacaoAtualizada: (atualizada) => setState(() => _pub = atualizada),
      onBaixarMidia: _baixarPrimeiraMidia,
      onFecharTela: () => Navigator.of(context).pop(),
    );
  }

  void _abrirMapaComentarios({
    required AppTheme theme,
    required PublicacaoSocial pub,
    required bool ehAutor,
    required String meuCpf,
  }) {
    DetalhesPubSecaoComentariosWidget.abrirMapa(
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
      onInteracaoAlterada: _carregarInteracoes,
    );
  }

  Widget _buildMidias(
    AppTheme theme,
    PublicacaoSocial pub, {
    bool ajustarTelaCheia = false,
    bool autoPlayVideo = true,
    bool usarGlobalKey = true,
  }) {
    return DetalhesPubMidiasWidget(
      theme: theme,
      publicacao: pub,
      ajustarTelaCheia: ajustarTelaCheia,
      autoPlayVideo: autoPlayVideo,
      midiaKey: usarGlobalKey ? _midiasKey : null,
      onDoubleTapLike: () => _reagir(TipoReacaoSocial.like),
      pdfFullScreen: _pdfEmTelaCheia,
      onAlternarPdfFullScreen: (v) => setState(() => _pdfEmTelaCheia = v),
    );
  }

  Widget _buildInputComentario(AppTheme theme) {
    return DetalhesPubBarraInputComentarioWidget(
      theme: theme,
      publicacaoId: _pub.id,
      controller: _comentarioCtrl,
      focusNode: _comentarioFocus,
      respondendoAComentario: _respondendoAComentario,
      onCancelarResposta: () => setState(() => _respondendoAComentario = null),
      onEnviar: _enviarComentario,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final pub = _pub;
    final usuarioEfetivo = _obterUsuarioEfetivo();
    final meuCpf = (usuarioEfetivo?.cpf ?? '').replaceAll(RegExp(r'\D'), '');
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

    if (_pdfEmTelaCheia) {
      return Scaffold(
        backgroundColor: theme.backgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: _buildMidias(theme, pub, ajustarTelaCheia: true),
          ),
        ),
      );
    }

    final usarReelsCompacto = !ehDesktop &&
        (pub.tipo == TipoFeedSocial.videos || pub.tipo == TipoFeedSocial.fotos) &&
        pub.midias.isNotEmpty;

    if (usarReelsCompacto) {
      return Scaffold(
        backgroundColor: theme.backgroundColor,
        body: SafeArea(
          child: VisualizadorReelsCompactoWidget(
            theme: theme,
            publicacoes: _lista,
            indiceAtivo: _indiceAtivo,
            pubAtiva: pub,
            usuarioLogado: usuarioEfetivo,
            reacoes: _reacoes,
            republicacoes: _republicacoesPub,
            comentarios: _comentarios,
            coautoresResolvidos: _coautoresResolvidos,
            minhaReacao: minhaReacao?.tipo,
            likes: likes,
            deslikes: deslikes,
            baixando: _baixando,
            onTrocarPublicacao: _trocarPublicacao,
            onReagir: _reagir,
            onRepublicar: _republicar,
            onSalvar: () => DialogSalvarPublicacao.mostrar(
              context,
              theme: theme,
              publicacaoId: pub.id,
              usuarioCpf: meuCpf,
            ),
            onEnviarChat: _enviarNoChat,
            onMaisOpcoes: () => _abrirMenuOpcoesPublicacao(ehAutor),
            onDownload: _baixarPrimeiraMidia,
            onAbrirMapaComentarios: () => _abrirMapaComentarios(
              theme: theme,
              pub: pub,
              ehAutor: ehAutor,
              meuCpf: meuCpf,
            ),
            buildMidia: (t, item, ehAtiva) => _buildMidias(
              t,
              item,
              ajustarTelaCheia: true,
              autoPlayVideo: ehAtiva,
              usarGlobalKey: ehAtiva,
            ),
            buildConteudoComentarios: (t, item) =>
                DetalhesPubListaComentariosWidget(
              theme: t,
              todosComentarios: _comentarios,
              comentariosRaiz: comentariosRaiz,
              ehAutorPublicacao: ehAutor,
              meuCpf: meuCpf,
              onResponder: (alvo) {
                setState(() => _respondendoAComentario = alvo);
                _comentarioFocus.requestFocus();
              },
              onInteracaoAlterada: _carregarInteracoes,
            ),
            buildInputComentario: _buildInputComentario,
          ),
        ),
      );
    }

    if (ehDesktop &&
        _desktopPageController.hasClients &&
        _desktopPageController.page?.round() != _indiceAtivo) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _desktopPageController.hasClients) {
          _desktopPageController.jumpToPage(_indiceAtivo);
        }
      });
    }

    return DetalhesPubLayoutPadraoWidget(
      theme: theme,
      ehDesktop: ehDesktop,
      lista: _lista,
      pub: pub,
      indiceAtivo: _indiceAtivo,
      desktopPageController: _desktopPageController,
      midiasKey: _midiasKey,
      pdfEmTelaCheia: _pdfEmTelaCheia,
      usuarioEfetivo: usuarioEfetivo,
      coautoresResolvidos: _coautoresResolvidos,
      reacoes: _reacoes,
      comentarios: _comentarios,
      comentariosRaiz: comentariosRaiz,
      minhaReacao: minhaReacao,
      likes: likes,
      deslikes: deslikes,
      ehAutor: ehAutor,
      meuCpf: meuCpf,
      onTrocarPublicacao: _trocarPublicacao,
      onReagir: _reagir,
      onAlternarPdfFullScreen: (v) => setState(() => _pdfEmTelaCheia = v),
      onAbrirMenuOpcoes: () => _abrirMenuOpcoesPublicacao(ehAutor),
      onFocarComentario: () => _comentarioFocus.requestFocus(),
      onRepublicar: _republicar,
      onEnviarNoChat: _enviarNoChat,
      onResponderComentario: (alvo) {
        setState(() => _respondendoAComentario = alvo);
        _comentarioFocus.requestFocus();
      },
      onInteracaoAlterada: _carregarInteracoes,
      onAbrirMapaComentarios: () => _abrirMapaComentarios(
        theme: theme,
        pub: pub,
        ehAutor: ehAutor,
        meuCpf: meuCpf,
      ),
      inputComentario: _buildInputComentario(theme),
    );
  }
}
