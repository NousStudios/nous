import 'dart:math';

int _contadorId = 0;
final _randomId = Random();

String gerarIdUnico() {
  _contadorId = (_contadorId + 1) & 0xFFFF;
  return '${DateTime.now().millisecondsSinceEpoch}_${_contadorId}_${_randomId.nextInt(9999)}';
}