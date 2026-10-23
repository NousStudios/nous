import 'package:nous/src/features/pdv/models/membro_loja.dart';

enum StatusConvite { pendente, aceito, recusado }

enum TipoNotificacao {
  conviteEntrada,
  alteracaoPapel,
  remocaoLoja,
  solicitacaoExclusaoDono,
  solicitacaoDadoUsuario,
}

class ConviteLoja {
  final String id;
  final String cpfConvidante;
  final String nomeConvidante;
  final String cpfDonoOriginal;
  final String cpfConvidado;
  final String lojaId;
  final String nomeLoja;
  final PapelMembro papel;
  final DateTime dataHora;
  final StatusConvite status;
  final TipoNotificacao tipo;
  final String dadoSolicitado;

  const ConviteLoja({
    required this.id,
    required this.cpfConvidante,
    required this.nomeConvidante,
    this.cpfDonoOriginal = '',
    required this.cpfConvidado,
    required this.lojaId,
    required this.nomeLoja,
    required this.papel,
    required this.dataHora,
    this.status = StatusConvite.pendente,
    this.tipo = TipoNotificacao.conviteEntrada,
    this.dadoSolicitado = '',
  });

  ConviteLoja copyWith({
    StatusConvite? status,
    TipoNotificacao? tipo,
    String? cpfDonoOriginal,
    String? dadoSolicitado,
  }) {
    return ConviteLoja(
      id: id,
      cpfConvidante: cpfConvidante,
      nomeConvidante: nomeConvidante,
      cpfDonoOriginal: cpfDonoOriginal ?? this.cpfDonoOriginal,
      cpfConvidado: cpfConvidado,
      lojaId: lojaId,
      nomeLoja: nomeLoja,
      papel: papel,
      dataHora: dataHora,
      status: status ?? this.status,
      tipo: tipo ?? this.tipo,
      dadoSolicitado: dadoSolicitado ?? this.dadoSolicitado,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cpfConvidante': cpfConvidante,
      'nomeConvidante': nomeConvidante,
      'cpfDonoOriginal': cpfDonoOriginal,
      'cpfConvidado': cpfConvidado,
      'lojaId': lojaId,
      'nomeLoja': nomeLoja,
      'papel': papel.name,
      'dataHora': dataHora.toIso8601String(),
      'status': status.name,
      'tipo': tipo.name,
      'dadoSolicitado': dadoSolicitado,
    };
  }

  factory ConviteLoja.fromJson(Map<String, dynamic> json) {
    final convidante = json['cpfConvidante'] as String? ?? '';
    final dono = json['cpfDonoOriginal'] as String? ?? '';
    return ConviteLoja(
      id: json['id'] as String? ?? '',
      cpfConvidante: convidante,
      nomeConvidante: json['nomeConvidante'] as String? ?? '',
      cpfDonoOriginal: dono.isNotEmpty ? dono : convidante,
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
      dadoSolicitado: json['dadoSolicitado'] as String? ?? '',
    );
  }
}