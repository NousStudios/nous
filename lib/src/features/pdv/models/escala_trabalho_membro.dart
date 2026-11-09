import 'package:nous/src/core/services/gerador_id.dart';

class EscalaTrabalhoMembro {
  final String id;
  final String cpf;
  final List<int> diasSemana; // 1 = Seg, ..., 7 = Dom
  final String horarioEntrada; // Ex: "08:00"
  final String horarioSaida; // Ex: "17:00"
  final bool ativo;
  final String observacoes;

  const EscalaTrabalhoMembro({
    required this.id,
    required this.cpf,
    this.diasSemana = const [1, 2, 3, 4, 5],
    this.horarioEntrada = '08:00',
    this.horarioSaida = '17:00',
    this.ativo = true,
    this.observacoes = '',
  });

  factory EscalaTrabalhoMembro.novo({
    required String cpf,
    List<int> diasSemana = const [1, 2, 3, 4, 5],
    String horarioEntrada = '08:00',
    String horarioSaida = '17:00',
    bool ativo = true,
    String observacoes = '',
  }) {
    return EscalaTrabalhoMembro(
      id: gerarIdUnico(),
      cpf: cpf,
      diasSemana: diasSemana,
      horarioEntrada: horarioEntrada,
      horarioSaida: horarioSaida,
      ativo: ativo,
      observacoes: observacoes,
    );
  }

  EscalaTrabalhoMembro copyWith({
    String? id,
    String? cpf,
    List<int>? diasSemana,
    String? horarioEntrada,
    String? horarioSaida,
    bool? ativo,
    String? observacoes,
  }) {
    return EscalaTrabalhoMembro(
      id: id ?? this.id,
      cpf: cpf ?? this.cpf,
      diasSemana: diasSemana ?? this.diasSemana,
      horarioEntrada: horarioEntrada ?? this.horarioEntrada,
      horarioSaida: horarioSaida ?? this.horarioSaida,
      ativo: ativo ?? this.ativo,
      observacoes: observacoes ?? this.observacoes,
    );
  }

  bool trabalhaNoDia(DateTime data) {
    if (!ativo) return false;
    return diasSemana.contains(data.weekday);
  }

  String resumoDias() {
    if (diasSemana.length == 7) return 'Todos os dias';
    if (diasSemana.length == 5 &&
        diasSemana.contains(1) &&
        diasSemana.contains(2) &&
        diasSemana.contains(3) &&
        diasSemana.contains(4) &&
        diasSemana.contains(5)) {
      return 'Segunda a Sexta';
    }
    const nomes = {
      1: 'Seg',
      2: 'Ter',
      3: 'Qua',
      4: 'Qui',
      5: 'Sex',
      6: 'Sáb',
      7: 'Dom',
    };
    final ordenados = List<int>.from(diasSemana)..sort();
    return ordenados.map((d) => nomes[d] ?? '$d').join(', ');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cpf': cpf,
      'diasSemana': diasSemana,
      'horarioEntrada': horarioEntrada,
      'horarioSaida': horarioSaida,
      'ativo': ativo,
      'observacoes': observacoes,
    };
  }

  factory EscalaTrabalhoMembro.fromJson(Map<String, dynamic> json) {
    final diasJson = json['diasSemana'] as List<dynamic>? ?? const [1, 2, 3, 4, 5];
    final diasSemana = diasJson.map((e) => (e as num).toInt()).toList();

    return EscalaTrabalhoMembro(
      id: json['id'] as String? ?? '',
      cpf: json['cpf'] as String? ?? '',
      diasSemana: diasSemana,
      horarioEntrada: json['horarioEntrada'] as String? ?? '08:00',
      horarioSaida: json['horarioSaida'] as String? ?? '17:00',
      ativo: json['ativo'] as bool? ?? true,
      observacoes: json['observacoes'] as String? ?? '',
    );
  }
}
