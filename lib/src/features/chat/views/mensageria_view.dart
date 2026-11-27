import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/views/perfil_social_view.dart';
import 'package:nous/src/features/chat/controllers/helpers/mensageria_filtros_helper.dart';
import 'package:nous/src/features/chat/controllers/mensageria_controller.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/services/chat_autoatendimento_service.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/services/gravador_audio_service.dart';
import 'package:nous/src/features/chat/services/mensageria_acoes_delegate.dart';
import 'package:nous/src/features/chat/views/dialogs/dialog_criar_grupo.dart';
import 'package:nous/src/features/chat/views/dialogs/dialog_detalhes_contato.dart';
import 'package:nous/src/features/chat/views/dialogs/dialog_editar_ficha_cliente_loja.dart';
import 'package:nous/src/features/chat/views/dialogs/dialog_editar_mensagem.dart';
import 'package:nous/src/features/chat/views/dialogs/dialog_encaminhar_mensagem.dart';
import 'package:nous/src/features/chat/views/dialogs/dialog_fazer_pedido_chat.dart';
import 'package:nous/src/features/chat/views/dialogs/dialog_historico_edicoes.dart';
import 'package:nous/src/features/chat/views/dialogs/dialog_menu_mensagem.dart';
import 'package:nous/src/features/chat/views/dialogs/dialog_nova_conversa.dart';
import 'package:nous/src/features/chat/views/dialogs/dialog_renomear_conversa.dart';
import 'package:nous/src/features/chat/views/widgets/barra_navegacao_mensageria_widget.dart';
import 'package:nous/src/features/chat/views/widgets/lista_conversas_widget.dart';
import 'package:nous/src/features/chat/views/widgets/painel_comunidades_widget.dart';
import 'package:nous/src/features/chat/views/widgets/painel_conversa_ativa_widget.dart';
import 'package:nous/src/features/chat/views/widgets/painel_ligacoes_widget.dart';
import 'package:nous/src/features/chat/views/widgets/painel_lista_transmissao_widget.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

class MensageriaView extends StatefulWidget {
  final bool modoLoja;
  final String? lojaId;
  final String? nomeLoja;
  final String? logoLoja;
  final String? operadorNome;
  final String? operadorCpf;
  final String? usuarioNome;
  final String? usuarioCpf;
  final String? usuarioFoto;
  final String? usuarioApelido;
  final bool mostrarBotaoVoltar;
  final String? conversaInicialId;

  const MensageriaView({
    super.key,
    this.modoLoja = false,
    this.lojaId,
    this.nomeLoja,
    this.logoLoja,
    this.operadorNome,
    this.operadorCpf,
    this.usuarioNome,
    this.usuarioCpf,
    this.usuarioFoto,
    this.usuarioApelido,
    this.mostrarBotaoVoltar = true,
    this.conversaInicialId,
  });

  @override
  State<MensageriaView> createState() => _MensageriaViewState();
}

class _MensageriaViewState extends State<MensageriaView>
    with WidgetsBindingObserver {
  final MensageriaController _controller = MensageriaController();
  bool _inicializado = false;
  Timer? _debounceAtualizarChat;
  AuthProvider? _authProvider;
  String _ultimoCpfAuth = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.configurar(
      modoLoja: widget.modoLoja,
      lojaId: widget.lojaId,
      nomeLoja: widget.nomeLoja,
      logoLoja: widget.logoLoja,
      operadorNome: widget.operadorNome,
      operadorCpf: widget.operadorCpf,
      usuarioNome: widget.usuarioNome,
      usuarioCpf: widget.usuarioCpf,
      usuarioFoto: widget.usuarioFoto,
      usuarioApelido: widget.usuarioApelido,
      conversaInicialId: widget.conversaInicialId,
    );
    _controller.addListener(_aoAtualizarController);
    ChatService.alteracoesChatNotifier.addListener(_aoAtualizarChat);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inicializado) {
      final auth = context.read<AuthProvider>();
      final pdv = context.read<PdvProvider>();
      _authProvider = auth;
      _ultimoCpfAuth = (auth.contaAtual?.cpf ?? auth.cpf).trim();
      auth.addListener(_aoAtualizarAuth);
      _controller.inicializar(auth: auth, pdv: pdv);
      _inicializado = true;
    }
  }

  void _aoAtualizarAuth() {
    if (!mounted || _controller.isDisposed || _authProvider == null) return;
    final novoCpf = (_authProvider!.contaAtual?.cpf ?? _authProvider!.cpf).trim();
    if (novoCpf.isNotEmpty && novoCpf != _ultimoCpfAuth) {
      _ultimoCpfAuth = novoCpf;
      if (!widget.modoLoja) {
        _controller.usuarioCpf = novoCpf;
      }
      _controller.recarregarConversas(
        auth: _authProvider!,
        pdv: context.read<PdvProvider>(),
        manterSelecionada: true,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        mounted &&
        !_controller.isDisposed) {
      final auth = context.read<AuthProvider>();
      final pdv = context.read<PdvProvider>();
      _controller.recarregarConversas(
        auth: auth,
        pdv: pdv,
        manterSelecionada: true,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounceAtualizarChat?.cancel();
    _authProvider?.removeListener(_aoAtualizarAuth);
    ChatService.alteracoesChatNotifier.removeListener(_aoAtualizarChat);
    _controller.removeListener(_aoAtualizarController);
    GravadorAudioService.instancia.cancelarGravacao();
    _controller.limpar();
    _controller.dispose();
    super.dispose();
  }

  void _aoAtualizarController() {
    if (mounted && !_controller.isDisposed) setState(() {});
  }

  void _aoAtualizarChat() {
    if (!mounted || _controller.isDisposed) return;
    // 1. Atualização ultra-rápida (sub-5ms) das mensagens na conversa aberta
    if (_controller.conversaSelecionada != null) {
      _controller.recarregarMensagensConversaAtiva();
    }
    // 2. Debounce na recarga da lista geral de contatos e lojas (evita travamentos em rajada)
    _debounceAtualizarChat?.cancel();
    _debounceAtualizarChat = Timer(const Duration(milliseconds: 650), () {
      if (!mounted || _controller.isDisposed) return;
      final auth = context.read<AuthProvider>();
      final pdv = context.read<PdvProvider>();
      _controller.recarregarConversas(
        auth: auth,
        pdv: pdv,
        manterSelecionada: true,
      );
    });
  }

  bool _larguraDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 720;
  }

  void _abrirCriarGrupo(AppTheme theme) {
    final pdv = context.read<PdvProvider>();
    final auth = context.read<AuthProvider>();
    final conta = auth.contaAtual;
    final Map<String, String> participantes = {};

    final todasLojas = [...pdv.lojasQueAdministro, ...pdv.lojasQueParticipo];
    for (final loja in todasLojas) {
      for (final m in loja.membros) {
        if (ChatService.normalizarCpf(m.cpf) !=
            ChatService.normalizarCpf(conta?.cpf ?? '')) {
          participantes[m.cpf] = m.nome;
        }
      }
    }

    DialogCriarGrupo.mostrar(
      context,
      theme: theme,
      participantesDisponiveis: participantes,
      lojaId: widget.modoLoja ? widget.lojaId : null,
      criadorCpf: conta?.cpf,
      criadorNome: conta?.nomeExibicao,
      onCriado: (grupo) {
        _controller.selecionarOuIniciarConversa(
          convId: grupo.id,
          titulo: grupo.titulo,
          subtitulo: grupo.subtitulo,
          identificador: grupo.identificador,
          foto: grupo.foto,
          ehLoja: grupo.ehLoja,
        );
      },
    );
  }

  Widget _buildPainelConversa(AppTheme theme, {required bool desktop}) {
    return PainelConversaAtivaWidget(
      controller: _controller,
      theme: theme,
      desktop: desktop,
      onVoltarMobile: () => _controller.selecionarConversa(null),
      onAbrirDetalhes: (c) {
        final auth = context.read<AuthProvider>();
        DialogDetalhesContato.mostrar(
          context,
          theme: theme,
          conversa: c,
          contaLogada: auth.contaAtual,
          onSelecionarFotoGrupo: () =>
              MensageriaAcoesDelegate.selecionarFotoGrupo(),
          onExportarBackup: (conv) =>
              MensageriaAcoesDelegate.exportarBackupConversa(context, conv),
          onSolicitarExclusao: (conv) =>
              MensageriaAcoesDelegate.solicitarExclusaoConversa(
            context: context,
            controller: _controller,
            conversa: conv,
            lojaId: widget.lojaId,
          ),
          onSolicitarSaidaGrupo: (conv) =>
              MensageriaAcoesDelegate.solicitarSaidaDoGrupo(
            context: context,
            controller: _controller,
            conversa: conv,
          ),
          onVisualizarFotoAmpliada: (caminho) =>
              MensageriaAcoesDelegate.visualizarFotoAmpliada(
            context: context,
            theme: theme,
            caminho: caminho,
          ),
          onAbrirArquivo: (caminho) =>
              MensageriaAcoesDelegate.abrirArquivo(context, caminho),
          onRenomearConversa: (conv) => _abrirDialogRenomear(conv, theme),
          onAbrirMinhaFichaLoja: (conv) async {
            final pdv = context.read<PdvProvider>();
            final auth = context.read<AuthProvider>();
            final lojaIdAlvo =
                (conv.lojaId != null && conv.lojaId!.isNotEmpty)
                ? conv.lojaId!
                : (conv.identificador.isNotEmpty ? conv.identificador : conv.id);
            final loja = await ChatAutoatendimentoService.obterLojaCatalogo(
              lojaIdBruto: lojaIdAlvo,
              pdv: pdv,
            );
            if (loja != null && auth.contaAtual != null) {
              final cliente =
                  await ChatAutoatendimentoService.resolverOuCriarFichaCliente(
                loja: loja,
                usuario: auth.contaAtual!,
                pdv: pdv,
              );
              if (mounted) {
                DialogEditarFichaClienteLoja.mostrar(
                  context: context,
                  theme: theme,
                  lojaId: loja.id,
                  cliente: cliente,
                );
              }
            }
          },
        );
      },
      onRenomearConversa: (c) {
        DialogRenomearConversa.mostrar(
          context,
          theme: theme,
          conversa: c,
          titulosCustomizados: _controller.titulosCustomizados,
          onSalvar: (novo) {
            final auth = context.read<AuthProvider>();
            final pdv = context.read<PdvProvider>();
            return _controller.renomearConversa(
              c,
              novo,
              auth: auth,
              pdv: pdv,
            );
          },
        );
      },
      onMostrarMenuMensagem: (msg) {
        DialogMenuMensagem.mostrar(
          context,
          theme: theme,
          msg: msg,
          onReagir: (emoji) => _controller.reagirMensagem(msg, emoji),
          onAlternarFixada: () => _controller.alternarFixarMensagem(msg),
          onEditar: () {
            DialogEditarMensagem.mostrar(
              context,
              theme: theme,
              msg: msg,
              onSalvar: (novo) => _controller.editarMensagem(msg, novo),
            );
          },
          onEncaminhar: () {
            final mapaDestinos = <String, ConversaChat>{
              for (final c in _controller.conversas) c.id: c,
            };
            for (final c in _controller.todosContatosDisponiveis) {
              mapaDestinos.putIfAbsent(c.id, () => c);
            }
            final destinos = mapaDestinos.values
                .where(
                  (c) =>
                      c.id != _controller.conversaSelecionada?.id &&
                      c.identificador != PdvProvider.idLojaColetivaNous &&
                      !c.id.contains(PdvProvider.idLojaColetivaNous),
                )
                .toList();
            DialogEncaminharMensagem.mostrar(
              context,
              theme: theme,
              msg: msg,
              conversasDisponiveis: destinos,
              onEncaminhar: (destino) async {
                final auth = context.read<AuthProvider>();
                final pdv = context.read<PdvProvider>();
                await _controller.encaminharMensagem(
                  msgOriginal: msg,
                  destino: destino,
                  auth: auth,
                );
                await _controller.recarregarConversas(
                  auth: auth,
                  pdv: pdv,
                  manterSelecionada: true,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: theme.cardBackgroundColor,
                    content: Text(
                      'Mensagem encaminhada para ${destino.titulo}.',
                      style: theme.getTextStyle(
                        fontSize: 12.5,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                );
              },
            );
          },
          onAlternarFavorita: () =>
              _controller.alternarFavoritarMensagem(msg),
          onVerHistorico: () {
            DialogHistoricoEdicoes.mostrar(
              context,
              theme: theme,
              msg: msg,
            );
          },
          onExcluir: () => _controller.excluirMensagemLocal(msg),
        );
      },
      onVerHistoricoEdicoes: (msg) {
        DialogHistoricoEdicoes.mostrar(
          context,
          theme: theme,
          msg: msg,
        );
      },
      onAbrirArquivo: (caminho) =>
          MensageriaAcoesDelegate.abrirArquivo(context, caminho),
      onVisualizarFotoAmpliada: (caminho) =>
          MensageriaAcoesDelegate.visualizarFotoAmpliada(
        context: context,
        theme: theme,
        caminho: caminho,
      ),
      onVerComanda: (msg) => MensageriaAcoesDelegate.abrirComandaDoChat(
        context: context,
        msg: msg,
        lojaId: widget.lojaId,
      ),
      onEnviarTexto: (texto) {
        final auth = context.read<AuthProvider>();
        _controller.enviarMensagem(
          texto: texto,
          auth: auth,
        );
      },
      onEnviarAudio: (caminho, duracao, tamanho) {
        final auth = context.read<AuthProvider>();
        _controller.enviarMensagem(
          texto: 'Mensagem de voz ($duracao)',
          tipo: 'audio',
          caminhoAnexo: caminho,
          nomeAnexo: p.basename(caminho),
          tamanhoAnexo: tamanho,
          auth: auth,
        );
      },
      onCapturarFotoCamera: () =>
          MensageriaAcoesDelegate.capturarFotoCamera(
        context: context,
        controller: _controller,
      ),
      onAnexarFoto: () => MensageriaAcoesDelegate.anexarFoto(
        context: context,
        controller: _controller,
      ),
      onAnexarArquivo: () => MensageriaAcoesDelegate.anexarArquivo(
        context: context,
        controller: _controller,
      ),
      onCompartilharContato: () =>
          MensageriaAcoesDelegate.compartilharContato(
        context: context,
        controller: _controller,
        theme: theme,
      ),
      onCompartilharComanda: () =>
          MensageriaAcoesDelegate.abrirDialogCompartilharComanda(
        context: context,
        theme: theme,
        controller: _controller,
        modoLoja: widget.modoLoja,
        lojaId: widget.lojaId,
      ),
      onFazerPedido: (c) => DialogFazerPedidoChat.mostrar(
        context: context,
        theme: theme,
        conversa: c,
        controller: _controller,
      ),
    );
  }

  Widget _buildListaConversas(AppTheme theme) {
    return ListaConversasWidget(
      controller: _controller,
      theme: theme,
      onAbrirNovaConversa: () {
        DialogNovaConversa.mostrar(
          context,
          theme: theme,
          todosContatosDisponiveis: _controller.todosContatosDisponiveis,
          onSelecionarContato: (c) {
            _controller.selecionarOuIniciarConversa(
              convId: c.id,
              titulo: c.titulo,
              subtitulo: c.subtitulo,
              identificador: c.identificador,
              foto: c.foto,
              ehLoja: c.ehLoja,
            );
          },
        );
      },
      onAbrirCriarGrupo: () => _abrirCriarGrupo(theme),
      onSelecionarConversa: (c) {
        _controller.selecionarConversa(c);
      },
      onAlternarFixar: (c) {
        final auth = context.read<AuthProvider>();
        final pdv = context.read<PdvProvider>();
        _controller.alternarFixar(
          c,
          auth: auth,
          pdv: pdv,
        );
      },
      onAlternarArquivar: (c) {
        final auth = context.read<AuthProvider>();
        final pdv = context.read<PdvProvider>();
        _controller.alternarArquivar(
          c,
          auth: auth,
          pdv: pdv,
        );
      },
      onAlternarSilenciar: (c) {
        final auth = context.read<AuthProvider>();
        final pdv = context.read<PdvProvider>();
        _controller.alternarSilenciar(
          c,
          auth: auth,
          pdv: pdv,
        );
      },
      onRenomearConversa: (c) => _abrirDialogRenomear(c, theme),
      onExcluirConversa: (c) {
        MensageriaAcoesDelegate.solicitarExclusaoConversa(
          context: context,
          controller: _controller,
          conversa: c,
          lojaId: widget.lojaId,
        );
      },
    );
  }

  void _abrirDialogRenomear(ConversaChat c, AppTheme theme) {
    DialogRenomearConversa.mostrar(
      context,
      theme: theme,
      conversa: c,
      titulosCustomizados: _controller.titulosCustomizados,
      onSalvar: (novo) {
        final auth = context.read<AuthProvider>();
        final pdv = context.read<PdvProvider>();
        return _controller.renomearConversa(
          c,
          novo,
          auth: auth,
          pdv: pdv,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final desktop = _larguraDesktop(context);

    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        final titulo = widget.modoLoja
            ? 'Mensagens — ${widget.nomeLoja ?? "Loja"}'
            : 'Mensagens';
        final bool barraUniversalDesabilitadaNoDesktop =
            desktop && _controller.conversaSelecionada != null;

        return PopScope(
          canPop: _controller.conversaSelecionada == null &&
              _controller.abaAtiva == AbaNavegacaoMensageria.conversas,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (_controller.conversaSelecionada != null) {
              _controller.selecionarConversa(null);
            } else if (_controller.abaAtiva !=
                AbaNavegacaoMensageria.conversas) {
              _controller.selecionarAba(AbaNavegacaoMensageria.conversas);
            }
          },
          child: Scaffold(
            backgroundColor: theme.backgroundColor,
            appBar: CustomAppBar(
              title: titulo,
              showBackButton:
                  widget.mostrarBotaoVoltar ||
                  barraUniversalDesabilitadaNoDesktop,
              onBackPressed: () {
                if (_controller.conversaSelecionada != null) {
                  _controller.selecionarConversa(null);
                } else if (_controller.abaAtiva !=
                    AbaNavegacaoMensageria.conversas) {
                  _controller.selecionarAba(AbaNavegacaoMensageria.conversas);
                } else if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) =>
                          const PerfilSocialView(mostrarBotaoVoltar: false),
                    ),
                    (route) => false,
                  );
                }
              },
            ),
            body: SafeArea(
              child: Builder(
                builder: (context) {
                  final estadoAcesso = context.select<AuthProvider,
                      ({bool visitante, bool isolado})>(
                    (a) => (
                      visitante: a.modoVisitante,
                      isolado: a.perfilIsolado,
                    ),
                  );
                  if (estadoAcesso.visitante || estadoAcesso.isolado) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: EstadoVazioContainer(
                            theme: theme,
                            mensagem: estadoAcesso.visitante
                                ? 'Você está no Modo Visitante. Entre com sua Conta Nous verificada para acessar as mensagens.'
                                : 'Seu perfil está em Modo Isolado aguardando verificação. As mensagens com outros usuários serão liberadas após a primeira validação.',
                          ),
                        ),
                      ),
                    );
                  }
                  if (desktop) {
                    final barraVertical = BarraNavegacaoMensageriaWidget(
                      theme: theme,
                      abaAtiva: _controller.abaAtiva,
                      totalNaoLidas: _controller.totalConversasNaoLidas,
                      onSelecionarAba: _controller.selecionarAba,
                    );

                    Widget conteudoPrincipal;
                    if (_controller.abaAtiva ==
                        AbaNavegacaoMensageria.ligacoes) {
                      conteudoPrincipal = Expanded(
                        child: PainelLigacoesWidget(
                          controller: _controller,
                          theme: theme,
                        ),
                      );
                    } else if (_controller.abaAtiva ==
                        AbaNavegacaoMensageria.comunidades) {
                      conteudoPrincipal = Expanded(
                        child: PainelComunidadesWidget(
                          controller: _controller,
                          theme: theme,
                          desktop: true,
                        ),
                      );
                    } else if (_controller.abaAtiva ==
                        AbaNavegacaoMensageria.transmissao) {
                      conteudoPrincipal = Expanded(
                        child: PainelListaTransmissaoWidget(
                          controller: _controller,
                          theme: theme,
                          desktop: true,
                        ),
                      );
                    } else {
                      conteudoPrincipal = Expanded(
                        child: Row(
                          children: [
                            SizedBox(
                              width: (MediaQuery.sizeOf(context).width * 0.34)
                                  .clamp(350.0, 460.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: theme.borderColor.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                child: _buildListaConversas(theme),
                              ),
                            ),
                            Expanded(
                              child: _buildPainelConversa(theme, desktop: true),
                            ),
                          ],
                        ),
                      );
                    }

                    return Row(
                      children: [
                        barraVertical,
                        conteudoPrincipal,
                      ],
                    );
                  }

                  // MODO COMPACTO / MOBILE (CELULAR):
                  // Se houver conversa selecionada, o painel do chat ocupa a tela inteira (sem barra inferior)
                  if (_controller.conversaSelecionada != null) {
                    return _buildPainelConversa(theme, desktop: false);
                  }

                  // Enquanto vê a lista de chats ou outras abas no celular, exibe em tela cheia
                  if (_controller.abaAtiva == AbaNavegacaoMensageria.ligacoes) {
                    return PainelLigacoesWidget(
                      controller: _controller,
                      theme: theme,
                    );
                  }
                  if (_controller.abaAtiva ==
                      AbaNavegacaoMensageria.comunidades) {
                    return PainelComunidadesWidget(
                      controller: _controller,
                      theme: theme,
                      desktop: false,
                    );
                  }
                  if (_controller.abaAtiva ==
                      AbaNavegacaoMensageria.transmissao) {
                    return PainelListaTransmissaoWidget(
                      controller: _controller,
                      theme: theme,
                      desktop: false,
                    );
                  }

                  return _buildListaConversas(theme);
                },
              ),
            ),
            bottomNavigationBar: (!desktop &&
                    _controller.conversaSelecionada == null)
                ? BarraNavegacaoInferiorMensageriaWidget(
                    theme: theme,
                    abaAtiva: _controller.abaAtiva,
                    totalNaoLidas: _controller.totalConversasNaoLidas,
                    onSelecionarAba: _controller.selecionarAba,
                  )
                : null,
          ),
        );
      },
    );
  }
}
