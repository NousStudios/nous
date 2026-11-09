import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/pagamento_funcionario.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/pdv/views/widgets/financeiro/item_linha_financeira.dart';
import 'package:nous/src/features/pdv/views/widgets/usuarios/barra_trabalhador_widget.dart';

/// Bloco que gerencia e exibe a folha de pagamentos a funcionários no período financeiro.
class BlocoFuncionariosFinanceiroWidget extends StatelessWidget {
  final AppTheme theme;
  final Loja? loja;
  final List<PagamentoFuncionario> pagamentos;
  final String cpfLogado;
  final bool podeRegistrar;
  final BoxDecoration decoracaoBloco;
  final Widget Function(AppTheme theme, String texto) tituloDoBloco;
  final void Function(PagamentoFuncionario p) onExcluirPagamento;
  final void Function(Loja loja) onRegistrarPagamento;

  const BlocoFuncionariosFinanceiroWidget({
    super.key,
    required this.theme,
    required this.loja,
    required this.pagamentos,
    this.cpfLogado = '',
    required this.podeRegistrar,
    required this.decoracaoBloco,
    required this.tituloDoBloco,
    required this.onExcluirPagamento,
    required this.onRegistrarPagamento,
  });

  @override
  Widget build(BuildContext context) {
    final membros = loja?.membros ?? const [];

    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: decoracaoBloco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          tituloDoBloco(theme, 'Pagamento de funcionários'),
          const SizedBox(height: 8),
          if (membros.isNotEmpty) ...[
            Text(
              'Trabalhadores e Diárias:',
              style: theme.getTextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: theme.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 6),
            for (final m in membros) ...[
              Builder(builder: (context) {
                // Procura último pagamento deste membro no período
                final pagMembro = pagamentos.where((p) => p.cpf == m.cpf).firstOrNull;
                return BarraTrabalhadorWidget(
                  theme: theme,
                  lojaId: loja?.id ?? '',
                  membro: m,
                  cpfLogado: cpfLogado,
                  contexto: ContextoBarraTrabalhador.financeiro,
                  pagamento: pagMembro,
                  podeGerenciar: podeRegistrar,
                );
              }),
            ],
            const SizedBox(height: 10),
            Divider(color: theme.borderColor.withValues(alpha: 0.3)),
            const SizedBox(height: 6),
          ],
          Text(
            'Lançamentos do Período (${pagamentos.length}):',
            style: theme.getTextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 6),
          if (pagamentos.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhum pagamento registrado no período.',
            )
          else
            for (final p in pagamentos)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: LinhaPagamentoFuncionarioWidget(
                  theme: theme,
                  pagamento: p,
                  podeExcluir: podeRegistrar,
                  onExcluir: () => onExcluirPagamento(p),
                ),
              ),
          if (podeRegistrar) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.textColor,
                  side: BorderSide(color: theme.borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: loja == null ? null : () => onRegistrarPagamento(loja!),
                child: Text(
                  'Registrar pagamento',
                  style: theme.getTextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
