import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/auth/views/perfil_social_view.dart';

/// Renderiza um texto destacando `#hashtags` e `@menções` em azul, com toque clicável.
class TextoComHashtagsWidget extends StatefulWidget {
  final AppTheme theme;
  final String texto;
  final double fontSize;
  final ValueChanged<String>? onTapTag;
  final ValueChanged<String>? onTapMencao;

  const TextoComHashtagsWidget({
    super.key,
    required this.theme,
    required this.texto,
    this.fontSize = 13.5,
    this.onTapTag,
    this.onTapMencao,
  });

  static Future<void> abrirPerfilPorHandle(
    BuildContext context,
    String handle,
  ) async {
    final alvoLimpo = handle.replaceAll('@', '').trim().toLowerCase();
    if (alvoLimpo.isEmpty) return;
    final contas = await ContasNousService.carregarTodas();
    final alvo = contas.where((u) {
      final un = u.nomeDeUsuario.replaceAll('@', '').trim().toLowerCase();
      return un == alvoLimpo;
    }).firstOrNull;
    if (!context.mounted) return;
    if (alvo != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PerfilSocialView(
            usuarioAlvo: alvo,
            mostrarBotaoVoltar: true,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Perfil @$alvoLimpo não encontrado.')),
      );
    }
  }

  @override
  State<TextoComHashtagsWidget> createState() => _TextoComHashtagsWidgetState();
}

class _TextoComHashtagsWidgetState extends State<TextoComHashtagsWidget> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final texto = widget.texto;
    final regex = RegExp(r'[#@]([\p{L}\p{N}_\.]+)', unicode: true);
    final spans = <InlineSpan>[];
    int ultimoIndice = 0;
    const corHashtag = Color(0xFF1D9BF0);

    for (final match in regex.allMatches(texto)) {
      if (match.start > ultimoIndice) {
        spans.add(
          TextSpan(
            text: texto.substring(ultimoIndice, match.start),
            style: widget.theme.getTextStyle(
              fontSize: widget.fontSize,
              color: widget.theme.textColor,
            ),
          ),
        );
      }
      final ehHashtag = texto[match.start] == '#';
      final termoLimpo = (match.group(1) ?? '').toLowerCase();
      TapGestureRecognizer? recognizer;
      if (ehHashtag && widget.onTapTag != null && termoLimpo.isNotEmpty) {
        recognizer = TapGestureRecognizer()
          ..onTap = () => widget.onTapTag!(termoLimpo);
        _recognizers.add(recognizer);
      } else if (!ehHashtag && termoLimpo.isNotEmpty) {
        recognizer = TapGestureRecognizer()
          ..onTap = () {
            if (widget.onTapMencao != null) {
              widget.onTapMencao!(termoLimpo);
            } else {
              TextoComHashtagsWidget.abrirPerfilPorHandle(context, termoLimpo);
            }
          };
        _recognizers.add(recognizer);
      }
      spans.add(
        TextSpan(
          text: match.group(0),
          recognizer: recognizer,
          style: widget.theme.getTextStyle(
            fontSize: widget.fontSize,
            fontWeight: FontWeight.w600,
            color: corHashtag,
          ),
        ),
      );
      ultimoIndice = match.end;
    }

    if (ultimoIndice < texto.length) {
      spans.add(
        TextSpan(
          text: texto.substring(ultimoIndice),
          style: widget.theme.getTextStyle(
            fontSize: widget.fontSize,
            color: widget.theme.textColor,
          ),
        ),
      );
    }

    return Text.rich(TextSpan(children: spans));
  }
}
