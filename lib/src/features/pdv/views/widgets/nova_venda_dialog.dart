import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
import 'package:nous/src/features/pdv/views/widgets/nova_venda/nova_venda_controller.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_venda/bloco_produtos_nova_venda_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_venda/cliente_seletor_nova_venda_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_venda/comanda_resumo_nova_venda_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/nova_venda/pagamento_nova_venda_widget.dart';

class NovaVendaDialog {
  static void limparRascunho(String? lojaId) {
    NovaVendaController.limparRascunho(lojaId);
  }

  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required List<ItemLoja> itensDisponiveis,
    required List<CategoriaLoja> categoriasDisponiveis,
    required List<GrupoComponentesLoja> gruposDisponiveis,
    required List<Cliente> Function() obterClientes,
    List<PedidoLoja> Function()? obterPedidos,
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
                    obterPedidos: obterPedidos ??
                        () =>
                            (lojaId != null
                                ? pdv.buscarPorId(lojaId)?.pedidosLoja
                                : null) ??
                            const <PedidoLoja>[],
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
  final List<PedidoLoja> Function()? obterPedidos;
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
  });

  @override
  State<_NovaVendaConteudo> createState() => _NovaVendaConteudoState();
}

class _NovaVendaConteudoState extends State<_NovaVendaConteudo> {
  late final NovaVendaController _c;

  @override
  void initState() {
    super.initState();
    _c = NovaVendaController(
      theme: widget.theme,
      lojaId: widget.lojaId,
      expandido: widget.expandido,
      itensDisponiveis: widget.itensDisponiveis,
      categoriasDisponiveis: widget.categoriasDisponiveis,
      gruposDisponiveis: widget.gruposDisponiveis,
      obterClientes: widget.obterClientes,
      obterPedidos: widget.obterPedidos,
      aoAbrirClientes: widget.aoAbrirClientes,
      nomeVendedor: widget.nomeVendedor,
      cnpjVendedor: widget.cnpjVendedor,
      proximoNumero: widget.proximoNumero,
      cpfAutor: widget.cpfAutor,
      nomeAutor: widget.nomeAutor,
      onConcluir: widget.onConcluir,
      aoCriarItem: widget.aoCriarItem,
      configuracoesImpressora: widget.configuracoesImpressora,
      movimentosEstoque: widget.movimentosEstoque,
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  AppTheme get theme => widget.theme;

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

  Widget _blocoCliente() {
    return ClienteSeletorNovaVendaWidget(
      theme: theme,
      clienteController: _c.clienteController,
      clienteFocusNode: _c.clienteFocusNode,
      clienteSelecionado: _c.clienteSelecionado,
      clienteFocado: _c.clienteFocado,
      sugestoes: _c.sugestoesDeCliente,
      todosClientes: widget.obterClientes(),
      onClienteFocadoChanged: _c.setClienteFocado,
      onDigitarCliente: _c.aoDigitarCliente,
      onSelecionarCliente: _c.selecionarCliente,
      onNovoCliente: _c.abrirClientes,
      obterDadoPrioritario: _c.obterDadoPrioritarioCliente,
      obterDividaCliente: _c.dividaDoCliente,
      decoracaoDoBloco: _decoracaoDoBloco,
      decoracaoCampo: _decoracaoCampo,
      tituloDoBloco: _tituloDoBloco,
      botaoPequeno: _botaoPequeno,
    );
  }

  Widget _blocoProduto() {
    return BlocoProdutosNovaVendaWidget(
      theme: theme,
      buscaController: _c.buscaController,
      buscaFocusNode: _c.buscaFocusNode,
      buscaFocada: _c.buscaFocada,
      onBuscaFocadaChanged: _c.setBuscaFocada,
      onSubmeterBusca: (v) => _c.aoSubmeterBusca(v, context),
      onAbrirNovoProduto: () => _c.abrirNovoProduto(context),
      categoriasEncontradas: _c.categoriasEncontradas,
      itensEncontrados: _c.itensEncontrados,
      todasCategorias: widget.categoriasDisponiveis,
      todosItens: widget.itensDisponiveis,
      carrinho: _c.carrinho,
      saldoDoItem: _c.saldoDoItem,
      nomeExibicaoLinha: _c.nomeExibicaoDaLinha,
      precoBaseUnitarioDaLinha: _c.precoBaseUnitarioDaLinha,
      subtotalBaseDaLinha: _c.subtotalBaseDaLinha,
      resumoAcompanhamentos: _c.resumoAcompanhamentos,
      gruposDaCategoria: _c.gruposDaCategoria,
      buscarItem: _c.buscarItem,
      onSelecionarCategoriaNaBusca: (cat) => _c.abrirSeletorDeItemDaCategoria(cat, context),
      onSelecionarItemNaBusca: (item) {
        _c.buscaController.clear();
        _c.processarAdicaoItemAoCarrinho(itemId: item.id, context: context);
      },
      onAlterarQuantidade: _c.alterarQuantidade,
      onEditarAcompanhamentos: (chave) => _c.editarAcompanhamentosDaLinha(chave, context),
      decoracaoDoBloco: _decoracaoDoBloco,
      decoracaoCampo: _decoracaoCampo,
      tituloDoBloco: _tituloDoBloco,
      botaoPequeno: _botaoPequeno,
      valorComVirgula: NovaVendaController.valorComVirgula,
      precoComoNumero: NovaVendaController.precoComoNumero,
    );
  }

  Widget _blocoComanda({bool expandirAltura = false}) {
    return ComandaResumoNovaVendaWidget(
      theme: theme,
      scrollController: _c.comandaScrollController,
      larguraComanda: NovaVendaController.larguraComanda,
      nomeVendedor: widget.nomeVendedor,
      cnpjVendedor: widget.cnpjVendedor,
      proximoNumero: widget.proximoNumero,
      dataHoraFormatada: NovaVendaController.dataHoraCompleta(_c.dataHora),
      nomeClienteDigitado: _c.clienteController.text,
      clienteSelecionado: _c.clienteSelecionado,
      deveMostrarCampoCliente: _c.deveMostrarCampoCliente,
      carrinho: _c.carrinho,
      nomeExibicaoLinha: _c.nomeExibicaoDaLinha,
      subtotalBaseLinha: _c.subtotalBaseDaLinha,
      buscarItem: _c.buscarItem,
      precoComoNumero: NovaVendaController.precoComoNumero,
      valorComVirgula: NovaVendaController.valorComVirgula,
      subtotalDosItens: _c.subtotalDosItens,
      frete: _c.frete,
      desconto: _c.desconto,
      rotuloDesconto: _c.rotuloDesconto,
      acrescimo: _c.acrescimo,
      rotuloAcrescimo: _c.rotuloAcrescimo,
      total: _c.total,
      pagamentos: _c.pagamentos,
      troco: _c.troco,
      decoracaoDoBloco: _decoracaoDoBloco,
      tituloDoBloco: _tituloDoBloco,
      expandirAltura: expandirAltura,
    );
  }

  Widget _blocoAjustes() {
    return BlocoAjustesNovaVendaWidget(
      theme: theme,
      freteController: _c.freteController,
      descontoController: _c.descontoController,
      acrescimoController: _c.acrescimoController,
      onRecalcularPrazo: _c.recalcularPrazoEMudar,
      decoracaoDoBloco: _decoracaoDoBloco,
      decoracaoCampo: _decoracaoCampo,
      tituloDoBloco: _tituloDoBloco,
    );
  }

  Widget _blocoPagamento() {
    return BlocoPagamentoNovaVendaWidget(
      theme: theme,
      scrollController: _c.pagamentoScrollController,
      formasDePagamento: NovaVendaController.formasDePagamento,
      formaAPrazo: NovaVendaController.formaAPrazo,
      pagamentos: _c.pagamentos,
      falta: _c.falta,
      troco: _c.troco,
      onEscolherForma: _c.escolherForma,
      onRemoverForma: _c.removerFormaERecalcular,
      onRecalcularPrazo: _c.recalcularPrazoEMudar,
      decoracaoDoBloco: _decoracaoDoBloco,
      decoracaoCampo: _decoracaoCampo,
      tituloDoBloco: _tituloDoBloco,
      valorComVirgula: NovaVendaController.valorComVirgula,
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
        onPressed: () => _c.concluir(context),
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
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final temDados = _c.carrinho.isNotEmpty ||
            _c.pagamentos.isNotEmpty ||
            _c.clienteController.text.isNotEmpty ||
            _c.freteController.text.isNotEmpty ||
            _c.descontoController.text.isNotEmpty ||
            _c.acrescimoController.text.isNotEmpty;

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
                  if (temDados)
                    IconButton(
                      icon: Icon(Icons.delete_sweep_outlined,
                          size: 20, color: theme.secondaryTextColor),
                      tooltip: 'Limpar campos da venda',
                      onPressed: _c.limparTudo,
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
                                _blocoCliente(),
                                const SizedBox(height: 12),
                                _blocoProduto(),
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
                                _blocoComanda(),
                                const SizedBox(height: 12),
                                _blocoPagamento(),
                                const SizedBox(height: 12),
                                if (_c.aviso != null) ...[
                                  Text(
                                    _c.aviso!,
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
                        if (_c.aviso != null) ...[
                          Text(
                            _c.aviso!,
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
      },
    );
  }
}
