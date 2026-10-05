class UsuarioNous {
  final String cpf;
  final String nome;
  final String dataNascimento;
  final List<String> emails;
  final String foto;
  final String nomePai;
  final String nomeMae;
  final String localNascimento;
  final String tipoSanguineo;
  final String estadoCivil;

  const UsuarioNous({
    required this.cpf,
    required this.nome,
    required this.dataNascimento,
    this.emails = const [],
    this.foto = '',
    this.nomePai = '',
    this.nomeMae = '',
    this.localNascimento = '',
    this.tipoSanguineo = '',
    this.estadoCivil = '',
  });

  UsuarioNous copyWith({
    String? nome,
    String? dataNascimento,
    List<String>? emails,
    String? foto,
    String? nomePai,
    String? nomeMae,
    String? localNascimento,
    String? tipoSanguineo,
    String? estadoCivil,
  }) {
    return UsuarioNous(
      cpf: cpf,
      nome: nome ?? this.nome,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      emails: emails ?? this.emails,
      foto: foto ?? this.foto,
      nomePai: nomePai ?? this.nomePai,
      nomeMae: nomeMae ?? this.nomeMae,
      localNascimento: localNascimento ?? this.localNascimento,
      tipoSanguineo: tipoSanguineo ?? this.tipoSanguineo,
      estadoCivil: estadoCivil ?? this.estadoCivil,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cpf': cpf,
      'nome': nome,
      'dataNascimento': dataNascimento,
      'emails': emails,
      'foto': foto,
      'nomePai': nomePai,
      'nomeMae': nomeMae,
      'localNascimento': localNascimento,
      'tipoSanguineo': tipoSanguineo,
      'estadoCivil': estadoCivil,
    };
  }

  factory UsuarioNous.fromJson(Map<String, dynamic> json) {
    return UsuarioNous(
      cpf: json['cpf'] as String? ?? '',
      nome: json['nome'] as String? ?? '',
      dataNascimento: json['dataNascimento'] as String? ?? '',
      emails: (json['emails'] as List<dynamic>? ?? const [])
          .map((item) => item as String)
          .toList(),
      foto: json['foto'] as String? ?? '',
      nomePai: json['nomePai'] as String? ?? '',
      nomeMae: json['nomeMae'] as String? ?? '',
      localNascimento: json['localNascimento'] as String? ?? '',
      tipoSanguineo: json['tipoSanguineo'] as String? ?? '',
      estadoCivil: json['estadoCivil'] as String? ?? '',
    );
  }
}