import 'package:nous/src/core/services/gerador_id.dart';

class ContratoTrabalhoMembro {
  final String id;
  final String cpf;
  final String tipoContrato; // CLT, PJ, Diarista, Temporário, Voluntário, Cooperado
  final double valorPadrao; // Diária ou salário base
  final String formaPagamentoPadrao;
  final List<String> caminhosArquivos;
  final DateTime dataInicio;
  final String observacoes;

  const ContratoTrabalhoMembro({
    required this.id,
    required this.cpf,
    this.tipoContrato = 'Diarista',
    this.valorPadrao = 0.0,
    this.formaPagamentoPadrao = 'Dinheiro',
    this.caminhosArquivos = const [],
    required this.dataInicio,
    this.observacoes = '',
  });

  factory ContratoTrabalhoMembro.novo({
    required String cpf,
    String tipoContrato = 'Diarista',
    double valorPadrao = 0.0,
    String formaPagamentoPadrao = 'Dinheiro',
    List<String> caminhosArquivos = const [],
    DateTime? dataInicio,
    String observacoes = '',
  }) {
    return ContratoTrabalhoMembro(
      id: gerarIdUnico(),
      cpf: cpf,
      tipoContrato: tipoContrato,
      valorPadrao: valorPadrao,
      formaPagamentoPadrao: formaPagamentoPadrao,
      caminhosArquivos: caminhosArquivos,
      dataInicio: dataInicio ?? DateTime.now(),
      observacoes: observacoes,
    );
  }

  ContratoTrabalhoMembro copyWith({
    String? id,
    String? cpf,
    String? tipoContrato,
    double? valorPadrao,
    String? formaPagamentoPadrao,
    List<String> ? caminhosArquivos,
    DateTime? dataInicio,
    String? observacoes,
  }) {
    return ContratoTrabalhoMembro(
      id: id ?? this.id,
      cpf: cpf ?? this.cpf,
      tipoContrato: tipoContrato ?? this.tipoContrato,
      valorPadrao: valorPadrao ?? this.valorPadrao,
      formaPagamentoPadrao: formaPagamentoPadrao ?? this.formaPagamentoPadrao,
      caminhosArquivos: caminhosArquivos ?? this.caminhosArquivos,
      dataInicio: dataInicio ?? this.dataInicio,
      observacoes: observacoes ?? this.observacoes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cpf': cpf,
      'tipoContrato': tipoContrato,
      'valorPadrao': valorPadrao,
      'formaPagamentoPadrao': formaPagamentoPadrao,
      'caminhosArquivos': caminhosArquivos,
      'dataInicio': dataInicio.toIso8601String(),
      'observacoes': observacoes,
    };
  }

  factory ContratoTrabalhoMembro.fromJson(Map<String, dynamic> json) {
    final arquivosJson = json['caminhosArquivos'] as List<dynamic>? ?? const [];
    final caminhosArquivos = arquivosJson.map((e) => e.toString()).toList();

    return ContratoTrabalhoMembro(
      id: json['id'] as String? ?? '',
      cpf: json['cpf'] as String? ?? '',
      tipoContrato: json['tipoContrato'] as String? ?? 'Diarista',
      valorPadrao: (json['valorPadrao'] as num?)?.toDouble() ?? 0.0,
      formaPagamentoPadrao: json['formaPagamentoPadrao'] as String? ?? 'Dinheiro',
      caminhosArquivos: caminhosArquivos,
      dataInicio: json['dataInicio'] != null
          ? DateTime.tryParse(json['dataInicio'] as String) ?? DateTime.now()
          : DateTime.now(),
      observacoes: json['observacoes'] as String? ?? '',
    );
  }
}
