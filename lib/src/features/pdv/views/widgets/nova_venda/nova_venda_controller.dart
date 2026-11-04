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
import 'package:nous/src/features/pdv/views/widgets/nova_venda/finalizador_nova_venda.dart';
import 'package:nous/src/features/pdv/views/widgets/novo_item_dialog.dart';

class NovaVendaController extends ChangeNotifier {
  static final Map<String, RascunhoVenda> rascunhosPorLoja = {};

  static void limparRascunho(String? lojaId) {
    rascunhosPorLoja.remove(lojaId ?? '');
  }

  static const List<String> formasDePagamento = [
    'Pix',
    'Dinheiro',
    'Débito',
    'Crédito',
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

  static double precoComoNumero(String texto) {
    var limpo = texto.replaceAll(RegExp(r'[^0-9,.]'), '');
    if (limpo.contains(',')) {
      limpo = limpo.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(limpo) ?? 0;
  }

  static String valorComVirgula(double valor) =>
      valor.toStringAsFixed(2).replaceAll('.', ',');

  static String doisDigitos(int n) => n.toString().padLeft(2, '0');

  static String dataHoraCompleta(DateTime d) =>
      '${doisDigitos(d.day)}/${doisDigitos(d.month)}/${d.year} '
      '${doisDigitos(d.hour)}:${doisDigitos(d.minute)}';

  void _restaurarRascunhoSeHouver() {
    final chaveLoja = lojaId ?? '';
    final rascunho = rascunhosPorLoja[chaveLoja];
    if (rascunho == null) return;

    if (rascunho.clienteId != null) {
      clienteSelecionado = buscarCliente(rascunho.clienteId!);
    }
    clienteController.text = rascunho.clienteNomeDigitado;
    freteController.text = rascunho.frete;
    descontoController.text = rascunho.desconto;
    acrescimoController.text = rascunho.acrescimo;

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
      carrinho.add(linha);
    }

    for (final pag in rascunho.pagamentos) {
      pagamentos.add(LinhaPagamento(
        forma: pag.forma,
        valorInicial: pag.valor,
      ));
    }
  }

  void salvarRascunhoAtual() {
    final temDados = carrinho.isNotEmpty ||
        pagamentos.isNotEmpty ||
        clienteSelecionado != null ||
        clienteController.text.trim().isNotEmpty ||
        freteController.text.trim().isNotEmpty ||
        descontoController.text.trim().isNotEmpty ||
        acrescimoController.text.trim().isNotEmpty;

    final chaveLoja = lojaId ?? '';
    if (temDados) {
      rascunhosPorLoja[chaveLoja] = RascunhoVenda(
        itens: carrinho.map((linha) {
          return ItemRascunho(
            chave: linha.chave,
            itemId: linha.itemId,
            categoriaId: linha.categoriaId,
            varianteNome: linha.varianteNome,
            precoVariante: linha.precoVariante,
            quantidade: linha.quantidade,
            acompanhamentos: Map<String, int>.from(linha.acompanhamentosPorItemId),
            observacao: linha.observacaoController.text,
          );
        }).toList(),
        pagamentos: pagamentos.map((p) {
          return (forma: p.forma, valor: p.controller.text);
        }).toList(),
        clienteId: clienteSelecionado?.id,
        clienteNomeDigitado: clienteController.text,
        frete: freteController.text,
        desconto: descontoController.text,
        acrescimo: acrescimoController.text,
      );
    } else {
      rascunhosPorLoja.remove(chaveLoja);
    }
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

  ItemLoja? buscarItem(String id) {
    for (final item in itensDisponiveis) {
      if (item.id == id) return item;
    }
    return null;
  }

  double saldoDoItem(String itemId) {
    var saldo = 0.0;
    for (final m in movimentosEstoque) {
      if (m.itemId == itemId) {
        saldo += m.quantidadeComSinal;
      }
    }
    return saldo;
  }

  CategoriaLoja? buscarCategoria(String id) {
    for (final categoria in categoriasDisponiveis) {
      if (categoria.id == id) return categoria;
    }
    return null;
  }

  GrupoComponentesLoja? buscarGrupo(String id) {
    for (final grupo in gruposDisponiveis) {
      if (grupo.id == id) return grupo;
    }
    return null;
  }

  Cliente? buscarCliente(String id) {
    for (final cliente in obterClientes()) {
      if (cliente.id == id) return cliente;
    }
    return null;
  }

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
    var soma = 0.0;
    linha.acompanhamentosPorItemId.forEach((itemId, quantidade) {
      final item = buscarItem(itemId);
      if (item == null) return;
      soma += precoComoNumero(item.preco) * quantidade;
    });
    return soma;
  }

  double precoBaseUnitarioDaLinha(LinhaCarrinho linha) {
    final item = buscarItem(linha.itemId);
    if (item == null) return 0;
    final precoItem = linha.precoVariante.trim().isNotEmpty
        ? precoComoNumero(linha.precoVariante)
        : precoComoNumero(item.preco);
    var soma = precoItem;
    if (linha.categoriaId != null) {
      final categoria = buscarCategoria(linha.categoriaId!);
      if (categoria != null) soma += precoComoNumero(categoria.preco);
    }
    return soma;
  }

  double precoUnitarioDaLinha(LinhaCarrinho linha) {
    return precoBaseUnitarioDaLinha(linha) +
        precoDosAcompanhamentosPorUnidade(linha);
  }

  double subtotalBaseDaLinha(LinhaCarrinho linha) =>
      precoBaseUnitarioDaLinha(linha) * linha.quantidade;

  double subtotalDaLinha(LinhaCarrinho linha) =>
      precoUnitarioDaLinha(linha) * linha.quantidade;

  double get subtotalDosItens {
    var soma = 0.0;
    for (final linha in carrinho) {
      soma += subtotalDaLinha(linha);
    }
    return soma;
  }

  double _calcularValorOuPorcentagem(String texto) {
    final t = texto.trim();
    if (t.isEmpty) return 0.0;
    if (t.contains('%')) {
      final limpo = t.replaceAll('%', '').trim();
      final percentual = precoComoNumero(limpo);
      if (percentual <= 0) return 0.0;
      return subtotalDosItens * (percentual / 100.0);
    }
    return precoComoNumero(t);
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

  String resumoAcompanhamentos(LinhaCarrinho linha) {
    final partes = <String>[];
    linha.acompanhamentosPorItemId.forEach((itemId, quantidade) {
      final item = buscarItem(itemId);
      if (item == null || quantidade <= 0) return;
      final valor = precoComoNumero(item.preco) * quantidade * linha.quantidade;
      partes.add('${quantidade}x ${item.nome} R\$ ${valorComVirgula(valor)}');
    });
    return partes.join(', ');
  }

  double dividaDoCliente(Cliente cliente) {
    final pedidos = obterPedidos?.call() ?? const <PedidoLoja>[];
    if (pedidos.isEmpty) return 0.0;
    var soma = 0.0;
    final nomeAlvo = cliente.nome.trim().toLowerCase();
    for (final p in pedidos) {
      final ehDesteCliente = p.clienteId == cliente.id ||
          (nomeAlvo.isNotEmpty &&
              p.clienteNome.trim().toLowerCase() == nomeAlvo);
      if (ehDesteCliente && p.aPrazoEmAberto) {
        soma += p.valorRestante;
      }
    }
    return soma;
  }

  String obterDadoPrioritarioCliente(Cliente cliente) {
    final end = cliente.endereco.trim();
    final num = cliente.numero.trim();
    final tel = cliente.telefone.trim();

    final enderecoCompleto = end.isNotEmpty
        ? (num.isNotEmpty ? '$end, $num' : end)
        : (num.isNotEmpty ? 'nº $num' : '');

    final partes = <String>[
      if (enderecoCompleto.isNotEmpty) enderecoCompleto,
      if (tel.isNotEmpty) tel,
    ];
    if (partes.isNotEmpty) {
      return partes.join(' • ');
    }

    if (cliente.descricao.trim().isNotEmpty) {
      return cliente.descricao.trim();
    }
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
