import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'linha_movimento_widget.dart';

/// Modal dialog com a Ficha Kardex do produto e seu histórico cronológico.
class FichaKardexDialog extends StatelessWidget {
  final AppTheme theme;
  final ItemLoja item;
  final double saldo;
  final List<MovimentoEstoque> movimentos;
  final bool podeEditar;
  final ValueChanged<MovimentoEstoque> onRemoverMovimento;

  const FichaKardexDialog({
    super.key,
    required this.theme,
    required this.item,
    required this.saldo,
    required this.movimentos,
    required this.podeEditar,
    required this.onRemoverMovimento,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: theme.textColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          item.nome.isEmpty
                              ? 'Ficha Kardex'
                              : 'Ficha Kardex: ${item.nome}',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        Text(
                          'Histórico e Movimentação Cronológica',
                          textAlign: TextAlign.center,
                          style: theme.getTextStyle(
                            fontSize: 10,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.backgroundColor.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.borderColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Saldo em Estoque:',
                                style: theme.getTextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor,
                                ),
                              ),
                              Text(
                                formatarQuantidadeEstoque(
                                    saldo, item.unidadeBase),
                                style: theme.getTextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: saldo <= 0
                                      ? Colors.redAccent
                                      : theme.textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Preço de Venda:',
                                style: theme.getTextStyle(
                                  fontSize: 11,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                              Text(
                                item.preco.trim().startsWith('R\$')
                                    ? item.preco.trim()
                                    : 'R\$ ${item.preco.trim()}',
                                style: theme.getTextStyle(
                                  fontSize: 11,
                                  color: theme.textColor,
                                ),
                              ),
                            ],
                          ),
                          if (item.precoCusto.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Preço de Custo:',
                                  style: theme.getTextStyle(
                                    fontSize: 11,
                                    color: theme.secondaryTextColor,
                                  ),
                                ),
                                Text(
                                  item.precoCusto.trim().startsWith('R\$')
                                      ? item.precoCusto.trim()
                                      : 'R\$ ${item.precoCusto.trim()}',
                                  style: theme.getTextStyle(
                                    fontSize: 11,
                                    color: theme.textColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (item.estoqueMinimo.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Estoque Mínimo:',
                                  style: theme.getTextStyle(
                                    fontSize: 11,
                                    color: theme.secondaryTextColor,
                                  ),
                                ),
                                Text(
                                  '${item.estoqueMinimo} ${item.unidadeBase.name}',
                                  style: theme.getTextStyle(
                                    fontSize: 11,
                                    color: theme.textColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (item.codigoBarras.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Código de Barras:',
                                  style: theme.getTextStyle(
                                    fontSize: 11,
                                    color: theme.secondaryTextColor,
                                  ),
                                ),
                                Text(
                                  item.codigoBarras,
                                  style: theme.getTextStyle(
                                    fontSize: 11,
                                    color: theme.textColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (movimentos.isEmpty)
                      EstadoVazioContainer(
                        theme: theme,
                        mensagem: 'Nenhum movimento registrado ainda.',
                      )
                    else ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Movimentações Registradas (${movimentos.length})',
                          style: theme.getTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                      for (final m in movimentos)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: LinhaMovimentoWidget(
                            theme: theme,
                            movimento: m,
                            unidade: item.unidadeBase,
                            podeExcluir: podeEditar,
                            onExcluir: () {
                              onRemoverMovimento(m);
                            },
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
