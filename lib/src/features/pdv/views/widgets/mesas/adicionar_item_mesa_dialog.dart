import 'package:flutter/material.dart';
import 'package:nous/src/core/services/gerador_id.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/mesas/configuracao_item_mesa_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/mesas/seletor_itens_mesa_widget.dart';

double _precoComoNumero(String texto) {
  var limpo = texto.replaceAll(RegExp(r'[^0-9,.]'), '');
  if (limpo.contains(',')) {
    limpo = limpo.replaceAll('.', '').replaceAll(',', '.');
  }
  return double.tryParse(limpo) ?? 0;
}

class AdicionarItemMesaDialog extends StatefulWidget {
  final AppTheme theme;
  final List<CategoriaLoja> categoriasDisponiveis;
  final List<ItemLoja> itensDisponiveis;
  final List<GrupoComponentesLoja> gruposDisponiveis;
  final String autorCpf;
  final String autorNome;
  final ValueChanged<ItemComandaMesa> aoAdicionar;

  const AdicionarItemMesaDialog({
    super.key,
    required this.theme,
    this.categoriasDisponiveis = const [],
    required this.itensDisponiveis,
    this.gruposDisponiveis = const [],
    required this.autorCpf,
    required this.autorNome,
    required this.aoAdicionar,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    List<CategoriaLoja> categoriasDisponiveis = const [],
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
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 660),
            child: AdicionarItemMesaDialog(
              theme: theme,
              categoriasDisponiveis: categoriasDisponiveis,
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
  final _observacaoController = TextEditingController();

  CategoriaLoja? _categoriaSelecionada;
  bool _modoAvulso = false;
  ItemLoja? _itemSelecionado;
  VarianteItem? _varianteSelecionada;
  int _quantidade = 1;
  final Map<String, int> _acompanhamentosQuantidades = {};

  @override
  void dispose() {
    _observacaoController.dispose();
    super.dispose();
  }

  double get _precoBaseItemAtual {
    if (_itemSelecionado == null) return 0.0;
    var precoItemStr = _itemSelecionado!.preco;
    if (_varianteSelecionada != null &&
        _varianteSelecionada!.preco.isNotEmpty) {
      precoItemStr = _varianteSelecionada!.preco;
    }
    var base = _precoComoNumero(precoItemStr);
    if (_categoriaSelecionada != null) {
      base += _precoComoNumero(_categoriaSelecionada!.preco);
    }
    return base;
  }

  double get _subtotalCalculado {
    if (_itemSelecionado == null) return 0.0;
    var totalUnitario = _precoBaseItemAtual;

    for (final entrada in _acompanhamentosQuantidades.entries) {
      if (entrada.value > 0) {
        final acompItem = widget.itensDisponiveis
            .where((i) => i.id == entrada.key)
            .firstOrNull;
        if (acompItem != null) {
          totalUnitario += _precoComoNumero(acompItem.preco) * entrada.value;
        }
      }
    }
    return totalUnitario * _quantidade;
  }

  void _selecionarItem(ItemLoja item) {
    setState(() {
      _itemSelecionado = item;
      _varianteSelecionada =
          item.variantes.isNotEmpty ? item.variantes.first : null;
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

    final precoItem = (_varianteSelecionada != null &&
            _varianteSelecionada!.preco.isNotEmpty)
        ? _precoComoNumero(_varianteSelecionada!.preco)
        : _precoComoNumero(_itemSelecionado!.preco);
    final precoCategoria = _categoriaSelecionada != null
        ? _precoComoNumero(_categoriaSelecionada!.preco)
        : 0.0;

    final itemVendido = ItemVendido(
      itemId: _itemSelecionado!.id,
      nomeItem: _itemSelecionado!.nome,
      varianteNome: _varianteSelecionada?.nome ?? '',
      foto: fotoItem,
      categoriaId: _categoriaSelecionada?.id,
      nomeCategoria: _categoriaSelecionada?.nome,
      precoItem: precoItem,
      precoCategoria: precoCategoria,
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

  Widget _configuracaoItem() {
    return ConfiguracaoItemMesaWidget(
      theme: widget.theme,
      item: _itemSelecionado!,
      categoriaSelecionada: _categoriaSelecionada,
      gruposDisponiveis: widget.gruposDisponiveis,
      itensDisponiveis: widget.itensDisponiveis,
      varianteSelecionada: _varianteSelecionada,
      quantidade: _quantidade,
      acompanhamentosQuantidades: _acompanhamentosQuantidades,
      observacaoController: _observacaoController,
      precoBaseItemAtual: _precoBaseItemAtual,
      subtotalCalculado: _subtotalCalculado,
      onTrocarItem: () => setState(() => _itemSelecionado = null),
      onSelecionarVariante: (v) => setState(() => _varianteSelecionada = v),
      onAlterarQuantidade: (q) => setState(() => _quantidade = q),
      onIncrementarAcompanhamento: (id) => setState(() {
        _acompanhamentosQuantidades[id] =
            (_acompanhamentosQuantidades[id] ?? 0) + 1;
      }),
      onDecrementarAcompanhamento: (id) => setState(() {
        final atual = _acompanhamentosQuantidades[id] ?? 0;
        if (atual > 0) {
          _acompanhamentosQuantidades[id] = atual - 1;
        }
      }),
      onConfirmarLancamento: _confirmarLancamento,
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
                onPressed: () {
                  if (_itemSelecionado != null) {
                    setState(() => _itemSelecionado = null);
                  } else if (_categoriaSelecionada != null) {
                    setState(() => _categoriaSelecionada = null);
                  } else if (_modoAvulso) {
                    setState(() => _modoAvulso = false);
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
              Expanded(
                child: Text(
                  _itemSelecionado != null
                      ? 'Personalizar Item'
                      : _categoriaSelecionada != null
                          ? _categoriaSelecionada!.nome
                          : _modoAvulso
                              ? 'Itens Avulsos'
                              : 'Adicionar à Mesa',
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
            child: _itemSelecionado != null
                ? _configuracaoItem()
                : SeletorItensMesaWidget(
                    theme: widget.theme,
                    categoriasDisponiveis: widget.categoriasDisponiveis,
                    itensDisponiveis: widget.itensDisponiveis,
                    categoriaSelecionada: _categoriaSelecionada,
                    modoAvulso: _modoAvulso,
                    onSelecionarCategoria: (cat) =>
                        setState(() => _categoriaSelecionada = cat),
                    onAlternarModoAvulso: (avulso) =>
                        setState(() => _modoAvulso = avulso),
                    onSelecionarItem: _selecionarItem,
                  ),
          ),
        ],
      ),
    );
  }
}
