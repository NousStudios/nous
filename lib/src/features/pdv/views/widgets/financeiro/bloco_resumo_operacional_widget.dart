import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/financeiro/seletor_periodo_financeiro_widget.dart';

/// Bloco que renderiza o dashboard de métricas do período selecionado:
/// Faturamento, Quantidade de Vendas, Ticket Médio, Saldo do Caixa e Pedidos em Aberto.
class BlocoResumoOperacionalWidget extends StatelessWidget {
  final AppTheme theme;
  final Loja? loja;
  final PeriodoFinanceiro periodo;
  final DateTime? desde;
  final DateTime? ate;
  final bool ehDiaUnico;
  final String rotuloPeriodoAtual;
  final BoxDecoration decoracaoBloco;
  final String Function(double v) valorFormatado;
  final double Function(String forma) entradasPorForma;

  const BlocoResumoOperacionalWidget({
    super.key,
    required this.theme,
    required this.loja,
    required this.periodo,
    required this.desde,
    required this.ate,
    required this.ehDiaUnico,
    required this.rotuloPeriodoAtual,
    required this.decoracaoBloco,
    required this.valorFormatado,
    required this.entradasPorForma,
  });

  Widget _itemMetricaResumo({
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
    if (loja == null) return const SizedBox.shrink();

    final todosPedidos = loja!.pedidosLoja;

    final pedidosPeriodoConcluidos = todosPedidos.where((p) {
      if (p.status != StatusPedido.concluido) return false;
      if (desde != null && p.dataHora.isBefore(desde!)) return false;
      if (ate != null && p.dataHora.isAfter(ate!)) return false;
      return true;
    }).toList();

    final pedidosPeriodoEmAberto = todosPedidos.where((p) {
      if (p.status != StatusPedido.aceito && p.status != StatusPedido.novo) {
        return false;
      }
      if (desde != null && p.dataHora.isBefore(desde!)) return false;
      if (ate != null && p.dataHora.isAfter(ate!)) return false;
      return true;
    }).toList();

    final totalVendas = pedidosPeriodoConcluidos.length;
    final faturamento = pedidosPeriodoConcluidos.fold<double>(
      0.0,
      (soma, p) => soma + p.valor,
    );
    final totalEmAberto = pedidosPeriodoEmAberto.fold<double>(
      0.0,
      (soma, p) => soma + p.valor,
    );
    final ticketMedio = totalVendas == 0 ? 0.0 : faturamento / totalVendas;

    final String tituloBloco;
    final String rotuloVendas;
    final String rotuloAReceber;

    if (periodo == PeriodoFinanceiro.hoje) {
      tituloBloco = 'Resumo Operacional do Dia';
      rotuloVendas = 'Vendas Hoje';
      rotuloAReceber = 'A receber hoje';
    } else if (ehDiaUnico) {
      tituloBloco = 'Resumo Operacional do Dia ($rotuloPeriodoAtual)';
      rotuloVendas = 'Vendas do Dia';
      rotuloAReceber = 'A receber no dia';
    } else {
      tituloBloco = 'Resumo Operacional ($rotuloPeriodoAtual)';
      rotuloVendas = 'Vendas no Período';
      rotuloAReceber = 'A receber no período';
    }

    double saldoEmDinheiro = 0.0;
    final bool caixaAberto;

    if (periodo == PeriodoFinanceiro.hoje) {
      final turnoAberto = loja!.turnosCaixa.where((t) => t.aberto).firstOrNull;
      caixaAberto = turnoAberto != null;
      if (turnoAberto != null) {
        double vendasDinheiroTurno = 0.0;
        for (final p in loja!.pedidosLoja) {
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
            loja!.turnosCaixa.isNotEmpty ? loja!.turnosCaixa.last : null;
        if (ultimoTurno != null && ultimoTurno.saldoFinalInformado != null) {
          saldoEmDinheiro = ultimoTurno.saldoFinalInformado!;
        }
      }
    } else {
      final turnosDoPeriodo = loja!.turnosCaixa.where((t) {
        if (desde != null && t.dataAbertura.isBefore(desde!)) return false;
        if (ate != null && t.dataAbertura.isAfter(ate!)) return false;
        return true;
      }).toList();

      final turnoAbertoPeriodo =
          turnosDoPeriodo.where((t) => t.aberto).firstOrNull;
      caixaAberto = turnoAbertoPeriodo != null;

      if (turnosDoPeriodo.isNotEmpty) {
        final turnoRef = turnosDoPeriodo.last;
        if (turnoRef.aberto) {
          double vendasDinheiroTurno = 0.0;
          for (final p in loja!.pedidosLoja) {
            if (p.status == StatusPedido.cancelado) continue;
            if (p.dataHora.isAfter(turnoRef.dataAbertura) ||
                p.dataHora.isAtSameMomentAs(turnoRef.dataAbertura)) {
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
          saldoEmDinheiro = turnoRef.saldoInicial +
              turnoRef.totalSuprimentos -
              turnoRef.totalSangrias +
              vendasDinheiroTurno;
        } else if (turnoRef.saldoFinalInformado != null) {
          saldoEmDinheiro = turnoRef.saldoFinalInformado!;
        } else {
          saldoEmDinheiro = entradasPorForma('Dinheiro');
        }
      } else {
        saldoEmDinheiro = entradasPorForma('Dinheiro');
      }
      if (saldoEmDinheiro < 0) saldoEmDinheiro = 0.0;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: decoracaoBloco,
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.dashboard_outlined, size: 20, color: theme.textColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tituloBloco,
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
                child: _itemMetricaResumo(
                  icone: Icons.attach_money,
                  rotulo: 'Faturamento',
                  valor: valorFormatado(faturamento),
                  destaque: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _itemMetricaResumo(
                  icone: Icons.receipt_long_outlined,
                  rotulo: rotuloVendas,
                  valor: '$totalVendas',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _itemMetricaResumo(
                  icone: Icons.trending_up,
                  rotulo: 'Ticket Médio',
                  valor: valorFormatado(ticketMedio),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _itemMetricaResumo(
                  icone: Icons.point_of_sale_outlined,
                  rotulo: 'Saldo Caixa (Dinheiro)',
                  valor: valorFormatado(saldoEmDinheiro),
                ),
              ),
            ],
          ),
          if (pedidosPeriodoEmAberto.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '$rotuloAReceber (${pedidosPeriodoEmAberto.length} ${pedidosPeriodoEmAberto.length == 1 ? 'pedido em aberto' : 'pedidos em aberto'}): ${valorFormatado(totalEmAberto)}',
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
