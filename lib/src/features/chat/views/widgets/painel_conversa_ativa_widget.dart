import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/chat/controllers/mensageria_controller.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/views/dialogs/dialog_editar_mensagem.dart';
import 'package:nous/src/features/chat/views/dialogs/dialog_encaminhar_mensagem.dart';
import 'package:nous/src/features/chat/views/widgets/painel_conversa/banner_mensagem_fixada_widget.dart';
import 'package:nous/src/features/chat/views/widgets/painel_conversa/banner_solicitacao_conversa_widget.dart';
import 'package:nous/src/features/chat/views/widgets/painel_conversa/barra_envio_mensagem_widget.dart';
import 'package:nous/src/features/chat/views/widgets/painel_conversa/barra_pesquisa_conversa_widget.dart';
import 'package:nous/src/features/chat/views/widgets/painel_conversa/cabecalho_conversa_ativa_widget.dart';
import 'package:nous/src/features/chat/views/widgets/painel_conversa/dialog_menu_anexos_chat.dart';
import 'package:nous/src/features/chat/views/widgets/painel_conversa/lista_mensagens_conversa_widget.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';

/// Painel central da conversa selecionada na Mensageria Nous.
class PainelConversaAtivaWidget extends StatefulWidget {
  final MensageriaController controller;
  final AppTheme theme;
  final bool desktop;
  final VoidCallback onVoltarMobile;
  final void Function(ConversaChat) onAbrirDetalhes;
  final void Function(ConversaChat) onRenomearConversa;
  final void Function(MensagemChat) onMostrarMenuMensagem;
  final void Function(MensagemChat) onVerHistoricoEdicoes;
  final void Function(String) onAbrirArquivo;
  final void Function(String) onVisualizarFotoAmpliada;
  final void Function(MensagemChat) onVerComanda;
  final void Function(String texto) onEnviarTexto;
  final void Function(String caminho, String duracao, int tamanho) onEnviarAudio;
  final VoidCallback onCapturarFotoCamera;
  final VoidCallback onAnexarFoto;
  final VoidCallback onAnexarArquivo;
  final VoidCallback onCompartilharContato;
  final VoidCallback onCompartilharComanda;
  final void Function(ConversaChat)? onFazerPedido;

  const PainelConversaAtivaWidget({
    super.key,
    required this.controller,
    required this.theme,
    required this.desktop,
    required this.onVoltarMobile,
    required this.onAbrirDetalhes,
    required this.onRenomearConversa,
    required this.onMostrarMenuMensagem,
    required this.onVerHistoricoEdicoes,
    required this.onAbrirArquivo,
    required this.onVisualizarFotoAmpliada,
    required this.onVerComanda,
    required this.onEnviarTexto,
    required this.onEnviarAudio,
    required this.onCapturarFotoCamera,
    required this.onAnexarFoto,
    required this.onAnexarArquivo,
    required this.onCompartilharContato,
    required this.onCompartilharComanda,
    this.onFazerPedido,
  });

  @override
  State<PainelConversaAtivaWidget> createState() =>
      _PainelConversaAtivaWidgetState();
}

class _PainelConversaAtivaWidgetState extends State<PainelConversaAtivaWidget> {
  final TextEditingController _mensagemController = TextEditingController();
  final TextEditingController _buscaConversaController = TextEditingController();
  final ScrollController _mensagensScrollController = ScrollController();
  bool _pesquisaAtiva = false;
  bool _mostrarBotaoDescer = false;
  String? _ultimoIdConversa;

  final Set<String> _mensagensSelecionadasIds = {};
  String? _mensagemDestacadaId;
  Timer? _timerDestaque;

  @override
  void initState() {
    super.initState();
    _buscaConversaController.addListener(() {
      if (mounted) setState(() {});
    });
    _mensagensScrollController.addListener(_verificarPosicaoScroll);
  }

  List<MensagemChat> _obterMensagensSelecionadas(ConversaChat conversa) {
    if (_mensagensSelecionadasIds.isEmpty) return const [];
    return conversa.mensagens
        .where((m) => _mensagensSelecionadasIds.contains(m.id))
        .toList();
  }

  bool _podeEditarMensagem(MensagemChat msg) {
    final cpfLogado =
        context.read<AuthProvider>().cpf.replaceAll(RegExp(r'\D'), '');
    final remNorm = msg.remetenteId.replaceAll(RegExp(r'\D'), '');
    final ehMinha = msg.enviadaPorMim ||
        (cpfLogado.isNotEmpty && remNorm == cpfLogado);
    return ehMinha && msg.tipo == 'texto';
  }

  void _copiarMensagens(List<MensagemChat> msgs, AppTheme theme) {
    final textos = msgs
        .map((msg) => msg.texto.trim().isNotEmpty
            ? msg.texto.trim()
            : (msg.nomeAnexo.trim().isNotEmpty ? msg.nomeAnexo.trim() : ''))
        .where((t) => t.isNotEmpty)
        .toList();
    if (textos.isEmpty) return;
    Clipboard.setData(ClipboardData(text: textos.join('\n')));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: theme.cardBackgroundColor,
          duration: const Duration(milliseconds: 1200),
          content: Text(
            msgs.length > 1
                ? '${msgs.length} mensagens copiadas!'
                : 'Mensagem copiada!',
            style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
          ),
        ),
      );
  }

  void _encaminharMensagensSelecionadas(
    List<MensagemChat> msgs,
    AppTheme theme,
  ) {
    if (msgs.isEmpty) return;
    final mapaDestinos = <String, ConversaChat>{
      for (final c in widget.controller.conversas) c.id: c,
    };
    for (final c in widget.controller.todosContatosDisponiveis) {
      mapaDestinos.putIfAbsent(c.id, () => c);
    }
    final destinos = mapaDestinos.values.toList()
      ..sort(
        (a, b) => b.dataHoraUltimaMensagem.compareTo(a.dataHoraUltimaMensagem),
      );
    DialogEncaminharMensagem.mostrar(
      context,
      theme: theme,
      msg: msgs.first,
      conversasDisponiveis: destinos,
      onEncaminhar: (destino) async {
        final auth = context.read<AuthProvider>();
        for (final msg in msgs) {
          await widget.controller.encaminharMensagem(
            msgOriginal: msg,
            destino: destino,
            auth: auth,
          );
        }
      },
    );
  }

  void _rolarParaMensagem(String mensagemId, List<MensagemChat> mensagens) {
    final msgIndex = mensagens.indexWhere((m) => m.id == mensagemId);
    if (msgIndex == -1) return;
    if (_mensagensScrollController.hasClients) {
      final maxScroll = _mensagensScrollController.position.maxScrollExtent;
      final alvo = mensagens.length <= 1
          ? 0.0
          : ((mensagens.length - 1 - msgIndex) / (mensagens.length - 1)) *
              maxScroll;
      _mensagensScrollController.animateTo(
        alvo.clamp(0.0, maxScroll),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
    _timerDestaque?.cancel();
    setState(() => _mensagemDestacadaId = mensagemId);
    _timerDestaque = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => _mensagemDestacadaId = null);
      }
    });
  }

  void _verificarPosicaoScroll() {
    if (!_mensagensScrollController.hasClients) return;
    final deveMostrar = _mensagensScrollController.offset > 180;
    if (deveMostrar != _mostrarBotaoDescer && mounted) {
      setState(() {
        _mostrarBotaoDescer = deveMostrar;
      });
    }
  }

  void _rolarParaUltimaMensagem() {
    if (!_mensagensScrollController.hasClients) return;
    _mensagensScrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  void _alternarPesquisa() {
    setState(() {
      _pesquisaAtiva = !_pesquisaAtiva;
      if (!_pesquisaAtiva) {
        _buscaConversaController.clear();
      }
    });
  }

  @override
  void dispose() {
    _timerDestaque?.cancel();
    _mensagensScrollController.removeListener(_verificarPosicaoScroll);
    _mensagemController.dispose();
    _buscaConversaController.dispose();
    _mensagensScrollController.dispose();
    super.dispose();
  }

  void _enviarTexto() {
    final texto = _mensagemController.text.trim();
    if (texto.isEmpty) return;
    final conv = widget.controller.conversaSelecionada;
    final contaLogada = context.read<AuthProvider>().contaAtual;
    if (conv != null &&
        widget.controller.ehSolicitacao(conv, contaLogada: contaLogada)) {
      widget.controller.aceitarSolicitacao(conv);
    }
    _mensagemController.clear();
    widget.onEnviarTexto(texto);
  }

  Future<void> _aceitarSolicitacao(ConversaChat conversa) async {
    await widget.controller.aceitarSolicitacao(conversa);
    if (mounted) setState(() {});
  }

  Future<void> _recusarSolicitacao(ConversaChat conversa) async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final pdv = context.read<PdvProvider>();
    await widget.controller.recusarSolicitacao(conversa, auth: auth, pdv: pdv);
  }

  bool _ehMembroOuDonoDaLoja(Loja loja, String cpfBruto) {
    final cpf = ChatService.normalizarCpf(cpfBruto);
    if (cpf.length != 11) return false;
    if (ChatService.normalizarCpf(loja.cpfDonoOriginal) == cpf) return true;
    return loja.membros.any((m) => ChatService.normalizarCpf(m.cpf) == cpf);
  }

  bool _podeExibirComandaNoClipe(ConversaChat? conversa) {
    if (conversa == null) return false;
    final pdv = context.read<PdvProvider?>();
    if (pdv == null) return false;
    final auth = context.read<AuthProvider?>();
    final meuCpf = ChatService.normalizarCpf(
      widget.controller.operadorCpf ?? auth?.cpf ?? pdv.cpfAtual ?? '',
    );

    // Caso 1: Conversa da loja para um funcionário dela (ou do funcionário para a loja)
    final idLojaConv = conversa.lojaId != null && conversa.lojaId!.isNotEmpty
        ? PdvProvider.normalizarIdLoja(conversa.lojaId!)
        : (conversa.ehLoja
            ? PdvProvider.normalizarIdLoja(conversa.identificador)
            : '');

    if (idLojaConv.isNotEmpty && idLojaConv != PdvProvider.idLojaColetivaNous) {
      final loja = pdv.buscarPorId(idLojaConv);
      if (loja != null) {
        if (widget.controller.modoLoja) {
          final cpfAlvo = ChatService.normalizarCpf(conversa.identificador);
          return _ehMembroOuDonoDaLoja(loja, cpfAlvo) ||
              conversa.subtitulo.toLowerCase().contains('membro da equipe');
        } else {
          return _ehMembroOuDonoDaLoja(loja, meuCpf);
        }
      }
      if (widget.controller.modoLoja &&
          conversa.subtitulo.toLowerCase().contains('membro da equipe')) {
        return true;
      }
    }

    // Caso 2: Conversa direta entre dois funcionários/membros da mesma loja
    if (!conversa.ehGrupo && !conversa.ehLoja && !widget.controller.modoLoja) {
      final outroCpf = ChatService.normalizarCpf(conversa.identificador);
      if (meuCpf.length == 11 && outroCpf.length == 11) {
        for (final loja in pdv.lojas) {
          if (loja.id == PdvProvider.idLojaColetivaNous) continue;
          if (_ehMembroOuDonoDaLoja(loja, meuCpf) &&
              _ehMembroOuDonoDaLoja(loja, outroCpf)) {
            return true;
          }
        }
      }
    }

    return false;
  }

  void _abrirMenuAnexo() {
    final conversa = widget.controller.conversaSelecionada;
    final ehLoja = conversa != null &&
        (conversa.ehLoja ||
            (conversa.lojaId != null && conversa.lojaId!.isNotEmpty));
    final mostrarComanda = _podeExibirComandaNoClipe(conversa);

    DialogMenuAnexosChat.mostrar(
      context: context,
      theme: widget.theme,
      onAnexarFoto: widget.onAnexarFoto,
      onAnexarArquivo: widget.onAnexarArquivo,
      onCompartilharContato: widget.onCompartilharContato,
      onCompartilharComanda:
          mostrarComanda ? widget.onCompartilharComanda : null,
      onFazerPedido: ehLoja && widget.onFazerPedido != null
          ? () => widget.onFazerPedido!(conversa)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final conversa = widget.controller.conversaSelecionada;

    if (conversa == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_outlined,
              size: 56,
              color: theme.secondaryTextColor.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Selecione uma conversa para começar',
              style: theme.getTextStyle(
                fontSize: 14,
                color: theme.secondaryTextColor,
              ),
            ),
          ],
        ),
      );
    }

    if (_ultimoIdConversa != conversa.id) {
      _ultimoIdConversa = conversa.id;
      _pesquisaAtiva = false;
      _mostrarBotaoDescer = false;
      _mensagensSelecionadasIds.clear();
      _mensagemDestacadaId = null;
      _timerDestaque?.cancel();
      if (_buscaConversaController.text.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _buscaConversaController.clear();
        });
      }
    }

    final termoBusca = _buscaConversaController.text.trim().toLowerCase();
    final selecionadas = _obterMensagensSelecionadas(conversa);
    final fixadas = conversa.mensagens.where((m) => m.fixada).toList();

    return Column(
      children: [
        CabecalhoConversaAtivaWidget(
          conversa: conversa,
          theme: theme,
          desktop: widget.desktop,
          onVoltarMobile: widget.onVoltarMobile,
          onAbrirDetalhes: widget.onAbrirDetalhes,
          onAlternarPesquisa: _alternarPesquisa,
          pesquisaAtiva: _pesquisaAtiva,
          quantidadeSelecionadas: selecionadas.length,
          podeEditarSelecionada: selecionadas.length == 1 &&
              _podeEditarMensagem(selecionadas.first),
          onLimparSelecao: () =>
              setState(() => _mensagensSelecionadasIds.clear()),
          onResponderSelecionada: selecionadas.length != 1
              ? null
              : () {
                  final sel = selecionadas.first;
                  setState(() => _mensagensSelecionadasIds.clear());
                  widget.controller.definirMensagemRespondendo(sel);
                },
          onEditarSelecionada: selecionadas.length != 1
              ? null
              : () {
                  final sel = selecionadas.first;
                  setState(() => _mensagensSelecionadasIds.clear());
                  DialogEditarMensagem.mostrar(
                    context,
                    theme: theme,
                    msg: sel,
                    onSalvar: (novo) =>
                        widget.controller.editarMensagem(sel, novo),
                  );
                },
          onCopiarSelecionada: selecionadas.isEmpty
              ? null
              : () {
                  final lista = List<MensagemChat>.from(selecionadas);
                  setState(() => _mensagensSelecionadasIds.clear());
                  _copiarMensagens(lista, theme);
                },
          onEncaminharSelecionada: selecionadas.isEmpty
              ? null
              : () {
                  final lista = List<MensagemChat>.from(selecionadas);
                  setState(() => _mensagensSelecionadasIds.clear());
                  _encaminharMensagensSelecionadas(lista, theme);
                },
          onExcluirSelecionada: selecionadas.isEmpty
              ? null
              : () {
                  final lista = List<MensagemChat>.from(selecionadas);
                  setState(() => _mensagensSelecionadasIds.clear());
                  for (final m in lista) {
                    widget.controller.excluirMensagemLocal(m);
                  }
                },
        ),
        if (_pesquisaAtiva)
          BarraPesquisaConversaWidget(
            controller: _buscaConversaController,
            theme: theme,
            termoBusca: termoBusca,
          ),
        if (fixadas.isNotEmpty)
          BannerMensagemFixadaWidget(
            fixadas: fixadas,
            theme: theme,
            onDesafixar: widget.controller.alternarFixarMensagem,
          ),
        ListaMensagensConversaWidget(
          conversa: conversa,
          controller: widget.controller,
          theme: theme,
          termoBusca: termoBusca,
          scrollController: _mensagensScrollController,
          mostrarBotaoDescer: _mostrarBotaoDescer,
          mensagensSelecionadasIds: _mensagensSelecionadasIds,
          mensagemDestacadaId: _mensagemDestacadaId,
          selecionadas: selecionadas,
          onRenomearConversa: widget.onRenomearConversa,
          onMostrarMenuMensagem: widget.onMostrarMenuMensagem,
          onVerHistoricoEdicoes: widget.onVerHistoricoEdicoes,
          onAbrirArquivo: widget.onAbrirArquivo,
          onVisualizarFotoAmpliada: widget.onVisualizarFotoAmpliada,
          onVerComanda: widget.onVerComanda,
          onAlternarSelecao: (m) {
            setState(() {
              if (!_mensagensSelecionadasIds.add(m.id)) {
                _mensagensSelecionadasIds.remove(m.id);
              }
            });
          },
          onReagir: (m, emoji) {
            setState(() => _mensagensSelecionadasIds.clear());
            widget.controller.reagirMensagem(m, emoji);
          },
          onTocarCitacao: _rolarParaMensagem,
          onRolarParaUltimaMensagem: _rolarParaUltimaMensagem,
        ),
        Builder(
          builder: (context) {
            final auth = context.watch<AuthProvider>();
            final ehSolicitacao = widget.controller.ehSolicitacao(
              conversa,
              contaLogada: auth.contaAtual,
            );

            if (ehSolicitacao) {
              return BannerSolicitacaoConversaWidget(
                conversa: conversa,
                theme: theme,
                onAceitar: _aceitarSolicitacao,
                onConfirmarRecusa: _recusarSolicitacao,
              );
            }

            return ValueListenableBuilder<TextEditingValue>(
              valueListenable: _mensagemController,
              builder: (context, _, _) {
                return BarraEnvioMensagemWidget(
                  controller: widget.controller,
                  theme: theme,
                  mensagemController: _mensagemController,
                  onEnviarTexto: _enviarTexto,
                  onEnviarAudio: widget.onEnviarAudio,
                  onCapturarFotoCamera: widget.onCapturarFotoCamera,
                  onAbrirMenuAnexo: _abrirMenuAnexo,
                  mensagemRespondendo: widget.controller.mensagemRespondendo,
                  onCancelarResposta: () =>
                      widget.controller.definirMensagemRespondendo(null),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
