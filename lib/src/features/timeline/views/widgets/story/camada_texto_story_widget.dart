import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';

/// Renderiza uma [CamadaTextoStory] com a fonte, alinhamento, cor e escala configurados.
class CamadaTextoStoryWidget extends StatelessWidget {
  final CamadaTextoStory camada;
  final ValueChanged<String>? onTapMencao;

  const CamadaTextoStoryWidget({
    super.key,
    required this.camada,
    this.onTapMencao,
  });

  static TextStyle resolverEstilo(CamadaTextoStory camada) {
    final corTexto = parseHex(camada.corTextoHex, const Color(0xFFFFFFFF));
    final tamanhoBase = 20.0 * camada.escala.clamp(0.6, 2.5);
    switch (camada.fonte) {
      case 'negrito':
        return TextStyle(
          color: corTexto,
          fontSize: tamanhoBase,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        );
      case 'serif':
        return TextStyle(
          color: corTexto,
          fontSize: tamanhoBase,
          fontFamily: 'serif',
          fontWeight: FontWeight.w600,
        );
      case 'mono':
        return TextStyle(
          color: corTexto,
          fontSize: tamanhoBase * 0.92,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w600,
        );
      default:
        return TextStyle(
          color: corTexto,
          fontSize: tamanhoBase,
          fontWeight: FontWeight.w600,
        );
    }
  }

  static Color parseHex(String hex, Color fallback) {
    final limpo = hex.replaceAll('#', '').trim();
    if (limpo.isEmpty) return fallback;
    final norm = limpo.length == 6 ? 'FF$limpo' : limpo;
    final val = int.tryParse(norm, radix: 16);
    return val != null ? Color(val) : fallback;
  }

  TextAlign _alinhamento() {
    switch (camada.alinhamento) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.center;
    }
  }

  @override
  Widget build(BuildContext context) {
    final temFundo = camada.corFundoHex.trim().isNotEmpty;
    final corFundo = temFundo
        ? parseHex(camada.corFundoHex, const Color(0x8A000000))
        : Colors.transparent;

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: EdgeInsets.symmetric(
        horizontal: temFundo ? 12 : 4,
        vertical: temFundo ? 6 : 2,
      ),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(10),
        boxShadow: temFundo
            ? null
            : const [
                BoxShadow(color: Color(0xDD000000), blurRadius: 8),
              ],
      ),
      child: (onTapMencao != null && camada.texto.contains('@'))
          ? _buildTextoComMencoes(resolverEstilo(camada))
          : Text(
              camada.texto,
              textAlign: _alinhamento(),
              style: resolverEstilo(camada),
            ),
    );
  }

  Widget _buildTextoComMencoes(TextStyle estiloBase) {
    final regex = RegExp(r'@([a-zA-Z0-9._]+)');
    final texto = camada.texto;
    final spans = <InlineSpan>[];
    var ultimo = 0;
    for (final m in regex.allMatches(texto)) {
      if (m.start > ultimo) {
        spans.add(
          TextSpan(text: texto.substring(ultimo, m.start), style: estiloBase),
        );
      }
      final handle = m.group(1) ?? '';
      spans.add(
        TextSpan(
          text: m.group(0),
          style: estiloBase.copyWith(
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w800,
          ),
          recognizer: handle.isNotEmpty
              ? (TapGestureRecognizer()..onTap = () => onTapMencao!(handle))
              : null,
        ),
      );
      ultimo = m.end;
    }
    if (ultimo < texto.length) {
      spans.add(TextSpan(text: texto.substring(ultimo), style: estiloBase));
    }
    return Text.rich(
      TextSpan(children: spans),
      textAlign: _alinhamento(),
    );
  }
}
