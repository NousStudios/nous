import 'dart:convert';

/// Status de deliberação do atestado de identidade
enum StatusValidacaoIdentidade {
  pendente,
  aprovado,
  rejeitado;

  static StatusValidacaoIdentidade fromString(String val) {
    return StatusValidacaoIdentidade.values.firstWhere(
      (e) => e.name == val.toLowerCase().trim(),
      orElse: () => StatusValidacaoIdentidade.pendente,
    );
  }
}

/// Modelo persistido de Solicitação de Validação / Atesto de Identidade Cidadã.
/// Permite que um novo CPF submeta sua ficha verdade para validação orgânica
/// pelos membros soberanos no Perfil Profissional Nous.
class SolicitacaoValidacaoIdentidade {
  final String id;
  final String cpfCandidato;
  final String nomeCandidato;
  final String apelidoCandidato;
  final String nomeDeUsuario;
  final String fotoCandidato;
  final String chavePublicaCandidato;
  final String dataHoraSolicitacao;
  final StatusValidacaoIdentidade status;
  final String cpfValidador;
  final String nomeValidador;
  final String assinaturaValidador;
  final String dataHoraValidacao;
  final String justificativa;

  const SolicitacaoValidacaoIdentidade({
    required this.id,
    required this.cpfCandidato,
    required this.nomeCandidato,
    this.apelidoCandidato = '',
    this.nomeDeUsuario = '',
    this.fotoCandidato = '',
    this.chavePublicaCandidato = '',
    required this.dataHoraSolicitacao,
    this.status = StatusValidacaoIdentidade.pendente,
    this.cpfValidador = '',
    this.nomeValidador = '',
    this.assinaturaValidador = '',
    this.dataHoraValidacao = '',
    this.justificativa = '',
  });

  bool get estaPendente => status == StatusValidacaoIdentidade.pendente;
  bool get estaAprovado => status == StatusValidacaoIdentidade.aprovado;
  bool get estaRejeitado => status == StatusValidacaoIdentidade.rejeitado;

  SolicitacaoValidacaoIdentidade copyWith({
    String? id,
    String? cpfCandidato,
    String? nomeCandidato,
    String? apelidoCandidato,
    String? nomeDeUsuario,
    String? fotoCandidato,
    String? chavePublicaCandidato,
    String? dataHoraSolicitacao,
    StatusValidacaoIdentidade? status,
    String? cpfValidador,
    String? nomeValidador,
    String? assinaturaValidador,
    String? dataHoraValidacao,
    String? justificativa,
  }) {
    return SolicitacaoValidacaoIdentidade(
      id: id ?? this.id,
      cpfCandidato: cpfCandidato ?? this.cpfCandidato,
      nomeCandidato: nomeCandidato ?? this.nomeCandidato,
      apelidoCandidato: apelidoCandidato ?? this.apelidoCandidato,
      nomeDeUsuario: nomeDeUsuario ?? this.nomeDeUsuario,
      fotoCandidato: fotoCandidato ?? this.fotoCandidato,
      chavePublicaCandidato: chavePublicaCandidato ?? this.chavePublicaCandidato,
      dataHoraSolicitacao: dataHoraSolicitacao ?? this.dataHoraSolicitacao,
      status: status ?? this.status,
      cpfValidador: cpfValidador ?? this.cpfValidador,
      nomeValidador: nomeValidador ?? this.nomeValidador,
      assinaturaValidador: assinaturaValidador ?? this.assinaturaValidador,
      dataHoraValidacao: dataHoraValidacao ?? this.dataHoraValidacao,
      justificativa: justificativa ?? this.justificativa,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cpfCandidato': cpfCandidato,
      'nomeCandidato': nomeCandidato,
      'apelidoCandidato': apelidoCandidato,
      'nomeDeUsuario': nomeDeUsuario,
      'fotoCandidato': fotoCandidato,
      'chavePublicaCandidato': chavePublicaCandidato,
      'dataHoraSolicitacao': dataHoraSolicitacao,
      'status': status.name,
      'cpfValidador': cpfValidador,
      'nomeValidador': nomeValidador,
      'assinaturaValidador': assinaturaValidador,
      'dataHoraValidacao': dataHoraValidacao,
      'justificativa': justificativa,
    };
  }

  factory SolicitacaoValidacaoIdentidade.fromJson(Map<String, dynamic> json) {
    return SolicitacaoValidacaoIdentidade(
      id: json['id'] as String? ?? '',
      cpfCandidato: json['cpfCandidato'] as String? ?? '',
      nomeCandidato: json['nomeCandidato'] as String? ?? '',
      apelidoCandidato: json['apelidoCandidato'] as String? ?? '',
      nomeDeUsuario: json['nomeDeUsuario'] as String? ?? '',
      fotoCandidato: json['fotoCandidato'] as String? ?? '',
      chavePublicaCandidato: json['chavePublicaCandidato'] as String? ?? '',
      dataHoraSolicitacao: json['dataHoraSolicitacao'] as String? ?? '',
      status: StatusValidacaoIdentidade.fromString(json['status'] as String? ?? 'pendente'),
      cpfValidador: json['cpfValidador'] as String? ?? '',
      nomeValidador: json['nomeValidador'] as String? ?? '',
      assinaturaValidador: json['assinaturaValidador'] as String? ?? '',
      dataHoraValidacao: json['dataHoraValidacao'] as String? ?? '',
      justificativa: json['justificativa'] as String? ?? '',
    );
  }

  String gerarCargaParaAssinatura() {
    return jsonEncode({
      'cpfCandidato': cpfCandidato,
      'chavePublicaCandidato': chavePublicaCandidato,
      'cpfValidador': cpfValidador,
      'status': status.name,
      'dataHoraValidacao': dataHoraValidacao,
    });
  }
}
