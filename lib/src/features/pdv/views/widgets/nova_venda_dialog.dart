import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/novo_item_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/venda_concluida_dialog.dart';

const List<String> _formasDePagamento = [
  'Pix',
  'Dinheiro',
  'Débito',
  'Crédito',
  'À Prazo',
];

const String _formaAPrazo = 'À Prazo';
const String _formaDinheiro = 'Dinheiro';

const double _larguraComanda = 220;

double _precoComoNumero(String texto) {
  var limpo = texto.replaceAll(RegExp(r'[^0-9,.]'), '');
  if (limpo.contains(',')) {
    limpo = limpo.replaceAll('.', '').replaceAll(',', '.');
  }
  return double.tryParse(limpo) ?? 0;
}

String _valorComVirgula(double valor) =>
    valor.toStringAsFixed(2).replaceAll('.', ',');

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

String _dataHoraCompleta(DateTime d) =>
    '${_doisDigitos(d.day)}/${_doisDigitos(d.month)}/${d.year} '
    '${_doisDigitos(d.hour)}:${_doisDigitos(d.minute)}';

class NovaVendaDialog {
  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required List<ItemLoja> itensDisponiveis,
    required List<CategoriaLoja> categoriasDisponiveis,
    required List<GrupoComponentesLoja> gruposDisponiveis,
    required List<Cliente> Function() obterClientes,
    required Future<void> Function() aoAbrirClientes,
    required String nomeVendedor,
    required String cnpjVendedor,
    required int proximoNumero,
    required ValueChanged<PedidoLoja> onConcluir,
    required Future<void> Function(ItemLoja item, List<String> categoriaIds,
        List<String> grupoIds) aoCriarItem,
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
            constraints: const BoxConstraints(maxWidth: 500),
            child: _NovaVendaConteudo(
              theme: theme,
              itensDisponiveis: itensDisponiveis,
              categoriasDisponiveis: categoriasDisponiveis,
              gruposDisponiveis: gruposDisponiveis,
              obterClientes: obterClientes,
              aoAbrirClientes: aoAbrirClientes,
              nomeVendedor: nomeVendedor,
              cnpjVendedor: cnpjVendedor,
              proximoNumero: proximoNumero,
              onConcluir: onConcluir,
              aoCriarItem: aoCriarItem,
            ),
          ),
        );
      },
    );
  }
}

class _NovaVendaConteudo extends StatefulWidget {
  final AppTheme theme;
  final List<ItemLoja> itensDisponiveis;
  final List<CategoriaLoja> categoriasDisponiveis;
  final List<GrupoComponentesLoja> gruposDisponiveis;
  final List<Cliente> Function() obterClientes;
  final Future<void> Function() aoAbrirClientes;
  final String nomeVendedor;
  final String cnpjVendedor;
  final int proximoNumero;
  final ValueChanged<PedidoLoja> onConcluir;
  final Future<void> Function(
      ItemLoja item, List<String> categoriaIds, List<String> grupoIds) aoCriarItem;

  const _NovaVendaConteudo({
    required this.theme,
    required this.itensDisponiveis,
    required this.categoriasDisponiveis,
    required this.gruposDisponiveis,
    required this.obterClientes,
    required this.aoAbrirClientes,
    required this.nomeVendedor,
    required this.cnpjVendedor,
    required this.proximoNumero,
    required this.onConcluir,
    required this.aoCriarItem,
  });

  @override
  State<_NovaVendaConteudo> createState() => _NovaVendaConteudoState();
}

class _LinhaCarrinho {
  final String chave;
  final String itemId;
  final String? categoriaId;
  int quantidade;
  final Map<String, int> acompanhamentosPorItemId;
  final TextEditingController observacaoController;

  _LinhaCarrinho({
    required this.chave,
    required this.itemId,
    this.categoriaId,
    Map<String, int>? acompanhamentos,
  })  : quantidade = 1,
        acompanhamentosPorItemId = acompanhamentos ?? {},
        observacaoController = TextEditingController();

  void dispose() {
    observacaoController.dispose();
  }
}

class _NovaVendaConteudoState extends State<_NovaVendaConteudo> {
  final _clienteController = TextEditingController();
  final _buscaController = TextEditingController();
  final _freteController = TextEditingController();
  final _descontoController = TextEditingController();
  final _acrescimoController = TextEditingController();
  final _valorRecebidoController = TextEditingController();
  final _comandaScrollController = ScrollController();
  final _pagamentoScrollController = ScrollController();

  final List<_LinhaCarrinho> _carrinho = [];
  Cliente? _clienteSelecionado;
  String? _formaPagamento;
  String? _aviso;
  late final DateTime _dataHora;

  AppTheme get theme => widget.theme;

  static const String _prefixoItem = 'item:';
  static const String _prefixoCategoria = 'cat:';

  @override
  void initState() {
    super.initState();
    _dataHora = DateTime.now();
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _buscaController.dispose();
    _freteController.dispose();
    _descontoController.dispose();
    _acrescimoController.dispose();
    _valorRecebidoController.dispose();
    _comandaScrollController.dispose();
    _pagamentoScrollController.dispose();
    for (final linha in _carrinho) {
      linha.dispose();
    }
    super.dispose();
  }

  ItemLoja? _buscarItem(String id) {
    for (final item in widget.itensDisponiveis) {
      if (item.id == id) return item;
    }
    return null;
  }

  CategoriaLoja? _buscarCategoria(String id) {
    for (final categoria in widget.categoriasDisponiveis) {
      if (categoria.id == id) return categoria;
    }
    return null;
  }

  GrupoComponentesLoja? _buscarGrupo(String id) {
    for (final grupo in widget.gruposDisponiveis) {
      if (grupo.id == id) return grupo;
    }
    return null;
  }

  Cliente? _buscarCliente(String id) {
    for (final cliente in widget.obterClientes()) {
      if (cliente.id == id) return cliente;
    }
    return null;
  }

  String _montarChave({required String itemId, String? categoriaId}) {
    if (categoriaId == null) return '$_prefixoItem$itemId';
    return '$_prefixoCategoria$categoriaId|$_prefixoItem$itemId';
  }

  List<GrupoComponentesLoja> _gruposDaCategoria(_LinhaCarrinho linha) {
    final categoriaId = linha.categoriaId;
    if (categoriaId == null) return [];
    final categoria = _buscarCategoria(categoriaId);
    if (categoria == null) return [];
    return categoria.grupoIds
        .map((id) => _buscarGrupo(id))
        .whereType<GrupoComponentesLoja>()
        .toList();
  }

  double _precoDosAcompanhamentosPorUnidade(_LinhaCarrinho linha) {
    var soma = 0.0;
    linha.acompanhamentosPorItemId.forEach((itemId, quantidade) {
      final item = _buscarItem(itemId);
      if (item == null) return;
      soma += _precoComoNumero(item.preco) * quantidade;
    });
    return soma;
  }

  double _precoUnitarioDaLinha(_LinhaCarrinho linha) {
    final item = _buscarItem(linha.itemId);
    if (item == null) return 0;
    var soma = _precoComoNumero(item.preco);
    if (linha.categoriaId != null) {
      final categoria = _buscarCategoria(linha.categoriaId!);
      if (categoria != null) soma += _precoComoNumero(categoria.preco);
    }
    soma += _precoDosAcompanhamentosPorUnidade(linha);
    return soma;
  }

  double _subtotalDaLinha(_LinhaCarrinho linha) =>
      _precoUnitarioDaLinha(linha) * linha.quantidade;

  double get _subtotalDosItens {
    var soma = 0.0;
    for (final linha in _carrinho) {
      soma += _subtotalDaLinha(linha);
    }
    return soma;
  }

  double get _frete => _precoComoNumero(_freteController.text);

  double get _desconto => _precoComoNumero(_descontoController.text);

  double get _acrescimo => _precoComoNumero(_acrescimoController.text);

  double get _total {
    final total = _subtotalDosItens + _frete + _acrescimo - _desconto;
    return total < 0 ? 0 : total;
  }

  double get _valorRecebido => _precoComoNumero(_valorRecebidoController.text);

  double get _troco {
    if (_formaPagamento != _formaDinheiro) return 0;
    final t = _valorRecebido - _total;
    return t < 0 ? 0 : t;
  }

  String _nomeExibicaoDaLinha(_LinhaCarrinho linha) {
    final item = _buscarItem(linha.itemId);
    if (item == null) return 'Item removido';
    if (linha.categoriaId == null) return item.nome;
    final categoria = _buscarCategoria(linha.categoriaId!);
    if (categoria == null) return item.nome;
    return '${categoria.nome} ${item.nome}';
  }

  _LinhaCarrinho? _linhaPorChave(String chave) {
    for (final linha in _carrinho) {
      if (linha.chave == chave) return linha;
    }
    return null;
  }

  List<CategoriaLoja> get _categoriasEncontradas {
    final termo = _buscaController.text.trim().toLowerCase();
    if (termo.isEmpty) return [];
    return widget.categoriasDisponiveis
        .where((c) => c.nome.toLowerCase().contains(termo))
        .take(4)
        .toList();
  }

  List<ItemLoja> get _itensEncontrados {
    final termo = _buscaController.text.trim().toLowerCase();
    if (termo.isEmpty) return [];
    final idsDeItensEmCategoriasEncontradas = <String>{};
    for (final categoria in _categoriasEncontradas) {
      idsDeItensEmCategoriasEncontradas.addAll(categoria.itemIds);
    }
    return widget.itensDisponiveis
        .where((item) => item.nome.toLowerCase().contains(termo))
        .where((item) => !idsDeItensEmCategoriasEncontradas.contains(item.id))
        .take(4)
        .toList();
  }

  bool get _temResultadoDeBusca =>
      _categoriasEncontradas.isNotEmpty || _itensEncontrados.isNotEmpty;

  List<Cliente> get _sugestoesDeCliente {
    if (_clienteSelecionado != null) return [];
    final termo = _clienteController.text.trim().toLowerCase();
    if (termo.isEmpty) return [];
    return widget
        .obterClientes()
        .where((cliente) => cliente.nome.toLowerCase().contains(termo))
        .take(3)
        .toList();
  }

  String _montarComanda() {
    const colunas = 40;
    const duplo = '========================================';
    const simples = '----------------------------------------';

    String linha(String esquerda, String direita) {
      final espaco = colunas - direita.length;
      if (esquerda.length >= espaco) {
        return '${esquerda.substring(0, espaco - 1)} $direita';
      }
      return '${esquerda.padRight(espaco)}$direita';
    }

    final buffer = StringBuffer();
    buffer.writeln(duplo);
    buffer.writeln(
      widget.nomeVendedor.isEmpty ? 'Nome do vendedor' : widget.nomeVendedor,
    );
    buffer.writeln('CNPJ: ${widget.cnpjVendedor}');
    buffer.writeln(duplo);
    buffer.writeln('Pedido #${widget.proximoNumero.toString().padLeft(4, '0')}');
    buffer.writeln('Data: ${_dataHoraCompleta(_dataHora)}');
    buffer.writeln(simples);
    buffer.writeln('Cliente: ${_clienteController.text.trim()}');
    buffer.writeln('Endereco: ${_clienteSelecionado?.endereco ?? ''}');
    buffer.writeln(simples);
    buffer.writeln('ITENS');
    buffer.writeln('');

    for (final linhaCarrinho in _carrinho) {
      final nome = _nomeExibicaoDaLinha(linhaCarrinho);
      final subtotal = _subtotalDaLinha(linhaCarrinho);
      buffer.writeln(
        linha('${linhaCarrinho.quantidade}x $nome', _valorComVirgula(subtotal)),
      );
      linhaCarrinho.acompanhamentosPorItemId.forEach((itemId, quantidade) {
        final acompanhamento = _buscarItem(itemId);
        if (acompanhamento == null || quantidade <= 0) return;
        final totalAcompanhamento = _precoComoNumero(acompanhamento.preco) *
            quantidade *
            linhaCarrinho.quantidade;
        buffer.writeln(
          linha(
            '   ${quantidade}x ${acompanhamento.nome} por unidade',
            _valorComVirgula(totalAcompanhamento),
          ),
        );
      });
      final obs = linhaCarrinho.observacaoController.text.trim();
      if (obs.isNotEmpty) {
        buffer.writeln('   Obs: $obs');
      }
      buffer.writeln('');
    }

    buffer.writeln(simples);
    buffer.writeln(
      linha('Subtotal', _valorComVirgula(_subtotalDosItens)),
    );
    buffer.writeln(linha('Frete', _valorComVirgula(_frete)));
    if (_desconto > 0) {
      buffer.writeln(
        linha('Desconto', '-${_valorComVirgula(_desconto)}'),
      );
    }
    if (_acrescimo > 0) {
      buffer.writeln(linha('Acrescimo', _valorComVirgula(_acrescimo)));
    }
    buffer.writeln(linha('TOTAL', _valorComVirgula(_total)));
    buffer.writeln('Pagamento: ${_formaPagamento ?? ''}');
    if (_formaPagamento == _formaDinheiro) {
      buffer.writeln(
        linha('Valor recebido', _valorComVirgula(_valorRecebido)),
      );
      buffer.writeln(linha('Troco', _valorComVirgula(_troco)));
    }
    buffer.writeln(duplo);
    buffer.writeln('linktr.ee/nous72');
    buffer.write(duplo);

    return buffer.toString();
  }

  void _adicionarLinhaAoCarrinho({required String itemId, String? categoriaId}) {
    final chave = _montarChave(itemId: itemId, categoriaId: categoriaId);
    setState(() {
      final existente = _linhaPorChave(chave);
      if (existente != null) {
        existente.quantidade++;
      } else {
        _carrinho.add(_LinhaCarrinho(
          chave: chave,
          itemId: itemId,
          categoriaId: categoriaId,
        ));
      }
      _aviso = null;
    });
  }

  void _alterarQuantidade(String chave, int variacao) {
    setState(() {
      final linha = _linhaPorChave(chave);
      if (linha == null) return;
      final nova = linha.quantidade + variacao;
      if (nova <= 0) {
        linha.dispose();
        _carrinho.remove(linha);
      } else {
        linha.quantidade = nova;
      }
      _aviso = null;
    });
  }

  void _editarAcompanhamentosDaLinha(String chave) {
    final linha = _linhaPorChave(chave);
    if (linha == null) return;

    final grupos = _gruposDaCategoria(linha);
    final theme = widget.theme;

    if (grupos.isEmpty) {
      _mostrarAviso(
          'Esta categoria nao tem grupos de componentes associados.');
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final selecionados = Map<String, int>.of(linha.acompanhamentosPorItemId);
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.cardBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: BorderSide(color: theme.borderColor),
              ),
              title: Text(
                'Acompanhamentos',
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              content: SizedBox(
                width: 320,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final grupo in grupos) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 6, bottom: 6),
                          child: Text(
                            grupo.nome,
                            textAlign: TextAlign.center,
                            style: theme.getTextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                        for (final itemId in grupo.itemIds)
                          Builder(builder: (context) {
                            final item = _buscarItem(itemId);
                            if (item == null) return const SizedBox.shrink();
                            final quantidade = selecionados[itemId] ?? 0;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.nome,
                                      style: theme.getTextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Text(
                                    'R\$ ${item.preco}',
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
                                        final atual = selecionados[itemId] ?? 0;
                                        if (atual <= 1) {
                                          selecionados.remove(itemId);
                                        } else {
                                          selecionados[itemId] = atual - 1;
                                        }
                                      });
                                    },
                                  ),
                                  SizedBox(
                                    width: 18,
                                    child: Text(
                                      '$quantidade',
                                      textAlign: TextAlign.center,
                                      style: theme.getTextStyle(fontSize: 12),
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
                                        selecionados[itemId] =
                                            (selecionados[itemId] ?? 0) + 1;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          }),
                        Divider(
                            color:
                                theme.borderColor.withValues(alpha: 0.6)),
                      ],
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
                    setState(() {
                      linha.acompanhamentosPorItemId
                        ..clear()
                        ..addAll(selecionados);
                    });
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(
                    'Concluir',
                    style: theme.getTextStyle(color: theme.textColor),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _aoDigitarCliente(String texto) {
    setState(() {
      final selecionado = _clienteSelecionado;
      if (selecionado != null && selecionado.nome != texto) {
        _clienteSelecionado = null;
        if (_formaPagamento == _formaAPrazo) _formaPagamento = null;
      }
    });
  }

  void _selecionarCliente(Cliente cliente) {
    setState(() {
      _clienteSelecionado = cliente;
      _clienteController.text = cliente.nome;
      _aviso = null;
    });
  }

  Future<void> _abrirClientes() async {
    await widget.aoAbrirClientes();
    if (!mounted) return;
    setState(() {
      final id = _clienteSelecionado?.id;
      if (id != null) {
        final atualizado = _buscarCliente(id);
        _clienteSelecionado = atualizado;
        if (atualizado != null) {
          _clienteController.text = atualizado.nome;
        } else if (_formaPagamento == _formaAPrazo) {
          _formaPagamento = null;
        }
      }
    });
  }

  void _escolherPagamento(String forma) {
    if (forma == _formaAPrazo && _clienteSelecionado == null) {
      _mostrarAviso('Selecione um cliente cadastrado para vender a prazo.');
      return;
    }
    setState(() {
      _formaPagamento = _formaPagamento == forma ? null : forma;
      if (_formaPagamento != _formaDinheiro) {
        _valorRecebidoController.clear();
      }
      _aviso = null;
    });
  }

  void _mostrarAviso(String texto) {
    setState(() => _aviso = texto);
  }

  void _abrirSeletorDeItemDaCategoria(CategoriaLoja categoria) {
    final theme = widget.theme;
    final itens = categoria.itemIds
        .map((id) => _buscarItem(id))
        .whereType<ItemLoja>()
        .toList();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            categoria.nome,
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: SizedBox(
            width: 280,
            child: itens.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Nenhum item nesta categoria ainda.',
                      textAlign: TextAlign.center,
                      style: theme.getTextStyle(
                        fontSize: 13,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final item in itens)
                          ListTile(
                            title: Text(item.nome,
                                style: theme.getTextStyle()),
                            trailing: Text(
                              'R\$ ${_valorComVirgula(_precoComoNumero(item.preco) + _precoComoNumero(categoria.preco))}',
                              style: theme.getTextStyle(fontSize: 11),
                            ),
                            onTap: () {
                              _buscaController.clear();
                              _adicionarLinhaAoCarrinho(
                                itemId: item.id,
                                categoriaId: categoria.id,
                              );
                              Navigator.of(dialogContext).pop();
                            },
                          ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Future<void> _abrirNovoProduto() async {
    await NovoItemDialog.mostrar(
      context,
      theme: theme,
      categorias: widget.categoriasDisponiveis,
      gruposComponentes: widget.gruposDisponiveis,
      onCriar: (item, categoriaIds, grupoIds) async {
        await widget.aoCriarItem(item, categoriaIds, grupoIds);
      },
    );
  }

  Future<void> _concluir() async {
    if (_carrinho.isEmpty) {
      _mostrarAviso('Adicione ao menos um produto.');
      return;
    }

    if (_formaPagamento == _formaAPrazo && _clienteSelecionado == null) {
      _mostrarAviso('Selecione um cliente cadastrado para vender a prazo.');
      return;
    }

    if (_formaPagamento == _formaDinheiro && _valorRecebido < _total) {
      _mostrarAviso('O valor recebido é menor que o total.');
      return;
    }

    final itensVendidos = <ItemVendido>[];
    for (final linha in _carrinho) {
      final item = _buscarItem(linha.itemId);
      if (item == null) continue;
      final categoria = linha.categoriaId == null
          ? null
          : _buscarCategoria(linha.categoriaId!);
      final acompanhamentos = <AcompanhamentoEscolhido>[];
      linha.acompanhamentosPorItemId.forEach((itemId, quantidade) {
        if (quantidade <= 0) return;
        final acompanhamento = _buscarItem(itemId);
        if (acompanhamento == null) return;
        acompanhamentos.add(AcompanhamentoEscolhido(
          itemId: acompanhamento.id,
          nomeItem: acompanhamento.nome,
          precoItem: _precoComoNumero(acompanhamento.preco),
          quantidadePorUnidade: quantidade,
        ));
      });
      itensVendidos.add(ItemVendido(
        itemId: item.id,
        nomeItem: item.nome,
        categoriaId: categoria?.id,
        nomeCategoria: categoria?.nome,
        precoItem: _precoComoNumero(item.preco),
        precoCategoria:
            categoria == null ? 0 : _precoComoNumero(categoria.preco),
        quantidade: linha.quantidade,
        acompanhamentos: acompanhamentos,
        observacao: linha.observacaoController.text.trim(),
      ));
    }

    final nomes = itensVendidos.map((i) => i.nomeExibicao).toList();
    final resumo = nomes.length > 1
        ? '${nomes.first} +${nomes.length - 1}'
        : (nomes.isEmpty ? 'Venda' : nomes.first);
    final cliente = _clienteController.text.trim();

    final pedido = PedidoLoja(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      numero: widget.proximoNumero,
      clienteId: _clienteSelecionado?.id,
      clienteNome: cliente.isEmpty ? 'Cliente' : cliente,
      produtoNome: resumo,
      dataHora: _dataHora,
      valor: _total,
      status: StatusPedido.aceito,
      comanda: _montarComanda(),
      formaPagamento: _formaPagamento ?? '',
      itens: itensVendidos,
      frete: _frete,
      desconto: _desconto,
      acrescimo: _acrescimo,
    );

    final confirmou = await VendaConcluidaDialog.mostrar(
      context,
      theme: theme,
      numeroPedido: widget.proximoNumero,
      valorTotal: _total,
    );

    if (!mounted) return;

    if (confirmou) {
      Navigator.of(context).pop();
      widget.onConcluir(pedido);
    }
  }

  BoxDecoration get _decoracaoDoBloco => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

  InputDecoration _decoracaoCampo(String dica) {
    OutlineInputBorder borda(Color cor) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: cor),
        );
    return InputDecoration(
      hintText: dica,
      hintStyle:
          theme.getTextStyle(fontSize: 12, color: theme.secondaryTextColor),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: borda(theme.borderColor),
      focusedBorder: borda(theme.textColor),
    );
  }

  Widget _tituloDoBloco(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: theme.getTextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: theme.textColor,
        ),
      ),
    );
  }

  Widget _botaoPequeno(String rotulo, VoidCallback aoPressionar) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.textColor,
        side: BorderSide(color: theme.borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: aoPressionar,
      child: Text(rotulo, style: theme.getTextStyle(fontSize: 11)),
    );
  }

  Widget _linhaDeCliente(Cliente cliente) {
    return InkWell(
      onTap: () => _selecionarCliente(cliente),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                cliente.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
              ),
            ),
            if (cliente.telefone.isNotEmpty)
              Text(cliente.telefone, style: theme.getTextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _blocoCliente() {
    final sugestoes = _sugestoesDeCliente;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco('Nome do Cliente'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _clienteController,
                  cursorColor: theme.textColor,
                  style: theme.getTextStyle(fontSize: 12),
                  decoration: _decoracaoCampo('Nome do cliente'),
                  onChanged: _aoDigitarCliente,
                ),
              ),
              const SizedBox(width: 8),
              _botaoPequeno('Novo Cliente', _abrirClientes),
            ],
          ),
          if (sugestoes.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final cliente in sugestoes) _linhaDeCliente(cliente),
          ],
          if (_clienteSelecionado != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Cliente cadastrado selecionado.',
                style: theme.getTextStyle(fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _linhaDeCategoriaNaBusca(CategoriaLoja categoria) {
    return InkWell(
      onTap: () => _abrirSeletorDeItemDaCategoria(categoria),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.category_outlined,
                size: 16, color: theme.secondaryTextColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Categoria: ${categoria.nome}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linhaDeResultado(ItemLoja item) {
    return InkWell(
      onTap: () {
        _buscaController.clear();
        _adicionarLinhaAoCarrinho(itemId: item.id);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
              ),
            ),
            Text(
              'R\$ ${_valorComVirgula(_precoComoNumero(item.preco))}',
              style: theme.getTextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linhaDoItemSelecionado(_LinhaCarrinho linha) {
    final grupos = _gruposDaCategoria(linha);
    final temGrupos = grupos.isNotEmpty;
    final acompanhamentos = linha.acompanhamentosPorItemId;
    final subtotal = _subtotalDaLinha(linha);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  _nomeExibicaoDaLinha(linha),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.textColor,
                  ),
                ),
              ),
              Text(
                'R\$ ${_valorComVirgula(_precoUnitarioDaLinha(linha))}',
                style: theme.getTextStyle(fontSize: 11),
              ),
              const SizedBox(width: 6),
              IconButton(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(Icons.remove, size: 18, color: theme.textColor),
                onPressed: () => _alterarQuantidade(linha.chave, -1),
              ),
              Text('${linha.quantidade}',
                  style: theme.getTextStyle(fontSize: 12)),
              IconButton(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(Icons.add, size: 18, color: theme.textColor),
                onPressed: () => _alterarQuantidade(linha.chave, 1),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  'R\$ ${_valorComVirgula(subtotal)}',
                  textAlign: TextAlign.right,
                  style: theme.getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 2),
            child: Row(
              children: [
                Expanded(
                  child: acompanhamentos.isEmpty
                      ? Text(
                          temGrupos ? 'sem acompanhamentos' : '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 10,
                            color: theme.secondaryTextColor,
                          ),
                        )
                      : Text(
                          acompanhamentos.entries
                              .map((entrada) {
                                final item = _buscarItem(entrada.key);
                                if (item == null) return '';
                                return '${entrada.value}x ${item.nome}';
                              })
                              .where((s) => s.isNotEmpty)
                              .join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 10,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                ),
                if (temGrupos)
                  TextButton(
                    onPressed: () => _editarAcompanhamentosDaLinha(linha.chave),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Editar acompanhamentos',
                      style: theme.getTextStyle(fontSize: 10),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4, right: 4),
            child: TextField(
              controller: linha.observacaoController,
              cursorColor: theme.textColor,
              style: theme.getTextStyle(fontSize: 11),
              decoration: _decoracaoCampo('Observação do item'),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blocoProduto() {
    final categorias = _categoriasEncontradas;
    final itens = _itensEncontrados;
    final buscando = _buscaController.text.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco('Produto Solicitado'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _buscaController,
                  cursorColor: theme.textColor,
                  style: theme.getTextStyle(fontSize: 12),
                  decoration: _decoracaoCampo('Pesquisar produtos cadastrados'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              _botaoPequeno('Novo Produto', _abrirNovoProduto),
            ],
          ),
          if (buscando) ...[
            const SizedBox(height: 8),
            if (!_temResultadoDeBusca)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  widget.itensDisponiveis.isEmpty &&
                          widget.categoriasDisponiveis.isEmpty
                      ? 'Nenhum item ou categoria criado na aba Loja ainda.'
                      : 'Nenhum resultado.',
                  style: theme.getTextStyle(fontSize: 11),
                ),
              )
            else ...[
              for (final categoria in categorias)
                _linhaDeCategoriaNaBusca(categoria),
              for (final item in itens) _linhaDeResultado(item),
            ],
          ],
          if (_carrinho.isNotEmpty) ...[
            const SizedBox(height: 8),
            Divider(color: theme.borderColor.withValues(alpha: 0.6)),
            for (final linha in _carrinho) _linhaDoItemSelecionado(linha),
          ],
        ],
      ),
    );
  }

  Widget _linhaComanda(String esquerda, String direita, {bool destaque = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              esquerda,
              style: theme.getTextStyle(
                fontSize: 12,
                color: destaque ? theme.textColor : theme.secondaryTextColor,
                fontWeight: destaque ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            direita,
            style: theme.getTextStyle(
              fontSize: 12,
              color: destaque ? theme.textColor : theme.secondaryTextColor,
              fontWeight: destaque ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _blocoComanda() {
    final totalLinhas = _carrinho.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco('Comanda'),
          SizedBox(
            height: 280,
            child: Scrollbar(
              controller: _comandaScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _comandaScrollController,
                child: Center(
                  child: Container(
                    width: _larguraComanda,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.backgroundColor.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Text(
                            widget.nomeVendedor.isEmpty
                                ? 'Nome do vendedor'
                                : widget.nomeVendedor,
                            textAlign: TextAlign.center,
                            style: theme.getTextStyle(
                                fontSize: 12, color: theme.textColor),
                          ),
                        ),
                        Center(
                          child: Text(
                            'CNPJ: ${widget.cnpjVendedor}',
                            textAlign: TextAlign.center,
                            style: theme.getTextStyle(
                                fontSize: 11,
                                color: theme.secondaryTextColor),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            'Pedido #${widget.proximoNumero.toString().padLeft(4, '0')}',
                            textAlign: TextAlign.center,
                            style: theme.getTextStyle(
                                fontSize: 12, color: theme.textColor),
                          ),
                        ),
                        Center(
                          child: Text(
                            'Data: ${_dataHoraCompleta(_dataHora)}',
                            textAlign: TextAlign.center,
                            style: theme.getTextStyle(
                                fontSize: 11,
                                color: theme.secondaryTextColor),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _linhaComanda('Cliente',
                            _clienteController.text.trim().isEmpty
                                ? '-'
                                : _clienteController.text.trim()),
                        _linhaComanda(
                            'Endereço', _clienteSelecionado?.endereco ?? '-'),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'ITENS',
                            style: theme.getTextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.textColor),
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (totalLinhas == 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Nenhum item adicionado.',
                              textAlign: TextAlign.center,
                              style: theme.getTextStyle(
                                  fontSize: 11,
                                  color: theme.secondaryTextColor),
                            ),
                          )
                        else
                          for (final linha in _carrinho)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _linhaComanda(
                                    '${linha.quantidade}x ${_nomeExibicaoDaLinha(linha)}',
                                    'R\$ ${_valorComVirgula(_subtotalDaLinha(linha))}',
                                  ),
                                  for (final entrada
                                      in linha.acompanhamentosPorItemId.entries)
                                    Builder(builder: (context) {
                                      final item = _buscarItem(entrada.key);
                                      if (item == null || entrada.value <= 0) {
                                        return const SizedBox.shrink();
                                      }
                                      final total =
                                          _precoComoNumero(item.preco) *
                                              entrada.value *
                                              linha.quantidade;
                                      return _linhaComanda(
                                        '   ${entrada.value}x ${item.nome} por unidade',
                                        'R\$ ${_valorComVirgula(total)}',
                                      );
                                    }),
                                  if (linha.observacaoController.text
                                      .trim()
                                      .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        'Obs: ${linha.observacaoController.text.trim()}',
                                        style: theme.getTextStyle(
                                            fontSize: 11,
                                            color: theme.secondaryTextColor),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        const SizedBox(height: 8),
                        Divider(
                            color: theme.borderColor.withValues(alpha: 0.6)),
                        _linhaComanda('Subtotal',
                            'R\$ ${_valorComVirgula(_subtotalDosItens)}'),
                        _linhaComanda(
                            'Frete', 'R\$ ${_valorComVirgula(_frete)}'),
                        if (_desconto > 0)
                          _linhaComanda('Desconto',
                              '-R\$ ${_valorComVirgula(_desconto)}'),
                        if (_acrescimo > 0)
                          _linhaComanda('Acréscimo',
                              'R\$ ${_valorComVirgula(_acrescimo)}'),
                        _linhaComanda(
                            'TOTAL', 'R\$ ${_valorComVirgula(_total)}',
                            destaque: true),
                        const SizedBox(height: 4),
                        _linhaComanda('Pagamento', _formaPagamento ?? '-'),
                        if (_formaPagamento == _formaDinheiro) ...[
                          _linhaComanda('Valor recebido',
                              'R\$ ${_valorComVirgula(_valorRecebido)}'),
                          _linhaComanda('Troco',
                              'R\$ ${_valorComVirgula(_troco)}',
                              destaque: true),
                        ],
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'linktr.ee/nous72',
                            textAlign: TextAlign.center,
                            style: theme.getTextStyle(
                                fontSize: 11,
                                color: theme.secondaryTextColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campoValor({
    required TextEditingController controller,
    required String rotulo,
  }) {
    return Expanded(
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        cursorColor: theme.textColor,
        style: theme.getTextStyle(fontSize: 12),
        decoration: _decoracaoCampo(rotulo),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _blocoAjustes() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco('Frete, Desconto e Acréscimo'),
          Row(
            children: [
              _campoValor(controller: _freteController, rotulo: 'Frete'),
              const SizedBox(width: 8),
              _campoValor(controller: _descontoController, rotulo: 'Desconto'),
              const SizedBox(width: 8),
              _campoValor(
                  controller: _acrescimoController, rotulo: 'Acréscimo'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _blocoPagamento() {
    final isDinheiro = _formaPagamento == _formaDinheiro;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco('Forma de Pagamento'),
          Scrollbar(
            controller: _pagamentoScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _pagamentoScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  for (final forma in _formasDePagamento)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: SizedBox(
                        width: 84,
                        child: _botaoDePagamento(forma),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isDinheiro) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _valorRecebidoController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    cursorColor: theme.textColor,
                    style: theme.getTextStyle(fontSize: 12),
                    decoration: _decoracaoCampo('Valor recebido'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Troco: R\$ ${_valorComVirgula(_troco)}',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _botaoDePagamento(String forma) {
    final selecionada = _formaPagamento == forma;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: selecionada ? theme.buttonColor : Colors.transparent,
        foregroundColor:
            selecionada ? theme.buttonTextColor : theme.textColor,
        side: BorderSide(
          color: selecionada ? theme.buttonColor : theme.borderColor,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () => _escolherPagamento(forma),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          forma,
          style: theme.getTextStyle(
            fontSize: 11,
            color: selecionada ? theme.buttonTextColor : theme.textColor,
          ),
        ),
      ),
    );
  }

  Widget _botaoConcluir() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: theme.buttonColor,
          foregroundColor: theme.buttonTextColor,
          side: BorderSide(color: theme.borderColor),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: _concluir,
        child: Text(
          'Concluir',
          style: theme.getTextStyle(
            fontSize: 14,
            color: theme.buttonTextColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                child: Text(
                  'Nova Venda',
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                _blocoCliente(),
                const SizedBox(height: 12),
                _blocoProduto(),
                const SizedBox(height: 12),
                _blocoComanda(),
                const SizedBox(height: 12),
                _blocoAjustes(),
                const SizedBox(height: 12),
                _blocoPagamento(),
                const SizedBox(height: 12),
                if (_aviso != null) ...[
                  Text(
                    _aviso!,
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                ],
                _botaoConcluir(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}