enum TipoNotificacaoSocial {
  curtida,
  deslike,
  comentario,
  republicacao,
  novoSeguidor,
  mencao,
  conviteColaboracao,
}

class NotificacaoSocial {
  final String id;
  final String destinatarioCpf;
  final String autorCpf;
  final String autorNome;
  final String autorFoto;
  final TipoNotificacaoSocial tipo;
  final String publicacaoId;
  final String resumo;
  final DateTime criadaEm;
  final bool lida;

  const NotificacaoSocial({
    required this.id,
    required this.destinatarioCpf,
    required this.autorCpf,
    this.autorNome = '',
    this.autorFoto = '',
    required this.tipo,
    this.publicacaoId = '',
    this.resumo = '',
    required this.criadaEm,
    this.lida = false,
  });

  NotificacaoSocial copyWith({
    String? id,
    String? destinatarioCpf,
    String? autorCpf,
    String? autorNome,
    String? autorFoto,
    TipoNotificacaoSocial? tipo,
    String? publicacaoId,
    String? resumo,
    DateTime? criadaEm,
    bool? lida,
  }) {
    return NotificacaoSocial(
      id: id ?? this.id,
      destinatarioCpf: destinatarioCpf ?? this.destinatarioCpf,
      autorCpf: autorCpf ?? this.autorCpf,
      autorNome: autorNome ?? this.autorNome,
      autorFoto: autorFoto ?? this.autorFoto,
      tipo: tipo ?? this.tipo,
      publicacaoId: publicacaoId ?? this.publicacaoId,
      resumo: resumo ?? this.resumo,
      criadaEm: criadaEm ?? this.criadaEm,
      lida: lida ?? this.lida,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'destinatarioCpf': destinatarioCpf,
        'autorCpf': autorCpf,
        'autorNome': autorNome,
        'autorFoto': autorFoto,
        'tipo': tipo.name,
        'publicacaoId': publicacaoId,
        'resumo': resumo,
        'criadaEm': criadaEm.toIso8601String(),
        'lida': lida,
      };

  factory NotificacaoSocial.fromJson(Map<String, dynamic> json) {
    return NotificacaoSocial(
      id: json['id'] as String? ?? '',
      destinatarioCpf: json['destinatarioCpf'] as String? ?? '',
      autorCpf: json['autorCpf'] as String? ?? '',
      autorNome: json['autorNome'] as String? ?? '',
      autorFoto: json['autorFoto'] as String? ?? '',
      tipo: TipoNotificacaoSocial.values.firstWhere(
        (e) => e.name == json['tipo'],
        orElse: () => TipoNotificacaoSocial.curtida,
      ),
      publicacaoId: json['publicacaoId'] as String? ?? '',
      resumo: json['resumo'] as String? ?? '',
      criadaEm:
          DateTime.tryParse(json['criadaEm'] as String? ?? '') ?? DateTime.now(),
      lida: json['lida'] == true || json['lida'] == 1,
    );
  }
}
