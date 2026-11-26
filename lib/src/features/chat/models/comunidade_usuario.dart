import 'dart:convert';

/// Canal de voz contínuo dentro de uma comunidade (inspirado no Discord).
class CanalVozComunidade {
  final String id;
  final String nome;
  final List<String> participantesAtivos;

  const CanalVozComunidade({
    required this.id,
    required this.nome,
    this.participantesAtivos = const [],
  });

  CanalVozComunidade copyWith({
    String? id,
    String? nome,
    List<String>? participantesAtivos,
  }) {
    return CanalVozComunidade(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      participantesAtivos: participantesAtivos ?? this.participantesAtivos,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'participantesAtivos': participantesAtivos,
    };
  }

  factory CanalVozComunidade.fromJson(Map<String, dynamic> json) {
    return CanalVozComunidade(
      id: json['id'] as String? ?? '',
      nome: json['nome'] as String? ?? 'Sala de Voz',
      participantesAtivos:
          (json['participantesAtivos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

/// Comunidade criada na mensageria pessoal do usuário (isolada da Ágora Digital e das Lojas).
class ComunidadeUsuario {
  final String id;
  final String nome;
  final String descricao;
  final String foto;
  final String criadorCpf;
  final List<String> membrosIds;
  final List<String> canaisTextoIds;
  final List<CanalVozComunidade> canaisVoz;
  final DateTime criadoEm;

  const ComunidadeUsuario({
    required this.id,
    required this.nome,
    this.descricao = '',
    this.foto = '',
    required this.criadorCpf,
    this.membrosIds = const [],
    this.canaisTextoIds = const [],
    this.canaisVoz = const [],
    required this.criadoEm,
  });

  ComunidadeUsuario copyWith({
    String? id,
    String? nome,
    String? descricao,
    String? foto,
    String? criadorCpf,
    List<String>? membrosIds,
    List<String>? canaisTextoIds,
    List<CanalVozComunidade>? canaisVoz,
    DateTime? criadoEm,
  }) {
    return ComunidadeUsuario(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      foto: foto ?? this.foto,
      criadorCpf: criadorCpf ?? this.criadorCpf,
      membrosIds: membrosIds ?? this.membrosIds,
      canaisTextoIds: canaisTextoIds ?? this.canaisTextoIds,
      canaisVoz: canaisVoz ?? this.canaisVoz,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'foto': foto,
      'criadorCpf': criadorCpf,
      'membrosIds': membrosIds,
      'canaisTextoIds': canaisTextoIds,
      'canaisVoz': canaisVoz.map((c) => c.toJson()).toList(),
      'criadoEm': criadoEm.toIso8601String(),
    };
  }

  factory ComunidadeUsuario.fromJson(Map<String, dynamic> json) {
    List<String> decodificarLista(dynamic raw, dynamic jsonStr) {
      if (raw is List) {
        return raw.map((e) => e.toString()).toList();
      }
      if (jsonStr is String && jsonStr.isNotEmpty) {
        try {
          final decoded = jsonDecode(jsonStr);
          if (decoded is List) {
            return decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {}
      }
      return const [];
    }

    List<CanalVozComunidade> canaisVozList = const [];
    if (json['canaisVoz'] is List) {
      canaisVozList = (json['canaisVoz'] as List<dynamic>)
          .map((e) => CanalVozComunidade.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (json['canais_voz_json'] is String &&
        (json['canais_voz_json'] as String).isNotEmpty) {
      try {
        final decoded = jsonDecode(json['canais_voz_json'] as String);
        if (decoded is List) {
          canaisVozList = decoded
              .map(
                (e) => CanalVozComunidade.fromJson(e as Map<String, dynamic>),
              )
              .toList();
        }
      } catch (_) {}
    }

    final criadoStr =
        (json['criadoEm'] as String?) ?? (json['criado_em'] as String?);

    return ComunidadeUsuario(
      id: json['id'] as String? ?? '',
      nome: json['nome'] as String? ?? 'Comunidade',
      descricao: json['descricao'] as String? ?? '',
      foto: json['foto'] as String? ?? '',
      criadorCpf:
          (json['criadorCpf'] as String?) ??
          (json['criador_cpf'] as String?) ??
          '',
      membrosIds: decodificarLista(json['membrosIds'], json['membros_json']),
      canaisTextoIds: decodificarLista(
        json['canaisTextoIds'],
        json['canais_texto_json'],
      ),
      canaisVoz: canaisVozList,
      criadoEm: criadoStr != null
          ? (DateTime.tryParse(criadoStr)?.toLocal() ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
