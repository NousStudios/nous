import 'package:flutter/material.dart';
import '../../../../../core/theme/theme_controller.dart';
import '../../../models/modelos_nova_venda.dart';
import 'botao_hover_forma.dart';

/// Bloco para inserção de Frete, Desconto e Acréscimo.
class BlocoAjustesNovaVendaWidget extends StatelessWidget {
  final AppTheme theme;
  final TextEditingController freteController;
  final TextEditingController descontoController;
  final TextEditingController acrescimoController;
  final VoidCallback onRecalcularPrazo;
  final BoxDecoration decoracaoDoBloco;
  final InputDecoration Function(String) decoracaoCampo;
  final Widget Function(String) tituloDoBloco;

  const BlocoAjustesNovaVendaWidget({
    super.key,
    required this.theme,
    required this.freteController,
    required this.descontoController,
    required this.acrescimoController,
    required this.onRecalcularPrazo,
    required this.decoracaoDoBloco,
    required this.decoracaoCampo,
    required this.tituloDoBloco,
  });

  Widget _campoValor({
    required TextEditingController controller,
    required String rotulo,
    TextInputType keyboardType =
        const TextInputType.numberWithOptions(decimal: true),
  }) {
    return Expanded(
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        cursorColor: theme.textColor,
        style: theme.getTextStyle(fontSize: 12),
        decoration: decoracaoCampo(rotulo),
        onTap: () {
          if (controller.text.isNotEmpty) {
            controller.selection = TextSelection(
              baseOffset: 0,
              extentOffset: controller.text.length,
            );
          }
        },
        onChanged: (_) => onRecalcularPrazo(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: decoracaoDoBloco,
      child: Column(
        children: [
          tituloDoBloco('Frete, Desconto e Acréscimo'),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 280) {
                return Column(
                  children: [
                    Row(
                      children: [
                        _campoValor(
                          controller: freteController,
                          rotulo: 'Frete',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _campoValor(
                          controller: descontoController,
                          rotulo: 'Desconto',
                          keyboardType: TextInputType.text,
                        ),
                        const SizedBox(width: 8),
                        _campoValor(
                          controller: acrescimoController,
                          rotulo: 'Acréscimo',
                          keyboardType: TextInputType.text,
                        ),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  _campoValor(
                    controller: freteController,
                    rotulo: 'Frete',
                  ),
                  const SizedBox(width: 8),
                  _campoValor(
                    controller: descontoController,
                    rotulo: 'Desconto (R\$ ou %)',
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(width: 8),
                  _campoValor(
                    controller: acrescimoController,
                    rotulo: 'Acréscimo (R\$ ou %)',
                    keyboardType: TextInputType.text,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Bloco que gerencia formas de pagamento e status da quitação (troco, restante).
class BlocoPagamentoNovaVendaWidget extends StatelessWidget {
  final AppTheme theme;
  final ScrollController scrollController;
  final List<String> formasDePagamento;
  final String formaAPrazo;
  final List<LinhaPagamento> pagamentos;
  final double falta;
  final double troco;
  final ValueChanged<String> onEscolherForma;
  final ValueChanged<String> onRemoverForma;
  final VoidCallback onRecalcularPrazo;
  final BoxDecoration decoracaoDoBloco;
  final InputDecoration Function(String) decoracaoCampo;
  final Widget Function(String) tituloDoBloco;
  final String Function(double) valorComVirgula;

  const BlocoPagamentoNovaVendaWidget({
    super.key,
    required this.theme,
    required this.scrollController,
    required this.formasDePagamento,
    required this.formaAPrazo,
    required this.pagamentos,
    required this.falta,
    required this.troco,
    required this.onEscolherForma,
    required this.onRemoverForma,
    required this.onRecalcularPrazo,
    required this.decoracaoDoBloco,
    required this.decoracaoCampo,
    required this.tituloDoBloco,
    required this.valorComVirgula,
  });

  Widget _linhaDePagamento(LinhaPagamento p) {
    final ehPrazo = p.forma == formaAPrazo;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 80, maxWidth: 115),
            child: Text(
              p.forma,
              style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: p.controller,
              readOnly: ehPrazo,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              cursorColor: theme.textColor,
              style: theme.getTextStyle(fontSize: 12),
              decoration: decoracaoCampo('Valor'),
              onTap: () {
                if (!ehPrazo && p.controller.text.isNotEmpty) {
                  p.controller.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: p.controller.text.length,
                  );
                }
              },
              onChanged: (_) => onRecalcularPrazo(),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: Icon(Icons.close, size: 16, color: theme.secondaryTextColor),
            onPressed: () => onRemoverForma(p.forma),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: decoracaoDoBloco,
      child: Column(
        children: [
          tituloDoBloco('Formas de Pagamento'),
          SingleChildScrollView(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                for (final forma in formasDePagamento)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 84),
                      child: BotaoHoverForma(
                        theme: theme,
                        rotulo: forma,
                        selecionada: pagamentos.any((p) => p.forma == forma),
                        aoClicar: () => onEscolherForma(forma),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (pagamentos.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final p in pagamentos) _linhaDePagamento(p),
          ],
          const SizedBox(height: 8),
          if (pagamentos.isEmpty)
            Text(
              'Escolha uma forma acima.',
              style: theme.getTextStyle(
                fontSize: 12,
                color: theme.secondaryTextColor,
              ),
            )
          else if (falta > 0.005)
            Text(
              'Faltam R\$ ${valorComVirgula(falta)} para completar.',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 12,
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (troco > 0.005)
            Text(
              'Troco: R\$ ${valorComVirgula(troco)}',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 12,
                color: theme.textColor,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Text(
              'Pagamento completo.',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 12,
                color: theme.textColor,
              ),
            ),
        ],
      ),
    );
  }
}
