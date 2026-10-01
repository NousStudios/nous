import 'package:nous/src/core/services/gerador_id.dart';

enum TipoMovimentoEstoque { entrada, saida }

enum CategoriaMovimentoEstoque { compra, venda, ajuste, perda, producao }

class MovimentoEstoque {
  final String id;
  final String itemId;
  final TipoMovimentoEstoque tipo;
  final double quantidade;
  final double custoUnitario;
  final DateTime dataHora;
  final String motivo;
  final String cpfAutor;
  final String nomeAutor;
  final String fornecedorId;
  final String fornecedorNome;
  final CategoriaMovimentoEstoque categoria;

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
    this.fornecedorId = '',
    this.fornecedorNome = '',
    this.categoria = CategoriaMovimentoEstoque.ajuste,
  });

  factory MovimentoEstoque.novo({
    required String itemId,
    required TipoMovimentoEstoque tipo,
    required double quantidade,
    double custoUnitario = 0,
    String motivo = '',
    String cpfAutor = '',
    String nomeAutor = '',
    String fornecedorId = '',
    String fornecedorNome = '',
    CategoriaMovimentoEstoque categoria = CategoriaMovimentoEstoque.ajuste,
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
      fornecedorId: fornecedorId,
      fornecedorNome: fornecedorNome,
      categoria: categoria,
    );
  }

  bool get ehEntrada => tipo == TipoMovimentoEstoque.entrada;

  double get quantidadeComSinal => ehEntrada ? quantidade : -quantidade;

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
      'fornecedorId': fornecedorId,
      'fornecedorNome': fornecedorNome,
      'categoria': categoria.name,
    };
  }

  factory MovimentoEstoque.fromJson(Map<String, dynamic> json) {
    final categoriaTexto = json['categoria'] as String?;
    final categoria = categoriaTexto == null
        ? CategoriaMovimentoEstoque.ajuste
        : CategoriaMovimentoEstoque.values.firstWhere(
            (c) => c.name == categoriaTexto,
            orElse: () => CategoriaMovimentoEstoque.ajuste,
          );
    return MovimentoEstoque(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      tipo: TipoMovimentoEstoque.values.byName(json['tipo'] as String),
      quantidade: (json['quantidade'] as num?)?.toDouble() ?? 0,
      custoUnitario: (json['custoUnitario'] as num?)?.toDouble() ?? 0,
      dataHora: DateTime.parse(json['dataHora'] as String),
      motivo: json['motivo'] as String? ?? '',
      cpfAutor: json['cpfAutor'] as String? ?? '',
      nomeAutor: json['nomeAutor'] as String? ?? '',
      fornecedorId: json['fornecedorId'] as String? ?? '',
      fornecedorNome: json['fornecedorNome'] as String? ?? '',
      categoria: categoria,
    );
  }
}