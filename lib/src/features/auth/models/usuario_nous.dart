class UsuarioNous {
  final String cpf;
  final String nome;
  final String apelido;
  final String nomeDeUsuario;
  final String dataNascimento;
  final List<String> emails;
  final List<String> emailsVerificados;
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
  final List<String> contasBloqueadas;
  final List<String> contasSilenciadas;
  final String chavePublica;
  final String chaveTrocaPublica;
  final String quemPodeEnviarMensagens;
  final String criadoEm;
  final String validadoPorCpf;
  final String validadoPorNome;
  final String validadoEm;
  final bool verificado;
  final List<Map<String, String>> validacoes;
  final List<String> links;
  final Map<String, String> coresPerfil;
  final List<String> timelinesVisiveis;
  final bool modoFotosGaleria;
  final String termosAceitosVersao;
  final String termosAceitosEm;
  final String notaPensamento;
  final String notaPensamentoCriadaEm;
  final String notaPensamentoMusica;

  /// Chaves ocultas por padrão ao criar/carregar uma Conta Nous (tudo privado exceto o nome).
  static const List<String> dadosPrivadosPadrao = [
    'apelido',
    'cpf',
    'dataNascimento',
    'nomeMae',
    'nomePai',
    'filiacao',
    'localNascimento',
    'tipoSanguineo',
    'estadoCivil',
    'telefone',
    'endereco',
    'biografia',
    'emails',
    'pagamentosTrabalhador',
    'escalaTrabalho',
    'registroPonto',
    'contratoTrabalho',
  ];

  const UsuarioNous({
    required this.cpf,
    required this.nome,
    this.apelido = '',
    this.nomeDeUsuario = '',
    required this.dataNascimento,
    this.emails = const [],
    this.emailsVerificados = const [],
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
    this.dadosPrivados = dadosPrivadosPadrao,
    this.dadosAutorizadosPorCpf = const [],
    this.seguindo = const [],
    this.seguidores = const [],
    this.contasBloqueadas = const [],
    this.contasSilenciadas = const [],
    this.chavePublica = '',
    this.chaveTrocaPublica = '',
    this.quemPodeEnviarMensagens = 'todos',
    this.criadoEm = '',
    this.validadoPorCpf = '',
    this.validadoPorNome = '',
    this.validadoEm = '',
    this.verificado = false,
    this.validacoes = const [],
    this.links = const [],
    this.coresPerfil = const {},
    this.timelinesVisiveis = const [],
    this.modoFotosGaleria = false,
    this.termosAceitosVersao = '',
    this.termosAceitosEm = '',
    this.notaPensamento = '',
    this.notaPensamentoCriadaEm = '',
    this.notaPensamentoMusica = '',
  });

  bool get temNotaPensamentoAtiva {
    if (notaPensamento.trim().isEmpty) return false;
    final dt = DateTime.tryParse(notaPensamentoCriadaEm);
    if (dt == null) return false;
    return DateTime.now().difference(dt).inHours < 24;
  }

  String get corStoryHex {
    final raw = coresPerfil['story']?.trim() ?? '';
    return raw.isNotEmpty ? raw : '#2E7D32';
  }

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
  /// Hierarquia estrita: Nome Completo (se permitido) -> Apelido -> @Usuário Nous.
  String nomeExibicaoPara({String? cpfVisualizador, bool reveladoParaDono = false}) {
    final fallback = apelidoExibicao.isNotEmpty
        ? apelidoExibicao
        : (usernameExibicao.isNotEmpty ? usernameExibicao : '@Usuário Nous');

    if (!dadoEstaPrivado('nome')) {
      return nomeExibicao.isNotEmpty ? nomeExibicao : fallback;
    }
    final meuCpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
    final outroLimpo = (cpfVisualizador ?? '').replaceAll(RegExp(r'\D'), '');
    if (outroLimpo.isEmpty || meuCpfLimpo == outroLimpo) {
      return reveladoParaDono
          ? (nomeExibicao.isNotEmpty ? nomeExibicao : fallback)
          : fallback;
    }
    if (dadoAutorizadoPara('nome', outroLimpo)) {
      return nomeExibicao.isNotEmpty ? nomeExibicao : fallback;
    }
    return fallback;
  }

  String fotoExibicaoPara(String cpfVisualizador) {
    if (dadoAutorizadoPara('foto', cpfVisualizador)) return fotoExibicao;
    return '';
  }

  String biografiaPara(String cpfVisualizador) {
    if (dadoAutorizadoPara('biografia', cpfVisualizador)) return biografia;
    return '';
  }

  String get criadoEmFormatado {
    final dt = criadoEm.trim().isEmpty
        ? DateTime.now()
        : DateTime.tryParse(criadoEm);
    if (dt == null) return criadoEm;
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }

  List<Map<String, String>> get validacoesOrdenadas {
    final lista = <Map<String, String>>[
      for (final v in validacoes) Map<String, String>.from(v),
    ];
    if (lista.isEmpty && validadoPorCpf.trim().isNotEmpty) {
      lista.add({
        'cpf': validadoPorCpf,
        'nome': validadoPorNome.isNotEmpty ? validadoPorNome : 'Usuário Nous',
        'dataHora': validadoEm,
        'assinatura': '',
      });
    }
    lista.sort((a, b) {
      final da = DateTime.tryParse(a['dataHora'] ?? '') ?? DateTime(2099);
      final db = DateTime.tryParse(b['dataHora'] ?? '') ?? DateTime(2099);
      return da.compareTo(db);
    });
    return lista;
  }

  int get totalValidacoes => validacoesOrdenadas.length;
  bool get possuiValidacao => verificado || totalValidacoes > 0;

  bool jaValidadoPor(String cpfValidador) {
    final norm = cpfValidador.replaceAll(RegExp(r'\D'), '');
    if (norm.isEmpty) return false;
    return validacoesOrdenadas.any(
      (v) => (v['cpf'] ?? '').replaceAll(RegExp(r'\D'), '') == norm,
    );
  }

  String get validadoEmFormatado {
    if (validadoEm.trim().isEmpty) return '';
    final dt = DateTime.tryParse(validadoEm);
    if (dt == null) return validadoEm;
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }

  bool estaSeguindo(String cpfOuId) {
    final limpo = cpfOuId.replaceAll(RegExp(r'\D'), '');
    return seguindo.any((s) => s.replaceAll(RegExp(r'\D'), '') == limpo);
  }

  bool emailEstaVerificado(String email) {
    final norm = email.trim().toLowerCase();
    if (norm.isEmpty) return false;
    return emailsVerificados.any((e) => e.trim().toLowerCase() == norm);
  }

  bool estaBloqueado(String cpfOuId) {
    final limpo = cpfOuId.replaceAll(RegExp(r'\D'), '');
    return contasBloqueadas.any((s) => s.replaceAll(RegExp(r'\D'), '') == limpo);
  }

  bool estaSilenciado(String cpfOuId) {
    final limpo = cpfOuId.replaceAll(RegExp(r'\D'), '');
    return contasSilenciadas.any((s) => s.replaceAll(RegExp(r'\D'), '') == limpo);
  }

  UsuarioNous copyWith({
    String? nome,
    String? apelido,
    String? nomeDeUsuario,
    String? dataNascimento,
    List<String>? emails,
    List<String>? emailsVerificados,
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
    List<String>? contasBloqueadas,
    List<String>? contasSilenciadas,
    String? chavePublica,
    String? chaveTrocaPublica,
    String? quemPodeEnviarMensagens,
    String? criadoEm,
    String? validadoPorCpf,
    String? validadoPorNome,
    String? validadoEm,
    bool? verificado,
    List<Map<String, String>>? validacoes,
    List<String>? links,
    Map<String, String>? coresPerfil,
    List<String>? timelinesVisiveis,
    bool? modoFotosGaleria,
    String? termosAceitosVersao,
    String? termosAceitosEm,
    String? notaPensamento,
    String? notaPensamentoCriadaEm,
    String? notaPensamentoMusica,
  }) {
    return UsuarioNous(
      cpf: cpf,
      nome: nome ?? this.nome,
      apelido: apelido ?? this.apelido,
      nomeDeUsuario: nomeDeUsuario ?? this.nomeDeUsuario,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      emails: emails ?? this.emails,
      emailsVerificados: emailsVerificados ?? this.emailsVerificados,
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
      contasBloqueadas: contasBloqueadas ?? this.contasBloqueadas,
      contasSilenciadas: contasSilenciadas ?? this.contasSilenciadas,
      chavePublica: chavePublica ?? this.chavePublica,
      chaveTrocaPublica: chaveTrocaPublica ?? this.chaveTrocaPublica,
      quemPodeEnviarMensagens:
          quemPodeEnviarMensagens ?? this.quemPodeEnviarMensagens,
      criadoEm: criadoEm ?? this.criadoEm,
      validadoPorCpf: validadoPorCpf ?? this.validadoPorCpf,
      validadoPorNome: validadoPorNome ?? this.validadoPorNome,
      validadoEm: validadoEm ?? this.validadoEm,
      verificado: verificado ?? this.verificado,
      validacoes: validacoes ?? this.validacoes,
      links: links ?? this.links,
      coresPerfil: coresPerfil ?? this.coresPerfil,
      timelinesVisiveis: timelinesVisiveis ?? this.timelinesVisiveis,
      modoFotosGaleria: modoFotosGaleria ?? this.modoFotosGaleria,
      termosAceitosVersao: termosAceitosVersao ?? this.termosAceitosVersao,
      termosAceitosEm: termosAceitosEm ?? this.termosAceitosEm,
      notaPensamento: notaPensamento ?? this.notaPensamento,
      notaPensamentoCriadaEm:
          notaPensamentoCriadaEm ?? this.notaPensamentoCriadaEm,
      notaPensamentoMusica: notaPensamentoMusica ?? this.notaPensamentoMusica,
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
      'emailsVerificados': emailsVerificados,
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
      'contasBloqueadas': contasBloqueadas,
      'contasSilenciadas': contasSilenciadas,
      'chavePublica': chavePublica,
      'chaveTrocaPublica': chaveTrocaPublica,
      'quemPodeEnviarMensagens': quemPodeEnviarMensagens,
      'criadoEm': criadoEm,
      'validadoPorCpf': validadoPorCpf,
      'validadoPorNome': validadoPorNome,
      'validadoEm': validadoEm,
      'verificado': verificado,
      'validacoes': validacoes,
      'links': links,
      'coresPerfil': coresPerfil,
      'timelinesVisiveis': timelinesVisiveis,
      'modoFotosGaleria': modoFotosGaleria,
      'termosAceitosVersao': termosAceitosVersao,
      'termosAceitosEm': termosAceitosEm,
      'notaPensamento': notaPensamento,
      'notaPensamentoCriadaEm': notaPensamentoCriadaEm,
      'notaPensamentoMusica': notaPensamentoMusica,
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
      emailsVerificados:
          (json['emailsVerificados'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
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
              dadosPrivadosPadrao)
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
      contasBloqueadas:
          (json['contasBloqueadas'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(),
      contasSilenciadas:
          (json['contasSilenciadas'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(),
      chavePublica: json['chavePublica'] as String? ?? '',
      chaveTrocaPublica: json['chaveTrocaPublica'] as String? ??
          json['chave_troca_publica'] as String? ??
          '',
      quemPodeEnviarMensagens:
          json['quemPodeEnviarMensagens'] as String? ?? 'todos',
      criadoEm: json['criadoEm'] as String? ?? json['criado_em'] as String? ?? '',
      validadoPorCpf: json['validadoPorCpf'] as String? ??
          json['validado_por_cpf'] as String? ??
          '',
      validadoPorNome: json['validadoPorNome'] as String? ??
          json['validado_por_nome'] as String? ??
          '',
      validadoEm: json['validadoEm'] as String? ??
          json['validado_em'] as String? ??
          '',
      verificado: json['verificado'] == true || json['verificado'] == 1,
      validacoes: (json['validacoes'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (m) => m.map(
              (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
            ),
          )
          .toList(),
      links: (json['links'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList(),
      coresPerfil: (json['coresPerfil'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
          ) ??
          const {},
      timelinesVisiveis: (json['timelinesVisiveis'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList(),
      modoFotosGaleria:
          json['modoFotosGaleria'] == true || json['modoFotosGaleria'] == 1,
      termosAceitosVersao: json['termosAceitosVersao'] as String? ?? '',
      termosAceitosEm: json['termosAceitosEm'] as String? ?? '',
      notaPensamento: json['notaPensamento'] as String? ?? '',
      notaPensamentoCriadaEm: json['notaPensamentoCriadaEm'] as String? ?? '',
      notaPensamentoMusica: json['notaPensamentoMusica'] as String? ?? '',
    );
  }

  /// Mescla esta ficha com outra recebida da rede sem perder validações,
  /// chaves criptográficas ou personalizações do perfil social.
  /// Quando [priorizarOutro] é true (ex.: evento em tempo real ou POST de
  /// atualização explícita), edições feitas em [outro] prevalecem nos campos
  /// mutáveis (bio, links, cores, privacidade, seguindo/seguidores).
  UsuarioNous mesclarCom(UsuarioNous outro, {bool priorizarOutro = false}) {
    String escolher(String localVal, String outroVal, {bool permitirVazioNoOutro = false}) {
      if (priorizarOutro) {
        if (permitirVazioNoOutro) return outroVal;
        return outroVal.isNotEmpty ? outroVal : localVal;
      }
      return localVal.isNotEmpty ? localVal : outroVal;
    }

    // União deduplicada de validações por CPF do validador (ou cpf_dataHora).
    final mapaVal = <String, Map<String, String>>{};
    for (final v in [...validacoes, ...outro.validacoes]) {
      final cpfVal = (v['cpf'] ?? '').replaceAll(RegExp(r'\D'), '');
      final chave = cpfVal.isNotEmpty ? cpfVal : '${v['cpf'] ?? ''}_${v['dataHora'] ?? ''}';
      final anterior = mapaVal[chave];
      if (anterior == null ||
          ((anterior['assinatura'] ?? '').isEmpty &&
              (v['assinatura'] ?? '').isNotEmpty)) {
        mapaVal[chave] = Map<String, String>.from(v);
      }
    }
    final validacoesMescladas = mapaVal.values.toList();
    final verificadoFinal =
        verificado || outro.verificado || validacoesMescladas.isNotEmpty;

    final nomeFinal = priorizarOutro
        ? ((outro.nome.isNotEmpty && outro.nome.toLowerCase() != 'blackview')
            ? outro.nome
            : nome)
        : ((nome.isNotEmpty && nome.toLowerCase() != 'blackview')
            ? nome
            : outro.nome);

    final validadoPorCpfFinal = validadoPorCpf.isNotEmpty
        ? validadoPorCpf
        : (outro.validadoPorCpf.isNotEmpty
            ? outro.validadoPorCpf
            : (validacoesMescladas.isNotEmpty
                ? (validacoesMescladas.first['cpf'] ?? '')
                : ''));
    final validadoPorNomeFinal = validadoPorNome.isNotEmpty
        ? validadoPorNome
        : (outro.validadoPorNome.isNotEmpty
            ? outro.validadoPorNome
            : (validacoesMescladas.isNotEmpty
                ? (validacoesMescladas.first['nome'] ?? '')
                : ''));
    final validadoEmFinal = validadoEm.isNotEmpty
        ? validadoEm
        : (outro.validadoEm.isNotEmpty
            ? outro.validadoEm
            : (validacoesMescladas.isNotEmpty
                ? (validacoesMescladas.first['dataHora'] ?? '')
                : ''));

    final dtNotaLocal = DateTime.tryParse(notaPensamentoCriadaEm);
    final dtNotaOutro = DateTime.tryParse(outro.notaPensamentoCriadaEm);
    final usarNotaOutro = priorizarOutro
        ? (outro.notaPensamentoCriadaEm.isNotEmpty ||
            (dtNotaLocal == null && dtNotaOutro != null))
        : (dtNotaOutro != null &&
            (dtNotaLocal == null || dtNotaOutro.isAfter(dtNotaLocal)));

    return UsuarioNous(
      cpf: cpf.isNotEmpty ? cpf : outro.cpf,
      nome: nomeFinal,
      apelido: escolher(apelido, outro.apelido, permitirVazioNoOutro: true),
      nomeDeUsuario: escolher(nomeDeUsuario, outro.nomeDeUsuario, permitirVazioNoOutro: true),
      dataNascimento: escolher(dataNascimento, outro.dataNascimento),
      emails: priorizarOutro
          ? (outro.emails.isNotEmpty ? outro.emails : emails)
          : {...emails, ...outro.emails}.toList(),
      emailsVerificados:
          {...emailsVerificados, ...outro.emailsVerificados}.toList(),
      foto: escolher(foto, outro.foto),
      nomePai: escolher(nomePai, outro.nomePai),
      nomeMae: escolher(nomeMae, outro.nomeMae),
      localNascimento: escolher(localNascimento, outro.localNascimento),
      tipoSanguineo: escolher(tipoSanguineo, outro.tipoSanguineo),
      estadoCivil: escolher(estadoCivil, outro.estadoCivil),
      biografia: escolher(biografia, outro.biografia, permitirVazioNoOutro: true),
      nomePublico: escolher(nomePublico, outro.nomePublico, permitirVazioNoOutro: true),
      apelidoPublico: escolher(apelidoPublico, outro.apelidoPublico, permitirVazioNoOutro: true),
      fotoPublica: escolher(fotoPublica, outro.fotoPublica, permitirVazioNoOutro: true),
      dadosPrivados: priorizarOutro ? outro.dadosPrivados : dadosPrivados,
      dadosAutorizadosPorCpf: priorizarOutro
          ? outro.dadosAutorizadosPorCpf
          : {...dadosAutorizadosPorCpf, ...outro.dadosAutorizadosPorCpf}.toList(),
      seguindo: priorizarOutro
          ? outro.seguindo
          : {...seguindo, ...outro.seguindo}.toList(),
      seguidores: priorizarOutro
          ? outro.seguidores
          : {...seguidores, ...outro.seguidores}.toList(),
      contasBloqueadas: priorizarOutro
          ? outro.contasBloqueadas
          : {...contasBloqueadas, ...outro.contasBloqueadas}.toList(),
      contasSilenciadas: priorizarOutro
          ? outro.contasSilenciadas
          : {...contasSilenciadas, ...outro.contasSilenciadas}.toList(),
      chavePublica: escolher(chavePublica, outro.chavePublica),
      chaveTrocaPublica: escolher(chaveTrocaPublica, outro.chaveTrocaPublica),
      quemPodeEnviarMensagens: escolher(
        quemPodeEnviarMensagens,
        outro.quemPodeEnviarMensagens,
      ),
      criadoEm: criadoEm.isNotEmpty ? criadoEm : outro.criadoEm,
      validadoPorCpf: validadoPorCpfFinal,
      validadoPorNome: validadoPorNomeFinal,
      validadoEm: validadoEmFinal,
      verificado: verificadoFinal,
      validacoes: validacoesMescladas,
      links: priorizarOutro
          ? outro.links
          : {...links, ...outro.links}.toList(),
      coresPerfil: priorizarOutro
          ? outro.coresPerfil
          : {...outro.coresPerfil, ...coresPerfil},
      timelinesVisiveis: priorizarOutro
          ? (outro.timelinesVisiveis.isNotEmpty
              ? outro.timelinesVisiveis
              : timelinesVisiveis)
          : (timelinesVisiveis.isNotEmpty
              ? timelinesVisiveis
              : outro.timelinesVisiveis),
      modoFotosGaleria: priorizarOutro
          ? outro.modoFotosGaleria
          : modoFotosGaleria,
      termosAceitosVersao: escolher(termosAceitosVersao, outro.termosAceitosVersao),
      termosAceitosEm: escolher(termosAceitosEm, outro.termosAceitosEm),
      notaPensamento: usarNotaOutro ? outro.notaPensamento : notaPensamento,
      notaPensamentoCriadaEm:
          usarNotaOutro ? outro.notaPensamentoCriadaEm : notaPensamentoCriadaEm,
      notaPensamentoMusica:
          usarNotaOutro ? outro.notaPensamentoMusica : notaPensamentoMusica,
    );
  }
}