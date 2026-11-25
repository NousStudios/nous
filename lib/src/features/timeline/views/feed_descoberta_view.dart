import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/core/widgets/floating_bottom_nav_bar.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/outbox_midia_service.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/widgets/feed/feed_descoberta_filtros_bar.dart';
import 'package:nous/src/features/timeline/views/widgets/feed/feed_descoberta_sliver_lista.dart';
import 'package:nous/src/features/timeline/views/widgets/feed/feed_stories_bar.dart';

class FeedDescobertaView extends StatefulWidget {
  final bool apenasAmigos;

  const FeedDescobertaView({
    super.key,
    this.apenasAmigos = false,
  });

  @override
  State<FeedDescobertaView> createState() => _FeedDescobertaViewState();
}

class _FeedDescobertaViewState extends State<FeedDescobertaView> {
  final TextEditingController _buscaTagCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  List<Map<String, dynamic>> _abas = TimelineService.abasDescobertaPadrao;
  int _abaSelecionada = 0;
  String? _tagFiltroAtiva;
  List<PublicacaoSocial> _publicacoes = [];
  List<UsuarioNous> _perfisEncontrados = [];
  Map<String, List<StorySocial>> _storiesPorAutor = {};
  bool _carregando = true;
  bool _carregandoMais = false;
  bool _temMais = true;
  late bool _modoApenasAmigos;
  static const int _tamanhoPagina = 30;

  @override
  void initState() {
    super.initState();
    _modoApenasAmigos = widget.apenasAmigos;
    _scrollCtrl.addListener(_onScroll);
    TimelineService.alteracoesTimelineNotifier.addListener(_aoAtualizar);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OutboxMidiaService.atualizarContagemPendencias();
      _carregar();
    });
  }

  @override
  void dispose() {
    TimelineService.alteracoesTimelineNotifier.removeListener(_aoAtualizar);
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _buscaTagCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (_carregando || _carregandoMais || !_temMais) return;
    if (pos.pixels >= pos.maxScrollExtent - 320) {
      _carregarMais();
    }
  }

  void _aoAtualizar() {
    if (mounted) _carregar();
  }

  Future<void> _aoPuxarParaAtualizar() async {
    try {
      final cliente = ClienteRedeLocal();
      if (cliente.estaConectado.value) {
        await cliente
            .sincronizarTimelineComServidor()
            .timeout(const Duration(seconds: 3));
      }
    } catch (_) {
    } finally {
      await _carregar();
    }
  }

  Future<void> _carregar() async {
    if (!mounted) return;
    setState(() => _carregando = true);

    final auth = context.read<AuthProvider>();
    final meuCpf = auth.cpf;
    final contaAtual = auth.contaAtual;

    final abas = await TimelineService.obterAbasDescoberta(meuCpf);
    if (_abaSelecionada >= abas.length) _abaSelecionada = 0;

    final List<String> tags;
    if (_tagFiltroAtiva != null && _tagFiltroAtiva!.isNotEmpty) {
      tags = [_tagFiltroAtiva!];
    } else if (abas.isNotEmpty) {
      tags = ((abas[_abaSelecionada]['tags'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList();
    } else {
      tags = const [];
    }

    final autoresFiltro = _modoApenasAmigos
        ? <String>{
            if (meuCpf.isNotEmpty) meuCpf,
            ...(contaAtual?.seguindo ?? const <String>[]),
          }.toList()
        : null;

    List<PublicacaoSocial> pubs;
    if (_modoApenasAmigos && (autoresFiltro == null || autoresFiltro.isEmpty)) {
      pubs = const [];
    } else {
      pubs = await TimelineService.listarPublicacoesDescoberta(
        tags: tags,
        apenasAutoresCpfs: autoresFiltro,
        limit: _tamanhoPagina,
        offset: 0,
      );
    }
    final temMaisInicial = pubs.length >= _tamanhoPagina;

    final bloqueadosOuSilenciados = <String>{
      ...(contaAtual?.contasBloqueadas ?? const []),
      ...(contaAtual?.contasSilenciadas ?? const []),
    }.map((c) => c.replaceAll(RegExp(r'\D'), '')).toSet();

    pubs = pubs.where((p) {
      final cpfAutor = p.autorCpf.replaceAll(RegExp(r'\D'), '');
      return !bloqueadosOuSilenciados.contains(cpfAutor);
    }).toList();

    final termo = _buscaTagCtrl.text
        .trim()
        .toLowerCase()
        .replaceAll('#', '')
        .replaceAll('@', '');
    var perfisEncontrados = <UsuarioNous>[];
    if (termo.isNotEmpty) {
      final todasContas = await ContasNousService.carregarTodas();
      perfisEncontrados = todasContas.where((c) {
        final cpfNorm = c.cpf.replaceAll(RegExp(r'\D'), '');
        if (bloqueadosOuSilenciados.contains(cpfNorm)) return false;
        final nome = c.nomeExibicao.toLowerCase();
        final user = c.nomeDeUsuario.toLowerCase().replaceAll('@', '');
        return nome.contains(termo) || user.contains(termo);
      }).take(8).toList();
    }
    final cpfsEncontrados = perfisEncontrados
        .map((c) => c.cpf.replaceAll(RegExp(r'\D'), ''))
        .toSet();
    if (termo.isNotEmpty && _tagFiltroAtiva == null) {
      pubs = pubs.where((p) {
        final cpfAutor = p.autorCpf.replaceAll(RegExp(r'\D'), '');
        return p.texto.toLowerCase().contains(termo) ||
            p.autorNome.toLowerCase().contains(termo) ||
            p.tags.any((t) => t.contains(termo)) ||
            cpfsEncontrados.contains(cpfAutor);
      }).toList();
    }

    final todosStories = await TimelineService.listarStoriesAtivosDaRede();
    final agrupados = <String, List<StorySocial>>{};
    for (final s in todosStories) {
      final cpfAutor = s.autorCpf.replaceAll(RegExp(r'\D'), '');
      if (cpfAutor.isEmpty) continue;
      if (_modoApenasAmigos &&
          cpfAutor != meuCpf.replaceAll(RegExp(r'\D'), '') &&
          !(autoresFiltro ?? const [])
              .map((c) => c.replaceAll(RegExp(r'\D'), ''))
              .contains(cpfAutor)) {
        continue;
      }
      agrupados.putIfAbsent(cpfAutor, () => []).add(s);
    }
    for (final lista in agrupados.values) {
      lista.sort((a, b) => a.criadoEm.compareTo(b.criadoEm));
    }

    if (!mounted) return;
    setState(() {
      _abas = abas;
      _publicacoes = pubs;
      _perfisEncontrados = perfisEncontrados;
      _storiesPorAutor = agrupados;
      _temMais = temMaisInicial;
      _carregando = false;
    });
  }

  Future<void> _carregarMais() async {
    if (!mounted || _carregandoMais || !_temMais) return;
    setState(() => _carregandoMais = true);

    final auth = context.read<AuthProvider>();
    final meuCpf = auth.cpf;
    final contaAtual = auth.contaAtual;

    final List<String> tags;
    if (_tagFiltroAtiva != null && _tagFiltroAtiva!.isNotEmpty) {
      tags = [_tagFiltroAtiva!];
    } else if (_abas.isNotEmpty && _abaSelecionada < _abas.length) {
      tags = ((_abas[_abaSelecionada]['tags'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList();
    } else {
      tags = const [];
    }

    final autoresFiltro = _modoApenasAmigos
        ? <String>{
            if (meuCpf.isNotEmpty) meuCpf,
            ...(contaAtual?.seguindo ?? const <String>[]),
          }.toList()
        : null;

    var novas = await TimelineService.listarPublicacoesDescoberta(
      tags: tags,
      apenasAutoresCpfs: autoresFiltro,
      limit: _tamanhoPagina,
      offset: _publicacoes.length,
    );
    final temMaisProx = novas.length >= _tamanhoPagina;

    final bloqueadosOuSilenciados = <String>{
      ...(contaAtual?.contasBloqueadas ?? const []),
      ...(contaAtual?.contasSilenciadas ?? const []),
    }.map((c) => c.replaceAll(RegExp(r'\D'), '')).toSet();

    novas = novas.where((p) {
      final cpfAutor = p.autorCpf.replaceAll(RegExp(r'\D'), '');
      return !bloqueadosOuSilenciados.contains(cpfAutor);
    }).toList();

    final termo = _buscaTagCtrl.text.trim().toLowerCase().replaceAll('#', '');
    if (termo.isNotEmpty && _tagFiltroAtiva == null) {
      novas = novas.where((p) {
        return p.texto.toLowerCase().contains(termo) ||
            p.autorNome.toLowerCase().contains(termo) ||
            p.tags.any((t) => t.contains(termo));
      }).toList();
    }

    if (!mounted) return;
    setState(() {
      final idsAtuais = _publicacoes.map((p) => p.id).toSet();
      for (final p in novas) {
        if (!idsAtuais.contains(p.id)) {
          _publicacoes.add(p);
        }
      }
      _temMais = temMaisProx;
      _carregandoMais = false;
    });
  }

  Future<void> _adicionarAbaTag(AppTheme theme) async {
    final resultado =
        await FeedDescobertaFiltrosBar.mostrarDialogNovaTimeline(
      context,
      theme,
    );
    if (resultado == null || !mounted) return;

    final novaLista = List<Map<String, dynamic>>.from(_abas)
      ..add({
        'id': 'desc_${DateTime.now().millisecondsSinceEpoch}',
        'titulo': resultado.titulo,
        'tags': resultado.tags,
        'ehPadrao': false,
      });
    final cpf = context.read<AuthProvider>().cpf;
    await TimelineService.salvarAbasDescoberta(cpf, novaLista);
    _abaSelecionada = novaLista.length - 1;
    _tagFiltroAtiva = null;
    await _carregar();
  }

  Future<void> _removerAba(String cpf, int indice) async {
    final nova = List<Map<String, dynamic>>.from(_abas)..removeAt(indice);
    await TimelineService.salvarAbasDescoberta(cpf, nova);
    _abaSelecionada = 0;
    await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, _) {
        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: CustomAppBar(
            title: _modoApenasAmigos ? 'Seguindo' : 'Descoberta',
            showBackButton: false,
          ),
          body: SafeArea(
            child: RefreshIndicator(
              color: theme.buttonColor,
              backgroundColor: theme.cardBackgroundColor,
              notificationPredicate: (n) => n.depth == 0,
              onRefresh: _aoPuxarParaAtualizar,
              child: CustomScrollView(
                controller: _scrollCtrl,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FeedDescobertaFiltrosBar(
                              theme: theme,
                              buscaController: _buscaTagCtrl,
                              onBuscaChanged: (_) {
                                _tagFiltroAtiva = null;
                                _carregar();
                              },
                              perfisEncontrados: _perfisEncontrados,
                              modoApenasAmigos: _modoApenasAmigos,
                              tagFiltroAtiva: _tagFiltroAtiva,
                              onLimparTagFiltro: () {
                                _tagFiltroAtiva = null;
                                _carregar();
                              },
                              abas: _abas,
                              abaSelecionada: _abaSelecionada,
                              onSelecionarAba: (indice) {
                                setState(() {
                                  _tagFiltroAtiva = null;
                                  _abaSelecionada = indice;
                                });
                                _carregar();
                              },
                              onRemoverAba: (indice) =>
                                  _removerAba(auth.cpf, indice),
                              onAdicionarAba: () => _adicionarAbaTag(theme),
                            ),
                            const SizedBox(height: 6),
                            FeedStoriesBar(
                              theme: theme,
                              contaAtual: auth.contaAtual,
                              meuCpf: auth.cpf,
                              storiesPorAutor: _storiesPorAutor,
                              buscarContaPorCpf: auth.buscarContaPorCpf,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox.shrink(),
                  ),
                  FeedDescobertaSliverLista(
                    theme: theme,
                    carregando: _carregando,
                    carregandoMais: _carregandoMais,
                    modoApenasAmigos: _modoApenasAmigos,
                    publicacoes: _publicacoes,
                    usuarioLogado: auth.contaAtual,
                    onTapTag: (tag) {
                      setState(() => _tagFiltroAtiva = tag);
                      _carregar();
                    },
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: FloatingBottomNavBar(
            maxWidth: 620,
            slotSelecionado: 3,
            subIndiceSelecionado: widget.apenasAmigos ? 1 : 0,
          ),
        );
      },
    );
  }
}
