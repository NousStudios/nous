import 'package:flutter/material.dart';

/// Funções auxiliares para garantir contraste legível em qualquer parte do app,
/// mesmo quando o usuário personaliza as cores livremente.

/// Calcula se uma cor de fundo é "clara" ou "escura" com base na sua luminância
/// (o quanto de luz ela reflete), em vez de comparar com uma cor fixa.
/// Retorna Brightness.light se o fundo for claro, Brightness.dark se for escuro.
Brightness getBrightnessFor(Color backgroundColor) {
  // computeLuminance() retorna um valor de 0.0 (preto) a 1.0 (branco)
  return backgroundColor.computeLuminance() > 0.5
      ? Brightness.light
      : Brightness.dark;
}

/// Retorna branco ou preto — o que for mais legível — para ser usado
/// como cor de texto/ícone em cima da cor de fundo informada.
Color getReadableTextColor(Color backgroundColor) {
  return backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
}