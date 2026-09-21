class UsuarioNous {
  final String cpf;
  final String nome;
  final String dataNascimento;
  final List<String> emails;

  const UsuarioNous({
    required this.cpf,
    required this.nome,
    required this.dataNascimento,
    this.emails = const [],
  });

  UsuarioNous copyWith({
    String? nome,
    String? dataNascimento,
    List<String>? emails,
  }) {
    return UsuarioNous(
      cpf: cpf,
      nome: nome ?? this.nome,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      emails: emails ?? this.emails,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cpf': cpf,
      'nome': nome,
      'dataNascimento': dataNascimento,
      'emails': emails,
    };
  }

  factory UsuarioNous.fromJson(Map<String, dynamic> json) {
    return UsuarioNous(
      cpf: json['cpf'] as String,
      nome: json['nome'] as String,
      dataNascimento: json['dataNascimento'] as String,
      emails: (json['emails'] as List<dynamic>? ?? const [])
          .map((item) => item as String)
          .toList(),
    );
  }
}