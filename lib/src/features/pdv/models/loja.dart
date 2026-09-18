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
    );
  }
}