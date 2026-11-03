import 'package:flutter/services.dart';

/// Converte automaticamente a primeira letra de cada palavra em maiúscula enquanto o usuário digita.
/// Permite letras minúsculas caso o usuário tenha apagado uma letra e digitado explicitamente em minúsculo.
class PrimeiraLetraMaiusculaFormatter extends TextInputFormatter {
  int? _posicaoPermitirMinuscula;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final texto = newValue.text;
    if (texto.isEmpty) {
      _posicaoPermitirMinuscula = null;
      return newValue;
    }

    // Se o usuário apagou algo (backspace ou delete)
    if (newValue.text.length < oldValue.text.length) {
      final offset = newValue.selection.baseOffset;
      if (offset >= 0) {
        _posicaoPermitirMinuscula = offset;
      }
      return newValue;
    }

    final buffer = StringBuffer();
    bool proximaMaiuscula = true;

    final inseriuUmChar = (newValue.text.length == oldValue.text.length + 1);
    final posInserida = newValue.selection.baseOffset - 1;

    for (int i = 0; i < texto.length; i++) {
      final char = texto[i];
      if (char == ' ' ||
          char == '\t' ||
          char == '\n' ||
          char == '-' ||
          char == '\'') {
        buffer.write(char);
        proximaMaiuscula = true;
      } else if (proximaMaiuscula) {
        // Se essa posição já era minúscula no oldValue, mantém minúscula
        final eraMinusculaNoOldValue = i < oldValue.text.length &&
            oldValue.text[i] == char &&
            char.toLowerCase() == char &&
            char.toUpperCase() != char;

        // Se o usuário apagou anteriormente nessa posição e está inserindo agora
        final permitirMinusculaAqui = (_posicaoPermitirMinuscula != null &&
            inseriuUmChar &&
            posInserida == i &&
            (posInserida == _posicaoPermitirMinuscula ||
                posInserida == _posicaoPermitirMinuscula! + 1));

        if (eraMinusculaNoOldValue || permitirMinusculaAqui) {
          buffer.write(char);
        } else {
          buffer.write(char.toUpperCase());
        }
        proximaMaiuscula = false;
      } else {
        buffer.write(char);
      }
    }

    if (inseriuUmChar && posInserida == _posicaoPermitirMinuscula) {
      _posicaoPermitirMinuscula = null;
    }

    final formatado = buffer.toString();
    return TextEditingValue(
      text: formatado,
      selection: newValue.selection,
    );
  }
}
