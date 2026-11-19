import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/core/widgets/floating_bottom_nav_bar.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/auth/views/dialogs/dialog_lista_conexoes.dart';
import 'package:nous/src/features/auth/views/helpers/perfil_foto_publica_helper.dart';
import 'package:nous/src/features/auth/views/widgets/cabecalho_perfil_publico_widget.dart';
import 'package:nous/src/features/auth/views/widgets/compartilhar_perfil_dialog.dart';
import 'package:nous/src/features/auth/views/widgets/editar_perfil_dialog.dart';
import 'package:nous/src/features/auth/views/widgets/selo_verificado_widget.dart';
import 'package:nous/src/features/auth/views/widgets/validacao_identidade_dialog.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/services/resolvedor_foto_chat.dart';
import 'package:nous/src/features/chat/views/mensageria_view.dart';
import 'package:nous/src/features/chat/views/widgets/visualizador_imagem_chat_dialog.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/central_conta_social_view.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_denuncia_social.dart';
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
  static const double _offsetInicialBotaoConta = 86.0;
  final PageController _pageController = PageController(initialPage: 1);
  final ScrollController _botoesAcaoScrollCtrl = ScrollController();
  bool _offsetInicialAplicado = false;
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
    _botoesAcaoScrollCtrl.dispose();
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
    if (oldWidget.usuarioAlvo != widget.usuarioAlvo) {
      _contaAlvoAtualizada = widget.usuarioAlvo;
      _fotoLocalResolvida = null;
      _inicializarEAutocurarPerfil();
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

  Future<void> _abrirEdicaoPerfil(
    BuildContext context,
    AppTheme theme,
    UsuarioNous conta,
  ) async {
    final atualizou = await showDialog<bool>(
      context: context,
      builder: (_) => EditarPerfilDialog(usuario: conta),
    );
    if (atualizou == true && mounted) {
      setState(() {});
    }
  }

  void _compartilharPerfil(BuildContext context, AppTheme theme, UsuarioNous conta) {
    CompartilharPerfilDialog.mostrar(
      context: context,
      theme: theme,
      conta: conta,
    );
  }

  void _abrirMensagensUsuario(BuildContext context, UsuarioNous conta) {
    final auth = context.read<AuthProvider>();
    final meuCpf = auth.contaAtual?.cpf ?? auth.cpf;
    final ehMeuProprioPerfil =
        ChatService.normalizarCpf(meuCpf) == ChatService.normalizarCpf(conta.cpf);

    if (ehMeuProprioPerfil) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const MensageriaView(
            modoLoja: false,
          ),
        ),
      );
      return;
    }

    final meuCpfNorm = ChatService.normalizarCpf(meuCpf);
    if (conta.quemPodeEnviarMensagens == 'apenas_seguidos' &&
        !conta.estaSeguindo(meuCpfNorm)) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Mensagens Restritas',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            '${conta.nomeExibicao} configurou o perfil para receber mensagens diretas apenas de pessoas que ele segue.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    final idConversaDireta = ChatService.conversaIdEntreUsuarios(meuCpf, conta.cpf);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MensageriaView(
          modoLoja: false,
          conversaInicialId: idConversaDireta,
        ),
      ),
    );
  }

  Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final limpo = hex.replaceAll('#', '');
    if (limpo.length != 6) return null;
    final val = int.tryParse('FF$limpo', radix: 16);
    return val != null ? Color(val) : null;
  }

  Future<void> _abrirOuCopiarLink(
    BuildContext context,
    AppTheme theme,
    String link,
  ) async {
    final linkLimpo = link.trim();
    final uri = Uri.tryParse(
      linkLimpo.startsWith('http://') || linkLimpo.startsWith('https://')
          ? linkLimpo
          : 'https://$linkLimpo',
    );
    if (uri != null) {
      try {
        final abriu = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (abriu) return;
      } catch (_) {}
    }
    if (!context.mounted) return;
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardBackgroundColor,
        content: Text(
          'Link copiado: $link',
          style: theme.getTextStyle(color: theme.textColor),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _abrirJanelaTodosLinks(
    BuildContext context,
    AppTheme theme,
    List<String> links,
    Color corBorda,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.borderColor),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.70,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                child: Row(
                  children: [
                    const SizedBox(width: 32),
                    Expanded(
                      child: Text(
                        'Links',
                        textAlign: TextAlign.center,
                        style: theme.getTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.secondaryTextColor),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.borderColor.withValues(alpha: 0.4)),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(14),
                  itemCount: links.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final link = links[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _abrirOuCopiarLink(context, theme, link),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: corBorda.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.link_rounded,
                              size: 16,
                              color: theme.buttonColor,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                link,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.getTextStyle(
                                  fontSize: 13,
                                  color: theme.textColor,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Copiar link',
                              icon: Icon(
                                Icons.copy_rounded,
                                size: 16,
                                color: theme.secondaryTextColor,
                              ),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: link));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Link copiado: $link'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
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

  Widget _buildBotaoPerfil({
    required AppTheme theme,
    required String rotulo,
    required VoidCallback onTap,
    double? largura,
  }) {
    final conteudo = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.borderColor.withValues(alpha: 0.8),
            width: 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: TextoRolante(
          texto: rotulo,
          textAlign: TextAlign.center,
          style: theme.getTextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
      ),
    );
    if (largura != null) {
      return SizedBox(width: largura, child: conteudo);
    }
    return Expanded(child: conteudo);
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
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _larguraMaximaConteudo),
                child: RefreshIndicator(
                  color: theme.buttonColor,
                  backgroundColor: theme.cardBackgroundColor,
                  onRefresh: _aoPuxarParaAtualizar,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

                      // Biografia Soberana
                      Center(
                        child: Text(
                          'Biografia',
                          style: theme.getTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textoSobreFundo,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Builder(
                          builder: (_) {
                            final bioExibida = ehProprioUsuario
                                ? conta.biografia
                                : conta.biografiaPara(contaPropria?.cpf ?? '');
                            return Text(
                              bioExibida.isNotEmpty
                                  ? bioExibida
                                  : 'Membro soberano da rede local Nous • SuperApp de Autogestão',
                              textAlign: TextAlign.center,
                              style: theme.getTextStyle(
                                fontSize: 12,
                                color: textoSecSobreFundo,
                              ),
                            );
                          },
                        ),
                      ),
                      if (conta.links.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Center(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              if (conta.links.length == 1) {
                                _abrirOuCopiarLink(
                                  context,
                                  theme,
                                  conta.links.first,
                                );
                              } else {
                                _abrirJanelaTodosLinks(
                                  context,
                                  theme,
                                  conta.links,
                                  corBordaPerfil,
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: corBordaPerfil.withValues(alpha: 0.65),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.link_rounded,
                                    size: 14,
                                    color: corDestaqueCustom ?? textoSobreFundo,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      conta.links.length == 1
                                          ? conta.links.first
                                          : '${conta.links.first}  •  +${conta.links.length - 1} link(s)',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.getTextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: textoSobreFundo,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Botões de ação em fila rolante (Conta à esquerda + 3 botões em destaque + escudinho de denúncia à direita)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final qtdPrincipais =
                              (ehProprioUsuario || contaPropria != null) ? 3 : 2;
                          final larguraBotao =
                              (constraints.maxWidth - ((qtdPrincipais - 1) * 8)) /
                                  qtdPrincipais;

                          if (ehProprioUsuario && !_offsetInicialAplicado) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              if (_botoesAcaoScrollCtrl.hasClients) {
                                _offsetInicialAplicado = true;
                                _botoesAcaoScrollCtrl.jumpTo(
                                  _offsetInicialBotaoConta,
                                );
                              }
                            });
                          }

                          return SingleChildScrollView(
                            controller: _botoesAcaoScrollCtrl,
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                if (ehProprioUsuario) ...[
                                  _buildBotaoPerfil(
                                    theme: theme,
                                    rotulo: 'Conta',
                                    largura: 76,
                                    onTap: () => CentralContaSocialView.abrir(
                                      context,
                                      theme: theme,
                                      usuario: conta,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  _buildBotaoPerfil(
                                    theme: theme,
                                    rotulo: 'Editar Perfil',
                                    largura: larguraBotao,
                                    onTap: () =>
                                        _abrirEdicaoPerfil(context, theme, conta),
                                  ),
                                  const SizedBox(width: 8),
                                ] else if (contaPropria != null) ...[
                                  _buildBotaoPerfil(
                                    theme: theme,
                                    rotulo: contaPropria.estaSeguindo(conta.cpf)
                                        ? 'Seguindo'
                                        : 'Seguir',
                                    largura: larguraBotao,
                                    onTap: () async {
                                      await auth.alternarSeguir(conta.cpf);
                                      if (mounted) setState(() {});
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                _buildBotaoPerfil(
                                  theme: theme,
                                  rotulo: 'Compartilhar',
                                  largura: larguraBotao,
                                  onTap: () =>
                                      _compartilharPerfil(context, theme, conta),
                                ),
                                const SizedBox(width: 8),
                                _buildBotaoPerfil(
                                  theme: theme,
                                  rotulo: 'Mensagens',
                                  largura: larguraBotao,
                                  onTap: () =>
                                      _abrirMensagensUsuario(context, conta),
                                ),
                                const SizedBox(width: 8),
                                if (contaPropria != null && !ehProprioUsuario)
                                  Tooltip(
                                    message: 'Silenciar ou Bloquear',
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () async {
                                        final bloqueado =
                                            contaPropria.estaBloqueado(conta.cpf);
                                        final silenciado =
                                            contaPropria.estaSilenciado(conta.cpf);
                                        final acao = await showDialog<String>(
                                          context: context,
                                          builder: (ctx) => Dialog(
                                            backgroundColor:
                                                theme.cardBackgroundColor,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              side: BorderSide(
                                                color: theme.borderColor,
                                              ),
                                            ),
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 340,
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(14),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    ListTile(
                                                      leading: Icon(
                                                        silenciado
                                                            ? Icons.volume_up_outlined
                                                            : Icons.volume_off_outlined,
                                                        color: theme.textColor,
                                                      ),
                                                      title: Text(
                                                        silenciado
                                                            ? 'Dessilenciar usuário'
                                                            : 'Silenciar usuário',
                                                        style: theme.getTextStyle(
                                                          fontSize: 13.5,
                                                          color: theme.textColor,
                                                        ),
                                                      ),
                                                      onTap: () => Navigator.pop(
                                                        ctx,
                                                        'silenciar',
                                                      ),
                                                    ),
                                                    ListTile(
                                                      leading: Icon(
                                                        bloqueado
                                                            ? Icons.lock_open_outlined
                                                            : Icons.block_rounded,
                                                        color: theme.dangerColor,
                                                      ),
                                                      title: Text(
                                                        bloqueado
                                                            ? 'Desbloquear usuário'
                                                            : 'Bloquear usuário',
                                                        style: theme.getTextStyle(
                                                          fontSize: 13.5,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: theme.dangerColor,
                                                        ),
                                                      ),
                                                      onTap: () => Navigator.pop(
                                                        ctx,
                                                        'bloquear',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                        if (!context.mounted || acao == null) {
                                          return;
                                        }
                                        if (acao == 'silenciar') {
                                          await context
                                              .read<AuthProvider>()
                                              .alternarSilenciarUsuario(
                                                conta.cpf,
                                              );
                                        } else if (acao == 'bloquear') {
                                          await context
                                              .read<AuthProvider>()
                                              .alternarBloquearUsuario(
                                                conta.cpf,
                                              );
                                        }
                                      },
                                      child: Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: theme.borderColor
                                                .withValues(alpha: 0.6),
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Icon(
                                          contaPropria.estaBloqueado(conta.cpf)
                                              ? Icons.block_rounded
                                              : Icons.more_horiz_rounded,
                                          size: 17,
                                          color: contaPropria
                                                  .estaBloqueado(conta.cpf)
                                              ? theme.dangerColor
                                              : textoSobreFundo,
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                if (contaPropria != null && !ehProprioUsuario)
                                  Tooltip(
                                    message: 'Denunciar',
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () async {
                                            final ok =
                                                await DialogDenunciaSocial
                                                    .mostrar(
                                              context,
                                              theme: theme,
                                              denunciante: contaPropria,
                                              alvoCpf: conta.cpf,
                                              alvoNome: conta.nomeExibicao,
                                            );
                                            if (ok == true && context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Denúncia registrada.',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                    child: Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: theme.borderColor
                                              .withValues(alpha: 0.6),
                                          width: 1.0,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.shield_outlined,
                                        size: 16,
                                        color: theme.secondaryTextColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      if (!ehProprioUsuario &&
                          contaPropria != null &&
                          !conta.jaValidadoPor(contaPropria.cpf)) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () async {
                              final atualizado =
                                  await ValidacaoIdentidadeDialog.mostrar(
                                context: context,
                                alvo: conta,
                                theme: theme,
                              );
                              if (atualizado != null && mounted) {
                                setState(() {
                                  _contaAlvoAtualizada = atualizado;
                                });
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_user_outlined,
                                    size: 13,
                                    color: textoSecSobreFundo,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Validar identidade',
                                    style: theme.getTextStyle(
                                      fontSize: 11.5,
                                      color: textoSecSobreFundo,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      // Rede Social Nous: Stories + Carrossel Horizontal de Feeds
                      TimelinePerfilSection(
                        theme: theme,
                        contaPerfil: conta,
                        usuarioLogado: auth.contaAtual,
                        ehProprioUsuario: ehProprioUsuario,
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
