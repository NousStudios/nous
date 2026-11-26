import 'dart:convert';

/// Filtro personalizado de conversas criado pelo usuário na Mensageria.
class FiltroChatPersonalizado {
  final String id;
  final String nome;
  final List<String> conversasIds;
  final int ordem;
  final DateTime criadoEm;

  const FiltroChatPersonalizado({
    required this.id,
    required this.nome,
    this.conversasIds = const [],
    this.ordem = 0,
    required this.criadoEm,
  });

  FiltroChatPersonalizado copyWith({
    String? id,
    String? nome,
    List<String>? conversasIds,
    int? ordem,
    DateTime? criadoEm,
  }) {
    return FiltroChatPersonalizado(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      conversasIds: conversasIds ?? this.conversasIds,
      ordem: ordem ?? this.ordem,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'conversasIds': conversasIds,
      'ordem': ordem,
      'criadoEm': criadoEm.toIso8601String(),
    };
  }

  factory FiltroChatPersonalizado.fromJson(Map<String, dynamic> json) {
    List<String> ids = const [];
    if (json['conversasIds'] is List) {
      ids = (json['conversasIds'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();
    } else if (json['conversas_json'] is String &&
        (json['conversas_json'] as String).isNotEmpty) {
      try {
        final decoded = jsonDecode(json['conversas_json'] as String);
        if (decoded is List) {
          ids = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    final criadoStr =
        (json['criadoEm'] as String?) ?? (json['criado_em'] as String?);

    return FiltroChatPersonalizado(
      id: json['id'] as String? ?? '',
      nome: json['nome'] as String? ?? 'Filtro',
      conversasIds: ids,
      ordem: (json['ordem'] as num?)?.toInt() ?? 0,
      criadoEm: criadoStr != null
          ? (DateTime.tryParse(criadoStr)?.toLocal() ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
