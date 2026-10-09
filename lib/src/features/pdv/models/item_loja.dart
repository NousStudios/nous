import 'package:nous/src/core/services/gerador_id.dart';

enum TipoItemLoja { produto, servico }

enum UnidadeItemLoja { un, g, ml }

class VarianteItem {
  final String nome;
  final String preco;

  const VarianteItem({
    required this.nome,
    this.preco = '',
  });

  VarianteItem copyWith({
    String? nome,
    String? preco,
  }) {
    return VarianteItem(
      nome: nome ?? this.nome,
      preco: preco ?? this.preco,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'preco': preco,
    };
  }

  factory VarianteItem.fromJson(dynamic json) {
    if (json is String) {
      return VarianteItem(nome: json);
    }
    if (json is Map<String, dynamic>) {
      return VarianteItem(
        nome: json['nome'] as String? ?? '',
        preco: json['preco'] as String? ?? '',
      );
    }
    return const VarianteItem(nome: '');
  }
}

class ItemLoja {
  final String id;
  final String nome;
  final TipoItemLoja? tipo;
  final String preco;
  final String precoCusto;
  final String codigoBarras;
  final List<VarianteItem> variantes;
  final List<String> imagens;
  final String descricao;
  final bool possuiDelivery;
  final String freteGratisAte;
  final String valorPorKm;
  final String estoqueMinimo;
  final UnidadeItemLoja unidadeBase;
  final double consumoPorVenda;

  const ItemLoja({
    required this.id,
    required this.nome,
    this.tipo,
    this.preco = '',
    this.precoCusto = '',
    this.codigoBarras = '',
    this.variantes = const [],
    this.imagens = const [],
    this.descricao = '',
    this.possuiDelivery = false,
    this.freteGratisAte = '',
    this.valorPorKm = '',
    this.estoqueMinimo = '',
    this.unidadeBase = UnidadeItemLoja.un,
    this.consumoPorVenda = 1.0,
  });

  factory ItemLoja.novo({
    required String nome,
    TipoItemLoja? tipo,
    String preco = '',
    String precoCusto = '',
    String codigoBarras = '',
    List<VarianteItem> variantes = const [],
    List<String> imagens = const [],
    String descricao = '',
    bool possuiDelivery = false,
    String freteGratisAte = '',
    String valorPorKm = '',
    String estoqueMinimo = '',
    UnidadeItemLoja unidadeBase = UnidadeItemLoja.un,
    double consumoPorVenda = 1.0,
  }) {
    return ItemLoja(
      id: gerarIdUnico(),
      nome: nome,
      tipo: tipo,
      preco: preco,
      precoCusto: precoCusto,
      codigoBarras: codigoBarras,
      variantes: variantes,
      imagens: imagens,
      descricao: descricao,
      possuiDelivery: possuiDelivery,
      freteGratisAte: freteGratisAte,
      valorPorKm: valorPorKm,
      estoqueMinimo: estoqueMinimo,
      unidadeBase: unidadeBase,
      consumoPorVenda: consumoPorVenda,
    );
  }

  ItemLoja copyWith({
    String? nome,
    TipoItemLoja? tipo,
    String? preco,
    String? precoCusto,
    String? codigoBarras,
    List<VarianteItem>? variantes,
    List<String>? imagens,
    String? descricao,
    bool? possuiDelivery,
    String? freteGratisAte,
    String? valorPorKm,
    String? estoqueMinimo,
    UnidadeItemLoja? unidadeBase,
    double? consumoPorVenda,
  }) {
    return ItemLoja(
      id: id,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      preco: preco ?? this.preco,
      precoCusto: precoCusto ?? this.precoCusto,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      variantes: variantes ?? this.variantes,
      imagens: imagens ?? this.imagens,
      descricao: descricao ?? this.descricao,
      possuiDelivery: possuiDelivery ?? this.possuiDelivery,
      freteGratisAte: freteGratisAte ?? this.freteGratisAte,
      valorPorKm: valorPorKm ?? this.valorPorKm,
      estoqueMinimo: estoqueMinimo ?? this.estoqueMinimo,
      unidadeBase: unidadeBase ?? this.unidadeBase,
      consumoPorVenda: consumoPorVenda ?? this.consumoPorVenda,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'tipo': tipo?.name,
      'preco': preco,
      'precoCusto': precoCusto,
      'codigoBarras': codigoBarras,
      'variantes': variantes.map((v) => v.toJson()).toList(),
      'imagens': imagens,
      'descricao': descricao,
      'possuiDelivery': possuiDelivery,
      'freteGratisAte': freteGratisAte,
      'valorPorKm': valorPorKm,
      'estoqueMinimo': estoqueMinimo,
      'unidadeBase': unidadeBase.name,
      'consumoPorVenda': consumoPorVenda,
    };
  }

  factory ItemLoja.fromJson(Map<String, dynamic> json) {
    final tipoTexto = json['tipo'] as String?;
    final unidadeTexto = json['unidadeBase'] as String?;
    final unidade = unidadeTexto == null
        ? UnidadeItemLoja.un
        : UnidadeItemLoja.values.firstWhere(
            (u) => u.name == unidadeTexto,
            orElse: () => UnidadeItemLoja.un,
          );
    return ItemLoja(
      id: json['id'] as String,
      nome: json['nome'] as String,
      tipo: tipoTexto == null
          ? null
          : TipoItemLoja.values.firstWhere(
              (t) => t.name == tipoTexto,
              orElse: () => TipoItemLoja.produto,
            ),
      preco: json['preco'] as String? ?? '',
      precoCusto: json['precoCusto'] as String? ?? '',
      codigoBarras: json['codigoBarras'] as String? ?? '',
      variantes: (json['variantes'] as List<dynamic>? ?? const [])
          .map((item) => VarianteItem.fromJson(item))
          .toList(),
      imagens: (json['imagens'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      descricao: json['descricao'] as String? ?? '',
      possuiDelivery: json['possuiDelivery'] as bool? ?? false,
      freteGratisAte: json['freteGratisAte'] as String? ?? '',
      valorPorKm: json['valorPorKm'] as String? ?? '',
      estoqueMinimo: json['estoqueMinimo'] as String? ?? '',
      unidadeBase: unidade,
      consumoPorVenda:
          (json['consumoPorVenda'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemLoja && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}