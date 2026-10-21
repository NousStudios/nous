class MensagemChat {
  final String id;
  final String conversaId;
  final String remetenteId;
  final String remetenteNome;
  final String remetenteFoto;
  final String destinatarioId;
  final String texto;
  final DateTime dataHora;
  final bool enviadaPorMim;
  final String nomeAtendente;
  final String cpfAtendente;
  final bool lida;

  const MensagemChat({
    required this.id,
    required this.conversaId,
    required this.remetenteId,
    required this.remetenteNome,
    this.remetenteFoto = '',
    this.destinatarioId = '',
    required this.texto,
    required this.dataHora,
    this.enviadaPorMim = false,
    this.nomeAtendente = '',
    this.cpfAtendente = '',
    this.lida = true,
  });

  MensagemChat copyWith({
    String? id,
    String? conversaId,
    String? remetenteId,
    String? remetenteNome,
    String? remetenteFoto,
    String? destinatarioId,
    String? texto,
    DateTime? dataHora,
    bool? enviadaPorMim,
    String? nomeAtendente,
    String? cpfAtendente,
    bool? lida,
  }) {
    return MensagemChat(
      id: id ?? this.id,
      conversaId: conversaId ?? this.conversaId,
      remetenteId: remetenteId ?? this.remetenteId,
      remetenteNome: remetenteNome ?? this.remetenteNome,
      remetenteFoto: remetenteFoto ?? this.remetenteFoto,
      destinatarioId: destinatarioId ?? this.destinatarioId,
      texto: texto ?? this.texto,
      dataHora: dataHora ?? this.dataHora,
      enviadaPorMim: enviadaPorMim ?? this.enviadaPorMim,
      nomeAtendente: nomeAtendente ?? this.nomeAtendente,
      cpfAtendente: cpfAtendente ?? this.cpfAtendente,
      lida: lida ?? this.lida,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversaId': conversaId,
      'remetenteId': remetenteId,
      'remetenteNome': remetenteNome,
      'remetenteFoto': remetenteFoto,
      'destinatarioId': destinatarioId,
      'texto': texto,
      'dataHora': dataHora.toIso8601String(),
      'enviadaPorMim': enviadaPorMim,
      'nomeAtendente': nomeAtendente,
      'cpfAtendente': cpfAtendente,
      'lida': lida,
    };
  }

  factory MensagemChat.fromJson(Map<String, dynamic> json) {
    return MensagemChat(
      id: json['id'] as String? ?? '',
      conversaId: json['conversaId'] as String? ?? '',
      remetenteId: json['remetenteId'] as String? ?? '',
      remetenteNome: json['remetenteNome'] as String? ?? '',
      remetenteFoto: json['remetenteFoto'] as String? ?? '',
      destinatarioId: json['destinatarioId'] as String? ?? '',
      texto: json['texto'] as String? ?? '',
      dataHora: json['dataHora'] != null
          ? DateTime.tryParse(json['dataHora'] as String) ?? DateTime.now()
          : DateTime.now(),
      enviadaPorMim: json['enviadaPorMim'] as bool? ?? false,
      nomeAtendente: json['nomeAtendente'] as String? ?? '',
      cpfAtendente: json['cpfAtendente'] as String? ?? '',
      lida: json['lida'] as bool? ?? true,
    );
  }
}
