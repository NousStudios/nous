import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/controllers/mensageria_controller.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/views/widgets/balao_mensagem_widget.dart';
import 'package:nous/src/features/chat/views/widgets/painel_conversa/banner_titulo_conversa_widget.dart';

/// Área rolável de mensagens da conversa ativa, com separadores de dia e botão de descer.
class ListaMensagensConversaWidget extends StatelessWidget {
  final ConversaChat conversa;
  final MensageriaController controller;
  final AppTheme theme;
  final String termoBusca;
  final ScrollController scrollController;
  final bool mostrarBotaoDescer;
  final Set<String> mensagensSelecionadasIds;
  final String? mensagemDestacadaId;
  final List<MensagemChat> selecionadas;
  final void Function(ConversaChat) onRenomearConversa;
  final void Function(MensagemChat) onMostrarMenuMensagem;
  final void Function(MensagemChat) onVerHistoricoEdicoes;
  final void Function(String) onAbrirArquivo;
  final void Function(String) onVisualizarFotoAmpliada;
  final void Function(MensagemChat) onVerComanda;
  final void Function(MensagemChat) onAlternarSelecao;
  final void Function(MensagemChat, String) onReagir;
  final void Function(String mensagemId, List<MensagemChat> mensagensValidas)
      onTocarCitacao;
  final VoidCallback onRolarParaUltimaMensagem;

  const ListaMensagensConversaWidget({
    super.key,
    required this.conversa,
    required this.controller,
    required this.theme,
    required this.termoBusca,
    required this.scrollController,
    required this.mostrarBotaoDescer,
    required this.mensagensSelecionadasIds,
    required this.mensagemDestacadaId,
    required this.selecionadas,
    required this.onRenomearConversa,
    required this.onMostrarMenuMensagem,
    required this.onVerHistoricoEdicoes,
    required this.onAbrirArquivo,
    required this.onVisualizarFotoAmpliada,
    required this.onVerComanda,
    required this.onAlternarSelecao,
    required this.onReagir,
    required this.onTocarCitacao,
    required this.onRolarParaUltimaMensagem,
  });

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
    if (diffDias > 1 && diffDias <= 7) {
      switch (local.weekday) {
        case DateTime.monday:
          return 'Segunda-feira';
        case DateTime.tuesday:
          return 'Terça-feira';
        case DateTime.wednesday:
          return 'Quarta-feira';
        case DateTime.thursday:
          return 'Quinta-feira';
        case DateTime.friday:
          return 'Sexta-feira';
        case DateTime.saturday:
          return 'Sábado';
        case DateTime.sunday:
          return 'Domingo';
      }
    }
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d/$m/${local.year}';
  }

  Widget _buildSeparadorDia(DateTime dataHora) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: theme.cardBackgroundColor.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.borderColor.withValues(alpha: 0.65),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.textColor.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          _formatarRotuloDia(dataHora),
          style: theme.getTextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.secondaryTextColor,
          ),
        ),
      ),
    );
  }

  bool _ehEnviadaPorMim(MensagemChat msg) {
    if (controller.modoLoja) {
      final lojaIdAtiva = controller.lojaId ?? '';
      final lojaIdLimpo =
          lojaIdAtiva.startsWith('loja_') ? lojaIdAtiva.substring(5) : lojaIdAtiva;
      final remLimpo = msg.remetenteId.startsWith('loja_')
          ? msg.remetenteId.substring(5)
          : msg.remetenteId;
      return msg.remetenteId.startsWith('loja_') ||
          (lojaIdLimpo.isNotEmpty && remLimpo == lojaIdLimpo);
    }

    final meuCpfNorm = ChatService.normalizarCpf(controller.usuarioCpf ?? '');
    final remNorm = ChatService.normalizarCpf(msg.remetenteId);
    final remLimpo = msg.remetenteId.startsWith('loja_')
        ? msg.remetenteId.substring(5)
        : msg.remetenteId;
    final lojaIdConvLimpo = (conversa.lojaId ?? '').replaceFirst('loja_', '');
    final ehMensagemDeLoja = msg.remetenteId.startsWith('loja_') ||
        (conversa.ehLoja &&
            lojaIdConvLimpo.isNotEmpty &&
            remLimpo == lojaIdConvLimpo);
    return !ehMensagemDeLoja && meuCpfNorm.isNotEmpty && remNorm == meuCpfNorm;
  }

  @override
  Widget build(BuildContext context) {
    final mensagensValidas = conversa.mensagens.where((m) {
      if (m.tipo == 'texto' &&
          m.texto.trim().isEmpty &&
          m.caminhoAnexo.trim().isEmpty) {
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
                        onRenomearConversa: onRenomearConversa,
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
                    key: ValueKey('msgs_${conversa.id}'),
                    controller: scrollController,
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
                          onRenomearConversa: onRenomearConversa,
                        );
                      }
                      final msgIndex = mensagensValidas.length - 1 - index;
                      final msg = mensagensValidas[msgIndex];
                      final ehPrimeiraDoDia = msgIndex == 0 ||
                          !_mesmoDia(
                            mensagensValidas[msgIndex - 1].dataHora,
                            msg.dataHora,
                          );

                      final balao = BalaoMensagemWidget(
                        key: ValueKey(msg.id),
                        msg: msg,
                        conversa: conversa,
                        enviadaPorMim: _ehEnviadaPorMim(msg),
                        modoLoja: controller.modoLoja,
                        theme: theme,
                        selecionada: mensagensSelecionadasIds.contains(msg.id),
                        modoSelecaoAtivo: mensagensSelecionadasIds.isNotEmpty,
                        destacada: mensagemDestacadaId == msg.id,
                        mostrarBarraReacoes: selecionadas.length == 1 &&
                            selecionadas.first.id == msg.id,
                        onMostrarMenu: onMostrarMenuMensagem,
                        onVerHistoricoEdicoes: onVerHistoricoEdicoes,
                        onAbrirArquivo: onAbrirArquivo,
                        onVisualizarFotoAmpliada: onVisualizarFotoAmpliada,
                        onVerComanda: onVerComanda,
                        onResponder: (m) =>
                            controller.definirMensagemRespondendo(m),
                        onAlternarSelecao: onAlternarSelecao,
                        onReagir: onReagir,
                        onTocarCitacao: (id) =>
                            onTocarCitacao(id, mensagensValidas),
                      );

                      if (ehPrimeiraDoDia) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSeparadorDia(msg.dataHora),
                            balao,
                          ],
                        );
                      }
                      return balao;
                    },
                  ),
          ),
          if (mostrarBotaoDescer)
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
                  onTap: onRolarParaUltimaMensagem,
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
  }
}
