import 'package:nous/src/core/services/gerador_id.dart';

enum TipoRecorrenciaGasto {
  diario('Diário'),
  semanal('Semanal'),
  mensal('Mensal'),
  diasAlternados('Dias alternados'),
  diasDaSemana('Dias específicos da semana');

  final String rotulo;
  const TipoRecorrenciaGasto(this.rotulo);
}

class GastoFixo {
  final String id;
  final String descricao;
  final double valor;
  final TipoRecorrenciaGasto recorrencia;
  final List<int> diasDaSemana; // 1 = Seg, ..., 7 = Dom
  final int? diaDoMes; // 1..31
  final String formaPagamentoPadrao;
  final String cpfFuncionario;
  final String nomeFuncionario;
  final bool ativo;
  final DateTime dataCriacao;

  const GastoFixo({
    required this.id,
    required this.descricao,
    required this.valor,
    this.recorrencia = TipoRecorrenciaGasto.diario,
    this.diasDaSemana = const [],
    this.diaDoMes,
    this.formaPagamentoPadrao = 'Dinheiro',
    this.cpfFuncionario = '',
    this.nomeFuncionario = '',
    this.ativo = true,
    required this.dataCriacao,
  });

  factory GastoFixo.novo({
    required String descricao,
    required double valor,
    TipoRecorrenciaGasto recorrencia = TipoRecorrenciaGasto.diario,
    List<int> diasDaSemana = const [],
    int? diaDoMes,
    String formaPagamentoPadrao = 'Dinheiro',
    String cpfFuncionario = '',
    String nomeFuncionario = '',
    bool ativo = true,
  }) {
    return GastoFixo(
      id: gerarIdUnico(),
      descricao: descricao,
      valor: valor,
      recorrencia: recorrencia,
      diasDaSemana: diasDaSemana,
      diaDoMes: diaDoMes,
      formaPagamentoPadrao: formaPagamentoPadrao,
      cpfFuncionario: cpfFuncionario,
      nomeFuncionario: nomeFuncionario,
      ativo: ativo,
      dataCriacao: DateTime.now(),
    );
  }

  GastoFixo copyWith({
    String? id,
    String? descricao,
    double? valor,
    TipoRecorrenciaGasto? recorrencia,
    List<int>? diasDaSemana,
    int? diaDoMes,
    String? formaPagamentoPadrao,
    String? cpfFuncionario,
    String? nomeFuncionario,
    bool? ativo,
    DateTime? dataCriacao,
  }) {
    return GastoFixo(
      id: id ?? this.id,
      descricao: descricao ?? this.descricao,
      valor: valor ?? this.valor,
      recorrencia: recorrencia ?? this.recorrencia,
      diasDaSemana: diasDaSemana ?? this.diasDaSemana,
      diaDoMes: diaDoMes ?? this.diaDoMes,
      formaPagamentoPadrao: formaPagamentoPadrao ?? this.formaPagamentoPadrao,
      cpfFuncionario: cpfFuncionario ?? this.cpfFuncionario,
      nomeFuncionario: nomeFuncionario ?? this.nomeFuncionario,
      ativo: ativo ?? this.ativo,
      dataCriacao: dataCriacao ?? this.dataCriacao,
    );
  }

  bool seAplicaAData(DateTime data) {
    if (!ativo) return false;
    switch (recorrencia) {
      case TipoRecorrenciaGasto.diario:
        return true;
      case TipoRecorrenciaGasto.semanal:
        return data.weekday == (diasDaSemana.isNotEmpty ? diasDaSemana.first : dataCriacao.weekday);
      case TipoRecorrenciaGasto.mensal:
        final diaAlvo = diaDoMes ?? dataCriacao.day;
        return data.day == diaAlvo;
      case TipoRecorrenciaGasto.diasAlternados:
        final diferencaDias = data.difference(DateTime(dataCriacao.year, dataCriacao.month, dataCriacao.day)).inDays;
        return diferencaDias % 2 == 0;
      case TipoRecorrenciaGasto.diasDaSemana:
        return diasDaSemana.contains(data.weekday);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descricao': descricao,
      'valor': valor,
      'recorrencia': recorrencia.name,
      'diasDaSemana': diasDaSemana,
      if (diaDoMes != null) 'diaDoMes': diaDoMes,
      'formaPagamentoPadrao': formaPagamentoPadrao,
      'cpfFuncionario': cpfFuncionario,
      'nomeFuncionario': nomeFuncionario,
      'ativo': ativo,
      'dataCriacao': dataCriacao.toIso8601String(),
    };
  }

  factory GastoFixo.fromJson(Map<String, dynamic> json) {
    final recNome = json['recorrencia'] as String? ?? 'diario';
    final recorrencia = TipoRecorrenciaGasto.values.firstWhere(
      (r) => r.name == recNome,
      orElse: () => TipoRecorrenciaGasto.diario,
    );

    final diasSemanaJson = json['diasDaSemana'] as List<dynamic>? ?? const [];
    final diasDaSemana = diasSemanaJson.map((e) => (e as num).toInt()).toList();

    return GastoFixo(
      id: json['id'] as String? ?? '',
      descricao: json['descricao'] as String? ?? '',
      valor: (json['valor'] as num?)?.toDouble() ?? 0.0,
      recorrencia: recorrencia,
      diasDaSemana: diasDaSemana,
      diaDoMes: (json['diaDoMes'] as num?)?.toInt(),
      formaPagamentoPadrao: json['formaPagamentoPadrao'] as String? ?? 'Dinheiro',
      cpfFuncionario: json['cpfFuncionario'] as String? ?? '',
      nomeFuncionario: json['nomeFuncionario'] as String? ?? '',
      ativo: json['ativo'] as bool? ?? true,
      dataCriacao: json['dataCriacao'] != null
          ? DateTime.tryParse(json['dataCriacao'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
