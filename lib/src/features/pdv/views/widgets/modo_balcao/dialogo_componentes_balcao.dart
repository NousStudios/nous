import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';

class DialogoComponentesBalcao {
  static double _precoComoNumero(String texto) {
    var limpo = texto.replaceAll(RegExp(r'[^0-9,.]'), '');
    if (limpo.contains(',')) {
      limpo = limpo.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(limpo) ?? 0;
  }

  static Future<ItemVendido?> mostrar({
    required BuildContext context,
    required AppTheme theme,
    required ItemVendido item,
    required List<GrupoComponentesLoja> grupos,
    required List<ItemLoja> itens,
  }) async {
    final selecionados = <String, int>{};
    for (final a in item.acompanhamentos) {
      selecionados[a.itemId] = a.quantidadePorUnidade;
    }
    final obsController = TextEditingController(text: item.observacao);

    return showDialog<ItemVendido>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.cardBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: BorderSide(color: theme.borderColor),
              ),
              title: Text(
                'Componentes e Observações\n${item.nomeExibicao}',
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              content: SizedBox(
                width: 380,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final grupo in grupos) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 6),
                          child: Text(
                            grupo.nome,
                            textAlign: TextAlign.center,
                            style: theme.getTextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                        for (final compId in grupo.itemIds)
                          Builder(
                            builder: (context) {
                              final comp = itens
                                  .where((i) => i.id == compId)
                                  .firstOrNull;
                              if (comp == null) return const SizedBox.shrink();
                              final qtd = selecionados[compId] ?? 0;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        comp.nome,
                                        style: theme.getTextStyle(fontSize: 12),
                                      ),
                                    ),
                                    Text(
                                      'R\$ ${comp.preco}',
                                      style: theme.getTextStyle(fontSize: 11),
                                    ),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                      constraints: const BoxConstraints(
                                          minWidth: 30, minHeight: 30),
                                      icon: Icon(Icons.remove,
                                          size: 16, color: theme.textColor),
                                      onPressed: () {
                                        setDialogState(() {
                                          final atual =
                                              selecionados[compId] ?? 0;
                                          if (atual <= 1) {
                                            selecionados.remove(compId);
                                          } else {
                                            selecionados[compId] = atual - 1;
                                          }
                                        });
                                      },
                                    ),
                                    SizedBox(
                                      width: 20,
                                      child: Text(
                                        '$qtd',
                                        textAlign: TextAlign.center,
                                        style: theme.getTextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                      constraints: const BoxConstraints(
                                          minWidth: 30, minHeight: 30),
                                      icon: Icon(Icons.add,
                                          size: 16, color: theme.textColor),
                                      onPressed: () {
                                        setDialogState(() {
                                          selecionados[compId] =
                                              (selecionados[compId] ?? 0) + 1;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        Divider(
                          color: theme.borderColor.withValues(alpha: 0.4),
                          height: 16,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        'Observação / Comentário do Item',
                        style: theme.getTextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: obsController,
                        style: theme.getTextStyle(fontSize: 12),
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Ex: Sem cebola, bem passado, sem gelo...',
                          hintStyle: theme.getTextStyle(
                            fontSize: 11,
                            color: theme.secondaryTextColor,
                          ),
                          filled: true,
                          fillColor:
                              theme.backgroundColor.withValues(alpha: 0.3),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: theme.borderColor.withValues(alpha: 0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: theme.textColor, width: 1.2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancelar',
                    style: theme.getTextStyle(color: theme.secondaryTextColor),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final novosAcomp = <AcompanhamentoEscolhido>[];
                    selecionados.forEach((compId, qtd) {
                      if (qtd > 0) {
                        final comp = itens
                            .where((i) => i.id == compId)
                            .firstOrNull;
                        if (comp != null) {
                          novosAcomp.add(
                            AcompanhamentoEscolhido(
                              itemId: comp.id,
                              nomeItem: comp.nome,
                              precoItem: _precoComoNumero(comp.preco),
                              quantidadePorUnidade: qtd,
                            ),
                          );
                        }
                      }
                    });

                    final itemAtualizado = item.copyWith(
                      acompanhamentos: novosAcomp,
                      observacao: obsController.text.trim(),
                    );
                    Navigator.of(dialogContext).pop(itemAtualizado);
                  },
                  child: Text(
                    'Concluir',
                    style: theme.getTextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class DialogoObservacaoBalcao {
  static Future<String?> mostrar({
    required BuildContext context,
    required AppTheme theme,
    required ItemVendido item,
  }) async {
    final controller = TextEditingController(text: item.observacao);

    return showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.borderColor),
        ),
        title: Text(
          'Observação do Item\n${item.nomeExibicao}',
          textAlign: TextAlign.center,
          style: theme.getTextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 3,
                style: theme.getTextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Ex: Sem gelo, sem cebola, ponto da carne...',
                  hintStyle: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.secondaryTextColor,
                  ),
                  filled: true,
                  fillColor: theme.backgroundColor.withValues(alpha: 0.3),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: theme.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: theme.textColor, width: 1.4),
                  ),
                ),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(null),
            child: Text(
              'Cancelar',
              style: theme.getTextStyle(color: theme.secondaryTextColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop(controller.text.trim());
            },
            child: Text(
              'Salvar',
              style: theme.getTextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
