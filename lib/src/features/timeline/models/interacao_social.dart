enum TipoReacaoSocial {
  like,
  deslike,
}

class ReacaoSocial {
  final String id;
  final String publicacaoId;
  final String usuarioCpf;
  final String usuarioNome;
  final String usuarioFoto;
  final TipoReacaoSocial tipo;
  final DateTime criadaEm;

  const ReacaoSocial({
    required this.id,
    required this.publicacaoId,
    required this.usuarioCpf,
    this.usuarioNome = '',
    this.usuarioFoto = '',
    required this.tipo,
    required this.criadaEm,
  });

  ReacaoSocial copyWith({
    String? id,
    String? publicacaoId,
    String? usuarioCpf,
    String? usuarioNome,
    String? usuarioFoto,
    TipoReacaoSocial? tipo,
    DateTime? criadaEm,
  }) {
    return ReacaoSocial(
      id: id ?? this.id,
      publicacaoId: publicacaoId ?? this.publicacaoId,
      usuarioCpf: usuarioCpf ?? this.usuarioCpf,
      usuarioNome: usuarioNome ?? this.usuarioNome,
      usuarioFoto: usuarioFoto ?? this.usuarioFoto,
      tipo: tipo ?? this.tipo,
      criadaEm: criadaEm ?? this.criadaEm,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'publicacaoId': publicacaoId,
        'usuarioCpf': usuarioCpf,
        'usuarioNome': usuarioNome,
        'usuarioFoto': usuarioFoto,
        'tipo': tipo.name,
        'criadaEm': criadaEm.toIso8601String(),
      };

  factory ReacaoSocial.fromJson(Map<String, dynamic> json) {
    return ReacaoSocial(
      id: json['id'] as String? ?? '',
      publicacaoId: json['publicacaoId'] as String? ?? '',
      usuarioCpf: json['usuarioCpf'] as String? ?? '',
      usuarioNome: json['usuarioNome'] as String? ?? '',
      usuarioFoto: json['usuarioFoto'] as String? ?? '',
      tipo: TipoReacaoSocial.values.firstWhere(
        (e) => e.name == json['tipo'],
        orElse: () => TipoReacaoSocial.like,
      ),
      criadaEm:
          DateTime.tryParse(json['criadaEm'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class ComentarioSocial {
  final String id;
  final String publicacaoId;
  final String autorCpf;
  final String autorNome;
  final String autorFoto;
  final String texto;
  final String respostaDeId;
  final DateTime criadaEm;
  final bool excluido;
  final bool fixado;

  const ComentarioSocial({
    required this.id,
    required this.publicacaoId,
    required this.autorCpf,
    this.autorNome = '',
    this.autorFoto = '',
    required this.texto,
    this.respostaDeId = '',
    required this.criadaEm,
    this.excluido = false,
    this.fixado = false,
  });

  ComentarioSocial copyWith({
    String? id,
    String? publicacaoId,
    String? autorCpf,
    String? autorNome,
    String? autorFoto,
    String? texto,
    String? respostaDeId,
    DateTime? criadaEm,
    bool? excluido,
    bool? fixado,
  }) {
    return ComentarioSocial(
      id: id ?? this.id,
      publicacaoId: publicacaoId ?? this.publicacaoId,
      autorCpf: autorCpf ?? this.autorCpf,
      autorNome: autorNome ?? this.autorNome,
      autorFoto: autorFoto ?? this.autorFoto,
      texto: texto ?? this.texto,
      respostaDeId: respostaDeId ?? this.respostaDeId,
      criadaEm: criadaEm ?? this.criadaEm,
      excluido: excluido ?? this.excluido,
      fixado: fixado ?? this.fixado,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'publicacaoId': publicacaoId,
        'autorCpf': autorCpf,
        'autorNome': autorNome,
        'autorFoto': autorFoto,
        'texto': texto,
        'respostaDeId': respostaDeId,
        'criadaEm': criadaEm.toIso8601String(),
        'excluido': excluido,
        'fixado': fixado,
      };

  factory ComentarioSocial.fromJson(Map<String, dynamic> json) {
    return ComentarioSocial(
      id: json['id'] as String? ?? '',
      publicacaoId: json['publicacaoId'] as String? ?? '',
      autorCpf: json['autorCpf'] as String? ?? '',
      autorNome: json['autorNome'] as String? ?? '',
      autorFoto: json['autorFoto'] as String? ?? '',
      texto: json['texto'] as String? ?? '',
      respostaDeId: json['respostaDeId'] as String? ?? '',
      criadaEm:
          DateTime.tryParse(json['criadaEm'] as String? ?? '') ?? DateTime.now(),
      excluido: json['excluido'] == true || json['excluido'] == 1,
      fixado: json['fixado'] == true || json['fixado'] == 1,
    );
  }
}

/// Item consolidado para o feed público "Interações na Rede" do usuário.
class RegistroInteracaoUsuario {
  final String id;
  final String tipoAcao; // 'like', 'deslike', 'comentario', 'republicacao'
  final String publicacaoId;
  final String resumo;
  final DateTime dataHora;

  const RegistroInteracaoUsuario({
    required this.id,
    required this.tipoAcao,
    required this.publicacaoId,
    required this.resumo,
    required this.dataHora,
  });
}
