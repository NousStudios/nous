import 'package:flutter/services.dart';

class TelefoneInputFormatter extends TextInputFormatter {
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

    if (digitos.length > 11) {
      digitos = digitos.substring(0, 11);
    }

    final textoFormatado = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      if (i == 0) textoFormatado.write('(');
      textoFormatado.write(digitos[i]);
      if (i == 1) textoFormatado.write(') ');

      final restantes = digitos.length - (i + 1);
      final metade = digitos.length == 11 ? 7 : 6;
      if (i + 1 == metade && restantes > 0) {
        textoFormatado.write('-');
      }
    }

    final resultado = textoFormatado.toString();
    return TextEditingValue(
      text: resultado,
      selection: TextSelection.collapsed(offset: resultado.length),
    );
  }
}