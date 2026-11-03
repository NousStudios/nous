import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/pdv/views/widgets/financeiro/item_linha_financeira.dart';

/// Bloco que lista as compras de estoque no período, separadas por fornecedor
/// e detalhadas em lista rolável com busca interativa.
class BlocoComprasFinanceiroWidget extends StatelessWidget {
  final AppTheme theme;
  final Loja? loja;
  final Map<String, double> porFornecedor;
  final List<MovimentoEstoque> compras;
  final TextEditingController pesquisaComprasController;
  final ScrollController scrollComprasController;
  final BoxDecoration decoracaoBloco;
  final Widget Function(AppTheme theme, String texto) tituloDoBloco;
  final Widget Function(AppTheme theme, String rotulo, String valor, {bool destaque}) linha;
  final String Function(double v) valorFormatado;
  final String Function(Loja? loja, MovimentoEstoque m) nomeDoItem;
  final String Function(Loja? loja, String itemId) unidadeDoItem;
  final VoidCallback onChangedPesquisa;

  const BlocoComprasFinanceiroWidget({
    super.key,
    required this.theme,
    required this.loja,
    required this.porFornecedor,
    required this.compras,
    required this.pesquisaComprasController,
    required this.scrollComprasController,
    required this.decoracaoBloco,
    required this.tituloDoBloco,
    required this.linha,
    required this.valorFormatado,
    required this.nomeDoItem,
    required this.unidadeDoItem,
    required this.onChangedPesquisa,
  });

  @override
  Widget build(BuildContext context) {
    if (porFornecedor.isEmpty && compras.isEmpty) {
      return Container(
        width: 320,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: decoracaoBloco,
        child: Column(
          children: [
            tituloDoBloco(theme, 'Compras do período'),
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhuma compra com custo registrado no período.',
            ),
          ],
        ),
      );
    }

    final entradas = porFornecedor.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    var total = 0.0;
    for (final e in entradas) {
      total += e.value;
    }

    final termo = pesquisaComprasController.text.trim().toLowerCase();
    final comprasFiltradas = compras.where((m) {
      if (termo.isEmpty) return true;
      final nome = nomeDoItem(loja, m).toLowerCase();
      final fornecedor = m.fornecedorNome.toLowerCase();
      final motivo = m.motivo.toLowerCase();
      return nome.contains(termo) ||
          fornecedor.contains(termo) ||
          motivo.contains(termo);
    }).toList();

    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: decoracaoBloco,
      child: Column(
        children: [
          tituloDoBloco(theme, 'Compras do período'),
          for (final e in entradas)
            linha(theme, e.key, valorFormatado(e.value)),
          const Divider(height: 20),
          linha(
            theme,
            'Total',
            valorFormatado(total),
            destaque: true,
          ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: pesquisaComprasController,
              onChanged: (_) => onChangedPesquisa(),
              style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Buscar item ou fornecedor...',
                hintStyle: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 16,
                  color: theme.secondaryTextColor,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                suffixIcon: pesquisaComprasController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          size: 14,
                          color: theme.secondaryTextColor,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        onPressed: () {
                          pesquisaComprasController.clear();
                          onChangedPesquisa();
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.backgroundColor.withValues(alpha: 0.3),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: theme.borderColor.withValues(alpha: 0.6),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.buttonColor),
                ),
              ),
            ),
          ),
          if (comprasFiltradas.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nenhum item encontrado.',
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 290),
              child: Scrollbar(
                controller: scrollComprasController,
                thumbVisibility: comprasFiltradas.length > 6,
                child: ListView.builder(
                  controller: scrollComprasController,
                  shrinkWrap: true,
                  physics: comprasFiltradas.length > 6
                      ? const AlwaysScrollableScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  itemCount: comprasFiltradas.length,
                  itemBuilder: (context, index) {
                    final compra = comprasFiltradas[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == comprasFiltradas.length - 1 ? 0 : 6,
                      ),
                      child: LinhaCompraEstoqueWidget(
                        theme: theme,
                        movimento: compra,
                        nomeItem: nomeDoItem(loja, compra),
                        unidade: unidadeDoItem(loja, compra.itemId),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
