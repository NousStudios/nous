enum StatusPedido { novo, aceito, concluido }

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
  final bool quitado;
  final double valorPago;

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
    this.quitado = false,
    this.valorPago = 0,
  });

  bool get aPrazoEmAberto => formaPagamento == 'À Prazo' && !quitado;

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
      quitado: quitado ?? this.quitado,
      valorPago: valorPago ?? this.valorPago,
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
      'quitado': quitado,
      'valorPago': valorPago,
    };
  }

  factory PedidoLoja.fromJson(Map<String, dynamic> json) {
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
      quitado: json['quitado'] as bool? ?? false,
      valorPago: (json['valorPago'] as num?)?.toDouble() ?? 0,
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