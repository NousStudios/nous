import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/controllers/mensageria_controller.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/views/widgets/balao_mensagem_widget.dart';
import 'package:nous/src/features/chat/views/widgets/painel_conversa/banner_titulo_conversa_widget.dart';
import 'package:nous/src/features/chat/views/widgets/painel_conversa/barra_envio_mensagem_widget.dart';
import 'package:nous/src/features/chat/views/widgets/painel_conversa/cabecalho_conversa_ativa_widget.dart';
import 'package:nous/src/features/chat/views/widgets/painel_conversa/dialog_menu_anexos_chat.dart';

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

  @override
  void initState() {
    super.initState();
    _mensagemController.addListener(() {
      if (mounted) setState(() {});
    });
    _buscaConversaController.addListener(() {
      if (mounted) setState(() {});
    });
    _mensagensScrollController.addListener(_verificarPosicaoScroll);
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

  bool _mesmoDia(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  String _formatarRotuloDia(DateTime dataHora) {
    final local = dataHora.toLocal();
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final dataMsg = DateTime(local.year, local.month, local.day);
    final diffDias = hoje.difference(dataMsg).inDays;

    if (diffDias == 0) return 'Hoje';
    if (diffDias == 1) return 'Ontem';
    if (diffDias == 2) return 'Anteontem';
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d/$m/${local.year}';
  }

  Widget _buildSeparadorDia(AppTheme theme, DateTime dataHora) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: theme.cardBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.borderColor.withValues(alpha: 0.6),
          ),
        ),
        child: Text(
          _formatarRotuloDia(dataHora),
          style: theme.getTextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: theme.secondaryTextColor,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mensagensScrollController.removeListener(_verificarPosicaoScroll);
    _mensagemController.dispose();
    _buscaConversaController.dispose();
    _mensagensScrollController.dispose();
    super.dispose();
  }

  void _enviarTexto() {
    final texto = _mensagemController.text.trim();
    if (texto.isEmpty) return;
    _mensagemController.clear();
    widget.onEnviarTexto(texto);
  }

  void _abrirMenuAnexo() {
    final conversa = widget.controller.conversaSelecionada;
    final ehLoja = conversa != null &&
        (conversa.ehLoja ||
            (conversa.lojaId != null && conversa.lojaId!.isNotEmpty));

    DialogMenuAnexosChat.mostrar(
      context: context,
      theme: widget.theme,
      onAnexarFoto: widget.onAnexarFoto,
      onAnexarArquivo: widget.onAnexarArquivo,
      onCompartilharContato: widget.onCompartilharContato,
      onCompartilharComanda: widget.onCompartilharComanda,
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
      _buscaConversaController.clear();
      _mostrarBotaoDescer = false;
    }

    final termoBusca = _buscaConversaController.text.trim().toLowerCase();

    return Column(
      children: [
        // Cabeçalho da Conversa
        CabecalhoConversaAtivaWidget(
          conversa: conversa,
          theme: theme,
          desktop: widget.desktop,
          onVoltarMobile: widget.onVoltarMobile,
          onAbrirDetalhes: widget.onAbrirDetalhes,
          onAlternarPesquisa: _alternarPesquisa,
          pesquisaAtiva: _pesquisaAtiva,
        ),

        // Barra de pesquisa de palavras-chave na conversa
        if (_pesquisaAtiva)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.cardBackgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: theme.borderColor.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: TextField(
              controller: _buscaConversaController,
              autofocus: true,
              style: theme.getTextStyle(fontSize: 13, color: theme.textColor),
              decoration: InputDecoration(
                hintText: 'Pesquisar palavras-chave no histórico...',
                hintStyle: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: theme.secondaryTextColor,
                ),
                suffixIcon: termoBusca.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          size: 16,
                          color: theme.secondaryTextColor,
                        ),
                        onPressed: () => _buscaConversaController.clear(),
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: theme.backgroundColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: theme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: theme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: theme.buttonColor),
                ),
              ),
            ),
          ),

        // Área das Mensagens
        Builder(
          builder: (context) {
            final mensagensValidas = conversa.mensagens.where((m) {
              if (m.tipo == 'texto' && m.texto.trim().isEmpty && m.caminhoAnexo.trim().isEmpty) {
                return false;
              }
              if (termoBusca.isNotEmpty) {
                final bateTexto = m.texto.toLowerCase().contains(termoBusca);
                final bateAnexo = m.nomeAnexo.toLowerCase().contains(termoBusca);
                final bateComanda = m.dadosPedidoJson.toLowerCase().contains(termoBusca);
                return bateTexto || bateAnexo || bateComanda;
              }
              return true;
            }).toList();

            return Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: mensagensValidas.isEmpty
                        ? Column(
                            children: [
                              BannerTituloConversaWidget(
                                conversa: conversa,
                                theme: theme,
                                onRenomearConversa: widget.onRenomearConversa,
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    termoBusca.isNotEmpty
                                        ? 'Nenhuma mensagem encontrada para "$termoBusca".'
                                        : 'Nenhuma mensagem ainda.\nEnvie uma mensagem abaixo para iniciar.',
                                    textAlign: TextAlign.center,
                                    style: theme.getTextStyle(
                                      fontSize: 12,
                                      color: theme.secondaryTextColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            controller: _mensagensScrollController,
                            reverse: true,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            itemCount: mensagensValidas.length + 1,
                            itemBuilder: (context, index) {
                              if (index == mensagensValidas.length) {
                                return BannerTituloConversaWidget(
                                  conversa: conversa,
                                  theme: theme,
                                  onRenomearConversa: widget.onRenomearConversa,
                                );
                              }
                              final msgIndex = mensagensValidas.length - 1 - index;
                              final msg = mensagensValidas[msgIndex];
                              final ehPrimeiraDoDia = msgIndex == 0 ||
                                  !_mesmoDia(
                                    mensagensValidas[msgIndex - 1].dataHora,
                                    msg.dataHora,
                                  );

                              final bool enviadaPorMim;
                              if (widget.controller.modoLoja) {
                                final lojaIdAtiva = widget.controller.lojaId ?? '';
                                final lojaIdLimpo = lojaIdAtiva.startsWith('loja_')
                                    ? lojaIdAtiva.substring(5)
                                    : lojaIdAtiva;
                                final remLimpo = msg.remetenteId.startsWith('loja_')
                                    ? msg.remetenteId.substring(5)
                                    : msg.remetenteId;
                                enviadaPorMim = lojaIdLimpo.isNotEmpty && remLimpo == lojaIdLimpo;
                              } else {
                                final meuCpfNorm = ChatService.normalizarCpf(
                                  widget.controller.usuarioCpf ?? '',
                                );
                                final remNorm = ChatService.normalizarCpf(msg.remetenteId);
                                final ehMensagemDeLoja = msg.remetenteId.startsWith('loja_') ||
                                    (conversa.ehLoja && msg.remetenteId == conversa.lojaId);
                                enviadaPorMim = !ehMensagemDeLoja &&
                                    meuCpfNorm.isNotEmpty &&
                                    remNorm == meuCpfNorm;
                              }

                              final balao = BalaoMensagemWidget(
                                msg: msg,
                                conversa: conversa,
                                enviadaPorMim: enviadaPorMim,
                                theme: theme,
                                onMostrarMenu: widget.onMostrarMenuMensagem,
                                onVerHistoricoEdicoes: widget.onVerHistoricoEdicoes,
                                onAbrirArquivo: widget.onAbrirArquivo,
                                onVisualizarFotoAmpliada: widget.onVisualizarFotoAmpliada,
                                onVerComanda: widget.onVerComanda,
                              );

                              if (ehPrimeiraDoDia) {
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildSeparadorDia(theme, msg.dataHora),
                                    balao,
                                  ],
                                );
                              }
                              return balao;
                            },
                          ),
                  ),
                  if (_mostrarBotaoDescer)
                    Positioned(
                      right: 16,
                      bottom: 14,
                      child: Material(
                        color: theme.cardBackgroundColor,
                        shape: CircleBorder(
                          side: BorderSide(color: theme.borderColor, width: 1.2),
                        ),
                        elevation: 4,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _rolarParaUltimaMensagem,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 24,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),

        // Barra de Envio
        BarraEnvioMensagemWidget(
          controller: widget.controller,
          theme: theme,
          mensagemController: _mensagemController,
          onEnviarTexto: _enviarTexto,
          onEnviarAudio: widget.onEnviarAudio,
          onCapturarFotoCamera: widget.onCapturarFotoCamera,
          onAbrirMenuAnexo: _abrirMenuAnexo,
        ),
      ],
    );
  }
}
