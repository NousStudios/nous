enum TipoChamada {
  voz,
  video,
}

enum EstadoChamada {
  iniciando,
  chamando, // Usuário discando
  tocando, // Usuário recebendo ligação
  conectada, // Em andamento
  encerrada,
}

class ChamadaSessao {
  final String id;
  final String conversaId;
  final TipoChamada tipo;
  final EstadoChamada estado;
  final String remetenteId;
  final String remetenteNome;
  final String remetenteFoto;
  final String destinatarioId;
  final String destinatarioNome;
  final String destinatarioFoto;
  final bool ehGrupo;
  final List<String> participantesIds;
  final bool videoHabilitado;
  final bool audioHabilitado;
  final DateTime iniciadaEm;

  const ChamadaSessao({
    required this.id,
    required this.conversaId,
    required this.tipo,
    required this.estado,
    required this.remetenteId,
    required this.remetenteNome,
    this.remetenteFoto = '',
    required this.destinatarioId,
    required this.destinatarioNome,
    this.destinatarioFoto = '',
    this.ehGrupo = false,
    this.participantesIds = const [],
    this.videoHabilitado = true,
    this.audioHabilitado = true,
    required this.iniciadaEm,
  });

  ChamadaSessao copyWith({
    String? id,
    String? conversaId,
    TipoChamada? tipo,
    EstadoChamada? estado,
    String? remetenteId,
    String? remetenteNome,
    String? remetenteFoto,
    String? destinatarioId,
    String? destinatarioNome,
    String? destinatarioFoto,
    bool? ehGrupo,
    List<String>? participantesIds,
    bool? videoHabilitado,
    bool? audioHabilitado,
    DateTime? iniciadaEm,
  }) {
    return ChamadaSessao(
      id: id ?? this.id,
      conversaId: conversaId ?? this.conversaId,
      tipo: tipo ?? this.tipo,
      estado: estado ?? this.estado,
      remetenteId: remetenteId ?? this.remetenteId,
      remetenteNome: remetenteNome ?? this.remetenteNome,
      remetenteFoto: remetenteFoto ?? this.remetenteFoto,
      destinatarioId: destinatarioId ?? this.destinatarioId,
      destinatarioNome: destinatarioNome ?? this.destinatarioNome,
      destinatarioFoto: destinatarioFoto ?? this.destinatarioFoto,
      ehGrupo: ehGrupo ?? this.ehGrupo,
      participantesIds: participantesIds ?? this.participantesIds,
      videoHabilitado: videoHabilitado ?? this.videoHabilitado,
      audioHabilitado: audioHabilitado ?? this.audioHabilitado,
      iniciadaEm: iniciadaEm ?? this.iniciadaEm,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversaId': conversaId,
      'tipo': tipo.name,
      'estado': estado.name,
      'remetenteId': remetenteId,
      'remetenteNome': remetenteNome,
      'remetenteFoto': remetenteFoto,
      'destinatarioId': destinatarioId,
      'destinatarioNome': destinatarioNome,
      'destinatarioFoto': destinatarioFoto,
      'ehGrupo': ehGrupo,
      'participantesIds': participantesIds,
      'videoHabilitado': videoHabilitado,
      'audioHabilitado': audioHabilitado,
      'iniciadaEm': iniciadaEm.toIso8601String(),
    };
  }

  factory ChamadaSessao.fromJson(Map<String, dynamic> json) {
    return ChamadaSessao(
      id: json['id'] as String? ?? '',
      conversaId: json['conversaId'] as String? ?? '',
      tipo: json['tipo'] == 'video' ? TipoChamada.video : TipoChamada.voz,
      estado: EstadoChamada.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => EstadoChamada.iniciando,
      ),
      remetenteId: json['remetenteId'] as String? ?? '',
      remetenteNome: json['remetenteNome'] as String? ?? '',
      remetenteFoto: json['remetenteFoto'] as String? ?? '',
      destinatarioId: json['destinatarioId'] as String? ?? '',
      destinatarioNome: json['destinatarioNome'] as String? ?? '',
      destinatarioFoto: json['destinatarioFoto'] as String? ?? '',
      ehGrupo: json['ehGrupo'] as bool? ?? false,
      participantesIds: (json['participantesIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      videoHabilitado: json['videoHabilitado'] as bool? ?? true,
      audioHabilitado: json['audioHabilitado'] as bool? ?? true,
      iniciadaEm: json['iniciadaEm'] != null
          ? DateTime.tryParse(json['iniciadaEm'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
