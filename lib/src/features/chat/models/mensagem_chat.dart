import 'dart:convert';

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
  final String tipo; // 'texto', 'imagem', 'arquivo', 'comanda'
  final String caminhoAnexo;
  final String nomeAnexo;
  final int tamanhoAnexo;
  final String pedidoId;
  final String dadosPedidoJson;
  final bool editada;
  final List<Map<String, dynamic>> historicoEdicoes;
  final String statusEnvio; // 'pendente', 'enviada', 'entregue', 'lida'
  final bool entregue;
  final bool favorita;

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
    this.lida = false,
    this.tipo = 'texto',
    this.caminhoAnexo = '',
    this.nomeAnexo = '',
    this.tamanhoAnexo = 0,
    this.pedidoId = '',
    this.dadosPedidoJson = '',
    this.editada = false,
    this.historicoEdicoes = const [],
    this.statusEnvio = 'enviada',
    this.entregue = false,
    this.favorita = false,
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
    String? tipo,
    String? caminhoAnexo,
    String? nomeAnexo,
    int? tamanhoAnexo,
    String? pedidoId,
    String? dadosPedidoJson,
    bool? editada,
    List<Map<String, dynamic>>? historicoEdicoes,
    String? statusEnvio,
    bool? entregue,
    bool? favorita,
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
      tipo: tipo ?? this.tipo,
      caminhoAnexo: caminhoAnexo ?? this.caminhoAnexo,
      nomeAnexo: nomeAnexo ?? this.nomeAnexo,
      tamanhoAnexo: tamanhoAnexo ?? this.tamanhoAnexo,
      pedidoId: pedidoId ?? this.pedidoId,
      dadosPedidoJson: dadosPedidoJson ?? this.dadosPedidoJson,
      editada: editada ?? this.editada,
      historicoEdicoes: historicoEdicoes ?? this.historicoEdicoes,
      statusEnvio: statusEnvio ?? this.statusEnvio,
      entregue: entregue ?? this.entregue,
      favorita: favorita ?? this.favorita,
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
      'tipo': tipo,
      'caminhoAnexo': caminhoAnexo,
      'nomeAnexo': nomeAnexo,
      'tamanhoAnexo': tamanhoAnexo,
      'pedidoId': pedidoId,
      'dadosPedidoJson': dadosPedidoJson,
      'editada': editada,
      'historicoEdicoes': historicoEdicoes,
      'statusEnvio': statusEnvio,
      'entregue': entregue,
      'favorita': favorita,
    };
  }

  factory MensagemChat.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> historico = [];
    final histRaw = json['historicoEdicoes'] ?? json['historico_edicoes'];
    if (histRaw is List) {
      historico = histRaw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } else if (histRaw is String && histRaw.isNotEmpty && histRaw != '[]') {
      try {
        final dec = jsonDecode(histRaw);
        if (dec is List) {
          historico =
              dec.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      } catch (_) {}
    }

    final lida = json['lida'] == true || json['lida'] == 1;
    final entregue = json['entregue'] == true || json['entregue'] == 1;
    final editada = json['editada'] == true || json['editada'] == 1;
    final favorita = json['favorita'] == true || json['favorita'] == 1;
    final enviadaPorMim = json['enviadaPorMim'] == true ||
        json['enviada_por_mim'] == true ||
        json['enviada_por_mim'] == 1;

    String status = json['statusEnvio'] as String? ??
        json['status_envio'] as String? ??
        'enviada';
    if (lida) {
      status = 'lida';
    } else if (entregue && status == 'pendente') {
      status = 'entregue';
    }

    final dataHoraStr =
        json['dataHora'] as String? ?? json['data_hora'] as String?;

    return MensagemChat(
      id: json['id'] as String? ?? '',
      conversaId: json['conversaId'] as String? ??
          json['conversa_id'] as String? ??
          '',
      remetenteId: json['remetenteId'] as String? ??
          json['remetente_id'] as String? ??
          '',
      remetenteNome: json['remetenteNome'] as String? ??
          json['remetente_nome'] as String? ??
          '',
      remetenteFoto: json['remetenteFoto'] as String? ??
          json['remetente_foto'] as String? ??
          '',
      destinatarioId: json['destinatarioId'] as String? ??
          json['destinatario_id'] as String? ??
          '',
      texto: json['texto'] as String? ?? '',
      dataHora: dataHoraStr != null
          ? (DateTime.tryParse(dataHoraStr)?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      enviadaPorMim: enviadaPorMim,
      nomeAtendente: json['nomeAtendente'] as String? ??
          json['nome_atendente'] as String? ??
          '',
      cpfAtendente: json['cpfAtendente'] as String? ??
          json['cpf_atendente'] as String? ??
          '',
      lida: lida,
      tipo: json['tipo'] as String? ?? 'texto',
      caminhoAnexo: json['caminhoAnexo'] as String? ??
          json['caminho_anexo'] as String? ??
          '',
      nomeAnexo: json['nomeAnexo'] as String? ??
          json['nome_anexo'] as String? ??
          '',
      tamanhoAnexo: json['tamanhoAnexo'] as int? ??
          json['tamanho_anexo'] as int? ??
          0,
      pedidoId: json['pedidoId'] as String? ??
          json['pedido_id'] as String? ??
          '',
      dadosPedidoJson: json['dadosPedidoJson'] as String? ??
          json['dados_pedido_json'] as String? ??
          '',
      editada: editada,
      historicoEdicoes: historico,
      statusEnvio: status,
      entregue: entregue,
      favorita: favorita,
    );
  }
}
