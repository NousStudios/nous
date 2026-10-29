import 'dart:convert';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';

class ConversaChat {
  final String id;
  final String titulo;
  final String subtitulo;
  final String foto;
  final String identificador; // CPF do usuário, ID da loja ou ID do grupo
  final bool ehLoja;
  final bool ehGrupo;
  final String nomeGrupo; // Nome do grupo mantido independente do título da conversa
  final String? lojaId; // ID da loja caso pertença ao escopo de uma loja
  final List<String> participantesIds;
  final String ultimaMensagem;
  final DateTime dataHoraUltimaMensagem;
  final int naoLidasCount;
  final List<MensagemChat> mensagens;
  final bool fixada;
  final bool arquivada;
  final DateTime? atualizadaEm;

  const ConversaChat({
    required this.id,
    required this.titulo,
    this.subtitulo = '',
    this.foto = '',
    required this.identificador,
    this.ehLoja = false,
    this.ehGrupo = false,
    this.nomeGrupo = '',
    this.lojaId,
    this.participantesIds = const [],
    this.ultimaMensagem = '',
    required this.dataHoraUltimaMensagem,
    this.naoLidasCount = 0,
    this.mensagens = const [],
    this.fixada = false,
    this.arquivada = false,
    this.atualizadaEm,
  });

  ConversaChat copyWith({
    String? id,
    String? titulo,
    String? subtitulo,
    String? foto,
    String? identificador,
    bool? ehLoja,
    bool? ehGrupo,
    String? nomeGrupo,
    String? lojaId,
    List<String>? participantesIds,
    String? ultimaMensagem,
    DateTime? dataHoraUltimaMensagem,
    int? naoLidasCount,
    List<MensagemChat>? mensagens,
    bool? fixada,
    bool? arquivada,
    DateTime? atualizadaEm,
  }) {
    return ConversaChat(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      subtitulo: subtitulo ?? this.subtitulo,
      foto: foto ?? this.foto,
      identificador: identificador ?? this.identificador,
      ehLoja: ehLoja ?? this.ehLoja,
      ehGrupo: ehGrupo ?? this.ehGrupo,
      nomeGrupo: nomeGrupo ?? this.nomeGrupo,
      lojaId: lojaId ?? this.lojaId,
      participantesIds: participantesIds ?? this.participantesIds,
      ultimaMensagem: ultimaMensagem ?? this.ultimaMensagem,
      dataHoraUltimaMensagem:
          dataHoraUltimaMensagem ?? this.dataHoraUltimaMensagem,
      naoLidasCount: naoLidasCount ?? this.naoLidasCount,
      mensagens: mensagens ?? this.mensagens,
      fixada: fixada ?? this.fixada,
      arquivada: arquivada ?? this.arquivada,
      atualizadaEm: atualizadaEm ?? this.atualizadaEm,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'subtitulo': subtitulo,
      'foto': foto,
      'identificador': identificador,
      'ehLoja': ehLoja,
      'ehGrupo': ehGrupo,
      'nomeGrupo': nomeGrupo,
      'nome_grupo': nomeGrupo,
      'lojaId': lojaId ?? '',
      'participantesIds': participantesIds,
      'ultimaMensagem': ultimaMensagem,
      'dataHoraUltimaMensagem': dataHoraUltimaMensagem.toIso8601String(),
      'naoLidasCount': naoLidasCount,
      'mensagens': mensagens.map((m) => m.toJson()).toList(),
      'fixada': fixada,
      'arquivada': arquivada,
      'atualizadaEm': (atualizadaEm ?? dataHoraUltimaMensagem).toIso8601String(),
    };
  }

  factory ConversaChat.fromJson(Map<String, dynamic> json) {
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

    final dataHoraStr = (json['dataHoraUltimaMensagem'] as String?) ??
        (json['data_hora_ultima_mensagem'] as String?);

    final ehG = (json['ehGrupo'] as bool?) ??
        ((json['eh_grupo'] as int?) == 1);

    var nGrupo = (json['nomeGrupo'] as String?) ??
        (json['nome_grupo'] as String?) ??
        '';

    final titOriginal = json['titulo'] as String? ?? '';
    if (nGrupo.isEmpty && ehG && titOriginal.isNotEmpty && titOriginal != 'Conversa' && titOriginal != 'Nova Conversa') {
      nGrupo = titOriginal;
    }

    return ConversaChat(
      id: json['id'] as String? ?? '',
      titulo: titOriginal,
      subtitulo: json['subtitulo'] as String? ?? '',
      foto: json['foto'] as String? ?? '',
      identificador: json['identificador'] as String? ?? '',
      ehLoja: (json['ehLoja'] as bool?) ??
          ((json['eh_loja'] as int?) == 1),
      ehGrupo: ehG,
      nomeGrupo: nGrupo,
      lojaId: json['lojaId'] as String? ?? json['loja_id'] as String?,
      participantesIds: participantes,
      ultimaMensagem: json['ultimaMensagem'] as String? ??
          json['ultima_mensagem'] as String? ??
          '',
      dataHoraUltimaMensagem: dataHoraStr != null
          ? DateTime.tryParse(dataHoraStr) ?? DateTime.now()
          : DateTime.now(),
      naoLidasCount: json['naoLidasCount'] as int? ?? 0,
      mensagens: (json['mensagens'] as List<dynamic>? ?? const [])
          .map((m) => MensagemChat.fromJson(m as Map<String, dynamic>))
          .toList(),
      fixada: json['fixada'] == true || json['fixada'] == 1,
      arquivada: json['arquivada'] == true || json['arquivada'] == 1,
      atualizadaEm: json['atualizadaEm'] != null
          ? DateTime.tryParse(json['atualizadaEm'] as String)
          : (json['atualizado_em'] != null
              ? DateTime.tryParse(json['atualizado_em'] as String)
              : null),
    );
  }
}

