import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

/// Painel interativo para parametrização de um item a ser adicionado à comanda da mesa
/// (seleção de variantes, adicionais/acompanhamentos, quantidade, observações e confirmação).
class ConfiguracaoItemMesaWidget extends StatelessWidget {
  final AppTheme theme;
  final ItemLoja item;
  final CategoriaLoja? categoriaSelecionada;
  final List<GrupoComponentesLoja> gruposDisponiveis;
  final List<ItemLoja> itensDisponiveis;
  final VarianteItem? varianteSelecionada;
  final int quantidade;
  final Map<String, int> acompanhamentosQuantidades;
  final TextEditingController observacaoController;
  final double precoBaseItemAtual;
  final double subtotalCalculado;
  final VoidCallback onTrocarItem;
  final ValueChanged<VarianteItem> onSelecionarVariante;
  final ValueChanged<int> onAlterarQuantidade;
  final ValueChanged<String> onIncrementarAcompanhamento;
  final ValueChanged<String> onDecrementarAcompanhamento;
  final VoidCallback onConfirmarLancamento;

  const ConfiguracaoItemMesaWidget({
    super.key,
    required this.theme,
    required this.item,
    required this.categoriaSelecionada,
    required this.gruposDisponiveis,
    required this.itensDisponiveis,
    required this.varianteSelecionada,
    required this.quantidade,
    required this.acompanhamentosQuantidades,
    required this.observacaoController,
    required this.precoBaseItemAtual,
    required this.subtotalCalculado,
    required this.onTrocarItem,
    required this.onSelecionarVariante,
    required this.onAlterarQuantidade,
    required this.onIncrementarAcompanhamento,
    required this.onDecrementarAcompanhamento,
    required this.onConfirmarLancamento,
  });

  String _valorFormatado(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  double _precoComoNumero(String preco) {
    final limpo =
        preco.replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.').trim();
    return double.tryParse(limpo) ?? 0.0;
  }

  Widget _miniaturaItem(ItemLoja item) {
    final fotoResolvida = item.imagens.isNotEmpty
        ? ImagemService.resolverCaminhoExistente(item.imagens.first)
        : null;
    if (fotoResolvida != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(
          File(fotoResolvida),
          width: 38,
          height: 38,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.inventory_2_outlined,
            size: 24,
            color: theme.textColor,
          ),
        ),
      );
    }
    return Icon(
      Icons.inventory_2_outlined,
      size: 28,
      color: theme.textColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gruposVinculados = <GrupoComponentesLoja>[];
    if (categoriaSelecionada != null) {
      for (final gId in categoriaSelecionada!.grupoIds) {
        final g = gruposDisponiveis.where((x) => x.id == gId).firstOrNull;
        if (g != null && !gruposVinculados.contains(g)) {
          gruposVinculados.add(g);
        }
      }
    }
    for (final g in gruposDisponiveis) {
      if (g.itemIds.contains(item.id) && !gruposVinculados.contains(g)) {
        gruposVinculados.add(g);
      }
    }

    final tituloItemComVariante = varianteSelecionada != null
        ? '${item.nome} (${varianteSelecionada!.nome})'
        : item.nome;
    final tituloExibicao = categoriaSelecionada != null
        ? '${categoriaSelecionada!.nome} • $tituloItemComVariante'
        : tituloItemComVariante;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _miniaturaItem(item),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tituloExibicao,
                      style: theme.getTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    Text(
                      '${_valorFormatado(precoBaseItemAtual)} por unidade',
                      style: theme.getTextStyle(
                        fontSize: 13,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onTrocarItem,
                child: Text(
                  'Trocar item',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.textColor,
                  ),
                ),
              ),
            ],
          ),
          if (item.variantes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Escolha a Variante / Opção:',
              style: theme.getTextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final variante in item.variantes) ...[
                  InkWell(
                    onTap: () => onSelecionarVariante(variante),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: varianteSelecionada == variante
                            ? theme.borderColor.withValues(alpha: 0.25)
                            : theme.backgroundColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: varianteSelecionada == variante
                              ? theme.textColor
                              : theme.borderColor.withValues(alpha: 0.5),
                          width: varianteSelecionada == variante ? 1.6 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            varianteSelecionada == variante
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            size: 15,
                            color: varianteSelecionada == variante
                                ? theme.textColor
                                : theme.secondaryTextColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            variante.nome,
                            style: theme.getTextStyle(
                              fontSize: 13,
                              fontWeight: varianteSelecionada == variante
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: theme.textColor,
                            ),
                          ),
                          if (variante.preco.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(${_valorFormatado(_precoComoNumero(variante.preco))})',
                              style: theme.getTextStyle(
                                fontSize: 11,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 16),
          // Seletor de Quantidade
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Quantidade:',
                style: theme.getTextStyle(
                  fontSize: 14,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: theme.textColor,
                onPressed: quantidade > 1
                    ? () => onAlterarQuantidade(quantidade - 1)
                    : null,
              ),
              Text(
                '$quantidade',
                style: theme.getTextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: theme.textColor,
                onPressed: () => onAlterarQuantidade(quantidade + 1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Grupos de Adicionais
          if (gruposVinculados.isNotEmpty) ...[
            for (final grupo in gruposVinculados) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 6),
                child: Text(
                  grupo.nome,
                  style: theme.getTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
              ),
              for (final itemIdAcomp in grupo.itemIds) ...[
                if (itemIdAcomp != item.id) ...[
                  Builder(
                    builder: (context) {
                      final acomp = itensDisponiveis
                          .where((i) => i.id == itemIdAcomp)
                          .firstOrNull;
                      if (acomp == null) return const SizedBox.shrink();

                      final qtdAtual =
                          acompanhamentosQuantidades[acomp.id] ?? 0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${acomp.nome} (+${_valorFormatado(_precoComoNumero(acomp.preco))})',
                                style: theme.getTextStyle(
                                  fontSize: 13,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              color: theme.textColor,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 28, minHeight: 28),
                              onPressed: qtdAtual > 0
                                  ? () => onDecrementarAcompanhamento(acomp.id)
                                  : null,
                            ),
                            Text(
                              '$qtdAtual',
                              style: theme.getTextStyle(fontSize: 13),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              color: theme.textColor,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 28, minHeight: 28),
                              onPressed: () =>
                                  onIncrementarAcompanhamento(acomp.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ],
            const SizedBox(height: 12),
          ],
          ThemedTextField(
            theme: theme,
            controller: observacaoController,
            label: 'Observações (ex: sem cebola, bem passado)',
            linhas: 2,
          ),
          const SizedBox(height: 16),
          // Subtotal e botão de lançamento
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.backgroundColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal do item:',
                  style: theme.getTextStyle(
                    fontSize: 14,
                    color: theme.secondaryTextColor,
                  ),
                ),
                Text(
                  _valorFormatado(subtotalCalculado),
                  style: theme.getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: theme.buttonColor,
              foregroundColor: theme.buttonTextColor,
              side: BorderSide(color: theme.borderColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: onConfirmarLancamento,
            child: Text(
              'Lançar na Mesa',
              style: theme.getTextStyle(
                fontSize: 14,
                color: theme.buttonTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
