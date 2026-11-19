enum TipoFeedSocial {
  fotos,
  videos,
  documentos,
  musicas,
  escritos,
  republicacoes,
  interacoes,
  salvos,
  likes,
  deslikes,
  denuncias,
}

enum PadraoExibicaoMidia {
  original,
  quadrado1x1,
  retrato4x5,
  paisagem16x9,
  vertical9x16,
  mosaico,
  personalizado,
}

class MidiaPublicacao {
  final String caminhoRelativo;
  final String nomeArquivo;
  final String mimeTipo;
  final int tamanhoBytes;
  final int largura;
  final int altura;
  final int duracaoSegundos;
  final double alinhamentoX;
  final double alinhamentoY;
  final double escalaZoom;

  const MidiaPublicacao({
    required this.caminhoRelativo,
    this.nomeArquivo = '',
    this.mimeTipo = '',
    this.tamanhoBytes = 0,
    this.largura = 0,
    this.altura = 0,
    this.duracaoSegundos = 0,
    this.alinhamentoX = 0.0,
    this.alinhamentoY = 0.0,
    this.escalaZoom = 1.0,
  });

  MidiaPublicacao copyWith({
    String? caminhoRelativo,
    String? nomeArquivo,
    String? mimeTipo,
    int? tamanhoBytes,
    int? largura,
    int? altura,
    int? duracaoSegundos,
    double? alinhamentoX,
    double? alinhamentoY,
    double? escalaZoom,
  }) {
    return MidiaPublicacao(
      caminhoRelativo: caminhoRelativo ?? this.caminhoRelativo,
      nomeArquivo: nomeArquivo ?? this.nomeArquivo,
      mimeTipo: mimeTipo ?? this.mimeTipo,
      tamanhoBytes: tamanhoBytes ?? this.tamanhoBytes,
      largura: largura ?? this.largura,
      altura: altura ?? this.altura,
      duracaoSegundos: duracaoSegundos ?? this.duracaoSegundos,
      alinhamentoX: alinhamentoX ?? this.alinhamentoX,
      alinhamentoY: alinhamentoY ?? this.alinhamentoY,
      escalaZoom: escalaZoom ?? this.escalaZoom,
    );
  }

  Map<String, dynamic> toJson() => {
        'caminhoRelativo': caminhoRelativo,
        'nomeArquivo': nomeArquivo,
        'mimeTipo': mimeTipo,
        'tamanhoBytes': tamanhoBytes,
        'largura': largura,
        'altura': altura,
        'duracaoSegundos': duracaoSegundos,
        'alinhamentoX': alinhamentoX,
        'alinhamentoY': alinhamentoY,
        'escalaZoom': escalaZoom,
      };

  factory MidiaPublicacao.fromJson(Map<String, dynamic> json) {
    return MidiaPublicacao(
      caminhoRelativo: json['caminhoRelativo'] as String? ?? '',
      nomeArquivo: json['nomeArquivo'] as String? ?? '',
      mimeTipo: json['mimeTipo'] as String? ?? '',
      tamanhoBytes: (json['tamanhoBytes'] as num?)?.toInt() ?? 0,
      largura: (json['largura'] as num?)?.toInt() ?? 0,
      altura: (json['altura'] as num?)?.toInt() ?? 0,
      duracaoSegundos: (json['duracaoSegundos'] as num?)?.toInt() ?? 0,
      alinhamentoX: (json['alinhamentoX'] as num?)?.toDouble() ?? 0.0,
      alinhamentoY: (json['alinhamentoY'] as num?)?.toDouble() ?? 0.0,
      escalaZoom: (json['escalaZoom'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class PublicacaoSocial {
  final String id;
  final String autorCpf;
  final String autorNome;
  final String autorFoto;
  final List<String> coautoresCpfs;
  final TipoFeedSocial tipo;
  final String texto;
  final List<MidiaPublicacao> midias;
  final PadraoExibicaoMidia padraoExibicao;
  final double? proporcaoCustom;
  final int colunasMosaico;
  final bool permitirDownload;
  final String publicacaoOriginalId;
  final double alinhamentoX;
  final double alinhamentoY;
  final double escalaZoom;
  final List<String> tags;
  final String lojaIdTag;
  final String itemLojaIdTag;
  final String itemLojaNomeTag;
  final String itemLojaPrecoTag;
  final DateTime criadaEm;
  final DateTime atualizadaEm;
  final bool excluida;
  final bool arquivada;
  final bool fixada;
  final int ordemManual;
  final int visualizacoes;
  final Map<String, int> visualizacoesPorOrigem;
  final int tempoMedioVisualizacaoSegundos;

  const PublicacaoSocial({
    required this.id,
    required this.autorCpf,
    this.autorNome = '',
    this.autorFoto = '',
    this.coautoresCpfs = const [],
    required this.tipo,
    this.texto = '',
    this.midias = const [],
    this.padraoExibicao = PadraoExibicaoMidia.original,
    this.proporcaoCustom,
    this.colunasMosaico = 3,
    this.permitirDownload = true,
    this.publicacaoOriginalId = '',
    this.alinhamentoX = 0.0,
    this.alinhamentoY = 0.0,
    this.escalaZoom = 1.0,
    this.tags = const [],
    this.lojaIdTag = '',
    this.itemLojaIdTag = '',
    this.itemLojaNomeTag = '',
    this.itemLojaPrecoTag = '',
    required this.criadaEm,
    required this.atualizadaEm,
    this.excluida = false,
    this.arquivada = false,
    this.fixada = false,
    this.ordemManual = 0,
    this.visualizacoes = 0,
    this.visualizacoesPorOrigem = const {},
    this.tempoMedioVisualizacaoSegundos = 0,
  });

  /// Extrai #tags normalizadas (minúsculas, sem '#') de um texto.
  static List<String> extrairTags(String texto) {
    final regex = RegExp(r'#([\p{L}\p{N}_]+)', unicode: true);
    return regex
        .allMatches(texto)
        .map((m) => (m.group(1) ?? '').toLowerCase())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
  }

  /// Extrai @menções normalizadas (minúsculas, sem '@') de um texto.
  static List<String> extrairMencoes(String texto) {
    final regex = RegExp(r'@([a-zA-Z0-9._]+)');
    return regex
        .allMatches(texto)
        .map((m) => (m.group(1) ?? '').toLowerCase())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
  }

  double? get aspectRatioEfetivo {
    switch (padraoExibicao) {
      case PadraoExibicaoMidia.quadrado1x1:
        return 1.0;
      case PadraoExibicaoMidia.retrato4x5:
        return 4 / 5;
      case PadraoExibicaoMidia.paisagem16x9:
        return 16 / 9;
      case PadraoExibicaoMidia.vertical9x16:
        return 9 / 16;
      case PadraoExibicaoMidia.personalizado:
        return (proporcaoCustom != null && proporcaoCustom! > 0.1)
            ? proporcaoCustom
            : null;
      case PadraoExibicaoMidia.original:
      case PadraoExibicaoMidia.mosaico:
        return null;
    }
  }

  PublicacaoSocial copyWith({
    String? id,
    String? autorCpf,
    String? autorNome,
    String? autorFoto,
    List<String>? coautoresCpfs,
    TipoFeedSocial? tipo,
    String? texto,
    List<MidiaPublicacao>? midias,
    PadraoExibicaoMidia? padraoExibicao,
    double? proporcaoCustom,
    int? colunasMosaico,
    bool? permitirDownload,
    String? publicacaoOriginalId,
    double? alinhamentoX,
    double? alinhamentoY,
    double? escalaZoom,
    List<String>? tags,
    String? lojaIdTag,
    String? itemLojaIdTag,
    String? itemLojaNomeTag,
    String? itemLojaPrecoTag,
    DateTime? criadaEm,
    DateTime? atualizadaEm,
    bool? excluida,
    bool? arquivada,
    bool? fixada,
    int? ordemManual,
    int? visualizacoes,
    Map<String, int>? visualizacoesPorOrigem,
    int? tempoMedioVisualizacaoSegundos,
  }) {
    return PublicacaoSocial(
      id: id ?? this.id,
      autorCpf: autorCpf ?? this.autorCpf,
      autorNome: autorNome ?? this.autorNome,
      autorFoto: autorFoto ?? this.autorFoto,
      coautoresCpfs: coautoresCpfs ?? this.coautoresCpfs,
      tipo: tipo ?? this.tipo,
      texto: texto ?? this.texto,
      midias: midias ?? this.midias,
      padraoExibicao: padraoExibicao ?? this.padraoExibicao,
      proporcaoCustom: proporcaoCustom ?? this.proporcaoCustom,
      colunasMosaico: colunasMosaico ?? this.colunasMosaico,
      permitirDownload: permitirDownload ?? this.permitirDownload,
      publicacaoOriginalId: publicacaoOriginalId ?? this.publicacaoOriginalId,
      alinhamentoX: alinhamentoX ?? this.alinhamentoX,
      alinhamentoY: alinhamentoY ?? this.alinhamentoY,
      escalaZoom: escalaZoom ?? this.escalaZoom,
      tags: tags ?? this.tags,
      lojaIdTag: lojaIdTag ?? this.lojaIdTag,
      itemLojaIdTag: itemLojaIdTag ?? this.itemLojaIdTag,
      itemLojaNomeTag: itemLojaNomeTag ?? this.itemLojaNomeTag,
      itemLojaPrecoTag: itemLojaPrecoTag ?? this.itemLojaPrecoTag,
      criadaEm: criadaEm ?? this.criadaEm,
      atualizadaEm: atualizadaEm ?? this.atualizadaEm,
      excluida: excluida ?? this.excluida,
      arquivada: arquivada ?? this.arquivada,
      fixada: fixada ?? this.fixada,
      ordemManual: ordemManual ?? this.ordemManual,
      visualizacoes: visualizacoes ?? this.visualizacoes,
      visualizacoesPorOrigem:
          visualizacoesPorOrigem ?? this.visualizacoesPorOrigem,
      tempoMedioVisualizacaoSegundos:
          tempoMedioVisualizacaoSegundos ?? this.tempoMedioVisualizacaoSegundos,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'autorCpf': autorCpf,
        'autorNome': autorNome,
        'autorFoto': autorFoto,
        'coautoresCpfs': coautoresCpfs,
        'tipo': tipo.name,
        'texto': texto,
        'midias': midias.map((m) => m.toJson()).toList(),
        'padraoExibicao': padraoExibicao.name,
        'proporcaoCustom': proporcaoCustom,
        'colunasMosaico': colunasMosaico,
        'permitirDownload': permitirDownload,
        'publicacaoOriginalId': publicacaoOriginalId,
        'alinhamentoX': alinhamentoX,
        'alinhamentoY': alinhamentoY,
        'escalaZoom': escalaZoom,
        'tags': tags,
        'lojaIdTag': lojaIdTag,
        'itemLojaIdTag': itemLojaIdTag,
        'itemLojaNomeTag': itemLojaNomeTag,
        'itemLojaPrecoTag': itemLojaPrecoTag,
        'criadaEm': criadaEm.toIso8601String(),
        'atualizadaEm': atualizadaEm.toIso8601String(),
        'excluida': excluida,
        'arquivada': arquivada,
        'fixada': fixada,
        'ordemManual': ordemManual,
        'visualizacoes': visualizacoes,
        'visualizacoesPorOrigem': visualizacoesPorOrigem,
        'tempoMedioVisualizacaoSegundos': tempoMedioVisualizacaoSegundos,
      };

  factory PublicacaoSocial.fromJson(Map<String, dynamic> json) {
    final agora = DateTime.now();
    return PublicacaoSocial(
      id: json['id'] as String? ?? '',
      autorCpf: json['autorCpf'] as String? ?? '',
      autorNome: json['autorNome'] as String? ?? '',
      autorFoto: json['autorFoto'] as String? ?? '',
      coautoresCpfs: (json['coautoresCpfs'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList(),
      tipo: TipoFeedSocial.values.firstWhere(
        (e) => e.name == json['tipo'],
        orElse: () => TipoFeedSocial.fotos,
      ),
      texto: json['texto'] as String? ?? '',
      midias: (json['midias'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((m) => MidiaPublicacao.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      padraoExibicao: PadraoExibicaoMidia.values.firstWhere(
        (e) => e.name == json['padraoExibicao'],
        orElse: () => PadraoExibicaoMidia.original,
      ),
      proporcaoCustom: (json['proporcaoCustom'] as num?)?.toDouble(),
      colunasMosaico: (json['colunasMosaico'] as num?)?.toInt() ?? 3,
      permitirDownload: json['permitirDownload'] as bool? ?? true,
      publicacaoOriginalId: json['publicacaoOriginalId'] as String? ?? '',
      alinhamentoX: (json['alinhamentoX'] as num?)?.toDouble() ?? 0.0,
      alinhamentoY: (json['alinhamentoY'] as num?)?.toDouble() ?? 0.0,
      escalaZoom: (json['escalaZoom'] as num?)?.toDouble() ?? 1.0,
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((e) => e.toString().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList(),
      lojaIdTag: json['lojaIdTag'] as String? ?? '',
      itemLojaIdTag: json['itemLojaIdTag'] as String? ?? '',
      itemLojaNomeTag: json['itemLojaNomeTag'] as String? ?? '',
      itemLojaPrecoTag: json['itemLojaPrecoTag'] as String? ?? '',
      criadaEm: DateTime.tryParse(json['criadaEm'] as String? ?? '') ?? agora,
      atualizadaEm:
          DateTime.tryParse(json['atualizadaEm'] as String? ?? '') ?? agora,
      excluida: json['excluida'] == true || json['excluida'] == 1,
      arquivada: json['arquivada'] == true || json['arquivada'] == 1,
      fixada: json['fixada'] == true || json['fixada'] == 1,
      ordemManual: (json['ordemManual'] as num?)?.toInt() ?? 0,
      visualizacoes: (json['visualizacoes'] as num?)?.toInt() ?? 0,
      visualizacoesPorOrigem:
          (json['visualizacoesPorOrigem'] as Map<dynamic, dynamic>? ?? const {})
              .map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0)),
      tempoMedioVisualizacaoSegundos:
          (json['tempoMedioVisualizacaoSegundos'] as num?)?.toInt() ?? 0,
    );
  }
}
