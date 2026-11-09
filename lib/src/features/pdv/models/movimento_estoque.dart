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
  final String formaPagamento;
  final bool pago;

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
    this.formaPagamento = '',
    this.pago = true,
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
    String formaPagamento = '',
    bool pago = true,
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
      formaPagamento: formaPagamento,
      pago: pago,
    );
  }

  MovimentoEstoque copyWith({
    String? id,
    String? itemId,
    TipoMovimentoEstoque? tipo,
    double? quantidade,
    double? custoUnitario,
    DateTime? dataHora,
    String? motivo,
    String? cpfAutor,
    String? nomeAutor,
    String? fornecedorId,
    String? fornecedorNome,
    CategoriaMovimentoEstoque? categoria,
    String? formaPagamento,
    bool? pago,
  }) {
    return MovimentoEstoque(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      tipo: tipo ?? this.tipo,
      quantidade: quantidade ?? this.quantidade,
      custoUnitario: custoUnitario ?? this.custoUnitario,
      dataHora: dataHora ?? this.dataHora,
      motivo: motivo ?? this.motivo,
      cpfAutor: cpfAutor ?? this.cpfAutor,
      nomeAutor: nomeAutor ?? this.nomeAutor,
      fornecedorId: fornecedorId ?? this.fornecedorId,
      fornecedorNome: fornecedorNome ?? this.fornecedorNome,
      categoria: categoria ?? this.categoria,
      formaPagamento: formaPagamento ?? this.formaPagamento,
      pago: pago ?? this.pago,
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
      'formaPagamento': formaPagamento,
      'pago': pago,
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
      id: json['id'] as String? ?? '',
      itemId: json['itemId'] as String? ?? '',
      tipo: TipoMovimentoEstoque.values.byName(json['tipo'] as String? ?? 'entrada'),
      quantidade: (json['quantidade'] as num?)?.toDouble() ?? 0,
      custoUnitario: (json['custoUnitario'] as num?)?.toDouble() ?? 0,
      dataHora: json['dataHora'] != null
          ? DateTime.tryParse(json['dataHora'] as String) ?? DateTime.now()
          : DateTime.now(),
      motivo: json['motivo'] as String? ?? '',
      cpfAutor: json['cpfAutor'] as String? ?? '',
      nomeAutor: json['nomeAutor'] as String? ?? '',
      fornecedorId: json['fornecedorId'] as String? ?? '',
      fornecedorNome: json['fornecedorNome'] as String? ?? '',
      categoria: categoria,
      formaPagamento: json['formaPagamento'] as String? ?? '',
      pago: json['pago'] as bool? ?? true,
    );
  }
}
