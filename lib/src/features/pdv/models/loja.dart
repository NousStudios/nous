import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';

class Loja {
  final String id;

  final String nome;
  final String cnpj;
  final String telefone;
  final String endereco;
  final String numero;
  final String email;
  final String categorias;
  final String tags;

  final List<CategoriaLoja> categoriasLoja;
  final List<ItemLoja> itensLoja;
  final List<GrupoComponentesLoja> gruposComponentesLoja;
  final List<Cliente> clientesLoja;

  const Loja({
    required this.id,
    required this.nome,
    required this.cnpj,
    required this.telefone,
    required this.endereco,
    required this.numero,
    required this.email,
    required this.categorias,
    required this.tags,
    this.categoriasLoja = const [],
    this.itensLoja = const [],
    this.gruposComponentesLoja = const [],
    this.clientesLoja = const [],
  });

  Loja copyWith({
    String? nome,
    String? cnpj,
    String? telefone,
    String? endereco,
    String? numero,
    String? email,
    String? categorias,
    String? tags,
    List<CategoriaLoja>? categoriasLoja,
    List<ItemLoja>? itensLoja,
    List<GrupoComponentesLoja>? gruposComponentesLoja,
    List<Cliente>? clientesLoja,
  }) {
    return Loja(
      id: id,
      nome: nome ?? this.nome,
      cnpj: cnpj ?? this.cnpj,
      telefone: telefone ?? this.telefone,
      endereco: endereco ?? this.endereco,
      numero: numero ?? this.numero,
      email: email ?? this.email,
      categorias: categorias ?? this.categorias,
      tags: tags ?? this.tags,
      categoriasLoja: categoriasLoja ?? this.categoriasLoja,
      itensLoja: itensLoja ?? this.itensLoja,
      gruposComponentesLoja: gruposComponentesLoja ?? this.gruposComponentesLoja,
      clientesLoja: clientesLoja ?? this.clientesLoja,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'cnpj': cnpj,
      'telefone': telefone,
      'endereco': endereco,
      'numero': numero,
      'email': email,
      'categorias': categorias,
      'tags': tags,
      'categoriasLoja': categoriasLoja.map((c) => c.toJson()).toList(),
      'itensLoja': itensLoja.map((i) => i.toJson()).toList(),
      'gruposComponentesLoja':
          gruposComponentesLoja.map((g) => g.toJson()).toList(),
      'clientesLoja': clientesLoja.map((c) => c.toJson()).toList(),
    };
  }

  factory Loja.fromJson(Map<String, dynamic> json) {
    return Loja(
      id: json['id'] as String,
      nome: json['nome'] as String,
      cnpj: json['cnpj'] as String,
      telefone: json['telefone'] as String,
      endereco: json['endereco'] as String,
      numero: json['numero'] as String,
      email: json['email'] as String,
      categorias: json['categorias'] as String,
      tags: json['tags'] as String,
      categoriasLoja: (json['categoriasLoja'] as List<dynamic>? ?? const [])
          .map((item) => CategoriaLoja.fromJson(item as Map<String, dynamic>))
          .toList(),
      itensLoja: (json['itensLoja'] as List<dynamic>? ?? const [])
          .map((item) => ItemLoja.fromJson(item as Map<String, dynamic>))
          .toList(),
      gruposComponentesLoja:
          (json['gruposComponentesLoja'] as List<dynamic>? ?? const [])
              .map((item) =>
                  GrupoComponentesLoja.fromJson(item as Map<String, dynamic>))
              .toList(),
      clientesLoja: (json['clientesLoja'] as List<dynamic>? ?? const [])
          .map((item) => Cliente.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}