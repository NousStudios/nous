import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/services/som_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/utils/texto_utils.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/modelos_nova_venda.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/gerador_comprovante_venda.dart';
import 'package:nous/src/features/pdv/views/dialogs/dialog_editar_acompanhamentos.dart';
import 'package:nous/src/features/pdv/views/dialogs/dialog_escolher_variante_item.dart';
import 'package:nous/src/features/pdv/views/dialogs/dialog_seletor_item_categoria.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_venda/calculadora_nova_venda.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_venda/finalizador_nova_venda.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_venda/gerenciador_rascunho_venda.dart';
import 'package:nous/src/features/pdv/views/widgets/novo_item_dialog.dart';

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
  final Future<void> Function(ItemLoja item, List<String> categoriaIds, List<String> grupoIds, [double? estoqueInicial]) aoCriarItem;
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
    for (final linha in carrinho) {
      linha.dispose();
    }
    carrinho.clear();

    for (final p in pagamentos) {
      p.dispose();
    }
    pagamentos.clear();

    clienteSelecionado = null;
    clienteController.clear();
    buscaController.clear();
    freteController.clear();
    descontoController.clear();
    acrescimoController.clear();
    aviso = null;
    limparRascunho(lojaId);
    notifyListeners();
  }

  ItemLoja? buscarItem(String id) =>
      itensDisponiveis.where((i) => i.id == id).firstOrNull;

  double saldoDoItem(String itemId) =>
      movimentosEstoque.where((m) => m.itemId == itemId).fold(0.0, (s, m) => s + m.quantidadeComSinal);

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
  }) {
    var base = categoriaId == null
        ? '$prefixoItem$itemId'
        : '$prefixoCategoria$categoriaId|$prefixoItem$itemId';
    if (varianteNome.trim().isNotEmpty) {
      base = '$base|var:${varianteNome.trim()}';
    }
    return base;
  }

  List<GrupoComponentesLoja> gruposDaCategoria(LinhaCarrinho linha) {
    final categoriaId = linha.categoriaId;
    if (categoriaId == null) return [];
    final categoria = buscarCategoria(categoriaId);
    if (categoria == null) return [];
    return categoria.grupoIds
        .map((id) => buscarGrupo(id))
        .whereType<GrupoComponentesLoja>()
        .toList();
  }

  double precoDosAcompanhamentosPorUnidade(LinhaCarrinho linha) {
    return CalculadoraNovaVenda.precoDosAcompanhamentosPorUnidade(
      linha: linha,
      buscarItem: buscarItem,
    );
  }

  double precoBaseUnitarioDaLinha(LinhaCarrinho linha) {
    return CalculadoraNovaVenda.precoBaseUnitarioDaLinha(
      linha: linha,
      buscarItem: buscarItem,
      buscarCategoria: buscarCategoria,
    );
  }

  double precoUnitarioDaLinha(LinhaCarrinho linha) {
    return CalculadoraNovaVenda.precoUnitarioDaLinha(
      linha: linha,
      buscarItem: buscarItem,
      buscarCategoria: buscarCategoria,
    );
  }

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

  double _calcularValorOuPorcentagem(String texto) {
    return CalculadoraNovaVenda.calcularValorOuPorcentagem(
      texto,
      subtotalDosItens,
    );
  }

  double get frete => precoComoNumero(freteController.text);
  double get desconto => _calcularValorOuPorcentagem(descontoController.text);
  double get acrescimo => _calcularValorOuPorcentagem(acrescimoController.text);

  String get rotuloDesconto {
    final t = descontoController.text.trim();
    if (t.contains('%')) {
      return 'Desconto ($t)';
    }
    return 'Desconto';
  }

  String get rotuloAcrescimo {
    final t = acrescimoController.text.trim();
    if (t.contains('%')) {
      return 'Acréscimo ($t)';
    }
    return 'Acréscimo';
  }

  double get total {
    final t = subtotalDosItens + frete + acrescimo - desconto;
    return t < 0 ? 0 : t;
  }

  bool get temAPrazo => pagamentos.any((p) => p.forma == formaAPrazo);

  double get somaTotalPagamentos {
    var soma = 0.0;
    for (final p in pagamentos) {
      soma += precoComoNumero(p.controller.text);
    }
    return soma;
  }

  double get falta {
    final f = total - somaTotalPagamentos;
    return f < 0 ? 0.0 : f;
  }

  double get troco {
    final t = somaTotalPagamentos - total;
    return t < 0 ? 0.0 : t;
  }

  String nomeExibicaoDaLinha(LinhaCarrinho linha) {
    final item = buscarItem(linha.itemId);
    if (item == null) return 'Item removido';
    final base = linha.categoriaId == null
        ? item.nome
        : '${buscarCategoria(linha.categoriaId!)?.nome ?? ''} ${item.nome}'.trim();
    if (linha.varianteNome.trim().isNotEmpty) {
      return '$base (${linha.varianteNome.trim()})';
    }
    return base;
  }

  LinhaCarrinho? linhaPorChave(String chave) {
    for (final linha in carrinho) {
      if (linha.chave == chave) return linha;
    }
    return null;
  }

  List<CategoriaLoja> get categoriasEncontradas {
    final termo = buscaController.text.trim();
    if (termo.isEmpty) return [];
    return categoriasDisponiveis
        .where((c) => TextoUtils.contemIgnorandoAcentos(c.nome, termo))
        .toList();
  }

  List<ItemLoja> get itensEncontrados {
    final termo = buscaController.text.trim();
    if (termo.isEmpty) return [];
    final idsDeItensEmCategoriasEncontradas = <String>{};
    for (final categoria in categoriasEncontradas) {
      idsDeItensEmCategoriasEncontradas.addAll(categoria.itemIds);
    }
    final termoLimpo = termo.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').toLowerCase();
    return itensDisponiveis
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

  void aoSubmeterBusca(String valor, BuildContext context) {
    final termo = valor.trim();
    if (termo.isEmpty) return;
    final termoLimpo = termo.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').toLowerCase();

    final itemPorCodigo = itensDisponiveis.where((i) {
      final c = i.codigoBarras.trim().replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').toLowerCase();
      return c.isNotEmpty && c == termoLimpo;
    }).firstOrNull;

    if (itemPorCodigo != null) {
      processarAdicaoItemAoCarrinho(itemId: itemPorCodigo.id, context: context);
      buscaController.clear();
      return;
    }

    final itens = itensEncontrados;
    if (itens.length == 1) {
      processarAdicaoItemAoCarrinho(itemId: itens.first.id, context: context);
      buscaController.clear();
    }
  }

  List<Cliente> get sugestoesDeCliente {
    final termo = clienteController.text.trim();
    final todos = obterClientes();
    if (termo.isEmpty) return todos;
    return todos.where((cliente) => cliente.correspondeABusca(termo)).toList();
  }

  bool deveMostrarCampoCliente(String chave) {
    final config = configuracoesImpressora;
    final configCampos = config.camposClienteComanda;
    final ehPadraoAntigoCompleto = !config.camposClientePersonalizados &&
        configCampos.length == kCamposClienteComanda.length &&
        kCamposClienteComanda.every((ch) => configCampos.contains(ch));

    final camposAtivos = ehPadraoAntigoCompleto
        ? kCamposClienteComandaPadrao
        : configCampos;

    return camposAtivos.contains(chave);
  }

  String montarComanda() {
    return GeradorComprovanteVenda.montarComandaTexto(
      nomeVendedor: nomeVendedor,
      cnpjVendedor: cnpjVendedor,
      numeroPedido: proximoNumero,
      dataHora: dataHora,
      nomeClienteDigitado: clienteController.text,
      clienteSelecionado: clienteSelecionado,
      deveMostrarCampoCliente: deveMostrarCampoCliente,
      carrinho: carrinho,
      nomeExibicaoLinha: nomeExibicaoDaLinha,
      subtotalBaseLinha: subtotalBaseDaLinha,
      buscarItem: buscarItem,
      precoComoNumero: precoComoNumero,
      valorComVirgula: valorComVirgula,
      subtotalDosItens: subtotalDosItens,
      frete: frete,
      desconto: desconto,
      rotuloDesconto: rotuloDesconto,
      acrescimo: acrescimo,
      rotuloAcrescimo: rotuloAcrescimo,
      total: total,
      pagamentos: pagamentos,
      troco: troco,
    );
  }

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
    final existente = linhaPorChave(chave);
    if (existente != null) {
      existente.quantidade++;
    } else {
      carrinho.add(LinhaCarrinho(
        chave: chave,
        itemId: itemId,
        categoriaId: categoriaId,
        varianteNome: varianteNome,
        precoVariante: precoVariante,
      ));
    }
    aviso = null;
    notifyListeners();

    if (context != null) {
      try {
        final loja = lojaId != null
            ? context.read<PdvProvider>().buscarPorId(lojaId!)
            : null;
        SomService.tocarEvento(SomService.eventoBipVenda, loja: loja);
      } catch (_) {}
    }
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
  }) async {
    final item = buscarItem(itemId);
    if (item == null) return;
    if (item.variantes.isNotEmpty) {
      final varianteEscolhida = await DialogEscolherVarianteItem.mostrar(
        context,
        theme: theme,
        item: item,
      );
      if (varianteEscolhida == null || !context.mounted) return;
      adicionarLinhaAoCarrinho(
        itemId: itemId,
        categoriaId: categoriaId,
        varianteNome: varianteEscolhida.nome,
        precoVariante: varianteEscolhida.preco,
        context: context,
      );
    } else {
      if (!context.mounted) return;
      adicionarLinhaAoCarrinho(
        itemId: itemId,
        categoriaId: categoriaId,
        context: context,
      );
    }
  }

  void alterarQuantidade(String chave, int variacao) {
    final linha = linhaPorChave(chave);
    if (linha == null) return;
    final nova = linha.quantidade + variacao;
    if (nova <= 0) {
      linha.dispose();
      carrinho.remove(linha);
    } else {
      linha.quantidade = nova;
    }
    aviso = null;
    notifyListeners();
  }

  Future<void> editarAcompanhamentosDaLinha(String chave, BuildContext context) async {
    final linha = linhaPorChave(chave);
    if (linha == null) return;

    final grupos = gruposDaCategoria(linha);
    if (grupos.isEmpty) {
      mostrarAviso('Esta categoria nao tem grupos de componentes associados.');
      return;
    }

    final selecionados = await DialogEditarAcompanhamentos.mostrar(
      context,
      theme: theme,
      grupos: grupos,
      selecionadosIniciais: linha.acompanhamentosPorItemId,
      buscarItem: buscarItem,
    );

    if (selecionados != null) {
      linha.acompanhamentosPorItemId
        ..clear()
        ..addAll(selecionados);
      notifyListeners();
    }
  }

  void aoDigitarCliente(String texto) {
    clienteFocado = true;
    final selecionado = clienteSelecionado;
    if (selecionado != null && selecionado.nome != texto) {
      clienteSelecionado = null;
      if (temAPrazo) removerForma(formaAPrazo);
    }
    notifyListeners();
  }

  void selecionarCliente(Cliente cliente) {
    clienteSelecionado = cliente;
    clienteController.text = cliente.nome;
    clienteFocado = false;
    aviso = null;
    if (cliente.fretePadrao > 0) {
      freteController.text =
          cliente.fretePadrao.toStringAsFixed(2).replaceAll('.', ',');
    }
    notifyListeners();
  }

  Future<void> abrirClientes() async {
    await aoAbrirClientes();
    final id = clienteSelecionado?.id;
    if (id != null) {
      final atualizado = buscarCliente(id);
      clienteSelecionado = atualizado;
      if (atualizado != null) {
        clienteController.text = atualizado.nome;
      } else if (temAPrazo) {
        removerForma(formaAPrazo);
      }
      notifyListeners();
    }
  }

  void removerForma(String forma) {
    final indice = pagamentos.indexWhere((p) => p.forma == forma);
    if (indice == -1) return;
    pagamentos[indice].dispose();
    pagamentos.removeAt(indice);
  }

  void recalcularPrazo() {
    if (!temAPrazo) return;
    final outras = pagamentos
        .where((p) => p.forma != formaAPrazo)
        .fold<double>(0.0, (s, p) => s + precoComoNumero(p.controller.text));
    final restante = total - outras;
    final valorAPrazo = restante < 0 ? 0.0 : restante;
    final indice = pagamentos.indexWhere((p) => p.forma == formaAPrazo);
    if (indice != -1) {
      pagamentos[indice].controller.text = valorComVirgula(valorAPrazo);
    }
  }

  void escolherForma(String forma) {
    final jaTem = pagamentos.any((p) => p.forma == forma);
    if (jaTem) {
      removerForma(forma);
      recalcularPrazo();
      notifyListeners();
      return;
    }
    if (forma == formaAPrazo && clienteSelecionado == null) {
      mostrarAviso('Selecione um cliente cadastrado para vender a prazo.');
      return;
    }

    if (forma == formaAPrazo) {
      final novoPagamento = LinhaPagamento(forma: forma, valorInicial: '0,00');
      novoPagamento.controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: novoPagamento.controller.text.length,
      );
      pagamentos.add(novoPagamento);
    } else {
      final outras = pagamentos
          .where((p) => p.forma != formaAPrazo)
          .fold<double>(0.0, (s, p) => s + precoComoNumero(p.controller.text));
      final restante = total - outras;
      final valor = restante < 0 ? 0.0 : restante;
      final novoPagamento = LinhaPagamento(
        forma: forma,
        valorInicial: valorComVirgula(valor),
      );
      novoPagamento.controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: novoPagamento.controller.text.length,
      );
      pagamentos.add(novoPagamento);
    }
    recalcularPrazo();
    aviso = null;
    notifyListeners();
  }

  void mostrarAviso(String texto) {
    aviso = texto;
    notifyListeners();
  }

  void abrirSeletorDeItemDaCategoria(CategoriaLoja categoria, BuildContext context) {
    DialogSeletorItemCategoria.mostrar(
      context,
      theme: theme,
      categoria: categoria,
      buscarItem: buscarItem,
      onSelecionarItem: (item) {
        buscaController.clear();
        processarAdicaoItemAoCarrinho(
          itemId: item.id,
          categoriaId: categoria.id,
          context: context,
        );
      },
    );
  }

  Future<void> abrirNovoProduto(BuildContext context) async {
    double? estoqueInicialInformado;
    await NovoItemDialog.mostrar(
      context,
      theme: theme,
      categorias: categoriasDisponiveis,
      gruposComponentes: gruposDisponiveis,
      layoutExpandido: expandido,
      onEstoqueAjustado: (novoSaldo) {
        estoqueInicialInformado = novoSaldo;
      },
      onCriar: (item, categoriaIds, grupoIds) async {
        await aoCriarItem(
          item,
          categoriaIds,
          grupoIds,
          estoqueInicialInformado,
        );
      },
    );
  }

  Future<void> concluir(BuildContext context) async {
    await FinalizadorNovaVenda.executar(
      context: context,
      theme: theme,
      lojaId: lojaId,
      carrinho: carrinho,
      pagamentos: pagamentos,
      clienteSelecionado: clienteSelecionado,
      clienteNomeDigitado: clienteController.text,
      subtotalDosItens: subtotalDosItens,
      frete: frete,
      desconto: desconto,
      acrescimo: acrescimo,
      total: total,
      falta: falta,
      troco: troco,
      temAPrazo: temAPrazo,
      montarComanda: montarComanda,
      buscarItem: buscarItem,
      buscarCategoria: buscarCategoria,
      nomeVendedor: nomeVendedor,
      cnpjVendedor: cnpjVendedor,
      proximoNumero: proximoNumero,
      cpfAutor: cpfAutor,
      nomeAutor: nomeAutor,
      configuracoesImpressora: configuracoesImpressora,
      itensDisponiveis: itensDisponiveis,
      onMostrarAviso: mostrarAviso,
      onConcluir: onConcluir,
      onVendaFinalizadaComSucesso: () {
        vendaConcluida = true;
        limparRascunho(lojaId);
      },
    );
  }

  String resumoAcompanhamentos(LinhaCarrinho linha) =>
      CalculadoraNovaVenda.resumoAcompanhamentos(linha: linha, buscarItem: buscarItem);

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
    for (final linha in carrinho) {
      linha.dispose();
    }
    for (final p in pagamentos) {
      p.dispose();
    }
    super.dispose();
  }
}
