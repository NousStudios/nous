import 'package:nous/src/core/services/gerador_id.dart';

enum TipoItemLoja { produto, servico }

class ItemLoja {
  final String id;
  final String nome;
  final TipoItemLoja? tipo;
  final String preco;
  final List<String> variantes;
  final String descricao;
  final bool possuiDelivery;
  final String freteGratisAte;
  final String valorPorKm;

  const ItemLoja({
    required this.id,
    required this.nome,
    this.tipo,
    this.preco = '',
    this.variantes = const [],
    this.descricao = '',
    this.possuiDelivery = false,
    this.freteGratisAte = '',
    this.valorPorKm = '',
  });

  factory ItemLoja.novo({
    required String nome,
    TipoItemLoja? tipo,
    String preco = '',
    List<String> variantes = const [],
    String descricao = '',
    bool possuiDelivery = false,
    String freteGratisAte = '',
    String valorPorKm = '',
  }) {
    return ItemLoja(
      id: gerarIdUnico(),
      nome: nome,
      tipo: tipo,
      preco: preco,
      variantes: variantes,
      descricao: descricao,
      possuiDelivery: possuiDelivery,
      freteGratisAte: freteGratisAte,
      valorPorKm: valorPorKm,
    );
  }

  ItemLoja copyWith({
    String? nome,
    TipoItemLoja? tipo,
    String? preco,
    List<String>? variantes,
    String? descricao,
    bool? possuiDelivery,
    String? freteGratisAte,
    String? valorPorKm,
  }) {
    return ItemLoja(
      id: id,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      preco: preco ?? this.preco,
      variantes: variantes ?? this.variantes,
      descricao: descricao ?? this.descricao,
      possuiDelivery: possuiDelivery ?? this.possuiDelivery,
      freteGratisAte: freteGratisAte ?? this.freteGratisAte,
      valorPorKm: valorPorKm ?? this.valorPorKm,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'tipo': tipo?.name,
      'preco': preco,
      'variantes': variantes,
      'descricao': descricao,
      'possuiDelivery': possuiDelivery,
      'freteGratisAte': freteGratisAte,
      'valorPorKm': valorPorKm,
    };
  }

  factory ItemLoja.fromJson(Map<String, dynamic> json) {
    final tipoTexto = json['tipo'] as String?;
    return ItemLoja(
      id: json['id'] as String,
      nome: json['nome'] as String,
      tipo: tipoTexto == null
          ? null
          : TipoItemLoja.values.firstWhere((t) => t.name == tipoTexto),
      preco: json['preco'] as String? ?? '',
      variantes: (json['variantes'] as List<dynamic>? ?? const [])
          .map((item) => item as String)
          .toList(),
      descricao: json['descricao'] as String? ?? '',
      possuiDelivery: json['possuiDelivery'] as bool? ?? false,
      freteGratisAte: json['freteGratisAte'] as String? ?? '',
      valorPorKm: json['valorPorKm'] as String? ?? '',
    );
  }
}