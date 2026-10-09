class Fornecedor {
  final String id;
  final String nome;
  final String cnpj;
  final String telefone;
  final String endereco;
  final String numero;
  final String email;
  final String redesSociais;
  final String descricao;
  final String origemClienteId;
  final String foto;
  final DateTime dataCriacao;

  const Fornecedor({
    required this.id,
    required this.nome,
    this.cnpj = '',
    this.telefone = '',
    this.endereco = '',
    this.numero = '',
    this.email = '',
    this.redesSociais = '',
    this.descricao = '',
    this.origemClienteId = '',
    this.foto = '',
    required this.dataCriacao,
  });

  Fornecedor copyWith({
    String? nome,
    String? cnpj,
    String? telefone,
    String? endereco,
    String? numero,
    String? email,
    String? redesSociais,
    String? descricao,
    String? origemClienteId,
    String? foto,
  }) {
    return Fornecedor(
      id: id,
      nome: nome ?? this.nome,
      cnpj: cnpj ?? this.cnpj,
      telefone: telefone ?? this.telefone,
      endereco: endereco ?? this.endereco,
      numero: numero ?? this.numero,
      email: email ?? this.email,
      redesSociais: redesSociais ?? this.redesSociais,
      descricao: descricao ?? this.descricao,
      origemClienteId: origemClienteId ?? this.origemClienteId,
      foto: foto ?? this.foto,
      dataCriacao: dataCriacao,
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
      'origemClienteId': origemClienteId,
      'foto': foto,
      'dataCriacao': dataCriacao.toIso8601String(),
    };
  }

  factory Fornecedor.fromJson(Map<String, dynamic> json) {
    final dataTexto = json['dataCriacao'] as String?;
    return Fornecedor(
      id: json['id'] as String,
      nome: json['nome'] as String? ?? '',
      cnpj: json['cnpj'] as String? ?? '',
      telefone: json['telefone'] as String? ?? '',
      endereco: json['endereco'] as String? ?? '',
      numero: json['numero'] as String? ?? '',
      email: json['email'] as String? ?? '',
      redesSociais: json['redesSociais'] as String? ?? '',
      descricao: json['descricao'] as String? ?? '',
      origemClienteId: json['origemClienteId'] as String? ?? '',
      foto: json['foto'] as String? ?? '',
      dataCriacao: dataTexto == null
          ? DateTime.now()
          : DateTime.tryParse(dataTexto) ?? DateTime.now(),
    );
  }

  bool correspondeABusca(String termo) {
    if (termo.isEmpty) return true;
    final termoLimpo = termo.trim().toLowerCase();
    if (termoLimpo.isEmpty) return true;

    final termoDigitos = termo.replaceAll(RegExp(r'[^0-9]'), '');

    if (nome.toLowerCase().contains(termoLimpo)) return true;
    if (endereco.toLowerCase().contains(termoLimpo)) return true;
    if (numero.toLowerCase().contains(termoLimpo)) return true;
    if (email.toLowerCase().contains(termoLimpo)) return true;
    if (redesSociais.toLowerCase().contains(termoLimpo)) return true;
    if (descricao.toLowerCase().contains(termoLimpo)) return true;
    if (cnpj.toLowerCase().contains(termoLimpo)) return true;
    if (telefone.toLowerCase().contains(termoLimpo)) return true;

    if (termoDigitos.isNotEmpty) {
      final docDigitos = cnpj.replaceAll(RegExp(r'[^0-9]'), '');
      if (docDigitos.contains(termoDigitos)) return true;
      final telDigitos = telefone.replaceAll(RegExp(r'[^0-9]'), '');
      if (telDigitos.contains(termoDigitos)) return true;
    }

    return false;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Fornecedor && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}