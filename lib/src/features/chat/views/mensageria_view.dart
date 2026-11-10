import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/core/widgets/floating_bottom_nav_bar.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
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
import 'package:nous/src/features/chat/views/widgets/lista_conversas_widget.dart';
import 'package:nous/src/features/chat/views/widgets/painel_conversa_ativa_widget.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';

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

class _MensageriaViewState extends State<MensageriaView> {
  final MensageriaController _controller = MensageriaController();
  bool _inicializado = false;
  Timer? _debounceAtualizarChat;

  @override
  void initState() {
    super.initState();
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
      _controller.inicializar(auth: auth, pdv: pdv);
      _inicializado = true;
    }
  }

  @override
  void dispose() {
    _debounceAtualizarChat?.cancel();
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
    // 2. Debounce na recarga da lista geral de contatos e lojas
    _debounceAtualizarChat?.cancel();
    _debounceAtualizarChat = Timer(const Duration(milliseconds: 300), () {
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
            DialogEncaminharMensagem.mostrar(
              context,
              theme: theme,
              msg: msg,
              conversasDisponiveis: _controller.conversas,
              onEncaminhar: (destino) {
                final auth = context.read<AuthProvider>();
                return _controller.encaminharMensagem(
                  msgOriginal: msg,
                  destino: destino,
                  auth: auth,
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
          canPop: _controller.conversaSelecionada == null,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (_controller.conversaSelecionada != null) {
              _controller.selecionarConversa(null);
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
                } else if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
            body: SafeArea(
              child: desktop
                  ? Row(
                      children: [
                        SizedBox(
                          width: 320,
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
                    )
                  : (_controller.conversaSelecionada != null
                      ? _buildPainelConversa(theme, desktop: false)
                      : _buildListaConversas(theme)),
            ),
            bottomNavigationBar:
                (!widget.modoLoja &&
                    !widget.mostrarBotaoVoltar &&
                    _controller.conversaSelecionada == null)
                ? const FloatingBottomNavBar(
                    maxWidth: 600,
                    slotSelecionado: 1,
                    subIndiceSelecionado: 1,
                  )
                : null,
          ),
        );
      },
    );
  }
}
