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

  const PagamentoFuncionario({
    required this.id,
    required this.cpf,
    required this.nome,
    required this.valor,
    required this.dataHora,
    this.descricao = '',
    this.cpfAutor = '',
    this.nomeAutor = '',
  });

  factory PagamentoFuncionario.novo({
    required String cpf,
    required String nome,
    required double valor,
    String descricao = '',
    String cpfAutor = '',
    String nomeAutor = '',
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
    };
  }

  factory PagamentoFuncionario.fromJson(Map<String, dynamic> json) {
    return PagamentoFuncionario(
      id: json['id'] as String,
      cpf: json['cpf'] as String,
      nome: json['nome'] as String? ?? '',
      valor: (json['valor'] as num).toDouble(),
      dataHora: DateTime.parse(json['dataHora'] as String),
      descricao: json['descricao'] as String? ?? '',
      cpfAutor: json['cpfAutor'] as String? ?? '',
      nomeAutor: json['nomeAutor'] as String? ?? '',
    );
  }
}