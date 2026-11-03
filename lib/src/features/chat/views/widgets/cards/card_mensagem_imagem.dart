import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';

class CardMensagemImagem extends StatefulWidget {
  final MensagemChat msg;
  final bool enviadaPorMim;
  final AppTheme theme;
  final void Function(String caminho) onVisualizarFoto;

  const CardMensagemImagem({
    super.key,
    required this.msg,
    required this.enviadaPorMim,
    required this.theme,
    required this.onVisualizarFoto,
  });

  @override
  State<CardMensagemImagem> createState() => _CardMensagemImagemState();
}

class _CardMensagemImagemState extends State<CardMensagemImagem> {
  static final Set<String> _tentativasDownload = {};

  @override
  void initState() {
    super.initState();
    _verificarDownloadRemoto();
  }

  @override
  void didUpdateWidget(covariant CardMensagemImagem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.msg.caminhoAnexo != widget.msg.caminhoAnexo) {
      _verificarDownloadRemoto();
    }
  }

  void _verificarDownloadRemoto() {
    final resolvido = ImagemService.resolverCaminhoExistente(
      widget.msg.caminhoAnexo,
    );
    final arquivo = resolvido != null ? File(resolvido) : null;

    if ((arquivo == null || !arquivo.existsSync()) &&
        widget.msg.caminhoAnexo.isNotEmpty &&
        ClienteRedeLocal().conectado &&
        !_tentativasDownload.contains(widget.msg.id)) {
      _tentativasDownload.add(widget.msg.id);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final baixado = await ClienteRedeLocal().baixarImagemRemota(
            widget.msg.caminhoAnexo,
          );
          if (baixado.isNotEmpty &&
              baixado != widget.msg.caminhoAnexo &&
              mounted) {
            await ChatService.salvarMensagem(
              widget.msg.copyWith(caminhoAnexo: baixado),
              originadaDaRede: true,
            );
            if (mounted) setState(() {});
          }
        } catch (_) {}
      });
    }
  }

  Widget _buildPlaceholderErro() {
    return Container(
      width: 180,
      height: 120,
      decoration: BoxDecoration(
        color: widget.theme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.theme.borderColor.withValues(alpha: 0.5),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_outlined,
              size: 28,
              color: widget.theme.secondaryTextColor,
            ),
            const SizedBox(height: 4),
            Text(
              'Imagem indisponível',
              style: widget.theme.getTextStyle(
                fontSize: 11,
                color: widget.theme.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvido = ImagemService.resolverCaminhoExistente(
      widget.msg.caminhoAnexo,
    );
    final arquivo = resolvido != null ? File(resolvido) : null;

    return Column(
      crossAxisAlignment: widget.enviadaPorMim
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (arquivo != null && arquivo.existsSync())
          GestureDetector(
            onTap: () => widget.onVisualizarFoto(arquivo.path),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 240,
                  maxHeight: 200,
                ),
                child: Image.file(
                  arquivo,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildPlaceholderErro(),
                ),
              ),
            ),
          )
        else
          _buildPlaceholderErro(),
        if (widget.msg.texto.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            widget.msg.texto,
            style: widget.theme.getTextStyle(
              fontSize: 13,
              color: widget.theme.textColor,
            ),
          ),
        ],
      ],
    );
  }
}
