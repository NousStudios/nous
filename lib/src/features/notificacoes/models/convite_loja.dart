import 'package:nous/src/features/pdv/models/membro_loja.dart';

enum StatusConvite { pendente, aceito, recusado }

class ConviteLoja {
  final String id;
  final String cpfConvidante;
  final String nomeConvidante;
  final String cpfConvidado;
  final String lojaId;
  final String nomeLoja;
  final PapelMembro papel;
  final DateTime dataHora;
  final StatusConvite status;

  const ConviteLoja({
    required this.id,
    required this.cpfConvidante,
    required this.nomeConvidante,
    required this.cpfConvidado,
    required this.lojaId,
    required this.nomeLoja,
    required this.papel,
    required this.dataHora,
    this.status = StatusConvite.pendente,
  });

  ConviteLoja copyWith({
    StatusConvite? status,
  }) {
    return ConviteLoja(
      id: id,
      cpfConvidante: cpfConvidante,
      nomeConvidante: nomeConvidante,
      cpfConvidado: cpfConvidado,
      lojaId: lojaId,
      nomeLoja: nomeLoja,
      papel: papel,
      dataHora: dataHora,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cpfConvidante': cpfConvidante,
      'nomeConvidante': nomeConvidante,
      'cpfConvidado': cpfConvidado,
      'lojaId': lojaId,
      'nomeLoja': nomeLoja,
      'papel': papel.name,
      'dataHora': dataHora.toIso8601String(),
      'status': status.name,
    };
  }

  factory ConviteLoja.fromJson(Map<String, dynamic> json) {
    return ConviteLoja(
      id: json['id'] as String,
      cpfConvidante: json['cpfConvidante'] as String? ?? '',
      nomeConvidante: json['nomeConvidante'] as String? ?? '',
      cpfConvidado: json['cpfConvidado'] as String? ?? '',
      lojaId: json['lojaId'] as String? ?? '',
      nomeLoja: json['nomeLoja'] as String? ?? '',
      papel: PapelMembro.values.byName(
        json['papel'] as String? ?? PapelMembro.funcionario.name,
      ),
      dataHora: DateTime.parse(json['dataHora'] as String),
      status: StatusConvite.values.byName(
        json['status'] as String? ?? StatusConvite.pendente.name,
      ),
    );
  }
}