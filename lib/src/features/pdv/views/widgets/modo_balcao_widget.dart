import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/estoque_baixa_service.dart';
import 'package:nous/src/features/pdv/views/widgets/modo_balcao/area_operador_balcao_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/modo_balcao/balcao_logica_helper.dart';
import 'package:nous/src/features/pdv/views/widgets/modo_balcao/barra_superior_balcao_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/modo_balcao/comanda_balcao_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/modo_balcao/dialogo_componentes_balcao.dart';
import 'package:nous/src/features/pdv/views/widgets/modo_balcao/dialogo_variante_balcao.dart';
import 'package:nous/src/features/pdv/views/widgets/venda_concluida_dialog.dart';

const List<String> _formasBalcao = [
  'Dinheiro',
  'Pix',
  'Débito',
  'Crédito',
  'Voucher',
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

  List<Cliente> get _sugestoesClientes => BalcaoLogicaHelper.filtrarClientes(
      widget.clientes, _clienteController.text);

  double _dividaDoCliente(Cliente cliente) {
    final loja = context.read<PdvProvider>().buscarPorId(widget.lojaId);
    return BalcaoLogicaHelper.dividaDoCliente(
      cliente,
      loja?.pedidosLoja ?? const <PedidoLoja>[],
    );
  }

  void _garantirFocoBipador() {
    if (!_bipadorFocusNode.hasFocus &&
        !_clienteFocusNode.hasFocus &&
        !_mostrarSugestoesCliente) {
      _bipadorFocusNode.requestFocus();
    }
  }

  double get _subtotalCarrinho =>
      _carrinho.fold<double>(0.0, (soma, item) => soma + item.subtotal);

  double get _freteValor =>
      BalcaoLogicaHelper.precoComoNumero(_freteController.text);
  double get _descontoValor =>
      BalcaoLogicaHelper.precoComoNumero(_descontoController.text);
  double get _acrescimoValor =>
      BalcaoLogicaHelper.precoComoNumero(_acrescimoController.text);

  double get _totalGeral {
    final total =
        _subtotalCarrinho + _freteValor - _descontoValor + _acrescimoValor;
    return total < 0 ? 0 : total;
  }

  double get _valorRecebido =>
      BalcaoLogicaHelper.precoComoNumero(_valorRecebidoController.text);

  double get _trocoCalculado {
    if (_formaPagamentoSelecionada != 'Dinheiro') return 0.0;
    final recebido = _valorRecebido;
    final total = _totalGeral;
    return recebido > total ? recebido - total : 0.0;
  }

  List<ItemLoja> get _itensFiltrados => BalcaoLogicaHelper.filtrarItens(
        itens: widget.itens,
        categorias: widget.categorias,
        categoriaFiltroId: _categoriaFiltroId,
        termo: _bipadorController.text,
      );

  void _aoDigitarBipador(String valor) {
    setState(() {});
  }

  void _aoPressionarEnterBipador() {
    final codigo = _bipadorController.text.trim();
    if (codigo.isEmpty) return;

    final itemEncontrado = BalcaoLogicaHelper.buscarItemParaBipagem(
      codigo: codigo,
      itens: widget.itens,
      itensFiltrados: _itensFiltrados,
    );

    if (itemEncontrado != null) {
      _processarAdicaoItemAoCarrinho(itemEncontrado);
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
      final varianteEscolhida = await DialogoVarianteBalcao.mostrar(
        context: context,
        theme: theme,
        item: item,
      );
      if (varianteEscolhida == null) return;
      _adicionarItemAoCarrinho(item, variante: varianteEscolhida);
    } else {
      _adicionarItemAoCarrinho(item);
    }
  }

  void _adicionarItemAoCarrinho(ItemLoja item, {VarianteItem? variante}) {
    SomService.tocarBipPadrao();
    setState(() {
      _aviso = null;
      _ultimoItemBipado = item;
      final res = BalcaoLogicaHelper.adicionarItemAoCarrinho(
        carrinho: _carrinho,
        item: item,
        categorias: widget.categorias,
        categoriaFiltroId: _categoriaFiltroId,
        variante: variante,
      );
      _ultimoItemVendido = res.ultimoItemVendido;
      _quantidadeUltimoBipado = res.quantidadeUltimoBipado;
    });
  }

  void _alterarQuantidadeCarrinho(int indice, int delta) {
    setState(() {
      final res = BalcaoLogicaHelper.alterarQuantidadeCarrinho(
        carrinho: _carrinho,
        indice: indice,
        delta: delta,
        ultimoItemVendidoAtual: _ultimoItemVendido,
        quantidadeUltimoBipadoAtual: _quantidadeUltimoBipado,
      );
      _ultimoItemVendido = res.ultimoItemVendido;
      _quantidadeUltimoBipado = res.quantidadeUltimoBipado;
    });
  }

  void _removerItemCarrinho(int indice) {
    setState(() {
      _ultimoItemVendido = BalcaoLogicaHelper.removerItemCarrinho(
        carrinho: _carrinho,
        indice: indice,
        ultimoItemVendidoAtual: _ultimoItemVendido,
      );
    });
  }

  List<GrupoComponentesLoja> _obterGruposDoItemVendido(ItemVendido item) =>
      BalcaoLogicaHelper.obterGruposDoItemVendido(
        item,
        widget.categorias,
        widget.gruposComponentes,
      );

  Future<void> _abrirDialogoComponentes(int indice) async {
    final item = _carrinho[indice];
    final grupos = _obterGruposDoItemVendido(item);

    if (grupos.isEmpty) {
      await _editarObservacaoItem(indice);
      return;
    }

    final itemAtualizado = await DialogoComponentesBalcao.mostrar(
      context: context,
      theme: theme,
      item: item,
      grupos: grupos,
      itens: widget.itens,
    );

    if (itemAtualizado != null) {
      setState(() {
        _carrinho[indice] = itemAtualizado;
        if (_ultimoItemVendido?.itemId == item.itemId &&
            _ultimoItemVendido?.categoriaId == item.categoriaId) {
          _ultimoItemVendido = itemAtualizado;
        }
      });
      _garantirFocoBipador();
    }
  }

  Future<void> _editarObservacaoItem(int indice) async {
    final item = _carrinho[indice];
    final novaObs = await DialogoObservacaoBalcao.mostrar(
      context: context,
      theme: theme,
      item: item,
    );

    if (novaObs != null) {
      setState(() {
        final atualizado = item.copyWith(observacao: novaObs);
        _carrinho[indice] = atualizado;
        if (_ultimoItemVendido?.itemId == item.itemId &&
            _ultimoItemVendido?.categoriaId == item.categoriaId) {
          _ultimoItemVendido = atualizado;
        }
      });
      _garantirFocoBipador();
    }
  }

  void _limparVenda() {
    setState(() {
      _carrinho.clear();
      _ultimoItemBipado = null;
      _ultimoItemVendido = null;
      _clienteSelecionado = null;
      _mostrarSugestoesCliente = false;
      _clienteController.clear();
      _descontoController.clear();
      _acrescimoController.clear();
      _freteController.clear();
      _valorRecebidoController.clear();
      _formaPagamentoSelecionada = 'Dinheiro';
      _aviso = null;
      _quantidadeUltimoBipado = 1;
    });
    _garantirFocoBipador();
  }

  Future<void> _finalizarVenda() async {
    if (_carrinho.isEmpty) {
      setState(() => _aviso = 'Insira pelo menos um item na comanda.');
      return;
    }

    final temPrazo = _formaPagamentoSelecionada.toLowerCase().contains('prazo');
    if (temPrazo && _clienteSelecionado == null) {
      setState(() {
        _aviso = 'Selecione um cliente cadastrado para vender a prazo.';
        _mostrarSugestoesCliente = true;
      });
      _clienteFocusNode.requestFocus();
      return;
    }

    final lojaAtual = context.read<PdvProvider>().buscarPorId(widget.lojaId);
    final pedido = BalcaoLogicaHelper.montarPedidoBalcao(
      agora: DateTime.now(),
      proximoNumero: widget.proximoNumero,
      clienteSelecionado: _clienteSelecionado,
      clienteNomeTexto: _clienteController.text,
      carrinho: _carrinho,
      total: _totalGeral,
      formaPagamentoSelecionada: _formaPagamentoSelecionada,
      valorRecebido: _valorRecebido,
      trocoCalculado: _trocoCalculado,
      temPrazo: temPrazo,
      freteValor: _freteValor,
      descontoValor: _descontoValor,
      acrescimoValor: _acrescimoValor,
      nomeVendedor: lojaAtual?.nome ?? widget.nomeLoja,
      cnpjVendedor: lojaAtual?.cnpj ?? '',
      lojaId: widget.lojaId,
    );

    final baixas = EstoqueBaixaService.calcularMovimentosBaixa(
      itensVendidos: _carrinho,
      itensCadastrados: widget.itens,
      motivo:
          'Venda #${pedido.numero.toString().padLeft(4, '0')} no Modo Balcão',
      cpfAutor: widget.cpfAutor,
      nomeAutor: widget.nomeAutor,
    );

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
              BarraSuperiorBalcaoWidget(
                theme: theme,
                nomeLoja: widget.nomeLoja,
                logoLoja: widget.logoLoja,
                caixaAberto: widget.caixaAberto,
                onSair: widget.onSair,
                onLimparVenda: _limparVenda,
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 6,
                      child: AreaOperadorBalcaoWidget(
                        theme: theme,
                        bipadorController: _bipadorController,
                        bipadorFocusNode: _bipadorFocusNode,
                        ultimoItemBipado: _ultimoItemBipado,
                        ultimoItemVendido: _ultimoItemVendido,
                        quantidadeUltimoBipado: _quantidadeUltimoBipado,
                        categorias: widget.categorias,
                        categoriaFiltroId: _categoriaFiltroId,
                        itensFiltrados: _itensFiltrados,
                        clientes: widget.clientes,
                        sugestoesClientes: _sugestoesClientes,
                        clienteSelecionado: _clienteSelecionado,
                        mostrarSugestoesCliente: _mostrarSugestoesCliente,
                        clienteController: _clienteController,
                        clienteFocusNode: _clienteFocusNode,
                        descontoController: _descontoController,
                        freteController: _freteController,
                        acrescimoController: _acrescimoController,
                        onChangedBipador: _aoDigitarBipador,
                        onSubmittedBipador: _aoPressionarEnterBipador,
                        onLimparBipador: () {
                          _bipadorController.clear();
                          setState(() {});
                          _garantirFocoBipador();
                        },
                        formatarValor: BalcaoLogicaHelper.valorFormatado,
                        obterSaldoEstoque: (id) =>
                            BalcaoLogicaHelper.saldoEstoque(
                          id,
                          widget.movimentosEstoque,
                        ),
                        onSelecionarCategoria: (id) {
                          setState(() => _categoriaFiltroId = id);
                          _garantirFocoBipador();
                        },
                        onSelecionarItem: (item) {
                          _processarAdicaoItemAoCarrinho(item);
                          _garantirFocoBipador();
                        },
                        obterDividaCliente: _dividaDoCliente,
                        onSelecionarCliente: (c) {
                          setState(() {
                            _clienteSelecionado = c;
                            _clienteController.text = c.nome;
                            _mostrarSugestoesCliente = false;
                            if (c.fretePadrao > 0) {
                              _freteController.text = c.fretePadrao
                                  .toStringAsFixed(2)
                                  .replaceAll('.', ',');
                            }
                          });
                        },
                        onRemoverCliente: () {
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
                        },
                        onAlterarVisibilidadeSugestoes: (visivel) {
                          setState(() => _mostrarSugestoesCliente = visivel);
                        },
                        onGarantirFocoBipador: _garantirFocoBipador,
                        onAjusteAlterado: () => setState(() {}),
                      ),
                    ),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: theme.borderColor.withValues(alpha: 0.5),
                    ),
                    Expanded(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        color: theme.cardBackgroundColor.withValues(alpha: 0.4),
                        child: ComandaBalcaoWidget(
                          theme: theme,
                          carrinho: _carrinho,
                          formaPagamentoSelecionada: _formaPagamentoSelecionada,
                          formasDePagamento: _formasBalcao,
                          valorRecebidoController: _valorRecebidoController,
                          subtotal: _subtotalCarrinho,
                          total: _totalGeral,
                          troco: _trocoCalculado,
                          descontoValor: _descontoValor,
                          acrescimoValor: _acrescimoValor,
                          freteValor: _freteValor,
                          aviso: _aviso,
                          obterGruposDoItemVendido: _obterGruposDoItemVendido,
                          onAlterarQuantidade: _alterarQuantidadeCarrinho,
                          onRemoverItem: _removerItemCarrinho,
                          onAbrirComponentes: _abrirDialogoComponentes,
                          onEditarObservacao: _editarObservacaoItem,
                          onSelecionarForma: (forma) => setState(
                              () => _formaPagamentoSelecionada = forma),
                          onFinalizarVenda: _finalizarVenda,
                        ),
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
}
