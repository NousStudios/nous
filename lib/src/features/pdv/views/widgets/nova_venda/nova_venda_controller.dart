import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/modelos_nova_venda.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_venda/calculadora_nova_venda.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_venda/gerenciador_rascunho_venda.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_venda/helpers/nova_venda_busca_helper.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_venda/helpers/nova_venda_carrinho_helper.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_venda/helpers/nova_venda_finalizacao_helper.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_venda/helpers/nova_venda_pagamento_helper.dart';

class NovaVendaController extends ChangeNotifier {
  static Map<String, RascunhoVenda> get rascunhosPorLoja =>
      GerenciadorRascunhoVenda.rascunhosPorLoja;

  static void limparRascunho(String? lojaId) {
    GerenciadorRascunhoVenda.limparRascunho(lojaId);
  }

  static const List<String> formasDePagamento = [
    'Pix',
    'Dinheiro',
    'Débito',
    'Crédito',
    'Voucher',
    'À Prazo',
  ];

  static const String formaAPrazo = 'À Prazo';
  static const double larguraComanda = 320;
  static const String prefixoItem = 'item:';
  static const String prefixoCategoria = 'cat:';

  final AppTheme theme;
  final String? lojaId;
  final bool expandido;
  final List<ItemLoja> itensDisponiveis;
  final List<CategoriaLoja> categoriasDisponiveis;
  final List<GrupoComponentesLoja> gruposDisponiveis;
  final List<Cliente> Function() obterClientes;
  final List<PedidoLoja> Function()? obterPedidos;
  final Future<void> Function() aoAbrirClientes;
  final String nomeVendedor;
  final String cnpjVendedor;
  final int proximoNumero;
  final String cpfAutor;
  final String nomeAutor;
  final void Function(PedidoLoja pedido, List<MovimentoEstoque> movimentosEstoque) onConcluir;
  final Future<void> Function(
    ItemLoja item,
    List<String> categoriaIds,
    List<String> grupoIds, [
    double? estoqueInicial,
  ]) aoCriarItem;
  final ConfiguracoesImpressora configuracoesImpressora;
  final List<MovimentoEstoque> movimentosEstoque;

  final clienteController = TextEditingController();
  final buscaController = TextEditingController();
  final freteController = TextEditingController();
  final descontoController = TextEditingController();
  final acrescimoController = TextEditingController();
  final comandaScrollController = ScrollController();
  final pagamentoScrollController = ScrollController();
  final buscaFocusNode = FocusNode();
  final clienteFocusNode = FocusNode();

  final List<LinhaCarrinho> carrinho = [];
  final List<LinhaPagamento> pagamentos = [];
  Cliente? clienteSelecionado;
  String? aviso;
  late final DateTime dataHora;
  bool buscaFocada = false;
  bool clienteFocado = false;
  bool vendaConcluida = false;

  NovaVendaController({
    required this.theme,
    this.lojaId,
    this.expandido = false,
    required this.itensDisponiveis,
    required this.categoriasDisponiveis,
    required this.gruposDisponiveis,
    required this.obterClientes,
    this.obterPedidos,
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
  }) {
    dataHora = DateTime.now();

    buscaFocusNode.addListener(() {
      if (buscaFocusNode.hasFocus && !buscaFocada) {
        buscaFocada = true;
        notifyListeners();
      }
    });

    clienteFocusNode.addListener(() {
      if (clienteFocusNode.hasFocus && !clienteFocado) {
        clienteFocado = true;
        notifyListeners();
      }
    });

    buscaController.addListener(_aoAlterarTextoBusca);

    _restaurarRascunhoSeHouver();
  }

  void _aoAlterarTextoBusca() {
    if (buscaFocusNode.hasFocus) {
      buscaFocadoOuDigitando();
    } else {
      notifyListeners();
    }
  }

  void buscaFocadoOuDigitando() {
    buscaFocada = true;
    notifyListeners();
  }

  static double precoComoNumero(String texto) =>
      CalculadoraNovaVenda.precoComoNumero(texto);

  static String valorComVirgula(double valor) =>
      CalculadoraNovaVenda.valorComVirgula(valor);

  static String doisDigitos(int n) => CalculadoraNovaVenda.doisDigitos(n);

  static String dataHoraCompleta(DateTime d) =>
      CalculadoraNovaVenda.dataHoraCompleta(d);

  void _restaurarRascunhoSeHouver() {
    GerenciadorRascunhoVenda.restaurarRascunho(
      lojaId: lojaId,
      buscarCliente: buscarCliente,
      clienteController: clienteController,
      freteController: freteController,
      descontoController: descontoController,
      acrescimoController: acrescimoController,
      carrinho: carrinho,
      pagamentos: pagamentos,
      onClienteRestaurado: (c) => clienteSelecionado = c,
    );
  }

  void salvarRascunhoAtual() {
    GerenciadorRascunhoVenda.salvarRascunho(
      lojaId: lojaId,
      carrinho: carrinho,
      pagamentos: pagamentos,
      clienteSelecionado: clienteSelecionado,
      clienteController: clienteController,
      freteController: freteController,
      descontoController: descontoController,
      acrescimoController: acrescimoController,
    );
  }

  void limparTudo() {
    NovaVendaCarrinhoHelper.limparTudo(
      carrinho: carrinho,
      pagamentos: pagamentos,
      controllers: [
        clienteController,
        buscaController,
        freteController,
        descontoController,
        acrescimoController,
      ],
    );
    clienteSelecionado = null;
    aviso = null;
    limparRascunho(lojaId);
    notifyListeners();
  }

  ItemLoja? buscarItem(String id) =>
      itensDisponiveis.where((i) => i.id == id).firstOrNull;

  double saldoDoItem(String itemId) => movimentosEstoque
      .where((m) => m.itemId == itemId)
      .fold(0.0, (s, m) => s + m.quantidadeComSinal);

  CategoriaLoja? buscarCategoria(String id) =>
      categoriasDisponiveis.where((c) => c.id == id).firstOrNull;

  GrupoComponentesLoja? buscarGrupo(String id) =>
      gruposDisponiveis.where((g) => g.id == id).firstOrNull;

  Cliente? buscarCliente(String id) =>
      obterClientes().where((c) => c.id == id).firstOrNull;

  String montarChave({
    required String itemId,
    String? categoriaId,
    String varianteNome = '',
  }) =>
      NovaVendaCarrinhoHelper.montarChave(
        itemId: itemId,
        prefixoItem: prefixoItem,
        prefixoCategoria: prefixoCategoria,
        categoriaId: categoriaId,
        varianteNome: varianteNome,
      );

  List<GrupoComponentesLoja> gruposDaCategoria(LinhaCarrinho linha) =>
      NovaVendaCarrinhoHelper.gruposDaCategoria(
        linha: linha,
        buscarCategoria: buscarCategoria,
        buscarGrupo: buscarGrupo,
      );

  double precoDosAcompanhamentosPorUnidade(LinhaCarrinho linha) =>
      CalculadoraNovaVenda.precoDosAcompanhamentosPorUnidade(
        linha: linha,
        buscarItem: buscarItem,
      );

  double precoBaseUnitarioDaLinha(LinhaCarrinho linha) =>
      CalculadoraNovaVenda.precoBaseUnitarioDaLinha(
        linha: linha,
        buscarItem: buscarItem,
        buscarCategoria: buscarCategoria,
      );

  double precoUnitarioDaLinha(LinhaCarrinho linha) =>
      CalculadoraNovaVenda.precoUnitarioDaLinha(
        linha: linha,
        buscarItem: buscarItem,
        buscarCategoria: buscarCategoria,
      );

  double subtotalBaseDaLinha(LinhaCarrinho linha) =>
      CalculadoraNovaVenda.subtotalBaseDaLinha(
        linha: linha,
        buscarItem: buscarItem,
        buscarCategoria: buscarCategoria,
      );

  double subtotalDaLinha(LinhaCarrinho linha) =>
      CalculadoraNovaVenda.subtotalDaLinha(
        linha: linha,
        buscarItem: buscarItem,
        buscarCategoria: buscarCategoria,
      );

  double get subtotalDosItens {
    var soma = 0.0;
    for (final linha in carrinho) {
      soma += subtotalDaLinha(linha);
    }
    return soma;
  }

  double _calcularValorOuPorcentagem(String texto) =>
      CalculadoraNovaVenda.calcularValorOuPorcentagem(texto, subtotalDosItens);

  double get frete => precoComoNumero(freteController.text);
  double get desconto => _calcularValorOuPorcentagem(descontoController.text);
  double get acrescimo => _calcularValorOuPorcentagem(acrescimoController.text);

  String get rotuloDesconto => NovaVendaPagamentoHelper.rotuloAjuste(
        descontoController.text,
        'Desconto',
      );

  String get rotuloAcrescimo => NovaVendaPagamentoHelper.rotuloAjuste(
        acrescimoController.text,
        'Acréscimo',
      );

  double get total => NovaVendaPagamentoHelper.calcularTotal(
        subtotalDosItens: subtotalDosItens,
        frete: frete,
        acrescimo: acrescimo,
        desconto: desconto,
      );

  bool get temAPrazo => pagamentos.any((p) => p.forma == formaAPrazo);

  double get somaTotalPagamentos =>
      NovaVendaPagamentoHelper.somaTotalPagamentos(pagamentos);

  double get falta => NovaVendaPagamentoHelper.calcularFalta(
        total: total,
        somaPagamentos: somaTotalPagamentos,
      );

  double get troco => NovaVendaPagamentoHelper.calcularTroco(
        total: total,
        somaPagamentos: somaTotalPagamentos,
      );

  String nomeExibicaoDaLinha(LinhaCarrinho linha) =>
      NovaVendaCarrinhoHelper.nomeExibicaoDaLinha(
        linha: linha,
        buscarItem: buscarItem,
        buscarCategoria: buscarCategoria,
      );

  LinhaCarrinho? linhaPorChave(String chave) =>
      NovaVendaCarrinhoHelper.linhaPorChave(carrinho, chave);

  List<CategoriaLoja> get categoriasEncontradas =>
      NovaVendaBuscaHelper.filtrarCategorias(
        termo: buscaController.text,
        categoriasDisponiveis: categoriasDisponiveis,
      );

  List<ItemLoja> get itensEncontrados => NovaVendaBuscaHelper.filtrarItens(
        termo: buscaController.text,
        itensDisponiveis: itensDisponiveis,
        categoriasEncontradas: categoriasEncontradas,
      );

  void aoSubmeterBusca(String valor, BuildContext context) {
    NovaVendaBuscaHelper.aoSubmeterBusca(
      valor: valor,
      itensDisponiveis: itensDisponiveis,
      itensEncontrados: itensEncontrados,
      onAdicionarItem: (itemId) =>
          processarAdicaoItemAoCarrinho(itemId: itemId, context: context),
      onLimparBusca: buscaController.clear,
    );
  }

  List<Cliente> get sugestoesDeCliente =>
      NovaVendaBuscaHelper.filtrarClientes(
        termo: clienteController.text,
        clientes: obterClientes(),
      );

  bool deveMostrarCampoCliente(String chave) =>
      NovaVendaBuscaHelper.deveMostrarCampoCliente(
        config: configuracoesImpressora,
        chave: chave,
      );

  String montarComanda() => NovaVendaFinalizacaoHelper.montarComanda(this);

  void adicionarLinhaAoCarrinho({
    required String itemId,
    String? categoriaId,
    String varianteNome = '',
    String precoVariante = '',
    BuildContext? context,
  }) {
    final chave = montarChave(
      itemId: itemId,
      categoriaId: categoriaId,
      varianteNome: varianteNome,
    );
    NovaVendaCarrinhoHelper.adicionarLinhaAoCarrinho(
      carrinho: carrinho,
      chave: chave,
      itemId: itemId,
      categoriaId: categoriaId,
      varianteNome: varianteNome,
      precoVariante: precoVariante,
      lojaId: lojaId,
      context: context,
    );
    aviso = null;
    notifyListeners();
  }

  void setBuscaFocada(bool focada) {
    buscaFocada = focada;
    notifyListeners();
  }

  void setClienteFocado(bool focado) {
    clienteFocado = focado;
    notifyListeners();
  }

  void removerFormaERecalcular(String forma) {
    removerForma(forma);
    recalcularPrazo();
    notifyListeners();
  }

  void recalcularPrazoEMudar() {
    recalcularPrazo();
    notifyListeners();
  }

  Future<void> processarAdicaoItemAoCarrinho({
    required String itemId,
    String? categoriaId,
    required BuildContext context,
  }) =>
      NovaVendaCarrinhoHelper.processarAdicaoItemAoCarrinho(
        item: buscarItem(itemId),
        itemId: itemId,
        categoriaId: categoriaId,
        context: context,
        theme: theme,
        onAdicionarLinha: adicionarLinhaAoCarrinho,
      );

  void alterarQuantidade(String chave, int variacao) {
    NovaVendaCarrinhoHelper.alterarQuantidade(
      carrinho: carrinho,
      chave: chave,
      variacao: variacao,
    );
    aviso = null;
    notifyListeners();
  }

  Future<void> editarAcompanhamentosDaLinha(
    String chave,
    BuildContext context,
  ) async {
    final linha = linhaPorChave(chave);
    final alterado = await NovaVendaCarrinhoHelper.editarAcompanhamentosDaLinha(
      linha: linha,
      context: context,
      theme: theme,
      grupos: linha == null ? const [] : gruposDaCategoria(linha),
      buscarItem: buscarItem,
      onMostrarAviso: mostrarAviso,
    );
    if (alterado) notifyListeners();
  }

  void aoDigitarCliente(String texto) {
    clienteFocado = true;
    clienteSelecionado = NovaVendaBuscaHelper.aoDigitarCliente(
      texto: texto,
      clienteSelecionado: clienteSelecionado,
      temAPrazo: temAPrazo,
      onRemoverForma: removerForma,
      formaAPrazo: formaAPrazo,
    );
    notifyListeners();
  }

  void selecionarCliente(Cliente cliente) {
    clienteSelecionado = cliente;
    clienteFocado = false;
    aviso = null;
    NovaVendaBuscaHelper.aplicarClienteSelecionado(
      cliente: cliente,
      clienteController: clienteController,
      freteController: freteController,
    );
    notifyListeners();
  }

  Future<void> abrirClientes() async {
    final anterior = clienteSelecionado;
    clienteSelecionado = await NovaVendaBuscaHelper.sincronizarClienteAposAbrir(
      clienteSelecionado: clienteSelecionado,
      aoAbrirClientes: aoAbrirClientes,
      buscarCliente: buscarCliente,
      clienteController: clienteController,
      temAPrazo: temAPrazo,
      onRemoverForma: removerForma,
      formaAPrazo: formaAPrazo,
    );
    if (anterior != null) notifyListeners();
  }

  void removerForma(String forma) => NovaVendaPagamentoHelper.removerForma(
        pagamentos: pagamentos,
        forma: forma,
      );

  void recalcularPrazo() => NovaVendaPagamentoHelper.recalcularPrazo(
        pagamentos: pagamentos,
        formaAPrazo: formaAPrazo,
        total: total,
      );

  void escolherForma(String forma) {
    final mensagemAviso = NovaVendaPagamentoHelper.escolherForma(
      forma: forma,
      formaAPrazo: formaAPrazo,
      pagamentos: pagamentos,
      clienteSelecionado: clienteSelecionado,
      total: total,
    );
    if (mensagemAviso != null) {
      mostrarAviso(mensagemAviso);
      return;
    }
    aviso = null;
    notifyListeners();
  }

  void mostrarAviso(String texto) {
    aviso = texto;
    notifyListeners();
  }

  void abrirSeletorDeItemDaCategoria(
    CategoriaLoja categoria,
    BuildContext context,
  ) {
    NovaVendaCarrinhoHelper.abrirSeletorDeItemDaCategoria(
      categoria: categoria,
      context: context,
      theme: theme,
      buscarItem: buscarItem,
      onLimparBusca: buscaController.clear,
      onSelecionar: (item) => processarAdicaoItemAoCarrinho(
        itemId: item.id,
        categoriaId: categoria.id,
        context: context,
      ),
    );
  }

  Future<void> abrirNovoProduto(BuildContext context) =>
      NovaVendaCarrinhoHelper.abrirNovoProduto(
        context: context,
        theme: theme,
        categoriasDisponiveis: categoriasDisponiveis,
        gruposDisponiveis: gruposDisponiveis,
        expandido: expandido,
        aoCriarItem: aoCriarItem,
      );

  Future<void> concluir(BuildContext context) =>
      NovaVendaFinalizacaoHelper.concluir(this, context);

  String resumoAcompanhamentos(LinhaCarrinho linha) =>
      CalculadoraNovaVenda.resumoAcompanhamentos(
        linha: linha,
        buscarItem: buscarItem,
      );

  double dividaDoCliente(Cliente cliente) =>
      CalculadoraNovaVenda.dividaDoCliente(
        cliente: cliente,
        pedidos: obterPedidos?.call() ?? const <PedidoLoja>[],
      );

  String obterDadoPrioritarioCliente(Cliente cliente) =>
      CalculadoraNovaVenda.obterDadoPrioritarioCliente(cliente);

  @override
  void dispose() {
    buscaController.removeListener(_aoAlterarTextoBusca);
    if (!vendaConcluida) {
      salvarRascunhoAtual();
    }
    buscaFocusNode.dispose();
    clienteFocusNode.dispose();
    clienteController.dispose();
    buscaController.dispose();
    freteController.dispose();
    descontoController.dispose();
    acrescimoController.dispose();
    comandaScrollController.dispose();
    pagamentoScrollController.dispose();
    NovaVendaCarrinhoHelper.disporListas(
      carrinho: carrinho,
      pagamentos: pagamentos,
    );
    super.dispose();
  }
}
