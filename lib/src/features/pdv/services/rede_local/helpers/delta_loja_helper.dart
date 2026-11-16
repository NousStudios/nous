import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';

/// Compacta o objeto [Loja] para transmissões contínuas de atualização (`loja_atualizada`),
/// evitando o tráfego de "Big Blob" com milhares de registros históricos antigos.
///
/// Como `LojasService.consolidarLojaComImagensLocais(..., manterItensAusentes: true)`
/// preserva localmente o histórico ausente, enviar apenas os registros ativos e os
/// mais recentes reduz drasticamente o consumo de banda (especialmente em 4G/internet)
/// sem perda de dados históricos.
class DeltaLojaHelper {
  DeltaLojaHelper._();

  static const int limitePedidosRecentes = 30;
  static const int limiteMovimentosRecentes = 50;
  static const int limiteAcoesRecentes = 30;
  static const int limiteTurnosFechadosRecentes = 5;
  static const int limitePagamentosRecentes = 30;

  static Loja compactarParaRede(Loja loja) {
    // 1. Pedidos: mantém todos os ativos / a prazo em aberto + últimos N concluídos/cancelados
    final pedidosAtivosOuEmAberto = <PedidoLoja>[];
    final pedidosHistorico = <PedidoLoja>[];
    for (final p in loja.pedidosLoja) {
      final ativo = p.status != StatusPedido.concluido &&
          p.status != StatusPedido.cancelado;
      if (ativo || p.aPrazoEmAberto) {
        pedidosAtivosOuEmAberto.add(p);
      } else {
        pedidosHistorico.add(p);
      }
    }
    pedidosHistorico.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    final pedidosCompactados = <PedidoLoja>[
      ...pedidosAtivosOuEmAberto,
      ...pedidosHistorico.take(limitePedidosRecentes),
    ]..sort((a, b) => b.dataHora.compareTo(a.dataHora));

    // 2. Movimentos de estoque recentes
    final movimentosOrdenados = List.of(loja.movimentosEstoque)
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));
    final movimentosCompactados =
        movimentosOrdenados.take(limiteMovimentosRecentes).toList();

    // 3. Ações de auditoria recentes
    final acoesOrdenadas = List.of(loja.acoes)
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));
    final acoesCompactadas = acoesOrdenadas.take(limiteAcoesRecentes).toList();

    // 4. Turnos de caixa: todos os abertos + últimos N fechados
    final turnosAbertos = loja.turnosCaixa.where((t) => t.aberto).toList();
    final turnosFechados = loja.turnosCaixa.where((t) => !t.aberto).toList()
      ..sort((a, b) => b.dataAbertura.compareTo(a.dataAbertura));
    final turnosCompactados = [
      ...turnosAbertos,
      ...turnosFechados.take(limiteTurnosFechadosRecentes),
    ];

    // 5. Pagamentos de funcionários recentes
    final pagamentosOrdenados = List.of(loja.pagamentosFuncionarios)
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));
    final pagamentosCompactados =
        pagamentosOrdenados.take(limitePagamentosRecentes).toList();

    return loja.copyWith(
      pedidosLoja: pedidosCompactados,
      movimentosEstoque: movimentosCompactados,
      acoes: acoesCompactadas,
      turnosCaixa: turnosCompactados,
      pagamentosFuncionarios: pagamentosCompactados,
    );
  }
}
