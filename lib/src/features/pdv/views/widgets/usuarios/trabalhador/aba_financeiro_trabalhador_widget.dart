import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/pdv/models/pagamento_funcionario.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';

/// Aba de Histórico Financeiro do Trabalhador: total recebido, pendente e extrato de diárias.
class AbaFinanceiroTrabalhadorWidget extends StatelessWidget {
  final AppTheme theme;
  final String lojaId;
  final List<PagamentoFuncionario> pagamentos;
  final double totalRecebido;
  final double totalDevido;
  final bool podeGerenciar;

  const AbaFinanceiroTrabalhadorWidget({
    super.key,
    required this.theme,
    required this.lojaId,
    required this.pagamentos,
    required this.totalRecebido,
    required this.totalDevido,
    required this.podeGerenciar,
  });

  String _formatarMoeda(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  String _formatarDataHora(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.backgroundColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.borderColor.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextoRolante(
                      texto: 'Total Recebido',
                      style: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor),
                    ),
                    const SizedBox(height: 2),
                    TextoRolante(
                      texto: _formatarMoeda(totalRecebido),
                      style: theme.getTextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textColor),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.backgroundColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.borderColor.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextoRolante(
                      texto: 'Pendente (A Prazo)',
                      style: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor),
                    ),
                    const SizedBox(height: 2),
                    TextoRolante(
                      texto: _formatarMoeda(totalDevido),
                      style: theme.getTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: totalDevido > 0 ? theme.dangerColor : theme.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextoRolante(
          texto: 'Extrato de Diárias e Pagamentos (${pagamentos.length}):',
          style: theme.getTextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.secondaryTextColor),
        ),
        const SizedBox(height: 6),
        if (pagamentos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Nenhum pagamento registrado para este trabalhador ainda.',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pagamentos.length,
            separatorBuilder: (_, _) => Divider(height: 6, color: theme.borderColor.withValues(alpha: 0.2)),
            itemBuilder: (context, idx) {
              final p = pagamentos[idx];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Text(_formatarDataHora(p.dataHora), style: theme.getTextStyle(fontSize: 10.5, color: theme.secondaryTextColor)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextoRolante(
                        texto: '${p.descricao.isNotEmpty ? p.descricao : "Diária/Salário"} (${p.formaPagamento}${!p.pago ? " • A Prazo" : ""})',
                        style: theme.getTextStyle(fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatarMoeda(p.valor),
                      style: theme.getTextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: !p.pago ? theme.dangerColor : theme.textColor,
                      ),
                    ),
                    if (!p.pago && podeGerenciar) ...[
                      const SizedBox(width: 6),
                      TextButton(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 24)),
                        onPressed: () => context.read<PdvProvider>().quitarPagamentoFuncionario(lojaId, p.id),
                        child: Text(
                          'Quitar',
                          style: theme.getTextStyle(fontSize: 10, color: theme.textColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
