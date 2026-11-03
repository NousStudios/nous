import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/services/som_service.dart';
import 'package:nous/src/core/services/janela_windows_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/services/gerador_comprovante_venda.dart';
import 'package:nous/src/features/pdv/views/widgets/novo_item_dialog.dart';
import 'package:nous/src/features/pdv/models/modelos_nova_venda.dart';
import 'package:nous/src/features/pdv/views/dialogs/dialog_escolher_variante_item.dart';
import 'package:nous/src/features/pdv/views/dialogs/dialog_editar_acompanhamentos.dart';
import 'package:nous/src/features/pdv/views/dialogs/dialog_seletor_item_categoria.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_venda/bloco_produtos_nova_venda_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_venda/cliente_seletor_nova_venda_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_venda/comanda_resumo_nova_venda_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_venda/pagamento_nova_venda_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_venda/finalizador_nova_venda.dart';

import 'package:nous/src/core/utils/texto_utils.dart';

const List<String> _formasDePagamento = [
  'Pix',
  'Dinheiro',
  'Débito',
  'Crédito',
  'À Prazo',
];

const String _formaAPrazo = 'À Prazo';

const double _larguraComanda = 320;

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
  static final Map<String, RascunhoVenda> _rascunhosPorLoja = {};

  static void limparRascunho(String? lojaId) {
    _rascunhosPorLoja.remove(lojaId ?? '');
  }

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
    required String cpfAutor,
    required String nomeAutor,
    required void Function(
      PedidoLoja pedido,
      List<MovimentoEstoque> movimentosEstoque,
    ) onConcluir,
    required Future<void> Function(ItemLoja item, List<String> categoriaIds,
        List<String> grupoIds, [double? estoqueInicial]) aoCriarItem,
    required ConfiguracoesImpressora configuracoesImpressora,
    String? lojaId,
    List<MovimentoEstoque> movimentosEstoque = const [],
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.f11): () {
              JanelaWindowsService.alternarTelaCheia();
            },
          },
          child: Consumer<PdvProvider>(
            builder: (ctx, pdv, child) {
              final expandido = pdv.layoutDesktopAtivo(lojaId);
              final larguraTela = MediaQuery.sizeOf(ctx).width;
              final maxWidth = expandido
                  ? (larguraTela > 1250 ? 1150.0 : larguraTela * 0.92)
                  : 500.0;

              return Dialog(
                backgroundColor: theme.cardBackgroundColor,
                insetPadding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.borderColor),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: _NovaVendaConteudo(
                    theme: theme,
                    lojaId: lojaId,
                    expandido: expandido,
                    itensDisponiveis: itensDisponiveis,
                    categoriasDisponiveis: categoriasDisponiveis,
                    gruposDisponiveis: gruposDisponiveis,
                    obterClientes: obterClientes,
                    aoAbrirClientes: aoAbrirClientes,
                    nomeVendedor: nomeVendedor,
                    cnpjVendedor: cnpjVendedor,
                    proximoNumero: proximoNumero,
                    cpfAutor: cpfAutor,
                    nomeAutor: nomeAutor,
                    onConcluir: onConcluir,
                    aoCriarItem: aoCriarItem,
                    configuracoesImpressora: configuracoesImpressora,
                    movimentosEstoque: movimentosEstoque,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _NovaVendaConteudo extends StatefulWidget {
  final AppTheme theme;
  final String? lojaId;
  final List<ItemLoja> itensDisponiveis;
  final List<CategoriaLoja> categoriasDisponiveis;
  final List<GrupoComponentesLoja> gruposDisponiveis;
  final List<Cliente> Function() obterClientes;
  final Future<void> Function() aoAbrirClientes;
  final String nomeVendedor;
  final String cnpjVendedor;
  final int proximoNumero;
  final String cpfAutor;
  final String nomeAutor;
  final void Function(
    PedidoLoja pedido,
    List<MovimentoEstoque> movimentosEstoque,
  ) onConcluir;
  final Future<void> Function(ItemLoja item, List<String> categoriaIds,
      List<String> grupoIds, [double? estoqueInicial]) aoCriarItem;
  final ConfiguracoesImpressora configuracoesImpressora;
  final List<MovimentoEstoque> movimentosEstoque;
  final bool expandido;

  const _NovaVendaConteudo({
    required this.theme,
    this.lojaId,
    this.expandido = false,
    required this.itensDisponiveis,
    required this.categoriasDisponiveis,
    required this.gruposDisponiveis,
    required this.obterClientes,
    required this.aoAbrirClientes,
    required this.nomeVendedor,
    required this.cnpjVendedor,
    required this.proximoNumero,
    required this.cpfAutor,
    required this.nomeAutor,
    required this.onConcluir,
    required this.aoCriarItem,
    required this.configuracoesImpressora,
    this.movimentosEstoque = const [],
  });

  @override
  State<_NovaVendaConteudo> createState() => _NovaVendaConteudoState();
}

class _NovaVendaConteudoState extends State<_NovaVendaConteudo> {
  final _clienteController = TextEditingController();
  final _buscaController = TextEditingController();
  final _freteController = TextEditingController();
  final _descontoController = TextEditingController();
  final _acrescimoController = TextEditingController();
  final _comandaScrollController = ScrollController();
  final _pagamentoScrollController = ScrollController();
  final _buscaFocusNode = FocusNode();
  final _clienteFocusNode = FocusNode();

  final List<LinhaCarrinho> _carrinho = [];
  final List<LinhaPagamento> _pagamentos = [];
  Cliente? _clienteSelecionado;
  String? _aviso;
  late final DateTime _dataHora;
  bool _buscaFocada = false;
  bool _clienteFocado = false;
  bool _vendaConcluida = false;

  AppTheme get theme => widget.theme;

  static const String _prefixoItem = 'item:';
  static const String _prefixoCategoria = 'cat:';

  @override
  void initState() {
    super.initState();
    _dataHora = DateTime.now();

    _buscaFocusNode.addListener(() {
      if (mounted && _buscaFocusNode.hasFocus && !_buscaFocada) {
        setState(() => _buscaFocada = true);
      }
    });

    _clienteFocusNode.addListener(() {
      if (mounted && _clienteFocusNode.hasFocus && !_clienteFocado) {
        setState(() => _clienteFocado = true);
      }
    });

    _restaurarRascunhoSeHouver();
  }

  void _restaurarRascunhoSeHouver() {
    final chaveLoja = widget.lojaId ?? '';
    final rascunho = NovaVendaDialog._rascunhosPorLoja[chaveLoja];
    if (rascunho == null) return;

    if (rascunho.clienteId != null) {
      _clienteSelecionado = _buscarCliente(rascunho.clienteId!);
    }
    _clienteController.text = rascunho.clienteNomeDigitado;
    _freteController.text = rascunho.frete;
    _descontoController.text = rascunho.desconto;
    _acrescimoController.text = rascunho.acrescimo;

    for (final item in rascunho.itens) {
      final linha = LinhaCarrinho(
        chave: item.chave,
        itemId: item.itemId,
        categoriaId: item.categoriaId,
        varianteNome: item.varianteNome,
        precoVariante: item.precoVariante,
        acompanhamentos: Map<String, int>.from(item.acompanhamentos),
      );
      linha.quantidade = item.quantidade;
      linha.observacaoController.text = item.observacao;
      _carrinho.add(linha);
    }

    for (final pag in rascunho.pagamentos) {
      _pagamentos.add(LinhaPagamento(
        forma: pag.forma,
        valorInicial: pag.valor,
      ));
    }
  }

  void _salvarRascunhoAtual() {
    final temDados = _carrinho.isNotEmpty ||
        _pagamentos.isNotEmpty ||
        _clienteSelecionado != null ||
        _clienteController.text.trim().isNotEmpty ||
        _freteController.text.trim().isNotEmpty ||
        _descontoController.text.trim().isNotEmpty ||
        _acrescimoController.text.trim().isNotEmpty;

    final chaveLoja = widget.lojaId ?? '';
    if (temDados) {
      NovaVendaDialog._rascunhosPorLoja[chaveLoja] = RascunhoVenda(
        itens: _carrinho.map((linha) {
          return ItemRascunho(
            chave: linha.chave,
            itemId: linha.itemId,
            categoriaId: linha.categoriaId,
            varianteNome: linha.varianteNome,
            precoVariante: linha.precoVariante,
            quantidade: linha.quantidade,
            acompanhamentos:
                Map<String, int>.from(linha.acompanhamentosPorItemId),
            observacao: linha.observacaoController.text,
          );
        }).toList(),
        pagamentos: _pagamentos.map((p) {
          return (forma: p.forma, valor: p.controller.text);
        }).toList(),
        clienteId: _clienteSelecionado?.id,
        clienteNomeDigitado: _clienteController.text,
        frete: _freteController.text,
        desconto: _descontoController.text,
        acrescimo: _acrescimoController.text,
      );
    } else {
      NovaVendaDialog._rascunhosPorLoja.remove(chaveLoja);
    }
  }

  void _limparTudo() {
    setState(() {
      for (final linha in _carrinho) {
        linha.dispose();
      }
      _carrinho.clear();

      for (final p in _pagamentos) {
        p.dispose();
      }
      _pagamentos.clear();

      _clienteSelecionado = null;
      _clienteController.clear();
      _buscaController.clear();
      _freteController.clear();
      _descontoController.clear();
      _acrescimoController.clear();
      _aviso = null;
    });
    NovaVendaDialog.limparRascunho(widget.lojaId);
  }

  @override
  void dispose() {
    if (!_vendaConcluida) {
      _salvarRascunhoAtual();
    }
    _buscaFocusNode.dispose();
    _clienteFocusNode.dispose();
    _clienteController.dispose();
    _buscaController.dispose();
    _freteController.dispose();
    _descontoController.dispose();
    _acrescimoController.dispose();
    _comandaScrollController.dispose();
    _pagamentoScrollController.dispose();
    for (final linha in _carrinho) {
      linha.dispose();
    }
    for (final p in _pagamentos) {
      p.dispose();
    }
    super.dispose();
  }

  ItemLoja? _buscarItem(String id) {
    for (final item in widget.itensDisponiveis) {
      if (item.id == id) return item;
    }
    return null;
  }

  double _saldoDoItem(String itemId) {
    var saldo = 0.0;
    for (final m in widget.movimentosEstoque) {
      if (m.itemId == itemId) {
        saldo += m.quantidadeComSinal;
      }
    }
    return saldo;
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

  String _montarChave({
    required String itemId,
    String? categoriaId,
    String varianteNome = '',
  }) {
    var base = categoriaId == null
        ? '$_prefixoItem$itemId'
        : '$_prefixoCategoria$categoriaId|$_prefixoItem$itemId';
    if (varianteNome.trim().isNotEmpty) {
      base = '$base|var:${varianteNome.trim()}';
    }
    return base;
  }

  List<GrupoComponentesLoja> _gruposDaCategoria(LinhaCarrinho linha) {
    final categoriaId = linha.categoriaId;
    if (categoriaId == null) return [];
    final categoria = _buscarCategoria(categoriaId);
    if (categoria == null) return [];
    return categoria.grupoIds
        .map((id) => _buscarGrupo(id))
        .whereType<GrupoComponentesLoja>()
        .toList();
  }

  double _precoDosAcompanhamentosPorUnidade(LinhaCarrinho linha) {
    var soma = 0.0;
    linha.acompanhamentosPorItemId.forEach((itemId, quantidade) {
      final item = _buscarItem(itemId);
      if (item == null) return;
      soma += _precoComoNumero(item.preco) * quantidade;
    });
    return soma;
  }

  double _precoBaseUnitarioDaLinha(LinhaCarrinho linha) {
    final item = _buscarItem(linha.itemId);
    if (item == null) return 0;
    final precoItem = linha.precoVariante.trim().isNotEmpty
        ? _precoComoNumero(linha.precoVariante)
        : _precoComoNumero(item.preco);
    var soma = precoItem;
    if (linha.categoriaId != null) {
      final categoria = _buscarCategoria(linha.categoriaId!);
      if (categoria != null) soma += _precoComoNumero(categoria.preco);
    }
    return soma;
  }

  double _precoUnitarioDaLinha(LinhaCarrinho linha) {
    return _precoBaseUnitarioDaLinha(linha) +
        _precoDosAcompanhamentosPorUnidade(linha);
  }

  double _subtotalBaseDaLinha(LinhaCarrinho linha) =>
      _precoBaseUnitarioDaLinha(linha) * linha.quantidade;

  double _subtotalDaLinha(LinhaCarrinho linha) =>
      _precoUnitarioDaLinha(linha) * linha.quantidade;

  double get _subtotalDosItens {
    var soma = 0.0;
    for (final linha in _carrinho) {
      soma += _subtotalDaLinha(linha);
    }
    return soma;
  }

  double _calcularValorOuPorcentagem(String texto) {
    final t = texto.trim();
    if (t.isEmpty) return 0.0;
    if (t.contains('%')) {
      final limpo = t.replaceAll('%', '').trim();
      final percentual = _precoComoNumero(limpo);
      if (percentual <= 0) return 0.0;
      return _subtotalDosItens * (percentual / 100.0);
    }
    return _precoComoNumero(t);
  }

  double get _frete => _precoComoNumero(_freteController.text);

  double get _desconto => _calcularValorOuPorcentagem(_descontoController.text);

  double get _acrescimo => _calcularValorOuPorcentagem(_acrescimoController.text);

  String get _rotuloDesconto {
    final t = _descontoController.text.trim();
    if (t.contains('%')) {
      return 'Desconto ($t)';
    }
    return 'Desconto';
  }

  String get _rotuloAcrescimo {
    final t = _acrescimoController.text.trim();
    if (t.contains('%')) {
      return 'Acréscimo ($t)';
    }
    return 'Acréscimo';
  }

  double get _total {
    final total = _subtotalDosItens + _frete + _acrescimo - _desconto;
    return total < 0 ? 0 : total;
  }

  bool get _temAPrazo =>
      _pagamentos.any((p) => p.forma == _formaAPrazo);

  double get _somaTotalPagamentos {
    var soma = 0.0;
    for (final p in _pagamentos) {
      soma += _precoComoNumero(p.controller.text);
    }
    return soma;
  }

  double get _falta {
    final f = _total - _somaTotalPagamentos;
    return f < 0 ? 0.0 : f;
  }

  double get _troco {
    final t = _somaTotalPagamentos - _total;
    return t < 0 ? 0.0 : t;
  }

  String _nomeExibicaoDaLinha(LinhaCarrinho linha) {
    final item = _buscarItem(linha.itemId);
    if (item == null) return 'Item removido';
    final base = linha.categoriaId == null
        ? item.nome
        : '${_buscarCategoria(linha.categoriaId!)?.nome ?? ''} ${item.nome}'.trim();
    if (linha.varianteNome.trim().isNotEmpty) {
      return '$base (${linha.varianteNome.trim()})';
    }
    return base;
  }

  LinhaCarrinho? _linhaPorChave(String chave) {
    for (final linha in _carrinho) {
      if (linha.chave == chave) return linha;
    }
    return null;
  }

  List<CategoriaLoja> get _categoriasEncontradas {
    final termo = _buscaController.text.trim();
    if (termo.isEmpty) return [];
    return widget.categoriasDisponiveis
        .where((c) => TextoUtils.contemIgnorandoAcentos(c.nome, termo))
        .toList();
  }

  List<ItemLoja> get _itensEncontrados {
    final termo = _buscaController.text.trim();
    if (termo.isEmpty) return [];
    final idsDeItensEmCategoriasEncontradas = <String>{};
    for (final categoria in _categoriasEncontradas) {
      idsDeItensEmCategoriasEncontradas.addAll(categoria.itemIds);
    }
    final termoLimpo = termo.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').toLowerCase();
    return widget.itensDisponiveis
        .where((item) {
          final nomeMatch = TextoUtils.contemIgnorandoAcentos(item.nome, termo);
          final codigoLimpo = item.codigoBarras
              .trim()
              .replaceAll(RegExp(r'[^0-9a-zA-Z]'), '')
              .toLowerCase();
          final codigoMatch = codigoLimpo.isNotEmpty &&
              (codigoLimpo == termoLimpo || codigoLimpo.contains(termoLimpo));
          return nomeMatch || codigoMatch;
        })
        .where((item) => !idsDeItensEmCategoriasEncontradas.contains(item.id))
        .toList();
  }

  void _aoSubmeterBusca(String valor) {
    final termo = valor.trim();
    if (termo.isEmpty) return;
    final termoLimpo = termo.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').toLowerCase();

    final itemPorCodigo = widget.itensDisponiveis.where((i) {
      final c = i.codigoBarras.trim().replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').toLowerCase();
      return c.isNotEmpty && c == termoLimpo;
    }).firstOrNull;

    if (itemPorCodigo != null) {
      _processarAdicaoItemAoCarrinho(itemId: itemPorCodigo.id);
      _buscaController.clear();
      return;
    }

    final itens = _itensEncontrados;
    if (itens.length == 1) {
      _processarAdicaoItemAoCarrinho(itemId: itens.first.id);
      _buscaController.clear();
    }
  }

  List<Cliente> get _sugestoesDeCliente {
    final termo = _clienteController.text.trim();
    final todos = widget.obterClientes();
    if (termo.isEmpty) return todos;
    return todos
        .where((cliente) => cliente.correspondeABusca(termo))
        .toList();
  }

  bool _deveMostrarCampoCliente(String chave) {
    final config = widget.configuracoesImpressora;
    final configCampos = config.camposClienteComanda;
    final ehPadraoAntigoCompleto = !config.camposClientePersonalizados &&
        configCampos.length == kCamposClienteComanda.length &&
        kCamposClienteComanda.every((ch) => configCampos.contains(ch));

    final camposAtivos = ehPadraoAntigoCompleto
        ? kCamposClienteComandaPadrao
        : configCampos;

    return camposAtivos.contains(chave);
  }

  String _montarComanda() {
    return GeradorComprovanteVenda.montarComandaTexto(
      nomeVendedor: widget.nomeVendedor,
      cnpjVendedor: widget.cnpjVendedor,
      numeroPedido: widget.proximoNumero,
      dataHora: _dataHora,
      nomeClienteDigitado: _clienteController.text,
      clienteSelecionado: _clienteSelecionado,
      deveMostrarCampoCliente: _deveMostrarCampoCliente,
      carrinho: _carrinho,
      nomeExibicaoLinha: _nomeExibicaoDaLinha,
      subtotalBaseLinha: _subtotalBaseDaLinha,
      buscarItem: _buscarItem,
      precoComoNumero: _precoComoNumero,
      valorComVirgula: _valorComVirgula,
      subtotalDosItens: _subtotalDosItens,
      frete: _frete,
      desconto: _desconto,
      rotuloDesconto: _rotuloDesconto,
      acrescimo: _acrescimo,
      rotuloAcrescimo: _rotuloAcrescimo,
      total: _total,
      pagamentos: _pagamentos,
      troco: _troco,
    );
  }

  void _adicionarLinhaAoCarrinho({
    required String itemId,
    String? categoriaId,
    String varianteNome = '',
    String precoVariante = '',
  }) {
    final chave = _montarChave(
      itemId: itemId,
      categoriaId: categoriaId,
      varianteNome: varianteNome,
    );
    setState(() {
      final existente = _linhaPorChave(chave);
      if (existente != null) {
        existente.quantidade++;
      } else {
        _carrinho.add(LinhaCarrinho(
          chave: chave,
          itemId: itemId,
          categoriaId: categoriaId,
          varianteNome: varianteNome,
          precoVariante: precoVariante,
        ));
      }
      _aviso = null;
    });
    try {
      final loja = widget.lojaId != null
          ? context.read<PdvProvider>().buscarPorId(widget.lojaId!)
          : null;
      SomService.tocarEvento(SomService.eventoBipVenda, loja: loja);
    } catch (_) {}
  }

  Future<void> _processarAdicaoItemAoCarrinho({
    required String itemId,
    String? categoriaId,
  }) async {
    final item = _buscarItem(itemId);
    if (item == null) return;
    if (item.variantes.isNotEmpty) {
      final varianteEscolhida = await _selecionarVarianteDialog(item);
      if (varianteEscolhida == null) return;
      _adicionarLinhaAoCarrinho(
        itemId: itemId,
        categoriaId: categoriaId,
        varianteNome: varianteEscolhida.nome,
        precoVariante: varianteEscolhida.preco,
      );
    } else {
      _adicionarLinhaAoCarrinho(
        itemId: itemId,
        categoriaId: categoriaId,
      );
    }
  }

  Future<VarianteItem?> _selecionarVarianteDialog(ItemLoja item) {
    return DialogEscolherVarianteItem.mostrar(
      context,
      theme: theme,
      item: item,
    );
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

  Future<void> _editarAcompanhamentosDaLinha(String chave) async {
    final linha = _linhaPorChave(chave);
    if (linha == null) return;

    final grupos = _gruposDaCategoria(linha);
    final theme = widget.theme;

    if (grupos.isEmpty) {
      _mostrarAviso(
          'Esta categoria nao tem grupos de componentes associados.');
      return;
    }

    final selecionados = await DialogEditarAcompanhamentos.mostrar(
      context,
      theme: theme,
      grupos: grupos,
      selecionadosIniciais: linha.acompanhamentosPorItemId,
      buscarItem: _buscarItem,
    );

    if (selecionados != null && mounted) {
      setState(() {
        linha.acompanhamentosPorItemId
          ..clear()
          ..addAll(selecionados);
      });
    }
  }

  void _aoDigitarCliente(String texto) {
    setState(() {
      final selecionado = _clienteSelecionado;
      if (selecionado != null && selecionado.nome != texto) {
        _clienteSelecionado = null;
        if (_temAPrazo) _removerForma(_formaAPrazo);
      }
    });
  }

  void _selecionarCliente(Cliente cliente) {
    setState(() {
      _clienteSelecionado = cliente;
      _clienteController.text = cliente.nome;
      _clienteFocado = false;
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
        } else if (_temAPrazo) {
          _removerForma(_formaAPrazo);
        }
      }
    });
  }

  void _removerForma(String forma) {
    final indice = _pagamentos.indexWhere((p) => p.forma == forma);
    if (indice == -1) return;
    _pagamentos[indice].dispose();
    _pagamentos.removeAt(indice);
  }

  void _recalcularPrazo() {
    if (!_temAPrazo) return;
    final outras = _pagamentos
        .where((p) => p.forma != _formaAPrazo)
        .fold<double>(0.0, (s, p) => s + _precoComoNumero(p.controller.text));
    final restante = _total - outras;
    final valorAPrazo = restante < 0 ? 0.0 : restante;
    final indice = _pagamentos.indexWhere((p) => p.forma == _formaAPrazo);
    if (indice != -1) {
      _pagamentos[indice].controller.text = _valorComVirgula(valorAPrazo);
    }
  }

  void _escolherForma(String forma) {
    final jaTem = _pagamentos.any((p) => p.forma == forma);
    if (jaTem) {
      setState(() {
        _removerForma(forma);
        _recalcularPrazo();
      });
      return;
    }
    if (forma == _formaAPrazo && _clienteSelecionado == null) {
      _mostrarAviso('Selecione um cliente cadastrado para vender a prazo.');
      return;
    }
    setState(() {
      if (forma == _formaAPrazo) {
        final novoPagamento =
            LinhaPagamento(forma: forma, valorInicial: '0,00');
        novoPagamento.controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: novoPagamento.controller.text.length,
        );
        _pagamentos.add(novoPagamento);
      } else {
        final outras = _pagamentos
            .where((p) => p.forma != _formaAPrazo)
            .fold<double>(
                0.0, (s, p) => s + _precoComoNumero(p.controller.text));
        final restante = _total - outras;
        final valor = restante < 0 ? 0.0 : restante;
        final novoPagamento = LinhaPagamento(
          forma: forma,
          valorInicial: _valorComVirgula(valor),
        );
        novoPagamento.controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: novoPagamento.controller.text.length,
        );
        _pagamentos.add(novoPagamento);
      }
      _recalcularPrazo();
      _aviso = null;
    });
  }

  void _mostrarAviso(String texto) {
    setState(() => _aviso = texto);
  }

  void _abrirSeletorDeItemDaCategoria(CategoriaLoja categoria) {
    DialogSeletorItemCategoria.mostrar(
      context,
      theme: theme,
      categoria: categoria,
      buscarItem: _buscarItem,
      onSelecionarItem: (item) {
        _buscaController.clear();
        _processarAdicaoItemAoCarrinho(
          itemId: item.id,
          categoriaId: categoria.id,
        );
      },
    );
  }

  Future<void> _abrirNovoProduto() async {
    double? estoqueInicialInformado;
    await NovoItemDialog.mostrar(
      context,
      theme: theme,
      categorias: widget.categoriasDisponiveis,
      gruposComponentes: widget.gruposDisponiveis,
      layoutExpandido: widget.expandido,
      onEstoqueAjustado: (novoSaldo) {
        estoqueInicialInformado = novoSaldo;
      },
      onCriar: (item, categoriaIds, grupoIds) async {
        await widget.aoCriarItem(
          item,
          categoriaIds,
          grupoIds,
          estoqueInicialInformado,
        );
      },
    );
  }

  Future<void> _concluir() async {
    await FinalizadorNovaVenda.executar(
      context: context,
      theme: theme,
      lojaId: widget.lojaId,
      carrinho: _carrinho,
      pagamentos: _pagamentos,
      clienteSelecionado: _clienteSelecionado,
      clienteNomeDigitado: _clienteController.text,
      subtotalDosItens: _subtotalDosItens,
      frete: _frete,
      desconto: _desconto,
      acrescimo: _acrescimo,
      total: _total,
      falta: _falta,
      troco: _troco,
      temAPrazo: _temAPrazo,
      montarComanda: _montarComanda,
      buscarItem: _buscarItem,
      buscarCategoria: _buscarCategoria,
      nomeVendedor: widget.nomeVendedor,
      cnpjVendedor: widget.cnpjVendedor,
      proximoNumero: widget.proximoNumero,
      cpfAutor: widget.cpfAutor,
      nomeAutor: widget.nomeAutor,
      configuracoesImpressora: widget.configuracoesImpressora,
      itensDisponiveis: widget.itensDisponiveis,
      onMostrarAviso: _mostrarAviso,
      onConcluir: widget.onConcluir,
      onVendaFinalizadaComSucesso: () {
        _vendaConcluida = true;
        NovaVendaDialog.limparRascunho(widget.lojaId);
      },
    );
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

  String _obterDadoPrioritarioCliente(Cliente cliente) {
    // 1º Prioridade: Endereço cadastrado (com número, se houver)
    final end = cliente.endereco.trim();
    final num = cliente.numero.trim();
    if (end.isNotEmpty) {
      return num.isNotEmpty ? '$end, $num' : end;
    }
    // 2º Prioridade: Telefone
    if (cliente.telefone.trim().isNotEmpty) {
      return cliente.telefone.trim();
    }
    // 3º Prioridade: Descrição do cliente
    if (cliente.descricao.trim().isNotEmpty) {
      return cliente.descricao.trim();
    }
    // Demais dados cadastrados até acabar: E-mail, Redes Sociais, Documento
    if (cliente.email.trim().isNotEmpty) {
      return cliente.email.trim();
    }
    if (cliente.redesSociais.trim().isNotEmpty) {
      return cliente.redesSociais.trim();
    }
    if (cliente.cnpj.trim().isNotEmpty) {
      return cliente.cnpj.trim();
    }
    return '';
  }

  Widget _blocoCliente() {
    return ClienteSeletorNovaVendaWidget(
      theme: theme,
      clienteController: _clienteController,
      clienteFocusNode: _clienteFocusNode,
      clienteSelecionado: _clienteSelecionado,
      clienteFocado: _clienteFocado,
      sugestoes: _sugestoesDeCliente,
      todosClientes: widget.obterClientes(),
      onClienteFocadoChanged: (focado) => setState(() => _clienteFocado = focado),
      onDigitarCliente: _aoDigitarCliente,
      onSelecionarCliente: _selecionarCliente,
      onNovoCliente: _abrirClientes,
      obterDadoPrioritario: _obterDadoPrioritarioCliente,
      decoracaoDoBloco: _decoracaoDoBloco,
      decoracaoCampo: _decoracaoCampo,
      tituloDoBloco: _tituloDoBloco,
      botaoPequeno: _botaoPequeno,
    );
  }

  String _resumoAcompanhamentos(LinhaCarrinho linha) {
    final partes = <String>[];
    linha.acompanhamentosPorItemId.forEach((itemId, quantidade) {
      final item = _buscarItem(itemId);
      if (item == null || quantidade <= 0) return;
      final valor =
          _precoComoNumero(item.preco) * quantidade * linha.quantidade;
      partes.add('${quantidade}x ${item.nome} R\$ ${_valorComVirgula(valor)}');
    });
    return partes.join(', ');
  }

  Widget _blocoProduto() {
    return BlocoProdutosNovaVendaWidget(
      theme: theme,
      buscaController: _buscaController,
      buscaFocusNode: _buscaFocusNode,
      buscaFocada: _buscaFocada,
      onBuscaFocadaChanged: (focada) => setState(() => _buscaFocada = focada),
      onSubmeterBusca: _aoSubmeterBusca,
      onAbrirNovoProduto: _abrirNovoProduto,
      categoriasEncontradas: _categoriasEncontradas,
      itensEncontrados: _itensEncontrados,
      todasCategorias: widget.categoriasDisponiveis,
      todosItens: widget.itensDisponiveis,
      carrinho: _carrinho,
      saldoDoItem: _saldoDoItem,
      nomeExibicaoLinha: _nomeExibicaoDaLinha,
      precoBaseUnitarioDaLinha: _precoBaseUnitarioDaLinha,
      subtotalBaseDaLinha: _subtotalBaseDaLinha,
      resumoAcompanhamentos: _resumoAcompanhamentos,
      gruposDaCategoria: _gruposDaCategoria,
      buscarItem: _buscarItem,
      onSelecionarCategoriaNaBusca: _abrirSeletorDeItemDaCategoria,
      onSelecionarItemNaBusca: (item) {
        _buscaController.clear();
        _processarAdicaoItemAoCarrinho(itemId: item.id);
      },
      onAlterarQuantidade: _alterarQuantidade,
      onEditarAcompanhamentos: _editarAcompanhamentosDaLinha,
      decoracaoDoBloco: _decoracaoDoBloco,
      decoracaoCampo: _decoracaoCampo,
      tituloDoBloco: _tituloDoBloco,
      botaoPequeno: _botaoPequeno,
      valorComVirgula: _valorComVirgula,
      precoComoNumero: _precoComoNumero,
    );
  }

  Widget _blocoComanda() {
    return ComandaResumoNovaVendaWidget(
      theme: theme,
      scrollController: _comandaScrollController,
      larguraComanda: _larguraComanda,
      nomeVendedor: widget.nomeVendedor,
      cnpjVendedor: widget.cnpjVendedor,
      proximoNumero: widget.proximoNumero,
      dataHoraFormatada: _dataHoraCompleta(_dataHora),
      nomeClienteDigitado: _clienteController.text,
      clienteSelecionado: _clienteSelecionado,
      deveMostrarCampoCliente: _deveMostrarCampoCliente,
      carrinho: _carrinho,
      nomeExibicaoLinha: _nomeExibicaoDaLinha,
      subtotalBaseLinha: _subtotalBaseDaLinha,
      buscarItem: _buscarItem,
      precoComoNumero: _precoComoNumero,
      valorComVirgula: _valorComVirgula,
      subtotalDosItens: _subtotalDosItens,
      frete: _frete,
      desconto: _desconto,
      rotuloDesconto: _rotuloDesconto,
      acrescimo: _acrescimo,
      rotuloAcrescimo: _rotuloAcrescimo,
      total: _total,
      pagamentos: _pagamentos,
      troco: _troco,
      decoracaoDoBloco: _decoracaoDoBloco,
      tituloDoBloco: _tituloDoBloco,
    );
  }

  Widget _blocoAjustes() {
    return BlocoAjustesNovaVendaWidget(
      theme: theme,
      freteController: _freteController,
      descontoController: _descontoController,
      acrescimoController: _acrescimoController,
      onRecalcularPrazo: () => setState(_recalcularPrazo),
      decoracaoDoBloco: _decoracaoDoBloco,
      decoracaoCampo: _decoracaoCampo,
      tituloDoBloco: _tituloDoBloco,
    );
  }

  Widget _blocoPagamento() {
    return BlocoPagamentoNovaVendaWidget(
      theme: theme,
      scrollController: _pagamentoScrollController,
      formasDePagamento: _formasDePagamento,
      formaAPrazo: _formaAPrazo,
      pagamentos: _pagamentos,
      falta: _falta,
      troco: _troco,
      onEscolherForma: _escolherForma,
      onRemoverForma: (forma) {
        setState(() {
          _removerForma(forma);
          _recalcularPrazo();
        });
      },
      onRecalcularPrazo: () => setState(_recalcularPrazo),
      decoracaoDoBloco: _decoracaoDoBloco,
      decoracaoCampo: _decoracaoCampo,
      tituloDoBloco: _tituloDoBloco,
      valorComVirgula: _valorComVirgula,
    );
  }

  Widget _botaoConcluir() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return theme.borderColor.withValues(alpha: 0.18);
            }
            return theme.buttonColor != Colors.transparent
                ? theme.buttonColor
                : Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return theme.buttonColor != Colors.transparent
                ? theme.buttonTextColor
                : theme.textColor;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return BorderSide(color: theme.textColor, width: 1.4);
            }
            return BorderSide(color: theme.borderColor, width: 1.0);
          }),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 14),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        onPressed: _concluir,
        child: Text(
          'Concluir',
          style: theme.getTextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: theme.buttonColor != Colors.transparent
                ? theme.buttonTextColor
                : theme.textColor,
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
              if (_carrinho.isNotEmpty ||
                  _pagamentos.isNotEmpty ||
                  _clienteController.text.isNotEmpty ||
                  _freteController.text.isNotEmpty ||
                  _descontoController.text.isNotEmpty ||
                  _acrescimoController.text.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.delete_sweep_outlined,
                      size: 20, color: theme.secondaryTextColor),
                  tooltip: 'Limpar campos da venda',
                  onPressed: _limparTudo,
                )
              else
                const SizedBox(width: 48),
            ],
          ),
        ),
        Flexible(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final emDuasColunas =
                  widget.expandido && constraints.maxWidth >= 780;

              if (emDuasColunas) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(
                          children: [
                            _blocoProduto(),
                            const SizedBox(height: 12),
                            _blocoComanda(),
                            const SizedBox(height: 12),
                            _blocoAjustes(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            _blocoCliente(),
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
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
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
              );
            },
          ),
        ),
      ],
    );
  }
}

