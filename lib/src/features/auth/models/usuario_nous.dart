class UsuarioNous {
  final String cpf;
  final String nome;
  final String apelido;
  final String dataNascimento;
  final List<String> emails;
  final String foto;
  final String nomePai;
  final String nomeMae;
  final String localNascimento;
  final String tipoSanguineo;
  final String estadoCivil;
  final String biografia;
  final String nomePublico;
  final String apelidoPublico;
  final String fotoPublica;

  const UsuarioNous({
    required this.cpf,
    required this.nome,
    this.apelido = '',
    required this.dataNascimento,
    this.emails = const [],
    this.foto = '',
    this.nomePai = '',
    this.nomeMae = '',
    this.localNascimento = '',
    this.tipoSanguineo = '',
    this.estadoCivil = '',
    this.biografia = '',
    this.nomePublico = '',
    this.apelidoPublico = '',
    this.fotoPublica = '',
  });

  String get nomeExibicao =>
      nomePublico.trim().isNotEmpty ? nomePublico.trim() : nome;
  String get apelidoExibicao =>
      apelidoPublico.trim().isNotEmpty ? apelidoPublico.trim() : apelido;
  String get fotoExibicao =>
      fotoPublica.trim().isNotEmpty ? fotoPublica.trim() : foto;

  UsuarioNous copyWith({
    String? nome,
    String? apelido,
    String? dataNascimento,
    List<String>? emails,
    String? foto,
    String? nomePai,
    String? nomeMae,
    String? localNascimento,
    String? tipoSanguineo,
    String? estadoCivil,
    String? biografia,
    String? nomePublico,
    String? apelidoPublico,
    String? fotoPublica,
  }) {
    return UsuarioNous(
      cpf: cpf,
      nome: nome ?? this.nome,
      apelido: apelido ?? this.apelido,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      emails: emails ?? this.emails,
      foto: foto ?? this.foto,
      nomePai: nomePai ?? this.nomePai,
      nomeMae: nomeMae ?? this.nomeMae,
      localNascimento: localNascimento ?? this.localNascimento,
      tipoSanguineo: tipoSanguineo ?? this.tipoSanguineo,
      estadoCivil: estadoCivil ?? this.estadoCivil,
      biografia: biografia ?? this.biografia,
      nomePublico: nomePublico ?? this.nomePublico,
      apelidoPublico: apelidoPublico ?? this.apelidoPublico,
      fotoPublica: fotoPublica ?? this.fotoPublica,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cpf': cpf,
      'nome': nome,
      'apelido': apelido,
      'dataNascimento': dataNascimento,
      'emails': emails,
      'foto': foto,
      'nomePai': nomePai,
      'nomeMae': nomeMae,
      'localNascimento': localNascimento,
      'tipoSanguineo': tipoSanguineo,
      'estadoCivil': estadoCivil,
      'biografia': biografia,
      'nomePublico': nomePublico,
      'apelidoPublico': apelidoPublico,
      'fotoPublica': fotoPublica,
    };
  }

  factory UsuarioNous.fromJson(Map<String, dynamic> json) {
    return UsuarioNous(
      cpf: json['cpf'] as String? ?? '',
      nome: json['nome'] as String? ?? '',
      apelido: json['apelido'] as String? ?? '',
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
      biografia: json['biografia'] as String? ?? '',
      nomePublico: json['nomePublico'] as String? ?? '',
      apelidoPublico: json['apelidoPublico'] as String? ?? '',
      fotoPublica: json['fotoPublica'] as String? ?? '',
    );
  }
}