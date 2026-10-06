import 'package:flutter/services.dart';

class CpfOuCnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digitos = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    final apagando = newValue.text.length < oldValue.text.length;
    final digitosAntigos = oldValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (apagando &&
        digitos.length == digitosAntigos.length &&
        digitos.isNotEmpty) {
      digitos = digitos.substring(0, digitos.length - 1);
    }

    if (digitos.length > 14) {
      digitos = digitos.substring(0, 14);
    }

    final buffer = StringBuffer();
    if (digitos.length <= 11) {
      for (var i = 0; i < digitos.length; i++) {
        buffer.write(digitos[i]);
        final posicao = i + 1;
        if (posicao == 3 || posicao == 6) buffer.write('.');
        if (posicao == 9) buffer.write('-');
      }
    } else {
      for (var i = 0; i < digitos.length; i++) {
        buffer.write(digitos[i]);
        final posicao = i + 1;
        if (posicao == 2 || posicao == 5) buffer.write('.');
        if (posicao == 8) buffer.write('/');
        if (posicao == 12) buffer.write('-');
      }
    }

    final resultado = buffer.toString();
    return TextEditingValue(
      text: resultado,
      selection: TextSelection.collapsed(offset: resultado.length),
    );
  }
}
