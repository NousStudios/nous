enum PapelMembro { dono, socio, admin, funcionario }

class MembroLoja {
  final String cpf;
  final String nome;
  final PapelMembro papel;
  final DateTime desde;

  const MembroLoja({
    required this.cpf,
    required this.nome,
    required this.papel,
    required this.desde,
  });

  MembroLoja copyWith({
    String? nome,
    PapelMembro? papel,
    DateTime? desde,
  }) {
    return MembroLoja(
      cpf: cpf,
      nome: nome ?? this.nome,
      papel: papel ?? this.papel,
      desde: desde ?? this.desde,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cpf': cpf,
      'nome': nome,
      'papel': papel.name,
      'desde': desde.toIso8601String(),
    };
  }

  factory MembroLoja.fromJson(Map<String, dynamic> json) {
    return MembroLoja(
      cpf: json['cpf'] as String,
      nome: json['nome'] as String? ?? '',
      papel: PapelMembro.values.byName(json['papel'] as String),
      desde: DateTime.parse(json['desde'] as String),
    );
  }
}