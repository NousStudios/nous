import 'package:nous/src/core/services/gerador_id.dart';

enum TipoMovimentoEstoque { entrada, saida }

class MovimentoEstoque {
  final String id;
  final String itemId;
  final TipoMovimentoEstoque tipo;
  final int quantidade;
  final double custoUnitario;
  final DateTime dataHora;
  final String motivo;
  final String cpfAutor;
  final String nomeAutor;

  const MovimentoEstoque({
    required this.id,
    required this.itemId,
    required this.tipo,
    required this.quantidade,
    this.custoUnitario = 0,
    required this.dataHora,
    this.motivo = '',
    this.cpfAutor = '',
    this.nomeAutor = '',
  });

  factory MovimentoEstoque.novo({
    required String itemId,
    required TipoMovimentoEstoque tipo,
    required int quantidade,
    double custoUnitario = 0,
    String motivo = '',
    String cpfAutor = '',
    String nomeAutor = '',
  }) {
    return MovimentoEstoque(
      id: gerarIdUnico(),
      itemId: itemId,
      tipo: tipo,
      quantidade: quantidade,
      custoUnitario: custoUnitario,
      dataHora: DateTime.now(),
      motivo: motivo,
      cpfAutor: cpfAutor,
      nomeAutor: nomeAutor,
    );
  }

  bool get ehEntrada => tipo == TipoMovimentoEstoque.entrada;

  int get quantidadeComSinal => ehEntrada ? quantidade : -quantidade;

  double get custoTotal => custoUnitario * quantidade;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'tipo': tipo.name,
      'quantidade': quantidade,
      'custoUnitario': custoUnitario,
      'dataHora': dataHora.toIso8601String(),
      'motivo': motivo,
      'cpfAutor': cpfAutor,
      'nomeAutor': nomeAutor,
    };
  }

  factory MovimentoEstoque.fromJson(Map<String, dynamic> json) {
    return MovimentoEstoque(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      tipo: TipoMovimentoEstoque.values.byName(json['tipo'] as String),
      quantidade: json['quantidade'] as int,
      custoUnitario: (json['custoUnitario'] as num?)?.toDouble() ?? 0,
      dataHora: DateTime.parse(json['dataHora'] as String),
      motivo: json['motivo'] as String? ?? '',
      cpfAutor: json['cpfAutor'] as String? ?? '',
      nomeAutor: json['nomeAutor'] as String? ?? '',
    );
  }
}