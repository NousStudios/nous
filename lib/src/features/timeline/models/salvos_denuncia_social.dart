enum VisibilidadeListaSalvos {
  publicaFeed,
  privada,
  colaboradores,
}

class ListaSalvosSocial {
  final String id;
  final String donoCpf;
  final String nome;
  final VisibilidadeListaSalvos visibilidade;
  final List<String> colaboradoresCpfs;
  final DateTime criadaEm;
  final DateTime? atualizadaEm;
  final bool excluida;

  const ListaSalvosSocial({
    required this.id,
    required this.donoCpf,
    required this.nome,
    this.visibilidade = VisibilidadeListaSalvos.publicaFeed,
    this.colaboradoresCpfs = const [],
    required this.criadaEm,
    this.atualizadaEm,
    this.excluida = false,
  });

  DateTime get atualizadaEfetiva => atualizadaEm ?? criadaEm;

  ListaSalvosSocial copyWith({
    String? id,
    String? donoCpf,
    String? nome,
    VisibilidadeListaSalvos? visibilidade,
    List<String>? colaboradoresCpfs,
    DateTime? criadaEm,
    DateTime? atualizadaEm,
    bool? excluida,
  }) {
    return ListaSalvosSocial(
      id: id ?? this.id,
      donoCpf: donoCpf ?? this.donoCpf,
      nome: nome ?? this.nome,
      visibilidade: visibilidade ?? this.visibilidade,
      colaboradoresCpfs: colaboradoresCpfs ?? this.colaboradoresCpfs,
      criadaEm: criadaEm ?? this.criadaEm,
      atualizadaEm: atualizadaEm ?? this.atualizadaEm,
      excluida: excluida ?? this.excluida,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'donoCpf': donoCpf,
        'nome': nome,
        'visibilidade': visibilidade.name,
        'colaboradoresCpfs': colaboradoresCpfs,
        'criadaEm': criadaEm.toIso8601String(),
        'atualizadaEm': (atualizadaEm ?? criadaEm).toIso8601String(),
        'excluida': excluida,
      };

  factory ListaSalvosSocial.fromJson(Map<String, dynamic> json) {
    return ListaSalvosSocial(
      id: json['id'] as String? ?? '',
      donoCpf: json['donoCpf'] as String? ?? '',
      nome: json['nome'] as String? ?? 'Conteúdos Salvos',
      visibilidade: VisibilidadeListaSalvos.values.firstWhere(
        (e) => e.name == json['visibilidade'],
        orElse: () => VisibilidadeListaSalvos.publicaFeed,
      ),
      colaboradoresCpfs: (json['colaboradoresCpfs'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList(),
      criadaEm:
          DateTime.tryParse(json['criadaEm'] as String? ?? '') ?? DateTime.now(),
      atualizadaEm: json['atualizadaEm'] != null
          ? DateTime.tryParse(json['atualizadaEm'] as String)
          : null,
      excluida: json['excluida'] == true || json['excluida'] == 1,
    );
  }
}

class ItemSalvoSocial {
  final String id;
  final String listaId;
  final String usuarioCpf;
  final String publicacaoId;
  final DateTime salvoEm;
  final DateTime? atualizadaEm;
  final bool excluida;

  const ItemSalvoSocial({
    required this.id,
    required this.listaId,
    required this.usuarioCpf,
    required this.publicacaoId,
    required this.salvoEm,
    this.atualizadaEm,
    this.excluida = false,
  });

  DateTime get atualizadaEfetiva => atualizadaEm ?? salvoEm;

  ItemSalvoSocial copyWith({
    String? id,
    String? listaId,
    String? usuarioCpf,
    String? publicacaoId,
    DateTime? salvoEm,
    DateTime? atualizadaEm,
    bool? excluida,
  }) {
    return ItemSalvoSocial(
      id: id ?? this.id,
      listaId: listaId ?? this.listaId,
      usuarioCpf: usuarioCpf ?? this.usuarioCpf,
      publicacaoId: publicacaoId ?? this.publicacaoId,
      salvoEm: salvoEm ?? this.salvoEm,
      atualizadaEm: atualizadaEm ?? this.atualizadaEm,
      excluida: excluida ?? this.excluida,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'listaId': listaId,
        'usuarioCpf': usuarioCpf,
        'publicacaoId': publicacaoId,
        'salvoEm': salvoEm.toIso8601String(),
        'atualizadaEm': (atualizadaEm ?? salvoEm).toIso8601String(),
        'excluida': excluida,
      };

  factory ItemSalvoSocial.fromJson(Map<String, dynamic> json) {
    return ItemSalvoSocial(
      id: json['id'] as String? ?? '',
      listaId: json['listaId'] as String? ?? '',
      usuarioCpf: json['usuarioCpf'] as String? ?? '',
      publicacaoId: json['publicacaoId'] as String? ?? '',
      salvoEm:
          DateTime.tryParse(json['salvoEm'] as String? ?? '') ?? DateTime.now(),
      atualizadaEm: json['atualizadaEm'] != null
          ? DateTime.tryParse(json['atualizadaEm'] as String)
          : null,
      excluida: json['excluida'] == true || json['excluida'] == 1,
    );
  }
}

class DenunciaSocial {
  final String id;
  final String denuncianteCpf;
  final String denuncianteNome;
  final String alvoCpf;
  final String alvoNome;
  final String publicacaoId;
  final String motivo;
  final DateTime criadaEm;

  const DenunciaSocial({
    required this.id,
    required this.denuncianteCpf,
    this.denuncianteNome = '',
    required this.alvoCpf,
    this.alvoNome = '',
    this.publicacaoId = '',
    required this.motivo,
    required this.criadaEm,
  });

  DenunciaSocial copyWith({
    String? id,
    String? denuncianteCpf,
    String? denuncianteNome,
    String? alvoCpf,
    String? alvoNome,
    String? publicacaoId,
    String? motivo,
    DateTime? criadaEm,
  }) {
    return DenunciaSocial(
      id: id ?? this.id,
      denuncianteCpf: denuncianteCpf ?? this.denuncianteCpf,
      denuncianteNome: denuncianteNome ?? this.denuncianteNome,
      alvoCpf: alvoCpf ?? this.alvoCpf,
      alvoNome: alvoNome ?? this.alvoNome,
      publicacaoId: publicacaoId ?? this.publicacaoId,
      motivo: motivo ?? this.motivo,
      criadaEm: criadaEm ?? this.criadaEm,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'denuncianteCpf': denuncianteCpf,
        'denuncianteNome': denuncianteNome,
        'alvoCpf': alvoCpf,
        'alvoNome': alvoNome,
        'publicacaoId': publicacaoId,
        'motivo': motivo,
        'criadaEm': criadaEm.toIso8601String(),
      };

  factory DenunciaSocial.fromJson(Map<String, dynamic> json) {
    return DenunciaSocial(
      id: json['id'] as String? ?? '',
      denuncianteCpf: json['denuncianteCpf'] as String? ?? '',
      denuncianteNome: json['denuncianteNome'] as String? ?? '',
      alvoCpf: json['alvoCpf'] as String? ?? '',
      alvoNome: json['alvoNome'] as String? ?? '',
      publicacaoId: json['publicacaoId'] as String? ?? '',
      motivo: json['motivo'] as String? ?? '',
      criadaEm:
          DateTime.tryParse(json['criadaEm'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
