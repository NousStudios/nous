class ReferenciaLoja {
  final String lojaId;
  final String cpfDonoOriginal;

  const ReferenciaLoja({
    required this.lojaId,
    required this.cpfDonoOriginal,
  });

  Map<String, dynamic> toJson() {
    return {
      'lojaId': lojaId,
      'cpfDonoOriginal': cpfDonoOriginal,
    };
  }

  factory ReferenciaLoja.fromJson(Map<String, dynamic> json) {
    return ReferenciaLoja(
      lojaId: json['lojaId'] as String,
      cpfDonoOriginal: json['cpfDonoOriginal'] as String,
    );
  }
}