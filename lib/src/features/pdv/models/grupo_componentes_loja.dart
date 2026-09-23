import 'package:nous/src/core/services/gerador_id.dart';

class GrupoComponentesLoja {
  final String id;
  final String nome;
  final List<String> itemIds;

  const GrupoComponentesLoja({
    required this.id,
    required this.nome,
    this.itemIds = const [],
  });

  factory GrupoComponentesLoja.novo({
    required String nome,
    List<String> itemIds = const [],
  }) {
    return GrupoComponentesLoja(
      id: gerarIdUnico(),
      nome: nome,
      itemIds: itemIds,
    );
  }

  GrupoComponentesLoja copyWith({
    String? nome,
    List<String>? itemIds,
  }) {
    return GrupoComponentesLoja(
      id: id,
      nome: nome ?? this.nome,
      itemIds: itemIds ?? this.itemIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'itemIds': itemIds,
    };
  }

  factory GrupoComponentesLoja.fromJson(Map<String, dynamic> json) {
    return GrupoComponentesLoja(
      id: json['id'] as String,
      nome: json['nome'] as String,
      itemIds: (json['itemIds'] as List<dynamic>? ?? const [])
          .map((item) => item as String)
          .toList(),
    );
  }
}