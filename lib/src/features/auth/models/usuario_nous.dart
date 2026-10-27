class UsuarioNous {
  final String cpf;
  final String nome;
  final String apelido;
  final String nomeDeUsuario;
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
  final List<String> dadosPrivados;
  final List<String> dadosAutorizadosPorCpf;
  final List<String> seguindo;
  final List<String> seguidores;

  const UsuarioNous({
    required this.cpf,
    required this.nome,
    this.apelido = '',
    this.nomeDeUsuario = '',
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
    this.dadosPrivados = const ['cpf', 'emails', 'dataNascimento', 'filiacao'],
    this.dadosAutorizadosPorCpf = const [],
    this.seguindo = const [],
    this.seguidores = const [],
  });

  String get nomeExibicao =>
      nomePublico.trim().isNotEmpty ? nomePublico.trim() : nome;
  String get apelidoExibicao =>
      apelidoPublico.trim().isNotEmpty ? apelidoPublico.trim() : apelido;
  String get fotoExibicao =>
      fotoPublica.trim().isNotEmpty ? fotoPublica.trim() : foto;

  String get usernameExibicao {
    final limpo = nomeDeUsuario.replaceAll('@', '').trim();
    if (limpo.isNotEmpty) {
      return '@$limpo';
    }
    final apelidoLimpo = apelidoExibicao.replaceAll('@', '').trim();
    if (apelidoLimpo.isNotEmpty) {
      return '@$apelidoLimpo';
    }
    return '';
  }

  bool dadoEstaPrivado(String chave) => dadosPrivados.contains(chave);

  bool dadoAutorizadoPara(String chave, String cpfOutro) {
    final meuCpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
    final outroLimpo = cpfOutro.replaceAll(RegExp(r'\D'), '');
    if (meuCpfLimpo == outroLimpo) return true;
    if (!dadoEstaPrivado(chave)) return true;
    return dadosAutorizadosPorCpf.contains('$outroLimpo:$chave');
  }

  /// Retorna a lista de CPFs que possuem autorização expressa para visualizar este dado privado
  List<String> obterCpfsAutorizadosPara(String chave) {
    final sufixo = ':$chave';
    final cpfs = <String>[];
    for (final entrada in dadosAutorizadosPorCpf) {
      if (entrada.endsWith(sufixo)) {
        final partes = entrada.split(':');
        if (partes.length == 2 && partes[0].isNotEmpty) {
          cpfs.add(partes[0]);
        }
      }
    }
    return cpfs;
  }

  /// Revoga a permissão de visualização de um usuário específico para um dado
  UsuarioNous revogarAutorizacao(String chave, String cpfOutro) {
    final outroLimpo = cpfOutro.replaceAll(RegExp(r'\D'), '');
    final chaveRemover = '$outroLimpo:$chave';
    final novaLista = dadosAutorizadosPorCpf.where((e) => e != chaveRemover).toList();
    return copyWith(dadosAutorizadosPorCpf: novaLista);
  }

  /// Concede permissão de visualização de um usuário específico para um dado
  UsuarioNous concederAutorizacao(String chave, String cpfOutro) {
    final outroLimpo = cpfOutro.replaceAll(RegExp(r'\D'), '');
    final chaveAdicionar = '$outroLimpo:$chave';
    if (dadosAutorizadosPorCpf.contains(chaveAdicionar)) return this;
    final novaLista = List<String>.from(dadosAutorizadosPorCpf)..add(chaveAdicionar);
    return copyWith(dadosAutorizadosPorCpf: novaLista);
  }

  /// Retorna o nome formatado respeitando a privacidade:
  /// Se o nome próprio for privado e quem visualiza não tiver autorização, retorna o apelido ou "Usuário Nous".
  String nomeExibicaoPara({String? cpfVisualizador, bool reveladoParaDono = false}) {
    if (!dadoEstaPrivado('nome')) {
      return nomeExibicao;
    }
    final meuCpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
    final outroLimpo = (cpfVisualizador ?? '').replaceAll(RegExp(r'\D'), '');
    if (outroLimpo.isEmpty || meuCpfLimpo == outroLimpo) {
      return reveladoParaDono ? nomeExibicao : (apelidoExibicao.isNotEmpty ? apelidoExibicao : 'Usuário Nous');
    }
    if (dadoAutorizadoPara('nome', outroLimpo)) {
      return nomeExibicao;
    }
    return apelidoExibicao.isNotEmpty ? apelidoExibicao : 'Usuário Nous';
  }

  bool estaSeguindo(String cpfOuId) {
    final limpo = cpfOuId.replaceAll(RegExp(r'\D'), '');
    return seguindo.any((s) => s.replaceAll(RegExp(r'\D'), '') == limpo);
  }

  UsuarioNous copyWith({
    String? nome,
    String? apelido,
    String? nomeDeUsuario,
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
    List<String>? dadosPrivados,
    List<String>? dadosAutorizadosPorCpf,
    List<String>? seguindo,
    List<String>? seguidores,
  }) {
    return UsuarioNous(
      cpf: cpf,
      nome: nome ?? this.nome,
      apelido: apelido ?? this.apelido,
      nomeDeUsuario: nomeDeUsuario ?? this.nomeDeUsuario,
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
      dadosPrivados: dadosPrivados ?? this.dadosPrivados,
      dadosAutorizadosPorCpf:
          dadosAutorizadosPorCpf ?? this.dadosAutorizadosPorCpf,
      seguindo: seguindo ?? this.seguindo,
      seguidores: seguidores ?? this.seguidores,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cpf': cpf,
      'nome': nome,
      'apelido': apelido,
      'nomeDeUsuario': nomeDeUsuario,
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
      'dadosPrivados': dadosPrivados,
      'dadosAutorizadosPorCpf': dadosAutorizadosPorCpf,
      'seguindo': seguindo,
      'seguidores': seguidores,
    };
  }

  factory UsuarioNous.fromJson(Map<String, dynamic> json) {
    return UsuarioNous(
      cpf: json['cpf'] as String? ?? '',
      nome: json['nome'] as String? ?? '',
      apelido: json['apelido'] as String? ?? '',
      nomeDeUsuario: json['nomeDeUsuario'] as String? ?? '',
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
      dadosPrivados: (json['dadosPrivados'] as List<dynamic>? ??
              const ['cpf', 'emails', 'dataNascimento', 'filiacao'])
          .map((item) => item as String)
          .toList(),
      dadosAutorizadosPorCpf:
          (json['dadosAutorizadosPorCpf'] as List<dynamic>? ?? const [])
              .map((item) => item as String)
              .toList(),
      seguindo: (json['seguindo'] as List<dynamic>? ?? const [])
          .map((item) => item as String)
          .toList(),
      seguidores: (json['seguidores'] as List<dynamic>? ?? const [])
          .map((item) => item as String)
          .toList(),
    );
  }
}