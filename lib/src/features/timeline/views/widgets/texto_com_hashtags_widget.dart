import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Renderiza um texto destacando `#hashtags` em azul, com toque opcional na tag.
class TextoComHashtagsWidget extends StatefulWidget {
  final AppTheme theme;
  final String texto;
  final double fontSize;
  final ValueChanged<String>? onTapTag;

  const TextoComHashtagsWidget({
    super.key,
    required this.theme,
    required this.texto,
    this.fontSize = 13.5,
    this.onTapTag,
  });

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
    final regex = RegExp(r'#([\p{L}\p{N}_]+)', unicode: true);
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
      final tagSemCerquilha = (match.group(1) ?? '').toLowerCase();
      TapGestureRecognizer? recognizer;
      if (widget.onTapTag != null && tagSemCerquilha.isNotEmpty) {
        recognizer = TapGestureRecognizer()
          ..onTap = () => widget.onTapTag!(tagSemCerquilha);
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
