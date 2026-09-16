import 'package:flutter/services.dart';

// TextInputFormatter que aplica a máscara de CNPJ (00.000.000/0000-00)
// automaticamente enquanto o usuário digita.
//
// Como funciona: toda vez que o texto do campo muda, o Flutter chama
// formatEditUpdate(). Aqui a gente ignora completamente o texto formatado
// anterior e reconstrói a máscara do zero, sempre a partir dos DÍGITOS que
// o usuário já digitou. Isso evita o problema clássico de "o cursor trava
// em cima do ponto/barra/traço da máscara" quando o usuário aperta
// backspace — porque não existe lógica de "andar" pela máscara, a gente
// simplesmente monta ela de novo a cada tecla digitada.
class CnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove tudo que não for número (pontos, barra, traço, letras...).
    var digitos = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // CNPJ tem 14 dígitos. Se o usuário tentar digitar mais que isso,
    // simplesmente ignoramos o excesso.
    if (digitos.length > 14) {
      digitos = digitos.substring(0, 14);
    }

    // Monta a máscara "00.000.000/0000-00" dígito por dígito.
    final textoFormatado = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      textoFormatado.write(digitos[i]);
      final posicao = i + 1; // posição "humana": 1ª, 2ª, 3ª casa...
      if (posicao == 2 || posicao == 5) textoFormatado.write('.');
      if (posicao == 8) textoFormatado.write('/');
      if (posicao == 12) textoFormatado.write('-');
    }

    final resultado = textoFormatado.toString();
    return TextEditingValue(
      text: resultado,
      // Sempre deixa o cursor no final do texto — é o comportamento mais
      // natural para quem está digitando um número aos poucos.
      selection: TextSelection.collapsed(offset: resultado.length),
    );
  }
}