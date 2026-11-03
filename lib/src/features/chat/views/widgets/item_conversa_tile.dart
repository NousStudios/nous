import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';

class ItemConversaTile extends StatefulWidget {
  final ConversaChat conversa;
  final bool selecionada;
  final AppTheme theme;
  final Widget avatar;
  final String horaFormatada;
  final VoidCallback onTap;
  final VoidCallback? onAlternarFixar;
  final VoidCallback? onAlternarArquivar;

  const ItemConversaTile({
    super.key,
    required this.conversa,
    required this.selecionada,
    required this.theme,
    required this.avatar,
    required this.horaFormatada,
    required this.onTap,
    this.onAlternarFixar,
    this.onAlternarArquivar,
  });

  @override
  State<ItemConversaTile> createState() => _ItemConversaTileState();
}

class _ItemConversaTileState extends State<ItemConversaTile> {
  bool _hovered = false;

  void _mostrarMenuContexto(BuildContext ctx, [Offset? posicao]) {
    final RenderBox? overlay =
        Overlay.of(ctx).context.findRenderObject() as RenderBox?;
    final targetPos =
        posicao ??
        (overlay != null
            ? Offset(overlay.size.width / 2, overlay.size.height / 2)
            : Offset.zero);

    showMenu<String>(
      context: ctx,
      position: RelativeRect.fromRect(
        targetPos & const Size(40, 40),
        Offset.zero & (overlay?.size ?? const Size(800, 600)),
      ),
      color: widget.theme.cardBackgroundColor,
      items: [
        PopupMenuItem(
          value: 'fixar',
          child: Row(
            children: [
              Icon(
                widget.conversa.fixada
                    ? Icons.push_pin_outlined
                    : Icons.push_pin_rounded,
                size: 16,
                color: widget.theme.textColor,
              ),
              const SizedBox(width: 10),
              Text(
                widget.conversa.fixada
                    ? 'Desafixar conversa'
                    : 'Fixar conversa',
                style: widget.theme.getTextStyle(
                  fontSize: 13,
                  color: widget.theme.textColor,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'arquivar',
          child: Row(
            children: [
              Icon(
                widget.conversa.arquivada
                    ? Icons.unarchive_outlined
                    : Icons.archive_outlined,
                size: 16,
                color: widget.theme.textColor,
              ),
              const SizedBox(width: 10),
              Text(
                widget.conversa.arquivada ? 'Desarquivar' : 'Arquivar conversa',
                style: widget.theme.getTextStyle(
                  fontSize: 13,
                  color: widget.theme.textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((valor) {
      if (valor == 'fixar') {
        widget.onAlternarFixar?.call();
      } else if (valor == 'arquivar') {
        widget.onAlternarArquivar?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final selecionada = widget.selecionada;
    final conversa = widget.conversa;

    final corFundo = selecionada
        ? theme.cardBackgroundColor.withValues(alpha: 0.95)
        : (_hovered
              ? theme.cardBackgroundColor.withValues(alpha: 0.7)
              : Colors.transparent);

    final String tituloExibicao;
    if (conversa.titulo.trim().isNotEmpty &&
        conversa.titulo != 'Conversa' &&
        conversa.titulo != 'Nova Conversa' &&
        conversa.titulo != 'Contato' &&
        conversa.titulo != 'Contato Nous') {
      tituloExibicao = conversa.titulo;
    } else if (conversa.subtitulo.trim().isNotEmpty &&
        conversa.subtitulo != 'Conversa' &&
        conversa.subtitulo != 'Contato Nous') {
      tituloExibicao = conversa.subtitulo;
    } else if (conversa.ehGrupo && conversa.nomeGrupo.trim().isNotEmpty) {
      tituloExibicao = conversa.nomeGrupo;
    } else {
      tituloExibicao = 'Contato Nous';
    }

    final String subtituloExibicao;
    final temMensagensReais = conversa.mensagens.isNotEmpty ||
        (conversa.ultimaMensagem.isNotEmpty &&
            conversa.ultimaMensagem != 'Toque para conversar.' &&
            conversa.ultimaMensagem != 'Comandas e mensagens da loja.' &&
            conversa.ultimaMensagem != 'Canal direto da equipe com a loja.' &&
            conversa.ultimaMensagem != 'Canal de atendimento da loja.');

    if (conversa.ehGrupo) {
      if (conversa.nomeGrupo.isNotEmpty &&
          conversa.nomeGrupo != tituloExibicao) {
        subtituloExibicao = temMensagensReais
            ? '${conversa.nomeGrupo} • ${conversa.ultimaMensagem}'
            : conversa.nomeGrupo;
      } else {
        subtituloExibicao = temMensagensReais
            ? conversa.ultimaMensagem
            : (conversa.subtitulo != tituloExibicao &&
                    conversa.subtitulo != 'Conversa' &&
                    conversa.subtitulo != 'Contato Nous'
                ? conversa.subtitulo
                : 'Grupo Nous');
      }
    } else {
      final subValido = conversa.subtitulo.isNotEmpty &&
          conversa.subtitulo != tituloExibicao &&
          conversa.subtitulo != 'Conversa' &&
          conversa.subtitulo != 'Contato Nous' &&
          conversa.subtitulo != 'Contato';

      if (temMensagensReais) {
        if (conversa.temTituloConversa) {
          subtituloExibicao = subValido && conversa.subtitulo.startsWith('@')
              ? '${conversa.subtitulo} • 🏷️ ${conversa.tituloConversa} • ${conversa.ultimaMensagem}'
              : '🏷️ ${conversa.tituloConversa} • ${conversa.ultimaMensagem}';
        } else if (subValido && conversa.subtitulo.startsWith('@')) {
          subtituloExibicao =
              '${conversa.subtitulo} • ${conversa.ultimaMensagem}';
        } else {
          subtituloExibicao = conversa.ultimaMensagem;
        }
      } else if (conversa.temTituloConversa) {
        subtituloExibicao = subValido && conversa.subtitulo.startsWith('@')
            ? '${conversa.subtitulo} • 🏷️ ${conversa.tituloConversa}'
            : '🏷️ ${conversa.tituloConversa}';
      } else if (subValido) {
        subtituloExibicao = conversa.subtitulo;
      } else {
        subtituloExibicao = conversa.ehLoja ? 'Loja Nous' : 'Usuário Nous';
      }
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: () => _mostrarMenuContexto(context),
        onSecondaryTapUp: (details) =>
            _mostrarMenuContexto(context, details.globalPosition),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: corFundo,
            border: Border(
              left: BorderSide(
                color: selecionada
                    ? theme.buttonColor
                    : (_hovered
                          ? theme.buttonColor.withValues(alpha: 0.6)
                          : Colors.transparent),
                width: 4.0,
              ),
              top: BorderSide(
                color: selecionada
                    ? theme.borderColor.withValues(alpha: 0.8)
                    : (_hovered
                          ? theme.borderColor.withValues(alpha: 0.4)
                          : Colors.transparent),
                width: 0.8,
              ),
              bottom: BorderSide(
                color: selecionada
                    ? theme.borderColor.withValues(alpha: 0.8)
                    : (_hovered
                          ? theme.borderColor.withValues(alpha: 0.4)
                          : Colors.transparent),
                width: 0.8,
              ),
              right: BorderSide(
                color: selecionada
                    ? theme.borderColor.withValues(alpha: 0.8)
                    : (_hovered
                          ? theme.borderColor.withValues(alpha: 0.4)
                          : Colors.transparent),
                width: 0.8,
              ),
            ),
          ),
          child: Row(
            children: [
              widget.avatar,
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tituloExibicao,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.getTextStyle(
                              fontSize: 13,
                              fontWeight: selecionada
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                        if (conversa.fixada) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.push_pin_rounded,
                            size: 13,
                            color: theme.secondaryTextColor.withValues(
                              alpha: 0.85,
                            ),
                          ),
                        ],
                        const SizedBox(width: 6),
                        Text(
                          widget.horaFormatada,
                          style: theme.getTextStyle(
                            fontSize: 10,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subtituloExibicao,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.getTextStyle(
                              fontSize: 11,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                        ),
                        if (!selecionada && conversa.naoLidasCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.dangerColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${conversa.naoLidasCount}',
                              style: theme.getTextStyle(
                                fontSize: 9,
                                color: theme.buttonTextColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
