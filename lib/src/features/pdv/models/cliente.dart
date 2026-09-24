class Cliente {
  final String id;
  final String nome;
  final String cnpj;
  final String telefone;
  final String endereco;
  final String numero;
  final String email;
  final String redesSociais;
  final String descricao;

  const Cliente({
    required this.id,
    required this.nome,
    this.cnpj = '',
    this.telefone = '',
    this.endereco = '',
    this.numero = '',
    this.email = '',
    this.redesSociais = '',
    this.descricao = '',
  });

  Cliente copyWith({
    String? nome,
    String? cnpj,
    String? telefone,
    String? endereco,
    String? numero,
    String? email,
    String? redesSociais,
    String? descricao,
  }) {
    return Cliente(
      id: id,
      nome: nome ?? this.nome,
      cnpj: cnpj ?? this.cnpj,
      telefone: telefone ?? this.telefone,
      endereco: endereco ?? this.endereco,
      numero: numero ?? this.numero,
      email: email ?? this.email,
      redesSociais: redesSociais ?? this.redesSociais,
      descricao: descricao ?? this.descricao,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'cnpj': cnpj,
      'telefone': telefone,
      'endereco': endereco,
      'numero': numero,
      'email': email,
      'redesSociais': redesSociais,
      'descricao': descricao,
    };
  }

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] as String,
      nome: json['nome'] as String,
      cnpj: json['cnpj'] as String? ?? '',
      telefone: json['telefone'] as String? ?? '',
      endereco: json['endereco'] as String? ?? '',
      numero: json['numero'] as String? ?? '',
      email: json['email'] as String? ?? '',
      redesSociais: json['redesSociais'] as String? ?? '',
      descricao: json['descricao'] as String? ?? '',
    );
  }
}