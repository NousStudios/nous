enum StatusPedido { novo, aceito, concluido }

class DadosComentario {
  final String texto;
  final String cpfAutor;
  final String nomeAutor;
  final String emailAutor;
  final DateTime dataHora;

  const DadosComentario({
    required this.texto,
    required this.cpfAutor,
    required this.nomeAutor,
    required this.emailAutor,
    required this.dataHora,
  });
}

class PagamentoParcial {
  final String forma;
  final double valor;

  const PagamentoParcial({
    required this.forma,
    required this.valor,
  });

  PagamentoParcial copyWith({String? forma, double? valor}) {
    return PagamentoParcial(
      forma: forma ?? this.forma,
      valor: valor ?? this.valor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'forma': forma,
      'valor': valor,
    };
  }

  factory PagamentoParcial.fromJson(Map<String, dynamic> json) {
    return PagamentoParcial(
      forma: json['forma'] as String? ?? '',
      valor: (json['valor'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AcompanhamentoEscolhido {
  final String itemId;
  final String nomeItem;
  final double precoItem;
  final int quantidadePorUnidade;

  const AcompanhamentoEscolhido({
    required this.itemId,
    required this.nomeItem,
    required this.precoItem,
    required this.quantidadePorUnidade,
  });

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'nomeItem': nomeItem,
      'precoItem': precoItem,
      'quantidadePorUnidade': quantidadePorUnidade,
    };
  }

  factory AcompanhamentoEscolhido.fromJson(Map<String, dynamic> json) {
    return AcompanhamentoEscolhido(
      itemId: json['itemId'] as String,
      nomeItem: json['nomeItem'] as String,
      precoItem: (json['precoItem'] as num).toDouble(),
      quantidadePorUnidade: json['quantidadePorUnidade'] as int,
    );
  }
}

class ItemVendido {
  final String itemId;
  final String nomeItem;
  final String? categoriaId;
  final String? nomeCategoria;
  final double precoItem;
  final double precoCategoria;
  final int quantidade;
  final List<AcompanhamentoEscolhido> acompanhamentos;
  final String observacao;

  const ItemVendido({
    required this.itemId,
    required this.nomeItem,
    this.categoriaId,
    this.nomeCategoria,
    required this.precoItem,
    this.precoCategoria = 0,
    required this.quantidade,
    this.acompanhamentos = const [],
    this.observacao = '',
  });

  double get totalDosAcompanhamentosPorUnidade => acompanhamentos.fold<double>(
        0,
        (soma, a) => soma + (a.precoItem * a.quantidadePorUnidade),
      );

  double get precoBase => precoItem + precoCategoria;

  double get subtotalBase => precoBase * quantidade;

  double get precoUnitario =>
      precoBase + totalDosAcompanhamentosPorUnidade;

  double get subtotal => precoUnitario * quantidade;

  double get subtotalDosAcompanhamentos =>
      totalDosAcompanhamentosPorUnidade * quantidade;

  String get nomeExibicao {
    if (nomeCategoria == null || nomeCategoria!.isEmpty) return nomeItem;
    return '$nomeCategoria $nomeItem';
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'nomeItem': nomeItem,
      'categoriaId': categoriaId,
      'nomeCategoria': nomeCategoria,
      'precoItem': precoItem,
      'precoCategoria': precoCategoria,
      'quantidade': quantidade,
      'acompanhamentos': acompanhamentos.map((a) => a.toJson()).toList(),
      'observacao': observacao,
    };
  }

  factory ItemVendido.fromJson(Map<String, dynamic> json) {
    return ItemVendido(
      itemId: json['itemId'] as String,
      nomeItem: json['nomeItem'] as String,
      categoriaId: json['categoriaId'] as String?,
      nomeCategoria: json['nomeCategoria'] as String?,
      precoItem: (json['precoItem'] as num).toDouble(),
      precoCategoria: (json['precoCategoria'] as num?)?.toDouble() ?? 0,
      quantidade: json['quantidade'] as int,
      acompanhamentos: (json['acompanhamentos'] as List<dynamic>? ?? const [])
          .map((a) =>
              AcompanhamentoEscolhido.fromJson(a as Map<String, dynamic>))
          .toList(),
      observacao: json['observacao'] as String? ?? '',
    );
  }
}

class PedidoLoja {
  final String id;
  final int numero;
  final String? clienteId;
  final String clienteNome;
  final String produtoNome;
  final DateTime dataHora;
  final double valor;
  final bool temMensagem;
  final StatusPedido status;
  final String comanda;
  final String formaPagamento;
  final List<PagamentoParcial> pagamentosExtras;
  final bool quitado;
  final double valorPago;
  final double valorRecebido;
  final double troco;
  final List<ItemVendido> itens;
  final double frete;
  final double desconto;
  final double acrescimo;
  final String nomeVendedor;
  final String cnpjVendedor;
  final String comentario;
  final String comentarioAutorCpf;
  final String comentarioAutorNome;
  final String comentarioAutorEmail;
  final DateTime? comentarioDataHora;

  const PedidoLoja({
    required this.id,
    required this.numero,
    this.clienteId,
    required this.clienteNome,
    required this.produtoNome,
    required this.dataHora,
    required this.valor,
    this.temMensagem = false,
    this.status = StatusPedido.novo,
    this.comanda = '',
    this.formaPagamento = '',
    this.pagamentosExtras = const [],
    this.quitado = false,
    this.valorPago = 0,
    this.valorRecebido = 0,
    this.troco = 0,
    this.itens = const [],
    this.frete = 0,
    this.desconto = 0,
    this.acrescimo = 0,
    this.nomeVendedor = '',
    this.cnpjVendedor = '',
    this.comentario = '',
    this.comentarioAutorCpf = '',
    this.comentarioAutorNome = '',
    this.comentarioAutorEmail = '',
    this.comentarioDataHora,
  });

  List<PagamentoParcial> get todosPagamentos {
    if (pagamentosExtras.isNotEmpty) return pagamentosExtras;
    if (formaPagamento.isEmpty) return const [];
    return [PagamentoParcial(forma: formaPagamento, valor: valor)];
  }

  bool get temAPrazo =>
      todosPagamentos.any((p) => p.forma == 'À Prazo');

  bool get aPrazoEmAberto => temAPrazo && !quitado;

  double get valorRestante {
    final restante = valor - valorPago;
    return restante < 0 ? 0 : restante;
  }

  PedidoLoja copyWith({
    bool? temMensagem,
    StatusPedido? status,
    String? comanda,
    bool? quitado,
    double? valorPago,
    String? comentario,
    String? comentarioAutorCpf,
    String? comentarioAutorNome,
    String? comentarioAutorEmail,
    DateTime? comentarioDataHora,
    bool limparComentario = false,
  }) {
    return PedidoLoja(
      id: id,
      numero: numero,
      clienteId: clienteId,
      clienteNome: clienteNome,
      produtoNome: produtoNome,
      dataHora: dataHora,
      valor: valor,
      temMensagem: temMensagem ?? this.temMensagem,
      status: status ?? this.status,
      comanda: comanda ?? this.comanda,
      formaPagamento: formaPagamento,
      pagamentosExtras: pagamentosExtras,
      quitado: quitado ?? this.quitado,
      valorPago: valorPago ?? this.valorPago,
      valorRecebido: valorRecebido,
      troco: troco,
      itens: itens,
      frete: frete,
      desconto: desconto,
      acrescimo: acrescimo,
      nomeVendedor: nomeVendedor,
      cnpjVendedor: cnpjVendedor,
      comentario: comentario ?? this.comentario,
      comentarioAutorCpf: comentarioAutorCpf ?? this.comentarioAutorCpf,
      comentarioAutorNome: comentarioAutorNome ?? this.comentarioAutorNome,
      comentarioAutorEmail: comentarioAutorEmail ?? this.comentarioAutorEmail,
      comentarioDataHora: comentarioDataHora ?? this.comentarioDataHora,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero': numero,
      'clienteId': clienteId,
      'clienteNome': clienteNome,
      'produtoNome': produtoNome,
      'dataHora': dataHora.toIso8601String(),
      'valor': valor,
      'temMensagem': temMensagem,
      'status': status.name,
      'comanda': comanda,
      'formaPagamento': formaPagamento,
      'pagamentosExtras': pagamentosExtras.map((p) => p.toJson()).toList(),
      'quitado': quitado,
      'valorPago': valorPago,
      'valorRecebido': valorRecebido,
      'troco': troco,
      'itens': itens.map((i) => i.toJson()).toList(),
      'frete': frete,
      'desconto': desconto,
      'acrescimo': acrescimo,
      'nomeVendedor': nomeVendedor,
      'cnpjVendedor': cnpjVendedor,
      'comentario': comentario,
      'comentarioAutorCpf': comentarioAutorCpf,
      'comentarioAutorNome': comentarioAutorNome,
      'comentarioAutorEmail': comentarioAutorEmail,
      'comentarioDataHora': comentarioDataHora?.toIso8601String(),
    };
  }

  factory PedidoLoja.fromJson(Map<String, dynamic> json) {
    final dataHoraComentario = json['comentarioDataHora'] as String?;
    return PedidoLoja(
      id: json['id'] as String,
      numero: json['numero'] as int,
      clienteId: json['clienteId'] as String?,
      clienteNome: json['clienteNome'] as String,
      produtoNome: json['produtoNome'] as String,
      dataHora: DateTime.parse(json['dataHora'] as String),
      valor: (json['valor'] as num).toDouble(),
      temMensagem: json['temMensagem'] as bool? ?? false,
      status: StatusPedido.values.byName(json['status'] as String),
      comanda: json['comanda'] as String? ?? '',
      formaPagamento: json['formaPagamento'] as String? ?? '',
      pagamentosExtras:
          (json['pagamentosExtras'] as List<dynamic>? ?? const [])
              .map((p) => PagamentoParcial.fromJson(p as Map<String, dynamic>))
              .toList(),
      quitado: json['quitado'] as bool? ?? false,
      valorPago: (json['valorPago'] as num?)?.toDouble() ?? 0,
      valorRecebido: (json['valorRecebido'] as num?)?.toDouble() ?? 0,
      troco: (json['troco'] as num?)?.toDouble() ?? 0,
      itens: (json['itens'] as List<dynamic>? ?? const [])
          .map((i) => ItemVendido.fromJson(i as Map<String, dynamic>))
          .toList(),
      frete: (json['frete'] as num?)?.toDouble() ?? 0,
      desconto: (json['desconto'] as num?)?.toDouble() ?? 0,
      acrescimo: (json['acrescimo'] as num?)?.toDouble() ?? 0,
      nomeVendedor: json['nomeVendedor'] as String? ?? '',
      cnpjVendedor: json['cnpjVendedor'] as String? ?? '',
      comentario: json['comentario'] as String? ?? '',
      comentarioAutorCpf: json['comentarioAutorCpf'] as String? ?? '',
      comentarioAutorNome: json['comentarioAutorNome'] as String? ?? '',
      comentarioAutorEmail: json['comentarioAutorEmail'] as String? ?? '',
      comentarioDataHora: dataHoraComentario == null
          ? null
          : DateTime.tryParse(dataHoraComentario),
    );
  }
}

List<PedidoLoja> aplicarPagamentoAPrazo(
  List<PedidoLoja> pedidos,
  String clienteId,
  double valor,
) {
  final abertos = pedidos
      .where((p) => p.clienteId == clienteId && p.aPrazoEmAberto)
      .toList();
  abertos.sort((a, b) => a.dataHora.compareTo(b.dataHora));

  var restante = valor;
  final atualizados = <String, PedidoLoja>{};

  for (final pedido in abertos) {
    if (restante <= 0.0001) break;
    final falta = pedido.valorRestante;
    if (restante >= falta - 0.005) {
      atualizados[pedido.id] =
          pedido.copyWith(quitado: true, valorPago: pedido.valor);
      restante -= falta;
    } else {
      atualizados[pedido.id] =
          pedido.copyWith(valorPago: pedido.valorPago + restante);
      restante = 0;
    }
  }

  return pedidos.map((p) => atualizados[p.id] ?? p).toList();
}