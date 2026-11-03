import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/turno_caixa.dart';
import 'package:nous/src/features/pdv/views/widgets/caixa/bloco_movimentacoes_turno.dart';
import 'package:nous/src/features/pdv/views/widgets/caixa/painel_fechamento_turno.dart';
import 'package:nous/src/features/pdv/views/widgets/caixa/painel_lancamento_movimento.dart';

/// Painel para exibição do turno aberto ativo, controle de sangrias, suprimentos e fechamento.
class PainelTurnoAberto extends StatelessWidget {
  final AppTheme theme;
  final BoxDecoration decoracao;
  final TurnoCaixa turno;
  final double vendasDinheiro;
  final double vendasEletronico;
  final double vendasAPrazo;
  final double saldoEsperadoDinheiro;
  final String Function(DateTime d) formatarDataHora;
  final String Function(double v) formatarMoeda;
  final double Function(String s) parsearValor;
  final Widget Function(String label, String valor, {bool destaque}) linhaResumo;

  // Estados de submodo
  final TipoMovimentoCaixa? modoMovimento;
  final bool modoFechamento;
  final bool salvando;

  // Controllers
  final TextEditingController movimentoValorController;
  final TextEditingController movimentoMotivoController;
  final TextEditingController saldoFechamentoController;
  final TextEditingController observacaoFechamentoController;

  // Callbacks
  final Future<void> Function(MovimentoCaixa mov) aoImprimirMovimento;
  final VoidCallback aoIniciarSuprimento;
  final VoidCallback aoIniciarSangria;
  final VoidCallback aoCancelarMovimento;
  final VoidCallback aoConfirmarMovimento;
  final VoidCallback aoConfirmarEImprimirMovimento;
  final VoidCallback aoIniciarFechamento;
  final VoidCallback aoCancelarFechamento;
  final VoidCallback aoFecharCaixa;
  final VoidCallback aoFecharCaixaEImprimir;
  final VoidCallback aoImprimirResumoTurno;
  final VoidCallback aoAlterarTextoFechamento;

  const PainelTurnoAberto({
    super.key,
    required this.theme,
    required this.decoracao,
    required this.turno,
    required this.vendasDinheiro,
    required this.vendasEletronico,
    required this.vendasAPrazo,
    required this.saldoEsperadoDinheiro,
    required this.formatarDataHora,
    required this.formatarMoeda,
    required this.parsearValor,
    required this.linhaResumo,
    required this.modoMovimento,
    required this.modoFechamento,
    required this.salvando,
    required this.movimentoValorController,
    required this.movimentoMotivoController,
    required this.saldoFechamentoController,
    required this.observacaoFechamentoController,
    required this.aoImprimirMovimento,
    required this.aoIniciarSuprimento,
    required this.aoIniciarSangria,
    required this.aoCancelarMovimento,
    required this.aoConfirmarMovimento,
    required this.aoConfirmarEImprimirMovimento,
    required this.aoIniciarFechamento,
    required this.aoCancelarFechamento,
    required this.aoFecharCaixa,
    required this.aoFecharCaixaEImprimir,
    required this.aoImprimirResumoTurno,
    required this.aoAlterarTextoFechamento,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: decoracao,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: theme.textColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Turno Ativo',
                        style: theme.getTextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    formatarDataHora(turno.dataAbertura),
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
              if (turno.abertoPorNome.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Operador: ${turno.abertoPorNome}',
                  style: theme.getTextStyle(
                    fontSize: 11,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Divider(color: theme.borderColor.withValues(alpha: 0.6)),
              linhaResumo('Fundo de troco inicial', formatarMoeda(turno.saldoInicial)),
              linhaResumo('Vendas em dinheiro (+)', formatarMoeda(vendasDinheiro)),
              linhaResumo('Vendas Pix / Cartão (+)', formatarMoeda(vendasEletronico)),
              if (vendasAPrazo > 0)
                linhaResumo('Vendas à prazo (a receber)', formatarMoeda(vendasAPrazo)),
              if (turno.totalSuprimentos > 0)
                linhaResumo('Suprimentos (+ troco adicionado)', formatarMoeda(turno.totalSuprimentos)),
              if (turno.totalSangrias > 0)
                linhaResumo('Sangrias (- retiradas p/ cofre)', '-${formatarMoeda(turno.totalSangrias)}'),
              Divider(color: theme.borderColor.withValues(alpha: 0.6)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.borderColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Saldo Atual em Dinheiro:',
                      style: theme.getTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    Text(
                      formatarMoeda(saldoEsperadoDinheiro),
                      style: theme.getTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        BlocoMovimentacoesTurno(
          theme: theme,
          decoracao: decoracao,
          turno: turno,
          formatarMoeda: formatarMoeda,
          aoImprimirMovimento: aoImprimirMovimento,
        ),
        const SizedBox(height: 12),
        if (modoMovimento != null) ...[
          PainelLancamentoMovimento(
            theme: theme,
            decoracao: decoracao,
            modoMovimento: modoMovimento!,
            valorController: movimentoValorController,
            motivoController: movimentoMotivoController,
            salvando: salvando,
            aoCancelar: aoCancelarMovimento,
            aoConfirmar: aoConfirmarMovimento,
            aoConfirmarEImprimir: aoConfirmarEImprimirMovimento,
          ),
          const SizedBox(height: 12),
        ] else if (modoFechamento) ...[
          PainelFechamentoTurno(
            theme: theme,
            decoracao: decoracao,
            saldoFechamentoController: saldoFechamentoController,
            observacaoFechamentoController: observacaoFechamentoController,
            saldoEsperadoDinheiro: saldoEsperadoDinheiro,
            parsearValor: parsearValor,
            formatarMoeda: formatarMoeda,
            linhaResumo: linhaResumo,
            salvando: salvando,
            aoVoltar: aoCancelarFechamento,
            aoFechar: aoFecharCaixa,
            aoFecharEImprimir: aoFecharCaixaEImprimir,
            aoAlterarTexto: aoAlterarTextoFechamento,
          ),
          const SizedBox(height: 12),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.textColor,
                    side: BorderSide(color: theme.borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: aoIniciarSuprimento,
                  icon: Icon(Icons.add_circle_outline, size: 16, color: theme.textColor),
                  label: Text('Suprimento', style: theme.getTextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.textColor,
                    side: BorderSide(color: theme.borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: aoIniciarSangria,
                  icon: Icon(Icons.remove_circle_outline, size: 16, color: theme.textColor),
                  label: Text('Sangria', style: theme.getTextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: theme.buttonColor,
                foregroundColor: theme.buttonTextColor,
                side: BorderSide(color: theme.borderColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: aoIniciarFechamento,
              icon: Icon(Icons.check_circle_outline, size: 18, color: theme.buttonTextColor),
              label: Text(
                'Fechar Caixa do Turno',
                style: theme.getTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.buttonTextColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.textColor,
                side: BorderSide(color: theme.borderColor),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: aoImprimirResumoTurno,
              icon: Icon(Icons.print_outlined, size: 16, color: theme.textColor),
              label: Text(
                'Imprimir Resumo do Turno',
                style: theme.getTextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
        if (turno.movimentacoes.isNotEmpty) ...[
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Movimentações deste Turno',
              style: theme.getTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final m in turno.movimentacoes.reversed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                m.tipo == TipoMovimentoCaixa.suprimento
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                size: 14,
                                color: theme.textColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${m.tipo == TipoMovimentoCaixa.suprimento ? "Suprimento" : "Sangria"}: ${m.motivo.isEmpty ? "Sem motivo" : m.motivo}',
                                style: theme.getTextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                          Text(
                            formatarMoeda(m.valor),
                            style: theme.getTextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
