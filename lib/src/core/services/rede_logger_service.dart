import 'package:flutter/foundation.dart';

class RegistroLogRede {
  final DateTime dataHora;
  final String origem;
  final String mensagem;
  final bool ehErro;

  const RegistroLogRede({
    required this.dataHora,
    required this.origem,
    required this.mensagem,
    this.ehErro = false,
  });
}

/// Buffer circular leve em memória para registrar eventos e falhas de rede/sync/CEP/OSM
/// sem bloquear a UI nem gravar arquivos desnecessários em disco.
class RedeLoggerService {
  RedeLoggerService._();

  static const int _limiteRegistros = 120;
  static final List<RegistroLogRede> _registros = [];

  static List<RegistroLogRede> get registros => List.unmodifiable(_registros);

  static void registrar(
    String origem,
    String mensagem, {
    bool erro = false,
  }) {
    if (_registros.length >= _limiteRegistros) {
      _registros.removeAt(0);
    }
    _registros.add(
      RegistroLogRede(
        dataHora: DateTime.now(),
        origem: origem,
        mensagem: mensagem,
        ehErro: erro,
      ),
    );
    if (kDebugMode) {
      debugPrint('[$origem]${erro ? ' [ERRO]' : ''} $mensagem');
    }
  }

  static void limpar() => _registros.clear();
}
