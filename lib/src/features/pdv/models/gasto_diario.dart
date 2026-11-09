import 'package:nous/src/core/services/gerador_id.dart';

/// Registro de gastos operacionais diários declarados pelo lojista (ex: carnes, feira,
/// insumos avulsos do dia) sem necessidade de cadastro individual no Kardex de estoque.
class GastoDiario {
  final String id;
  final DateTime dataHora;
  final double valor;
  final String descricao;
  final String autorNome;
  final String autorCpf;
  final String formaPagamento;
  final bool pago;

  const GastoDiario({
    required this.id,
    required this.dataHora,
    required this.valor,
    this.descricao = '',
    this.autorNome = '',
    this.autorCpf = '',
    this.formaPagamento = 'Dinheiro',
    this.pago = true,
  });

  factory GastoDiario.novo({
    required double valor,
    DateTime? dataHora,
    String descricao = '',
    String autorNome = '',
    String autorCpf = '',
    String formaPagamento = 'Dinheiro',
    bool pago = true,
  }) {
    return GastoDiario(
      id: gerarIdUnico(),
      dataHora: dataHora ?? DateTime.now(),
      valor: valor,
      descricao: descricao,
      autorNome: autorNome,
      autorCpf: autorCpf,
      formaPagamento: formaPagamento,
      pago: pago,
    );
  }

  GastoDiario copyWith({
    String? id,
    DateTime? dataHora,
    double? valor,
    String? descricao,
    String? autorNome,
    String? autorCpf,
    String? formaPagamento,
    bool? pago,
  }) {
    return GastoDiario(
      id: id ?? this.id,
      dataHora: dataHora ?? this.dataHora,
      valor: valor ?? this.valor,
      descricao: descricao ?? this.descricao,
      autorNome: autorNome ?? this.autorNome,
      autorCpf: autorCpf ?? this.autorCpf,
      formaPagamento: formaPagamento ?? this.formaPagamento,
      pago: pago ?? this.pago,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dataHora': dataHora.toIso8601String(),
      'valor': valor,
      'descricao': descricao,
      'autorNome': autorNome,
      'autorCpf': autorCpf,
      'formaPagamento': formaPagamento,
      'pago': pago,
    };
  }

  factory GastoDiario.fromJson(Map<String, dynamic> json) {
    final dataStr = json['dataHora'] as String?;
    final data = dataStr != null ? DateTime.tryParse(dataStr) : null;
    return GastoDiario(
      id: json['id'] as String? ?? '',
      dataHora: data ?? DateTime.now(),
      valor: (json['valor'] as num?)?.toDouble() ?? 0.0,
      descricao: json['descricao'] as String? ?? '',
      autorNome: json['autorNome'] as String? ?? '',
      autorCpf: json['autorCpf'] as String? ?? '',
      formaPagamento: json['formaPagamento'] as String? ?? 'Dinheiro',
      pago: json['pago'] as bool? ?? true,
    );
  }
}
