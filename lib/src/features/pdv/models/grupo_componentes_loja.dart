import 'package:nous/src/core/services/gerador_id.dart';

class GrupoComponentesLoja {
  final String id;
  final String nome;
  final String foto;
  final List<String> itemIds;

  const GrupoComponentesLoja({
    required this.id,
    required this.nome,
    this.foto = '',
    this.itemIds = const [],
  });

  factory GrupoComponentesLoja.novo({
    required String nome,
    String foto = '',
    List<String> itemIds = const [],
  }) {
    return GrupoComponentesLoja(
      id: gerarIdUnico(),
      nome: nome,
      foto: foto,
      itemIds: itemIds,
    );
  }

  GrupoComponentesLoja copyWith({
    String? nome,
    String? foto,
    List<String>? itemIds,
  }) {
    return GrupoComponentesLoja(
      id: id,
      nome: nome ?? this.nome,
      foto: foto ?? this.foto,
      itemIds: itemIds ?? this.itemIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'foto': foto,
      'itemIds': itemIds,
    };
  }

  factory GrupoComponentesLoja.fromJson(Map<String, dynamic> json) {
    return GrupoComponentesLoja(
      id: json['id'] as String,
      nome: json['nome'] as String,
      foto: json['foto'] as String? ?? '',
      itemIds: (json['itemIds'] as List<dynamic>? ?? const [])
          .map((item) => item as String)
          .toList(),
    );
  }
}