class Cliente {
  final String id;
  final String nome;
  final String endereco;
  final String telefone;
  final String cnpj;

  const Cliente({
    required this.id,
    required this.nome,
    this.endereco = '',
    this.telefone = '',
    this.cnpj = '',
  });

  Cliente copyWith({
    String? nome,
    String? endereco,
    String? telefone,
    String? cnpj,
  }) {
    return Cliente(
      id: id,
      nome: nome ?? this.nome,
      endereco: endereco ?? this.endereco,
      telefone: telefone ?? this.telefone,
      cnpj: cnpj ?? this.cnpj,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'endereco': endereco,
      'telefone': telefone,
      'cnpj': cnpj,
    };
  }

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] as String,
      nome: json['nome'] as String,
      endereco: json['endereco'] as String? ?? '',
      telefone: json['telefone'] as String? ?? '',
      cnpj: json['cnpj'] as String? ?? '',
    );
  }
}