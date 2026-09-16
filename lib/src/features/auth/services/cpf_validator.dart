// Validação LOCAL de CPF — não depende de internet nem de servidor.
//
// Todo CPF tem 11 dígitos. Os 2 últimos (os "dígitos verificadores") são
// calculados matematicamente a partir dos 9 primeiros. Esse arquivo refaz
// essa conta e confere se os 2 últimos dígitos batem com o que deveriam ser.
//
// IMPORTANTE: isso só confirma que o NÚMERO é matematicamente possível.
// Não confirma que a pessoa existe de verdade — isso é a etapa 2 (o
// servidor/backend), que ainda não existe no projeto.

class CpfValidator {
  // Impede que essa classe seja "instanciada" (ex: CpfValidator()).
  // Ela só serve para agrupar funções relacionadas a CPF.
  CpfValidator._();

  /// Remove tudo que não for número (pontos, traço, espaços).
  /// Ex: "123.456.789-09" vira "12345678909".
  static String onlyDigits(String input) {
    return input.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Devolve true se o CPF for matematicamente válido, false caso contrário.
  static bool isValid(String rawCpf) {
    final cpf = onlyDigits(rawCpf);

    // Um CPF sempre tem exatamente 11 dígitos.
    if (cpf.length != 11) return false;

    // CPFs como "111.111.111-11" ou "000.000.000-00" passariam na conta
    // matemática mas não são CPFs reais emitidos — por isso são bloqueados
    // manualmente aqui.
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return false;

    final digits = cpf.split('').map(int.parse).toList();

    // Confere o 1º dígito verificador (a 10ª posição, índice 9).
    final firstCheckDigit = _calculateCheckDigit(digits.sublist(0, 9));
    if (firstCheckDigit != digits[9]) return false;

    // Confere o 2º dígito verificador (a 11ª posição, índice 10).
    // Esse cálculo usa os 9 primeiros dígitos + o 1º dígito verificador.
    final secondCheckDigit = _calculateCheckDigit(digits.sublist(0, 10));
    if (secondCheckDigit != digits[10]) return false;

    return true;
  }

  /// Faz a conta oficial de um dígito verificador de CPF.
  /// Multiplica cada número por um "peso" que decresce, soma tudo,
  /// e aplica o resto da divisão por 11 (regra oficial da Receita Federal).
  static int _calculateCheckDigit(List<int> baseDigits) {
    int weight = baseDigits.length + 1;
    int sum = 0;

    for (final digit in baseDigits) {
      sum += digit * weight;
      weight--;
    }

    final remainder = sum % 11;
    return remainder < 2 ? 0 : 11 - remainder;
  }

  /// Aplica a máscara visual "123.456.789-09" enquanto o usuário digita.
  /// Útil para o campo de texto mostrar o CPF formatado.
  static String applyMask(String rawInput) {
    final digits = onlyDigits(rawInput);
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length && i < 11; i++) {
      buffer.write(digits[i]);
      if (i == 2 || i == 5) buffer.write('.');
      if (i == 8) buffer.write('-');
    }

    return buffer.toString();
  }
}