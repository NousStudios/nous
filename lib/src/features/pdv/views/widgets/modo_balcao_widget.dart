import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/services/janela_windows_service.dart';
import 'package:nous/src/core/services/som_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/venda_concluida_dialog.dart';

const List<String> _formasBalcao = [
  'Dinheiro',
  'Pix',
  'Débito',
  'Crédito',
  'À Prazo',
];

class ModoBalcaoWidget extends StatefulWidget {
  final AppTheme theme;
  final String lojaId;
  final String nomeLoja;
  final String logoLoja;
  final List<ItemLoja> itens;
  final List<CategoriaLoja> categorias;
  final List<GrupoComponentesLoja> gruposComponentes;
  final List<Cliente> clientes;
  final List<MovimentoEstoque> movimentosEstoque;
  final ConfiguracoesImpressora configuracoesImpressora;
  final String cpfAutor;
  final String nomeAutor;
  final int proximoNumero;
  final bool caixaAberto;
  final VoidCallback onSair;
  final void Function(
    PedidoLoja pedido,
    List<MovimentoEstoque> movimentosEstoque,
  ) onConcluirVenda;

  const ModoBalcaoWidget({
    super.key,
    required this.theme,
    required this.lojaId,
    required this.nomeLoja,
    required this.logoLoja,
    required this.itens,
    required this.categorias,
    required this.gruposComponentes,
    required this.clientes,
    required this.movimentosEstoque,
    required this.configuracoesImpressora,
    required this.cpfAutor,
    required this.nomeAutor,
    required this.proximoNumero,
    required this.caixaAberto,
    required this.onSair,
    required this.onConcluirVenda,
  });

  @override
  State<ModoBalcaoWidget> createState() => _ModoBalcaoWidgetState();
}

class _ModoBalcaoWidgetState extends State<ModoBalcaoWidget> {
  final _bipadorController = TextEditingController();
  final _bipadorFocusNode = FocusNode();
  final _clienteController = TextEditingController();
  final _clienteFocusNode = FocusNode();
  final _descontoController = TextEditingController();
  final _acrescimoController = TextEditingController();
  final _freteController = TextEditingController();
  final _valorRecebidoController = TextEditingController();

  final List<ItemVendido> _carrinho = [];
  ItemLoja? _ultimoItemBipado;
  ItemVendido? _ultimoItemVendido;
  int _quantidadeUltimoBipado = 1;

  String? _categoriaFiltroId;
  Cliente? _clienteSelecionado;
  bool _mostrarSugestoesCliente = false;

  String _formaPagamentoSelecionada = 'Dinheiro';
  String? _aviso;

  AppTheme get theme => widget.theme;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_tratarTecladoGlobal);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _garantirFocoBipador();
      }
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_tratarTecladoGlobal);
    _bipadorController.dispose();
    _bipadorFocusNode.dispose();
    _clienteController.dispose();
    _clienteFocusNode.dispose();
    _descontoController.dispose();
    _acrescimoController.dispose();
    _freteController.dispose();
    _valorRecebidoController.dispose();
    super.dispose();
  }

  bool _tratarTecladoGlobal(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.f11) {
      JanelaWindowsService.alternarTelaCheia();
      return true;
    }
    return false;
  }

  List<Cliente> get _sugestoesClientes {
    final termo = _clienteController.text.trim();
    if (termo.isEmpty) return widget.clientes;
    return widget.clientes.where((c) => c.correspondeABusca(termo)).toList();
  }

  CategoriaLoja? _obterCategoriaDoItem(ItemLoja item) {
    if (_categoriaFiltroId != null) {
      final cat = widget.categorias
          .where((c) => c.id == _categoriaFiltroId)
          .firstOrNull;
      if (cat != null && cat.itemIds.contains(item.id)) {
        return cat;
      }
    }
    return null;
  }

  void _garantirFocoBipador() {
    if (!_bipadorFocusNode.hasFocus &&
        !_clienteFocusNode.hasFocus &&
        !_mostrarSugestoesCliente) {
      _bipadorFocusNode.requestFocus();
    }
  }

  double _saldoEstoque(String itemId) {
    var saldo = 0.0;
    for (final m in widget.movimentosEstoque) {
      if (m.itemId == itemId) {
        saldo += m.quantidadeComSinal;
      }
    }
    return saldo;
  }

  double _precoComoNumero(String texto) {
    var limpo = texto.replaceAll(RegExp(r'[^0-9,.]'), '');
    if (limpo.contains(',')) {
      limpo = limpo.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(limpo) ?? 0;
  }

  String _valorFormatado(double valor) =>
      valor.toStringAsFixed(2).replaceAll('.', ',');

  double get _subtotalCarrinho {
    return _carrinho.fold<double>(0.0, (soma, item) => soma + item.subtotal);
  }

  double get _freteValor {
    return _precoComoNumero(_freteController.text);
  }

  double get _descontoValor {
    return _precoComoNumero(_descontoController.text);
  }

  double get _acrescimoValor {
    return _precoComoNumero(_acrescimoController.text);
  }

  double get _totalGeral {
    final sub = _subtotalCarrinho;
    final total = sub + _freteValor - _descontoValor + _acrescimoValor;
    return total < 0 ? 0 : total;
  }

  double get _valorRecebido {
    return _precoComoNumero(_valorRecebidoController.text);
  }

  double get _trocoCalculado {
    if (_formaPagamentoSelecionada != 'Dinheiro') return 0.0;
    final recebido = _valorRecebido;
    final total = _totalGeral;
    if (recebido > total) {
      return recebido - total;
    }
    return 0.0;
  }

  List<ItemLoja> get _itensFiltrados {
    final termo = _bipadorController.text.trim().toLowerCase();
    var lista = widget.itens.where((i) {
      if (_categoriaFiltroId != null) {
        final cat = widget.categorias
            .where((c) => c.id == _categoriaFiltroId)
            .firstOrNull;
        if (cat != null && !cat.itemIds.contains(i.id)) {
          return false;
        }
      }
      if (termo.isEmpty) return true;
      final nome = i.nome.toLowerCase();
      final codigo = i.codigoBarras.trim().toLowerCase();
      return nome.contains(termo) || codigo.contains(termo);
    }).toList();
    return lista;
  }

  void _aoDigitarBipador(String valor) {
    setState(() {});
  }

  void _aoPressionarEnterBipador() {
    final codigo = _bipadorController.text.trim();
    if (codigo.isEmpty) return;

    // 1. Tenta correspondência exata por código de barras
    final itemPorCodigo = widget.itens.where((i) {
      final cb = i.codigoBarras.trim().toLowerCase();
      return cb.isNotEmpty && cb == codigo.toLowerCase();
    }).firstOrNull;

    if (itemPorCodigo != null) {
      _processarAdicaoItemAoCarrinho(itemPorCodigo);
      _bipadorController.clear();
      _garantirFocoBipador();
      return;
    }

    // 2. Tenta por nome exato
    final itemPorNome = widget.itens.where((i) {
      return i.nome.trim().toLowerCase() == codigo.toLowerCase();
    }).firstOrNull;

    if (itemPorNome != null) {
      _processarAdicaoItemAoCarrinho(itemPorNome);
      _bipadorController.clear();
      _garantirFocoBipador();
      return;
    }

    // 3. Se houver apenas um resultado filtrado na lista, adiciona ele
    final filtrados = _itensFiltrados;
    if (filtrados.length == 1) {
      _processarAdicaoItemAoCarrinho(filtrados.first);
      _bipadorController.clear();
      _garantirFocoBipador();
      return;
    }

    setState(() {
      _aviso = 'Produto "$codigo" não encontrado.';
    });
  }

  Future<void> _processarAdicaoItemAoCarrinho(ItemLoja item) async {
    if (item.variantes.isNotEmpty) {
      final varianteEscolhida = await _selecionarVarianteDialog(item);
      if (varianteEscolhida == null) return;
      _adicionarItemAoCarrinho(item, variante: varianteEscolhida);
    } else {
      _adicionarItemAoCarrinho(item);
    }
  }

  Future<VarianteItem?> _selecionarVarianteDialog(ItemLoja item) {
    return showDialog<VarianteItem>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.borderColor),
        ),
        title: Text(
          'Escolha a Variante\n${item.nome}',
          textAlign: TextAlign.center,
          style: theme.getTextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        content: SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: theme.borderColor.withValues(alpha: 0.5),
                    ),
                  ),
                  title: Text(
                    'Padrão',
                    style: theme.getTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                  trailing: Text(
                    'R\$ ${item.preco}',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                  onTap: () => Navigator.of(dialogCtx).pop(
                    VarianteItem(nome: '', preco: item.preco),
                  ),
                ),
                const SizedBox(height: 8),
                for (final v in item.variantes) ...[
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: theme.borderColor.withValues(alpha: 0.5),
                      ),
                    ),
                    title: Text(
                      v.nome,
                      style: theme.getTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    trailing: Text(
                      'R\$ ${v.preco.isNotEmpty ? v.preco : item.preco}',
                      style: theme.getTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    onTap: () => Navigator.of(dialogCtx).pop(v),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
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
        ],
      ),
    );
  }

  void _adicionarItemAoCarrinho(ItemLoja item, {VarianteItem? variante}) {
    SomService.tocarBipPadrao();
    final categoria = _obterCategoriaDoItem(item);
    final precoCat =
        categoria != null ? _precoComoNumero(categoria.preco) : 0.0;
    final precoItem = (variante != null && variante.preco.trim().isNotEmpty)
        ? _precoComoNumero(variante.preco)
        : _precoComoNumero(item.preco);
    final nomeVar = (variante != null && variante.nome.trim().isNotEmpty)
        ? variante.nome.trim()
        : '';

    setState(() {
      _aviso = null;
      _ultimoItemBipado = item;
      _quantidadeUltimoBipado = 1;

      final indice = _carrinho.indexWhere(
        (it) =>
            it.itemId == item.id &&
            it.categoriaId == categoria?.id &&
            it.varianteNome == nomeVar,
      );

      if (indice != -1) {
        final atual = _carrinho[indice];
        final atualizado = atual.copyWith(quantidade: atual.quantidade + 1);
        _carrinho[indice] = atualizado;
        _quantidadeUltimoBipado = atualizado.quantidade;
        _ultimoItemVendido = atualizado;
      } else {
        final novo = ItemVendido(
          itemId: item.id,
          nomeItem: item.nome,
          categoriaId: categoria?.id,
          nomeCategoria: categoria?.nome,
          varianteNome: nomeVar,
          precoItem: precoItem,
          precoCategoria: precoCat,
          quantidade: 1,
          foto: item.imagens.firstOrNull ?? '',
        );
        _carrinho.add(novo);
        _ultimoItemVendido = novo;
      }
    });
  }

  void _alterarQuantidadeCarrinho(int indice, int delta) {
    setState(() {
      final atual = _carrinho[indice];
      final novaQtd = atual.quantidade + delta;
      if (novaQtd <= 0) {
        _carrinho.removeAt(indice);
        if (_ultimoItemVendido?.itemId == atual.itemId &&
            _ultimoItemVendido?.categoriaId == atual.categoriaId) {
          _ultimoItemVendido = null;
        }
      } else {
        final atualizado = atual.copyWith(quantidade: novaQtd);
        _carrinho[indice] = atualizado;
        if (_ultimoItemVendido?.itemId == atual.itemId &&
            _ultimoItemVendido?.categoriaId == atual.categoriaId) {
          _ultimoItemVendido = atualizado;
          _quantidadeUltimoBipado = novaQtd;
        }
      }
    });
  }

  void _removerItemCarrinho(int indice) {
    setState(() {
      final removido = _carrinho.removeAt(indice);
      if (_ultimoItemVendido?.itemId == removido.itemId &&
          _ultimoItemVendido?.categoriaId == removido.categoriaId) {
        _ultimoItemVendido = null;
      }
    });
  }

  List<GrupoComponentesLoja> _obterGruposDoItemVendido(ItemVendido item) {
    if (item.categoriaId != null) {
      final cat = widget.categorias
          .where((c) => c.id == item.categoriaId)
          .firstOrNull;
      if (cat != null && cat.grupoIds.isNotEmpty) {
        final grupos = widget.gruposComponentes
            .where((g) => cat.grupoIds.contains(g.id))
            .toList();
        if (grupos.isNotEmpty) return grupos;
      }
    }
    return widget.gruposComponentes;
  }

  void _abrirDialogoComponentes(int indice) {
    final item = _carrinho[indice];
    final grupos = _obterGruposDoItemVendido(item);

    if (grupos.isEmpty) {
      _editarObservacaoItem(indice);
      return;
    }

    final selecionados = <String, int>{};
    for (final a in item.acompanhamentos) {
      selecionados[a.itemId] = a.quantidadePorUnidade;
    }
    final obsController = TextEditingController(text: item.observacao);

    showDialog<void>(
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
                              final comp = widget.itens
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
                        final comp = widget.itens
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

                    setState(() {
                      final itemAtualizado = item.copyWith(
                        acompanhamentos: novosAcomp,
                        observacao: obsController.text.trim(),
                      );
                      _carrinho[indice] = itemAtualizado;
                      if (_ultimoItemVendido?.itemId == item.itemId &&
                          _ultimoItemVendido?.categoriaId ==
                              item.categoriaId) {
                        _ultimoItemVendido = itemAtualizado;
                      }
                    });

                    Navigator.of(dialogContext).pop();
                    _garantirFocoBipador();
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

  void _editarObservacaoItem(int indice) {
    final item = _carrinho[indice];
    final controller = TextEditingController(text: item.observacao);

    showDialog<void>(
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
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'Cancelar',
              style: theme.getTextStyle(color: theme.secondaryTextColor),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                final atualizado = item.copyWith(
                  observacao: controller.text.trim(),
                );
                _carrinho[indice] = atualizado;
                if (_ultimoItemVendido?.itemId == item.itemId &&
                    _ultimoItemVendido?.categoriaId == item.categoriaId) {
                  _ultimoItemVendido = atualizado;
                }
              });
              Navigator.of(dialogCtx).pop();
              _garantirFocoBipador();
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

  void _limparVenda() {
    setState(() {
      _carrinho.clear();
      _ultimoItemBipado = null;
      _ultimoItemVendido = null;
      _clienteSelecionado = null;
      _mostrarSugestoesCliente = false;
      _clienteController.clear();
      _freteController.clear();
      _descontoController.clear();
      _acrescimoController.clear();
      _valorRecebidoController.clear();
      _formaPagamentoSelecionada = 'Dinheiro';
      _bipadorController.clear();
      _aviso = null;
    });
    _garantirFocoBipador();
  }

  String _montarComanda() {
    final buffer = StringBuffer();
    for (final it in _carrinho) {
      buffer.writeln(
          '${it.quantidade}x ${it.nomeExibicao} - R\$ ${_valorFormatado(it.subtotal)}');
      if (it.observacao.trim().isNotEmpty) {
        buffer.writeln('   Obs: ${it.observacao.trim()}');
      }
      for (final a in it.acompanhamentos) {
        buffer.writeln('   + ${a.quantidadePorUnidade}x ${a.nomeItem}');
      }
    }
    if (_freteValor > 0) {
      buffer.writeln('Frete: + R\$ ${_valorFormatado(_freteValor)}');
    }
    if (_acrescimoValor > 0) {
      buffer.writeln('Acréscimo: + R\$ ${_valorFormatado(_acrescimoValor)}');
    }
    if (_descontoValor > 0) {
      buffer.writeln('Desconto: - R\$ ${_valorFormatado(_descontoValor)}');
    }
    return buffer.toString().trim();
  }

  Future<void> _finalizarVenda() async {
    if (_carrinho.isEmpty) {
      setState(() => _aviso = 'Insira pelo menos um item na comanda.');
      return;
    }

    final total = _totalGeral;
    final agora = DateTime.now();
    final clienteNome = _clienteSelecionado?.nome ??
        (_clienteController.text.trim().isNotEmpty
            ? _clienteController.text.trim()
            : 'Consumidor Final');

    final resumoItens =
        _carrinho.map((i) => '${i.quantidade}x ${i.nomeExibicao}').join(', ');
    final temPrazo = _formaPagamentoSelecionada.toLowerCase().contains('prazo');

    if (temPrazo && _clienteSelecionado == null) {
      setState(() {
        _aviso = 'Selecione um cliente cadastrado para vender a prazo.';
        _mostrarSugestoesCliente = true;
      });
      _clienteFocusNode.requestFocus();
      return;
    }

    final pedido = PedidoLoja(
      id: agora.millisecondsSinceEpoch.toString(),
      numero: widget.proximoNumero,
      clienteId: _clienteSelecionado?.id,
      clienteNome: clienteNome,
      produtoNome: resumoItens,
      dataHora: agora,
      valor: total,
      status: StatusPedido.concluido,
      comanda: _montarComanda(),
      formaPagamento: _formaPagamentoSelecionada,
      pagamentosExtras: const [],
      valorRecebido: _formaPagamentoSelecionada == 'Dinheiro' && _valorRecebido > 0
          ? _valorRecebido
          : total,
      troco: _trocoCalculado,
      quitado: !temPrazo,
      valorPago: !temPrazo ? total : 0.0,
      itens: List.of(_carrinho),
      frete: _freteValor,
      desconto: _descontoValor,
      acrescimo: _acrescimoValor,
      nomeVendedor: widget.nomeAutor,
      cnpjVendedor: widget.cpfAutor,
    );

    // Gera baixas automáticas proporcionais de estoque
    final baixas = <MovimentoEstoque>[];
    for (final it in _carrinho) {
      final itemLoja = widget.itens.where((i) => i.id == it.itemId).firstOrNull;
      final consumo = (itemLoja?.consumoPorVenda ?? 1.0) * it.quantidade;
      final custoUnit = double.tryParse(
              (itemLoja?.precoCusto ?? '').replaceAll(',', '.')) ??
          0.0;
      baixas.add(
        MovimentoEstoque.novo(
          itemId: it.itemId,
          tipo: TipoMovimentoEstoque.saida,
          quantidade: consumo,
          custoUnitario: custoUnit,
          motivo:
              'Venda #${pedido.numero.toString().padLeft(4, '0')} no Modo Balcão',
          cpfAutor: widget.cpfAutor,
          nomeAutor: widget.nomeAutor,
          categoria: CategoriaMovimentoEstoque.venda,
        ),
      );
    }

    // Diálogo com opção de impressão de cupom térmico
    final confirmou = await VendaConcluidaDialog.mostrar(
      context,
      theme: theme,
      pedido: pedido,
      configuracoesImpressora: widget.configuracoesImpressora,
      cliente: _clienteSelecionado,
    );

    if (confirmou) {
      widget.onConcluirVenda(pedido, baixas);
      _limparVenda();
    }
  }

  @override
  Widget build(BuildContext context) {
    final temLogo = widget.logoLoja.isNotEmpty && File(widget.logoLoja).existsSync();

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): widget.onSair,
        const SingleActivator(LogicalKeyboardKey.f11): () {
          JanelaWindowsService.alternarTelaCheia();
        },
      },
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // ═══ BARRA SUPERIOR DO MODO BALCÃO ═══
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.cardBackgroundColor.withValues(alpha: 0.9),
                  border: Border(
                    bottom: BorderSide(
                      color: theme.borderColor.withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.textColor,
                        side: BorderSide(color: theme.borderColor),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: widget.onSair,
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: Text(
                        'Voltar ao PDV (Esc)',
                        style: theme.getTextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.borderColor.withValues(alpha: 0.3),
                      backgroundImage:
                          temLogo ? FileImage(File(widget.logoLoja)) : null,
                      child: !temLogo
                          ? Icon(Icons.storefront,
                              size: 16, color: theme.textColor)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.nomeLoja.isNotEmpty
                              ? widget.nomeLoja
                              : 'Minha Loja',
                          style: theme.getTextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.caixaAberto
                                    ? const Color(0xFF4CAF50)
                                    : theme.secondaryTextColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.caixaAberto ? 'Caixa Aberto' : 'Caixa Fechado',
                              style: theme.getTextStyle(
                                fontSize: 11,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.borderColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.textColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.point_of_sale_rounded,
                              size: 16, color: theme.textColor),
                          const SizedBox(width: 8),
                          Text(
                            'MODO BALCÃO • FRENTE DE CAIXA',
                            style: theme.getTextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ).copyWith(letterSpacing: 0.8),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: Icon(Icons.fullscreen_rounded,
                          color: theme.textColor, size: 20),
                      tooltip: 'Alternar Tela Cheia (F11)',
                      onPressed: () => JanelaWindowsService.alternarTelaCheia(),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_sweep_outlined,
                          color: theme.secondaryTextColor, size: 20),
                      tooltip: 'Limpar Venda Atual',
                      onPressed: _limparVenda,
                    ),
                  ],
                ),
              ),

              // ═══ CORPO PRINCIPAL: 2 GRANDES ÁREAS (OPERADOR & CLIENTE) ═══
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── ÁREA 1: OPERADOR (BIPADOR, VISOR DO PRODUTO & CATÁLOGO) ──
                    Expanded(
                      flex: 6,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Campo de Bipagem e Leitura de Código
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: theme.cardBackgroundColor
                                    .withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: theme.textColor.withValues(alpha: 0.7),
                                  width: 1.8,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.qr_code_scanner_rounded,
                                      size: 26, color: theme.textColor),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _bipadorController,
                                      focusNode: _bipadorFocusNode,
                                      autofocus: true,
                                      cursorColor: theme.textColor,
                                      style: theme.getTextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: theme.textColor,
                                      ),
                                      decoration: InputDecoration(
                                        hintText:
                                            'Passe o código de barras ou digite o nome do item e aperte Enter...',
                                        hintStyle: theme.getTextStyle(
                                          fontSize: 13,
                                          color: theme.secondaryTextColor
                                              .withValues(alpha: 0.7),
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                      onChanged: _aoDigitarBipador,
                                      onSubmitted: (_) =>
                                          _aoPressionarEnterBipador(),
                                    ),
                                  ),
                                  if (_bipadorController.text.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      color: theme.secondaryTextColor,
                                      onPressed: () {
                                        _bipadorController.clear();
                                        setState(() {});
                                        _garantirFocoBipador();
                                      },
                                    ),
                                  const SizedBox(width: 4),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.buttonColor !=
                                              Colors.transparent
                                          ? theme.buttonColor
                                          : theme.borderColor
                                              .withValues(alpha: 0.3),
                                      foregroundColor: theme.textColor,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(color: theme.textColor),
                                      ),
                                    ),
                                    onPressed: _aoPressionarEnterBipador,
                                    icon: const Icon(Icons.add, size: 18),
                                    label: Text(
                                      'Inserir (Enter)',
                                      style: theme.getTextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // 2. Visor do Último Produto Registrado (Visor do Caixa)
                            _buildVisorUltimoProduto(),
                            const SizedBox(height: 12),

                            // 3. Barra de Categorias e Filtros Rápidos
                            _buildBarraCategorias(),
                            const SizedBox(height: 10),

                            // 4. Catálogo Visual de Produtos
                            Expanded(
                              child: _buildCatalogoProdutos(),
                            ),
                            const SizedBox(height: 10),

                            // 5. Linha de Cliente e Descontos Rápidos
                            _buildSecaoClienteEAjustes(),
                          ],
                        ),
                      ),
                    ),

                    // Divisória vertical suave
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: theme.borderColor.withValues(alpha: 0.5),
                    ),

                    // ── ÁREA 2: A GRANDE COMANDA AMPLIADA (CLIENTE & OPERADOR) ──
                    Expanded(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        color: theme.cardBackgroundColor.withValues(alpha: 0.4),
                        child: _buildComandaAmpliada(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══ VISOR DO ÚLTIMO PRODUTO BIPADO ═══
  Widget _buildVisorUltimoProduto() {
    final itemVendido = _ultimoItemVendido;
    final item = _ultimoItemBipado;
    final foto = item?.imagens.firstOrNull ?? itemVendido?.foto ?? '';
    final temFoto = foto.isNotEmpty && File(foto).existsSync();
    final nomeExibicao = itemVendido?.nomeExibicao ?? item?.nome ?? '';
    final precoUnitario =
        itemVendido?.precoUnitario ?? _precoComoNumero(item?.preco ?? '');
    final totalItem = itemVendido?.subtotal ??
        (precoUnitario * _quantidadeUltimoBipado);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.borderColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              image: temFoto
                  ? DecorationImage(
                      image: FileImage(File(foto)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: !temFoto
                ? Icon(Icons.shopping_bag_outlined,
                    size: 28, color: theme.textColor)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item != null || itemVendido != null
                      ? 'ÚLTIMO PRODUTO: $nomeExibicao'
                      : 'NENHUM PRODUTO REGISTRADO AINDA',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: item != null || itemVendido != null
                        ? theme.textColor
                        : theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item != null || itemVendido != null
                      ? 'Qtd: $_quantidadeUltimoBipado | Unitário: R\$ ${_valorFormatado(precoUnitario)}'
                      : 'Passe o leitor óptico sobre o código de barras',
                  style: theme.getTextStyle(
                    fontSize: 11,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          if (item != null || itemVendido != null)
            Text(
              'R\$ ${_valorFormatado(totalItem)}',
              style: theme.getTextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
        ],
      ),
    );
  }

  // ═══ BARRA DE CATEGORIAS ═══
  Widget _buildBarraCategorias() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChipCategoria(
            titulo: 'Todos',
            selecionado: _categoriaFiltroId == null,
            onTap: () => setState(() => _categoriaFiltroId = null),
          ),
          for (final cat in widget.categorias)
            _buildChipCategoria(
              titulo: cat.nome,
              selecionado: _categoriaFiltroId == cat.id,
              onTap: () => setState(() => _categoriaFiltroId = cat.id),
            ),
        ],
      ),
    );
  }

  Widget _buildChipCategoria({
    required String titulo,
    required bool selecionado,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          onTap();
          _garantirFocoBipador();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selecionado
                ? (theme.buttonColor != Colors.transparent
                    ? theme.buttonColor.withValues(alpha: 0.8)
                    : theme.borderColor.withValues(alpha: 0.35))
                : theme.backgroundColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selecionado
                  ? theme.textColor
                  : theme.borderColor.withValues(alpha: 0.5),
              width: selecionado ? 1.4 : 1.0,
            ),
          ),
          child: Text(
            titulo,
            style: theme.getTextStyle(
              fontSize: 11,
              fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
              color: selecionado ? theme.textColor : theme.secondaryTextColor,
            ),
          ),
        ),
      ),
    );
  }

  // ═══ CATÁLOGO VISUAL DE PRODUTOS ═══
  Widget _buildCatalogoProdutos() {
    final itens = _itensFiltrados;
    if (itens.isEmpty) {
      return Center(
        child: Text(
          'Nenhum produto encontrado.',
          style: theme.getTextStyle(
            fontSize: 12,
            color: theme.secondaryTextColor,
          ),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        mainAxisExtent: 120,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: itens.length,
      itemBuilder: (context, index) {
        final item = itens[index];
        final foto = item.imagens.firstOrNull ?? '';
        final temFoto = foto.isNotEmpty && File(foto).existsSync();
        final saldo = _saldoEstoque(item.id);
        final esgotado = saldo <= 0;

        return InkWell(
          onTap: () {
            _processarAdicaoItemAoCarrinho(item);
            _garantirFocoBipador();
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: theme.backgroundColor.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(9)),
                          image: temFoto
                              ? DecorationImage(
                                  image: FileImage(File(foto)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: theme.borderColor.withValues(alpha: 0.15),
                        ),
                        child: !temFoto
                            ? Center(
                                child: Icon(Icons.shopping_bag_outlined,
                                    size: 24,
                                    color: theme.secondaryTextColor),
                              )
                            : null,
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: esgotado
                                ? Colors.redAccent.withValues(alpha: 0.85)
                                : theme.cardBackgroundColor
                                    .withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            esgotado
                                ? 'Esgotado'
                                : 'Est: ${formatarQuantidadeComUnidade(saldo, item.unidadeBase)}',
                            style: theme.getTextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: esgotado ? theme.textColor : theme.textColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.getTextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                      Text(
                        'R\$ ${item.preco}',
                        style: theme.getTextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══ LINHA DE CLIENTE E AJUSTES RÁPIDOS COM SUGESTÕES ═══
  Widget _buildSecaoClienteEAjustes() {
    return TapRegion(
      groupId: 'balcao_cliente_busca',
      onTapOutside: (_) {
        if (_mostrarSugestoesCliente) {
          setState(() => _mostrarSugestoesCliente = false);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_mostrarSugestoesCliente && _clienteSelecionado == null)
            _buildPainelSugestoesCliente(),
          _buildLinhaClienteEAjustes(),
        ],
      ),
    );
  }

  Widget _buildPainelSugestoesCliente() {
    final clientes = _sugestoesClientes;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      constraints: const BoxConstraints(maxHeight: 180),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: clientes.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                widget.clientes.isEmpty
                    ? 'Nenhum cliente cadastrado no sistema.'
                    : 'Nenhum cliente encontrado para este termo.',
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              itemCount: clientes.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: theme.borderColor.withValues(alpha: 0.2),
              ),
              itemBuilder: (context, index) {
                final c = clientes[index];
                final temFoto = c.foto.isNotEmpty && File(c.foto).existsSync();
                final doc = c.cnpj.isNotEmpty ? c.cnpj : '';
                final tel = c.telefone.isNotEmpty ? c.telefone : '';
                final end = c.endereco.isNotEmpty
                    ? '${c.endereco}${c.numero.isNotEmpty ? ', nº ${c.numero}' : ''}'
                    : '';

                return InkWell(
                  onTap: () {
                    setState(() {
                      _clienteSelecionado = c;
                      _clienteController.text = c.nome;
                      _mostrarSugestoesCliente = false;
                    });
                    _garantirFocoBipador();
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              theme.borderColor.withValues(alpha: 0.3),
                          backgroundImage:
                              temFoto ? FileImage(File(c.foto)) : null,
                          child: !temFoto
                              ? Icon(Icons.person,
                                  size: 18, color: theme.textColor)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.nome,
                                style: theme.getTextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor,
                                ),
                              ),
                              if (doc.isNotEmpty || tel.isNotEmpty)
                                Text(
                                  [if (doc.isNotEmpty) doc, if (tel.isNotEmpty) tel]
                                      .join(' • '),
                                  style: theme.getTextStyle(
                                    fontSize: 10,
                                    color: theme.secondaryTextColor,
                                  ),
                                ),
                              if (end.isNotEmpty)
                                Text(
                                  end,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.getTextStyle(
                                    fontSize: 10,
                                    color: theme.secondaryTextColor,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Icon(Icons.add_circle_outline,
                            size: 18, color: theme.secondaryTextColor),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildLinhaClienteEAjustes() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.person_outline, size: 18, color: theme.secondaryTextColor),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: _clienteSelecionado != null
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.borderColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.borderColor),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor:
                              theme.borderColor.withValues(alpha: 0.3),
                          backgroundImage: (_clienteSelecionado!.foto.isNotEmpty &&
                                  File(_clienteSelecionado!.foto).existsSync())
                              ? FileImage(File(_clienteSelecionado!.foto))
                              : null,
                          child: (_clienteSelecionado!.foto.isEmpty ||
                                  !File(_clienteSelecionado!.foto).existsSync())
                              ? Icon(Icons.person,
                                  size: 14, color: theme.textColor)
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _clienteSelecionado!.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.getTextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _clienteSelecionado = null;
                              _clienteController.clear();
                              _mostrarSugestoesCliente = false;
                              if (_formaPagamentoSelecionada
                                  .toLowerCase()
                                  .contains('prazo')) {
                                _formaPagamentoSelecionada = 'Dinheiro';
                              }
                            });
                            _garantirFocoBipador();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(Icons.close,
                                size: 14, color: theme.secondaryTextColor),
                          ),
                        ),
                      ],
                    ),
                  )
                : TextField(
                    controller: _clienteController,
                    focusNode: _clienteFocusNode,
                    cursorColor: theme.textColor,
                    style: theme.getTextStyle(fontSize: 11),
                    decoration: InputDecoration(
                      hintText: 'Cliente (clique ou digite p/ buscar)',
                      hintStyle: theme.getTextStyle(
                          fontSize: 11, color: theme.secondaryTextColor),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onTap: () {
                      setState(() => _mostrarSugestoesCliente = true);
                    },
                    onChanged: (v) {
                      setState(() => _mostrarSugestoesCliente = true);
                    },
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _descontoController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              cursorColor: theme.textColor,
              style: theme.getTextStyle(fontSize: 11),
              decoration: InputDecoration(
                hintText: 'Desc: 0,00',
                hintStyle: theme.getTextStyle(
                    fontSize: 11, color: theme.secondaryTextColor),
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _freteController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  cursorColor: theme.textColor,
                  style: theme.getTextStyle(fontSize: 11),
                  decoration: InputDecoration(
                    hintText: 'Frete: 0,00',
                    hintStyle: theme.getTextStyle(
                        fontSize: 11, color: theme.secondaryTextColor),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                Container(
                  height: 1,
                  color: theme.borderColor.withValues(alpha: 0.25),
                  margin: const EdgeInsets.symmetric(vertical: 2),
                ),
                TextField(
                  controller: _acrescimoController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  cursorColor: theme.textColor,
                  style: theme.getTextStyle(fontSize: 11),
                  decoration: InputDecoration(
                    hintText: 'Acrésc: 0,00',
                    hintStyle: theme.getTextStyle(
                        fontSize: 11, color: theme.secondaryTextColor),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══ ÁREA 2: A GRANDE COMANDA AMPLIADA DO CLIENTE ═══
  Widget _buildComandaAmpliada() {
    final subtotal = _subtotalCarrinho;
    final total = _totalGeral;
    final troco = _trocoCalculado;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cabeçalho da Comanda do Balcão
        Row(
          children: [
            Icon(Icons.receipt_long_rounded, size: 24, color: theme.textColor),
            const SizedBox(width: 10),
            Text(
              'COMANDA DA COMPRA',
              style: theme.getTextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ).copyWith(letterSpacing: 0.8),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.borderColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${_carrinho.length} ${_carrinho.length == 1 ? "item" : "itens"}',
                style: theme.getTextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Divider(height: 1, color: theme.borderColor.withValues(alpha: 0.4)),
        const SizedBox(height: 8),

        // Lista de Itens Ampliada (Visível com clareza para o Cliente no Balcão)
        Expanded(
          child: _carrinho.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: theme.secondaryTextColor.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'CAIXA LIVRE',
                        style: theme.getTextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Passe o primeiro produto no leitor de código de barras.',
                        textAlign: TextAlign.center,
                        style: theme.getTextStyle(
                          fontSize: 13,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _carrinho.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 12,
                    color: theme.borderColor.withValues(alpha: 0.2),
                  ),
                  itemBuilder: (context, index) {
                    final item = _carrinho[index];
                    final itemTotal = item.subtotal;
                    final temFoto = item.foto.isNotEmpty &&
                        File(item.foto).existsSync();

                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.backgroundColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: theme.borderColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              image: temFoto
                                  ? DecorationImage(
                                      image: FileImage(File(item.foto)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: !temFoto
                                ? Icon(Icons.shopping_bag_outlined,
                                    size: 20, color: theme.secondaryTextColor)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.nomeExibicao,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.getTextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.quantidade}x R\$ ${_valorFormatado(item.precoUnitario)}',
                                  style: theme.getTextStyle(
                                    fontSize: 12,
                                    color: theme.secondaryTextColor,
                                  ),
                                ),
                                if (item.acompanhamentos.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    item.acompanhamentos
                                        .map((a) =>
                                            '${a.quantidadePorUnidade}x ${a.nomeItem} (+R\$ ${_valorFormatado(a.precoItem * a.quantidadePorUnidade)})')
                                        .join(' • '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.getTextStyle(
                                      fontSize: 10,
                                      color: theme.secondaryTextColor,
                                    ),
                                  ),
                                ],
                                if (item.observacao.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    'Obs: ${item.observacao}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.getTextStyle(
                                      fontSize: 11,
                                      color: theme.textColor
                                          .withValues(alpha: 0.85),
                                    ).copyWith(fontStyle: FontStyle.italic),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    if (_obterGruposDoItemVendido(item)
                                        .isNotEmpty)
                                      InkWell(
                                        onTap: () =>
                                            _abrirDialogoComponentes(index),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: item
                                                    .acompanhamentos.isNotEmpty
                                                ? theme.textColor
                                                    .withValues(alpha: 0.12)
                                                : theme.borderColor
                                                    .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: item.acompanhamentos
                                                      .isNotEmpty
                                                  ? theme.textColor
                                                  : theme.borderColor
                                                      .withValues(alpha: 0.4),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.tune,
                                                  size: 11,
                                                  color: theme.textColor),
                                              const SizedBox(width: 4),
                                              Text(
                                                item.acompanhamentos.isNotEmpty
                                                    ? 'Componentes (${item.acompanhamentos.length})'
                                                    : '+ Componentes',
                                                style: theme.getTextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w600,
                                                  color: theme.textColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    InkWell(
                                      onTap: () =>
                                          _editarObservacaoItem(index),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: item.observacao.isNotEmpty
                                              ? theme.textColor
                                                  .withValues(alpha: 0.12)
                                              : theme.borderColor
                                                  .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: item.observacao.isNotEmpty
                                                ? theme.textColor
                                                : theme.borderColor
                                                    .withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.edit_note_outlined,
                                                size: 12,
                                                color: theme.textColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              item.observacao.isNotEmpty
                                                  ? 'Editar Obs'
                                                  : '+ Observação',
                                              style: theme.getTextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w600,
                                                color: theme.textColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Controles de quantidade
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    size: 18),
                                color: theme.secondaryTextColor,
                                onPressed: () =>
                                    _alterarQuantidadeCarrinho(index, -1),
                              ),
                              Text(
                                '${item.quantidade}',
                                style: theme.getTextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline,
                                    size: 18),
                                color: theme.secondaryTextColor,
                                onPressed: () =>
                                    _alterarQuantidadeCarrinho(index, 1),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'R\$ ${_valorFormatado(itemTotal)}',
                            style: theme.getTextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                size: 16, color: Colors.redAccent),
                            tooltip: 'Remover',
                            onPressed: () => _removerItemCarrinho(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 10),

        // Painel de Formas de Pagamento
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final forma in _formasBalcao)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () {
                      if (forma.toLowerCase().contains('prazo') &&
                          _clienteSelecionado == null) {
                        setState(() {
                          _aviso =
                              'Selecione um cliente cadastrado para vender a prazo.';
                          _mostrarSugestoesCliente = true;
                        });
                        _clienteFocusNode.requestFocus();
                        return;
                      }
                      setState(() => _formaPagamentoSelecionada = forma);
                      _garantirFocoBipador();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: _formaPagamentoSelecionada == forma
                            ? (theme.buttonColor != Colors.transparent
                                ? theme.buttonColor.withValues(alpha: 0.8)
                                : theme.borderColor.withValues(alpha: 0.35))
                            : theme.backgroundColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _formaPagamentoSelecionada == forma
                              ? theme.textColor
                              : theme.borderColor.withValues(alpha: 0.4),
                          width:
                              _formaPagamentoSelecionada == forma ? 1.4 : 1.0,
                        ),
                      ),
                      child: Text(
                        forma,
                        style: theme.getTextStyle(
                          fontSize: 11,
                          fontWeight: _formaPagamentoSelecionada == forma
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _formaPagamentoSelecionada == forma
                              ? theme.textColor
                              : theme.secondaryTextColor,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Se forma for dinheiro: Campo de valor recebido e Troco Gigante
        if (_formaPagamentoSelecionada == 'Dinheiro') ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.backgroundColor.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Valor Recebido (R\$)',
                        style: theme.getTextStyle(
                            fontSize: 11, color: theme.secondaryTextColor),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _valorRecebidoController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        cursorColor: theme.textColor,
                        style: theme.getTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ex: 100,00',
                          hintStyle: theme.getTextStyle(
                              fontSize: 13,
                              color: theme.secondaryTextColor),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.borderColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'TROCO DO CLIENTE',
                        style: theme.getTextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                      Text(
                        'R\$ ${_valorFormatado(troco)}',
                        style: theme.getTextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Bloco do TOTAL GERAL em Destaque Gigante
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.backgroundColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.textColor.withValues(alpha: 0.7),
              width: 1.6,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL A PAGAR',
                    style: theme.getTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.secondaryTextColor,
                    ).copyWith(letterSpacing: 1.0),
                  ),
                  if (_descontoValor > 0 || _acrescimoValor > 0 || _freteValor > 0)
                    Text(
                      'Subtotal: R\$ ${_valorFormatado(subtotal)}',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                ],
              ),
              Text(
                'R\$ ${_valorFormatado(total)}',
                style: theme.getTextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
        ),
        if (_aviso != null) ...[
          const SizedBox(height: 8),
          Text(
            _aviso!,
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 12,
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
        const SizedBox(height: 12),

        // Botão Gigante de Finalizar Venda
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.buttonColor != Colors.transparent
                ? theme.buttonColor
                : theme.borderColor.withValues(alpha: 0.35),
            foregroundColor: theme.textColor,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: theme.textColor, width: 1.5),
            ),
            elevation: 2,
          ),
          onPressed: _finalizarVenda,
          icon: const Icon(Icons.check_circle_outline, size: 24),
          label: Text(
            'FINALIZAR VENDA',
            style: theme.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ).copyWith(letterSpacing: 0.8),
          ),
        ),
      ],
    );
  }
}
