import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/turno_caixa.dart';

/// Card com os indicadores e conferência financeira do turno de caixa.
class CardResumoFinanceiroTurno extends StatelessWidget {
  final AppTheme theme;
  final BoxDecoration decoracao;
  final TurnoCaixa turno;
  final double vendasDinheiro;
  final double totalVendas;
  final double saldoEsperado;
  final double saldoInformado;
  final double diferencaQuebra;
  final String Function(double) formatarMoeda;

  const CardResumoFinanceiroTurno({
    super.key,
    required this.theme,
    required this.decoracao,
    required this.turno,
    required this.vendasDinheiro,
    required this.totalVendas,
    required this.saldoEsperado,
    required this.saldoInformado,
    required this.diferencaQuebra,
    required this.formatarMoeda,
  });

  Widget _buildIndicadorMini({
    required String titulo,
    required String valor,
    required String subtitulo,
    required IconData icone,
    Color? corValor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.borderColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: 12, color: theme.secondaryTextColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 10,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.getTextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: corValor ?? theme.textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.getTextStyle(
              fontSize: 9,
              color: theme.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = turno;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: decoracao,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  size: 16, color: theme.textColor),
              const SizedBox(width: 6),
              Text(
                'Resumo Financeiro do Turno',
                style: theme.getTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Linha de indicadores
          Row(
            children: [
              Expanded(
                child: _buildIndicadorMini(
                  titulo: 'Fundo Inicial',
                  valor: formatarMoeda(t.saldoInicial),
                  subtitulo: 'Abertura',
                  icone: Icons.savings_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildIndicadorMini(
                  titulo: 'Vendas Dinheiro',
                  valor: formatarMoeda(vendasDinheiro),
                  subtitulo: 'Total: ${formatarMoeda(totalVendas)}',
                  icone: Icons.point_of_sale_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildIndicadorMini(
                  titulo: 'Suprimentos',
                  valor: '+${formatarMoeda(t.totalSuprimentos)}',
                  subtitulo:
                      '${t.movimentacoes.where((m) => m.tipo == TipoMovimentoCaixa.suprimento).length} entradas',
                  icone: Icons.arrow_upward,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildIndicadorMini(
                  titulo: 'Sangrias',
                  valor: '-${formatarMoeda(t.totalSangrias)}',
                  subtitulo:
                      '${t.movimentacoes.where((m) => m.tipo == TipoMovimentoCaixa.sangria).length} saídas',
                  icone: Icons.arrow_downward,
                  corValor: t.totalSangrias > 0 ? Colors.redAccent : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Conferência do caixa
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.borderColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saldo Esperado em Caixa',
                        style: theme.getTextStyle(
                          fontSize: 10,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatarMoeda(saldoEsperado),
                        style: theme.getTextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saldo Final Informado',
                        style: theme.getTextStyle(
                          fontSize: 10,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatarMoeda(saldoInformado),
                        style: theme.getTextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Diferença / Quebra',
                        style: theme.getTextStyle(
                          fontSize: 10,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            diferencaQuebra == 0
                                ? Icons.check_circle_outline
                                : diferencaQuebra < 0
                                    ? Icons.remove_circle_outline
                                    : Icons.add_circle_outline,
                            size: 13,
                            color: diferencaQuebra < 0
                                ? Colors.redAccent
                                : theme.textColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            diferencaQuebra == 0
                                ? 'Exato'
                                : '${diferencaQuebra > 0 ? "+" : ""}${formatarMoeda(diferencaQuebra)}',
                            style: theme.getTextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: diferencaQuebra < 0
                                  ? Colors.redAccent
                                  : theme.textColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
