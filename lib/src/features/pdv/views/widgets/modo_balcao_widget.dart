import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/services/janela_windows_service.dart';
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
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/estoque_baixa_service.dart';
import 'package:nous/src/features/pdv/views/widgets/modo_balcao/barra_superior_balcao_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/modo_balcao/campo_bipador_balcao_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/modo_balcao/catalogo_balcao_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/modo_balcao/cliente_ajustes_balcao_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/modo_balcao/comanda_balcao_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/modo_balcao/dialogo_componentes_balcao.dart';
import 'package:nous/src/features/pdv/views/widgets/modo_balcao/dialogo_variante_balcao.dart';
import 'package:nous/src/features/pdv/views/widgets/modo_balcao/visor_ultimo_produto_widget.dart';
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

  List<Cliente> get _sugestoesClientes {
    final termo = _clienteController.text.trim();
    if (termo.isEmpty) return widget.clientes;
    return widget.clientes.where((c) => c.correspondeABusca(termo)).toList();
  }

  double _dividaDoCliente(Cliente cliente) {
    final loja = context.read<PdvProvider>().buscarPorId(widget.lojaId);
    final pedidos = loja?.pedidosLoja ?? const <PedidoLoja>[];
    if (pedidos.isEmpty) return 0.0;
    final nomeNorm = TextoUtils.normalizarParaBusca(cliente.nome);
    var total = 0.0;
    for (final p in pedidos) {
      if (!p.aPrazoEmAberto) continue;
      final mesmoId = p.clienteId != null &&
          p.clienteId!.isNotEmpty &&
          p.clienteId == cliente.id;
      final mesmoNome = (p.clienteId == null || p.clienteId!.isEmpty) &&
          nomeNorm.isNotEmpty &&
          TextoUtils.normalizarParaBusca(p.clienteNome) == nomeNorm;
      if (mesmoId || mesmoNome) {
        total += p.valorRestante;
      }
    }
    return total;
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

  double get _freteValor => _precoComoNumero(_freteController.text);
  double get _descontoValor => _precoComoNumero(_descontoController.text);
  double get _acrescimoValor => _precoComoNumero(_acrescimoController.text);

  double get _totalGeral {
    final sub = _subtotalCarrinho;
    final total = sub + _freteValor - _descontoValor + _acrescimoValor;
    return total < 0 ? 0 : total;
  }

  double get _valorRecebido => _precoComoNumero(_valorRecebidoController.text);

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

  String _montarComanda() {
    final buffer = StringBuffer();
    for (final item in _carrinho) {
      buffer.writeln(
        '${item.quantidade}x ${item.nomeExibicao} - R\$ ${_valorFormatado(item.subtotal)}',
      );
      for (final a in item.acompanhamentos) {
        buffer.writeln('  + ${a.quantidadePorUnidade}x ${a.nomeItem}');
      }
      if (item.observacao.isNotEmpty) {
        buffer.writeln('  Obs: ${item.observacao}');
      }
    }
    if (_freteValor > 0) {
      buffer.writeln('Frete: R\$ ${_valorFormatado(_freteValor)}');
    }
    if (_acrescimoValor > 0) {
      buffer.writeln('Acréscimo: R\$ ${_valorFormatado(_acrescimoValor)}');
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

    final lojaAtual = context.read<PdvProvider>().buscarPorId(widget.lojaId);
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
      nomeVendedor: lojaAtual?.nome ?? widget.nomeLoja,
      cnpjVendedor: lojaAtual?.cnpj ?? '',
      lojaId: widget.lojaId,
    );

    // Gera baixas automáticas proporcionais de estoque (incluindo acompanhamentos)
    final baixas = EstoqueBaixaService.calcularMovimentosBaixa(
      itensVendidos: _carrinho,
      itensCadastrados: widget.itens,
      motivo:
          'Venda #${pedido.numero.toString().padLeft(4, '0')} no Modo Balcão',
      cpfAutor: widget.cpfAutor,
      nomeAutor: widget.nomeAutor,
    );

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
              BarraSuperiorBalcaoWidget(
                theme: theme,
                nomeLoja: widget.nomeLoja,
                logoLoja: widget.logoLoja,
                caixaAberto: widget.caixaAberto,
                onSair: widget.onSair,
                onLimparVenda: _limparVenda,
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
                            CampoBipadorBalcaoWidget(
                              theme: theme,
                              controller: _bipadorController,
                              focusNode: _bipadorFocusNode,
                              onChanged: _aoDigitarBipador,
                              onSubmitted: _aoPressionarEnterBipador,
                              onLimpar: () {
                                _bipadorController.clear();
                                setState(() {});
                                _garantirFocoBipador();
                              },
                            ),
                            const SizedBox(height: 12),

                            // 2. Visor do Último Produto Registrado (Visor do Caixa)
                            VisorUltimoProdutoWidget(
                              theme: theme,
                              item: _ultimoItemBipado,
                              itemVendido: _ultimoItemVendido,
                              quantidade: _quantidadeUltimoBipado,
                              formatarValor: _valorFormatado,
                            ),
                            const SizedBox(height: 12),

                            // 3 e 4. Categorias e Catálogo Visual de Produtos
                            Expanded(
                              child: CatalogoBalcaoWidget(
                                theme: theme,
                                categorias: widget.categorias,
                                categoriaFiltroId: _categoriaFiltroId,
                                itens: _itensFiltrados,
                                obterSaldoEstoque: _saldoEstoque,
                                onSelecionarCategoria: (id) {
                                  setState(() => _categoriaFiltroId = id);
                                  _garantirFocoBipador();
                                },
                                onSelecionarItem: (item) {
                                  _processarAdicaoItemAoCarrinho(item);
                                  _garantirFocoBipador();
                                },
                              ),
                            ),
                            const SizedBox(height: 10),

                            // 5. Linha de Cliente e Descontos Rápidos
                            ClienteAjustesBalcaoWidget(
                              theme: theme,
                              clientes: widget.clientes,
                              sugestoesClientes: _sugestoesClientes,
                              clienteSelecionado: _clienteSelecionado,
                              mostrarSugestoesCliente: _mostrarSugestoesCliente,
                              clienteController: _clienteController,
                              clienteFocusNode: _clienteFocusNode,
                              descontoController: _descontoController,
                              freteController: _freteController,
                              acrescimoController: _acrescimoController,
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