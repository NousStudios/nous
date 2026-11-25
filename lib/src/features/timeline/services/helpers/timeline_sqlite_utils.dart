import 'dart:convert';

/// Utilitários compartilhados pelos helpers SQLite da timeline.
class TimelineSqliteUtils {
  TimelineSqliteUtils._();

  static String normalizarCpf(String cpf) =>
      cpf.replaceAll(RegExp(r'\D'), '');

  static Map<String, dynamic> decodificarDadosJson(
    Map<String, Object?> row, {
    String coluna = 'dados_json',
  }) {
    final jsonStr = row[coluna] as String? ?? '{}';
    return jsonDecode(jsonStr) as Map<String, dynamic>;
  }
}
