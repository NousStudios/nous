import 'package:nous/src/core/services/gerador_id.dart';

class PagamentoFuncionario {
  final String id;
  final String cpf;
  final String nome;
  final double valor;
  final DateTime dataHora;
  final String descricao;
  final String cpfAutor;
  final String nomeAutor;
  final String formaPagamento;
  final bool pago;

  const PagamentoFuncionario({
    required this.id,
    required this.cpf,
    required this.nome,
    required this.valor,
    required this.dataHora,
    this.descricao = '',
    this.cpfAutor = '',
    this.nomeAutor = '',
    this.formaPagamento = 'Dinheiro',
    this.pago = true,
  });

  factory PagamentoFuncionario.novo({
    required String cpf,
    required String nome,
    required double valor,
    String descricao = '',
    String cpfAutor = '',
    String nomeAutor = '',
    String formaPagamento = 'Dinheiro',
    bool pago = true,
  }) {
    return PagamentoFuncionario(
      id: gerarIdUnico(),
      cpf: cpf,
      nome: nome,
      valor: valor,
      dataHora: DateTime.now(),
      descricao: descricao,
      cpfAutor: cpfAutor,
      nomeAutor: nomeAutor,
      formaPagamento: formaPagamento,
      pago: pago,
    );
  }

  PagamentoFuncionario copyWith({
    String? id,
    String? cpf,
    String? nome,
    double? valor,
    DateTime? dataHora,
    String? descricao,
    String? cpfAutor,
    String? nomeAutor,
    String? formaPagamento,
    bool? pago,
  }) {
    return PagamentoFuncionario(
      id: id ?? this.id,
      cpf: cpf ?? this.cpf,
      nome: nome ?? this.nome,
      valor: valor ?? this.valor,
      dataHora: dataHora ?? this.dataHora,
      descricao: descricao ?? this.descricao,
      cpfAutor: cpfAutor ?? this.cpfAutor,
      nomeAutor: nomeAutor ?? this.nomeAutor,
      formaPagamento: formaPagamento ?? this.formaPagamento,
      pago: pago ?? this.pago,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cpf': cpf,
      'nome': nome,
      'valor': valor,
      'dataHora': dataHora.toIso8601String(),
      'descricao': descricao,
      'cpfAutor': cpfAutor,
      'nomeAutor': nomeAutor,
      'formaPagamento': formaPagamento,
      'pago': pago,
    };
  }

  factory PagamentoFuncionario.fromJson(Map<String, dynamic> json) {
    return PagamentoFuncionario(
      id: json['id'] as String? ?? '',
      cpf: json['cpf'] as String? ?? '',
      nome: json['nome'] as String? ?? '',
      valor: (json['valor'] as num?)?.toDouble() ?? 0.0,
      dataHora: json['dataHora'] != null
          ? DateTime.tryParse(json['dataHora'] as String) ?? DateTime.now()
          : DateTime.now(),
      descricao: json['descricao'] as String? ?? '',
      cpfAutor: json['cpfAutor'] as String? ?? '',
      nomeAutor: json['nomeAutor'] as String? ?? '',
      formaPagamento: json['formaPagamento'] as String? ?? 'Dinheiro',
      pago: json['pago'] as bool? ?? true,
    );
  }
}
