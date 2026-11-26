import 'dart:convert';
import 'package:nous/src/features/chat/models/chamada_sessao.dart';

/// Registro persistido de uma chamada de voz ou vídeo no histórico de Ligações.
class RegistroChamada {
  final String id;
  final String conversaId;
  final String tituloContato;
  final String fotoContato;
  final List<String> participantesIds;
  final TipoChamada tipo;
  final bool recebida;
  final bool atendida;
  final int duracaoSegundos;
  final DateTime dataHora;
  final bool ehGrupo;
  final bool ehAgora;

  const RegistroChamada({
    required this.id,
    required this.conversaId,
    required this.tituloContato,
    this.fotoContato = '',
    this.participantesIds = const [],
    this.tipo = TipoChamada.voz,
    this.recebida = false,
    this.atendida = false,
    this.duracaoSegundos = 0,
    required this.dataHora,
    this.ehGrupo = false,
    this.ehAgora = false,
  });

  RegistroChamada copyWith({
    String? id,
    String? conversaId,
    String? tituloContato,
    String? fotoContato,
    List<String>? participantesIds,
    TipoChamada? tipo,
    bool? recebida,
    bool? atendida,
    int? duracaoSegundos,
    DateTime? dataHora,
    bool? ehGrupo,
    bool? ehAgora,
  }) {
    return RegistroChamada(
      id: id ?? this.id,
      conversaId: conversaId ?? this.conversaId,
      tituloContato: tituloContato ?? this.tituloContato,
      fotoContato: fotoContato ?? this.fotoContato,
      participantesIds: participantesIds ?? this.participantesIds,
      tipo: tipo ?? this.tipo,
      recebida: recebida ?? this.recebida,
      atendida: atendida ?? this.atendida,
      duracaoSegundos: duracaoSegundos ?? this.duracaoSegundos,
      dataHora: dataHora ?? this.dataHora,
      ehGrupo: ehGrupo ?? this.ehGrupo,
      ehAgora: ehAgora ?? this.ehAgora,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversaId': conversaId,
      'tituloContato': tituloContato,
      'fotoContato': fotoContato,
      'participantesIds': participantesIds,
      'tipo': tipo.name,
      'recebida': recebida,
      'atendida': atendida,
      'duracaoSegundos': duracaoSegundos,
      'dataHora': dataHora.toIso8601String(),
      'ehGrupo': ehGrupo,
      'ehAgora': ehAgora,
    };
  }

  factory RegistroChamada.fromJson(Map<String, dynamic> json) {
    List<String> participantes = const [];
    if (json['participantesIds'] is List) {
      participantes = (json['participantesIds'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();
    } else if (json['participantes_json'] is String &&
        (json['participantes_json'] as String).isNotEmpty) {
      try {
        final decoded = jsonDecode(json['participantes_json'] as String);
        if (decoded is List) {
          participantes = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    final dataStr =
        (json['dataHora'] as String?) ?? (json['data_hora'] as String?);
    final tipoStr = json['tipo'] as String? ?? 'voz';

    return RegistroChamada(
      id: json['id'] as String? ?? '',
      conversaId:
          (json['conversaId'] as String?) ??
          (json['conversa_id'] as String?) ??
          '',
      tituloContato:
          (json['tituloContato'] as String?) ??
          (json['titulo_contato'] as String?) ??
          'Contato Nous',
      fotoContato:
          (json['fotoContato'] as String?) ??
          (json['foto_contato'] as String?) ??
          '',
      participantesIds: participantes,
      tipo: TipoChamada.values.firstWhere(
        (e) => e.name == tipoStr,
        orElse: () => TipoChamada.voz,
      ),
      recebida: json['recebida'] == true || json['recebida'] == 1,
      atendida: json['atendida'] == true || json['atendida'] == 1,
      duracaoSegundos:
          (json['duracaoSegundos'] as num?)?.toInt() ??
          (json['duracao_segundos'] as num?)?.toInt() ??
          0,
      dataHora: dataStr != null
          ? (DateTime.tryParse(dataStr)?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      ehGrupo: json['ehGrupo'] == true || json['eh_grupo'] == 1,
      ehAgora: json['ehAgora'] == true || json['eh_agora'] == 1,
    );
  }
}
