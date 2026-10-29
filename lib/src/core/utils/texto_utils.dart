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
}
