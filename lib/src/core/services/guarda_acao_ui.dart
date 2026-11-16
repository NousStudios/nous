import 'package:flutter/foundation.dart';

/// Evita a execução simultânea ou repetida em rajada (double/multi-tap)
/// de diálogos, navegações e processos assíncronos quando o usuário clica várias vezes.
class GuardaAcaoUi {
  GuardaAcaoUi._();

  static final Set<String> _emExecucao = <String>{};
  static final Map<String, DateTime> _ultimoFim = <String, DateTime>{};

  static bool _emCooldown(String chave, Duration cooldown) {
    final ultimo = _ultimoFim[chave];
    if (ultimo == null) return false;
    return DateTime.now().difference(ultimo) < cooldown;
  }

  /// Executa [acao] apenas se [chave] não estiver em andamento nem em cooldown.
  static Future<T?> executarUnico<T>(
    String chave,
    Future<T> Function() acao, {
    Duration cooldown = const Duration(milliseconds: 450),
  }) async {
    if (_emExecucao.contains(chave) || _emCooldown(chave, cooldown)) {
      return null;
    }
    _emExecucao.add(chave);
    try {
      return await acao();
    } finally {
      _emExecucao.remove(chave);
      _ultimoFim[chave] = DateTime.now();
    }
  }

  /// Executa [acao] síncrona apenas se [chave] não estiver em andamento nem em cooldown.
  static bool executarSincrono(
    String chave,
    VoidCallback acao, {
    Duration cooldown = const Duration(milliseconds: 450),
  }) {
    if (_emExecucao.contains(chave) || _emCooldown(chave, cooldown)) {
      return false;
    }
    _emExecucao.add(chave);
    try {
      acao();
      return true;
    } finally {
      _emExecucao.remove(chave);
      _ultimoFim[chave] = DateTime.now();
    }
  }

  @visibleForTesting
  static void limparParaTestes() {
    _emExecucao.clear();
    _ultimoFim.clear();
  }
}
