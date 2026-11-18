import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/core/widgets/floating_bottom_nav_bar.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_stories.dart';
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
  List<Map<String, dynamic>> _abas = TimelineService.abasDescobertaPadrao;
  int _abaSelecionada = 0;
  String? _tagFiltroAtiva;
  List<PublicacaoSocial> _publicacoes = [];
  Map<String, List<StorySocial>> _storiesPorAutor = {};
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    TimelineService.alteracoesTimelineNotifier.addListener(_aoAtualizar);
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  @override
  void dispose() {
    TimelineService.alteracoesTimelineNotifier.removeListener(_aoAtualizar);
    _buscaTagCtrl.dispose();
    super.dispose();
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

    final autoresFiltro = widget.apenasAmigos
        ? (contaAtual?.seguindo ?? const <String>[])
        : const <String>[];

    List<PublicacaoSocial> pubs;
    if (widget.apenasAmigos && autoresFiltro.isEmpty) {
      pubs = const [];
    } else {
      pubs = await TimelineService.listarPublicacoesDescoberta(
        tags: tags,
        apenasAutoresCpfs: autoresFiltro,
      );
    }

    final termo = _buscaTagCtrl.text.trim().toLowerCase().replaceAll('#', '');
    if (termo.isNotEmpty && _tagFiltroAtiva == null) {
      pubs = pubs.where((p) {
        return p.texto.toLowerCase().contains(termo) ||
            p.autorNome.toLowerCase().contains(termo) ||
            p.tags.any((t) => t.contains(termo));
      }).toList();
    }

    final todosStories = await TimelineService.listarStoriesAtivosDaRede();
    final agrupados = <String, List<StorySocial>>{};
    for (final s in todosStories) {
      final cpfAutor = s.autorCpf.replaceAll(RegExp(r'\D'), '');
      if (cpfAutor.isEmpty) continue;
      if (widget.apenasAmigos &&
          cpfAutor != meuCpf.replaceAll(RegExp(r'\D'), '') &&
          !autoresFiltro
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
      _storiesPorAutor = agrupados;
      _carregando = false;
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
            title: widget.apenasAmigos
                ? 'Feed de Amigos'
                : 'Feed de Descoberta',
            showBackButton: false,
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                      child: ThemedTextField(
                        theme: theme,
                        controller: _buscaTagCtrl,
                        label: 'Buscar por #tag, assunto ou pessoa...',
                        onChanged: (_) {
                          _tagFiltroAtiva = null;
                          _carregar();
                        },
                      ),
                    ),

                    if (!widget.apenasAmigos)
                      SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          children: [
                            if (_tagFiltroAtiva != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
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
                                padding: const EdgeInsets.only(right: 6),
                                child: GestureDetector(
                                  onLongPress: (_abas[i]['ehPadrao'] == true)
                                      ? null
                                      : () async {
                                          final nova =
                                              List<Map<String, dynamic>>.from(
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
                                      _abas[i]['titulo'] as String? ?? 'Feed',
                                      style: theme.getTextStyle(
                                        fontSize: 12,
                                        color: (_tagFiltroAtiva == null &&
                                                _abaSelecionada == i)
                                            ? theme.buttonTextColor
                                            : theme.textColor,
                                      ),
                                    ),
                                    selected: _tagFiltroAtiva == null &&
                                        _abaSelecionada == i,
                                    selectedColor: theme.buttonColor,
                                    backgroundColor: theme.cardBackgroundColor,
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
                                color: theme.buttonColor,
                              ),
                              onPressed: () => _adicionarAbaTag(theme),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 6),

                    // Faixa horizontal de Stories ativos no topo do Feed
                    if (_storiesPorAutor.isNotEmpty || auth.contaAtual != null)
                      SizedBox(
                        height: 76,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          children: [
                            if (auth.contaAtual != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: GestureDetector(
                                  onTap: () => DialogCriarStory.mostrar(
                                    context,
                                    theme: theme,
                                    autor: auth.contaAtual!,
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: theme.cardBackgroundColor,
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
                                          color: theme.secondaryTextColor,
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
                                  final conta = auth.buscarContaPorCpf(
                                    cpfAutor,
                                  );
                                  final foto =
                                      (conta?.fotoExibicao.isNotEmpty ?? false)
                                      ? conta!.fotoExibicao
                                      : primeiro.autorFoto;
                                  final nome =
                                      (conta?.nomeExibicao.isNotEmpty ?? false)
                                      ? conta!.nomeExibicao
                                      : (primeiro.autorNome.isNotEmpty
                                            ? primeiro.autorNome
                                            : 'Story');
                                  final meuCpfLimpo = auth.cpf.replaceAll(
                                    RegExp(r'\D'),
                                    '',
                                  );
                                  final ehEu =
                                      meuCpfLimpo.isNotEmpty &&
                                      meuCpfLimpo == cpfAutor;

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 10),
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
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: theme.buttonColor,
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
                                              overflow: TextOverflow.ellipsis,
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

                    Expanded(
                      child: _carregando
                          ? const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : RefreshIndicator(
                              color: theme.buttonColor,
                              backgroundColor: theme.cardBackgroundColor,
                              onRefresh: _aoPuxarParaAtualizar,
                              child: _publicacoes.isEmpty
                                  ? ListView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      padding: const EdgeInsets.all(20),
                                      children: [
                                        EstadoVazioContainer(
                                          theme: theme,
                                          mensagem: widget.apenasAmigos
                                              ? 'Siga outros usuários Nous para acompanhar as publicações deles aqui.'
                                              : 'Nenhuma publicação encontrada para esta timeline ainda.',
                                        ),
                                      ],
                                    )
                                  : ListView.builder(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        4,
                                        12,
                                        90,
                                      ),
                                      itemCount: _publicacoes.length,
                                      itemBuilder: (context, index) {
                                        return CardPublicacaoCompletoWidget(
                                          theme: theme,
                                          publicacao: _publicacoes[index],
                                          usuarioLogado: auth.contaAtual,
                                          onTapTag: (tag) {
                                            setState(
                                              () => _tagFiltroAtiva = tag,
                                            );
                                            _carregar();
                                          },
                                        );
                                      },
                                    ),
                            ),
                    ),
                  ],
                ),
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
