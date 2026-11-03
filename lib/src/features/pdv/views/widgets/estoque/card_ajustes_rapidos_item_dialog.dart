import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_switch.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';

/// Card que exibe dados cadastrais e permite ajustes rápidos de preço, código e unidade durante a movimentação de estoque.
class CardAjustesRapidosItemDialog extends StatelessWidget {
  final AppTheme theme;
  final ItemLoja item;
  final bool ehEntrada;
  final bool mostrarAjustesRapidos;
  final VoidCallback onAlternarMostrarAjustesRapidos;
  final TextEditingController precoVendaController;
  final TextEditingController codigoBarrasController;
  final UnidadeItemLoja unidadeRapida;
  final ValueChanged<UnidadeItemLoja> onAlterarUnidade;
  final bool atualizarCustoNoCadastro;
  final ValueChanged<bool> onAlternarAtualizarCustoNoCadastro;
  final VoidCallback? onEditarItemCompleto;

  const CardAjustesRapidosItemDialog({
    super.key,
    required this.theme,
    required this.item,
    required this.ehEntrada,
    required this.mostrarAjustesRapidos,
    required this.onAlternarMostrarAjustesRapidos,
    required this.precoVendaController,
    required this.codigoBarrasController,
    required this.unidadeRapida,
    required this.onAlterarUnidade,
    required this.atualizarCustoNoCadastro,
    required this.onAlternarAtualizarCustoNoCadastro,
    this.onEditarItemCompleto,
  });

  InputDecoration _decoracaoCampo(String dica) {
    OutlineInputBorder borda(Color cor) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cor),
        );
    return InputDecoration(
      hintText: dica,
      hintStyle:
          theme.getTextStyle(fontSize: 12, color: theme.secondaryTextColor),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: borda(theme.borderColor),
      focusedBorder: borda(theme.textColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined,
                  size: 16, color: theme.textColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dados do Cadastro do Item',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
              if (onEditarItemCompleto != null)
                InkWell(
                  onTap: onEditarItemCompleto,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.edit_note_rounded,
                            size: 15, color: theme.textColor),
                        const SizedBox(width: 4),
                        Text(
                          'Editar completo',
                          style: theme.getTextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Venda: R\$ ${item.preco.isEmpty ? "0,00" : item.preco}',
                  style: theme.getTextStyle(
                      fontSize: 11, color: theme.secondaryTextColor),
                ),
              ),
              Expanded(
                child: Text(
                  'Custo atual: R\$ ${item.precoCusto.isEmpty ? "0,00" : item.precoCusto}',
                  style: theme.getTextStyle(
                      fontSize: 11, color: theme.secondaryTextColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Código: ${item.codigoBarras.isEmpty ? "Sem código" : item.codigoBarras}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                      fontSize: 11, color: theme.secondaryTextColor),
                ),
              ),
              Expanded(
                child: Text(
                  'Mínimo: ${item.estoqueMinimo.isEmpty ? "0" : item.estoqueMinimo} ${unidadeRapida.name}',
                  style: theme.getTextStyle(
                      fontSize: 11, color: theme.secondaryTextColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onAlternarMostrarAjustesRapidos,
            borderRadius: BorderRadius.circular(6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  mostrarAjustesRapidos
                      ? Icons.keyboard_arrow_up
                      : Icons.tune,
                  size: 14,
                  color: theme.textColor,
                ),
                const SizedBox(width: 4),
                Text(
                  mostrarAjustesRapidos
                      ? 'Ocultar ajustes rápidos'
                      : 'Ajustar preço de venda, código de barras ou unidade',
                  style: theme.getTextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
              ],
            ),
          ),
          if (mostrarAjustesRapidos) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Novo Preço de Venda (R\$)',
                        style: theme.getTextStyle(
                            fontSize: 10, color: theme.secondaryTextColor),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: precoVendaController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        cursorColor: theme.textColor,
                        style: theme.getTextStyle(fontSize: 11),
                        decoration: _decoracaoCampo('Ex: 15,00'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Código de Barras / EAN',
                        style: theme.getTextStyle(
                            fontSize: 10, color: theme.secondaryTextColor),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: codigoBarrasController,
                        cursorColor: theme.textColor,
                        style: theme.getTextStyle(fontSize: 11),
                        decoration: _decoracaoCampo('Código'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unidade de Medida do Item',
                  style: theme.getTextStyle(
                      fontSize: 10, color: theme.secondaryTextColor),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    for (final u in UnidadeItemLoja.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () => onAlterarUnidade(u),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: unidadeRapida == u
                                  ? (theme.buttonColor != Colors.transparent
                                      ? theme.buttonColor
                                          .withValues(alpha: 0.8)
                                      : theme.borderColor
                                          .withValues(alpha: 0.35))
                                  : theme.backgroundColor
                                      .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: unidadeRapida == u
                                    ? theme.textColor
                                    : theme.borderColor
                                        .withValues(alpha: 0.5),
                                width: unidadeRapida == u ? 1.4 : 1.0,
                              ),
                            ),
                            child: Text(
                              u == UnidadeItemLoja.un
                                  ? 'Unidade (un)'
                                  : u == UnidadeItemLoja.g
                                      ? 'Gramas (g)'
                                      : 'Mililitros (ml)',
                              style: theme.getTextStyle(
                                fontSize: 11,
                                fontWeight: unidadeRapida == u
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: unidadeRapida == u
                                    ? theme.textColor
                                    : theme.secondaryTextColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
          if (ehEntrada) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                ThemedSwitch(
                  theme: theme,
                  value: atualizarCustoNoCadastro,
                  onChanged: onAlternarAtualizarCustoNoCadastro,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Atualizar preço de custo no cadastro do item com esta compra',
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.textColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
