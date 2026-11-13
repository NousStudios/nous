import 'dart:io';
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
import 'package:nous/src/features/auth/views/widgets/compartilhar_perfil_dialog.dart';
import 'package:nous/src/features/auth/views/widgets/editar_perfil_dialog.dart';
import 'package:nous/src/features/auth/views/widgets/selo_verificado_widget.dart';
import 'package:nous/src/features/auth/views/widgets/validacao_identidade_dialog.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/services/resolvedor_foto_chat.dart';
import 'package:nous/src/features/chat/views/mensageria_view.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';

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
  int _abaConteudoSelecionada = 0; // 0: Grade, 1: Vídeo, 2: Documento, 3: Música
  UsuarioNous? _contaAlvoAtualizada;
  String? _fotoLocalResolvida;
  bool _baixandoFoto = false;

  @override
  void initState() {
    super.initState();
    _contaAlvoAtualizada = widget.usuarioAlvo;
    _inicializarEAutocurarPerfil();
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

  Widget _buildBotaoPerfil({
    required AppTheme theme,
    required String rotulo,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
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
      ),
    );
  }

  Widget _buildMetricaItem(
    AppTheme theme,
    String valor,
    String rotulo, {
    VoidCallback? onTap,
  }) {
    final item = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          valor,
          style: theme.getTextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          rotulo,
          style: theme.getTextStyle(
            fontSize: 11,
            color: theme.secondaryTextColor,
          ),
        ),
      ],
    );

    if (onTap == null) return item;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: item,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final contaPropria = auth.contaAtual;
    final conta = _contaAlvoAtualizada ??
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

    final apelidoExibicao = conta.usernameExibicao;

    final nomeExibicao = conta.nomeExibicao.isNotEmpty
        ? conta.nomeExibicao
        : 'Usuário Nous';

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

        return Scaffold(
          backgroundColor: fundoFinal,
          appBar: CustomAppBar(
            title: '',
            showBackButton: widget.mostrarBotaoVoltar,
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _larguraMaximaConteudo),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cabeçalho Social Centralizado com Imagem Unificada e Autocura
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor:
                              theme.borderColor.withValues(alpha: 0.3),
                          backgroundImage: providerFoto,
                          child: !temFoto
                              ? (_baixandoFoto
                                  ? SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: theme.textColor,
                                      ),
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 52,
                                      color: theme.textColor,
                                    ))
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: TextoRolante(
                                texto: apelidoExibicao,
                                textAlign: TextAlign.center,
                                style: theme.getTextStyle(
                                  fontSize: 13,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                            ),
                            if (conta.possuiValidacao) ...[
                              const SizedBox(width: 5),
                              SeloVerificadoWidget(
                                usuario: conta,
                                theme: theme,
                                tamanho: 17,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: TextoRolante(
                          texto: nomeExibicao,
                          textAlign: TextAlign.center,
                          style: theme.getTextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 330),
                          child: Row(
                            children: [
                              Expanded(
                                child: Center(
                                  child: _buildMetricaItem(theme, '0', 'Posts'),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: _buildMetricaItem(
                                    theme,
                                    '${conta.seguidores.length}',
                                    'Seguidores',
                                    onTap: () {
                                      DialogListaConexoes.exibir(
                                        context: context,
                                        titulo: 'Seguidores',
                                        cpfs: conta.seguidores,
                                        theme: theme,
                                        usuarioDonoLista: conta,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: _buildMetricaItem(
                                    theme,
                                    '${conta.seguindo.length}',
                                    'Seguindo',
                                    onTap: () {
                                      DialogListaConexoes.exibir(
                                        context: context,
                                        titulo: 'Seguindo',
                                        cpfs: conta.seguindo,
                                        theme: theme,
                                        usuarioDonoLista: conta,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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
                        child: Text(
                          conta.biografia.isNotEmpty
                              ? conta.biografia
                              : 'Membro soberano da rede local Nous • SuperApp de Autogestão',
                          textAlign: TextAlign.center,
                          style: theme.getTextStyle(
                            fontSize: 12,
                            color: textoSecSobreFundo,
                          ),
                        ),
                      ),
                      if (conta.links.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            for (final link in conta.links)
                              InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: link));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor:
                                          theme.cardBackgroundColor,
                                      content: Text(
                                        'Link copiado: $link',
                                        style: theme.getTextStyle(
                                          color: theme.textColor,
                                        ),
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: corBordaPerfil
                                          .withValues(alpha: 0.65),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.link_rounded,
                                        size: 13,
                                        color: corDestaqueCustom ??
                                            textoSobreFundo,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        link,
                                        style: theme.getTextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: textoSobreFundo,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Botões de ação
                      Row(
                        children: [
                          if (ehProprioUsuario) ...[
                            _buildBotaoPerfil(
                              theme: theme,
                              rotulo: 'Editar Perfil',
                              onTap: () => _abrirEdicaoPerfil(context, theme, conta),
                            ),
                            const SizedBox(width: 8),
                          ] else if (contaPropria != null) ...[
                            _buildBotaoPerfil(
                              theme: theme,
                              rotulo: contaPropria.estaSeguindo(conta.cpf)
                                  ? 'Seguindo'
                                  : 'Seguir',
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
                            onTap: () =>
                                _compartilharPerfil(context, theme, conta),
                          ),
                          const SizedBox(width: 8),
                          _buildBotaoPerfil(
                            theme: theme,
                            rotulo: 'Mensagens',
                            onTap: () => _abrirMensagensUsuario(context, conta),
                          ),
                        ],
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

                      // Destaques / Stories (Carrossel Horizontal de Círculos)
                      SizedBox(
                        height: 64,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: 8,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            return Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.cardBackgroundColor,
                                border: Border.all(
                                  color: theme.borderColor.withValues(alpha: 0.5),
                                  width: 1.2,
                                ),
                              ),
                              child: Icon(
                                Icons.add,
                                size: 20,
                                color: theme.secondaryTextColor.withValues(alpha: 0.6),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Divisor
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: theme.borderColor.withValues(alpha: 0.4),
                      ),

                      // Abas de Conteúdo (Grade | Vídeo | Documento | Música)
                      Row(
                        children: [
                          _buildAbaIcone(theme, 0, Icons.grid_on_sharp),
                          _buildAbaIcone(theme, 1, Icons.play_circle_outline_rounded),
                          _buildAbaIcone(theme, 2, Icons.description_outlined),
                          _buildAbaIcone(theme, 3, Icons.music_note_outlined),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Grade de Conteúdo Social (3 colunas estilo protótipo)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 9,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          childAspectRatio: 1.0,
                        ),
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: BoxDecoration(
                              color: theme.cardBackgroundColor.withValues(alpha: 0.4),
                              border: Border.all(
                                color: theme.borderColor.withValues(alpha: 0.4),
                                width: 0.8,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 22,
                                color: theme.secondaryTextColor.withValues(alpha: 0.3),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 80), // Espaço para a barra flutuante
                    ],
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
      },
    );
  }

  Widget _buildAbaIcone(AppTheme theme, int index, IconData icone) {
    final selecionada = _abaConteudoSelecionada == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _abaConteudoSelecionada = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selecionada ? theme.textColor : Colors.transparent,
                width: 2.0,
              ),
            ),
          ),
          child: Icon(
            icone,
            size: 20,
            color: selecionada ? theme.textColor : theme.secondaryTextColor,
          ),
        ),
      ),
    );
  }
}
