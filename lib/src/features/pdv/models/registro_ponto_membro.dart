import 'package:nous/src/core/services/gerador_id.dart';

class RegistroPontoMembro {
  final String id;
  final String cpf;
  final DateTime dataHoraEntrada;
  final DateTime? dataHoraSaida;
  final String observacao;
  final String cpfAutor;

  const RegistroPontoMembro({
    required this.id,
    required this.cpf,
    required this.dataHoraEntrada,
    this.dataHoraSaida,
    this.observacao = '',
    this.cpfAutor = '',
  });

  factory RegistroPontoMembro.novo({
    required String cpf,
    required DateTime dataHoraEntrada,
    DateTime? dataHoraSaida,
    String observacao = '',
    String cpfAutor = '',
  }) {
    return RegistroPontoMembro(
      id: gerarIdUnico(),
      cpf: cpf,
      dataHoraEntrada: dataHoraEntrada,
      dataHoraSaida: dataHoraSaida,
      observacao: observacao,
      cpfAutor: cpfAutor,
    );
  }

  RegistroPontoMembro copyWith({
    String? id,
    String? cpf,
    DateTime? dataHoraEntrada,
    DateTime? dataHoraSaida,
    bool limparSaida = false,
    String? observacao,
    String? cpfAutor,
  }) {
    return RegistroPontoMembro(
      id: id ?? this.id,
      cpf: cpf ?? this.cpf,
      dataHoraEntrada: dataHoraEntrada ?? this.dataHoraEntrada,
      dataHoraSaida: limparSaida ? null : (dataHoraSaida ?? this.dataHoraSaida),
      observacao: observacao ?? this.observacao,
      cpfAutor: cpfAutor ?? this.cpfAutor,
    );
  }

  bool get estaEmAberto => dataHoraSaida == null;

  Duration get duracaoTrabalhada {
    final fim = dataHoraSaida ?? DateTime.now();
    return fim.difference(dataHoraEntrada);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cpf': cpf,
      'dataHoraEntrada': dataHoraEntrada.toIso8601String(),
      if (dataHoraSaida != null) 'dataHoraSaida': dataHoraSaida!.toIso8601String(),
      'observacao': observacao,
      'cpfAutor': cpfAutor,
    };
  }

  factory RegistroPontoMembro.fromJson(Map<String, dynamic> json) {
    return RegistroPontoMembro(
      id: json['id'] as String? ?? '',
      cpf: json['cpf'] as String? ?? '',
      dataHoraEntrada: json['dataHoraEntrada'] != null
          ? DateTime.tryParse(json['dataHoraEntrada'] as String) ?? DateTime.now()
          : DateTime.now(),
      dataHoraSaida: json['dataHoraSaida'] != null
          ? DateTime.tryParse(json['dataHoraSaida'] as String)
          : null,
      observacao: json['observacao'] as String? ?? '',
      cpfAutor: json['cpfAutor'] as String? ?? '',
    );
  }
}
