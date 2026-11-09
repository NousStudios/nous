import 'package:flutter/services.dart';

/// Formatador de máscara soberano para datas no padrão brasileiro DD/MM/AAAA.
/// Garante que digitar com ou sem barras, colar textos ou editar posições intermediárias
/// nunca inverta dígitos nem reposicione o cursor incorretamente.
class DataInputFormatterBR extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Conta quantos dígitos numéricos estavam antes do cursor do usuário
    int digitosAntesDoCursor = 0;
    for (int i = 0; i < newValue.selection.end && i < newValue.text.length; i++) {
      final c = newValue.text.codeUnitAt(i);
      if (c >= 48 && c <= 57) {
        digitosAntesDoCursor++;
      }
    }

    // Extrai apenas os números limitados a 8 dígitos
    final digitos = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limitado = digitos.length > 8 ? digitos.substring(0, 8) : digitos;

    if (digitosAntesDoCursor > limitado.length) {
      digitosAntesDoCursor = limitado.length;
    }

    // Formata no padrão DD/MM/AAAA
    final buffer = StringBuffer();
    for (int i = 0; i < limitado.length; i++) {
      if (i == 2 || i == 4) {
        buffer.write('/');
      }
      buffer.write(limitado[i]);
    }
    final textoFormatado = buffer.toString();

    // Posiciona o cursor exatamente após a quantidade de dígitos contados
    int novoOffset = 0;
    int digitosContados = 0;
    for (int i = 0; i < textoFormatado.length; i++) {
      if (digitosContados == digitosAntesDoCursor) {
        break;
      }
      final c = textoFormatado.codeUnitAt(i);
      if (c >= 48 && c <= 57) {
        digitosContados++;
      }
      novoOffset = i + 1;
    }

    // Se o cursor parou exatamente antes de uma barra '/', avança após a barra
    if (novoOffset < textoFormatado.length && textoFormatado[novoOffset] == '/') {
      novoOffset++;
    }

    if (novoOffset > textoFormatado.length) {
      novoOffset = textoFormatado.length;
    }

    return TextEditingValue(
      text: textoFormatado,
      selection: TextSelection.collapsed(offset: novoOffset),
    );
  }
}
