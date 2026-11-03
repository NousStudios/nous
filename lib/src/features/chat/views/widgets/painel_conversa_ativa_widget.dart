import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/controllers/mensageria_controller.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
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
  final VoidCallback onCompartilharComanda;

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
    required this.onCompartilharComanda,
  });

  @override
  State<PainelConversaAtivaWidget> createState() =>
      _PainelConversaAtivaWidgetState();
}

class _PainelConversaAtivaWidgetState extends State<PainelConversaAtivaWidget> {
  final TextEditingController _mensagemController = TextEditingController();
  final ScrollController _mensagensScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _mensagemController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _mensagemController.dispose();
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
    DialogMenuAnexosChat.mostrar(
      context: context,
      theme: widget.theme,
      onCapturarFotoCamera: widget.onCapturarFotoCamera,
      onAnexarFoto: widget.onAnexarFoto,
      onAnexarArquivo: widget.onAnexarArquivo,
      onCompartilharComanda: widget.onCompartilharComanda,
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

    return Column(
      children: [
        // Cabeçalho da Conversa
        CabecalhoConversaAtivaWidget(
          conversa: conversa,
          theme: theme,
          desktop: widget.desktop,
          onVoltarMobile: widget.onVoltarMobile,
          onAbrirDetalhes: widget.onAbrirDetalhes,
          onRenomearConversa: widget.onRenomearConversa,
        ),

        // Área das Mensagens
        Builder(
          builder: (context) {
            final mensagensValidas = conversa.mensagens.where((m) {
              if (m.tipo == 'texto' && m.texto.trim().isEmpty && m.caminhoAnexo.trim().isEmpty) {
                return false;
              }
              return true;
            }).toList();

            return Expanded(
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
                              'Nenhuma mensagem ainda.\nEnvie uma mensagem abaixo para iniciar.',
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
                        final msg =
                            mensagensValidas[mensagensValidas.length - 1 - index];
                        final enviadaPorMim =
                            msg.enviadaPorMim ||
                            (widget.controller.usuarioCpf != null &&
                                (msg.remetenteId == widget.controller.usuarioCpf ||
                                    msg.cpfAtendente ==
                                        widget.controller.usuarioCpf)) ||
                            (widget.controller.modoLoja &&
                                msg.remetenteId == widget.controller.lojaId);

                        return BalaoMensagemWidget(
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
                      },
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
