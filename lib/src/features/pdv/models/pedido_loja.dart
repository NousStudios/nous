enum StatusPedido { novo, aceito, concluido }

class PedidoLoja {
  final String id;
  final int numero;
  final String clienteNome;
  final String produtoNome;
  final DateTime dataHora;
  final double valor;
  final bool temMensagem;
  final StatusPedido status;

  const PedidoLoja({
    required this.id,
    required this.numero,
    required this.clienteNome,
    required this.produtoNome,
    required this.dataHora,
    required this.valor,
    this.temMensagem = false,
    this.status = StatusPedido.novo,
  });

  PedidoLoja copyWith({
    bool? temMensagem,
    StatusPedido? status,
  }) {
    return PedidoLoja(
      id: id,
      numero: numero,
      clienteNome: clienteNome,
      produtoNome: produtoNome,
      dataHora: dataHora,
      valor: valor,
      temMensagem: temMensagem ?? this.temMensagem,
      status: status ?? this.status,
    );
  }
}