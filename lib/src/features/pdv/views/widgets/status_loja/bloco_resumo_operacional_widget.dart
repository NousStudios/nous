import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';

/// Card que exibe o resumo operacional e financeiro do dia da loja.
class BlocoResumoOperacionalWidget extends StatelessWidget {
  final String lojaId;
  final AppTheme theme;

  const BlocoResumoOperacionalWidget({
    super.key,
    required this.lojaId,
    required this.theme,
  });

  BoxDecoration _decoracaoDoBloco(AppTheme theme) {
    return BoxDecoration(
      color: theme.cardBackgroundColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: theme.borderColor),
    );
  }

  Widget _itemMetrica({
    required AppTheme theme,
    required IconData icone,
    required String rotulo,
    required String valor,
    bool destaque = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: destaque
              ? theme.textColor.withValues(alpha: 0.35)
              : theme.borderColor.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: 14, color: theme.secondaryTextColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  rotulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 11,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.getTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pdv = context.watch<PdvProvider>();
    final loja = pdv.buscarPorId(lojaId);
    if (loja == null) return const SizedBox.shrink();

    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);

    final pedidosHojeConcluidos = loja.pedidosLoja.where((p) {
      if (p.status != StatusPedido.concluido) return false;
      final dataPedido =
          DateTime(p.dataHora.year, p.dataHora.month, p.dataHora.day);
      return dataPedido == hoje;
    }).toList();

    final pedidosHojeEmAberto = loja.pedidosLoja.where((p) {
      if (p.status != StatusPedido.aceito && p.status != StatusPedido.novo) {
        return false;
      }
      final dataPedido =
          DateTime(p.dataHora.year, p.dataHora.month, p.dataHora.day);
      return dataPedido == hoje;
    }).toList();

    final totalVendasHoje = pedidosHojeConcluidos.length;
    final faturamentoHoje = pedidosHojeConcluidos.fold<double>(
      0.0,
      (soma, p) => soma + p.valor,
    );
    final totalEmAbertoHoje = pedidosHojeEmAberto.fold<double>(
      0.0,
      (soma, p) => soma + p.valor,
    );
    final ticketMedio =
        totalVendasHoje == 0 ? 0.0 : faturamentoHoje / totalVendasHoje;

    // Situação do caixa e saldo em dinheiro
    final turnoAberto = loja.turnosCaixa.where((t) => t.aberto).firstOrNull;
    final caixaAberto = turnoAberto != null;

    double saldoEmDinheiro = 0.0;
    if (turnoAberto != null) {
      double vendasDinheiroTurno = 0.0;
      for (final p in loja.pedidosLoja) {
        if (p.status == StatusPedido.cancelado) continue;
        if (p.dataHora.isAfter(turnoAberto.dataAbertura) ||
            p.dataHora.isAtSameMomentAs(turnoAberto.dataAbertura)) {
          if (p.pagamentosExtras.isNotEmpty) {
            for (final pag in p.todosPagamentos) {
              if (pag.forma.toLowerCase() == 'dinheiro') {
                vendasDinheiroTurno += pag.valor;
              }
            }
            vendasDinheiroTurno -= p.troco;
          } else {
            if (p.formaPagamento.toLowerCase() == 'dinheiro') {
              vendasDinheiroTurno += p.valor;
            }
          }
        }
      }
      if (vendasDinheiroTurno < 0) vendasDinheiroTurno = 0.0;
      saldoEmDinheiro = turnoAberto.saldoInicial +
          turnoAberto.totalSuprimentos -
          turnoAberto.totalSangrias +
          vendasDinheiroTurno;
      if (saldoEmDinheiro < 0) saldoEmDinheiro = 0.0;
    } else {
      final ultimoTurno =
          loja.turnosCaixa.isNotEmpty ? loja.turnosCaixa.last : null;
      if (ultimoTurno != null && ultimoTurno.saldoFinalInformado != null) {
        saldoEmDinheiro = ultimoTurno.saldoFinalInformado!;
      }
    }

    String moeda(double v) =>
        'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _decoracaoDoBloco(theme),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.dashboard_outlined, size: 20, color: theme.textColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Resumo Operacional do Dia',
                  style: theme.getTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: caixaAberto
                      ? theme.borderColor.withValues(alpha: 0.25)
                      : Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: caixaAberto ? theme.borderColor : Colors.redAccent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      caixaAberto ? Icons.lock_open : Icons.lock_outline,
                      size: 13,
                      color: caixaAberto ? theme.textColor : Colors.redAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      caixaAberto ? 'Caixa Aberto' : 'Caixa Fechado',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: caixaAberto ? theme.textColor : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _itemMetrica(
                  theme: theme,
                  icone: Icons.attach_money,
                  rotulo: 'Faturamento',
                  valor: moeda(faturamentoHoje),
                  destaque: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _itemMetrica(
                  theme: theme,
                  icone: Icons.receipt_long_outlined,
                  rotulo: 'Vendas Hoje',
                  valor: '$totalVendasHoje',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _itemMetrica(
                  theme: theme,
                  icone: Icons.trending_up,
                  rotulo: 'Ticket Médio',
                  valor: moeda(ticketMedio),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _itemMetrica(
                  theme: theme,
                  icone: Icons.point_of_sale_outlined,
                  rotulo: 'Saldo Caixa (Dinheiro)',
                  valor: moeda(saldoEmDinheiro),
                ),
              ),
            ],
          ),
          if (pedidosHojeEmAberto.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'A receber hoje (${pedidosHojeEmAberto.length} ${pedidosHojeEmAberto.length == 1 ? 'pedido em aberto' : 'pedidos em aberto'}): ${moeda(totalEmAbertoHoje)}',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 11,
                color: theme.secondaryTextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
