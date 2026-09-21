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
  });

  bool get aPrazoEmAberto => formaPagamento == 'À Prazo' && !quitado;

  PedidoLoja copyWith({
    bool? temMensagem,
    StatusPedido? status,
    String? comanda,
    bool? quitado,
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
    );
  }
}