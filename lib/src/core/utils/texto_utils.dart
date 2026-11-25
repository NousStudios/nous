/// Utilitários de manipulação de texto e normalização para buscas
class TextoUtils {
  TextoUtils._();

  static const String _comAcento =
      'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÌÍÎÏìíîïÙÚÛÜùúûüÇçÑñÝýÿ';
  static const String _semAcento =
      'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeIIIIiiiiUUUUuuuuCcNnYyy';

  /// Remove acentos e diacríticos de uma string, preservando caracteres normais.
  static String removerAcentos(String texto) {
    if (texto.isEmpty) return '';
    var resultado = texto;
    for (int i = 0; i < _comAcento.length; i++) {
      resultado = resultado.replaceAll(_comAcento[i], _semAcento[i]);
    }
    return resultado;
  }

  /// Normaliza um texto para busca: remove espaços excedentes, passa para minúsculo e remove acentos.
  static String normalizarParaBusca(String texto) {
    return removerAcentos(texto.toLowerCase().trim());
  }

  /// Verifica se [textoAlvo] contém [termoPesquisa] ignorando maiúsculas/minúsculas e acentuação.
  static bool contemIgnorandoAcentos(String textoAlvo, String termoPesquisa) {
    if (termoPesquisa.trim().isEmpty) return true;
    final alvoNorm = normalizarParaBusca(textoAlvo);
    final termoNorm = normalizarParaBusca(termoPesquisa);
    return alvoNorm.contains(termoNorm);
  }

  /// Calcula relevância entre `0.0` (sem relação) e `1.0` (igual) tolerando
  /// pequenos erros de digitação ou transcrição de voz (distância de Levenshtein).
  static double calcularRelevanciaBusca(
    String textoAlvo,
    String termoPesquisa,
  ) {
    final termoNorm = normalizarParaBusca(termoPesquisa);
    if (termoNorm.isEmpty) return 1.0;
    final alvoNorm = normalizarParaBusca(textoAlvo);
    if (alvoNorm.isEmpty) return 0.0;

    if (alvoNorm == termoNorm) return 1.0;
    if (alvoNorm.startsWith(termoNorm)) return 0.95;
    if (alvoNorm.contains(termoNorm)) return 0.90;

    final tokensTermo = termoNorm
        .split(RegExp(r'[\s,.;:!?-]+'))
        .where((t) => t.length >= 3)
        .toList();
    if (tokensTermo.isEmpty) return 0.0;

    final palavrasAlvo = alvoNorm
        .split(RegExp(r'[\s,.;:!?-]+'))
        .where((p) => p.length >= 2)
        .toList();
    if (palavrasAlvo.isEmpty) return 0.0;

    var somaScores = 0.0;
    var matches = 0;

    for (final token in tokensTermo) {
      var melhorToken = 0.0;
      for (final palavra in palavrasAlvo) {
        if (palavra == token) {
          melhorToken = 1.0;
          break;
        }
        if (palavra.contains(token) || token.contains(palavra)) {
          if (0.82 > melhorToken) melhorToken = 0.82;
          continue;
        }
        final maxLen =
            palavra.length > token.length ? palavra.length : token.length;
        final maxDist = maxLen <= 4 ? 1 : (maxLen <= 8 ? 2 : 3);
        if ((palavra.length - token.length).abs() > maxDist) continue;
        final dist = _levenshtein(token, palavra);
        if (dist <= maxDist) {
          final sim = (1.0 - (dist / maxLen)) * 0.80;
          if (sim > melhorToken) melhorToken = sim;
        }
      }
      if (melhorToken >= 0.50) {
        matches++;
        somaScores += melhorToken;
      }
    }

    if (matches == 0) return 0.0;
    return (somaScores / tokensTermo.length).clamp(0.0, 0.89);
  }

  static int _levenshtein(String a, String b) {
    final m = a.length;
    final n = b.length;
    if (m == 0) return n;
    if (n == 0) return m;
    var prev = List<int>.generate(n + 1, (j) => j);
    var curr = List<int>.filled(n + 1, 0);
    for (var i = 1; i <= m; i++) {
      curr[0] = i;
      for (var j = 1; j <= n; j++) {
        final custo = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        final del = prev[j] + 1;
        final ins = curr[j - 1] + 1;
        final sub = prev[j - 1] + custo;
        var min = del < ins ? del : ins;
        if (sub < min) min = sub;
        curr[j] = min;
      }
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }
    return prev[n];
  }
}
