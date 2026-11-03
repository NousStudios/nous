import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/pagamento_funcionario.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/pdv/views/widgets/financeiro/item_linha_financeira.dart';

/// Bloco que gerencia e exibe a folha de pagamentos a funcionários no período financeiro.
class BlocoFuncionariosFinanceiroWidget extends StatelessWidget {
  final AppTheme theme;
  final Loja? loja;
  final List<PagamentoFuncionario> pagamentos;
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
    required this.podeRegistrar,
    required this.decoracaoBloco,
    required this.tituloDoBloco,
    required this.onExcluirPagamento,
    required this.onRegistrarPagamento,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: decoracaoBloco,
      child: Column(
        children: [
          tituloDoBloco(theme, 'Pagamento de funcionários'),
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
