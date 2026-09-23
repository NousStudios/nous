import 'package:nous/src/core/services/gerador_id.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';

class CategoriaLoja {
  final String id;
  final String nome;
  final TipoItemLoja? tipo;
  final List<String> itemIds;

  const CategoriaLoja({
    required this.id,
    required this.nome,
    this.tipo,
    this.itemIds = const [],
  });

  factory CategoriaLoja.nova({
    required String nome,
    TipoItemLoja? tipo,
    List<String> itemIds = const [],
  }) {
    return CategoriaLoja(
      id: gerarIdUnico(),
      nome: nome,
      tipo: tipo,
      itemIds: itemIds,
    );
  }

  CategoriaLoja copyWith({
    String? nome,
    TipoItemLoja? tipo,
    List<String>? itemIds,
  }) {
    return CategoriaLoja(
      id: id,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      itemIds: itemIds ?? this.itemIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'tipo': tipo?.name,
      'itemIds': itemIds,
    };
  }

  factory CategoriaLoja.fromJson(Map<String, dynamic> json) {
    final tipoTexto = json['tipo'] as String?;
    return CategoriaLoja(
      id: json['id'] as String,
      nome: json['nome'] as String,
      tipo: tipoTexto == null
          ? null
          : TipoItemLoja.values.firstWhere((t) => t.name == tipoTexto),
      itemIds: (json['itemIds'] as List<dynamic>? ?? const [])
          .map((item) => item as String)
          .toList(),
    );
  }
}