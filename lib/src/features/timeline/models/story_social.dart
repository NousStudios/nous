class CamadaTextoStory {
  final String texto;
  final double x;
  final double y;
  final double escala;
  final String fonte; // 'padrao', 'negrito', 'serif', 'mono'
  final String corTextoHex;
  final String corFundoHex;
  final String alinhamento; // 'center', 'left', 'right'

  const CamadaTextoStory({
    required this.texto,
    this.x = 0.5,
    this.y = 0.5,
    this.escala = 1.0,
    this.fonte = 'padrao',
    this.corTextoHex = 'FFFFFFFF',
    this.corFundoHex = '99000000',
    this.alinhamento = 'center',
  });

  CamadaTextoStory copyWith({
    String? texto,
    double? x,
    double? y,
    double? escala,
    String? fonte,
    String? corTextoHex,
    String? corFundoHex,
    String? alinhamento,
  }) {
    return CamadaTextoStory(
      texto: texto ?? this.texto,
      x: x ?? this.x,
      y: y ?? this.y,
      escala: escala ?? this.escala,
      fonte: fonte ?? this.fonte,
      corTextoHex: corTextoHex ?? this.corTextoHex,
      corFundoHex: corFundoHex ?? this.corFundoHex,
      alinhamento: alinhamento ?? this.alinhamento,
    );
  }

  Map<String, dynamic> toJson() => {
        'texto': texto,
        'x': x,
        'y': y,
        'escala': escala,
        'fonte': fonte,
        'corTextoHex': corTextoHex,
        'corFundoHex': corFundoHex,
        'alinhamento': alinhamento,
      };

  factory CamadaTextoStory.fromJson(Map<String, dynamic> json) {
    return CamadaTextoStory(
      texto: json['texto'] as String? ?? '',
      x: (json['x'] as num?)?.toDouble() ?? 0.5,
      y: (json['y'] as num?)?.toDouble() ?? 0.5,
      escala: (json['escala'] as num?)?.toDouble() ?? 1.0,
      fonte: json['fonte'] as String? ?? 'padrao',
      corTextoHex: json['corTextoHex'] as String? ?? 'FFFFFFFF',
      corFundoHex: json['corFundoHex'] as String? ?? '99000000',
      alinhamento: json['alinhamento'] as String? ?? 'center',
    );
  }
}

class StorySocial {
  final String id;
  final String autorCpf;
  final String autorNome;
  final String autorFoto;
  final String tituloDestaque;
  final String caminhoMidia;
  final String tipoMidia; // 'imagem', 'video', 'texto'
  final String texto;
  final String corFundoHex;
  final bool ehDestaquePermanente;
  final DateTime criadoEm;
  final DateTime? expiraEm;
  final List<String> visualizadoPorCpfs;
  final bool excluido;
  final bool arquivado;
  final DateTime? atualizadoEm;
  final String perguntaEnquete;
  final List<String> opcoesEnquete;
  final Map<String, int> votosEnquete; // cpf -> indice da opcao
  final String lojaIdTag;
  final String itemLojaIdTag;
  final String itemLojaNomeTag;
  final String itemLojaPrecoTag;
  final List<CamadaTextoStory> camadasTexto;
  final String storyOriginalId;
  final String autorOriginalNome;

  const StorySocial({
    required this.id,
    required this.autorCpf,
    this.autorNome = '',
    this.autorFoto = '',
    this.tituloDestaque = '',
    this.caminhoMidia = '',
    this.tipoMidia = 'imagem',
    this.texto = '',
    this.corFundoHex = '',
    this.ehDestaquePermanente = false,
    required this.criadoEm,
    this.expiraEm,
    this.visualizadoPorCpfs = const [],
    this.excluido = false,
    this.arquivado = false,
    this.atualizadoEm,
    this.perguntaEnquete = '',
    this.opcoesEnquete = const [],
    this.votosEnquete = const {},
    this.lojaIdTag = '',
    this.itemLojaIdTag = '',
    this.itemLojaNomeTag = '',
    this.itemLojaPrecoTag = '',
    this.camadasTexto = const [],
    this.storyOriginalId = '',
    this.autorOriginalNome = '',
  });

  DateTime get atualizadoEfetivo => atualizadoEm ?? criadoEm;

  bool get estaAtivo {
    if (excluido || arquivado) return false;
    if (ehDestaquePermanente || expiraEm == null) return true;
    return DateTime.now().isBefore(expiraEm!);
  }

  StorySocial copyWith({
    String? id,
    String? autorCpf,
    String? autorNome,
    String? autorFoto,
    String? tituloDestaque,
    String? caminhoMidia,
    String? tipoMidia,
    String? texto,
    String? corFundoHex,
    bool? ehDestaquePermanente,
    DateTime? criadoEm,
    DateTime? expiraEm,
    List<String>? visualizadoPorCpfs,
    bool? excluido,
    bool? arquivado,
    DateTime? atualizadoEm,
    String? perguntaEnquete,
    List<String>? opcoesEnquete,
    Map<String, int>? votosEnquete,
    String? lojaIdTag,
    String? itemLojaIdTag,
    String? itemLojaNomeTag,
    String? itemLojaPrecoTag,
    List<CamadaTextoStory>? camadasTexto,
    String? storyOriginalId,
    String? autorOriginalNome,
  }) {
    return StorySocial(
      id: id ?? this.id,
      autorCpf: autorCpf ?? this.autorCpf,
      autorNome: autorNome ?? this.autorNome,
      autorFoto: autorFoto ?? this.autorFoto,
      tituloDestaque: tituloDestaque ?? this.tituloDestaque,
      caminhoMidia: caminhoMidia ?? this.caminhoMidia,
      tipoMidia: tipoMidia ?? this.tipoMidia,
      texto: texto ?? this.texto,
      corFundoHex: corFundoHex ?? this.corFundoHex,
      ehDestaquePermanente: ehDestaquePermanente ?? this.ehDestaquePermanente,
      criadoEm: criadoEm ?? this.criadoEm,
      expiraEm: expiraEm ?? this.expiraEm,
      visualizadoPorCpfs: visualizadoPorCpfs ?? this.visualizadoPorCpfs,
      excluido: excluido ?? this.excluido,
      arquivado: arquivado ?? this.arquivado,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      perguntaEnquete: perguntaEnquete ?? this.perguntaEnquete,
      opcoesEnquete: opcoesEnquete ?? this.opcoesEnquete,
      votosEnquete: votosEnquete ?? this.votosEnquete,
      lojaIdTag: lojaIdTag ?? this.lojaIdTag,
      itemLojaIdTag: itemLojaIdTag ?? this.itemLojaIdTag,
      itemLojaNomeTag: itemLojaNomeTag ?? this.itemLojaNomeTag,
      itemLojaPrecoTag: itemLojaPrecoTag ?? this.itemLojaPrecoTag,
      camadasTexto: camadasTexto ?? this.camadasTexto,
      storyOriginalId: storyOriginalId ?? this.storyOriginalId,
      autorOriginalNome: autorOriginalNome ?? this.autorOriginalNome,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'autorCpf': autorCpf,
        'autorNome': autorNome,
        'autorFoto': autorFoto,
        'tituloDestaque': tituloDestaque,
        'caminhoMidia': caminhoMidia,
        'tipoMidia': tipoMidia,
        'texto': texto,
        'corFundoHex': corFundoHex,
        'ehDestaquePermanente': ehDestaquePermanente,
        'criadoEm': criadoEm.toIso8601String(),
        'expiraEm': expiraEm?.toIso8601String(),
        'visualizadoPorCpfs': visualizadoPorCpfs,
        'excluido': excluido,
        'arquivado': arquivado,
        'atualizadoEm': (atualizadoEm ?? criadoEm).toIso8601String(),
        'perguntaEnquete': perguntaEnquete,
        'opcoesEnquete': opcoesEnquete,
        'votosEnquete': votosEnquete,
        'lojaIdTag': lojaIdTag,
        'itemLojaIdTag': itemLojaIdTag,
        'itemLojaNomeTag': itemLojaNomeTag,
        'itemLojaPrecoTag': itemLojaPrecoTag,
        'camadasTexto': camadasTexto.map((c) => c.toJson()).toList(),
        'storyOriginalId': storyOriginalId,
        'autorOriginalNome': autorOriginalNome,
      };

  factory StorySocial.fromJson(Map<String, dynamic> json) {
    final votosRaw = json['votosEnquete'];
    final votosMap = <String, int>{};
    if (votosRaw is Map) {
      votosRaw.forEach((k, v) {
        if (v is num) votosMap[k.toString()] = v.toInt();
      });
    }
    return StorySocial(
      id: json['id'] as String? ?? '',
      autorCpf: json['autorCpf'] as String? ?? '',
      autorNome: json['autorNome'] as String? ?? '',
      autorFoto: json['autorFoto'] as String? ?? '',
      tituloDestaque: json['tituloDestaque'] as String? ?? '',
      caminhoMidia: json['caminhoMidia'] as String? ?? '',
      tipoMidia: json['tipoMidia'] as String? ?? 'imagem',
      texto: json['texto'] as String? ?? '',
      corFundoHex: json['corFundoHex'] as String? ?? '',
      ehDestaquePermanente: json['ehDestaquePermanente'] == true ||
          json['ehDestaquePermanente'] == 1,
      criadoEm:
          DateTime.tryParse(json['criadoEm'] as String? ?? '') ?? DateTime.now(),
      expiraEm: json['expiraEm'] != null
          ? DateTime.tryParse(json['expiraEm'] as String)
          : null,
      visualizadoPorCpfs:
          (json['visualizadoPorCpfs'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
      excluido: json['excluido'] == true || json['excluido'] == 1,
      arquivado: json['arquivado'] == true || json['arquivado'] == 1,
      atualizadoEm: json['atualizadoEm'] != null
          ? DateTime.tryParse(json['atualizadoEm'] as String)
          : null,
      perguntaEnquete: json['perguntaEnquete'] as String? ?? '',
      opcoesEnquete: (json['opcoesEnquete'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      votosEnquete: votosMap,
      lojaIdTag: json['lojaIdTag'] as String? ?? '',
      itemLojaIdTag: json['itemLojaIdTag'] as String? ?? '',
      itemLojaNomeTag: json['itemLojaNomeTag'] as String? ?? '',
      itemLojaPrecoTag: json['itemLojaPrecoTag'] as String? ?? '',
      camadasTexto: (json['camadasTexto'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((m) => CamadaTextoStory.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      storyOriginalId: json['storyOriginalId'] as String? ?? '',
      autorOriginalNome: json['autorOriginalNome'] as String? ?? '',
    );
  }
}

enum OrigemFeedExterno {
  rssAtom,
  instagramPonte,
  youtubePonte,
  webhookJson,
  custom,
}

class FeedPersonalizado {
  final String id;
  final String donoCpf;
  final String titulo;
  final String iconeNome;
  final OrigemFeedExterno origem;
  final String urlOuIdentificador;
  final bool ativo;
  final DateTime criadoEm;

  const FeedPersonalizado({
    required this.id,
    required this.donoCpf,
    required this.titulo,
    this.iconeNome = 'rss',
    this.origem = OrigemFeedExterno.rssAtom,
    this.urlOuIdentificador = '',
    this.ativo = true,
    required this.criadoEm,
  });

  FeedPersonalizado copyWith({
    String? id,
    String? donoCpf,
    String? titulo,
    String? iconeNome,
    OrigemFeedExterno? origem,
    String? urlOuIdentificador,
    bool? ativo,
    DateTime? criadoEm,
  }) {
    return FeedPersonalizado(
      id: id ?? this.id,
      donoCpf: donoCpf ?? this.donoCpf,
      titulo: titulo ?? this.titulo,
      iconeNome: iconeNome ?? this.iconeNome,
      origem: origem ?? this.origem,
      urlOuIdentificador: urlOuIdentificador ?? this.urlOuIdentificador,
      ativo: ativo ?? this.ativo,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'donoCpf': donoCpf,
        'titulo': titulo,
        'iconeNome': iconeNome,
        'origem': origem.name,
        'urlOuIdentificador': urlOuIdentificador,
        'ativo': ativo,
        'criadoEm': criadoEm.toIso8601String(),
      };

  factory FeedPersonalizado.fromJson(Map<String, dynamic> json) {
    return FeedPersonalizado(
      id: json['id'] as String? ?? '',
      donoCpf: json['donoCpf'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      iconeNome: json['iconeNome'] as String? ?? 'rss',
      origem: OrigemFeedExterno.values.firstWhere(
        (e) => e.name == json['origem'],
        orElse: () => OrigemFeedExterno.rssAtom,
      ),
      urlOuIdentificador: json['urlOuIdentificador'] as String? ?? '',
      ativo: json['ativo'] as bool? ?? true,
      criadoEm:
          DateTime.tryParse(json['criadoEm'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
