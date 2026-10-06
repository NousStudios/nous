import 'package:nous/src/features/pdv/models/membro_loja.dart';

enum StatusConvite { pendente, aceito, recusado }

enum TipoNotificacao {
  conviteEntrada,
  alteracaoPapel,
  remocaoLoja,
  solicitacaoExclusaoDono,
}

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
  final TipoNotificacao tipo;

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
    this.tipo = TipoNotificacao.conviteEntrada,
  });

  ConviteLoja copyWith({
    StatusConvite? status,
    TipoNotificacao? tipo,
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
      tipo: tipo ?? this.tipo,
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
      'tipo': tipo.name,
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
      papel: PapelMembro.values.firstWhere(
        (p) => p.name == (json['papel'] as String?),
        orElse: () => PapelMembro.funcionario,
      ),
      dataHora: DateTime.tryParse(json['dataHora'] as String? ?? '') ??
          DateTime.now(),
      status: StatusConvite.values.firstWhere(
        (s) => s.name == (json['status'] as String?),
        orElse: () => StatusConvite.pendente,
      ),
      tipo: TipoNotificacao.values.firstWhere(
        (t) => t.name == (json['tipo'] as String?),
        orElse: () => TipoNotificacao.conviteEntrada,
      ),
    );
  }
}