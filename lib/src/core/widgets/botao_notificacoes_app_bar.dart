import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/services/guarda_acao_ui.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/notificacoes/views/widgets/notificacoes_dialog.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/timeline/models/notificacao_social.dart';
import 'package:nous/src/features/timeline/services/timeline_repositorio_sqlite.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';

/// Botão de notificações da AppBar com recarga reativa e debounce de alterações no chat.
class BotaoNotificacoesAppBar extends StatefulWidget {
  final String? lojaId;
  final String cpfUsuario;
  final AppTheme theme;

  const BotaoNotificacoesAppBar({
    super.key,
    required this.lojaId,
    required this.cpfUsuario,
    required this.theme,
  });

  @override
  State<BotaoNotificacoesAppBar> createState() =>
      _BotaoNotificacoesAppBarState();
}

class _BotaoNotificacoesAppBarState extends State<BotaoNotificacoesAppBar> {
  List<MensagemChat> _msgsNaoLidas = const [];
  List<NotificacaoSocial> _sociaisNaoLidas = const [];
  Timer? _debounce;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    ChatService.alteracoesChatNotifier.addListener(_agendarRecarga);
    TimelineService.alteracoesTimelineNotifier.addListener(_agendarRecarga);
    _recarregar();
  }

  @override
  void didUpdateWidget(covariant BotaoNotificacoesAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lojaId != widget.lojaId ||
        oldWidget.cpfUsuario != widget.cpfUsuario) {
      _recarregar();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    ChatService.alteracoesChatNotifier.removeListener(_agendarRecarga);
    TimelineService.alteracoesTimelineNotifier.removeListener(_agendarRecarga);
    super.dispose();
  }

  void _agendarRecarga() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), () {
      if (mounted) _recarregar();
    });
  }

  Future<void> _recarregar() async {
    if (_carregando) return;
    _carregando = true;
    try {
      final List<MensagemChat> resultado;
      if (widget.lojaId != null) {
        resultado =
            await ChatService.obterMensagensNaoLidasDaLoja(widget.lojaId!);
      } else if (widget.cpfUsuario.isNotEmpty) {
        resultado = await ChatService.obterMensagensNaoLidasDoUsuario(
            widget.cpfUsuario);
      } else {
        resultado = const <MensagemChat>[];
      }
      final List<NotificacaoSocial> sociais =
          (widget.lojaId == null && widget.cpfUsuario.isNotEmpty)
              ? (await TimelineRepositorioSqlite
                      .listarNotificacoesSociaisDoUsuario(
                  widget.cpfUsuario,
                ))
                  .where((s) => !s.lida)
                  .toList()
              : const <NotificacaoSocial>[];
      if (!mounted) return;
      final mudouMsgs = resultado.length != _msgsNaoLidas.length ||
          (resultado.isNotEmpty &&
              _msgsNaoLidas.isNotEmpty &&
              resultado.first.id != _msgsNaoLidas.first.id);
      final mudouSociais = sociais.length != _sociaisNaoLidas.length ||
          (sociais.isNotEmpty &&
              _sociaisNaoLidas.isNotEmpty &&
              sociais.first.id != _sociaisNaoLidas.first.id);
      if (mudouMsgs || mudouSociais) {
        setState(() {
          _msgsNaoLidas = resultado;
          _sociaisNaoLidas = sociais;
        });
      }
    } catch (_) {
    } finally {
      _carregando = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificacoes = context.watch<NotificacoesProvider>();
    final pdv = context.watch<PdvProvider>();
    final theme = widget.theme;
    final lojaId = widget.lojaId;

    final msgsFiltradas = _msgsNaoLidas
        .where((m) => lojaId != null
            ? !notificacoes.estaDispensadaNaLoja(lojaId, 'msg_${m.id}')
            : !notificacoes.estaDispensadaNaSessao('msg_${m.id}'))
        .toList();
    final temMensagens = msgsFiltradas.isNotEmpty;
    final quantidadeConvites = (lojaId == null)
        ? notificacoes.convites
            .where((c) => !notificacoes.estaDispensadaNaSessao('convite_${c.id}'))
            .length
        : 0;
    final quantidadeSociais = (lojaId == null)
        ? _sociaisNaoLidas
            .where((s) => !notificacoes.estaDispensadaNaSessao('nsoc_${s.id}'))
            .length
        : 0;
    final ehLojaColetiva = lojaId == PdvProvider.idLojaColetivaNous;
    final totalEstoqueBaixo = (lojaId == null || ehLojaColetiva)
        ? 0
        : pdv
            .itensEstoqueBaixoPorLoja(lojaId)
            .where((a) => !notificacoes.estaDispensadaNaLoja(
                lojaId, 'alerta_estoque_${a.lojaId}_${a.item.id}'))
            .length;
    final temNotificacaoAtiva = quantidadeConvites > 0 ||
        quantidadeSociais > 0 ||
        totalEstoqueBaixo > 0 ||
        temMensagens;
    final quantidadeBadge =
        quantidadeConvites + quantidadeSociais + totalEstoqueBaixo;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        IconButton(
          tooltip: totalEstoqueBaixo > 0
              ? 'Notificações ($totalEstoqueBaixo item(ns) com estoque baixo/esgotado)'
              : 'Notificações',
          icon: Icon(
            temNotificacaoAtiva
                ? Icons.notifications_active_outlined
                : Icons.notifications_none,
            color: temNotificacaoAtiva
                ? theme.dangerColor
                : theme.secondaryTextColor,
          ),
          onPressed: () => GuardaAcaoUi.executarUnico<void>(
            'dialog_notificacoes',
            () => NotificacoesDialog.mostrar(context, lojaId: lojaId),
          ),
        ),
        if (quantidadeBadge > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: BoxDecoration(
                color: theme.dangerColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                quantidadeBadge > 9 ? '9+' : '$quantidadeBadge',
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          )
        else if (temMensagens)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.dangerColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
