class AvaliacaoProduto {
  final String id;
  final String itemId;
  final String lojaId;
  final String autorCpf;
  final String autorNome;
  final String autorFoto;
  final int estrelas;
  final String comentario;
  final DateTime criadoEm;
  final int curtidas;
  final int descurtidas;

  const AvaliacaoProduto({
    required this.id,
    required this.itemId,
    required this.lojaId,
    required this.autorCpf,
    required this.autorNome,
    this.autorFoto = '',
    required this.estrelas,
    required this.comentario,
    required this.criadoEm,
    this.curtidas = 0,
    this.descurtidas = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'item_id': itemId,
        'loja_id': lojaId,
        'autor_cpf': autorCpf,
        'autor_nome': autorNome,
        'autor_foto': autorFoto,
        'estrelas': estrelas,
        'comentario': comentario,
        'criado_em': criadoEm.toIso8601String(),
        'curtidas': curtidas,
        'descurtidas': descurtidas,
      };

  factory AvaliacaoProduto.fromJson(Map<String, dynamic> json) =>
      AvaliacaoProduto(
        id: json['id'] as String? ?? '',
        itemId: json['item_id'] as String? ?? '',
        lojaId: json['loja_id'] as String? ?? '',
        autorCpf: json['autor_cpf'] as String? ?? '',
        autorNome: json['autor_nome'] as String? ?? 'Cliente Nous',
        autorFoto: json['autor_foto'] as String? ?? '',
        estrelas: (json['estrelas'] as num?)?.toInt().clamp(1, 5) ?? 5,
        comentario: json['comentario'] as String? ?? '',
        criadoEm: DateTime.tryParse(json['criado_em'] as String? ?? '') ??
            DateTime.now(),
        curtidas: (json['curtidas'] as num?)?.toInt() ?? 0,
        descurtidas: (json['descurtidas'] as num?)?.toInt() ?? 0,
      );

  AvaliacaoProduto copyWith({
    String? id,
    String? itemId,
    String? lojaId,
    String? autorCpf,
    String? autorNome,
    String? autorFoto,
    int? estrelas,
    String? comentario,
    DateTime? criadoEm,
    int? curtidas,
    int? descurtidas,
  }) {
    return AvaliacaoProduto(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      lojaId: lojaId ?? this.lojaId,
      autorCpf: autorCpf ?? this.autorCpf,
      autorNome: autorNome ?? this.autorNome,
      autorFoto: autorFoto ?? this.autorFoto,
      estrelas: estrelas ?? this.estrelas,
      comentario: comentario ?? this.comentario,
      criadoEm: criadoEm ?? this.criadoEm,
      curtidas: curtidas ?? this.curtidas,
      descurtidas: descurtidas ?? this.descurtidas,
    );
  }
}

class ResumoAvaliacoesProduto {
  final double mediaEstrelas;
  final int totalAvaliacoes;
  final Map<int, int> contagemPorEstrela;

  const ResumoAvaliacoesProduto({
    required this.mediaEstrelas,
    required this.totalAvaliacoes,
    required this.contagemPorEstrela,
  });

  static const vazio = ResumoAvaliacoesProduto(
    mediaEstrelas: 0.0,
    totalAvaliacoes: 0,
    contagemPorEstrela: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
  );
}
