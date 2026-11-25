enum StatusProjetoComunitario { aberto, emAndamento, concluido }

/// Projeto comunitário de Autogestão Social criado no mapa do Nous
/// (ex.: buraco na rua, iluminação, limpeza, melhoria urbana).
class ProjetoComunitario {
  final String id;
  final String titulo;
  final String descricao;
  final String categoria;
  final double latitude;
  final double longitude;
  final String enderecoResumo;
  final String criadorCpf;
  final String criadorNome;
  final String responsavelCpf;
  final String responsavelNome;
  final StatusProjetoComunitario status;
  final String caminhoFoto;
  final List<String> apoiadoresCpfs;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  const ProjetoComunitario({
    required this.id,
    required this.titulo,
    this.descricao = '',
    this.categoria = 'Infraestrutura',
    required this.latitude,
    required this.longitude,
    this.enderecoResumo = '',
    required this.criadorCpf,
    this.criadorNome = '',
    this.responsavelCpf = '',
    this.responsavelNome = '',
    this.status = StatusProjetoComunitario.aberto,
    this.caminhoFoto = '',
    this.apoiadoresCpfs = const [],
    required this.criadoEm,
    required this.atualizadoEm,
  });

  bool get temResponsavel => responsavelCpf.trim().isNotEmpty;

  ProjetoComunitario copyWith({
    String? titulo,
    String? descricao,
    String? categoria,
    double? latitude,
    double? longitude,
    String? enderecoResumo,
    String? criadorCpf,
    String? criadorNome,
    String? responsavelCpf,
    String? responsavelNome,
    StatusProjetoComunitario? status,
    String? caminhoFoto,
    List<String>? apoiadoresCpfs,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return ProjetoComunitario(
      id: id,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      categoria: categoria ?? this.categoria,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      enderecoResumo: enderecoResumo ?? this.enderecoResumo,
      criadorCpf: criadorCpf ?? this.criadorCpf,
      criadorNome: criadorNome ?? this.criadorNome,
      responsavelCpf: responsavelCpf ?? this.responsavelCpf,
      responsavelNome: responsavelNome ?? this.responsavelNome,
      status: status ?? this.status,
      caminhoFoto: caminhoFoto ?? this.caminhoFoto,
      apoiadoresCpfs: apoiadoresCpfs ?? this.apoiadoresCpfs,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'categoria': categoria,
      'latitude': latitude,
      'longitude': longitude,
      'enderecoResumo': enderecoResumo,
      'criadorCpf': criadorCpf,
      'criadorNome': criadorNome,
      'responsavelCpf': responsavelCpf,
      'responsavelNome': responsavelNome,
      'status': status.name,
      'caminhoFoto': caminhoFoto,
      'apoiadoresCpfs': apoiadoresCpfs,
      'criadoEm': criadoEm.toIso8601String(),
      'atualizadoEm': atualizadoEm.toIso8601String(),
    };
  }

  factory ProjetoComunitario.fromJson(Map<String, dynamic> json) {
    final statusRaw = (json['status'] as String? ?? 'aberto').trim();
    return ProjetoComunitario(
      id: json['id'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      descricao: json['descricao'] as String? ?? '',
      categoria: json['categoria'] as String? ?? 'Infraestrutura',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      enderecoResumo: json['enderecoResumo'] as String? ?? '',
      criadorCpf: json['criadorCpf'] as String? ?? '',
      criadorNome: json['criadorNome'] as String? ?? '',
      responsavelCpf: json['responsavelCpf'] as String? ?? '',
      responsavelNome: json['responsavelNome'] as String? ?? '',
      status: StatusProjetoComunitario.values.firstWhere(
        (s) => s.name == statusRaw,
        orElse: () => StatusProjetoComunitario.aberto,
      ),
      caminhoFoto: json['caminhoFoto'] as String? ?? '',
      apoiadoresCpfs: (json['apoiadoresCpfs'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList(),
      criadoEm: DateTime.tryParse(json['criadoEm'] as String? ?? '') ??
          DateTime.now(),
      atualizadoEm: DateTime.tryParse(json['atualizadoEm'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
