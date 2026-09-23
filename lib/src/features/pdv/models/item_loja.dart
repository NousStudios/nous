enum TipoItemLoja { produto, servico }

String _gerarIdUnico() => DateTime.now().millisecondsSinceEpoch.toString();

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
      id: _gerarIdUnico(),
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

class CategoriaLoja {
  final String id;
  final String nome;
  final String? grupoComponentesId;
  final TipoItemLoja? tipo;
  final List<String> itemIds;

  const CategoriaLoja({
    required this.id,
    required this.nome,
    this.grupoComponentesId,
    this.tipo,
    this.itemIds = const [],
  });

  factory CategoriaLoja.nova({
    required String nome,
    String? grupoComponentesId,
    TipoItemLoja? tipo,
    List<String> itemIds = const [],
  }) {
    return CategoriaLoja(
      id: _gerarIdUnico(),
      nome: nome,
      grupoComponentesId: grupoComponentesId,
      tipo: tipo,
      itemIds: itemIds,
    );
  }

  CategoriaLoja copyWith({
    String? nome,
    String? grupoComponentesId,
    TipoItemLoja? tipo,
    List<String>? itemIds,
  }) {
    return CategoriaLoja(
      id: id,
      nome: nome ?? this.nome,
      grupoComponentesId: grupoComponentesId ?? this.grupoComponentesId,
      tipo: tipo ?? this.tipo,
      itemIds: itemIds ?? this.itemIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'grupoComponentesId': grupoComponentesId,
      'tipo': tipo?.name,
      'itemIds': itemIds,
    };
  }

  factory CategoriaLoja.fromJson(Map<String, dynamic> json) {
    final tipoTexto = json['tipo'] as String?;
    return CategoriaLoja(
      id: json['id'] as String,
      nome: json['nome'] as String,
      grupoComponentesId: json['grupoComponentesId'] as String?,
      tipo: tipoTexto == null
          ? null
          : TipoItemLoja.values.firstWhere((t) => t.name == tipoTexto),
      itemIds: (json['itemIds'] as List<dynamic>? ?? const [])
          .map((item) => item as String)
          .toList(),
    );
  }
}

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
      id: _gerarIdUnico(),
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