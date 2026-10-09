import 'package:nous/src/core/services/gerador_id.dart';

enum StatusTurnoCaixa { aberto, fechado }

enum TipoMovimentoCaixa { sangria, suprimento }

class MovimentoCaixa {
  final String id;
  final DateTime dataHora;
  final TipoMovimentoCaixa tipo;
  final double valor;
  final String motivo;
  final String autorCpf;
  final String autorNome;

  const MovimentoCaixa({
    required this.id,
    required this.dataHora,
    required this.tipo,
    required this.valor,
    this.motivo = '',
    this.autorCpf = '',
    this.autorNome = '',
  });

  factory MovimentoCaixa.novo({
    required TipoMovimentoCaixa tipo,
    required double valor,
    String motivo = '',
    String autorCpf = '',
    String autorNome = '',
  }) {
    return MovimentoCaixa(
      id: gerarIdUnico(),
      dataHora: DateTime.now(),
      tipo: tipo,
      valor: valor,
      motivo: motivo,
      autorCpf: autorCpf,
      autorNome: autorNome,
    );
  }

  MovimentoCaixa copyWith({
    String? id,
    DateTime? dataHora,
    TipoMovimentoCaixa? tipo,
    double? valor,
    String? motivo,
    String? autorCpf,
    String? autorNome,
  }) {
    return MovimentoCaixa(
      id: id ?? this.id,
      dataHora: dataHora ?? this.dataHora,
      tipo: tipo ?? this.tipo,
      valor: valor ?? this.valor,
      motivo: motivo ?? this.motivo,
      autorCpf: autorCpf ?? this.autorCpf,
      autorNome: autorNome ?? this.autorNome,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dataHora': dataHora.toIso8601String(),
      'tipo': tipo.name,
      'valor': valor,
      'motivo': motivo,
      'autorCpf': autorCpf,
      'autorNome': autorNome,
    };
  }

  factory MovimentoCaixa.fromJson(Map<String, dynamic> json) {
    final tipoNome = json['tipo'] as String?;
    final tipo = TipoMovimentoCaixa.values.firstWhere(
      (t) => t.name == tipoNome,
      orElse: () => TipoMovimentoCaixa.sangria,
    );
    final dataStr = json['dataHora'] as String?;
    final data = dataStr != null ? DateTime.tryParse(dataStr) : null;

    return MovimentoCaixa(
      id: json['id'] as String? ?? '',
      dataHora: data ?? DateTime.now(),
      tipo: tipo,
      valor: (json['valor'] as num?)?.toDouble() ?? 0.0,
      motivo: json['motivo'] as String? ?? '',
      autorCpf: json['autorCpf'] as String? ?? '',
      autorNome: json['autorNome'] as String? ?? '',
    );
  }
}

class TurnoCaixa {
  final String id;
  final DateTime dataAbertura;
  final DateTime? dataFechamento;
  final String abertoPorCpf;
  final String abertoPorNome;
  final String fechadoPorCpf;
  final String fechadoPorNome;
  final double saldoInicial;
  final double? saldoFinalInformado;
  final List<MovimentoCaixa> movimentacoes;
  final StatusTurnoCaixa status;
  final String observacao;

  const TurnoCaixa({
    required this.id,
    required this.dataAbertura,
    this.dataFechamento,
    this.abertoPorCpf = '',
    this.abertoPorNome = '',
    this.fechadoPorCpf = '',
    this.fechadoPorNome = '',
    this.saldoInicial = 0.0,
    this.saldoFinalInformado,
    this.movimentacoes = const [],
    this.status = StatusTurnoCaixa.aberto,
    this.observacao = '',
  });

  factory TurnoCaixa.abrir({
    required double saldoInicial,
    String abertoPorCpf = '',
    String abertoPorNome = '',
  }) {
    return TurnoCaixa(
      id: gerarIdUnico(),
      dataAbertura: DateTime.now(),
      abertoPorCpf: abertoPorCpf,
      abertoPorNome: abertoPorNome,
      saldoInicial: saldoInicial,
      status: StatusTurnoCaixa.aberto,
    );
  }

  bool get aberto => status == StatusTurnoCaixa.aberto;

  double get totalSangrias {
    return movimentacoes
        .where((m) => m.tipo == TipoMovimentoCaixa.sangria)
        .fold(0.0, (soma, m) => soma + m.valor);
  }

  double get totalSuprimentos {
    return movimentacoes
        .where((m) => m.tipo == TipoMovimentoCaixa.suprimento)
        .fold(0.0, (soma, m) => soma + m.valor);
  }

  TurnoCaixa copyWith({
    String? id,
    DateTime? dataAbertura,
    DateTime? dataFechamento,
    String? abertoPorCpf,
    String? abertoPorNome,
    String? fechadoPorCpf,
    String? fechadoPorNome,
    double? saldoInicial,
    double? saldoFinalInformado,
    List<MovimentoCaixa>? movimentacoes,
    StatusTurnoCaixa? status,
    String? observacao,
  }) {
    return TurnoCaixa(
      id: id ?? this.id,
      dataAbertura: dataAbertura ?? this.dataAbertura,
      dataFechamento: dataFechamento ?? this.dataFechamento,
      abertoPorCpf: abertoPorCpf ?? this.abertoPorCpf,
      abertoPorNome: abertoPorNome ?? this.abertoPorNome,
      fechadoPorCpf: fechadoPorCpf ?? this.fechadoPorCpf,
      fechadoPorNome: fechadoPorNome ?? this.fechadoPorNome,
      saldoInicial: saldoInicial ?? this.saldoInicial,
      saldoFinalInformado: saldoFinalInformado ?? this.saldoFinalInformado,
      movimentacoes: movimentacoes ?? this.movimentacoes,
      status: status ?? this.status,
      observacao: observacao ?? this.observacao,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dataAbertura': dataAbertura.toIso8601String(),
      'dataFechamento': dataFechamento?.toIso8601String(),
      'abertoPorCpf': abertoPorCpf,
      'abertoPorNome': abertoPorNome,
      'fechadoPorCpf': fechadoPorCpf,
      'fechadoPorNome': fechadoPorNome,
      'saldoInicial': saldoInicial,
      'saldoFinalInformado': saldoFinalInformado,
      'movimentacoes': movimentacoes.map((m) => m.toJson()).toList(),
      'status': status.name,
      'observacao': observacao,
    };
  }

  factory TurnoCaixa.fromJson(Map<String, dynamic> json) {
    final statusNome = json['status'] as String?;
    final status = StatusTurnoCaixa.values.firstWhere(
      (s) => s.name == statusNome,
      orElse: () => StatusTurnoCaixa.aberto,
    );
    final dataAberturaStr = json['dataAbertura'] as String?;
    final dataAbertura = dataAberturaStr != null
        ? (DateTime.tryParse(dataAberturaStr) ?? DateTime.now())
        : DateTime.now();
    final dataFechamentoStr = json['dataFechamento'] as String?;
    final dataFechamento = dataFechamentoStr != null
        ? DateTime.tryParse(dataFechamentoStr)
        : null;

    final movsJson = json['movimentacoes'] as List<dynamic>? ?? const [];
    final movimentacoes = movsJson
        .map((m) => MovimentoCaixa.fromJson(m as Map<String, dynamic>))
        .toList();

    return TurnoCaixa(
      id: json['id'] as String? ?? '',
      dataAbertura: dataAbertura,
      dataFechamento: dataFechamento,
      abertoPorCpf: json['abertoPorCpf'] as String? ?? '',
      abertoPorNome: json['abertoPorNome'] as String? ?? '',
      fechadoPorCpf: json['fechadoPorCpf'] as String? ?? '',
      fechadoPorNome: json['fechadoPorNome'] as String? ?? '',
      saldoInicial: (json['saldoInicial'] as num?)?.toDouble() ?? 0.0,
      saldoFinalInformado: (json['saldoFinalInformado'] as num?)?.toDouble(),
      movimentacoes: movimentacoes,
      status: status,
      observacao: json['observacao'] as String? ?? '',
    );
  }
}
