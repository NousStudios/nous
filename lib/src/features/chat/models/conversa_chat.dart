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
  final String
  nomeGrupo; // Nome do grupo mantido independente do título da conversa
  final String tituloConversa; // Título/assunto da conversa, independente do nome do contato
  final String? lojaId; // ID da loja caso pertença ao escopo de uma loja
  final List<String> participantesIds;
  final String ultimaMensagem;
  final DateTime dataHoraUltimaMensagem;
  final int naoLidasCount;
  final List<MensagemChat> mensagens;
  final bool fixada;
  final bool arquivada;
  final bool silenciada;
  final DateTime? atualizadaEm;
  final bool ultimaMensagemEnviadaPorMim;
  final String statusUltimaMensagem;

  const ConversaChat({
    required this.id,
    required this.titulo,
    this.subtitulo = '',
    this.foto = '',
    required this.identificador,
    this.ehLoja = false,
    this.ehGrupo = false,
    this.nomeGrupo = '',
    this.tituloConversa = '',
    this.lojaId,
    this.participantesIds = const [],
    this.ultimaMensagem = '',
    required this.dataHoraUltimaMensagem,
    this.naoLidasCount = 0,
    this.mensagens = const [],
    this.fixada = false,
    this.arquivada = false,
    this.silenciada = false,
    this.atualizadaEm,
    this.ultimaMensagemEnviadaPorMim = false,
    this.statusUltimaMensagem = '',
  });

  bool get temTituloConversa =>
      tituloConversa.trim().isNotEmpty &&
      tituloConversa.trim().toLowerCase() != titulo.trim().toLowerCase() &&
      tituloConversa.trim().toLowerCase() != nomeGrupo.trim().toLowerCase();

  ConversaChat copyWith({
    String? id,
    String? titulo,
    String? subtitulo,
    String? foto,
    String? identificador,
    bool? ehLoja,
    bool? ehGrupo,
    String? nomeGrupo,
    String? tituloConversa,
    String? lojaId,
    List<String>? participantesIds,
    String? ultimaMensagem,
    DateTime? dataHoraUltimaMensagem,
    int? naoLidasCount,
    List<MensagemChat>? mensagens,
    bool? fixada,
    bool? arquivada,
    bool? silenciada,
    DateTime? atualizadaEm,
    bool? ultimaMensagemEnviadaPorMim,
    String? statusUltimaMensagem,
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
      tituloConversa: tituloConversa ?? this.tituloConversa,
      lojaId: lojaId ?? this.lojaId,
      participantesIds: participantesIds ?? this.participantesIds,
      ultimaMensagem: ultimaMensagem ?? this.ultimaMensagem,
      dataHoraUltimaMensagem:
          dataHoraUltimaMensagem ?? this.dataHoraUltimaMensagem,
      naoLidasCount: naoLidasCount ?? this.naoLidasCount,
      mensagens: mensagens ?? this.mensagens,
      fixada: fixada ?? this.fixada,
      arquivada: arquivada ?? this.arquivada,
      silenciada: silenciada ?? this.silenciada,
      atualizadaEm: atualizadaEm ?? this.atualizadaEm,
      ultimaMensagemEnviadaPorMim:
          ultimaMensagemEnviadaPorMim ?? this.ultimaMensagemEnviadaPorMim,
      statusUltimaMensagem: statusUltimaMensagem ?? this.statusUltimaMensagem,
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
      'tituloConversa': tituloConversa,
      'titulo_conversa': tituloConversa,
      'lojaId': lojaId ?? '',
      'participantesIds': participantesIds,
      'ultimaMensagem': ultimaMensagem,
      'dataHoraUltimaMensagem': dataHoraUltimaMensagem.toIso8601String(),
      'naoLidasCount': naoLidasCount,
      'mensagens': mensagens.map((m) => m.toJson()).toList(),
      'fixada': fixada,
      'arquivada': arquivada,
      'silenciada': silenciada,
      'atualizadaEm': (atualizadaEm ?? dataHoraUltimaMensagem)
          .toIso8601String(),
      'ultimaMensagemEnviadaPorMim': ultimaMensagemEnviadaPorMim,
      'statusUltimaMensagem': statusUltimaMensagem,
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

    final dataHoraStr =
        (json['dataHoraUltimaMensagem'] as String?) ??
        (json['data_hora_ultima_mensagem'] as String?);

    final ehG = (json['ehGrupo'] as bool?) ?? ((json['eh_grupo'] as int?) == 1);

    var nGrupo =
        (json['nomeGrupo'] as String?) ?? (json['nome_grupo'] as String?) ?? '';

    final titOriginal = (json['titulo'] as String? ?? '').trim();
    final subOriginal = (json['subtitulo'] as String? ?? '').trim();
    if (nGrupo.isEmpty &&
        ehG &&
        titOriginal.isNotEmpty &&
        titOriginal != 'Conversa' &&
        titOriginal != 'Nova Conversa') {
      nGrupo = titOriginal;
    }

    final titValido = titOriginal.isNotEmpty &&
        titOriginal != 'Conversa' &&
        titOriginal != 'Nova Conversa' &&
        titOriginal != 'Contato' &&
        titOriginal != 'Contato Nous';

    final subValido = subOriginal.isNotEmpty &&
        subOriginal != 'Conversa' &&
        subOriginal != 'Contato Nous';

    final tituloResolvido = titValido
        ? titOriginal
        : (nGrupo.isNotEmpty
            ? nGrupo
            : (subValido
                ? subOriginal
                : (ehG
                    ? (nGrupo.isNotEmpty ? nGrupo : 'Grupo')
                    : 'Contato Nous')));

    return ConversaChat(
      id: json['id'] as String? ?? '',
      titulo: tituloResolvido,
      subtitulo: subOriginal,
      foto: json['foto'] as String? ?? '',
      identificador: json['identificador'] as String? ?? '',
      ehLoja: (json['ehLoja'] as bool?) ?? ((json['eh_loja'] as int?) == 1),
      ehGrupo: ehG,
      nomeGrupo: nGrupo,
      tituloConversa: (json['tituloConversa'] as String?) ??
          (json['titulo_conversa'] as String?) ??
          '',
      lojaId: json['lojaId'] as String? ?? json['loja_id'] as String?,
      participantesIds: participantes,
      ultimaMensagem:
          json['ultimaMensagem'] as String? ??
          json['ultima_mensagem'] as String? ??
          '',
      dataHoraUltimaMensagem: dataHoraStr != null
          ? (DateTime.tryParse(dataHoraStr)?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      naoLidasCount: json['naoLidasCount'] as int? ?? 0,
      mensagens: (json['mensagens'] as List<dynamic>? ?? const [])
          .map((m) => MensagemChat.fromJson(m as Map<String, dynamic>))
          .toList(),
      fixada: json['fixada'] == true || json['fixada'] == 1,
      arquivada: json['arquivada'] == true || json['arquivada'] == 1,
      silenciada: json['silenciada'] == true || json['silenciada'] == 1,
      atualizadaEm: json['atualizadaEm'] != null
          ? DateTime.tryParse(json['atualizadaEm'] as String)?.toLocal()
          : (json['atualizado_em'] != null
                ? DateTime.tryParse(json['atualizado_em'] as String)?.toLocal()
                : null),
      ultimaMensagemEnviadaPorMim:
          json['ultimaMensagemEnviadaPorMim'] == true ||
          json['ultima_mensagem_enviada_por_mim'] == 1,
      statusUltimaMensagem:
          (json['statusUltimaMensagem'] as String?) ??
          (json['status_ultima_mensagem'] as String?) ??
          '',
    );
  }
}
