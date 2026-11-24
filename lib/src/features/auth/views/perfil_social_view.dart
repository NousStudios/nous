import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/core/widgets/floating_bottom_nav_bar.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/auth/views/dialogs/dialog_lista_conexoes.dart';
import 'package:nous/src/features/auth/views/helpers/perfil_foto_publica_helper.dart';
import 'package:nous/src/features/auth/views/widgets/cabecalho_perfil_publico_widget.dart';
import 'package:nous/src/features/auth/views/widgets/perfil_social/perfil_acoes_header_widget.dart';
import 'package:nous/src/features/auth/views/widgets/perfil_social/perfil_bio_links_widget.dart';
import 'package:nous/src/features/auth/views/widgets/selo_verificado_widget.dart';
import 'package:nous/src/features/chat/services/resolvedor_foto_chat.dart';
import 'package:nous/src/features/chat/views/widgets/visualizador_imagem_chat_dialog.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_posts_contabilizados.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_stories.dart';
import 'package:nous/src/features/timeline/views/widgets/camera_criacao_view.dart';
import 'package:nous/src/features/timeline/views/widgets/timeline_perfil_section.dart';

class PerfilSocialView extends StatefulWidget {
  final UsuarioNous? usuarioAlvo;
  final bool mostrarBotaoVoltar;

  const PerfilSocialView({
    super.key,
    this.usuarioAlvo,
    this.mostrarBotaoVoltar = false,
  });

  @override
  State<PerfilSocialView> createState() => _PerfilSocialViewState();
}

class _PerfilSocialViewState extends State<PerfilSocialView> {
  static const double _larguraMaximaConteudo = 600;
  final PageController _pageController = PageController(initialPage: 1);
  final ScrollController _perfilScrollCtrl = ScrollController();
  int _paginaAtual = 1;
  UsuarioNous? _contaAlvoAtualizada;
  String? _fotoLocalResolvida;
  bool _baixandoFoto = false;
  List<StorySocial> _storiesAtivos24h = [];
  int _totalPosts = 0;

  @override
  void initState() {
    super.initState();
    _contaAlvoAtualizada = widget.usuarioAlvo;
    TimelineService.alteracoesTimelineNotifier.addListener(_recarregarResumoSocial);
    _inicializarEAutocurarPerfil();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recarregarResumoSocial());
  }

  @override
  void dispose() {
    TimelineService.alteracoesTimelineNotifier
        .removeListener(_recarregarResumoSocial);
    _perfilScrollCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _recarregarResumoSocial() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final cpf = (_contaAlvoAtualizada ?? widget.usuarioAlvo ?? auth.contaAtual)?.cpf ?? '';
    if (cpf.isEmpty) return;
    final stories = await TimelineService.listarStoriesAtivos24h(cpf);
    final posts = await TimelineService.contarPublicacoesDoUsuario(cpf);
    if (!mounted) return;
    setState(() {
      _storiesAtivos24h = stories;
      _totalPosts = posts;
    });
  }

  Future<void> _aoPuxarParaAtualizar() async {
    try {
      final cliente = ClienteRedeLocal();
      if (cliente.estaConectado.value) {
        final auth = context.read<AuthProvider>();
        await Future.wait([
          cliente.sincronizarIdentidadeUsuario(auth: auth),
          cliente.sincronizarTimelineComServidor(),
        ]).timeout(const Duration(seconds: 3));
      }
    } catch (_) {
    } finally {
      try {
        await _inicializarEAutocurarPerfil().timeout(
          const Duration(seconds: 2),
        );
      } catch (_) {}
      await _recarregarResumoSocial();
      TimelineService.notificarAlteracao();
    }
  }

  @override
  void didUpdateWidget(covariant PerfilSocialView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final cpfAntigo =
        (oldWidget.usuarioAlvo?.cpf ?? '').replaceAll(RegExp(r'\D'), '');
    final cpfNovo =
        (widget.usuarioAlvo?.cpf ?? '').replaceAll(RegExp(r'\D'), '');
    if (cpfAntigo != cpfNovo || oldWidget.usuarioAlvo != widget.usuarioAlvo) {
      _contaAlvoAtualizada = widget.usuarioAlvo;
      _fotoLocalResolvida = null;
      _inicializarEAutocurarPerfil();
      if (cpfAntigo != cpfNovo) {
        _recarregarResumoSocial();
      }
    }
  }

  Future<void> _inicializarEAutocurarPerfil() async {
    final alvo = _contaAlvoAtualizada;
    if (alvo == null) return;

    final cpfLimpo = alvo.cpf.replaceAll(RegExp(r'\D'), '');

    // 1. Tenta resolver no cache do chat primeiro
    if (cpfLimpo.isNotEmpty) {
      final cacheFoto = ResolvedorFotoChat.instancia.obterFotoEmCache(cpfLimpo);
      if (cacheFoto.isNotEmpty) {
        final resolvido = ImagemService.resolverCaminhoExistente(cacheFoto);
        if (resolvido != null && File(resolvido).existsSync()) {
          _fotoLocalResolvida = resolvido;
        }
      }
    }

    // 2. Se a foto do objeto atual já for válida fisicamente em disco, utiliza
    if (_fotoLocalResolvida == null && alvo.fotoExibicao.isNotEmpty) {
      final resolvido = ImagemService.resolverCaminhoExistente(alvo.fotoExibicao);
      if (resolvido != null && File(resolvido).existsSync()) {
        _fotoLocalResolvida = resolvido;
        if (cpfLimpo.isNotEmpty) {
          ResolvedorFotoChat.instancia.registrarFoto(cpfLimpo, resolvido);
        }
      }
    }

    if (mounted) setState(() {});

    // 3. Autocura assíncrona: harmoniza com o SQLite local e balcão na rede local
    if (cpfLimpo.length == 11) {
      try {
        final contaDb = await ContasNousService.buscarPorCpf(cpfLimpo);
        if (contaDb != null && mounted) {
          _contaAlvoAtualizada = contaDb;
          if (_fotoLocalResolvida == null && contaDb.fotoExibicao.isNotEmpty) {
            final res = ImagemService.resolverCaminhoExistente(contaDb.fotoExibicao);
            if (res != null && File(res).existsSync()) {
              _fotoLocalResolvida = res;
              ResolvedorFotoChat.instancia.registrarFoto(cpfLimpo, res);
            }
          }
          setState(() {});
        }
      } catch (_) {}

      // Se ainda não temos a foto física resolvida, baixa do balcão pela rede
      if (_fotoLocalResolvida == null && !_baixandoFoto && ClienteRedeLocal().conectado) {
        _baixandoFoto = true;
        try {
          final usuarioBalcao = await ClienteRedeLocal().buscarUsuarioRemoto(cpfLimpo);
          if (usuarioBalcao != null && mounted) {
            _contaAlvoAtualizada = usuarioBalcao;
          }

          final fotoParaBaixar = _contaAlvoAtualizada?.fotoExibicao ?? alvo.fotoExibicao;
          if (fotoParaBaixar.isNotEmpty || cpfLimpo.length == 11) {
            final baixado = await ClienteRedeLocal().baixarImagemRemota(
              fotoParaBaixar,
              cpf: cpfLimpo,
            );

            if (baixado.isNotEmpty && File(baixado).existsSync() && mounted) {
              _fotoLocalResolvida = baixado;
              ResolvedorFotoChat.instancia.registrarFoto(cpfLimpo, baixado);
              setState(() {});
            }
          }
        } catch (_) {} finally {
          _baixandoFoto = false;
        }
      }
    }
  }

  Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final limpo = hex.replaceAll('#', '');
    if (limpo.length != 6) return null;
    final val = int.tryParse('FF$limpo', radix: 16);
    return val != null ? Color(val) : null;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final contaPropria = auth.contaAtual;
    final cpfAlvoRef = widget.usuarioAlvo?.cpf ?? contaPropria?.cpf ?? '';
    final contaNoCache = cpfAlvoRef.isNotEmpty
        ? auth.buscarContaPorCpf(cpfAlvoRef)
        : null;
    final conta = (widget.usuarioAlvo == null ? contaPropria : contaNoCache) ??
        _contaAlvoAtualizada ??
        widget.usuarioAlvo ??
        contaPropria ??
        const UsuarioNous(
          cpf: '',
          nome: 'Usuário Nous',
          apelido: 'usuario',
          dataNascimento: '',
        );

    final ehProprioUsuario = widget.usuarioAlvo == null ||
        (contaPropria != null &&
            contaPropria.cpf.replaceAll(RegExp(r'\D'), '') ==
                conta.cpf.replaceAll(RegExp(r'\D'), ''));

    final fotoResolvida = _fotoLocalResolvida ??
        ImagemService.resolverCaminhoExistente(conta.fotoExibicao);
    final temFoto = fotoResolvida != null && File(fotoResolvida).existsSync();
    final providerFoto = temFoto
        ? ImagemService.obterImageProvider(fotoResolvida)
        : null;

    final apelidoOculto = !ehProprioUsuario && conta.dadoEstaPrivado('apelido');
    final apelidoExibicao = apelidoOculto ? '' : conta.usernameExibicao;

    final nomeOculto = !ehProprioUsuario && conta.dadoEstaPrivado('nome');
    final nomeExibicao = nomeOculto
        ? (apelidoOculto || conta.apelidoExibicao.isEmpty
            ? 'Cidadão Nous'
            : conta.apelidoExibicao)
        : (conta.nomeExibicao.isNotEmpty ? conta.nomeExibicao : 'Usuário Nous');

    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        final corFundoCustom = _parseHexColor(conta.coresPerfil['fundo']);
        final corDestaqueCustom = _parseHexColor(conta.coresPerfil['destaque']);
        final fundoFinal = corFundoCustom ?? theme.backgroundColor;
        final textoSobreFundo = corFundoCustom != null
            ? (corFundoCustom.computeLuminance() > 0.5
                ? const Color(0xFF141416)
                : const Color(0xFFF5F5F7))
            : theme.textColor;
        final textoSecSobreFundo = corFundoCustom != null
            ? textoSobreFundo.withValues(alpha: 0.72)
            : theme.secondaryTextColor;
        final corBordaPerfil = corDestaqueCustom ?? theme.borderColor;

        final perfilScaffold = Scaffold(
          backgroundColor: fundoFinal,
          appBar: CustomAppBar(
            title: '',
            showBackButton: widget.mostrarBotaoVoltar,
          ),
          body: SafeArea(
            child: RefreshIndicator(
              color: theme.textColor,
              backgroundColor: theme.cardBackgroundColor,
              onRefresh: _aoPuxarParaAtualizar,
              child: SingleChildScrollView(
                controller: _perfilScrollCtrl,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _larguraMaximaConteudo,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                      // Cabeçalho Social Unificado
                      CabecalhoPerfilPublicoWidget(
                        theme: theme,
                        providerFoto: providerFoto,
                        temFoto: temFoto,
                        carregandoFoto: _baixandoFoto,
                        temStoryAtivo: _storiesAtivos24h.isNotEmpty,
                        corDestaqueAnel: (() {
                          final h = conta.corStoryHex.replaceAll('#', '').trim();
                          final v = int.tryParse(h, radix: 16);
                          if (v == null) return const Color(0xFF2E7D32);
                          return Color(h.length == 6 ? (0xFF000000 | v) : v);
                        })(),
                        tooltipFoto: _storiesAtivos24h.isNotEmpty
                            ? 'Toque para ver o Story • Segure para ampliar a foto'
                            : (temFoto
                                  ? 'Toque ou segure para ampliar a foto'
                                  : (ehProprioUsuario
                                        ? 'Toque para definir a foto do perfil público'
                                        : '')),
                        onTapFoto: () {
                          if (_storiesAtivos24h.isNotEmpty) {
                            DialogVisualizarStory.mostrar(
                              context,
                              theme: theme,
                              story: _storiesAtivos24h.first,
                              stories: _storiesAtivos24h,
                              ehAutor: ehProprioUsuario,
                              usuarioLogado: auth.contaAtual,
                            );
                          } else if (temFoto) {
                            VisualizadorImagemChatDialog.abrir(
                              context,
                              caminho: fotoResolvida,
                              theme: theme,
                              permitirDownload: ehProprioUsuario,
                              permitirEncaminhar: ehProprioUsuario,
                            );
                          } else if (ehProprioUsuario) {
                            PerfilFotoPublicaHelper.gerenciar(
                              context,
                              theme: theme,
                              conta: conta,
                              onAtualizada: (salvo) {
                                if (!mounted) return;
                                setState(() {
                                  _fotoLocalResolvida = salvo;
                                });
                              },
                            );
                          }
                        },
                        onLongPressFoto: () {
                          if (temFoto) {
                            VisualizadorImagemChatDialog.abrir(
                              context,
                              caminho: fotoResolvida,
                              theme: theme,
                              permitirDownload: ehProprioUsuario,
                              permitirEncaminhar: ehProprioUsuario,
                            );
                          } else if (ehProprioUsuario) {
                            PerfilFotoPublicaHelper.gerenciar(
                              context,
                              theme: theme,
                              conta: conta,
                              onAtualizada: (salvo) {
                                if (!mounted) return;
                                setState(() {
                                  _fotoLocalResolvida = salvo;
                                });
                              },
                            );
                          }
                        },
                        handleTexto: apelidoExibicao,
                        nomeTexto: nomeExibicao,
                        seloVerificado: conta.possuiValidacao
                            ? SeloVerificadoWidget(
                                usuario: conta,
                                theme: theme,
                                tamanho: 17,
                              )
                            : null,
                        metricas: [
                          MetricaPerfilPublico(
                            valor: '$_totalPosts',
                            rotulo: 'Posts',
                            onTap: () => DialogPostsContabilizados.mostrar(
                              context,
                              theme: theme,
                              contaPerfil: conta,
                              usuarioLogado: auth.contaAtual,
                            ),
                          ),
                          MetricaPerfilPublico(
                            valor: '${conta.seguidores.length}',
                            rotulo: 'Seguidores',
                            onTap: () => DialogListaConexoes.exibir(
                              context: context,
                              titulo: 'Seguidores',
                              cpfs: conta.seguidores,
                              theme: theme,
                              usuarioDonoLista: conta,
                            ),
                          ),
                          MetricaPerfilPublico(
                            valor: '${conta.seguindo.length}',
                            rotulo: 'Seguindo',
                            onTap: () => DialogListaConexoes.exibir(
                              context: context,
                              titulo: 'Seguindo',
                              cpfs: conta.seguindo,
                              theme: theme,
                              usuarioDonoLista: conta,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Biografia Soberana e Links Externos
                      PerfilBioLinksWidget(
                        theme: theme,
                        biografia: ehProprioUsuario
                            ? conta.biografia
                            : conta.biografiaPara(contaPropria?.cpf ?? ''),
                        links: conta.links,
                        textoSobreFundo: textoSobreFundo,
                        textoSecSobreFundo: textoSecSobreFundo,
                        corBordaPerfil: corBordaPerfil,
                        corDestaqueCustom: corDestaqueCustom,
                      ),

                      const SizedBox(height: 16),

                      // Botões de ação em fila rolante + validação de identidade
                      PerfilAcoesHeaderWidget(
                        theme: theme,
                        conta: conta,
                        contaPropria: contaPropria,
                        ehProprioUsuario: ehProprioUsuario,
                        textoSobreFundo: textoSobreFundo,
                        textoSecSobreFundo: textoSecSobreFundo,
                        onContaAtualizada: (atualizado) {
                          if (!mounted) return;
                          setState(() {
                            _contaAlvoAtualizada = atualizado;
                          });
                        },
                        onPerfilAtualizado: () {
                          if (mounted) setState(() {});
                        },
                      ),

                      const SizedBox(height: 18),

                      // Rede Social Nous: Stories + Carrossel Horizontal de Feeds
                      TimelinePerfilSection(
                        theme: theme,
                        contaPerfil: conta,
                        usuarioLogado: auth.contaAtual,
                        ehProprioUsuario: ehProprioUsuario,
                        scrollController: _perfilScrollCtrl,
                      ),

                      const SizedBox(height: 80), // Espaço para a barra flutuante
                    ],
                  ),
                ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: widget.mostrarBotaoVoltar
              ? null
              : const FloatingBottomNavBar(
                  maxWidth: _larguraMaximaConteudo,
                  slotSelecionado: 1,
                  subIndiceSelecionado: 0,
                ),
        );

        final habilitarCameraPorArrasto = ehProprioUsuario &&
            !kIsWeb &&
            (Platform.isAndroid || Platform.isIOS);

        if (!habilitarCameraPorArrasto) return perfilScaffold;

        return PageView(
          controller: _pageController,
          onPageChanged: (index) {
            if (mounted) setState(() => _paginaAtual = index);
          },
          children: [
            CameraCriacaoView(
              theme: theme,
              autor: conta,
              ativa: _paginaAtual == 0,
              onVoltarPerfil: () {
                if (_pageController.hasClients) {
                  _pageController.animateToPage(
                    1,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOut,
                  );
                }
              },
            ),
            perfilScaffold,
          ],
        );
      },
    );
  }
}
