import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nous/src/core/services/gerador_id.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

double _precoComoNumero(String texto) {
  var limpo = texto.replaceAll(RegExp(r'[^0-9,.]'), '');
  if (limpo.contains(',')) {
    limpo = limpo.replaceAll('.', '').replaceAll(',', '.');
  }
  return double.tryParse(limpo) ?? 0;
}

String _valorFormatado(double valor) =>
    'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

class AdicionarItemMesaDialog extends StatefulWidget {
  final AppTheme theme;
  final List<ItemLoja> itensDisponiveis;
  final List<GrupoComponentesLoja> gruposDisponiveis;
  final String autorCpf;
  final String autorNome;
  final ValueChanged<ItemComandaMesa> aoAdicionar;

  const AdicionarItemMesaDialog({
    super.key,
    required this.theme,
    required this.itensDisponiveis,
    this.gruposDisponiveis = const [],
    required this.autorCpf,
    required this.autorNome,
    required this.aoAdicionar,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required List<ItemLoja> itensDisponiveis,
    List<GrupoComponentesLoja> gruposDisponiveis = const [],
    required String autorCpf,
    required String autorNome,
    required ValueChanged<ItemComandaMesa> aoAdicionar,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: theme.cardBackgroundColor,
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
            child: AdicionarItemMesaDialog(
              theme: theme,
              itensDisponiveis: itensDisponiveis,
              gruposDisponiveis: gruposDisponiveis,
              autorCpf: autorCpf,
              autorNome: autorNome,
              aoAdicionar: (item) {
                Navigator.of(dialogContext).pop();
                aoAdicionar(item);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  State<AdicionarItemMesaDialog> createState() =>
      _AdicionarItemMesaDialogState();
}

class _AdicionarItemMesaDialogState extends State<AdicionarItemMesaDialog> {
  final _pesquisaController = TextEditingController();
  final _observacaoController = TextEditingController();

  ItemLoja? _itemSelecionado;
  int _quantidade = 1;
  final Map<String, int> _acompanhamentosQuantidades = {};

  @override
  void dispose() {
    _pesquisaController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  List<ItemLoja> get _itensFiltrados {
    final query = _pesquisaController.text.trim().toLowerCase();
    if (query.isEmpty) return widget.itensDisponiveis;
    return widget.itensDisponiveis
        .where((i) => i.nome.toLowerCase().contains(query))
        .toList();
  }

  double get _subtotalCalculado {
    if (_itemSelecionado == null) return 0.0;
    var totalItem = _precoComoNumero(_itemSelecionado!.preco) * _quantidade;

    for (final entrada in _acompanhamentosQuantidades.entries) {
      if (entrada.value > 0) {
        final acompItem = widget.itensDisponiveis
            .where((i) => i.id == entrada.key)
            .firstOrNull;
        if (acompItem != null) {
          totalItem +=
              _precoComoNumero(acompItem.preco) * entrada.value * _quantidade;
        }
      }
    }
    return totalItem;
  }

  void _selecionarItem(ItemLoja item) {
    setState(() {
      _itemSelecionado = item;
      _quantidade = 1;
      _acompanhamentosQuantidades.clear();
      _observacaoController.clear();
    });
  }

  void _confirmarLancamento() {
    if (_itemSelecionado == null) return;

    final listaAcompanhamentos = <AcompanhamentoEscolhido>[];
    for (final entrada in _acompanhamentosQuantidades.entries) {
      if (entrada.value > 0) {
        final acompItem = widget.itensDisponiveis
            .where((i) => i.id == entrada.key)
            .firstOrNull;
        if (acompItem != null) {
          listaAcompanhamentos.add(
            AcompanhamentoEscolhido(
              itemId: acompItem.id,
              nomeItem: acompItem.nome,
              precoItem: _precoComoNumero(acompItem.preco),
              quantidadePorUnidade: entrada.value,
            ),
          );
        }
      }
    }

    final fotoItem = _itemSelecionado!.imagens.isNotEmpty
        ? _itemSelecionado!.imagens.first
        : '';

    final itemVendido = ItemVendido(
      itemId: _itemSelecionado!.id,
      nomeItem: _itemSelecionado!.nome,
      foto: fotoItem,
      precoItem: _precoComoNumero(_itemSelecionado!.preco),
      quantidade: _quantidade,
      acompanhamentos: listaAcompanhamentos,
      observacao: _observacaoController.text.trim(),
    );

    final itemComanda = ItemComandaMesa(
      id: gerarIdUnico(),
      item: itemVendido,
      autorCpf: widget.autorCpf,
      autorNome: widget.autorNome,
      dataHora: DateTime.now(),
    );

    widget.aoAdicionar(itemComanda);
  }

  Widget _miniaturaItem(ItemLoja item) {
    if (item.imagens.isNotEmpty && File(item.imagens.first).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(
          File(item.imagens.first),
          width: 38,
          height: 38,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.inventory_2_outlined,
            size: 24,
            color: widget.theme.textColor,
          ),
        ),
      );
    }
    return Icon(
      Icons.inventory_2_outlined,
      size: 28,
      color: widget.theme.textColor,
    );
  }

  Widget _seletorDeItens() {
    final itens = _itensFiltrados;

    return Column(
      children: [
        ThemedTextField(
          theme: widget.theme,
          controller: _pesquisaController,
          label: 'Buscar item no cardápio...',
        ),
        const SizedBox(height: 12),
        if (itens.isEmpty)
          EstadoVazioContainer(
            theme: widget.theme,
            mensagem: 'Nenhum item encontrado.',
          )
        else
          Expanded(
            child: ListView.separated(
              itemCount: itens.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final item = itens[index];
                return InkWell(
                  onTap: () => _selecionarItem(item),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.theme.backgroundColor
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: widget.theme.borderColor.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      children: [
                        _miniaturaItem(item),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.nome,
                            style: widget.theme.getTextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: widget.theme.textColor,
                            ),
                          ),
                        ),
                        Text(
                          _valorFormatado(_precoComoNumero(item.preco)),
                          style: widget.theme.getTextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: widget.theme.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _configuracaoItem() {
    final item = _itemSelecionado!;

    final gruposVinculados = widget.gruposDisponiveis.where((g) {
      return g.itemIds.contains(item.id);
    }).toList();

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
                      item.nome,
                      style: widget.theme.getTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: widget.theme.textColor,
                      ),
                    ),
                    Text(
                      _valorFormatado(_precoComoNumero(item.preco)),
                      style: widget.theme.getTextStyle(
                        fontSize: 13,
                        color: widget.theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _itemSelecionado = null),
                child: Text(
                  'Trocar item',
                  style: widget.theme.getTextStyle(
                    fontSize: 12,
                    color: widget.theme.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Seletor de Quantidade
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Quantidade:',
                style: widget.theme.getTextStyle(
                  fontSize: 14,
                  color: widget.theme.textColor,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: widget.theme.textColor,
                onPressed: _quantidade > 1
                    ? () => setState(() => _quantidade--)
                    : null,
              ),
              Text(
                '$_quantidade',
                style: widget.theme.getTextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.theme.textColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: widget.theme.textColor,
                onPressed: () => setState(() => _quantidade++),
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
                  style: widget.theme.getTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.theme.textColor,
                  ),
                ),
              ),
              for (final itemIdAcomp in grupo.itemIds) ...[
                if (itemIdAcomp != item.id) ...[
                  Builder(
                    builder: (context) {
                      final acomp = widget.itensDisponiveis
                          .where((i) => i.id == itemIdAcomp)
                          .firstOrNull;
                      if (acomp == null) return const SizedBox.shrink();

                      final qtdAtual =
                          _acompanhamentosQuantidades[acomp.id] ?? 0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${acomp.nome} (+${_valorFormatado(_precoComoNumero(acomp.preco))})',
                                style: widget.theme.getTextStyle(
                                  fontSize: 13,
                                  color: widget.theme.secondaryTextColor,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              color: widget.theme.textColor,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 28, minHeight: 28),
                              onPressed: qtdAtual > 0
                                  ? () => setState(() =>
                                      _acompanhamentosQuantidades[acomp.id] =
                                          qtdAtual - 1)
                                  : null,
                            ),
                            Text(
                              '$qtdAtual',
                              style: widget.theme.getTextStyle(fontSize: 13),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              color: widget.theme.textColor,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 28, minHeight: 28),
                              onPressed: () => setState(() =>
                                  _acompanhamentosQuantidades[acomp.id] =
                                      qtdAtual + 1),
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
            theme: widget.theme,
            controller: _observacaoController,
            label: 'Observações (ex: sem cebola, bem passado)',
            linhas: 2,
          ),
          const SizedBox(height: 16),
          // Subtotal e botão de lançamento
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: widget.theme.backgroundColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.theme.borderColor.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal do item:',
                  style: widget.theme.getTextStyle(
                    fontSize: 14,
                    color: widget.theme.secondaryTextColor,
                  ),
                ),
                Text(
                  _valorFormatado(_subtotalCalculado),
                  style: widget.theme.getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.theme.textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: widget.theme.buttonColor,
              foregroundColor: widget.theme.buttonTextColor,
              side: BorderSide(color: widget.theme.borderColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _confirmarLancamento,
            child: Text(
              'Lançar na Mesa',
              style: widget.theme.getTextStyle(
                fontSize: 14,
                color: widget.theme.buttonTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: widget.theme.textColor),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  _itemSelecionado == null
                      ? 'Adicionar Item à Mesa'
                      : 'Personalizar Item',
                  textAlign: TextAlign.center,
                  style: widget.theme.getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.theme.textColor,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _itemSelecionado == null
                ? _seletorDeItens()
                : _configuracaoItem(),
          ),
        ],
      ),
    );
  }
}
