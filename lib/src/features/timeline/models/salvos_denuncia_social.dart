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

  const ListaSalvosSocial({
    required this.id,
    required this.donoCpf,
    required this.nome,
    this.visibilidade = VisibilidadeListaSalvos.publicaFeed,
    this.colaboradoresCpfs = const [],
    required this.criadaEm,
  });

  ListaSalvosSocial copyWith({
    String? id,
    String? donoCpf,
    String? nome,
    VisibilidadeListaSalvos? visibilidade,
    List<String>? colaboradoresCpfs,
    DateTime? criadaEm,
  }) {
    return ListaSalvosSocial(
      id: id ?? this.id,
      donoCpf: donoCpf ?? this.donoCpf,
      nome: nome ?? this.nome,
      visibilidade: visibilidade ?? this.visibilidade,
      colaboradoresCpfs: colaboradoresCpfs ?? this.colaboradoresCpfs,
      criadaEm: criadaEm ?? this.criadaEm,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'donoCpf': donoCpf,
        'nome': nome,
        'visibilidade': visibilidade.name,
        'colaboradoresCpfs': colaboradoresCpfs,
        'criadaEm': criadaEm.toIso8601String(),
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
    );
  }
}

class ItemSalvoSocial {
  final String id;
  final String listaId;
  final String usuarioCpf;
  final String publicacaoId;
  final DateTime salvoEm;

  const ItemSalvoSocial({
    required this.id,
    required this.listaId,
    required this.usuarioCpf,
    required this.publicacaoId,
    required this.salvoEm,
  });

  ItemSalvoSocial copyWith({
    String? id,
    String? listaId,
    String? usuarioCpf,
    String? publicacaoId,
    DateTime? salvoEm,
  }) {
    return ItemSalvoSocial(
      id: id ?? this.id,
      listaId: listaId ?? this.listaId,
      usuarioCpf: usuarioCpf ?? this.usuarioCpf,
      publicacaoId: publicacaoId ?? this.publicacaoId,
      salvoEm: salvoEm ?? this.salvoEm,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'listaId': listaId,
        'usuarioCpf': usuarioCpf,
        'publicacaoId': publicacaoId,
        'salvoEm': salvoEm.toIso8601String(),
      };

  factory ItemSalvoSocial.fromJson(Map<String, dynamic> json) {
    return ItemSalvoSocial(
      id: json['id'] as String? ?? '',
      listaId: json['listaId'] as String? ?? '',
      usuarioCpf: json['usuarioCpf'] as String? ?? '',
      publicacaoId: json['publicacaoId'] as String? ?? '',
      salvoEm:
          DateTime.tryParse(json['salvoEm'] as String? ?? '') ?? DateTime.now(),
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
