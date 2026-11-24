import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/core/widgets/floating_bottom_nav_bar.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/auth/views/perfil_social_view.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/outbox_midia_service.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_stories.dart';
import 'package:nous/src/features/timeline/views/widgets/avatar_com_story_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/camera_criacao_view.dart';
import 'package:nous/src/features/timeline/views/widgets/card_escrito_widget.dart';
import 'package:nous/src/features/timeline/views/widgets/card_publicacao_completo_widget.dart';

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
    final tituloCtrl = TextEditingController();
    final tagsCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.borderColor),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Nova Timeline por #Tag',
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 14),
                ThemedTextField(
                  theme: theme,
                  controller: tituloCtrl,
                  label: 'Nome da timeline (ex.: Receitas)',
                ),
                const SizedBox(height: 10),
                ThemedTextField(
                  theme: theme,
                  controller: tagsCtrl,
                  label: 'Tags separadas por vírgula (ex.: receita, bolo)',
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.buttonColor,
                    foregroundColor: theme.buttonTextColor,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Adicionar Timeline'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (ok == true && mounted) {
      final titulo = tituloCtrl.text.trim();
      final tags = tagsCtrl.text
          .split(',')
          .map((e) => e.trim().toLowerCase().replaceAll('#', ''))
          .where((e) => e.isNotEmpty)
          .toList();
      if (titulo.isNotEmpty && tags.isNotEmpty) {
        final novaLista = List<Map<String, dynamic>>.from(_abas)
          ..add({
            'id': 'desc_${DateTime.now().millisecondsSinceEpoch}',
            'titulo': titulo,
            'tags': tags,
            'ehPadrao': false,
          });
        final cpf = context.read<AuthProvider>().cpf;
        await TimelineService.salvarAbasDescoberta(cpf, novaLista);
        _abaSelecionada = novaLista.length - 1;
        _tagFiltroAtiva = null;
        await _carregar();
      }
    }

    tituloCtrl.dispose();
    tagsCtrl.dispose();
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
            title: _modoApenasAmigos
                ? 'Seguindo'
                : 'Descoberta',
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
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                8,
                                14,
                                6,
                              ),
                              child: ThemedTextField(
                                theme: theme,
                                controller: _buscaTagCtrl,
                                label: 'Buscar por #tag, assunto ou @pessoa...',
                                onChanged: (_) {
                                  _tagFiltroAtiva = null;
                                  _carregar();
                                },
                              ),
                            ),
                            if (_perfisEncontrados.isNotEmpty)
                              SizedBox(
                                height: 42,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  itemCount: _perfisEncontrados.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (_, idx) {
                                    final conta = _perfisEncontrados[idx];
                                    return ActionChip(
                                      backgroundColor:
                                          theme.cardBackgroundColor,
                                      side: BorderSide(
                                        color: theme.borderColor
                                            .withValues(alpha: 0.45),
                                      ),
                                      avatar: AvatarComStoryWidget(
                                        theme: theme,
                                        cpf: conta.cpf,
                                        nome: conta.nomeExibicao,
                                        foto: conta.fotoExibicao,
                                        radius: 11,
                                        usuario: conta,
                                      ),
                                      label: Text(
                                        conta.usernameExibicao.isNotEmpty
                                            ? '${conta.nomeExibicao} (${conta.usernameExibicao})'
                                            : conta.nomeExibicao,
                                        style: theme.getTextStyle(
                                          fontSize: 11.5,
                                          color: theme.textColor,
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => PerfilSocialView(
                                              usuarioAlvo: conta,
                                              mostrarBotaoVoltar: true,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            if (!_modoApenasAmigos)
                              SizedBox(
                                height: 44,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  children: [
                                    if (_tagFiltroAtiva != null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 6),
                                        child: InputChip(
                                          label: Text('#$_tagFiltroAtiva'),
                                          selected: true,
                                          onDeleted: () {
                                            _tagFiltroAtiva = null;
                                            _carregar();
                                          },
                                        ),
                                      ),
                                    for (int i = 0; i < _abas.length; i++)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 6),
                                        child: GestureDetector(
                                          onLongPress:
                                              (_abas[i]['ehPadrao'] == true)
                                                  ? null
                                                  : () async {
                                                      final nova = List<
                                                          Map<String,
                                                              dynamic>>.from(
                                                        _abas,
                                                      )..removeAt(i);
                                                      await TimelineService
                                                          .salvarAbasDescoberta(
                                                        auth.cpf,
                                                        nova,
                                                      );
                                                      _abaSelecionada = 0;
                                                      await _carregar();
                                                    },
                                          child: ChoiceChip(
                                            label: Text(
                                              _abas[i]['titulo'] as String? ??
                                                  'Feed',
                                              style: theme.getTextStyle(
                                                fontSize: 12,
                                                color: (_tagFiltroAtiva ==
                                                            null &&
                                                        _abaSelecionada == i)
                                                    ? theme.buttonTextColor
                                                    : theme.textColor,
                                              ),
                                            ),
                                            selected: _tagFiltroAtiva == null &&
                                                _abaSelecionada == i,
                                            selectedColor: theme.buttonColor,
                                            backgroundColor:
                                                theme.cardBackgroundColor,
                                            onSelected: (_) {
                                              setState(() {
                                                _tagFiltroAtiva = null;
                                                _abaSelecionada = i;
                                              });
                                              _carregar();
                                            },
                                          ),
                                        ),
                                      ),
                                    IconButton(
                                      tooltip: 'Adicionar timeline de #tag',
                                      icon: Icon(
                                        Icons.add_circle_outline_rounded,
                                        color: theme.textColor,
                                      ),
                                      onPressed: () => _adicionarAbaTag(theme),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 6),
                            if (_storiesPorAutor.isNotEmpty ||
                                auth.contaAtual != null)
                              SizedBox(
                                height: 76,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  children: [
                                    if (auth.contaAtual != null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 10),
                                        child: GestureDetector(
                                          onTap: () => Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (ctx) => CameraCriacaoView(
                                                theme: theme,
                                                autor: auth.contaAtual!,
                                                ativa: true,
                                                onVoltarPerfil: () =>
                                                    Navigator.of(ctx).pop(),
                                              ),
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Container(
                                                width: 52,
                                                height: 52,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color:
                                                      theme.cardBackgroundColor,
                                                  border: Border.all(
                                                    color: theme.borderColor
                                                        .withValues(alpha: 0.7),
                                                    width: 1.4,
                                                  ),
                                                ),
                                                child: Icon(
                                                  Icons.add,
                                                  size: 22,
                                                  color: theme.textColor,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '+ Story',
                                                style: theme.getTextStyle(
                                                  fontSize: 10,
                                                  color:
                                                      theme.secondaryTextColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    for (final entry in _storiesPorAutor.entries)
                                      Builder(
                                        builder: (_) {
                                          final cpfAutor = entry.key;
                                          final storiesAutor = entry.value;
                                          final primeiro = storiesAutor.first;
                                          final conta =
                                              auth.buscarContaPorCpf(cpfAutor);
                                          final foto =
                                              (conta?.fotoExibicao.isNotEmpty ??
                                                      false)
                                                  ? conta!.fotoExibicao
                                                  : primeiro.autorFoto;
                                          final nome =
                                              (conta?.nomeExibicao.isNotEmpty ??
                                                      false)
                                                  ? conta!.nomeExibicao
                                                  : (primeiro.autorNome
                                                          .isNotEmpty
                                                      ? primeiro.autorNome
                                                      : 'Story');
                                          final meuCpfLimpo =
                                              auth.cpf.replaceAll(
                                            RegExp(r'\D'),
                                            '',
                                          );
                                          final ehEu = meuCpfLimpo.isNotEmpty &&
                                              meuCpfLimpo == cpfAutor;

                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                right: 10),
                                            child: GestureDetector(
                                              onTap: () =>
                                                  DialogVisualizarStory.mostrar(
                                                context,
                                                theme: theme,
                                                story: storiesAutor.first,
                                                stories: storiesAutor,
                                                ehAutor: ehEu,
                                                usuarioLogado: auth.contaAtual,
                                              ),
                                              child: SizedBox(
                                                width: 58,
                                                child: Column(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              2),
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color:
                                                              theme.borderColor,
                                                          width: 2.2,
                                                        ),
                                                      ),
                                                      child: _buildAvatarAutor(
                                                        theme,
                                                        foto,
                                                        nome,
                                                        raio: 22,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      nome,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: theme.getTextStyle(
                                                        fontSize: 10,
                                                        color: theme.textColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                      SliverToBoxAdapter(
                        child: SizedBox.shrink(),
                      ),
                      if (_carregando)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else if (_publicacoes.isEmpty)
                        SliverToBoxAdapter(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 620),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: EstadoVazioContainer(
                                  theme: theme,
                                  mensagem: _modoApenasAmigos
                                      ? 'Siga outros usuários Nous para acompanhar as publicações deles aqui.'
                                      : 'Nenhuma publicação encontrada para esta timeline ainda.',
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                          sliver: SliverList.builder(
                            itemCount: _publicacoes.length +
                                (_carregandoMais ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= _publicacoes.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final pub = _publicacoes[index];
                              return Center(
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 620),
                                  child: pub.tipo == TipoFeedSocial.escritos
                                      ? CardEscritoWidget(
                                          key: ValueKey('pub_desc_${pub.id}'),
                                          theme: theme,
                                          publicacao: pub,
                                          usuarioLogado: auth.contaAtual,
                                          listaPublicacoes: _publicacoes,
                                          indiceInicial: index,
                                          abrirDetalhesAoTocarCabecalho: true,
                                          onTapTag: (tag) {
                                            setState(
                                              () => _tagFiltroAtiva = tag,
                                            );
                                            _carregar();
                                          },
                                        )
                                      : CardPublicacaoCompletoWidget(
                                          key: ValueKey('pub_desc_${pub.id}'),
                                          theme: theme,
                                          publicacao: pub,
                                          usuarioLogado: auth.contaAtual,
                                          listaPublicacoes: _publicacoes,
                                          indiceInicial: index,
                                          abrirDetalhesAoTocarCabecalho: true,
                                          onTapTag: (tag) {
                                            setState(
                                              () => _tagFiltroAtiva = tag,
                                            );
                                            _carregar();
                                          },
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
          bottomNavigationBar: FloatingBottomNavBar(
            maxWidth: 620,
            slotSelecionado: 3,
            subIndiceSelecionado: widget.apenasAmigos ? 1 : 0,
          ),
        );
      },
    );
  }

  Widget _buildAvatarAutor(
    AppTheme theme,
    String fotoAutor,
    String rotuloAutor, {
    double raio = 13,
  }) {
    final inicial = rotuloAutor.trim().isNotEmpty
        ? rotuloAutor.trim()[0].toUpperCase()
        : '?';

    Widget buildFallback() => CircleAvatar(
          radius: raio,
          backgroundColor: theme.borderColor.withValues(alpha: 0.35),
          child: Text(
            inicial,
            style: theme.getTextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
        );

    final providerDireto = ImagemService.obterImageProvider(fotoAutor);
    if (providerDireto != null) {
      return CircleAvatar(
        radius: raio,
        backgroundColor: theme.borderColor.withValues(alpha: 0.35),
        backgroundImage: providerDireto,
      );
    }

    if (fotoAutor.trim().isEmpty) {
      return buildFallback();
    }

    return FutureBuilder<String?>(
      future: TimelineService.resolverCaminhoMidia(fotoAutor),
      builder: (context, snapshot) {
        final caminho = snapshot.data;
        if (caminho != null && caminho.isNotEmpty) {
          final prov = ImagemService.obterImageProvider(caminho);
          if (prov != null) {
            return CircleAvatar(
              radius: raio,
              backgroundColor: theme.borderColor.withValues(alpha: 0.35),
              backgroundImage: prov,
            );
          }
        }
        return buildFallback();
      },
    );
  }
}
