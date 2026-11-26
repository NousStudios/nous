import 'dart:convert';

/// Lista de transmissão para envio simultâneo de mídias/mensagens a múltiplos contatos Nous.
class ListaTransmissao {
  final String id;
  final String nome;
  final List<String> destinatariosCpfs;
  final DateTime criadoEm;
  final DateTime? atualizadoEm;

  const ListaTransmissao({
    required this.id,
    required this.nome,
    this.destinatariosCpfs = const [],
    required this.criadoEm,
    this.atualizadoEm,
  });

  ListaTransmissao copyWith({
    String? id,
    String? nome,
    List<String>? destinatariosCpfs,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return ListaTransmissao(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      destinatariosCpfs: destinatariosCpfs ?? this.destinatariosCpfs,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'destinatariosCpfs': destinatariosCpfs,
      'criadoEm': criadoEm.toIso8601String(),
      'atualizadoEm': (atualizadoEm ?? criadoEm).toIso8601String(),
    };
  }

  factory ListaTransmissao.fromJson(Map<String, dynamic> json) {
    List<String> dests = const [];
    if (json['destinatariosCpfs'] is List) {
      dests = (json['destinatariosCpfs'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();
    } else if (json['destinatarios_json'] is String &&
        (json['destinatarios_json'] as String).isNotEmpty) {
      try {
        final decoded = jsonDecode(json['destinatarios_json'] as String);
        if (decoded is List) {
          dests = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    final criadoStr =
        (json['criadoEm'] as String?) ?? (json['criado_em'] as String?);
    final atualizadoStr =
        (json['atualizadoEm'] as String?) ??
        (json['atualizado_em'] as String?);

    return ListaTransmissao(
      id: json['id'] as String? ?? '',
      nome: json['nome'] as String? ?? 'Lista de Transmissão',
      destinatariosCpfs: dests,
      criadoEm: criadoStr != null
          ? (DateTime.tryParse(criadoStr)?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      atualizadoEm: atualizadoStr != null
          ? DateTime.tryParse(atualizadoStr)?.toLocal()
          : null,
    );
  }
}
